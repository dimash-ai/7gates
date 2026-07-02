# Goal

Port Focal's **recurrence-scoped mutations** — editing and deleting recurring calendar events with a
`single` / `following` / `all` scope — onto the Focal FastAPI backend, faithful to the legacy contract.
After this slice a user can edit or delete **one occurrence** (via a per-occurrence override, including a
soft-delete), **this-and-following** occurrences (splitting the series), or the **whole series**.

Second and final slice of Phase 2 step 2 ("Events with recurrence + overrides"), building on the shipped
`focal-calendar-recurrence-read` (schema + create + occurrence expansion). The override **table** already
exists and is read/merged by expansion; this slice makes the override + split + group-delete **writes**.

> **Binding contract = the legacy source** (`focal/server/storage.ts`, `focal/server/routes.ts`,
> `focal/server/utils/recurrence.ts`); cited line numbers are the authority. Rebuilt idiomatically
> (service branches + the `recurrence` domain helpers), not transliterated, but must match observably.
> Paths relative to the pipeline root; service at `superapp/apps/focal/server`, legacy read-only at `focal/`.

> **Backend-only.** No React UI. Reuses the calendar service's `_build_occurrence`, `_overrides_map`,
> `_compute_priority`, `_enrich`, owned-link, completion, and time-normalization.

> **Scope resolution (legacy `resolveRecurringTarget` + `getRecurringMutationScope`, storage.ts:341-371).**
> Scope ∈ `{single, following, all}`. The `:id` is a **master id** or a **synthetic occurrence id**
> (`{master}__occurrence__{YYYY-MM-DD}`). The **target occurrence date is `occurrenceDate ?? parsed`** — the
> `occurrenceDate` query param **takes precedence**, falling back to the date parsed from an occurrence id
> (storage.ts:349). When `recurrenceScope` is omitted it **defaults** to `single` for an occurrence id and
> `all` for a master id. The master must be owned by the JWT `sub` (the legacy has no ownership check — this
> slice **adds** it). **A non-recurring master (`recurrence == "none"`) or a legacy child row
> (`recurring_event_id` set) is updated/deleted in place, ignoring the scope** (storage.ts:4044-4050);
> `single`/`following` apply only to a recurring master, where they require a target occurrence date (none →
> `validation_error`, a documented hardening over the legacy's bare 404).

> **Request encoding (intentional idiom).** `recurrenceScope` + `occurrenceDate` are **query params** on
> both `PATCH` and `DELETE` (clean control-vs-payload separation, consistent across verbs). The legacy read
> them from the PATCH **body** and the DELETE **query**; standardizing on the query is a documented
> deviation. `PATCH` body is the `EventUpdate` payload; `DELETE` has no body.

> **`EventUpdate` un-defers the recurrence rule.** This slice adds `recurrence` / `recurrenceEndDate` /
> `recurrenceExceptions` to `EventUpdate` (validated as in create). They apply to the **master** on
> `all`/`following`; on `single` they are **stripped** (`sanitizeSingleOccurrenceUpdates`, storage.ts:373) —
> an override cannot change the recurrence rule. `recurringEventId`/`recurrenceGroupId`/`oldLogic` remain
> server-managed (not `EventUpdate` fields).

> **Error envelope.** Typed `AppError` only. `not_found` (404) when the master is missing/non-owned, or when
> **update-`single`, update-`following`, or delete-`single`** target an occurrence that doesn't resolve
> (excepted/soft-deleted) — **delete-`following` does NOT check** (it truncates by date even for an
> excepted/deleted target, storage.ts:4314-4342). `validation_error` (422) for a bad `occurrenceDate`, a
> recurring-master `single`/`following` with no target date, a bad recurrence rule, or `endTime ≤ startTime`
> (effective). `related_record_not_found` (400) for a bad owned-link. `PATCH` → **200** + the enriched
> result; `DELETE` → **204**.

# Scope

**Domain helpers — `app/domain/recurrence.py`**

- `previous_occurrence(d, recurrence)` — port of `previousOccurrenceDate` (recurrence.ts:43-54): daily −1d,
  weekly −7d, **monthly −1 month with month-end clamp** (Mar 31 → Feb 28), **yearly −1 year** (Feb 29 →
  Feb 28). It is **not** a strict inverse of `advance_occurrence` (the clamps don't round-trip); match
  date-fns `subMonths`/`subYears`. (Deferred from slice 1; add it now.)
- `recurrence_group_id(event)` — port of `getRecurringGroupId` (storage.ts:311-326):
  `event.recurrence_group_id` if set, else the event's own `id` when it is a recurring master
  (`is_recurring_type(recurrence)` and `recurring_event_id` is None), else `None`.

**Scope + target resolution (service)**

- Resolve `(master, target_occurrence_date, scope)` (port `resolveRecurringTarget` +
  `getRecurringMutationScope`): master id = parsed master (occurrence id) or the id; **target date =
  `occurrenceDate` param ?? parsed-id date**; load the **owned** master (`not_found` if missing/non-owned);
  scope = `recurrenceScope` ?? (occurrence id → `single`, master id → `all`). If the master is
  **non-recurring** (`recurrence == "none"`) or a child (`recurring_event_id` set), update/delete the row in
  place **ignoring the scope** (storage.ts:4044-4050) — i.e. the existing calendar update/delete path. Else
  (recurring master) `single`/`following` require a target date (none → `validation_error`).

**UPDATE — `PATCH /api/events/:id?recurrenceScope&occurrenceDate`** (`updateRecurringEventNew`, storage.ts:4025-4264)

- **`all`** (storage.ts:4052-4068): update the **master** in place with the payload (incl. the recurrence
  rule if provided), reusing the existing event-update logic (owned-link, completion transition, recomputed
  priority, time normalization). **Date-reset (exact condition):** when a **target occurrence date** is
  present AND the payload sets `date` AND `payload.date == the current occurrence's resolved date` AND that
  date `!= master.date` (editing a *moved* occurrence "for all"), drop the `date` change (keep
  `master.date`) so the series isn't anchored to the moved override's date. Returns the enriched master.
- **`following`** (storage.ts:4075-4157): if `occurrenceDate <= master.date`, just update the master (can't
  split before the start). Else **split**: (a) set the master's `recurrence_end_date =
  previous_occurrence(occurrenceDate)`; (b) prune the master's `recurrence_exceptions` to `< occurrenceDate`;
  (c) **create a new master** from the effective occurrence merged with the payload — `recurrence` from the
  payload (if a valid type) else the master's; `recurrence_end_date` from the payload else the master's;
  `recurrence_exceptions = []`; **`recurrence_group_id = recurrence_group_id(master)`** (both masters share
  the group); priority computed; `old_logic=False`; (d) **delete overrides** with `occurrence_date >=
  occurrenceDate`. Returns the enriched new master.
- **`single`** (storage.ts:4159-4264): upsert the **override** for `(master, occurrenceDate)`. Strip the
  recurrence-rule fields from the payload; merge onto the **effective occurrence** (master + any existing
  override); recompute priority from the merged hierarchy; **completion transition is by the *explicit*
  `completed` only** — `transition_completed_at(prev, payload.completed)` where `prev` = the existing
  override's `completed` if one exists, else `False` (NOT the master's — so editing a title on a
  done series doesn't stamp `completedAt`, storage.ts:4190-4210). Unique `(recurring_event_id,
  occurrence_date)` upsert (`is_deleted=False`). Returns the enriched **occurrence** (synthetic id).

**DELETE — `DELETE /api/events/:id?recurrenceScope&occurrenceDate`** (`deleteRecurringEventNew`, storage.ts:4266-4400)

- **`all`** (storage.ts:4289-4308): delete every `calendar_events` row where `recurrence_group_id ==
  recurrence_group_id(master)` **OR** `id == that group id`; overrides cascade (the master FK is `ON DELETE
  CASCADE`). Fallback to deleting the single master row when the master has no group id.
- **`following`** (storage.ts:4314-4342): if `occurrenceDate <= master.date`, delete the master. Else
  truncate: set `recurrence_end_date = previous_occurrence(occurrenceDate)`, prune `recurrence_exceptions`
  to `< occurrenceDate`, and delete overrides with `occurrence_date >= occurrenceDate`. **Unlike the single
  and update-following paths, this does NOT require the target occurrence to resolve** — it truncates by
  date even when that date is excepted/soft-deleted (storage.ts:4314-4342 builds no occurrence).
- **`single`** (storage.ts:4344-4399): **soft-delete** the occurrence — upsert an override with
  `is_deleted=True` snapshotting the effective occurrence's fields. (The read slice already skips
  `is_deleted` overrides.)
- All three return **204**. Only **delete-`single`** requires the target occurrence to resolve (a
  non-resolving target → `not_found`); `all` and `following` do not build the occurrence.

**Schema + routes**

- `EventUpdate` gains `recurrence` / `recurrence_end_date` / `recurrence_exceptions` (same validators as
  `EventCreate`; `recurrence`/`recurrence_exceptions` are NOT NULL → an explicit `null` is rejected;
  `recurrence_end_date` is nullable → `null` clears it/open-ended).
- A `sanitize_single_occurrence_updates(data)` helper (service or domain) drops
  `recurrence`/`recurrence_end_date`/`recurrence_exceptions` for the `single` scope.
- `app/api/calendar.py`: `PATCH` + `DELETE` accept `recurrenceScope` (`Query`, optional, validated against
  the scope enum → else `validation_error`) and `occurrenceDate` (`Query`, optional, `YYYY-MM-DD` or
  `validation_error`). `PATCH` → 200 enriched; `DELETE` → 204.

**Cross-cutting**

- Every path tenant-scoped to `sub`; client `userId` ignored. Async, SQLAlchemy 2.0, Pydantic v2, typed
  `AppError` only. `single`/`following` operations run in one transaction (the master update + new-master
  create + override deletes commit together — atomic, an improvement over the legacy's sequential writes).

**Tests** (vs local Docker Postgres)

- **Scope defaults + target date:** PATCH/DELETE on an occurrence id with no `recurrenceScope` → `single`;
  on a master id → `all`; an explicit `recurrenceScope` overrides. An `occurrenceDate` query param
  **overrides** the date parsed from an occurrence id (param-wins precedence).
- **Non-recurring master ignores scope:** `single`/`following` on a non-recurring event update/delete the
  row in place (the plain calendar path), not an error.
- **UPDATE single:** an override is created/updated for the date; the occurrence reflects the change while
  other occurrences don't; the recurrence rule fields are stripped (an override can't change the series);
  editing a non-completion field on a completed series does **not** stamp `completedAt`; toggling
  `completed` on the occurrence does.
- **UPDATE following:** the master's `recurrence_end_date` becomes `previous_occurrence(date)`, future
  exceptions pruned, a new master is created with `recurrence_group_id(new) == recurrence_group_id(original)`
  + the applied rule, and overrides `>= date` are deleted; `occurrenceDate <= master.date` updates the
  master in place.
- **UPDATE all:** the master is updated (incl. the recurrence rule); the date-reset fires only for a *moved*
  occurrence (payload.date == the occurrence's date != master.date); priority recomputed.
- **DELETE single / following / all:** single → an `is_deleted` override (the occurrence disappears from
  expansion); following → master truncated + future overrides gone (and it truncates **even for an
  excepted/soft-deleted target date** — no resolution check); all → the whole group (+ overrides via
  cascade) removed; each → 204.
- **Validation / tenant:** a recurring-master `single`/`following` without a target date → `validation_error`;
  a bad `occurrenceDate` / `recurrenceScope` / `recurrence` value, an explicit `null`
  `recurrence`/`recurrenceExceptions`, or effective `endTime ≤ startTime` on a scoped PATCH →
  `validation_error` (a `null` `recurrenceEndDate` clears it); a non-owned master → `not_found`; a bad
  owned-link on update → `related_record_not_found`.
- Contract test: the PATCH single-occurrence response is the enriched occurrence shape (synthetic id,
  `isRecurringInstance=true`).

# Out of scope

- The legacy `old_logic` child-row handling; `customRecurrence` (read + ignored in the legacy PATCH).
- Google Calendar sync, CRM interaction sync, source columns, AI-agent webhooks, calendar cache (the legacy
  PATCH/DELETE side effects) — not ported.
- Google sync / source-CRM columns, the calendar-init payload, bookings, shared calendars, meeting
  requests, RLS policies, the React UI, ETL. No schema change in this slice (the tables already exist).

# Acceptance criteria

- [ ] `cd superapp/apps/focal/server && make verify` is green (ruff + mypy + pytest); `uv run alembic check`
      shows no drift (this slice adds **no** migration — the recurrence tables already exist).
- [ ] **Scope resolution:** scope defaults from the id (occurrence→`single`, master→`all`) and is overridden
      by `recurrenceScope`; the `occurrenceDate` param wins over the parsed-id date; a non-recurring master
      updates/deletes in place ignoring the scope; a recurring-master `single`/`following` requires a target
      date (tested).
- [ ] **UPDATE `single`** upserts an override (recurrence-rule fields stripped); the occurrence reflects it,
      siblings unchanged; the override's `completedAt` moves only on an explicit `completed` change (prev =
      the override's own / `False`, not the master's) (tested).
- [ ] **UPDATE `following`** splits the series: master `recurrence_end_date = previous_occurrence(date)`,
      future exceptions pruned, a new master with `recurrence_group_id(new) == recurrence_group_id(original)`
      + the applied rule, overrides `>= date` deleted; `date <= master.date` updates the master (tested).
- [ ] **UPDATE `all`** updates the master (incl. the recurrence rule); the date-reset fires only when
      `payload.date == the occurrence's resolved date != master.date`; priority recomputed (tested).
- [ ] **DELETE `single`/`following`/`all`** → soft-delete override / master truncation + future-override
      delete (truncating even for an excepted/soft-deleted target — no resolution check) / group delete
      (overrides cascade); each returns **204** (tested).
- [ ] **Validation/tenant/links:** a recurring-master `single`/`following` without a target date, a bad
      `occurrenceDate`/`recurrenceScope`/`recurrence` value, an explicit-null `recurrence`/
      `recurrenceExceptions`, or effective `endTime ≤ startTime` on a scoped PATCH → `validation_error` (a
      `null` `recurrenceEndDate` clears it); a non-owned master → `not_found`; a bad
      `projectId`/`productId`/`activityId` → `related_record_not_found` (tested).
- [ ] `previous_occurrence` + `recurrence_group_id` are added to `app/domain/recurrence.py` with unit tests
      (incl. the monthly/yearly clamp, e.g. Mar-31 → Feb-28 and Feb-29 → Feb-28; not a strict inverse).
- [ ] Every business error is a typed `AppError` (`{error:{code,message}}`), never a raw `HTTPException`; no
      PII logged (review + grep). The `single`/`following` writes are atomic (one transaction).

# Verification commands

```sh
docker compose -f superapp/apps/focal/docker-compose.yml up -d

cd superapp/apps/focal/server
uv sync --frozen
uv run alembic upgrade head     # no new migration this slice; head is unchanged
make verify
uv run alembic check            # no model/migration drift
```

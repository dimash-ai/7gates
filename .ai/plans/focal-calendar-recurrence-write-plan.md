# Summary

Implement `focal-calendar-recurrence-write` (slice 2 of 2 for recurring events) on the shipped
recurrence-read slice. It makes `PATCH`/`DELETE /api/events/{id}` recurrence-scoped (`single`/`following`/
`all` via `recurrenceScope` + `occurrenceDate` query params): edit/delete one occurrence (override writes,
incl. soft-delete), this-and-following (series split), or the whole series (group delete). **No migration**
— the recurrence columns + `calendar_event_overrides` already exist. Four independently-green slices:
**(1)** domain helpers + scope/target resolution + routes; **(2)** UPDATE scopes + the `EventUpdate`
recurrence rule; **(3)** DELETE scopes; **(4)** tests. Task: [focal-calendar-recurrence-write.md](../tasks/focal-calendar-recurrence-write.md).
Binding contract: legacy `focal/server/storage.ts` (`updateRecurringEventNew` 4025-4264,
`deleteRecurringEventNew` 4266-4400, `resolveRecurringTarget`/`getRecurringMutationScope` 341-371,
`getRecurringGroupId` 311-326, `sanitizeSingleOccurrenceUpdates` 373-383) + `recurrence.ts:43-54`.

## Decisions (design + the Gate-1 rulings)

- **No migration this slice.** The override table + recurrence columns shipped in slice 1; this is service +
  schema + routes only. `alembic check` must stay clean.
- **Domain helpers — `app/domain/recurrence.py`:** add `previous_occurrence(d, recurrence)` (daily −1d,
  weekly −7d, monthly −1mo with month-end clamp `Mar 31 → Feb 28`, yearly −1y `Feb 29 → Feb 28`; port of
  `previousOccurrenceDate`; **not** a strict inverse of `advance_occurrence`) and `recurrence_group_id(*,
  group_id, recurrence, recurring_event_id, event_id)` (port of `getRecurringGroupId`: return the **stored**
  `group_id` if set, else `event_id` when it's a recurring master (`is_recurring_type(recurrence)` and no
  `recurring_event_id`), else `None` — so a second split of an already-split master keeps the original group).
- **Scope + target resolution (service).** Port `resolveRecurringTarget` + `getRecurringMutationScope`:
  `parse_occurrence_event_id(id)` → master id; **target date = `occurrence_date` param ?? parsed-id date**
  (param wins, `storage.ts:349`); scope = `recurrenceScope` ?? (occurrence id → `single`, master id →
  `all`). Load the **owned** master (`_require`-style; `not_found` if missing/non-owned). If the master is
  **non-recurring** (`recurrence == "none"`) or a child (`recurring_event_id` set), do the plain in-place
  update/delete **ignoring the scope** (`storage.ts:4044-4050`). Else recurring → dispatch on the scope; a
  `single`/`following` with no target date → `validation_error`.
- **`EventUpdate` un-defers the recurrence rule (lands in slice 2, with the `all` branch that applies it —
  so slice 1 keeps the existing recurrence-ignored-on-PATCH test green).** Add `recurrence` / `recurrence_end_date` /
  `recurrence_exceptions` (same validators as `EventCreate`; the `model_validator(before)` rejects an
  explicit `null` on `recurrence` and `recurrence_exceptions`; `recurrence_end_date` is nullable → `null`
  clears). `recurrenceScope`/`occurrenceDate` are **not** schema fields — they're `Query` params.
- **`sanitize_single_occurrence_updates(data)`** (service helper) drops `recurrence`/`recurrence_end_date`/
  `recurrence_exceptions` for the `single` scope (an override can't change the rule, `storage.ts:373`).
- **UPDATE `all`** (`storage.ts:4052-4068`): update the master in place via the existing event-update logic,
  refactored into `_apply_event_update(master, data)` (owned-link, effective `endTime>startTime`, completion
  transition, recompute priority, time normalization). **Date-reset:** when a target occurrence date is
  present AND `data["date"]` is set AND `data["date"] == the resolved occurrence's date != master.date`, drop
  `data["date"]` (keep the master's). Returns the enriched master.
- **UPDATE `following`** (`storage.ts:4075-4157`): if `occurrence_date <= master.date`, just
  `_apply_event_update(master, data)`. Else, in one transaction: build the **effective occurrence**
  (`_build_occurrence`; `not_found` if it doesn't resolve); set master `recurrence_end_date =
  previous_occurrence(occurrence_date)` + prune `recurrence_exceptions` to `< occurrence_date`; **create a
  new master** from the effective occurrence merged with `data` — `recurrence` = `data` if a valid type else
  the master's; `recurrence_end_date` by **key-presence** (the payload value when the key is present — an
  explicit `null` clears it / open-ended — else inherit the master's); `recurrence_exceptions = []`; **`recurrence_group_id
  = recurrence_group_id(master)`**; `recurring_event_id=None`; `old_logic=False`; priority computed; delete
  overrides with `occurrence_date >= target`. Returns the enriched new master.
- **UPDATE `single`** (`storage.ts:4159-4264`): build the effective occurrence (`not_found` if None); merge
  `sanitize_single_occurrence_updates(data)` onto it; recompute priority from the merged hierarchy; **completion
  transition only on the explicit `completed`** — `transition_completed_at(prev, data.get("completed"))`
  where `prev` = the existing override's `completed` if one exists else `False` (NOT the master's,
  `storage.ts:4190`). Upsert the override (unique `(recurring_event_id, occurrence_date)`, `is_deleted=False`).
  Returns the enriched **occurrence** (synthetic id) via `_build_occurrence`.
- **DELETE `all`** (`storage.ts:4289-4308`): delete `calendar_events` where **`user_id == sub`** AND
  (`recurrence_group_id == gid OR id == gid`) (`gid = recurrence_group_id(master)`); overrides cascade
  (`ON DELETE CASCADE`); fallback to a single-row delete when `gid` is None. The `user_id == sub` filter is
  load-bearing — a destructive group delete must never touch another tenant's same-group-id rows.
- **DELETE `following`** (`storage.ts:4314-4342`): if `occurrence_date <= master.date`, delete the master.
  Else truncate (master `recurrence_end_date = previous_occurrence`, prune exceptions) + delete overrides
  `>= target`. **No occurrence-resolution check** (truncates by date even for an excepted/soft-deleted
  target).
- **DELETE `single`** (`storage.ts:4344-4399`): build the effective occurrence (`not_found` if None); upsert
  an override with `is_deleted=True` snapshotting its fields.
- **Routes:** `app/api/calendar.py` `PATCH` + `DELETE` gain `recurrence_scope: str | None = Query(None,
  alias="recurrenceScope")` (validated against the scope enum → `validation_error`) and `occurrence_date:
  str | None = Query(None, alias="occurrenceDate")` (`YYYY-MM-DD` or `validation_error`). `PATCH` → 200
  enriched (master or occurrence); `DELETE` → 204.
- Tenant-scoped to `sub` on every path; reuse `_build_occurrence`/`_overrides_map`/`_compute_priority`/
  `_enrich`/`_owned_*`; typed `AppError` only; `single`/`following` writes are atomic (one commit).

# Files to change

| path | change | why |
|------|--------|-----|
| `superapp/apps/focal/server/app/domain/recurrence.py` | modify | add `previous_occurrence` + `recurrence_group_id` |
| `superapp/apps/focal/server/app/schemas/calendar.py` | modify | `EventUpdate` += `recurrence`/`recurrence_end_date`/`recurrence_exceptions` (validators + null-reject for the NOT NULL ones) |
| `superapp/apps/focal/server/app/services/calendar.py` | modify | scope/target resolution; `update_event`/`delete_event` gain `scope`+`occurrence_date` and dispatch `all`/`following`/`single`; `_apply_event_update` (refactor of the in-place path); `_sanitize_single`; override upsert + soft-delete + split + group-delete; reuse existing helpers |
| `superapp/apps/focal/server/app/api/calendar.py` | modify | `PATCH` + `DELETE` accept `recurrenceScope` + `occurrenceDate` `Query` params; pass to the service |
| `superapp/apps/focal/server/tests/test_recurrence_unit.py` | modify | `previous_occurrence` (incl. Mar-31/Feb-29 clamp) + `recurrence_group_id` unit tests |
| `superapp/apps/focal/server/tests/test_calendar_recurrence_db.py` | modify | scoped UPDATE/DELETE DB tests (single/following/all), scope defaults + param precedence, completion-on-override, split + group delete, validation/tenant; **replace** the now-obsolete recurrence-ignored-on-PATCH test (rule now applied via `all`); a cross-tenant same-group-id DELETE-all regression |
| `superapp/apps/focal/server/tests/test_contracts.py` | modify | pin the PATCH single-occurrence enriched response (synthetic id, `isRecurringInstance`) |

# Implementation slices

Each slice is independently reviewable (gate-code → fix loop) and leaves `make verify` green.

1. **Helpers + resolution + routes (existing PATCH/DELETE behavior preserved).** Add `previous_occurrence` +
   `recurrence_group_id` (+ unit tests); add the scope/target resolution + `_sanitize_single`; thread
   `recurrenceScope` + `occurrenceDate` `Query` params through `PATCH`/`DELETE` into
   `update_event`/`delete_event`, defaulting to the in-place path for `all`/non-recurring. **`EventUpdate` is
   NOT extended yet** — recurrence stays out of the schema, so a master PATCH still ignores recurrence and the
   existing `test_patch_recurrence_fields_on_master_are_ignored` stays green. *Verify:* `make verify` +
   `alembic check` green; the existing calendar/recurrence tests pass unchanged; helper unit tests pass.
2. **UPDATE scopes + the recurrence rule on `EventUpdate`.** Refactor the in-place update into
   `_apply_event_update`; add `recurrence`/`recurrence_end_date`/`recurrence_exceptions` to `EventUpdate`
   (validators); implement `all` (applies the rule + date-reset), `following` (split), `single` (override
   upsert + completion semantics, recurrence stripped). **Replace** the now-obsolete
   `test_patch_recurrence_fields_on_master_are_ignored` (a master PATCH is the `all` scope and now *does*
   apply the rule). *Verify:* the UPDATE-scope DB tests pass.
3. **DELETE scopes.** Implement `all` (group delete + cascade), `following` (truncate, no resolution check),
   `single` (soft-delete override). *Verify:* the DELETE-scope DB tests pass.
4. **Contracts + end-to-end.** Pin the PATCH single-occurrence shape; full sweep. *Verify:* `make verify` +
   `alembic upgrade head` (head unchanged) + `alembic check` green end-to-end.

# Tests

- **Scope defaults + target precedence:** occurrence id → `single`, master id → `all`; explicit
  `recurrenceScope` overrides; an `occurrenceDate` param overrides the parsed-id date.
- **Non-recurring master ignores scope:** `single`/`following` on a non-recurring event update/delete in
  place (not an error).
- **UPDATE single:** override created/updated; the occurrence changes, siblings don't; recurrence-rule
  fields stripped; `completedAt` moves only on an explicit `completed` (prev = override's own / `False`).
- **UPDATE following:** master truncated to `previous_occurrence`, future exceptions pruned, new master with
  `recurrence_group_id(new) == recurrence_group_id(original)` + applied rule, overrides `>= date` deleted;
  `date <= master.date` updates the master. **Re-split:** a second `following` split of the already-split
  new master keeps the *original* group id (the stored `recurrence_group_id` wins).
- **UPDATE all:** master updated (rule included); date-reset fires only for a moved occurrence
  (`payload.date == occurrence date != master.date`); priority recomputed.
- **DELETE single/following/all:** soft-delete override / truncate (incl. an excepted/soft-deleted target,
  no resolution check) / group delete (overrides cascade); each → 204. **Cross-tenant:** a second tenant
  owning a row with the same `recurrence_group_id` is untouched by another tenant's DELETE-all.
- **Validation/tenant/links:** recurring-master `single`/`following` w/o a target date, bad
  `occurrenceDate`/`recurrenceScope`/`recurrence`, explicit-null `recurrence`/`recurrenceExceptions`,
  effective `endTime ≤ startTime` → `validation_error` (null `recurrenceEndDate` clears); non-owned master →
  `not_found`; bad owned-link → `related_record_not_found`.
- **Unit:** `previous_occurrence` (daily/weekly + Mar-31→Feb-28 + Feb-29→Feb-28); `recurrence_group_id`
  (stored gid / own-id-for-master / None).
- **Contracts:** PATCH single-occurrence → enriched occurrence shape (synthetic id, `isRecurringInstance`).
- **No-PII / typed-error sweep** (review + grep): no raw `HTTPException`; no token/email logged.

# Error & rescue map

| failure mode | error | caught where | response |
|--------------|-------|--------------|----------|
| Master missing/non-owned; update-single/update-following/delete-single occurrence doesn't resolve | `NotFoundError` | resolution / `_build_occurrence` → None | 404 `not_found` |
| Recurring-master `single`/`following` with no target date; bad `occurrenceDate`/`recurrenceScope`/`recurrence`; explicit-null `recurrence`/`recurrenceExceptions`; effective `endTime ≤ startTime` | `RequestValidationError`/`ValidationError` | route `Query` / schema / service | 422 `validation_error` |
| Bad `projectId`/`productId`/`activityId` on update | `RelatedRecordNotFoundError` | service owned-link | 400 `related_record_not_found` |
| `single`/`following` mid-write failure | exception → rollback (no `AppError` handler covers arbitrary errors — `app/main.py` maps only `AppError` + `RequestValidationError`) | service (one commit) | 500 unhandled; no partial split |

# Review lenses (pre-answer)

- **Scope / strategy.** No new model/migration; extends the calendar service + `EventUpdate` + routes + the
  recurrence domain helpers. Reuses the read slice's `_build_occurrence`/`_overrides_map`/`_compute_priority`/
  `_enrich`. The in-place update is refactored (not duplicated) into `_apply_event_update`, used by `all`,
  the non-recurring path, and the `following` short-circuit.
- **Architecture.** Resolution → dispatch on scope; `single`/`following` writes in one transaction; pure
  date logic stays in the domain util; typed `AppError` throughout; tenant-scoped.
- **Completeness.** All six scope branches + the two short-circuits + the date-reset + the override-
  completion semantics + the delete-following no-resolution rule + param-precedence — each mapped to a test.
- **Tests & verification.** `make verify` green; `alembic check` clean (no migration); helper unit tests +
  scoped DB tests + the contract pin.

# Risks & migrations

- **No migration.** Schema unchanged; `alembic check` must remain clean (guard against accidental model
  edits).
- **Series split correctness** is the highest-risk path (two masters + override pruning, atomic). Covered by
  focused DB tests (the new master's group id, the old master's truncation, the deleted future overrides).
- **Completion-on-override semantics** (prev = override-or-`False`, explicit-only) is subtle; pinned by a
  test that a non-completion edit on a completed series leaves `completedAt` null.
- **No behavior change to the read path or non-recurring CRUD** beyond the new query params (optional,
  default None → existing behavior). The existing suites are the guard.

# Scope check

- [x] Matches the task's Scope and Out of scope (scoped UPDATE/DELETE only; no new schema; Google/CRM/cache
      side effects, RLS, the React UI stay out).
- [x] Small enough to review per slice — 4 sequenced, each green + independently gate-coded.
- [x] Size smell: no new error code, no new model, no migration; one new domain helper pair + service
      branches; `EventUpdate` gains the (already-validated) recurrence rule fields.

# Out of scope

The legacy `old_logic` child-row handling and `customRecurrence`; the PATCH/DELETE side effects (Google
sync, CRM interaction sync, AI-agent webhooks, calendar cache); Google/source-CRM columns; the
calendar-init payload, bookings, shared calendars, meeting requests; RLS; the React UI; ETL.

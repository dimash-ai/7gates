# Goal

Port Focal's **recurring calendar events — the schema, creation, and occurrence expansion (read path)** —
onto the Focal FastAPI backend, faithful to the legacy contract. After this slice a user can create a
recurring master event (`daily`/`weekly`/`monthly`/`yearly`, with an optional end date and per-date
exceptions), and `GET /api/events` / `GET /api/events/:id` expand the series into virtual occurrences within
the date window — applying any per-occurrence **overrides** (including soft-deletes) that exist.

First of **two** slices for Phase 2 step 2 ("Events with recurrence + overrides") in
[MIGRATION_BREAKDOWN.md](../../superapp/apps/focal/docs/MIGRATION_BREAKDOWN.md). It builds directly on the
shipped `focal-calendar-events` (non-recurring) slice. **The recurrence-scoped *mutations* (editing or
deleting a single occurrence, "this-and-following" series splits, group delete) are the SECOND slice
(`focal-calendar-recurrence-write`) and are out of scope here** — this slice is read + schema + create.

> **Binding contract = the legacy source** (`focal/server/storage.ts`, `focal/server/routes.ts`,
> `focal/server/utils/recurrence.ts`, `focal/shared/schema.ts`); cited line numbers are the authority.
> Behavior is **rebuilt idiomatically** (a `app/domain/recurrence.py` util + the calendar service/repo),
> not transliterated, but must match observably (contract + DB tests). Paths are relative to the pipeline
> root; service at `superapp/apps/focal/server`, legacy read-only at `focal/`.

> **Backend-only slice.** No React UI. Responses keep the legacy camelCase names; the enriched event read
> now **adds the recurrence fields** the non-recurring slice deferred: `recurrence`, `recurringEventId`,
> `recurrenceEndDate`, `recurrenceExceptions`, `recurrenceGroupId`, `oldLogic`, plus `occurrenceDate` and
> `isRecurringInstance` on a virtual occurrence.

> **Additive schema change.** Add the six recurrence columns to `calendar_events` and a new
> `calendar_event_overrides` table, via a reviewed `alembic revision --autogenerate` migration (additive
> `add_column` + `create_table`), committed in-slice so `make verify` + `alembic check` run against it.
> Schema changes edit models only; the migration is generated (not hand-authored). Links keep the
> calendar's `ON DELETE SET NULL`; the override→master FK is `ON DELETE CASCADE`. The added recurrence
> columns are nullable/defaulted except `old_logic` (NOT NULL); `calendar_events` is empty pre-prod, so the
> additive NOT NULL add is safe (reviewed).

> **Identity of a virtual occurrence — the load-bearing detail.** A recurring **master** is a row with
> `recurrence ∈ {daily,weekly,monthly,yearly}` and `recurring_event_id IS NULL`. Expansion produces
> **virtual** occurrence objects (not rows) whose synthetic id is `"{masterId}__occurrence__{YYYY-MM-DD}"`
> (legacy `buildOccurrenceEventId`/`parseOccurrenceEventId`, `recurrence.ts:109`-126). `GET /:id` on such an
> id resolves the single occurrence (parse → master + date → build instance). The `:id` path param stays an
> opaque `str` (never coerced).

> **Error envelope (this slice's contract):** typed `AppError` only. `not_found` (404) for `GET /:id` on a
> missing/non-owned master, a non-recurring id that doesn't exist, **or a synthetic occurrence id whose
> master is missing/non-owned/not a recurring master, or whose occurrence is excepted or soft-deleted**.
> Matching legacy (`storage.ts:3807`-3819), the occurrence date is **NOT** validated against the cadence — an
> off-cadence parseable date still builds an instance (not a 404). `validation_error` (422) for an invalid
> `recurrence` value, a malformed `recurrenceEndDate`, or a `recurrenceExceptions` that isn't an array of
> `YYYY-MM-DD` strings. `related_record_not_found` (400) for a bad owned-link (unchanged from the calendar
> slice).

# Scope

**Schema (models + the additive migration)**

- Extend `app/models/calendar.py::CalendarEvent` with the recurrence columns (legacy `schema.ts:302`-308):
  - `recurrence` (String(20), default `"none"`) — `none`/`daily`/`weekly`/`monthly`/`yearly`.
  - `recurring_event_id` (String, nullable) — the parent master id on legacy child rows; **null on a master**.
  - `recurrence_end_date` (Date, nullable) — inclusive upper bound; null = open-ended.
  - `recurrence_exceptions` (JSONB `list[str]`, default `list`) — `YYYY-MM-DD` dates skipped from the series.
  - `recurrence_group_id` (String, nullable) — links a series (set to the master's own id on create).
  - `old_logic` (Boolean, not null, default `False`) — legacy handling flag; the port always writes `False`.
- Add `app/models/calendar.py::CalendarEventOverride` → `focal.calendar_event_overrides` (legacy
  `schema.ts:381`-435): `id` (uuid PK), `recurring_event_id` (String, NOT NULL,
  `ForeignKey("focal.calendar_events.id", ondelete="CASCADE")`, indexed), `occurrence_date` (Date, NOT
  NULL), `is_deleted` (Boolean, NOT NULL, default `False`), **plus the same overridable event fields** as
  `CalendarEvent` (title/date/start_time/end_time/description/location/color/timezone/other_participants;
  priority/priority_score/priority_level/status/completed/completed_at; tags/contact_ids;
  project_id/product_id/activity_id), `created_at`/`updated_at` (TimestampMixin). **Unique
  `(recurring_event_id, occurrence_date)`** (legacy `uidx_calendar_event_overrides_recurring_event_occurrence`).
- Register `CalendarEventOverride` in `app/models/__init__.py`. **Migration:** `uv run alembic revision
  --autogenerate -m "calendar recurrence + overrides"`, review (focal schema, the `add_column`s, the
  `create_table` + unique index + the CASCADE FK), commit; `alembic upgrade head` + `alembic check` clean.
  RLS stays out of scope (app-layer tenant isolation, tested).

**Recurrence domain util — `app/domain/recurrence.py` (port of `focal/server/utils/recurrence.ts`)**

- `RECURRENCE_TYPES = {"daily","weekly","monthly","yearly"}`; `is_recurring_type(value)`.
- `advance_occurrence(d, recurrence)`: `daily`=+1 day, `weekly`=+7 days, `monthly`=+1 month **with
  month-end clamping** (Jan 31 → Feb 28, matching date-fns `addMonths`), `yearly`=+1 year (Feb 29 → Feb 28 on
  non-leap). (`previous_occurrence`, used only by the slice-2 "following" split, is deferred to slice 2.)
- `occurrence_dates_in_range(start, recurrence, window_start, window_end, recurrence_end_date)` — port
  `getOccurrenceDatesInRange` (`recurrence.ts:56`-88): advance from `start` to `window_start`, then collect
  each date `≤ window_end`, bounded by an **inclusive** `recurrence_end_date`. **Exceptions are NOT skipped
  here** (the caller does, faithful).
- `build_occurrence_event_id(master_id, date)` → `"{master_id}__occurrence__{YYYY-MM-DD}"`;
  `parse_occurrence_event_id(id)` → `(master_id, occurrence_date)` or `None` (port `recurrence.ts:96`-126;
  finds the **first** `__occurrence__` marker — tolerant of a double wrapper, matching legacy).

**Create — `POST /api/events` (extend the shipped handler)**

- Accept **only** the recurrence rule: `recurrence` (default `"none"`; must be `none` or a valid recurring
  type → else `validation_error`), `recurrenceEndDate` (calendar date or null), `recurrenceExceptions`
  (array of `YYYY-MM-DD` strings, default `[]`). **`recurringEventId`, `recurrenceGroupId`, and `oldLogic`
  are server-managed and ignored if sent** (`extra="ignore"`; they are not `EventCreate` fields). The server
  sets `recurring_event_id = null` (always a master in this slice), `recurrence_group_id = id` when
  `recurrence` is a recurring type (else null), and `old_logic = False` (legacy `storage.ts:3825`-3826). A
  non-recurring create (`recurrence="none"`) is unchanged. Returns the created enriched event (now including
  the recurrence fields), **HTTP 200**.

**List — `GET /api/events` (extend with expansion)** (`storage.getAllEventsEnriched`, `storage.ts:3701`-3776)

- Query **direct** events for the window: `user_id == sub`, `date` in `[from,to]`, and
  (`recurrence` is null/`"none"` **OR** `recurring_event_id` is not null) — i.e. non-recurring rows and
  legacy child rows.
- Query **master** events: `user_id == sub`, `recurring_event_id` is null, `recurrence in
  (daily,weekly,monthly,yearly)`, `date ≤ to`, and (`recurrence_end_date` is null OR `≥ from`).
- Load the overrides map for those masters within the window (keyed `"{master_id}:{occurrence_date}"`).
- For each master, `occurrence_dates_in_range(...)`, then **build a virtual occurrence** per date:
  - an override with `is_deleted=true` → **skip** the occurrence;
  - no override and the date ∈ `recurrence_exceptions` → **skip**;
  - an override (not deleted) → the occurrence's overridable fields come from the override, the recurrence
    fields from the master; id = the synthetic occurrence id; `recurringEventId = master.id`;
  - no override → master fields with `date = occurrenceDate`; id = the synthetic occurrence id.
  (Port `buildRecurringEventInstance`, `storage.ts:3247`-3314.)
- Combine direct rows + virtual occurrences, enrich each (the existing owned-project resolution), and sort
  **`date` ASC, then `startTime` ASC**. `occurrenceDate` + `isRecurringInstance=true` are set on virtual
  occurrences (non-recurring rows: `occurrenceDate=null`, `isRecurringInstance=false`).

**Get — `GET /api/events/:id`**

- A **plain id** → the stored row (enriched), tenant-scoped, `not_found` if missing/non-owned (unchanged).
- A **synthetic occurrence id** (`parse_occurrence_event_id` matches) → load the owned master, build the
  single occurrence for that date (applying any override / exception / soft-delete). `not_found` if the
  master is missing/non-owned, not a recurring master (`recurrence` non-recurring or `recurring_event_id`
  set), or the occurrence is excepted/soft-deleted. **Matching legacy (`storage.ts:3807`-3819), the date is
  NOT validated against the cadence** — any parseable date builds an instance unless excepted/deleted.

**Enriched read shape**

- Add to `EnrichedEventRead` (and `EventRead`): `recurrence`, `recurring_event_id`, `recurrence_end_date`,
  `recurrence_exceptions`, `recurrence_group_id`, `old_logic`, plus `occurrence_date` (date|null) and
  `is_recurring_instance` (bool, default false) on the enriched read. camelCase via `by_alias`. (These were
  the documented deferred omissions in the non-recurring slice; this slice fills them in.)

**Out of this slice's mutation surface (defer to slice 2)**

- `PATCH`/`DELETE` continue to operate on the **stored row by id** (a master or non-recurring event), as in
  the calendar slice. A `PATCH`/`DELETE` on a **synthetic occurrence id** → `not_found` (it is not a stored
  row; per-occurrence editing is slice 2). **`EventUpdate` does NOT add the recurrence fields in this slice**
  — `recurrence`/`recurrenceEndDate`/`recurrenceExceptions`/`recurringEventId`/`recurrenceGroupId`/`oldLogic`
  are **ignored on PATCH** (`extra="ignore"`); the rule is set at create and editing it is slice 2. PATCH
  still edits the non-recurrence fields of a master/event (title, times, links, …) — on a master that
  affects all its occurrences. The `recurrenceScope`/`occurrenceDate` params, override **writes**, the
  "this-and-following" split, and group delete are **slice 2** (`focal-calendar-recurrence-write`).

**Cross-cutting**

- Tenant-scoped to `sub`; client `userId`/unknown fields ignored. Async, SQLAlchemy 2.0, Pydantic v2, typed
  `AppError` only. Reuse the calendar service's enrichment, owned-link, completion, and time-normalization.

**Tests** (vs local Docker Postgres)

- **Create recurring master** for each `recurrence` type → 200; the row stores `recurrence`,
  `recurrenceGroupId == id`, `oldLogic == false`; the read includes the recurrence fields. A client-supplied
  `recurringEventId`/`recurrenceGroupId`/`oldLogic` on create is **ignored** (server-managed).
- **Expansion** in the window: a `daily`/`weekly`/`monthly`/`yearly` master yields the expected occurrence
  dates; **`recurrenceEndDate` is an inclusive bound**; a `monthly` master starting Jan 31 yields Jan 31,
  **Feb 28, Mar 28, …** (the iterative month-end clamp walks from the previous occurrence, date-fns
  semantics); a `yearly` master starting Feb 29 yields Feb 29 then **Feb 28** in non-leap years.
- **`recurrenceExceptions`** dates are skipped from the expansion; an exception date that **also** has a
  (non-deleted) override is **shown** — the override takes precedence over the exception (legacy
  `storage.ts:3256`).
- **Overrides (seeded via DB, since writes are slice 2):** an override changes that occurrence's fields; an
  `isDeleted` override removes that occurrence; the unique `(recurring_event_id, occurrence_date)` holds.
- **Get by synthetic occurrence id** → the single occurrence (with override applied); an excepted or
  soft-deleted occurrence, or a missing/non-owned/non-recurring master → `not_found`. (An **off-cadence**
  date still builds an instance — matching legacy, not a 404.)
- **List ordering** (`date`, then `startTime`) across mixed direct + recurring occurrences; tenant-scoped.
- **Validation:** invalid `recurrence` value, malformed `recurrenceEndDate`, non-array / non-`YYYY-MM-DD`
  `recurrenceExceptions` → `validation_error`.
- **Mutation boundary:** a `PATCH`/`DELETE` on a synthetic occurrence id → `not_found` (deferred to slice 2);
  a `PATCH` sending `recurrence`/`recurrenceEndDate`/`recurrenceExceptions` on a master **ignores** them
  (the rule is unchanged), while a non-recurrence field still updates.
- Contract test pins the enriched recurrence fields (camelCase) + `occurrenceDate`/`isRecurringInstance`.

# Out of scope

- **Recurrence-scoped mutations (slice 2, `focal-calendar-recurrence-write`):** single-occurrence edit/delete
  (override writes incl. `isDeleted`), the "this-and-following" series split (master `recurrenceEndDate` +
  new master), group delete by `recurrenceGroupId`, and the `recurrenceScope`/`occurrenceDate` params.
- **`old_logic` child-row writing** — the column exists for parity; the port creates only `recurrence`-based
  masters (`old_logic=False`).
- Google Calendar sync, source/CRM columns, the legacy denormalized text `project`/`product`, the calendar
  init payload, bookings, shared calendars, meeting requests, RLS policies, the React UI, ETL.

# Acceptance criteria

- [ ] `cd superapp/apps/focal/server && make verify` is green (ruff + mypy + pytest); any `uv.lock` change is
      committed; `uv run alembic check` shows no model/migration drift (incl. the recurrence add-columns +
      the `calendar_event_overrides` table + unique index + CASCADE FK).
- [ ] **Schema:** `calendar_events` gains the six recurrence columns; `focal.calendar_event_overrides` exists
      with the unique `(recurring_event_id, occurrence_date)` and the `ON DELETE CASCADE` master FK (tested
      via the migration assertion + model).
- [ ] **Create** a recurring master (each type) → 200; `recurrenceGroupId == id`, `oldLogic == false`; the
      enriched read includes `recurrence`/`recurrenceEndDate`/`recurrenceExceptions`/`recurringEventId`/
      `recurrenceGroupId`; a client-supplied `recurringEventId`/`recurrenceGroupId`/`oldLogic` is ignored
      (server-managed) (tested).
- [ ] **Expansion** yields the correct occurrence dates per type within the window; `recurrenceEndDate` is an
      inclusive bound; `monthly` Jan-31 yields Jan-31, Feb-28, Mar-28, … (iterative clamp); `yearly` Feb-29 →
      Feb-28 (non-leap); `recurrenceExceptions` are skipped, but an exception date with a non-deleted
      override is shown (tested).
- [ ] **Overrides:** a seeded (non-deleted) override changes that occurrence; an `isDeleted` override removes
      it; occurrences carry the synthetic id `"{masterId}__occurrence__{date}"`, `occurrenceDate`, and
      `isRecurringInstance=true` (tested).
- [ ] **Get by occurrence id** resolves the single occurrence; an excepted/soft-deleted occurrence or a
      missing/non-owned/non-recurring master → typed `not_found` (404) (an off-cadence date still builds, per
      legacy); a `PATCH`/`DELETE` on an occurrence id → `not_found`, and a `PATCH` of recurrence fields on a
      master is ignored — both deferred to slice 2 (tested).
- [ ] **List** combines direct + expanded occurrences ordered `date` then `startTime`, tenant-scoped; a
      malformed list-query date still falls back to the default window (tested).
- [ ] **Validation:** invalid `recurrence`, malformed `recurrenceEndDate`, non-array/non-date
      `recurrenceExceptions` → typed `validation_error` (422) (tested).
- [ ] Every business error is a typed `AppError` (`{error:{code,message}}`), never a raw `HTTPException`; no
      PII logged (review + grep). No scoped-mutation/override-write/split code is added (that is slice 2).

# Verification commands

```sh
docker compose -f superapp/apps/focal/docker-compose.yml up -d

cd superapp/apps/focal/server
uv sync --frozen
uv run alembic upgrade head     # applies the recurrence add-columns + overrides table
make verify
uv run alembic check            # no drift between models and committed migrations
```

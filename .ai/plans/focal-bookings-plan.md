# Summary

Implement `focal-bookings` (Phase 2 step 4): tenant-scoped CRUD for `focal.bookings` + fold real
bookings into `GET /api/calendar/init`. **No model change, no migration** — the `Booking` model and
the baseline `focal.bookings` table already exist. Task:
[focal-bookings.md](../tasks/focal-bookings.md). Legacy contract: `focal/server/routes.ts:3436-3555`
+ `storage.ts:5105-5175`.

## Decisions (design + the Gate-1 rulings)

- **No migration.** Build schema + service + router + init wiring over the existing
  `app/models/bookings.py`; `alembic check` must stay clean.
- **Denormalized passthrough.** Store/return `project` / `product` / `project_type` (free-form name
  labels) + `tags` verbatim from the client; no read-time resolution (the model keeps these columns
  by design, unlike events/tasks). The `project_id` / `product_id` FKs are validated as owned.
- **Tenant-scoped everywhere (hardening over the leaky legacy).** Every query filters `user_id == sub`;
  by-id get/update/delete return `not_found` for a missing or non-owned id (legacy had no owner check).
- **Owned-link validation.** A non-null `project_id` / `product_id` must be one of the caller's own
  projects (`_owned_project`) → `RelatedRecordNotFoundError` otherwise (mirrors `tasks` / events).
- **Window = strict containment** (`storage.ts:5115`): `start_date >= window_start AND end_date <=
  window_end`, ordered by `start_date`, via the shared `get_date_range` (same defaults/fallback as
  events/tasks). Faithful to legacy (differs from the event overlap window).
- **Schemas (`app/schemas/bookings.py`, own `_Camel`).**
  - `BookingCreate`: `title` (min 1, non-blank), `description?`, `project?`, `project_id?`,
    `project_type?`, `product?`, `product_id?`, `tags?`, `start_date`, `end_date`, `color?` (default
    `#f43f5e`). `start_date`/`end_date` validated `YYYY-MM-DD` (the shared `_validate_date` pattern).
    `source_type`/`source_id` are **not** accepted (server-managed; null for manual bookings).
  - `BookingUpdate`: the mutable set only (`title`, `description`, `project`, `project_id`,
    `project_type`, `product`, `product_id`, `tags`, `start_date`, `end_date`, `color`), all optional;
    a `model_validator(before)` rejects null on `title`/`start_date`/`end_date` (NOT NULL) and a
    blank `title` — the same shape as `EventUpdate._reject_null_on_not_null`; null on a nullable field
    clears it.
  - `BookingRead` (`from_attributes=True`): `id`, `user_id`, `title`, `description`, `start_date`,
    `end_date`, `color`, `project`, `project_type`, `product`, `tags`, `project_id`, `product_id`,
    `source_type`, `source_id`, `created_at`, `updated_at`.
- **Status codes:** `POST` → 200 (`BookingRead`), `DELETE` → 204 (superapp convention).
- **No end-vs-start validation** — the legacy doesn't check it and the approved task doesn't require
  it; bookings store the dates as given (keeps the slice aligned to the task).

# Files to change

| path | change | why |
|------|--------|-----|
| `superapp/apps/focal/server/app/schemas/bookings.py` | add | `BookingCreate` / `BookingUpdate` / `BookingRead` |
| `superapp/apps/focal/server/app/services/bookings.py` | add | `BookingsService` — windowed list + tenant-scoped CRUD + owned-link validation |
| `superapp/apps/focal/server/app/api/bookings.py` | add | `/api/bookings` router (GET list/by-id, POST, PATCH, DELETE) |
| `superapp/apps/focal/server/app/main.py` | modify | register the bookings router |
| `superapp/apps/focal/server/app/schemas/calendar.py` | modify | `CalendarInitRead.bookings: list[Any]` → `list[BookingRead]`; refresh the "not ported" docstring |
| `superapp/apps/focal/server/app/services/calendar_init.py` | modify | add `BookingsService`; `get_init` returns the window's bookings (not `[]`) |
| `superapp/apps/focal/server/tests/test_bookings_db.py` | add | CRUD, window (incl. strict-containment exclusion), tenant, owned-link, PATCH semantics |
| `superapp/apps/focal/server/tests/test_calendar_init_db.py` | modify | bookings now populate the init aggregate |
| `superapp/apps/focal/server/tests/test_contracts.py` | modify | `BookingRead` shape pin; init bookings now a `BookingRead` list |

# Implementation slices

Each leaves `make verify` green.

1. **Schema + service + router.** Add the three schemas; `BookingsService` (list/get/create/update/
   delete + `_require` + `_owned_project`/`_require_owned_link`); the `/api/bookings` router +
   `get_bookings_service` session dependency; register in `app/main.py`. *Verify:* `make verify` +
   `alembic check` green.
2. **Calendar-init wiring.** Switch `CalendarInitRead.bookings` to `list[BookingRead]` and return real
   bookings from `get_init`. *Verify:* init tests green.
3. **Tests.** Booking DB tests + the init/contract updates. *Verify:* full `make verify` green.

# Tests

- **Create/read:** POST stores title/dates/color (default `#f43f5e`)/denormalized names/tags verbatim;
  GET by id returns the camelCase `BookingRead`; `source_type`/`source_id` are null.
- **Window:** a booking fully inside the window is listed (ordered by `start_date`); a booking that
  **starts before `window_start`** AND a separate one that **ends after `window_end`** are both
  excluded (proving *both* halves of strict containment, not just a start-date filter);
  omitted/malformed dates → default range.
- **PATCH:** applies mutable fields + returns `BookingRead`; omitted keys unchanged; explicit null
  clears a nullable field; null-or-blank `title`, or null on `start_date`/`end_date` → 422;
  `userId`/`sourceType`/`sourceId` in the body are ignored (not written).
- **DELETE:** → 204; the booking is gone; a second delete → 404.
- **Tenant:** get/patch/delete of another user's booking → 404; list returns only the caller's.
- **Owned-link:** create/patch with a non-owned `projectId`/`productId` → 400
  `related_record_not_found`; a null link is allowed.
- **Calendar-init:** a created booking appears in `init.bookings` as a `BookingRead`, windowed +
  tenant-scoped identically to `GET /api/bookings`; the contract pins the `BookingRead` shape.

# Error & rescue map

| failure mode | error | caught where | response |
|--------------|-------|--------------|----------|
| Missing/non-owned booking id (get/patch/delete) | `NotFoundError` | `_require` | 404 `not_found` |
| Non-owned `projectId`/`productId` | `RelatedRecordNotFoundError` | `_require_owned_link` | 400 `related_record_not_found` |
| Missing `title`/`startDate`/`endDate` on create; null on a NOT NULL field on patch; bad date | `RequestValidationError`/`ValidationError` | schema | 422 `validation_error` |
| No auth / bad JWT | `AuthRequiredError` | `get_current_user_id` | 401 `auth_required` |

# Review lenses (pre-answer)

- **Scope / strategy.** No model/migration/new error code; one new schema/service/router trio + a
  small calendar-init wiring. Reuses `get_date_range` + the events/tasks owned-link pattern.
- **Architecture.** Tenant-scoped CRUD; denormalized passthrough by model design; typed `AppError`;
  the init aggregate gains a fourth real collection.
- **Completeness.** CRUD + window (incl. exclusion) + tenant + owned-link + PATCH null/immutability +
  init aggregation, each mapped to a test.
- **Tests & verification.** `make verify` green; `alembic check` clean (no migration); contract pins.

# Risks & migrations

- **No migration.** Model + table already exist; `alembic check` must stay clean (guard against an
  accidental model edit).
- **Init contract change.** `bookings` flips from always-`[]` to a real list — the init tests/contract
  are updated in the same slice; only an event-only window still yields `[]` (no bookings created).
- **Strict-containment window** is a deliberate legacy fidelity choice (not overlap) — pinned by an
  exclusion test so it isn't "fixed" by accident.
- **No behavior change** to events/tasks/projects or the calendar-init window math — their suites guard.

# Scope check

- [x] Matches the task's Scope / Out of scope (CRUD + init wiring; no model/migration; denormalized
      passthrough; activity-instance source / cache / shared-calendars / UI stay out).
- [x] Small enough to review per slice — 3 sequenced, each green.
- [x] Size smell: no new model, no migration, no new error code; one schema/service/router trio +
      a two-line init wiring.

# Out of scope

`Booking` model/column changes or migrations; read-time name resolution / orphan detection;
activity-instance auto-creation + the `source_type='activity_instance'` flow (Phase 4); calendar cache
invalidation; shared-calendar bookings; the React UI; ETL.

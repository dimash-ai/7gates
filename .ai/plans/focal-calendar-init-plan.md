# Summary

Implement `focal-calendar-init` (Phase 2 step 3): a single tenant-scoped read aggregate
`GET /api/calendar/init?startDate=&endDate=` returning the window's `events` (recurrence-expanded),
`tasks`, `bookings` (`[]`, deferred to step 4), and `projects`. It is **pure composition** over three
already-shipped services — no new query/enrichment logic, no model, no migration. Task:
[focal-calendar-init.md](../tasks/focal-calendar-init.md). Legacy contract: `focal/server/routes.ts:4284`
(`Promise.all` of `getAllEventsEnriched` + `getAllTasksEnriched` + `getAllBookings` + `getAllProjects`).

## Decisions (design + the Gate-1 rulings)

- **Composition over three services, one session.** A new `CalendarInitService(session)` instantiates
  `CalendarService` / `TasksService` / `ProjectsService` on the **same** session and calls their existing
  list methods. The recurrence expansion, priority, orphan resolution, and date-windowing already live in
  those services and are reused verbatim — nothing is re-queried or re-enriched here. (Sequential awaits,
  not the legacy's `Promise.all`: a single async SQLAlchemy session can't run concurrent queries.)
- **Full typed objects, no pruning (Gate-1 ruling, APPROVED).** Returns full `EnrichedEventRead` /
  `EnrichedTaskRead` / `ProjectRead`, not the legacy's hand-pruned dicts or 7-field light projects. Honors
  the "Pydantic models for all I/O" rule + `gen:api`; matches the shipped mindmap-init aggregate. Payload
  micro-opt deferred.
- **`bookings = []` (deferred).** Bookings are Phase 2 step 4. The key is always present, typed
  `list[Any]`, mirroring `app/schemas/mindmap.py` `InitRead.activities: list[Any]`. Wired to the bookings
  service when step 4 lands (expand → contract).
- **Tenant from JWT `sub`.** `get_current_user_id` dependency; the endpoint takes **no** `userId` query
  param (the legacy did; the superapp never trusts a client-supplied user id).
- **Date window** via `startDate`/`endDate` + the `current_utc_date` dependency, threaded into
  `list_events` / `list_tasks` so init and the per-collection endpoints share the same `get_date_range`
  window + defaults. `list_projects` is not windowed (the user's full project list, as in legacy).
- **No model, no migration, no caching.** `alembic check` stays clean.

# Files to change

| path | change | why |
|------|--------|-----|
| `superapp/apps/focal/server/app/schemas/calendar.py` | modify | add `CalendarInitRead` (imports `EnrichedTaskRead`, `ProjectRead`; `bookings: list[Any]`) |
| `superapp/apps/focal/server/app/services/calendar_init.py` | add | `CalendarInitService` — composes the three services on one session |
| `superapp/apps/focal/server/app/api/calendar_init.py` | add | thin `/api/calendar` router with `GET /init` + the session-backed service dependency |
| `superapp/apps/focal/server/app/main.py` | modify | register the new router |
| `superapp/apps/focal/server/tests/test_calendar_init_db.py` | add | aggregate shape, window, recurrence expansion, null-due-date tasks, tenant isolation, malformed-date fallback |
| `superapp/apps/focal/server/tests/test_contracts.py` | modify | pin the camelCase aggregate shape (four keys + `bookings == []`) |

## Decisions on placement

- `CalendarInitRead` lives in `app/schemas/calendar.py` (the calendar-view aggregate's domain), importing
  `EnrichedTaskRead` (`app/schemas/tasks`) + `ProjectRead` (`app/schemas/projects`) — the same cross-schema
  import the shipped `InitRead` already does. Confirm no import cycle (neither tasks nor projects schema
  imports calendar).
- The init router is its own file (`app/api/calendar_init.py`, prefix `/api/calendar`), keeping the events
  router (`app/api/calendar.py`, prefix `/api/events`) focused. The service is its own file because the
  data spans three domains and belongs to none of the existing single-domain services.

# Implementation slices

Each leaves `make verify` green.

1. **Schema + service + router.** Add `CalendarInitRead`; `CalendarInitService.get_init` composing
   `list_events` / `list_tasks` / `list_projects` + `bookings=[]`; the `/api/calendar` router with
   `GET /init` (+ a `get_calendar_init_service` session dependency); register it in `app/main.py`.
   *Verify:* `make verify` + `alembic check` green; existing suites unchanged.
2. **Tests.** DB integration tests + the contract pin (below). *Verify:* full `make verify` green.

# Tests

- **Shape:** `GET /api/calendar/init` → 200 with exactly the keys `events`, `tasks`, `bookings`,
  `projects`; `bookings == []`.
- **Events = recurrence-expanded:** a recurring master appears in `events` as its in-window occurrences
  (same as `GET /api/events`), confirming the reuse of `list_events`.
- **Tasks:** a windowed task and a null-due-date task both appear (reuse of `list_tasks`).
- **Projects:** the caller's projects appear with the full `ProjectRead` shape (not a light projection).
- **Window:** `startDate`/`endDate` bound the events/tasks; omitted → default range; a malformed
  `startDate` falls back to the default range (no 500), matching `GET /api/events`.
- **Tenant isolation:** a second user's events/tasks/projects never appear in the caller's init.
- **Contract:** the four camelCase keys, `bookings == []`, and an init event asserts the **full**
  `EnrichedEventRead` key set (mirroring the `/api/events` contract pin) — directly proving no pruning
  rather than leaning only on response-model typing.

# Error & rescue map

| failure mode | error | caught where | response |
|--------------|-------|--------------|----------|
| Malformed/partial `startDate`/`endDate` | none — `get_date_range` falls back to the default window | service (reused) | 200 with the default range |
| No auth / bad JWT | `AuthRequiredError` | `get_current_user_id` dependency | 401 `auth_required` |
| DB unavailable mid-aggregate | exception → rollback | session context | 500 (unhandled; read-only, no partial write) |

# Review lenses (pre-answer)

- **Scope / strategy.** One read endpoint; zero new domain logic — composition of shipped services.
  No model, no migration, no new error code. The only genuinely new code is the 4-field response schema,
  a ~10-line service, and a thin router.
- **Architecture.** Aggregator service over one shared session; tenant-scoped via the JWT; typed response
  model; deferred domain (`bookings`) as an empty typed list per the mindmap-init precedent.
- **Completeness.** Window defaults + malformed-date fallback, recurrence expansion reuse, null-due-date
  tasks, tenant isolation, and the deferred-bookings placeholder each map to a test.
- **Tests & verification.** `make verify` green; `alembic check` clean (no migration); contract pin.

# Risks & migrations

- **No migration.** Read-only aggregate over migrated tables; `alembic check` must stay clean.
- **Import cycle risk** from `CalendarInitRead` importing task/project schemas into `calendar.py` — checked
  against the existing mindmap precedent; verify at implementation.
- **`bookings` placeholder** is a known temporary `[]` until step 4; the contract test pins it so the
  step-4 wiring is a deliberate, reviewed change.
- **No behavior change** to `/api/events`, `/api/tasks`, `/api/projects` — they are only read; their suites
  are the guard.

# Scope check

- [x] Matches the task's Scope / Out of scope (one read aggregate; bookings deferred; no pruning; no new
      model/migration; shared-calendar / Google / CRM / UI stay out).
- [x] Small enough to review in one pass — 2 sequenced slices, each green.
- [x] Size smell: no new model, no migration, no new error code; one schema + one tiny service + one thin
      router + tests.

# Out of scope

The bookings domain/data (step 4), the legacy empty-field pruning + light-projects projection, response
caching, the diagnostic size log, shared calendars, Google integration, CRM/contacts, meeting requests,
the React calendar UI, ETL.

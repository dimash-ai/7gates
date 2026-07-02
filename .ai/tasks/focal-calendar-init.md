# Goal

Port the calendar bootstrap aggregate `GET /api/calendar/init` (Phase 2 step 3) so the calendar view
loads all of its data in **one** request instead of four. It returns the window's events (recurrence-
expanded), tasks, bookings, and the user's projects in a single tenant-scoped payload.

# Scope

- New endpoint **`GET /api/calendar/init`** (legacy `routes.ts:4284`) with optional `startDate` /
  `endDate` (`YYYY-MM-DD`) query params. A new `/api/calendar`-prefixed router; the user is the JWT
  `sub` (the superapp tenant rule — **never** a client-supplied `userId`, unlike the legacy query param).
- A typed `CalendarInitRead` response aggregating four lists:
  - `events` — the window's recurrence-expanded, enriched events (reuse `CalendarService.list_events`).
  - `tasks` — the window's enriched tasks, including null-due-date tasks (reuse `TasksService.list_tasks`).
  - `projects` — the user's projects (reuse `ProjectsService.list_projects`).
  - `bookings` — **`[]`** (empty): the bookings domain is Phase 2 step 4 and isn't ported yet. This
    mirrors the shipped mindmap-init aggregate, which returns `activities: []` for its not-yet-ported
    domain (`app/schemas/mindmap.py` `InitRead.activities: list[Any]`). The key is always present so the
    client can iterate it; it gets wired to the bookings service when step 4 lands (expand → contract).
- Pure **composition over the three existing services** on one shared session — no new query/enrichment
  logic, no duplication of the recurrence/priority/orphan resolution that already lives in those services.
- Date window via `startDate`/`endDate` + `current_utc_date` (same `get_date_range` defaults as
  `list_events` / `list_tasks`), so init and the per-collection endpoints agree on the window.

# Decisions (design rulings to confirm at Gate 1)

- **Full typed objects, no field-pruning.** The legacy handler hand-prunes empty/null/empty-string/
  empty-array optional fields and sends a 7-field "light" projects projection to shrink the payload. This
  port returns the full typed `EnrichedEventRead` / `EnrichedTaskRead` / `ProjectRead` objects instead.
  Rationale: the monorepo rule is "Pydantic models for all I/O" (a dict-pruned response is untyped and
  breaks `gen:api`); the shipped mindmap-init aggregate already returns full typed objects; the React
  client is being rewritten against the new typed contract and reads fields by name (absent vs null is
  indistinguishable to it). The payload micro-optimization is deferred — revisit only if a real payload-
  size problem is measured.
- **No new model, no migration.** This is a read-only aggregate over already-migrated tables; `alembic
  check` must stay clean.
- **No caching.** The legacy comment mentions a cache but the code only logs the response size and
  returns; there is nothing to port.

# Out of scope

- The bookings domain itself (models/CRUD/data) — Phase 2 step 4. Here `bookings` is an empty list.
- The legacy empty-field pruning and the light-projects projection (see Decisions).
- Any response caching, the `[calendar/init] size=...` diagnostic log line.
- Shared calendars, Google integration, CRM/contacts, meeting requests, the React calendar UI, ETL.
- Any change to `/api/events`, `/api/tasks`, `/api/projects` or their services beyond reuse.

# Acceptance criteria

- [ ] `GET /api/calendar/init` returns `200` with a camelCase body containing exactly the keys
      `events`, `tasks`, `bookings`, `projects` (all four always present).
- [ ] `events` are the recurrence-expanded enriched events within the window and `tasks` are the enriched
      tasks within the window (null-due-date tasks included), matching what `GET /api/events` and
      `GET /api/tasks` return for the same window.
- [ ] `projects` is the caller's project list; `bookings` is `[]`.
- [ ] Entities carry the **full typed shape** (not legacy-pruned / light projections): an event has the
      complete `EnrichedEventRead` field set (empty fields present as null, not omitted) and a project has
      the complete `ProjectRead` field set (not the 7-field light projection).
- [ ] The window honors `startDate`/`endDate`; when omitted — or malformed/partial — the shared
      `get_date_range` default range applies (no 500), matching `GET /api/events` / `GET /api/tasks`.
- [ ] Tenant isolation: only the caller's (JWT `sub`) data is returned; a second user's events/tasks/
      projects never leak; the endpoint takes no `userId` query param.
- [ ] Typed `AppError` only — no raw `HTTPException`; no PII/token logged.
- [ ] `make verify` is green and `alembic check` reports no new operations (no model/migration change).
- [ ] A contract test pins the aggregate shape (the four camelCase keys + `bookings == []`).

# Verification commands

```sh
make verify
DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev uv run --frozen alembic check
```

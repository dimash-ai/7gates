# Goal

The filtered shared-calendar events read (Phase 2 step 5, slice 4 of 4 — completing the
shared-calendars sub-program): `GET /api/shared-calendars/{id}/events` returns the **owner's**
recurrence-expanded, enriched events for the window, filtered by the calendar's
`filter_type`/`filter_value`/`filter_rules`, to any viewer+ participant — **enforcing the access the
legacy left commented out**.

# Scope

- **`app/domain/shared_calendar_filter.py`** — a pure `apply_shared_calendar_filter(events, *,
  filter_type, filter_value, filter_rules)` (port of `applySharedCalendarFilter`, routes.ts:224),
  generic over an event with `is_work_time` / `sphere` / `project_id` / `product_id` / `project_type`:
  - `all` (and any unknown type) → all events.
  - `isWorkTime` → `event.is_work_time == (filter_value == "true")`.
  - `sphere` / `project` / `product` / `projectType` → `event.sphere` / `project_id` / `product_id` /
    `project_type == filter_value`.
  - `custom` → `filter_rules.conditions` (each `field` ∈ camelCase
    `isWorkTime`/`sphere`/`projectId`/`productId`/`projectType`, `operator` ∈ `eq`/`neq`/`in`/`nin`,
    `value`) combined by `filter_rules.logic` (`and` → all match via `all()`; `or` → any match via
    `any()`, so **empty** conditions give `and` → all events, `or` → no events, matching the legacy
    `every`/`some`). An unknown field/operator makes that condition pass (faithful). `filter_rules`
    absent → all events.
- **`SharedCalendarsService.list_events(user_id, calendar_id, *, start, end, today)`**:
  `_resolve_access(viewer)` → (calendar, role); fetch the **owner's** events via
  `CalendarService(self.session).list_events(calendar.user_id, start=, end=, today=)` (the existing
  recurrence-expanded + enriched, windowed list); return `apply_shared_calendar_filter(...)`.
- **Route** `GET /api/shared-calendars/{calendar_id}/events?startDate=&endDate=` → `require viewer`;
  response `list[EnrichedEventRead]`. Added to the existing `/api/shared-calendars` router.

# Decisions (design rulings to confirm at Gate 1)

- **Events come from the OWNER** (`calendar.user_id`), not the requester — a viewer+ participant reads
  the owner's filtered events. This is the RBAC-gated **cross-tenant** read the shared calendar exists
  for; `_resolve_access(viewer)` is the gate (404 missing / 403 non-participant).
- **Reuse `CalendarService.list_events`** (recurrence expansion + enrichment + the shared
  `get_date_range` window) — the filter operates on the enriched `is_work_time`/`sphere`/`project_id`/
  `product_id`/`project_type` fields. No re-implementation of event fetching.
- **The filter is uniform** — it does not vary by the participant's role. The "developer sees other
  pages" notion is the frontend `canViewOtherPages` flag (already on `my-role`), **not** a backend
  event-scope difference; the legacy `/events` applies the calendar filter to everyone.
- **Pure filter helper** (generic over a small Protocol) so it's unit-testable without a DB; faithful
  unknown-field/operator → condition passes.
- **No migration**; typed `AppError` only; tenant/access from the JWT `sub` (no `userId` query).

# Out of scope

- Per-role event scoping (a frontend `canViewOtherPages` concern, not backend); Google sync (Phase 3);
  writing events through the shared calendar; RLS; the React UI; ETL. This is the **last** slice of the
  shared-calendars sub-program (Phase 2 step 5).

# Acceptance criteria

- [ ] `GET /{id}/events` returns the **owner's** window events (recurrence-expanded + enriched),
      filtered by the calendar; a viewer+ participant (and the owner) get 200; a non-participant → 403;
      a missing calendar → 404.
- [ ] `filter_type="all"` (and an unknown filter type) returns every owner event; `isWorkTime`/
      `sphere`/`project`/`product`/`projectType` each return only the matching subset; `custom` honors
      `and`/`or` over its conditions (`eq`/`neq`/`in`/`nin`), an unknown field/operator leaves that
      condition passing, and empty conditions give `and` → all / `or` → none.
- [ ] A pending/declined participant (not accepted) → 403 on `/events` (the accepted-gated access).
- [ ] A recurring master in the owner's calendar appears as its in-window occurrences in the result
      (proving the `list_events` reuse), and a non-matching event is excluded by a non-`all` filter.
- [ ] The result is the same `EnrichedEventRead` camelCase shape as `GET /api/events`; the window
      honors `startDate`/`endDate` (default/fallback via `get_date_range`).
- [ ] `make verify` green; `alembic check` clean (no migration); the filter helper has unit tests
      covering every filter type incl. `custom` and/or + unknown field.

# Verification commands

```sh
make verify
DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev uv run --frozen alembic check
```

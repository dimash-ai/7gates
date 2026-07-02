# Summary

Implement `focal-shared-calendars-events` (Phase 2 step 5, slice 4 of 4 — completes the sub-program):
a pure filter engine + `GET /api/shared-calendars/{id}/events` returning the **owner's** recurrence-
expanded enriched events, filtered by the calendar, to any viewer+ participant. No migration. Task:
[focal-shared-calendars-events.md](../tasks/focal-shared-calendars-events.md). Legacy:
`routes.ts:224` (filter) + `:7974` (route).

## Decisions (design + the Gate-1 rulings)

- **`app/domain/shared_calendar_filter.py`** — a pure, DB-free helper:
  ```
  class FilterableEvent(Protocol):
      is_work_time: bool
      sphere: str | None
      project_id: str | None
      product_id: str | None
      project_type: str | None

  def apply_shared_calendar_filter[E: FilterableEvent](
      events: list[E], *, filter_type: str, filter_value: str | None,
      filter_rules: dict[str, Any] | None,
  ) -> list[E]: ...
  ```
  - `all` / unknown type → `events`.
  - `isWorkTime` → `e.is_work_time == (filter_value == "true")`.
  - `sphere`/`project`/`product`/`projectType` → `e.sphere`/`project_id`/`product_id`/`project_type
    == filter_value`.
  - `custom` → `None`/absent rules → `events`; else for each event evaluate `rules["conditions"]`
    (`_FIELD_MAP` maps camelCase `isWorkTime`/`sphere`/`projectId`/`productId`/`projectType` →
    the snake attr; unknown field → condition `True`), operator `eq`/`neq`/`in`/`nin` (unknown → `True`),
    combine with `all(...)` for `logic == "and"` else `any(...)`. `_FIELD_MAP` + an operator dispatch.
- **`SharedCalendarsService.list_events(user_id, calendar_id, *, start, end, today)`**:
  `_resolve_access(viewer)` → (calendar, _); `events = CalendarService(self.session).list_events(
  calendar.user_id, start=start, end=end, today=today)`; `return apply_shared_calendar_filter(events,
  filter_type=calendar.filter_type, filter_value=calendar.filter_value,
  filter_rules=calendar.filter_rules)`. The events are the OWNER's (cross-tenant share, gated by viewer).
- **Route** (extend `app/api/shared_calendars.py`): `GET /{calendar_id}/events` with `startDate`/
  `endDate` `Query` (str) + `current_utc_date`; `response_model=list[EnrichedEventRead]`; viewer-gated.
- **No migration**; reuse `CalendarService` (import it into the shared-calendars service);
  `EnrichedEventRead` satisfies the `FilterableEvent` protocol (it has all five attrs).

# Files to change

| path | change | why |
|------|--------|-----|
| `superapp/apps/focal/server/app/domain/shared_calendar_filter.py` | add | the pure filter engine |
| `superapp/apps/focal/server/app/services/shared_calendars.py` | modify | `list_events` (compose `_resolve_access` + `CalendarService.list_events` + the filter) |
| `superapp/apps/focal/server/app/api/shared_calendars.py` | modify | `GET /{calendar_id}/events` route |
| `superapp/apps/focal/server/tests/test_shared_calendar_filter.py` | add | unit tests for every filter type incl. custom and/or + unknown field + empty conditions |
| `superapp/apps/focal/server/tests/test_shared_calendar_events_db.py` | add | the route: owner-event sourcing, viewer/404/403, recurrence, filter end-to-end |
| `superapp/apps/focal/server/tests/test_contracts.py` | modify | pin the `/events` item shape == `EnrichedEventRead` |

# Implementation slices

1. **Filter engine.** The domain helper + unit tests. *Verify:* unit tests + ruff/mypy.
2. **Service + route.** `list_events` + the route. *Verify:* `make verify` + `alembic check`.
3. **Tests.** The DB route tests + the contract pin. *Verify:* full `make verify`.

# Tests

- **Filter unit (`FilterableEvent` stub or `EnrichedEventRead`):** `all`/unknown-type → all;
  `isWorkTime` true/false; `sphere`/`project`/`product`/`projectType` subset; `custom` `and` (all
  conditions), `or` (any), each of `eq`/`neq`/`in`/`nin`, a `projectId`/`productId` condition (proving
  the camelCase→snake field mapping), unknown field → passes, **unknown operator → passes**, empty
  conditions (`and` → all, `or` → none), absent `filter_rules` → all.
- **Route (DB):** owner creates a calendar + events; **the owner (200)** and a viewer+ participant
  (200) get the owner's events filtered by the calendar; a recurring master appears as occurrences; a
  non-`all` filter excludes non-matching events; a non-participant → 403; **a pending/declined
  participant → 403**; missing calendar → 404; window honored.
- **Cross-tenant:** the requester sees the OWNER's events (not their own), proving the share.
- **Contract:** an `/events` item has the full `EnrichedEventRead` key set.

# Error & rescue map

| failure mode | error | response |
|--------------|-------|----------|
| Missing calendar | `NotFoundError` | 404 |
| Non-participant / pending (not accepted) | `PermissionDeniedError` | 403 |
| Malformed `startDate`/`endDate` | none — `get_date_range` falls back | 200, default window |

# Review lenses (pre-answer)

- **Scope / strategy.** One pure helper + one route composing existing pieces (`_resolve_access`,
  `CalendarService.list_events`). No model/migration/new error code.
- **Architecture.** Owner-event source gated by viewer access (cross-tenant share); pure filter (unit-
  testable); uniform across roles.
- **Completeness.** Every filter branch + the access matrix + recurrence + cross-tenant + window each
  map to a test.
- **Tests & verification.** `make verify` green; `alembic check` clean; filter unit tests + the route
  DB tests + the contract pin.

# Risks & migrations

- **No migration** — `alembic check` stays clean.
- **Cross-tenant read** is the security-sensitive bit (a participant reads the owner's events) — gated
  by `_resolve_access(viewer)` (accepted-only) + the calendar filter; pinned by the access-matrix +
  cross-tenant tests.
- **Filter fidelity** (custom and/or, unknown field/operator, empty conditions) is the subtle logic —
  isolated in the pure helper with direct unit tests.
- **No behavior change** to `/api/events` or the slice-2/3 routes; their suites guard.

# Scope check

- [x] Matches the task (one read route + filter engine; per-role scope/Google/RLS/UI out).
- [x] 3 sequenced slices, each green.
- [x] Size: one domain helper + one service method + one route + tests; no migration/new error code.

# Out of scope

Per-role event scoping (frontend `canViewOtherPages`); Google sync (Phase 3); writing events via the
shared calendar; RLS; the React UI; ETL. Last slice of the shared-calendars sub-program.

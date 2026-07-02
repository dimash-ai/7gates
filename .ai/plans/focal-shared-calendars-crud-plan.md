# Summary

Implement `focal-shared-calendars-crud` (Phase 2 step 5, slice 2 of 4): the `/api/shared-calendars`
CRUD + caller-view routes over the slice-1 `rbac` foundation, **applying the RBAC enforcement the
legacy left commented out**. No new migration. Task:
[focal-shared-calendars-crud.md](../tasks/focal-shared-calendars-crud.md). Legacy:
`routes.ts:7426-7645`/`:7920`, `storage.ts:6389`/`:6563`/`:6539`.

## Decisions (design + the Gate-1 rulings)

- **`get_resource_role` (rbac.py) gains an `invite_status == "accepted"` filter** — resolves the
  slice-1 carry-forward (a pending invite with `user_id` must not pass). Update slice-1
  `tests/test_rbac_db.py`: `_seed_participant` seeds `accepted`; add a pending-denied case.
- **`SharedCalendarsService`** (one session):
  - `_resolve_access(user_id, calendar_id, minimum) -> (SharedCalendar, role)`: load the calendar
    (`NotFoundError` 404 if missing); `role = "owner"` when `calendar.user_id == user_id`, else
    `await get_resource_role(...)` (accepted participant); raise `PermissionDeniedError` (403) when
    `role is None or ROLE_RANK.get(role, -1) < ROLE_RANK[minimum]`; return `(calendar, role)`.
  - `list_owned(user_id)` → `where user_id == sub` (order by `created_at`).
  - `list_accessible(user_id)` → owned ∪ accepted-participant calendars; for each, look up **the
    caller's own** participant row → `participant_role`/`invite_status` (the owner has an accepted
    `owner` row, so this is correct + deterministic, never an arbitrary joined row) + a
    `participants_count` (count of **all** rows for that calendar).
  - `my_participation(user_id)` → accepted, non-owner participations → items `{calendar, role,
    isOwner=False}` + `is_only_participant` + `own_calendars_count`.
  - `create(user_id, payload)` → generate the calendar `id` explicitly (`str(uuid4())`) so the owner
    participant's `shared_calendar_id` references it (there's no ORM relationship to propagate it),
    add the `SharedCalendar` **and** a `SharedCalendarParticipant` (`role="owner"`,
    `invite_status="accepted"`) → **one commit** (atomic) → `SharedCalendarRead`.
  - `get` / `update` / `delete` / `my_role` → `_resolve_access(viewer|owner)`; update applies the
    `SharedCalendarUpdate` fields; delete cascades participants (FK).
- **Schemas** (`app/schemas/shared_calendar.py`, own `_Camel`): `SharedCalendarCreate` (name min 1 +
  non-blank; `filter_type` default `"all"`; `color` default `#3b82f6`; `is_active` default `True`;
  no `user_id`/`sync_settings`; explicit null on `filter_type`/`color`/`is_active` coalesces to the
  default, legacy `x || default`), `SharedCalendarUpdate` (all-optional mutable set: name/filter_type/
  filter_value/filter_rules/google_calendar_id/color/is_active; reject null on `name` (also blank) and
  on `filter_type` — both NOT NULL columns),
  `SharedCalendarRead` (full row incl. `sync_settings`), `AccessibleSharedCalendarRead`(+`participants_count`,
  `participant_role`, `invite_status`), `MyParticipationItem`/`MyParticipationRead`, `MyRoleRead`
  (`role`, `is_owner`, `can_edit`, `can_view_other_pages`).
- **`my_role` flags** (port routes.ts:7952): `can_edit = role in {full_access, editor}`;
  `can_view_other_pages = role in {owner, full_access, developer}`; owner → all `True`.
- **Enforcement:** read (`get`/`my_role`) = `viewer`; calendar-config `update` + `delete` = `owner`
  (the legacy commented intent); `create` = any authed user; list/accessible/my-participation are
  caller-scoped (no per-calendar check). Tenant = JWT `sub` throughout.
- **Routes** (`app/api/shared_calendars.py`, prefix `/api/shared-calendars`): declare `/accessible`
  + `/my-participation` **before** `/{id}`; `/{id}/my-role` nested. Register in `app/main.py`.
  `POST` → 200, `DELETE` → 204. No migration.

# Files to change

| path | change | why |
|------|--------|-----|
| `superapp/apps/focal/server/app/rbac.py` | modify | `get_resource_role` gates on `invite_status="accepted"` |
| `superapp/apps/focal/server/app/schemas/shared_calendar.py` | add | the 6 schemas |
| `superapp/apps/focal/server/app/services/shared_calendars.py` | add | `SharedCalendarsService` + `_resolve_access` |
| `superapp/apps/focal/server/app/api/shared_calendars.py` | add | the 8 routes |
| `superapp/apps/focal/server/app/main.py` | modify | register the router |
| `superapp/apps/focal/server/tests/test_shared_calendars_db.py` | add | CRUD + caller-view + enforcement + accepted-gating + route-order |
| `superapp/apps/focal/server/tests/test_rbac_db.py` | modify | seed `accepted`; add a pending-denied case |
| `superapp/apps/focal/server/tests/test_contracts.py` | modify | pin `SharedCalendarRead` + accessible/my-role shapes |

# Implementation slices

Each leaves `make verify` green.

1. **rbac accepted-gating + schemas.** `get_resource_role` filter + update slice-1 tests; add the
   schemas. *Verify:* rbac tests green.
2. **Service + routes.** `SharedCalendarsService` + the router + `app/main.py`. *Verify:* `make verify`
   + `alembic check` green.
3. **Tests.** CRUD/caller-view/enforcement DB tests + the contract pins. *Verify:* full `make verify`.

# Tests

- **Create:** `POST` returns `SharedCalendarRead`; the owner immediately resolves to `owner` (via
  `my_role` and `get`); the owner participant row exists (`accepted`).
- **Enforcement:** owner + accepted participant can `GET`/`my_role` (`viewer`); a non-participant →
  403; a missing id → 404. `PUT`/`DELETE` by a non-owner participant → 403; by a stranger → 403;
  missing → 404; `DELETE` → 204 and the participants are gone (cascade).
- **Accepted-gating:** a **pending** participant (status `pending`, `user_id` set) is denied `GET`/
  `my_role` (403) and excluded from `accessible`/`my-participation`.
- **accessible:** owned + participant calendars returned; an owned calendar **with another
  participant** still reports the **caller's** `participant_role="owner"`/`invite_status="accepted"`
  (not the other participant's) + the correct `participants_count` (all rows).
- **my-participation:** only accepted non-owner participations; items carry `role` + `isOwner=False`;
  `isOnlyParticipant`/`ownCalendarsCount` correct.
- **my-role flags (parameterized over all 6 roles):** owner → all true; full_access →
  `canEdit=True`,`canViewOtherPages=True`; editor → `canEdit=True`,`canViewOtherPages=False`;
  developer → `canEdit=False`,`canViewOtherPages=True`; viewer + requester → both false.
- **Update:** applies fields, returns the updated read; null on `name`/`filter_type` → 422; tenant —
  another user's calendar → 404/403.
- **Route order:** `GET /accessible` + `/my-participation` resolve to their handlers (not `/{id}`).
- **Tenant + camelCase:** list/accessible return only the caller's; responses camelCase (contract pin).

# Error & rescue map

| failure mode | error | caught where | response |
|--------------|-------|--------------|----------|
| Missing calendar (get/put/delete/my-role) | `NotFoundError` | `_resolve_access` | 404 `not_found` |
| Existing calendar, role below `minimum` (incl. pending/non-participant) | `PermissionDeniedError` | `_resolve_access` | 403 `permission_denied` |
| Missing/blank `name` on create; null on a NOT NULL update field | `RequestValidationError`/`ValidationError` | schema | 422 `validation_error` |
| No auth | `AuthRequiredError` | `get_current_user_id` | 401 `auth_required` |

# Review lenses (pre-answer)

- **Scope / strategy.** One router + service + schemas over slice-1's rbac/models; no migration, no new
  error code. Reuses `get_resource_role`/`ROLE_RANK`/`PermissionDeniedError`/`NotFoundError`.
- **Architecture.** Service-level `_resolve_access` gives 404-vs-403 + the calendar object; owner via
  `calendar.user_id`; accepted-only participants; atomic create; route ordering.
- **Completeness.** Every route + the enforcement matrix + the accepted-gating + the accessible
  caller-role correctness + my-role flags + route order each map to a test.
- **Tests & verification.** `make verify` green; `alembic check` clean (no migration); contract pins.

# Risks & migrations

- **No migration** — slice-1 tables; `alembic check` must stay clean.
- **rbac change** (accepted filter) touches slice-1's module — the slice-1 tests are updated in lockstep
  (accepted seeds + a pending-denied case); the owner's `accepted` row keeps the owner resolving.
- **`accessible` correctness** (caller's role, not an arbitrary join row) is the subtle bit — pinned by
  the multi-participant owned-calendar test.
- **Enforcement is new behavior** (legacy was commented out) — a deliberate, contract-mandated
  hardening; the matrix tests are the guard. No change to events/tasks/bookings.

# Scope check

- [x] Matches the task Scope / Out of scope (CRUD + caller-view + enforcement; participants/join →
      slice 3; `/events` → slice 4; Google/RLS/UI out).
- [x] 3 sequenced slices, each green.
- [x] Size: one router/service/schema trio + a one-line rbac change + tests; no migration/new error code.

# Out of scope

Participant management + join (slice 3); the filtered `/events` + filter engine (slice 4); Google
sync-settings/disconnect (Phase 3); RLS; the React UI; ETL.

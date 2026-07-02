# Goal

Shared-calendar CRUD + caller-view (Phase 2 step 5, slice 2 of 4) over the slice-1 `rbac` foundation:
create / list / get / update / delete a shared calendar plus the caller-view reads (accessible,
my-participation, my-role) — **with the RBAC enforcement the legacy left commented out now actually
applied** through `require_role`/`get_resource_role`. Participant management + join are slice 3; the
filtered `/events` read is slice 4.

# Scope

- **`app/api/shared_calendars.py`** (new `/api/shared-calendars` router) + register in `app/main.py`.
  The legacy surface (`routes.ts:7426-7645`, `:7920`), tenant = JWT `sub` (no `userId` query param):
  - `GET /api/shared-calendars` — the caller's **owned** calendars (`user_id == sub`).
  - `GET /api/shared-calendars/accessible` — owned **+** accepted-participant calendars, each
    augmented with `participantsCount` (count of **all** participant rows) plus the caller's
    `participantRole` / `inviteStatus` (`getAccessibleSharedCalendars`, storage.ts:6591 + routes.ts:7456).
  - `GET /api/shared-calendars/my-participation` — `{participatingCalendars: [{calendar, role,
    isOwner}], isOnlyParticipant, ownCalendarsCount}` over the caller's **accepted, non-owner**
    participations (`isOwner` is always `false` in this list, kept for the legacy item shape).
  - `POST /api/shared-calendars` — create the calendar **and** an `owner` participant row
    (`invite_status="accepted"`); → 200 `SharedCalendarRead`.
  - `GET /api/shared-calendars/{id}` — the calendar; **require `viewer`** (any accepted participant or
    the owner).
  - `PUT /api/shared-calendars/{id}` — update `name`/`filter_type`/`filter_value`/`filter_rules`/
    `google_calendar_id`/`color`/`is_active`; **require `owner`**.
  - `DELETE /api/shared-calendars/{id}` — delete (participants cascade); **require `owner`**; → 204.
  - `GET /api/shared-calendars/{id}/my-role` — `{role, isOwner, canEdit, canViewOtherPages}` (port of
    `routes.ts:7920`); **require `viewer`**.
- **`SharedCalendarsService`** with the eight operations + a `_resolve_access(user_id, calendar_id,
  minimum) -> (calendar, role)` helper: load the calendar (`NotFoundError` if missing), resolve the
  role (`owner` when `calendar.user_id == sub`, else the accepted-participant role), and raise
  `PermissionDeniedError` when the role is `None` or its `ROLE_RANK` is below `minimum`.
- **Enhance `app/rbac.py` `get_resource_role`** to count only `invite_status == "accepted"`
  participants (resolves the slice-1 carry-forward: a pending invite with `user_id` set must not pass
  `require_role`); update the slice-1 rbac tests to seed accepted rows + add a pending-denied case.
- **Schemas** (`app/schemas/shared_calendar.py`, all on the project `_Camel` base — camelCase in/out):
  `SharedCalendarCreate`, `SharedCalendarUpdate`, `SharedCalendarRead`, `AccessibleSharedCalendarRead`
  (read + `participantsCount` + caller `participantRole`/`inviteStatus`), `MyParticipationRead` (items
  carry `calendar`/`role`/`isOwner`), `MyRoleRead`.

# Decisions (design rulings to confirm at Gate 1)

- **Apply the enforcement the legacy commented out.** Legacy `GET/PUT/DELETE /:id` had their
  permission checks commented out (`routes.ts:7571`/`:7596`/`:7634`) — anyone could read/edit/delete.
  The port enforces per RBAC_CONTRACT: read = `viewer`, calendar-config edit + delete = **`owner`**
  (the legacy *intent*, `checkSharedCalendarPermission(..., "owner")`). Event-write roles
  (owner/full_access/editor) are a slice-4 concern.
- **`get_resource_role` gates on `accepted`** + owner resolves via `calendar.user_id` (in
  `_resolve_access`) — matching `checkSharedCalendarPermission`/`my-role` (`routes.ts:7936`,
  `storage.ts:6539`), not the looser `checkUserPermissionInCalendar`. The owner participant row
  (created `accepted` at POST) also resolves the owner, so both paths agree.
- **404 vs 403:** `_resolve_access` raises `NotFoundError` (404) for a missing calendar and
  `PermissionDeniedError` (403) for an existing-but-forbidden one (faithful to `my-role`).
- **`my-role` flags** (port `routes.ts:7952`): `canEdit = role in {full_access, editor}`;
  `canViewOtherPages = role in {owner, full_access, developer}`; the owner gets all true.
- **camelCase contract.** Every schema uses the `_Camel` base so the API accepts/returns `filterType`,
  `filterValue`, `filterRules`, `googleCalendarId`, `isActive`, `userId`, `participantsCount`,
  `participantRole`, `inviteStatus`, `isOwner`, `canEdit`, `canViewOtherPages` — matching the
  legacy/client contract (`schema.ts:1450`, `Calendars.tsx`).
- **Atomic create.** `POST` writes the calendar + the owner participant in one transaction (one
  commit) — never a calendar without its owner row.
- **Route ordering.** The static sub-paths (`/accessible`, `/my-participation`) are declared **before**
  `/{id}` so `/{id}` can't shadow them; `/{id}/my-role` is a distinct nested path.
- **No new migration** (slice-1 tables exist); `POST` → 200, `DELETE` → 204 (superapp convention).

# Out of scope

- Participant management (`GET/POST/PATCH/DELETE /{id}/participants`) + `POST /join` — slice 3.
- The filtered `GET /{id}/events` + the filter engine — slice 4.
- Google `sync-settings` / `disconnect-google` (Phase 3) — the columns exist but no behavior here.
- RLS; the React UI; ETL.

# Acceptance criteria

- [ ] `POST` creates the calendar **and** an `owner`/`accepted` participant row; the owner immediately
      resolves to role `owner` (via `calendar.user_id` and the participant row).
- [ ] `GET /` returns only the caller's owned calendars; `GET /accessible` returns owned + accepted-
      participant calendars each with a correct `participantsCount`; `my-participation` returns only
      accepted non-owner participations with the role + `isOnlyParticipant`/`ownCalendarsCount`.
- [ ] `GET /{id}` / `my-role` allow the owner + any accepted participant (`viewer`+); a non-participant
      → 403; a missing calendar → 404. `PUT`/`DELETE` require `owner` → 403 for a non-owner
      participant, 404 for a missing calendar; `DELETE` → 204 and cascades participants.
- [ ] A **pending** participant (`invite_status != "accepted"`, even with `user_id` set) is denied by
      `get_resource_role`/`_resolve_access` (the slice-1 carry-forward); the slice-1 rbac tests are
      updated accordingly.
- [ ] `my-role` returns `{role, isOwner, canEdit, canViewOtherPages}` with the legacy flag logic;
      `accessible` items carry `participantRole`/`inviteStatus` and `participantsCount` counts **all**
      participant rows; `my-participation` items carry `isOwner`.
- [ ] Responses are camelCase (`filterType`/`googleCalendarId`/`isActive`/`participantRole`/
      `inviteStatus`/`participantsCount`/`isOwner`/`canEdit`/`canViewOtherPages`); a contract test pins
      `SharedCalendarRead` + the accessible/my-role shapes.
- [ ] `POST` is atomic (calendar + owner participant commit together); `/accessible` and
      `/my-participation` resolve to their own handlers (not shadowed by `/{id}`) — pinned by a test.
- [ ] Tenant from JWT `sub` (no `userId` query); typed `AppError` only; `make verify` green;
      `alembic check` clean (no migration).

# Verification commands

```sh
make verify
DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev uv run --frozen alembic check
```

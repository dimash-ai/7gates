# Goal

Lay the foundation for calendar sharing (Phase 2 step 5, slice 1 of 3): a focal-local **`rbac`**
module + the **`shared_calendars`** and **`shared_calendar_participants`** models + their migration.
No routes/schemas/service yet — the owner CRUD (slice 2), participants + join (slice 2), and the
filtered `/events` read (slice 3) build on this. Decomposition + role model confirmed with the owner:
**faithful 6-role ladder (1:1), granular split (rbac + models first).**

# Scope

- **`app/rbac.py`** — the resource-role enforcement primitives (shape per
  [`docs/RBAC_CONTRACT.md`](../../superapp/docs/RBAC_CONTRACT.md), business-code rules per CLAUDE.md):
  - `SHARED_CALENDAR_ROLES` — the legacy 6 roles **carried 1:1**: `owner`, `full_access`, `editor`,
    `developer`, `viewer`, `requester` (no collapsing — the owner chose the faithful model).
  - `ROLE_RANK` — a rank map for **rank-compare** (never raw string `<`). The legacy gates are: read =
    any role; write = `owner`/`full_access`/`editor`; participant add/remove = `owner`. So:
    `owner > full_access > editor > {developer, viewer, requester}` — the read-only trio share one
    rank (identical *write* permission; `developer`'s broader **scope** and `requester`'s request
    **capability** are separate dimensions per the contract, enforced in their later slices, never via
    this ladder).
  - `get_resource_role(session, calendar_id, user_id) -> str | None` — port of
    `checkUserPermissionInCalendar` (storage.ts:6834): the participant's role for
    `(calendar_id, user_id)`, else `None`. (The owner resolves through this because creation inserts an
    `owner` participant row — slice 2.)
  - `require_role(minimum)` — a FastAPI dependency factory: resolves the caller's role on the
    path's `{calendar_id}` and raises a typed **`PermissionDeniedError`** (reuse the existing one in
    `app/errors.py`, 403) when the role is `None` or its rank is below `minimum`. It looks the rank up
    with `ROLE_RANK.get(role)` so an unknown/corrupt stored role (the column is plain varchar) **denies**
    rather than raising an untyped `KeyError`. Defined now so later-slice routes just declare it; it's
    exercised by direct-call tests this slice.
- **`app/models/shared_calendar.py`** — faithful SQLAlchemy 2.0 models of the legacy tables
  (`schema.ts:1450` / `:1510`):
  - `SharedCalendar` (`focal.shared_calendars`): `id` **String PK** (uuid-shaped,
    `default=lambda: str(uuid4())`, matching `calendar.py`/`bookings.py` — not a native `uuid` type),
    `user_id` (owner, NOT NULL), `name`
    (NOT NULL), `filter_type` (NOT NULL default `"all"`), `filter_value`, `filter_rules` (JSONB),
    `google_calendar_id`, `sync_settings` (JSONB), `color` (default `#3b82f6`), `is_active` (default
    true), timestamps. Indexes on `user_id`, `filter_type`, `google_calendar_id`.
  - `SharedCalendarParticipant` (`focal.shared_calendar_participants`): `id` **String PK** (uuid-shaped,
    as above), `shared_calendar_id` (FK `focal.shared_calendars.id` **ON DELETE CASCADE**, NOT NULL),
    `user_id`
    (nullable until join), `email` (nullable), `role` (NOT NULL default `"viewer"`), `invite_status`
    (NOT NULL default `"pending"`), `invite_code` (nullable), timestamps. Indexes on
    `shared_calendar_id`, `user_id`, `email`, `invite_code`.
  - Register both in `app/models/__init__.py`.
- **Migration** — create both tables (FK cascade + the legacy indexes); generated + reviewed in-slice.

# Decisions (design rulings to confirm at Gate 1)

- **Faithful 6 roles + grouped read-only rank** (owner's choice). The 6 role strings are stored 1:1;
  `ROLE_RANK` groups `developer`/`viewer`/`requester` at the read level because they have identical
  write permission. `developer` scope (read-all vs filtered) and `requester` capability are separate
  checks handled in slices 3 / step 6 — not rungs.
- **Reuse `PermissionDeniedError`** (code `permission_denied`, 403) — no new error code. The
  contract's `insufficient_role` snippet is illustrative.
- **Model the full legacy table** incl. `google_calendar_id` / `sync_settings` (nullable, no logic) —
  faithful table fidelity + avoids a future migration; the Google sync *behavior* is Phase 3.
- **No RLS in this migration** — consistent with the already-shipped focal tables (events, bookings),
  which carry no RLS yet; RLS is a deferred cross-cutting pass (validated at the Phase 6 cutover). The
  `rbac` dependency is the first line of enforcement.
- **No routes/schemas/service** — this slice is the enforcement primitives + persistence only.

# Out of scope

- All `/api/shared-calendars*` routes, schemas, and the service (owner CRUD + my-role/my-participation/
  accessible → slice 2; participants + join → slice 2; filtered `/events` + the filter engine →
  slice 3).
- Google `sync-settings` / `disconnect-google` behavior (Phase 3) — columns modeled, logic deferred.
- The `requester` `can_request` capability + meeting requests (step 6); `developer` scope filtering
  (slice 3).
- RLS policies (deferred cross-cutting); the React UI; ETL.

# Acceptance criteria

- [ ] `ROLE_RANK` ranks the 6 roles so that `owner > full_access > editor` and the read-only trio
      (`developer`/`viewer`/`requester`) all rank below `editor`; comparison is by rank, not raw string.
- [ ] `require_role(minimum)` returns the caller's role when its rank `>=` `minimum`'s and raises
      `PermissionDeniedError` (403, typed envelope) when the role is `None` or lower; an unknown/corrupt
      stored role string **denies** (typed) rather than raising `KeyError`.
- [ ] Boundary tests cover `require_role("viewer"|"editor"|"owner")` against all six stored roles (and a
      non-participant), locking the grouped read-only rank (e.g. `developer`/`requester` pass `viewer`
      but fail `editor`).
- [ ] `get_resource_role` returns the participant's role for an owned/participating `(calendar_id,
      user_id)` and `None` for a non-participant — matching `checkUserPermissionInCalendar`.
- [ ] The migration creates `focal.shared_calendars` + `focal.shared_calendar_participants` with the
      participant→calendar FK **ON DELETE CASCADE** and the legacy indexes; deleting a calendar
      cascades its participants.
- [ ] `make verify` green; `alembic upgrade head` + `alembic check` clean (model matches the migration).
- [ ] Typed `AppError` only (no raw `HTTPException`); roles read from the membership table, never the JWT.

# Verification commands

```sh
make verify
DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev uv run --frozen alembic upgrade head
DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev uv run --frozen alembic check
```

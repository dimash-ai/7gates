# Summary

Implement `focal-shared-calendars-rbac` (Phase 2 step 5, slice 1 of 3): the focal-local `rbac`
enforcement primitives + the `shared_calendars` / `shared_calendar_participants` models + their
migration. **No routes/schemas/service** — owner CRUD + participants/join (slice 2) and filtered
`/events` (slice 3) build on this. Owner-confirmed: **faithful 6-role ladder (1:1)**, **granular split**.
Task: [focal-shared-calendars-rbac.md](../tasks/focal-shared-calendars-rbac.md). Contract:
[RBAC_CONTRACT.md](../../superapp/docs/RBAC_CONTRACT.md); legacy `schema.ts:1450/:1510`,
`storage.ts:6834` (`checkUserPermissionInCalendar`) + `:6389` (owner participant auto-insert).

## Decisions (design + the Gate-1 rulings)

- **`app/rbac.py`** (new module):
  - `SHARED_CALENDAR_ROLES: tuple[str, ...]` = the 6 legacy roles 1:1 (`owner`, `full_access`,
    `editor`, `developer`, `viewer`, `requester`).
  - `ROLE_RANK = {"viewer": 10, "requester": 10, "developer": 10, "editor": 20, "full_access": 30,
    "owner": 40}` — the read-only trio share rank 10 (identical *write* permission; `developer` scope
    + `requester` capability are separate dimensions, later slices). Comparison is by rank.
  - `get_resource_role(session, calendar_id, user_id) -> str | None` — `select(participant.role)`
    where `(shared_calendar_id, user_id)`, `scalars().first()` (port of `checkUserPermissionInCalendar`).
  - `require_role(minimum: str)` → returns an async `checker(calendar_id, user_id=Depends(
    get_current_user_id), session=Depends(_rbac_session)) -> str`: `role = await get_resource_role(...)`;
    `rank = ROLE_RANK.get(role)` (unknown/None → deny); raise `PermissionDeniedError` (reuse
    `app/errors.py`, 403) if `rank is None or rank < ROLE_RANK[minimum]`, else return `role`.
  - `_rbac_session()` — an `AsyncIterator[AsyncSession]` from `get_sessionmaker()()` (a dedicated
    read session for the check, matching the router session pattern). The checker is direct-call
    testable (pass `calendar_id`/`user_id`/`session` explicitly).
- **`app/models/shared_calendar.py`** (new) — faithful models (String uuid-shaped PKs via
  `default=lambda: str(uuid4())`, like `calendar.py`/`bookings.py`):
  - `SharedCalendar` (`focal.shared_calendars`): `user_id` (NOT NULL, indexed), `name` **String(255)**
    NOT NULL (faithful to legacy `varchar(255)`), `filter_type` String(20) NOT NULL default `"all"`
    (indexed), `filter_value` String(500),
    `filter_rules` JSONB, `google_calendar_id` String(500) (indexed), `sync_settings` JSONB, `color`
    String(20) default `"#3b82f6"`, `is_active` Boolean default `True`, `TimestampMixin`.
  - `SharedCalendarParticipant` (`focal.shared_calendar_participants`): `shared_calendar_id` String FK
    `focal.shared_calendars.id` **ondelete="CASCADE"** NOT NULL (indexed), `user_id` String (nullable,
    indexed), `email` String(255) (nullable, indexed), `role` String(20) NOT NULL default `"viewer"`,
    `invite_status` String(20) NOT NULL default `"pending"`, `invite_code` String(20) (nullable,
    indexed), `TimestampMixin`.
  - Register both in `app/models/__init__.py` (import + `__all__`).
- **Migration** — `alembic revision --autogenerate -m "shared calendars + participants"` off head
  `dc7e133e8aaa`; review the emitted SQL: two `create_table`s, the participant→calendar FK with
  `ondelete=CASCADE`, and the indexes. Reversible `downgrade` (drop both).
- **Record the decision:** update `apps/focal/CLAUDE.md` Calendar-Sharing Roles section — the
  working "lean 4-level" decision becomes **confirmed: faithful 6 roles 1:1** (keep the legacy→canonical
  rationale table for reference). The contract requires documenting the chosen model there.
- **No RLS** (consistent with the shipped focal tables); **no routes/schemas/service**.

# Files to change

| path | change | why |
|------|--------|-----|
| `superapp/apps/focal/server/app/rbac.py` | add | `SHARED_CALENDAR_ROLES`, `ROLE_RANK`, `get_resource_role`, `require_role`, `_rbac_session` |
| `superapp/apps/focal/server/app/models/shared_calendar.py` | add | `SharedCalendar` + `SharedCalendarParticipant` |
| `superapp/apps/focal/server/app/models/__init__.py` | modify | register both models |
| `superapp/apps/focal/server/alembic/versions/<rev>_shared_calendars.py` | add | create both tables (FK CASCADE + indexes) |
| `superapp/apps/focal/server/tests/test_rbac_db.py` | add | `ROLE_RANK` unit + `get_resource_role`/`require_role` boundary (DB-seeded) |
| `superapp/apps/focal/server/tests/test_migration.py` | modify | assert both tables + the participant FK `ON DELETE CASCADE` in the emitted SQL |
| `superapp/apps/focal/CLAUDE.md` | modify | record the confirmed faithful 6-role decision (the section still shows the stale working 4-level mapping) |

# Implementation slices

Each leaves `make verify` green.

1. **Models + migration.** Add the two models; register them; autogenerate + review the migration
   (FK CASCADE + indexes). *Verify:* `alembic upgrade head` + `alembic check` clean; `make verify` green.
2. **rbac module.** `ROLE_RANK`, `get_resource_role`, `require_role`, `_rbac_session`. *Verify:* the
   rbac tests pass.
3. **Tests + doc.** rbac DB tests + the migration assertions; record the confirmed decision in
   `apps/focal/CLAUDE.md`. *Verify:* full `make verify` + `alembic check`.

# Tests

- **`ROLE_RANK` (unit):** `owner > full_access > editor` and `developer`/`viewer`/`requester` all share
  a rank below `editor`; the map has exactly the 6 roles.
- **`get_resource_role` (DB):** a seeded participant `(calendar_id, user_id, role)` → that role; a
  non-participant `(calendar_id, other_user)` → `None`.
- **`require_role` boundary (DB):** seed each of the 6 roles in turn and call the
  `require_role("viewer")`, `require_role("editor")`, `require_role("owner")` checkers — assert: all 6
  pass `viewer`; only `owner`/`full_access`/`editor` pass `editor`; only `owner` passes `owner`; a
  non-participant and an unknown/corrupt stored role both **deny** with `PermissionDeniedError` (not
  `KeyError`).
- **Migration (offline `--sql`):** `upgrade dc7e133e8aaa:<rev>` emits `CREATE TABLE
  focal.shared_calendars` + `focal.shared_calendar_participants`, the participant FK with `ON DELETE
  CASCADE`, and the indexes; `downgrade` drops both. Plus the live `alembic upgrade head`/`check`.

# Error & rescue map

| failure mode | error | caught where | response |
|--------------|-------|--------------|----------|
| Caller has no role / role rank below `minimum` | `PermissionDeniedError` | `require_role` checker | 403 `permission_denied` |
| Unknown/corrupt stored role string | `PermissionDeniedError` (via `ROLE_RANK.get` → None) | `require_role` checker | 403 `permission_denied` |
| (later slices) calendar not found | `NotFoundError` | service | 404 (out of scope here) |

# Review lenses (pre-answer)

- **Scope / strategy.** Foundation-only: enforcement primitives + persistence, no routes. Reuses the
  existing `PermissionDeniedError`, `TimestampMixin`, `get_current_user_id`, `get_sessionmaker`.
- **Architecture.** Roles read from the membership table (never the JWT); rank-compare with a typed
  denial; FK CASCADE so deleting a calendar removes its participants; faithful 6-role model.
- **Completeness.** ROLE_RANK ordering, the participant lookup, the rank boundaries (incl. unknown
  role), and the migration shape each map to a test.
- **Tests & verification.** `make verify` green; `alembic upgrade head` + `alembic check` clean; the
  rbac primitives are direct-call/DB tested without routes.

# Risks & migrations

- **New migration** off head `dc7e133e8aaa`; additive `create_table`s + FK CASCADE + indexes;
  reversible `downgrade`. Tables are empty pre-prod (no backfill).
- **Routes-free module** could look unused — but `require_role`/`get_resource_role` are exercised by
  direct-call DB tests and consumed by slices 2/3. The slice is a deliberate, owner-approved
  foundation cut.
- **Faithful 6-role rank grouping** is the subtle bit — pinned by the boundary tests across all six.
- **`google_calendar_id`/`sync_settings`** are modeled but unused until Phase 3 (no logic here).

# Scope check

- [x] Matches the task's Scope / Out of scope (rbac + models + migration only; routes/service/filter
      engine/Google/RLS/UI stay out).
- [x] Small enough to review per slice — 3 sequenced, each green.
- [x] Size smell: one module + two models + one migration + tests + a doc decision-record; no routes.

# Out of scope

All `/api/shared-calendars*` routes/schemas/service (slices 2/3); the filter engine + `/events`
(slice 3); participants/join routes (slice 2); Google sync-settings/disconnect (Phase 3); the
`requester` capability + meeting requests (step 6); `developer` scope filtering (slice 3); RLS
policies; the React UI; ETL.

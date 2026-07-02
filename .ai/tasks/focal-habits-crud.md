# Goal

Port the focal **habits lifecycle** surface (Phase 4, slice 1 of 2): habit CRUD + archive/restore +
reorder over the already-scaffolded `Habit` model. `GET /api/habits` (`?archived`), `POST
/api/habits` (create), `GET /api/habits/{id}`, `PATCH /api/habits/{id}`, `DELETE /api/habits/{id}`,
`POST /api/habits/{id}/restore`, `POST /api/habits/reorder`. Habit **entries / streaks / stats** are
slice 2. Legacy: `routes.ts:3175`, `storage.ts:6845`, `schema.ts:916`.

# Scope

- **`app/schemas/habit.py`** — `_Camel` base; `HabitCreate`, `HabitUpdate`, `HabitRead`,
  `HabitReorder`:
  - `HabitCreate`: `name` (required, stripped, non-blank), `description?`, `color` (default
    `"#22c55e"`), `type` (`Literal["positive","negative"]`, default `"positive"`), `category?`,
    `frequency` (`Literal["daily","weekly"]`, default `"daily"`), `target_days_per_week`
    (int 1–7, default 7), `project_id?`, `is_archived` (default `False`), `sort_order` (default 0).
  - `HabitUpdate`: every field optional; same constraints when present; `name` (if present) stripped
    non-blank; applied via `exclude_unset` (an omitted field is untouched). Explicit `null` for any
    **NOT NULL** column — `name`, `type`, `frequency` — is rejected with 422 (a `model_validator`
    before-hook), so it can never reach the DB as an integrity error.
  - `HabitRead`: all columns, camelCase, `from_attributes`.
  - `HabitReorder`: `ordered_ids: list[str]` (non-empty).
- **`app/services/habits.py`** — `HabitsService`:
  - `list_habits(user_id, *, archived=False)` → active (`is_archived=False`, order by `sort_order`)
    or archived (`is_archived=True`, order by `updated_at` **ascending**, matching legacy).
  - `get_habit(user_id, id)` → `_require` (404 if missing **or not owned**, matching `projects.py`).
  - `create_habit(user_id, payload)` → validate the `project_id` link (if set) is owned; insert.
  - `update_habit(user_id, id, payload)` → `_require`; if `project_id` is being set, validate it is
    owned; apply `exclude_unset`; commit.
  - `delete_habit(user_id, id)` → `_require`, hard delete (legacy `deleteHabit`; entries fall via the
    `habit_id` `ON DELETE CASCADE`).
  - `restore_habit(user_id, id)` → `_require`, set `is_archived=False`, commit (legacy
    `/{id}/restore`).
  - `reorder_habits(user_id, ordered_ids)` → set `sort_order = index` for each id **scoped to the
    user** in one transaction (legacy `reorderHabits`); unknown/foreign ids are no-ops.
- **`app/api/habits.py`** — `/api/habits` router; static `/reorder` declared **before** `/{habit_id}`;
  the seven routes above. Registered in `app/main.py`.
- **Tests** — list active vs archived (+ ordering), create (defaults + validation), get
  own/cross-tenant 404, update (partial + validation + ownership), delete (+ cross-tenant 404 + entry
  cascade), restore, reorder (scoped, partial-id no-op), explicit-null on a NOT NULL field → 422,
  project-link validation (owned ok / foreign → error), tenant isolation.

# Decisions (design rulings to confirm at Gate 1)

- **404 on cross-tenant** (not the legacy 403). `_require` collapses missing/not-owned to
  `NotFoundError`, matching the established `projects.py` convention (no existence leak) — a deliberate
  hardening over the legacy 403.
- **Tenant from the JWT `sub`** (no `?userId=` / body `userId`).
- **Validation via Pydantic** (`Literal` + `Field` bounds) → 422 on bad `type`/`frequency`/
  `targetDaysPerWeek`/blank `name`, the superapp convention (legacy returned 400).
- **`project_id` link validated** — when provided, it must be the caller's owned project, else
  `RelatedRecordNotFoundError` (matching `tasks.py._require_owned_link`). This hardens the legacy,
  which inserts loosely (a nonexistent id 500s on the FK; a foreign id links cross-tenant); the
  superapp validates owned links consistently.
- **`DELETE` → 204; `reorder` → 204; `restore`/`update`/`get` → 200; `create` → 200** (FastAPI default,
  the superapp convention used by the shipped routers; legacy create was 201).
- **No migration** — the `Habit` model already exists; `alembic check` stays clean. Typed `AppError`
  only; camelCase.

# Out of scope

- Habit **entries** (set/delete per day), **streaks**, **entry stats** — slice 2. The React UI;
  Google; ETL. No model/migration change.

# Acceptance criteria

- [ ] `GET /api/habits` lists active habits by `sort_order`; `?archived=true` lists archived by
      `updated_at`.
- [ ] `POST /api/habits` creates with defaults applied; blank `name` / bad `type` / `frequency` /
      `targetDaysPerWeek` out of 1–7 → 422.
- [ ] `GET/PATCH/DELETE /api/habits/{id}` work for the owner; a missing id or another user's id → 404.
- [ ] `PATCH` updates only the provided fields (partial); `DELETE` removes the habit and cascades its
      entries; `POST /{id}/restore` clears `is_archived`.
- [ ] `POST /api/habits/reorder` sets `sort_order` to the given order **only for the caller's** habits
      (a foreign/unknown id is a no-op).
- [ ] Explicit `null` for `name` / `type` / `frequency` on create or `PATCH` → 422 (never a DB error).
- [ ] A `project_id` (on create/update) that is missing or another user's → `RelatedRecordNotFoundError`
      (not a 500); an owned `project_id` is accepted.
- [ ] Tenant isolation across list/get/update/delete/reorder; `make verify` green; `alembic check`
      clean (no migration).

# Verification commands

```sh
make verify
DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev uv run --frozen alembic check
```

# Summary

Implement `focal-habits-crud` (Phase 4, slice 1 of 2): the habits lifecycle surface over the
already-scaffolded `Habit` model — `GET /api/habits` (`?archived`), `POST /api/habits`, `GET/PATCH/
DELETE /api/habits/{id}`, `POST /api/habits/{id}/restore`, `POST /api/habits/reorder`. **No** model or
migration change. Entries / streaks / stats are slice 2. Task:
[focal-habits-crud.md](../tasks/focal-habits-crud.md). Legacy: `routes.ts:3175`, `storage.ts:6845`.

## Decisions (design + the Gate-1 rulings)

- **404 on cross-tenant** via `_require` (missing or not-owned → `NotFoundError`), matching
  `projects.py`/`tasks.py` (no existence leak); a deliberate hardening over the legacy 403.
- **`project_id` is a validated owned link** — when set on create/update, it must be the caller's
  project, else `RelatedRecordNotFoundError` (mirrors `tasks.py._require_owned_link`). Removes the
  legacy's 500-on-bad-FK and the cross-tenant link.
- **Explicit `null` on a NOT NULL column** (`name`, `type`, `frequency`) → 422 via a
  `model_validator(mode="before")` on `HabitUpdate` (and required `name` on `HabitCreate`); never
  reaches the DB. Other nullable fields accept `null`.
- **Pydantic validation** (`Literal` + `Field` bounds) → 422 on bad `type`/`frequency`/
  `targetDaysPerWeek`/blank `name` (superapp convention; legacy 400).
- **`exclude_unset`** on update (partial; an omitted field is untouched).
- **Status codes:** `create` → 201 (matching `projects.py` + legacy); `update`/`restore`/`get`/`list`
  → 200; `DELETE` and `reorder` → 204 (legacy delete/reorder returned `{success:true}`).
  `RelatedRecordNotFoundError` is a 400.
- **`reorder`** sets `sort_order = index` per id **scoped to the user** in one transaction; a
  foreign/unknown id matches no row (no-op), faithful to `reorderHabits`.
- **No migration**; `alembic check` stays clean. Typed `AppError` only; camelCase; tenant = JWT `sub`.

# Files to change

| path | change | why |
|------|--------|-----|
| `app/schemas/habit.py` | add | `_Camel` base + `HabitCreate` / `HabitUpdate` / `HabitRead` / `HabitReorder` |
| `app/services/habits.py` | add | `HabitsService` (list / get / create / update / delete / restore / reorder) |
| `app/api/habits.py` | add | `/api/habits` router (static `/reorder` before `/{habit_id}`) + session dep |
| `app/main.py` | modify | register the router |
| `tests/test_habits_db.py` | add | CRUD + archive/restore + reorder + validation + tenant isolation |

# Implementation slices

Each leaves `make verify` green.

1. **Schema + service + router + main.** *Verify:* `make verify` + `alembic check` (no migration) green.
2. **Tests.** *Verify:* full `make verify` green.

# Tests

- **list:** active habits ordered by `sort_order`; `?archived=true` → archived ordered by `updated_at`
  ascending; the other set excluded.
- **create:** defaults applied (`color`/`type`/`frequency`/`target_days_per_week`/`is_archived`/
  `sort_order`); blank `name`, bad `type`/`frequency`, `targetDaysPerWeek` ∉ 1–7 → 422.
- **null on NOT NULL:** `{"type": null}` / `{"frequency": null}` / `{"name": null}` on create or PATCH
  → 422.
- **project link:** create/update with an owned `projectId` → ok; a missing or another user's
  `projectId` → `RelatedRecordNotFoundError` (not 500).
- **get/update/delete:** owner → ok; missing or another user's id → 404; PATCH is partial.
- **delete cascade:** deleting a habit removes its `habit_entries` (FK CASCADE).
- **restore:** `is_archived` cleared.
- **reorder:** `sort_order` set to the given order for the caller's habits; a foreign id in the list is
  a no-op (the owner's order unchanged).
- **tenant isolation:** a second user's habits never appear / can't be mutated.

# Error & rescue map

| failure mode | error | response |
|--------------|-------|----------|
| get/update/delete/restore a missing or other-user id | `NotFoundError` | 404 |
| create/update with a missing/foreign `project_id` | `RelatedRecordNotFoundError` | per its status |
| blank `name` / bad `type`/`frequency` / `targetDaysPerWeek` ∉ 1–7 / explicit null on a NOT NULL field | Pydantic `RequestValidationError` | 422 |
| empty `orderedIds` | Pydantic validation | 422 |
| no auth / bad JWT | `AuthRequiredError` (dependency) | 401 |

# Review lenses (pre-answer)

- **Scope / strategy.** Service + router + schema + tests over an existing model; no migration. CRUD
  split from entries (slice 2). Reuses `NotFoundError` + `RelatedRecordNotFoundError`.
- **Architecture.** Tenant-scoped via the JWT `sub`; owned-link validation matches `tasks.py`;
  NOT NULL columns can't be nulled; reorder is one transaction.
- **Completeness.** Defaults, every validation path, ownership, cascade, reorder scoping, tenant
  isolation each map to a test.
- **Tests & verification.** `make verify` green; `alembic check` clean (no migration).

# Risks & migrations

- **No migration** — `Habit` model already exists; `alembic check` must stay clean.
- **Route ordering:** `/reorder` must precede `/{habit_id}` (`/streaks` is added before `/{habit_id}`
  in slice 2).
- **reorder atomicity:** one transaction, per-row `WHERE id AND user_id` (a foreign id is a no-op, no
  cross-tenant write).
- **No behavior change** to existing endpoints — additive (new router).

# Scope check

- [x] Matches the task Scope / Out of scope (lifecycle only; entries/streaks/stats deferred; no
      model/migration change).
- [x] Reviewable in one pass — 2 sequenced slices, each green.
- [x] Size smell: no model, no migration, one schema + one service + one router + tests.

# Out of scope

Habit entries (set/delete per day), streaks, entry stats (slice 2); the React UI; Google; ETL.

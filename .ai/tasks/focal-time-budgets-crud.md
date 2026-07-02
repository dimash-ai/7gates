# Goal

Time-budget **hierarchy CRUD** (Phase 4 time-budgets, slice 2 of 2): create / update / delete for
categories, subcategories, and items under the settings tree — 9 routes added to the existing
`/api/time-budgets` router. Settings + the `GET /{year}` aggregate were slice 1 (shipped). Legacy:
`routes.ts:5306-5412`, `storage.ts:5667-5775`.

# Scope

- **`app/schemas/time_budget.py`** (extend) — `TimeBudgetCategoryCreate` / `…Update`,
  `TimeBudgetSubcategoryCreate` / `…Update`, `TimeBudgetItemCreate` / `…Update`:
  - Creates require the owned parent FK (`settings_id` / `category_id` / `subcategory_id`) + `name`;
    optional `color` (category/subcategory), `allocated_hours` (default 0), `sort_order` (default 0).
  - Updates are partial; explicit `null` on a NOT NULL column (`name` / `allocated_hours` /
    `sort_order`) → 422; `color` may be null. The parent FK is **not** updatable.
- **`app/services/time_budgets.py`** (extend `TimeBudgetsService`) — a shared
  `_require_owned(model, row_id, user_id)` → row (404 when missing or not the caller's), then per level:
  `create_category` / `update_category` / `delete_category` and the subcategory + item equivalents.
  Each create validates the **owned parent** (`settings` / `category` / `subcategory`); each update /
  delete validates ownership of the row.
- **`app/api/time_budgets.py`** (extend) — `POST/PATCH/DELETE` for `/categories[/{id}]`,
  `/subcategories[/{id}]`, `/items[/{id}]`. Create → 201, `PATCH` → 200, `DELETE` → 204.
- **Tests** — create under an owned vs foreign/missing parent; partial update; null-on-NOT-NULL 422;
  delete + cascade; cross-tenant 404 on update/delete; the rows nest correctly in `GET /{year}`;
  tenant isolation.

# Decisions (design rulings to confirm at Gate 1)

- **Tenant from the JWT `sub`** (no body `userId`); every **create validates the owned parent** →
  `NotFoundError` (404) when the `settings_id` / `category_id` / `subcategory_id` is missing or another
  user's. This hardens the legacy, which inserted the body FK unchecked (cross-tenant links; a 500 on a
  nonexistent FK).
- **update / delete by id verify ownership** → 404 cross-tenant (the legacy updated/deleted by id with
  no ownership check).
- **Partial update** (`exclude_unset`); explicit `null` on a NOT NULL column (`name`,
  `allocated_hours`, `sort_order`) → 422 (`model_validator`); `color` is nullable.
- **Delete cascades** via the existing FK `ON DELETE CASCADE` (category → subcategories → items;
  subcategory → items).
- **Create → 201, `PATCH` → 200, `DELETE` → 204.** camelCase; typed `AppError`. **No migration** (the
  models + the slice-1 constraint already exist).

# Out of scope

- Settings + the year aggregate (slice 1, shipped); the React UI; Google; ETL. No model/migration.

# Acceptance criteria

- [ ] `POST /api/time-budgets/categories` with an owned `settingsId` → 201; a missing or another user's
      `settingsId` → 404. Same for `/subcategories` (`categoryId`) and `/items` (`subcategoryId`).
- [ ] `PATCH /…/{id}` updates the caller's row (partial); a missing / other-user id → 404; explicit
      `null` on a NOT NULL field → 422 (each of category / subcategory / item).
- [ ] `DELETE /…/{id}` → 204 and cascades (a deleted category removes its subcategories + items); a
      missing / other-user id → 404.
- [ ] The created / updated rows appear correctly nested under `GET /api/time-budgets/{year}`.
- [ ] Tenant isolation; `make verify` green; `alembic check` clean (no migration).

# Verification commands

```sh
make verify
DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev uv run --frozen alembic check
```

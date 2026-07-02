# Goal

Time-budget **settings + the year aggregate** (Phase 4 time-budgets, slice 1 of 2): `GET
/api/time-budgets/{year}` (get-or-create settings, seed default categories on first access, return the
nested `settings` + `categories → subcategories → items` tree) and `PATCH
/api/time-budgets/settings/{id}`. Category/subcategory/item CRUD is slice 2. Legacy: `routes.ts:5216`,
`storage.ts:5607`, `schema.ts` (time_budget_*).

# Scope

- **`app/models/time_budget.py`** (modify) + migration — add `UniqueConstraint("user_id", "year")` to
  `TimeBudgetSettings` (one settings row per user-year), so get-or-create is atomic via
  `INSERT … ON CONFLICT`. Migration created + reviewed in-slice under `alembic/versions/`.
- **`app/schemas/time_budget.py`** — `_Camel` base; reads `TimeBudgetSettingsRead`,
  `TimeBudgetCategoryRead`, `TimeBudgetSubcategoryRead`, `TimeBudgetItemRead`; nested
  `TimeBudgetSubcategoryNode` (`= SubcategoryRead + items: list[ItemRead]`), `TimeBudgetCategoryNode`
  (`= CategoryRead + subcategories: list[SubcategoryNode]`), `TimeBudgetYearRead` (`{settings,
  categories: list[CategoryNode]}`); `TimeBudgetSettingsUpdate` (numeric config fields optional;
  explicit `null` on a NOT NULL column rejected → 422).
- **`app/services/time_budgets.py`** — `TimeBudgetsService`:
  - `get_year(user_id, year)` → get-or-create the `(user, year)` settings **atomically**:
    `pg_insert(TimeBudgetSettings).values(…).on_conflict_do_nothing(index_elements=["user_id","year"])
    .returning(id)` — if it returns an id (this request created the row) seed the 3 default categories;
    if not (a concurrent request won) re-select the existing settings and do **not** re-seed. Then load
    the full tree in **≤3 batch reads** (categories by `settings_id`; subcategories by those category
    ids; items by those subcategory ids — skipping a level's query when the prior level is empty) and
    nest in Python (no N+1); returns `TimeBudgetYearRead`.
  - `update_settings(user_id, settings_id, payload)` → require owned (404), partial `exclude_unset`.
- **`app/api/time_budgets.py`** — `/api/time-budgets` router: `GET /{year}` (`year: int`),
  `PATCH /settings/{settings_id}`. Registered in `app/main.py`.
- **Tests** — first GET seeds settings + 3 categories; second GET is idempotent (no duplicate seed);
  leap-year `total_days_in_year`; nested shape; settings update (partial, owned 404, null-on-NOT-NULL
  422); tenant isolation.

# Decisions (design rulings to confirm at Gate 1)

- **Get-or-create on `GET /{year}`** — faithful to the legacy (the frontend calls it expecting the year
  to exist; a documented, intentional deviation from GET-is-safe, matching the source). Made
  **concurrency-safe** by a new `UniqueConstraint(user_id, year)` + `INSERT … ON CONFLICT DO NOTHING
  RETURNING id`: only the request that wins the insert seeds the 3 default categories; a concurrent
  loser re-reads — so no duplicate settings or categories. (The legacy lacked the constraint and had
  this race.)
- **`total_days_in_year = 366 if leap else 365`** (port `getDaysInCalendarYear`); other settings use the
  model defaults (`accountable=13`, `working_days=246`, `working_hours=8`, `holidays=119`, `sleep=8`,
  `hygiene=1`, `eating=2`).
- **Default categories:** `Я` (`#3b82f6`, 1420), `Семья` (`#22c55e`, 1000), `Бизнес` (`#f59e0b`, 2325),
  `sort_order` 0/1/2 — verbatim from the legacy seed.
- **Tenant from the JWT `sub`** (no `?userId=`); `update_settings` verifies ownership → `NotFoundError`
  (404) when missing or another user's — hardening the legacy, which updated settings by id with no
  ownership check (a cross-tenant write).
- **`PATCH settings` is partial** (`exclude_unset`); `year` / `id` / `user_id` are not updatable;
  explicit `null` on a NOT NULL numeric column → 422 (`model_validator` before-hook).
- **Nested read in Python** (≤3 batch reads), faithful to `getTimeBudgetFullData`; camelCase; typed
  `AppError`; `GET`/`PATCH` → 200. **One migration** — only the `(user_id, year)` unique constraint
  (the 4 tables already exist).

# Out of scope

- Category / subcategory / item CRUD (slice 2). The React UI; Google; ETL. No model/migration change.

# Acceptance criteria

- [ ] First `GET /api/time-budgets/{year}` creates the settings + the 3 default categories (each with
      empty `subcategories`) and returns `{settings, categories:[…]}`; a second GET returns the **same**
      settings id with no duplicate categories.
- [ ] `total_days_in_year` is 366 for a leap year (e.g. 2024) and 365 otherwise (e.g. 2026).
- [ ] The response nests `settings` + `categories[].subcategories[].items[]`.
- [ ] `PATCH /api/time-budgets/settings/{id}` updates the caller's settings (partial); a missing or
      another user's id → 404; explicit `null` on a NOT NULL field → 422.
- [ ] The `(user_id, year)` unique constraint is in the migration and applies (`alembic upgrade head`
      OK, `alembic check` clean); a duplicate `(user, year)` settings row cannot be created.
- [ ] Tenant isolation; `make verify` green.

# Verification commands

```sh
make verify
DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev uv run --frozen alembic check
```

# Summary

Implement `focal-time-budgets-aggregate` (Phase 4 time-budgets, slice 1 of 2): time-budget settings +
the `GET /api/time-budgets/{year}` get-or-create aggregate (seed defaults on first access, return the
nested tree) + `PATCH /api/time-budgets/settings/{id}`. Adds **one migration** — a `(user_id, year)`
unique constraint on `time_budget_settings` — so get-or-create is concurrency-safe. Hierarchy CRUD is
slice 2. Task: [focal-time-budgets-aggregate.md](../tasks/focal-time-budgets-aggregate.md). Legacy:
`routes.ts:5216`, `storage.ts:5607`.

## Decisions (design + the Gate-1 rulings)

- **`(user_id, year)` unique constraint** (new `UniqueConstraint` on `TimeBudgetSettings`) + migration,
  so `get_year` does `pg_insert(...).on_conflict_do_nothing(index_elements=["user_id","year"])
  .returning(id)`: an id back ⇒ this request created the row ⇒ seed the 3 default categories; nothing
  back ⇒ a concurrent request won ⇒ re-select, don't re-seed. No duplicate settings/categories.
- **Get-or-create on `GET`** is faithful to the legacy (frontend expects the year to exist) — an
  intentional GET-with-write, documented.
- **`total_days_in_year = 366 if leap else 365`**; other settings default from the model. Default
  categories: `Я`(#3b82f6,1420)/`Семья`(#22c55e,1000)/`Бизнес`(#f59e0b,2325), `sort_order` 0/1/2.
- **Nested tree in Python** via ≤3 batch reads (categories→subcategories→items), skipping a level when
  the prior is empty (no N+1), faithful to `getTimeBudgetFullData`.
- **Tenant from JWT `sub`**; `update_settings` requires owned → `NotFoundError` (404) (hardens the
  legacy no-ownership update). `PATCH` is partial (`exclude_unset`); explicit `null` on a NOT NULL
  numeric column → 422 (`model_validator`); `year`/`id`/`user_id` not updatable.
- camelCase; typed `AppError`; `GET`/`PATCH` → 200.

# Files to change

| path | change | why |
|------|--------|-----|
| `app/models/time_budget.py` | modify | add `UniqueConstraint("user_id", "year")` to `TimeBudgetSettings` |
| `alembic/versions/<rev>_time_budget_settings_unique.py` | add | the unique-constraint migration |
| `app/schemas/time_budget.py` | add | reads + nested nodes + `TimeBudgetYearRead` + `TimeBudgetSettingsUpdate` |
| `app/services/time_budgets.py` | add | `TimeBudgetsService` (`get_year`, `update_settings`) |
| `app/api/time_budgets.py` | add | `/api/time-budgets` router (`GET /{year}`, `PATCH /settings/{id}`) |
| `app/main.py` | modify | register the router |
| `tests/test_time_budgets_db.py` | add | seed/idempotency/leap/nesting/settings-update/tenant |
| `tests/test_migration.py` | modify | assert the unique constraint in the migration |

# Implementation slices

1. **Model + constraint + migration.** Add the `UniqueConstraint`; autogenerate the migration; verify
   it emits `UNIQUE (user_id, year)`. *Verify:* reset schema → `alembic upgrade head` → `alembic check`.
2. **Schemas + service + router + main.** *Verify:* `make verify` green.
3. **Tests.** *Verify:* full `make verify` green.

# Tests

- **seed + idempotent:** first `GET /{year}` → settings + 3 default categories (names/colors/hours/
  order), empty subcategories; a second GET → same settings id, still 3 categories (no re-seed).
- **leap year:** `total_days_in_year` = 366 for 2024, 365 for 2026.
- **nesting:** the response is `{settings, categories:[{...,subcategories:[{...,items:[...]}]}]}` (seed a
  subcategory + item directly and confirm they nest under the right parents).
- **settings update:** `PATCH /settings/{id}` updates the caller's settings (partial — an omitted field
  is untouched); a missing/other-user id → 404; explicit `null` on a NOT NULL field → 422.
- **tenant isolation:** a second user's `GET /{year}` creates/returns *their own* settings, never the
  first user's; cross-tenant settings PATCH → 404.
- **migration:** `test_migration.py` asserts `UNIQUE (user_id, year)` (or the named uq constraint) in
  the upgrade SQL.

# Error & rescue map

| failure mode | error | response |
|--------------|-------|----------|
| PATCH a missing or other-user settings id | `NotFoundError` | 404 |
| explicit `null` on a NOT NULL settings field | Pydantic validation | 422 |
| concurrent first GET for the same `(user, year)` | `ON CONFLICT DO NOTHING` → loser re-reads | 200 (one settings row) |
| no auth | `AuthRequiredError` | 401 |

# Review lenses (pre-answer)

- **Scope / strategy.** Settings + aggregate read only; hierarchy CRUD deferred. One small migration
  (a constraint). The aggregate is the only non-trivial logic.
- **Architecture.** Concurrency-safe get-or-create via the unique key; tenant-scoped; nested read with
  no N+1; typed errors.
- **Completeness.** Seed, idempotency, leap year, nesting, settings update + validation, tenant
  isolation, migration each map to a test.
- **Tests & verification.** `make verify` green; migration applies; `alembic check` clean.

# Risks & migrations

- **Migration adds a UNIQUE constraint** — safe on the empty dev schema; legacy `(user_id, year)`
  duplicates (if any) would need a pre-ETL cleanup (noted, out of this slice).
- **GET-with-write** is intentional (legacy parity); documented.
- **Route:** `GET /{year}` (`year: int`) vs `PATCH /settings/{id}` are distinct paths — no shadowing.
- **No behavior change** to other endpoints (additive router).

# Scope check

- [x] Matches the task (settings + aggregate; hierarchy CRUD deferred; one constraint migration).
- [x] Reviewable in one pass — 3 sequenced slices, each green.
- [x] Size smell: one model line + one constraint migration, schema + service + thin router + tests.

# Out of scope

Category/subcategory/item CRUD (slice 2); the React UI; Google; ETL.

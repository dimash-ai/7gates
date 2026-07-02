# Summary

Implement `focal-time-budgets-crud` (Phase 4 time-budgets, slice 2 of 2): create / update / delete for
categories, subcategories, and items — 9 routes added to the existing `/api/time-budgets` router.
Extends the slice-1 schemas + service. **No** model or migration change. Task:
[focal-time-budgets-crud.md](../tasks/focal-time-budgets-crud.md). Legacy: `routes.ts:5306`,
`storage.ts:5667`.

## Decisions (design + the Gate-1 rulings)

- **A shared `_require_owned(model, row_id, user_id)`** (generic over the mapped class) → row, raising
  `NotFoundError` (404) when missing or `row.user_id != user_id`. Used by every update / delete and by
  the create owned-parent checks — no per-level duplication.
- **Create validates the owned parent** (`settings` / `category` / `subcategory`) before insert → 404
  on a missing / foreign parent (hardens the legacy unchecked body FK: cross-tenant link + 500-on-bad-
  FK). **Tenant from the JWT `sub`**; a body `userId` is dropped (`extra="ignore"`).
- **The parent FK is not updatable** — the `…Update` schemas omit `settings_id`/`category_id`/
  `subcategory_id`, so a PATCH that sends one is ignored (`extra="ignore"`).
- **Partial update** (`exclude_unset`); a module helper `_reject_null(data, allow_null={"color"})` in a
  `model_validator(before)` rejects explicit `null` on the NOT NULL columns (`name`/`allocated_hours`/
  `sort_order`) → 422; `color` may be null.
- **Delete relies on the FK `ON DELETE CASCADE`** (category → subcategories → items; subcategory →
  items).
- **Create → 201, `PATCH` → 200, `DELETE` → 204.** camelCase; typed `AppError`. No migration; no
  `main.py` change (router already registered).

# Files to change

| path | change | why |
|------|--------|-----|
| `app/schemas/time_budget.py` | modify | add `…Create`/`…Update` for category / subcategory / item + the `_reject_null` helper |
| `app/services/time_budgets.py` | modify | add `_require_owned` + the 9 create/update/delete methods |
| `app/api/time_budgets.py` | modify | add the 9 `POST/PATCH/DELETE` routes |
| `tests/test_time_budgets_crud_db.py` | add | CRUD + owned-parent + cascade + tenant + immutability tests |

# Implementation slices

Each leaves `make verify` green.

1. **Schemas + service methods.** *Verify:* `make verify`.
2. **Routes.** *Verify:* `make verify` + `alembic check` (no migration).
3. **Tests.** *Verify:* full `make verify` green.

# Tests

- **create:** with an owned parent → 201 and the row appears nested in `GET /{year}`; a missing /
  another user's parent (`settingsId` / `categoryId` / `subcategoryId`) → 404 — for all three levels.
- **create ignores `userId`:** a body `userId` does not change ownership (the row is the JWT user's).
- **update:** partial (an omitted field untouched); a `PATCH` that sends `settingsId`/`categoryId`/
  `subcategoryId` does **not** re-parent the row; a missing / other-user id → 404; explicit `null` on a
  NOT NULL field → 422 (each level).
- **delete:** the caller's row → 204; deleting a category removes its subcategories + items (cascade);
  a missing / other-user id → 404.
- **tenant isolation:** a second user cannot read/mutate the first user's rows.

# Error & rescue map

| failure mode | error | response |
|--------------|-------|----------|
| create under a missing / foreign parent | `NotFoundError` | 404 |
| update / delete a missing or other-user id | `NotFoundError` | 404 |
| explicit `null` on a NOT NULL field | Pydantic validation | 422 |
| no auth | `AuthRequiredError` | 401 |

# Review lenses (pre-answer)

- **Scope / strategy.** Extends an existing service + router over existing models; no migration. Three
  parallel CRUD sets sharing one ownership helper — minimal duplication.
- **Architecture.** Owned-parent validation on writes; ownership 404 on mutation; immutable parent FK;
  cascade delete; typed errors.
- **Completeness.** Each level's create/update/delete, the parent-validation, null rejection, cascade,
  immutability, tenant isolation maps to a test.
- **Tests & verification.** `make verify` green; `alembic check` clean (no migration).

# Risks & migrations

- **No migration** — models + the slice-1 constraint exist; `alembic check` stays clean.
- **Route ordering:** the static `/categories` / `/subcategories` / `/items` segments don't collide
  with `GET /{year}` (int-constrained, GET-only) or `PATCH /settings/{id}`.
- **No behavior change** to slice-1 endpoints — additive routes + schemas.

# Scope check

- [x] Matches the task (hierarchy CRUD; settings/aggregate was slice 1; no model/migration).
- [x] Reviewable in one pass — 3 sequenced slices, each green.
- [x] Size smell: no model, no migration; schema + service + router extension + one test file.

# Out of scope

Settings + the year aggregate (slice 1); the React UI; Google; ETL.

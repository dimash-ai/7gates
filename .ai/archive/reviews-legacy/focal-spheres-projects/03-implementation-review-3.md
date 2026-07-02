# Codex Review Verdict

Score: 8.6 / 10
Status: BLOCKED

## Reason
The staged slice is scoped correctly to the spheres vertical and matches the legacy duplicate/fuzzy/cascade behavior in the main paths. One malformed PATCH edge can escape validation and hit DB constraints as an untyped 500, which violates the typed error/validation contract.

## Must Fix
- `apps/focal/server/app/schemas/spheres.py:20`-`26` allows explicit `null` for non-nullable fields like `name`, `allocated_hours`, `sort_order`, and `gives_energy`, and `apps/focal/server/app/services/spheres.py:54`-`56` writes every explicitly-set field directly. A request such as `PATCH /api/spheres/{id}` with `{"name": null}` or `{"givesEnergy": null}` will set a NOT NULL column to `NULL` and fail at commit as an untyped DB error instead of `validation_error` or preserving the existing value.

## Should Consider
- Add a positive `GET /api/spheres/{id}` owned-row assertion in `tests/test_spheres_db.py`; current coverage checks cross-tenant 404 but not the successful detail response.

## Tests Reviewed
Inspected staged diff and status; ran `git -C superapp --no-pager diff --cached --check`. Reviewed plan, task, staged sphere files/tests, and legacy `routes.ts:4721-4877`, `storage.ts:5823-5885`, `utils/fuzzy.ts`. Did not run `make verify` in the read-only sandbox; user reported it passes 136 tests.

## Release Risk
Medium

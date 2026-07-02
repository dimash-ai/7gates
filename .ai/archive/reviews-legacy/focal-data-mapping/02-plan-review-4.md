# Codex Review Verdict

Score: 8.8 / 10
Status: BLOCKED

## Reason
The plan resolves the prior `--selftest` omissions and stays scoped to additive contract-freeze tooling, but the selftest/validation plan still misses the required `columns[].focal` mapping target for non-dropped columns. That is the core legacy→focal mapping field, and model reconciliation only proves it for the 18 modeled tables, not the 13 pending ported tables.

## Must Fix
- `.ai/tasks/focal-data-mapping.md:43` requires every column mapping to carry `legacy` and `focal`, but the selftest coverage list at `.ai/plans/focal-data-mapping-plan.md:82` covers type/nullable/default/index_unique/notes/model status without a missing-or-empty `focal` tamper. Add explicit validation and a selftest tamper for missing/empty `columns[].focal` on non-dropped columns, especially because `.ai/plans/focal-data-mapping-plan.md:64` leaves 13 ported tables as `pending` where model reconciliation will not catch an empty target.

## Should Consider
- Add parser fixture coverage for the real `schema.ts` edge shapes, especially multi-line `uniqueIndex(...).on(...)` and expression indexes like `focal/shared/schema.ts:1599`, so the regex parser’s “fail loud” path is exercised before the real inventory pass.

## Tests Reviewed
Read `.ai/tasks/focal-data-mapping.md`, `.ai/plans/focal-data-mapping-plan.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, contract-freeze routes tooling, `CONVENTIONS.md`, `README.md`, `MIGRATION_PLAN.md`, `focal/shared/schema.ts`, and `superapp/apps/focal/server/app/models/`. Verified 39 `pgTable`s and 18 SQLAlchemy model tables by inspection/search. No executable tests run; this is a plan review and `check_tables.sh` is not implemented yet.

## Release Risk
Medium

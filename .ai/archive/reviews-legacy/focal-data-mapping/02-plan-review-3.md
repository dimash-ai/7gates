# Codex Review Verdict

Score: 8.8 / 10
Status: BLOCKED

## Reason
The D4 `crm-boundary` mapping and `--coverage` green-bar issue are resolved, and the plan is otherwise well scoped to the existing routes-inventory pattern. It is still blocked because the `--selftest` tamper list claims to cover every acceptance rule but still omits concrete required table/column/model checks.

## Must Fix
- `.ai/plans/focal-data-mapping-plan.md:81` claims the selftest covers every acceptance rule, but the listed tampers at `.ai/plans/focal-data-mapping-plan.md:83` through `.ai/plans/focal-data-mapping-plan.md:88` do not cover several required rules from `.ai/tasks/focal-data-mapping.md:99`, `.ai/tasks/focal-data-mapping.md:102`, and `.ai/tasks/focal-data-mapping.md:104`: missing `reason` on a `dropped` record, missing/empty `type` or `nullable` on a non-dropped column, and invalid/missing `model.status` / pending-table `phase`.

## Should Consider
- `superapp/apps/focal/docs/contract-freeze/CONVENTIONS.md:47` still lists code-derived inventories without `tables.json`; the README clarification may be enough, but a narrow conventions update would reduce future ambiguity between Drizzle-derived `tables.json` and DB-derived `schema-snapshot.json`.

## Tests Reviewed
Read `.ai/tasks/focal-data-mapping.md`, `.ai/plans/focal-data-mapping-plan.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, route-freeze tooling/docs, `focal/shared/schema.ts`, `superapp/apps/focal/server/app/models/`, and `MIGRATION_PLAN.md` §3a/§6/§8. Ran `rg -c "pgTable\\(" focal/shared/schema.ts` → 39, `rg "__tablename__ =" superapp/apps/focal/server/app/models/*.py | wc -l` → 18, and `bash superapp/apps/focal/docs/contract-freeze/check_routes.sh --selftest` → passed with 17 tampers caught.

## Release Risk
Medium

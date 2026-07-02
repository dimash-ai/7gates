# Codex Review Verdict

Score: 8.4 / 10
Status: BLOCKED

(Round 2 — first review of the rewritten JSON-convention plan, mirroring the routes-inventory tooling.)

## Reason
The plan is strongly aligned with the existing routes-inventory pattern, correct paths, 39 legacy `pgTable`s, 18 modeled target tables, deferred snapshot risk, and `--selftest` intent. It is still blocked by concrete task coverage gaps in the authored mapping and verification plan.

## Must Fix
- `.ai/plans/focal-data-mapping-plan.md:62-66` omits the task-required D4 CRM `blocked_by: ["crm-boundary"]` for `contacts` / `interactions` / `meeting_requests`; `.ai/tasks/focal-data-mapping.md:65-68` and `.ai/tasks/focal-data-mapping.md:103` require those tables to use real dispositions plus `blocked_by[]`.
- `.ai/plans/focal-data-mapping-plan.md:77-80` does not selftest several required table/column validation rules from `.ai/tasks/focal-data-mapping.md:99-106`: column `disposition` enum, explicit `default` / `index_unique`, required `notes` for transformed/dropped columns, invalid relocated `target`, and missing extension fields on a ported table.
- `.ai/plans/focal-data-mapping-plan.md:44-45` says each slice has a green bar, but `.ai/plans/focal-data-mapping-plan.md:57-61` leaves slice 2 with authored-content checks still failing and no separate executable partial-check command. Define the green command per slice or restructure the slice so the full checker has the expected pass/fail target.

## Should Consider
- `superapp/apps/focal/docs/contract-freeze/CONVENTIONS.md:47-53` still distinguishes code-derived inventories from DB-derived table snapshot provenance; consider a narrow conventions update or README wording that explicitly says Drizzle-derived `tables.json` uses code provenance while `schema-snapshot.json` remains DB-derived/deferred.

## Tests Reviewed
Read the task, plan, scoring rubric, `CLAUDE.md`, route-freeze tooling/docs, `focal/shared/schema.ts`, target models, and `MIGRATION_PLAN.md` §3a/§6/§8. Ran `rg -c "pgTable\\(" focal/shared/schema.ts` → 39, `rg "__tablename__ =" superapp/apps/focal/server/app/models/*.py | wc -l` → 18, and `bash superapp/apps/focal/docs/contract-freeze/check_routes.sh --selftest` → passed with 17 tampers caught.

## Release Risk
Medium

# Codex Review Verdict

Score: 7.8 / 10
Status: BLOCKED

## Reason
The task is well-scoped as a mapping/spec artifact, but its verification criteria do not prove the core contract it claims to freeze. It also bakes in tenant-key assumptions that are unsafe for shared-calendar access and nullable CRM ownership, which could propagate into RLS and ETL mistakes.

## Must Fix
- `.ai/tasks/focal-data-mapping.md:49` requires exactly one tenant key for future RLS, but `focal/shared/schema.ts:1512`, `focal/shared/schema.ts:1515`, and `focal/shared/schema.ts:1527` show `shared_calendar_participants` has calendar membership plus optional participant identity and role-based access. Clarify that the mapping must record all owner/access paths, or explicitly separate ETL ownership from RLS visibility.
- `.ai/tasks/focal-data-mapping.md:51` names `contacts` as a direct owner example via `created_by`/`updated_by`, but `focal/shared/schema.ts:164` and `focal/shared/schema.ts:165` show both are nullable. The task needs an explicit requirement for null/mismatched CRM owners and derived `interactions` ownership before this can be an authoritative tenant contract.
- `.ai/tasks/focal-data-mapping.md:64` through `.ai/tasks/focal-data-mapping.md:70` require type/nullability/default/index/unique mapping, and `superapp/apps/focal/docs/MIGRATION_PLAN.md:291` through `superapp/apps/focal/docs/MIGRATION_PLAN.md:295` make that the migration output, but the checker criteria at `.ai/tasks/focal-data-mapping.md:90` through `.ai/tasks/focal-data-mapping.md:99` only require non-empty fields and target column-name reconciliation. Strengthen acceptance so wrong types/defaults/FKs/indexes cannot pass as long as strings are present.

## Should Consider
- Validate the 13 pending-table phases in `check_tables.sh`; the matrix is listed at `.ai/tasks/focal-data-mapping.md:77`, but the checker criteria do not explicitly require phase-matrix reconciliation.
- Clarify `.ai/tasks/focal-data-mapping.md:126` through `.ai/tasks/focal-data-mapping.md:127`: D4 and `dashboard_cohort_retention` are not `pgTable` sections, so “explicitly dispositioned” conflicts with the table-disposition vocabulary.

## Tests Reviewed
Read-only inspection: `.ai/tasks/focal-data-mapping.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, `superapp/apps/focal/docs/MIGRATION_PLAN.md` sections 3a/6/7, `focal/shared/schema.ts`, and `superapp/apps/focal/server/app/models/*.py`. No tests were run.

## Release Risk
Medium

# Codex Review Verdict

Score: 8.2 / 10
Status: BLOCKED

## Reason
The task is mostly well-scoped and strongly oriented around preventing silent table/column loss, but it has an internal contradiction for deferred/retired tables and a verification gap around target-model reconciliation. Those gaps would let a bad mapping pass the stated checks.

## Must Fix
- `.ai/tasks/focal-data-mapping.md:34` requires `Target:` to be a `focal.*` modeled/pending table, while `.ai/tasks/focal-data-mapping.md:60` requires the 7 AI tables to be `deferred` and `sessions` to be `retired`, and `.ai/tasks/focal-data-mapping.md:73` requires every `pgTable` to have `Target:`, `Tenant key:`, and `Identity/FK:`. Define explicit conventions for deferred/retired tables, or exempt them from target/tenant/identity checks.
- `.ai/tasks/focal-data-mapping.md:103` requires the 18 modeled tables to match shipped SQLAlchemy columns, but `.ai/tasks/focal-data-mapping.md:73` and `.ai/tasks/focal-data-mapping.md:108` only require source table/column presence plus non-empty `type`/`nullable`. Add a verifiable check or required reconciliation artifact for target columns, FKs, defaults, and indexes/uniqueness.

## Should Consider
- `.ai/tasks/focal-data-mapping.md:51` has no structured `notes` / `transform` / `reason` column, even though transformed/dropped dispositions are supposed to name the change or reason. Add a machine-checkable place for that instead of relying on prose.

## Tests Reviewed
Inspected `.ai/tasks/focal-data-mapping.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, `focal/shared/schema.ts`, `superapp/apps/focal/docs/MIGRATION_PLAN.md` sections 3a/6/7, and the SQLAlchemy model table list under `superapp/apps/focal/server/app/models/`. No commands were run beyond read-only inspection.

## Release Risk
Medium

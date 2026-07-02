# Codex Review Verdict

Score: 8.2 / 10
Status: BLOCKED

## Reason
The task is mostly well scoped, but it embeds a wrong identity-mapping reference and leaves the core mapping-quality gate too weak to prove the contract. Those gaps could produce a plausible-looking freeze doc that still bakes in bad ID assumptions or omits defaults/index/FK/tenant details.

## Must Fix
- `.ai/tasks/focal-data-mapping.md:35` references “§7 old-id→new-id”, but `superapp/apps/focal/docs/MIGRATION_PLAN.md:296` says `users.id` already equals `auth.users.id`, and `superapp/apps/focal/docs/MIGRATION_PLAN.md:314` shows §7 is only the cutover gate. Fix the task to require the resolved identity-continuity rule.
- `.ai/tasks/focal-data-mapping.md:95` only makes the completeness check prove table disposition and source-column presence, while `.ai/tasks/focal-data-mapping.md:85` requires type, nullability, defaults, indexes/uniqueness, ID/FK strategy, and tenant key. Add a measurable requirement so those fields cannot be omitted while the task still passes.

## Should Consider
- `.ai/tasks/focal-data-mapping.md:3` says “38 pgTables, +sessions”, but `focal/shared/schema.ts:11` defines `sessions` as a `pgTable`; reword to avoid scope confusion.
- `.ai/tasks/focal-data-mapping.md:24` names a fixed disposition vocabulary but does not define the values.
- `.ai/tasks/focal-data-mapping.md:29` should specify whether mappings/checks key columns by Drizzle property names or DB column names.

## Tests Reviewed
Inspected `.ai/tasks/focal-data-mapping.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, `focal/shared/schema.ts`, `superapp/apps/focal/docs/MIGRATION_PLAN.md`, and `superapp/apps/focal/server/app/models/`. Ran read-only `rg`/`nl` commands only; no runtime tests were run because this is a task-definition review.

## Release Risk
Medium

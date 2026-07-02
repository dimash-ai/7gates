# Codex Review Verdict

Score: 7.6 / 10
Status: BLOCKED

## Reason
The task is directionally strong, but it still allows the core mapping freeze to pass while silently missing column/default/index details and leaves tenant/disposition semantics ambiguous. Those gaps undermine the stated purpose of preventing silent schema/data loss.

## Must Fix
- `.ai/tasks/focal-data-mapping.md:42`-`.ai/tasks/focal-data-mapping.md:44` only requires the checker to verify that every `pgTable` appears with a disposition, but the goal at `.ai/tasks/focal-data-mapping.md:3`-`.ai/tasks/focal-data-mapping.md:9` is a column-level binding contract. This does not catch omitted legacy columns, dropped defaults, or missing uniqueness/index constraints, despite `superapp/apps/focal/docs/MIGRATION_PLAN.md:291`-`superapp/apps/focal/docs/MIGRATION_PLAN.md:293` requiring defaults and indexes.
- `.ai/tasks/focal-data-mapping.md:33` assumes each row has a direct tenant key column like `user_id`/`sub`, but several migrating tables do not: `contacts` uses `created_by`/`updated_by` in `focal/shared/schema.ts:162`-`focal/shared/schema.ts:165`, `interactions` scopes through `contact_id` plus optional `created_by` in `focal/shared/schema.ts:243`-`focal/shared/schema.ts:246`, and `event_contacts` has only `event_id`/`contact_id` in `focal/shared/schema.ts:444`-`focal/shared/schema.ts:447`. The task must define direct vs derived tenant-key handling and what the mapping should record for join tables.
- `.ai/tasks/focal-data-mapping.md:24` lists allowed dispositions without `retired`, while `.ai/tasks/focal-data-mapping.md:35`-`.ai/tasks/focal-data-mapping.md:38` and `.ai/tasks/focal-data-mapping.md:70` require `sessions` to be retired. The checker/doc vocabulary is therefore ambiguous and can fail or encode `sessions` inconsistently.

## Should Consider
- Add an explicit pending-table-to-phase matrix for the 13 pending tables called out at `.ai/tasks/focal-data-mapping.md:48`-`.ai/tasks/focal-data-mapping.md:52`; `user_activity_logs` in particular is not obviously assigned from the task text alone.

## Tests Reviewed
Inspected `.ai/tasks/focal-data-mapping.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, `focal/shared/schema.ts`, `superapp/apps/focal/server/app/models/`, `superapp/apps/focal/docs/MIGRATION_PLAN.md`, and the existing route freeze checker pattern. No tests were run; this was a task-definition review.

## Release Risk
Medium

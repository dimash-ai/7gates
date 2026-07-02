# Codex Review Verdict

Score: 9.1 / 10
Status: APPROVED

## Reason
The task is tightly scoped to a freeze/spec artifact, names the authoritative sources, preserves the 31/7/1 table disposition contract, and explicitly assigns semantic correctness to gate review instead of pretending the structural checker proves it. Acceptance criteria are mostly measurable and cover column coverage, model reconciliation, ownership/RLS, FK/default/index fidelity, and service verification.

## Must Fix
None

## Should Consider
- `.ai/tasks/focal-data-mapping.md:37` and `.ai/tasks/focal-data-mapping.md:52` slightly conflict for `relocated`: the disposition says destination is outside `focal.*`, while the migrating-table header says `Target:` is the `focal.*` table. Since this plan expects no relocated tables, this is not blocking, but clarifying it would reduce reviewer ambiguity.
- `.ai/tasks/focal-data-mapping.md:74` asks defaults/indexes to be carried, but `.ai/tasks/focal-data-mapping.md:105`-`.ai/tasks/focal-data-mapping.md:107` only require non-empty `type` and `nullable`. Consider requiring explicit `none`/`n/a` in `default` and `index/unique` cells so omissions are easier to distinguish from intentional absence.
- The model reconciliation wording at `.ai/tasks/focal-data-mapping.md:110`-`.ai/tasks/focal-data-mapping.md:111` should be interpreted to include inherited SQLAlchemy columns such as `TimestampMixin.created_at` / `updated_at` from `superapp/apps/focal/server/app/models/base.py:16`; otherwise a text-only parser could under-check modeled tables.

## Tests Reviewed
Inspected `.ai/tasks/focal-data-mapping.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, `focal/shared/schema.ts`, `superapp/apps/focal/server/app/models/*.py`, `focal/shared/schema.indexes.test.ts`, and `superapp/apps/focal/docs/MIGRATION_PLAN.md` sections 3a/6/7. No verification command was run because this review is only for the task definition.

## Release Risk
Low

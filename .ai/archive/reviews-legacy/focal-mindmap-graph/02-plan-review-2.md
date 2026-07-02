# Codex Review Verdict

Score: 8.8 / 10
Status: BLOCKED

## Reason
The plan is mostly grounded in the actual FastAPI scaffold: paths match, the composite-PK migration strategy aligns with the current single-column PK in `app/models/mindmap.py` and the baseline constraint names, and the test map covers most acceptance criteria. It is blocked by one contract ambiguity that could implement edge upsert incorrectly.

## Must Fix
- `.ai/plans/focal-mindmap-graph-plan.md:46` and `.ai/plans/focal-mindmap-graph-plan.md:95` say `sourceNodeId`/`targetNodeId` are required only on edge create, but the task requires them for edge upsert at `.ai/tasks/focal-mindmap-graph.md:87`, and the legacy route validates them before calling storage at `focal/server/routes.ts:4529` and `focal/server/routes.ts:4531`. Update the plan so every `PUT /api/mindmap-edges/{id}` requires those body fields, while conflict updates still preserve the stored source/target values.

## Should Consider
- Make the batch duplicate-id test explicitly assert the returned duplicate rows reflect the final state, matching `.ai/tasks/focal-mindmap-graph.md:110`; the plan currently says input order and last-wins at `.ai/plans/focal-mindmap-graph-plan.md:115` but does not pin the repeated final-state response.
- Add an explicit migration-test note for the irreversible downgrade. The current `tests/test_migration.py:27` helper assumes Alembic returns success, while the planned migration downgrade intentionally raises at `.ai/plans/focal-mindmap-graph-plan.md:30`.

## Tests Reviewed
Not run; plan review only. Inspected the task, plan, rubric, `CLAUDE.md`, FastAPI model/service/test/migration scaffold, foundation Alembic baseline, and legacy `routes.ts`, `storage.ts`, and schema files.

## Release Risk
Medium

# Codex Review Verdict

Score: 8.8 / 10
Status: BLOCKED

## Reason
The plan is well-scoped, aligns with the actual FastAPI scaffold and legacy MindMap contract, and correctly calls out the composite-PK model/test/migration fallout. It falls just short because one explicit acceptance criterion is not mapped to a concrete test despite the plan claiming each criterion is covered.

## Must Fix
- Add explicit test coverage for malicious/ignored client identity and unknown fields. The task requires body/query `userId != sub` to be served against `sub` and unknown body fields to be ignored, with this behavior tested (`.ai/tasks/focal-mindmap-graph.md:188`-`.ai/tasks/focal-mindmap-graph.md:189`). The plan states the behavior (`.ai/plans/focal-mindmap-graph-plan.md:64`-`.ai/plans/focal-mindmap-graph-plan.md:65`) but the enumerated tests only cover general tenant isolation and omit this acceptance case (`.ai/plans/focal-mindmap-graph-plan.md:110`-`.ai/plans/focal-mindmap-graph-plan.md:131`).

## Should Consider
- Add an explicit PUT body-`id`-defers-to-path test. The task names this behavior (`.ai/tasks/focal-mindmap-graph.md:124`) and the plan repeats it (`.ai/plans/focal-mindmap-graph-plan.md:39`-`.ai/plans/focal-mindmap-graph-plan.md:42`), but the tests list does not pin it.
- Use `op.f(...)` for the PK constraint names in the hand-authored migration for consistency with the existing naming-convention-safe migration pattern (`superapp/apps/focal/server/alembic/versions/2026_06_03_1000-d4f1a2b3c4e5_drop_work_time_sphere_check.py:23`-`27`; naming convention at `superapp/apps/focal/server/app/db.py:15`-`20`).

## Tests Reviewed
Inspected `.ai/tasks/focal-mindmap-graph.md`, `.ai/plans/focal-mindmap-graph-plan.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, `superapp/apps/focal/server/app/models/mindmap.py`, `tests/test_models_db.py`, `tests/test_migration.py`, Alembic baseline/check-drop migrations, `app/services/tasks.py`, `app/api/tasks.py`, `app/main.py`, `app/errors.py`, `app/db.py`, `tests/test_contracts.py`, `tests/test_projects_db.py`, `tests/test_tasks_db.py`, and legacy `focal/server/routes.ts`, `focal/server/storage.ts`, `focal/shared/schema.ts`. No runtime tests were run; this was a plan review.

## Release Risk
Medium

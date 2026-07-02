# Codex Review Verdict

Score: 8.1 / 10
Status: BLOCKED

## Reason
The plan is well scoped and mostly aligned with the backend-only task, with correct files, slices, and broad test coverage. It still has concrete contract gaps in the priority model and tag validation that would let Claude implement behavior that differs from the legacy/task requirements.

## Must Fix
- `.ai/plans/focal-tasks-tags-plan.md:63` uses boolean `or` for energy, but the task and legacy require nullish fallback: `project.givesEnergy ?? sphere.givesEnergy ?? false` (`.ai/tasks/focal-tasks-tags.md:148`, `focal/server/storage.ts:976`). A project with `gives_energy=False` and a true sphere would be scored incorrectly.
- `.ai/plans/focal-tasks-tags-plan.md:58` only resolves `project` by `projectId`; legacy `getHierarchyContext` falls back from `product.parentProjectId` when `projectId` is missing (`focal/server/storage.ts:936`, `focal/server/storage.ts:940`). The plan needs this parent-project fallback and a DB test for product-only priority/enrichment context.
- `.ai/tasks/focal-tasks-tags.md:173` requires `PATCH /api/tags/:id` to reject `name:null` or `color:null`, but the plan only calls out non-blank/length validation (`.ai/plans/focal-tasks-tags-plan.md:90`, `.ai/plans/focal-tasks-tags-plan.md:164`). This matters because current `TagUpdate` accepts `None` (`superapp/apps/focal/server/app/schemas/tags.py:10`) and the service ignores it as a no-op (`superapp/apps/focal/server/app/services/tags.py:98`).

## Should Consider
- Add `uv run alembic check` to the final verification steps explicitly; the task requires it (`.ai/tasks/focal-tasks-tags.md:222`), while `make verify` does not include it (`superapp/apps/focal/server/Makefile:14`).
- Add explicit tests that create ignores `status`, `completed`, and `eventId`; the plan states the behavior, but the listed create tests do not name those inputs.

## Tests Reviewed
Not run; read `.ai/tasks/focal-tasks-tags.md`, `.ai/plans/focal-tasks-tags-plan.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, relevant FastAPI models/routes/services/schemas/tests, legacy `routes.ts`, `storage.ts`, and `contract-freeze` inventories.

## Release Risk
Medium

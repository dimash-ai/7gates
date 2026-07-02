# Codex Review Verdict

Score: 7.1 / 10
Status: BLOCKED

## Reason
The task is well scoped overall, but it bakes in a wrong/ambiguous legacy contract for project move semantics and leaves sphere deletion behavior dangerously underspecified. As written, Claude could implement a passing slice that diverges from the actual client/server contract or deletes/retains related project data incorrectly.

## Must Fix
- `.ai/tasks/focal-spheres-projects.md:42`, `.ai/tasks/focal-spheres-projects.md:57`-`.ai/tasks/focal-spheres-projects.md:63`, and `.ai/tasks/focal-spheres-projects.md:99`-`.ai/tasks/focal-spheres-projects.md:101` define `/api/projects/:id/move` as arbitrary self-referential reparenting with cycle/missing-parent checks. The legacy route is different: it accepts `newParentId` only as one of `budget`, `economic-safety`, `society`, `life-spheres`, rejects products, and calls `moveProject(id, newParentId, newSphere)` (`focal/server/routes.ts:3796`-`focal/server/routes.ts:3834`); storage sets `parentProjectId: null` and updates `parentType`, products, tasks, events, and bookings (`focal/server/storage.ts:5279`-`focal/server/storage.ts:5393`). Clarify whether this slice intentionally changes the contract, or rewrite the task/tests to match legacy.
- `.ai/tasks/focal-spheres-projects.md:39` and `.ai/tasks/focal-spheres-projects.md:90` reduce spheres to generic CRUD but do not define the legacy duplicate/fuzzy-name checks or delete side effects. Legacy create/update reject duplicate and similar names (`focal/server/routes.ts:4758`-`focal/server/routes.ts:4775`, `focal/server/routes.ts:4807`-`focal/server/routes.ts:4829`), and legacy delete removes projects whose `sphere` matches before deleting the sphere (`focal/server/routes.ts:4857`-`focal/server/routes.ts:4868`). This must be explicitly accepted, rejected, or replaced with a safer tested rule.

## Should Consider
- `.ai/tasks/focal-spheres-projects.md:35`-`.ai/tasks/focal-spheres-projects.md:48` says response shapes are bound by `routes.json`, but that file only inventories route metadata, not schemas. Add concise expected response examples for create/update/delete/move/move-preview and error envelopes, especially camelCase vs snake_case.
- `.ai/tasks/focal-spheres-projects.md:96`-`.ai/tasks/focal-spheres-projects.md:98` makes the work-time rule a rejecting invariant; legacy create coerces `sphere` to null while update can preserve it. State clearly that this is an intentional behavior change from legacy.
- `.ai/tasks/focal-spheres-projects.md:87`-`.ai/tasks/focal-spheres-projects.md:89` should clarify how to run autogenerate/check without leaving an authored Alembic revision, since migrations are explicitly out of scope.

## Tests Reviewed
Inspected `.ai/tasks/focal-spheres-projects.md`, `CLAUDE.md`, `.ai/checklists/scoring-rubric.md`, `superapp/apps/focal/docs/contract-freeze/routes.json`, `superapp/apps/focal/docs/contract-freeze/tables.json`, and relevant legacy route/storage/client/test snippets with `sed`, `nl`, `rg`, and `jq`. No runtime tests were run; this was a task-definition review.

## Release Risk
High

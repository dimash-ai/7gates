# Codex Review Verdict

Score: 7.4 / 10
Status: BLOCKED

## Reason
The plan is broadly aligned with the task and actual FastAPI scaffold, but it misses two concrete composite-PK follow-through issues that can break verification or leave model/migration drift ambiguous. The scope is otherwise appropriate and the endpoint/test coverage is mostly strong.

## Must Fix
- `superapp/apps/focal/server/app/models/mindmap.py:12-14` declares `id` before `user_id`, while the plan only says to mark both columns `primary_key=True` at `.ai/plans/focal-mindmap-graph-plan.md:66`. That will make SQLAlchemy metadata naturally order the composite key as `(id, user_id)`, conflicting with the planned migration's explicit `(user_id, id)` at `.ai/plans/focal-mindmap-graph-plan.md:25-27`; the plan must specify reordering the model columns or using an explicit `PrimaryKeyConstraint("user_id", "id", ...)`.
- The file list at `.ai/plans/focal-mindmap-graph-plan.md:62-74` omits `superapp/apps/focal/server/tests/test_models_db.py`, but that existing test uses scalar lookup for `MindmapNode` at `superapp/apps/focal/server/tests/test_models_db.py:282`. After a composite PK, `session.get(MindmapNode, "nj")` is invalid and will break pytest unless updated to the composite identity.

## Should Consider
- Add an explicit migration test in `superapp/apps/focal/server/tests/test_migration.py`. That file exists specifically because `make verify` uses `Base.metadata.create_all` rather than running migrations (`superapp/apps/focal/server/tests/test_migration.py:1-6`), so the new hand-authored PK swap should be pinned with offline SQL assertions too.
- Make the batch tests explicitly cover missing `nodes` as well as non-array `nodes`; the task requires both to return `validation_error`.

## Tests Reviewed
Inspected `.ai/tasks/focal-mindmap-graph.md`, `.ai/plans/focal-mindmap-graph-plan.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, the FastAPI scaffold under `superapp/apps/focal/server/`, legacy `focal/server/routes.ts`, `focal/server/storage.ts`, `focal/shared/schema.ts`, and contract-freeze route/table inventories. No tests were run; this was a read-only plan review.

## Release Risk
Medium

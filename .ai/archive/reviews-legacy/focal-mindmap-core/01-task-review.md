# Codex Review Verdict

Score: 8.2 / 10
Status: BLOCKED

## Reason
The task is mostly well-scoped, but it has blocking ambiguity around required endpoints and an unmeasurable MindMap invariant. As written, Claude could implement a green slice that omits acceptance-critical behavior or guesses at branch rules.

## Must Fix
- `.ai/tasks/focal-mindmap-core.md:37` scopes routers/services to `spheres`, `projects`, `tasks`, `mindmap-nodes`, `mindmap-edges`, `mindmap`, and `tags`, but `.ai/tasks/focal-mindmap-core.md:83` requires CRUD over `goals` and `task_tags`; clarify whether `goals` and `task_tags` need first-class route/service coverage in this slice.
- `.ai/tasks/focal-mindmap-core.md:52` requires encoding the two MindMap branches, but the acceptance criteria at `.ai/tasks/focal-mindmap-core.md:86` through `.ai/tasks/focal-mindmap-core.md:91` only make work-time, task sort, and contract shape testing measurable; define the Mission/Provision branch rules and required tests.

## Should Consider
- Add an explicit endpoint matrix for each migrated route group, including methods, response status codes, legacy shape source, and delete/cascade behavior.
- Give the exact path for `routes.json` referenced at `.ai/tasks/focal-mindmap-core.md:39`.
- Clarify what `mindmap` means as a route group versus `mindmap-nodes` and `mindmap-edges`.

## Tests Reviewed
Inspected `.ai/tasks/focal-mindmap-core.md`, `.ai/checklists/scoring-rubric.md`, and `CLAUDE.md`. No tests were run because this was a task-definition review.

## Release Risk
Medium

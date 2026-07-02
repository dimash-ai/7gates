# Codex Review Verdict

Score: 7.8 / 10
Status: BLOCKED

## Reason
The task is mostly scoped and test-oriented, but it leaves a security-critical tenant-isolation edge case ambiguous and omits verifiable success criteria for one in-scope endpoint. As written, Claude could satisfy the checklist while leaving cross-tenant foreign-key references or `/api/mindmap/init` behavior untested.

## Must Fix
- `.ai/tasks/focal-mindmap-core.md:54` and `.ai/tasks/focal-mindmap-core.md:98`: tenant isolation is defined as “cannot read or mutate another user's rows,” but the task does not explicitly require ownership validation for referenced IDs in create/update payloads, such as task `sphere`/project/tag IDs, project parent IDs, mindmap node parents, and mindmap edge endpoints. This is a security/access-control gap.
- `.ai/tasks/focal-mindmap-core.md:49` includes `GET /api/mindmap/init`, but `.ai/tasks/focal-mindmap-core.md:98` through `.ai/tasks/focal-mindmap-core.md:111` do not explicitly require integration or contract coverage for that endpoint.

## Should Consider
- `.ai/tasks/focal-mindmap-core.md:43` through `.ai/tasks/focal-mindmap-core.md:44`: project `move` / `move-preview` should state required edge cases, especially cycle prevention, moving under missing or foreign parents, root moves, and confirmation that preview is side-effect-free.
- `.ai/tasks/focal-mindmap-core.md:19` and `.ai/tasks/focal-mindmap-core.md:80`: backend type export via `gen:api` is mentioned, but no acceptance criterion or verification command proves it happened.

## Tests Reviewed
Inspected `.ai/tasks/focal-mindmap-core.md`, `.ai/checklists/scoring-rubric.md`, and `CLAUDE.md`. No tests were run; this was a task-definition review only.

## Release Risk
Medium

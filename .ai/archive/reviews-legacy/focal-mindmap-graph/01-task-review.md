# Codex Review Verdict

Score: 7.6 / 10
Status: BLOCKED

## Reason
The task is detailed and mostly bounded, but it has a fundamental tenant/identity ambiguity that can make the implementation impossible or security-sensitive. A few stated requirements also lack measurable acceptance coverage.

## Must Fix
- `.ai/tasks/focal-mindmap-graph.md:37` and `.ai/tasks/focal-mindmap-graph.md:49` require dropping the scoped-id scheme while keeping a plain client-supplied `id` as the primary key, but `.ai/tasks/focal-mindmap-graph.md:38` and `.ai/tasks/focal-mindmap-graph.md:96` require every upsert to be tenant-scoped. The task does not define how two tenants can own the same client-supplied node/edge id; with a single-column PK, user B cannot create their own `id` if user A already has it, and returning `not_found` would also make normal tenant-local upsert semantics ambiguous. Define the storage identity contract explicitly, such as composite `(user_id, id)` uniqueness or a private internal scoped id.
- `.ai/tasks/focal-mindmap-graph.md:39` and `.ai/tasks/focal-mindmap-graph.md:53` require RLS as a second line of tenant protection, but the acceptance criteria at `.ai/tasks/focal-mindmap-graph.md:123`-`.ai/tasks/focal-mindmap-graph.md:148` do not require any RLS verification. Add an explicit migration/RLS acceptance check or DB-level test, otherwise a security requirement can be silently skipped.
- `.ai/tasks/focal-mindmap-graph.md:85` specifies `fullDescription` must be `≤ 2500 chars`, but no acceptance criterion or test at `.ai/tasks/focal-mindmap-graph.md:123`-`.ai/tasks/focal-mindmap-graph.md:148` defines over-limit behavior. Specify the expected response and require a test.

## Should Consider
- `.ai/tasks/focal-mindmap-graph.md:88`-`.ai/tasks/focal-mindmap-graph.md:90` should define batch edge cases: empty `nodes`, duplicate ids in one batch, missing node `id`, and whether the operation is atomic or partial-success.
- `.ai/tasks/focal-mindmap-graph.md:69`-`.ai/tasks/focal-mindmap-graph.md:73` should explicitly say whether edge upsert validates that `sourceNodeId` and `targetNodeId` exist for the same tenant, or deliberately allows dangling edges to match legacy behavior.

## Tests Reviewed
Read `.ai/tasks/focal-mindmap-graph.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, and referenced legacy route/storage/schema excerpts. No tests were run; this was a task-definition review only.

## Release Risk
High

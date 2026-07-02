# Codex Review Verdict

Score: 7.8 / 10
Status: BLOCKED

## Reason
The task is strong on endpoint scope, tenant isolation, error envelopes, and contract-oriented tests, but it leaves an unsafe migration rollback path undefined. It also omits a measurable acceptance test for one explicit legacy edge-upsert behavior.

## Must Fix
- `.ai/tasks/focal-mindmap-graph.md:61` requires a downgrade for the PK swap, while `.ai/tasks/focal-mindmap-graph.md:32` and `.ai/tasks/focal-mindmap-graph.md:158` make duplicate `id` values across users valid. A downgrade back to an `id`-only primary key cannot succeed after valid duplicate data exists unless the task defines an irreversible downgrade or an explicit data-retention/data-deletion strategy.
- `.ai/tasks/focal-mindmap-graph.md:86` requires edge conflict updates to leave `sourceNodeId`/`targetNodeId` unchanged, but `.ai/tasks/focal-mindmap-graph.md:129` and `.ai/tasks/focal-mindmap-graph.md:167` only require style-update coverage. Add a required test that attempts to change source/target on an existing edge and proves they are preserved.

## Should Consider
- `.ai/tasks/focal-mindmap-graph.md:23` says unknown request fields are ignored, but the acceptance criteria only explicitly test `userId`. Add a contract test for a generic unknown field if unchanged client compatibility depends on it.
- `.ai/tasks/focal-mindmap-graph.md:103` should clarify whether an explicitly provided `nodeData` replaces the full JSON document or deep-merges it.
- `.ai/tasks/focal-mindmap-graph.md:112` should clarify whether deleting a node leaves incident edges intact, since dangling edges are allowed elsewhere.

## Tests Reviewed
Read-only review of `.ai/tasks/focal-mindmap-graph.md`, `.ai/checklists/scoring-rubric.md`, and `CLAUDE.md`; no implementation tests were run.

## Release Risk
Medium

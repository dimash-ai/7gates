# Codex Review Verdict

Score: 8.6 / 10
Status: BLOCKED

## Reason
The task is tightly scoped and has strong acceptance coverage, but one acceptance criterion still contradicts the core PUT/upsert contract. Claude cannot implement and verify unknown-id PUT behavior without choosing between mutually exclusive requirements.

## Must Fix
- `.ai/tasks/focal-mindmap-graph.md:45`-`.ai/tasks/focal-mindmap-graph.md:48` and `.ai/tasks/focal-mindmap-graph.md:113`-`.ai/tasks/focal-mindmap-graph.md:116` say `PUT`/batch upserts never 404 on an unknown id and create the caller's own row, but `.ai/tasks/focal-mindmap-graph.md:133` and `.ai/tasks/focal-mindmap-graph.md:174`-`.ai/tasks/focal-mindmap-graph.md:175` require an unknown/malformed `:id` on any node/edge `GET`/`PUT`/`DELETE` to return typed `not_found`. Remove `PUT` from the unknown-id 404 criterion, or define a separate concrete malformed-id case that does not conflict with upsert creation.

## Should Consider
- `.ai/tasks/focal-mindmap-graph.md:82`-`.ai/tasks/focal-mindmap-graph.md:86` and `.ai/tasks/focal-mindmap-graph.md:161`-`.ai/tasks/focal-mindmap-graph.md:163` should explicitly state and test whether an edge conflict update preserves or updates `sourceNodeId`/`targetNodeId`; the legacy storage updates style fields only, but the required source/target body fields make this easy to misread.
- `.ai/tasks/focal-mindmap-graph.md:102`, `.ai/tasks/focal-mindmap-graph.md:166`-`.ai/tasks/focal-mindmap-graph.md:178` define batch behavior for empty arrays and missing item ids, but not for missing/non-array `nodes` or invalid field types. Clarifying whether these use the typed `{error:{code,message}}` envelope would prevent default framework 422 drift.

## Tests Reviewed
Read `.ai/tasks/focal-mindmap-graph.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, and referenced legacy MindMap route/storage/schema excerpts. No tests were run; this was a task-definition review only.

## Release Risk
Medium

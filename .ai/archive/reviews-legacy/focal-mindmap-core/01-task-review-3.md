# Codex Review Verdict

Score: 7.8 / 10
Status: BLOCKED

## Reason
The task is detailed and mostly bounded, but it contains a blocking contract ambiguity around the work-time invariant that can send implementation and tests at the wrong model. Because the acceptance criteria names `tasks` fields that the frozen table mapping places on `projects`, the slice is not yet safely implementable.

## Must Fix
- `.ai/tasks/focal-mindmap-core.md:107` says to reject "a task with `is_work_time=true` and a non-null `sphere`," but the binding mapping is `contract-freeze/tables.json`: `sphere` and `is_work_time` are on `projects` at lines 3572 and 3582, while `tasks` columns at lines 4224-4434 do not include either field. Clarify whether this invariant applies to projects, task payload enrichment via project, or a missing table-mapping change.

## Should Consider
- `.ai/tasks/focal-mindmap-core.md:47` includes `/api/mindmap-nodes/batch`, but the acceptance criteria only calls out CRUD for mindmap nodes/edges. Add an explicit criterion for batch semantics and tests.
- `.ai/tasks/focal-mindmap-core.md:45` and `.ai/tasks/focal-mindmap-core.md:52` say task payload tags persist `task_tags`, but the mapping also retains `tasks.tags`; clarify replace/merge behavior and which source drives responses.

## Tests Reviewed
Inspected `.ai/tasks/focal-mindmap-core.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, and the relevant `contract-freeze/tables.json` sections with `sed`, `nl`, `rg`, and `jq`.

## Release Risk
Medium

# Codex Review Verdict

Score: 8.1 / 10
Status: BLOCKED

## Reason
The task definition is detailed and mostly scoped, but it contains contradictions that would lead Claude to implement or test the wrong behavior. The blockers are acceptance criteria that disagree with the stated schema/domain model and an underspecified move contract.

## Must Fix
- `.ai/tasks/focal-mindmap-core.md:70`-`.ai/tasks/focal-mindmap-core.md:76` says the work-time invariant lives on `projects` and `tasks` carries none of it, but `.ai/tasks/focal-mindmap-core.md:111`-`.ai/tasks/focal-mindmap-core.md:112` requires rejecting a `task` with `is_work_time` and `sphere`. Rewrite the acceptance criterion to cover project create/update.
- `.ai/tasks/focal-mindmap-core.md:43`-`.ai/tasks/focal-mindmap-core.md:44` and `.ai/tasks/focal-mindmap-core.md:124`-`.ai/tasks/focal-mindmap-core.md:126` define `projects` move as tree reparent/cycle detection, but do not state the allowed parent domain, request contract, or cascade behavior. Since `.ai/tasks/focal-mindmap-core.md:38`-`.ai/tasks/focal-mindmap-core.md:40` makes `routes.json`/legacy storage binding, this must explicitly choose legacy budget-node move semantics vs arbitrary project reparenting.
- `.ai/tasks/focal-mindmap-core.md:52`-`.ai/tasks/focal-mindmap-core.md:54` describes task tags as a denormalized string-array plus `task_tags`, but `.ai/tasks/focal-mindmap-core.md:58` and `.ai/tasks/focal-mindmap-core.md:116`-`.ai/tasks/focal-mindmap-core.md:119` require validating task "tag ids." Clarify whether task payload tags are tag names, tag row IDs, or both, and what ownership check/test is required.

## Should Consider
- `.ai/tasks/focal-mindmap-core.md:116`-`.ai/tasks/focal-mindmap-core.md:119` names task `project_id` and tags for cross-tenant ownership tests, but not `product_id`; products are in scope, so add that case if task/product binding is supported.
- `.ai/tasks/focal-mindmap-core.md:120`-`.ai/tasks/focal-mindmap-core.md:123` asks for legacy shape/semantics for MindMap init and batch upsert, but does not spell expected fields or status behavior. Contract tests can cover this, but concise examples would reduce ambiguity.

## Tests Reviewed
Inspected `.ai/tasks/focal-mindmap-core.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, and relevant legacy route/schema context. No runtime tests run; task-definition review only.

## Release Risk
Medium

# Codex Review Verdict

Score: 8.1 / 10
Status: BLOCKED

## Reason
The task is detailed and mostly measurable, but several contract-critical behaviors remain ambiguous enough that Claude could implement the wrong API and still appear to satisfy the checklist. The biggest gaps are nullable PATCH semantics, FK/tenant rules for carried legacy links, list date-window defaults, and RLS verification.

## Must Fix
- `.ai/tasks/focal-tasks-tags.md:54-56` defines `startDate`/`endDate` as optional filters but does not specify behavior when one or both are omitted. Acceptance at `.ai/tasks/focal-tasks-tags.md:146-149` cannot distinguish “all tasks” from a legacy default date window, so the list contract is not fully testable.
- `.ai/tasks/focal-tasks-tags.md:68` includes `contactId` and `goalId`, but `.ai/tasks/focal-tasks-tags.md:71` and `.ai/tasks/focal-tasks-tags.md:154-157` only require FK/non-owned handling for `projectId`/`productId`/`activityId`. Clarify whether `contactId`/`goalId` must resolve to the authenticated user’s rows, are stored without validation, or are intentionally out of acceptance.
- `.ai/tasks/focal-tasks-tags.md:73-77` does not define explicit `null` semantics for PATCH on nullable/editable fields. The `submitted ?? existing` note implies `null` is ignored, while “partial update of editable columns” could imply `null` clears fields like `dueDate`, `dueTime`, `projectId`, `productId`, or `tags`; acceptance only tests omitted fields.
- `.ai/tasks/focal-tasks-tags.md:45-46` requires a `tasks` RLS policy, but the acceptance criteria and verification commands at `.ai/tasks/focal-tasks-tags.md:138-181` do not include any direct RLS verification. Add an explicit migration/policy check or test.

## Should Consider
- `.ai/tasks/focal-tasks-tags.md:96-100` says `/api/tags` should reach legacy parity while also specifying a missing `color` should default. If this is an intentional modernization from the legacy route behavior, call it out explicitly so reviewers do not treat it as accidental drift.
- `.ai/tasks/focal-tasks-tags.md:73` says “editable columns” but never enumerates them. A short whitelist would reduce the risk of accepting system-managed fields beyond the separately mentioned `completedAt`, `priority_score`, and `userId`.

## Tests Reviewed
Read-only review only: inspected `.ai/tasks/focal-tasks-tags.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, and referenced legacy task/tag route/storage snippets. No tests were run.

## Release Risk
Medium

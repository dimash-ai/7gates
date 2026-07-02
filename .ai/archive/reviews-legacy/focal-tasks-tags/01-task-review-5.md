# Codex Review Verdict

Score: 7.8 / 10
Status: BLOCKED

## Reason
The task definition is detailed and mostly measurable, but it has a concrete internal conflict around `activityId` tenant isolation. That ambiguity affects the security contract and can lead to incompatible implementations.

## Must Fix
- `.ai/tasks/focal-tasks-tags.md:36` says every task link, including `activityId`, is scoped to JWT `sub`, and `.ai/tasks/focal-tasks-tags.md:37` says non-owned linked records are treated like missing records. But `.ai/tasks/focal-tasks-tags.md:48` and `.ai/tasks/focal-tasks-tags.md:101` say `activityId` is checked by DB-FK existence only and ownership is deferred. `.ai/tasks/focal-tasks-tags.md:218` only requires tests for non-existent `activityId`, not non-owned `activityId`. Pick one contract and make the acceptance criteria match it.

## Should Consider
- `.ai/tasks/focal-tasks-tags.md:99` and `.ai/tasks/focal-tasks-tags.md:234` say create requires `title`, but only update explicitly rejects blank/whitespace titles at `.ai/tasks/focal-tasks-tags.md:124`. Specify and test whether blank create titles are allowed.
- `.ai/tasks/focal-tasks-tags.md:164` to `.ai/tasks/focal-tasks-tags.md:170` should state whether tag PATCH applies the same `name` validation as create, and whether blank `color` is valid.

## Tests Reviewed
Read-only inspection of `.ai/tasks/focal-tasks-tags.md`, `.ai/checklists/scoring-rubric.md`, and `CLAUDE.md`; no tests run because this was a task-definition review.

## Release Risk
Medium

# Codex Review Verdict

Score: 8.4 / 10
Status: BLOCKED

## Reason
The task definition is detailed and mostly verifiable, but two contract ambiguities can lead to incompatible implementations. The main gaps are activity-link validation despite activities being deferred, and inconsistent tag validation error/status requirements.

## Must Fix
- `.ai/tasks/focal-tasks-tags.md:47` and `.ai/tasks/focal-tasks-tags.md:98` require `activityId` to resolve to a user-owned row, but `.ai/tasks/focal-tasks-tags.md:126` and `.ai/tasks/focal-tasks-tags.md:194` say the activities vertical is deferred. Define exactly what establishes `activityId` ownership in this slice, or state whether `activityId` is stored unvalidated, rejected, or ignored until Phase 4.
- `.ai/tasks/focal-tasks-tags.md:42` says every business error uses a typed `{error:{code,message}}` AppError envelope and `.ai/tasks/focal-tasks-tags.md:45` defines `validation_error` as 422, but `.ai/tasks/focal-tasks-tags.md:158` and `.ai/tasks/focal-tasks-tags.md:233` require missing tag `name`/`color` to return 400. Specify the exact error code, status, and envelope for tag create/update validation failures.

## Should Consider
- `.ai/tasks/focal-tasks-tags.md:78` and `.ai/tasks/focal-tasks-tags.md:175` say malformed present `startDate`/`endDate` values are “passed through,” but the expected API result is not measurable. Define whether this returns rows, no dated rows, or a typed error if the database rejects the value.
- `.ai/tasks/focal-tasks-tags.md:107` allows PATCH `title`, but only create explicitly requires `title` at `.ai/tasks/focal-tasks-tags.md:97`. Clarify PATCH behavior for `title:null`, blank title, and omitted title.
- `.ai/tasks/focal-tasks-tags.md:98` validates `projectId` and `productId` independently. Consider stating whether a user-owned `productId` must belong to the supplied `projectId`, or whether cross-project combinations are intentionally allowed for legacy parity.

## Tests Reviewed
Read `.ai/tasks/focal-tasks-tags.md`, `.ai/checklists/scoring-rubric.md`, and `CLAUDE.md`. No tests run; this was a task-definition review only.

## Release Risk
Medium

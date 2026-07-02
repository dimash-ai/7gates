# Codex Review Verdict

Score: 8.6 / 10
Status: BLOCKED

## Reason
The task is well-scoped and most round-1 fixes are clearly reflected, but two remaining edge cases are under-specified enough to let Claude build behavior that diverges from the legacy contract or produces raw DB errors. The acceptance criteria are otherwise strong and measurable.

## Must Fix
- `.ai/tasks/focal-calendar-events.md:90-105` does not specify the legacy hierarchy fallback where `activityId` can supply `activity.projectId` / `activity.productId` before priority is computed; legacy does this at `focal/server/storage.ts:3429-3433`. Add this behavior and a test where an event only has `activityId`, the activity priority is null/invalid, and product/project priority is used.
- `.ai/tasks/focal-calendar-events.md:136-145` says PATCH has “null-vs-omitted semantics” but does not define explicit null handling for non-null fields like `title`, `date`, `startTime`, `tags`, `contactIds`, or `completed`. Since the model makes several of these non-null at `.ai/tasks/focal-calendar-events.md:69-77`, the task needs clear 422-vs-clear-vs-no-op rules and tests so nulls cannot leak into DB constraint failures.

## Should Consider
- Clarify malformed `startDate` / `endDate` list-query behavior: `.ai/tasks/focal-calendar-events.md:110-113` says reuse `get_date_range`, but `.ai/tasks/focal-calendar-events.md:53-57` broadly says malformed dates are `validation_error` 422.

## Tests Reviewed
Read `.ai/tasks/focal-calendar-events.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, and relevant legacy/source context in `focal/server/storage.ts`, `focal/server/routes.ts`, `focal/shared/schema.ts`, plus existing Focal `daterange`, `tasks`, and model files. No tests run; this was a task-definition review only.

## Release Risk
Medium

# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 8.1 / 10
Status: BLOCKED

## Reason
The design is mostly well-scoped and reuse-first, but it has two correctness gaps in the unhappy-path/permission model that would send the build in the wrong direction.

## Must Fix
- `.ai/design/focal-parity-calendar-buttons-design.md:64-66` and `.ai/design/focal-parity-calendar-buttons-design.md:99` gate the task button only on `canEdit`, but tasks are in the OTHER_PAGES write domain: `superapp/apps/focal/server/app/data_scope.py:14-16`, `superapp/apps/focal/server/app/data_scope.py:55-56`, and `superapp/apps/focal/server/app/api/tasks.py:36-40`. `superapp/apps/focal/client/src/features/calendars/CalendarFilterContext.tsx:205-206` shows an `editor` has `canEdit: true` but `canViewOtherPages: false`, so the proposed design would enable a task create dialog that can only 403 on save. Define the correct task permission gate and test it.
- `.ai/design/focal-parity-calendar-buttons-design.md:111` claims blank event titles hit an existing no-API guard, but `superapp/apps/focal/client/src/features/calendar/CalendarPage.tsx:296-300` calls `createMutation.mutate(createPayload(draft))` with no title trim/required check, while that guard exists only in `superapp/apps/focal/client/src/features/events/EventsPage.tsx:307-310`. Add the CalendarPage/EventDialog create validation to the design and include a test for the dialog path.

## Should Consider
Add a CalendarPage-level task save test because `.ai/design/focal-parity-calendar-buttons-design.md:64-65` says saving from the left-rail task dialog creates and closes, but the slice test at `.ai/design/focal-parity-calendar-buttons-design.md:119-120` only proves the dialog opens and read-only disables the button.

## Tests Reviewed
N/A

## Release Risk
Medium

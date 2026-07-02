# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 7.8 / 10
Status: BLOCKED

## Reason
The requested status and duplicate paths are mostly present, but the diff includes a separate golden-hours/prime-time feature outside this build slice, and the duplicate action still allows repeated creates while the mutation is pending.

## Must Fix
- `apps/focal/client/src/features/calendar/CalendarPage.tsx:213`, `apps/focal/client/src/features/calendar/CalendarPage.tsx:609`, `apps/focal/client/src/features/calendar/TimeGrid.tsx:80`, and `apps/focal/client/src/features/calendar/PrimeTimeDialog.tsx:48` add an unrelated settings-driven golden-hours feature. This build step was scoped to calendar event status + duplicate actions; remove this work from the slice or land it separately.
- `apps/focal/client/src/features/calendar/EventPopover.tsx:407` disables Duplicate only for read-only mode, and `apps/focal/client/src/features/calendar/CalendarPage.tsx:406` calls `createMutation.mutate(...)` without a pending guard. A rapid double-click can issue multiple `createEvent` calls, violating B2’s explicit double-create failure criterion.

## Should Consider
- `apps/focal/client/src/features/events/eventsFilters.test.ts:690` asserts `recurrenceEndDate` is omitted, while Gate A said the duplicate payload should set `recurrenceEndDate: null` and `recurrenceExceptions: []`; align the implementation/test contract if relying on backend defaults is intentional.

## Tests Reviewed
Inspected `CalendarPage.test.tsx`, `eventsFilters.test.ts`, `PrimeTimeDialog.test.tsx`, and `TimeGrid.test.tsx`; no suite run in read-only review.

## Release Risk
Medium

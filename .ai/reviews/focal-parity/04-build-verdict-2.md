# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.3 / 10
Status: BLOCKED

## Reason
The three prior fixes are present in the diff, but the provider still has a fail-open role path on a defined slice-1 unhappy path. That can make a participant-only viewer/requester look like they have main-calendar/full sidebar rights when one calendar endpoint fails.

## Must Fix
- `apps/focal/client/src/features/calendars/CalendarFilterContext.tsx:297` auto-selects the first `participatingCalendars` entry, but `apps/focal/client/src/features/calendars/CalendarFilterContext.tsx:308` resolves the selected calendar only from `accessible`. If `/my-participation` succeeds and `/accessible` fails or returns empty, `stableCurrentCalendar` becomes `null`, and `resolveRights` at `apps/focal/client/src/features/calendars/CalendarFilterContext.tsx:155` grants full main-calendar rights (`canEdit`/`canViewOtherPages` true). This violates the design's fail-closed shared-calendar error path and makes the limited sidebar disappear for restricted participants.

## Should Consider
- Main-calendar legacy/default-name normalization from old-focal is still absent around `apps/focal/client/src/features/calendars/CalendarFilterContext.tsx:244` and `apps/focal/client/src/features/calendars/CalendarsPage.tsx:665`; stored values like `main` or `Основной` can render literally.
- Add focused tests for the endpoint-failure path above and for main-calendar live rename/recolor via `mainCalendarUpdated`.

## Tests Reviewed
`git -C superapp-parity --no-pager diff feature/focal-migration`; `git -C superapp-parity status`; inspected `CalendarFilterContext.test.tsx` and `AppSidebar.test.tsx`; did not rerun pnpm checks in the read-only sandbox.

## Release Risk
Medium

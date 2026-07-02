# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.2 / 10
Status: BLOCKED

## Reason
The core provider role matrix and filter helpers are mostly in place, but two slice-1 shell behaviors are incorrect and the new shell/switcher behavior is not adequately tested.

## Must Fix
- `apps/focal/client/src/features/calendars/CalendarFilterContext.tsx:80` reads `focal_main_calendar_name` / `focal_main_calendar_color`, while the existing main-calendar editor writes `focal:calendars:main-name` / `focal:calendars:main-color` at `apps/focal/client/src/features/calendars/CalendarsPage.tsx:101` and `apps/focal/client/src/features/calendars/CalendarsPage.tsx:669`. Renaming/recoloring the main calendar therefore will not update the new switcher, and the required main-calendar name normalization is also absent.
- `apps/focal/client/src/components/AppSidebar.tsx:225` still renders the Personal CRM link whenever `VITE_PRIMA_URL` is set, outside the limited-menu filter at `apps/focal/client/src/components/AppSidebar.tsx:181`. For viewer/editor/requester-style limited roles, the sidebar can show more than `/calendar` and `/meeting-requests`, contrary to the slice requirement.
- Add focused shell/switcher tests for the new user-facing behavior. Current coverage only tests provider internals and a refresh click; `apps/focal/client/src/App.test.tsx:25` mocks the provider away, and `apps/focal/client/src/components/AppShell.test.tsx:163` does not exercise limited menu, viewing banner, or calendar selection.

## Should Consider
- Surface accessible/participation query failures in the switcher instead of silently showing empty calendar groups.

## Tests Reviewed
`git -C superapp-parity --no-pager diff feature/focal-migration`, `git -C superapp-parity status`, `CalendarFilterContext.test.tsx`, `AppShell.test.tsx`, `App.test.tsx`.

## Release Risk
Medium

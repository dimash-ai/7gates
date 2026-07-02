# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 7.0 / 10
Status: BLOCKED

## Reason
The slice closes much of the shared-calendar owner-resolution surface, but the calendar scope invariant still has concrete cross-owner authorization gaps. There is also a client scoping miss that can mix viewer reference data into owner-scoped pages.

## Must Fix
- `apps/focal/server/app/services/shared_calendars.py:222`-`229` allows shared-calendar event creation after only a role check, with no validation that the new event matches the selected calendar filter. `apps/focal/server/app/services/shared_calendars.py:241`-`244` plus `:271`-`:279` only check the pre-update event is in-filter, so an editor can update an in-filter owner event into an out-of-filter event. This violates the design's "create/move/edit outside the filter -> 403" invariant.
- `apps/focal/server/app/api/ai_chat.py:204` resolves AI scope by owner userId, then `apps/focal/server/app/api/ai_chat.py:323`-`335` passes only `user_id` into entity handlers; `apps/focal/server/app/ai/entity_handlers.py:411`-`418` loads calendar events via raw `CalendarService.list_events(ctx.user_id, ...)`. A permitted assistant-mode caller can query all owner events through AI instead of only the selected shared calendar's filtered events.
- `apps/focal/client/src/features/tasks/TasksPage.tsx:199`-`203` scopes the tasks query to `currentCalendarId` but still fetches projects with bare `queryKey: ['projects']` and `listProjects()`. In assistant mode this can render owner-scoped tasks with the viewer's own project reference data/cache.

## Should Consider
None

## Tests Reviewed
Inspected `git diff feature/focal-migration`, `git log feature/focal-migration..HEAD`, design/plan/task docs, test_calendar_scope_db.py, test_data_scope_db.py, and related client tests. Did not rerun the full suites; local checks were reported green.

## Release Risk
High

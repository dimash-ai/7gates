# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 7.8 / 10
Status: BLOCKED

## Reason
The prior write-scope and AI filtered-read fixes are mostly reflected, but the calendar read partition is still not fully closed for by-id/non-event calendar-domain reads. A shared-calendar participant could still be granted owner-scoped access unless the design explicitly validates every calendar-domain read object against the selected calendar scope.

## Must Fix
- The design routes shared event list reads through the filtered path and validates create/update/delete, but does not explicitly close by-id calendar reads: `GET /api/events/{event_id}` (`api/calendar.py:43`) + `CalendarService.get_event` returns any owner event by id (`services/calendar.py:139`). Same for `bookings` (`bookings.py:19/41`) and `meeting_requests` (`meeting_requests.py:19/36`) list/by-id reads. Add an explicit contract + tests that shared-mode by-id/list calendar reads return only objects matching the selected calendar filter / shared_calendar scope, else 403/404.

## Should Consider
- If AI calendar/event reads are available to viewer/editor, explicitly state mixed calendar handlers must not include owner tasks unless `canViewOtherPages`, since current handlers combine events and tasks.

## Tests Reviewed
N/A

## Release Risk
High

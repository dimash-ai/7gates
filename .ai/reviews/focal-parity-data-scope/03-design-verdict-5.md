# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 7.2 / 10
Status: BLOCKED

## Reason
The role-set split fixes the prior editor/developer over-grant at a high level, but the calendar-domain design still leaks owner data through aggregate and filtered-calendar paths. The closed-partition guard is also not actually closed over current `get_current_user_id` routers.

## Must Fix
- `calendar_init` classified as calendar-domain viewer+ read, but `CalendarInitService.get_init` returns owner tasks and projects as well as events/bookings (`services/calendar_init.py:30/31/33`; schema `schemas/calendar.py:267`) — would expose non-calendar data to editor/viewer/requester. Split the aggregate by domain gate or omit other-pages payloads unless `canViewOtherPages`.
- "No service changes" + client `matchesFilter` for event lists leaks: safe shared reads apply the saved filter server-side (`services/shared_calendars.py:204`) while raw `CalendarService.list_events` returns all owner events (`services/calendar.py:81`), and by-id writes (`api/calendar.py:55`) let an editor mutate any known owner event. Enforce shared-calendar visibility server-side for calendar-domain reads and by-id writes.
- The closed-partition rule omits `app/api/ai.py` and `app/api/ai_chat.py` even though both inject `get_current_user_id` (`ai.py:48/76/106`, `ai_chat.py:191/862`). Classify them or add an explicit AI bucket so the guard passes intentionally.

## Should Consider
None

## Tests Reviewed
N/A

## Release Risk
High

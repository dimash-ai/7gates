# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 7.8 / 10
Status: BLOCKED

## Reason
The prior partition and role-set fixes are mostly reflected, and the `get_current_user_id` router buckets now cover the current API surface. However, two remaining calendar-scope paths can still bypass the selected shared-calendar filter: AI event-backed reads and event creation.

## Must Fix
- AI calendar/event reads are still designed as raw owner-scope reads: AI reads gated by the other-pages read gate, while `/api/ai/chat` dispatch passes `data_owner` directly into entity handlers (`ai_chat.py:310`) and event-backed handlers call raw `CalendarService.list_events(ctx.user_id, ...)` (`entity_handlers.py:411`). This bypasses the server-side shared-calendar filter required for filtered calendar reads.
- Calendar `POST /api/events` is not included in the filtered-scope write rule: the design only calls out by-id writes, but event creation is a calendar mutation (`api/calendar.py:32`) and current creation only validates owner-owned links (`services/calendar.py:161`). An editor on a filtered shared calendar could create owner events outside that calendar's filtered scope unless create is also validated against the selected calendar filter.

## Should Consider
- Clarify whether `calendar_init` omits unauthorized `tasks`/`projects` keys or returns empty arrays, since the response schema requires those fields (`schemas/calendar.py:267`).

## Tests Reviewed
N/A

## Release Risk
High

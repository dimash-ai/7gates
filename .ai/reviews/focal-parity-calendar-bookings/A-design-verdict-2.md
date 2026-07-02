# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 8.1 / 10
Status: BLOCKED

## Reason
The revised design addresses the prior blockers: wide-window booking fetch, full booking metadata, mini-month deferral, all-day strip gating, and shared-calendar reference degradation. It still misses two concrete calendar call-sites that will produce incorrect UI/interaction behavior once bookings are added.

## Must Fix
- `superapp-parity/apps/focal/client/src/features/calendar/CalendarPage.tsx:209` and `superapp-parity/apps/focal/client/src/features/calendar/CalendarPage.tsx:707`: the design does not update the event-only empty-state gate. With zero events and visible bookings, the page will still render the “empty” overlay over a non-empty calendar; design must require empty state to consider visible bookings.
- `superapp-parity/apps/focal/client/src/features/calendar/MonthView.tsx:73` and `superapp-parity/apps/focal/client/src/features/calendar/YearView.tsx:94`: the design adds selectable booking chips/dots to views whose day cells are already `<button>`s for zooming. It must specify the interaction/DOM structure so booking selection is not nested inside another button and does not also trigger day zoom.

## Should Consider
- Specify that update payloads send `null` for cleared nullable booking fields, not omitted keys, because `BookingsService.update_booking` preserves omitted fields.

## Tests Reviewed
N/A

## Release Risk
Medium

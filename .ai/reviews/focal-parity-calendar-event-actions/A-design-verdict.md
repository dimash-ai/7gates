# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 8.4 / 10
Status: BLOCKED

## Reason
The main scoping decision is sound: adding actions to the existing `EventPopover` and deferring convert-to-task avoids duplicating surfaces and keeps this slice on the event API. The design is blocked because the duplicate contract says “same fields” but the proposed `createPayload(editDraft(event))` path would not preserve old-focal copy semantics or full event metadata.

## Must Fix
- Fix the duplicate payload design. The design requires duplicating “same fields” and proposes `createEvent(createPayload(editDraft(event)))` (`.ai/design/focal-parity-calendar-event-actions-design.md:59`, `.ai/design/focal-parity-calendar-event-actions-design.md:85`), but `CalendarPage`’s local `editDraft` currently seeds only core grid fields (`superapp-parity/apps/focal/client/src/features/calendar/CalendarPage.tsx:139`) and omits description, location, timezone, tags, contact/contact participant fields, and status unless only status is added. Old-focal copied those fields and intentionally stripped recurrence (`superapp/apps/old-focal/client/src/pages/Calendar.tsx:2048`, `superapp/apps/old-focal/client/src/pages/Calendar.tsx:2066`). The design must specify a payload builder that preserves copyable metadata and explicitly defines recurring-event copy behavior.

## Should Consider
- Reconcile the `tentative` status choice with old-focal and sibling surfaces: old-focal `EventStatus` and `EventInfoDialog` only expose `planned | confirmed` (`superapp/apps/old-focal/client/src/components/EventCard.tsx:20`, `superapp/apps/old-focal/client/src/components/EventInfoDialog.tsx:353`), while the new Events dialog status options are also only `planned | confirmed` (`superapp-parity/apps/focal/client/src/features/events/EventDialog.tsx:33`). If `tentative` is intentional because the new backend/EventBlock supports it, document that as a new-app extension and update/shared-test the sibling status UI contract.
- Prefer reusing existing `focal.events.status.*` labels or centralizing status labels instead of adding parallel `focal.calendar.status.*` keys unless there is a clear copy distinction.

## Tests Reviewed
N/A for design; inspected the referenced calendar/event files and old-focal copy/status behavior.

## Release Risk
Medium

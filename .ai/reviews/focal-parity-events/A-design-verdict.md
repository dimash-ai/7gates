# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 8.2 / 10
Status: BLOCKED

## Reason
The design is well-scoped overall and the slice/test breakdown is mostly coherent, but it makes a wrong interface assumption for the event timezone field. That affects a core success criterion: persisting per-event timezone without changing the user's global display timezone.

## Must Fix
- `TimezoneSelector.tsx` exposes no controlled props and binds selection to global `displayTimezone` via `setDisplayTimezone`. The design needs a controlled event-timezone picker or an explicit `TimezoneSelector` API extension, with tests proving event timezone updates the draft/payload and does not mutate the display timezone preference.

## Should Consider
- Clarify mutation ownership between `EventDialog` and `EventsPage` (recurring edits must keep routing through `RecurringScopeDialog`).
- Add explicit tag name-to-id normalization for editing legacy events, reusing the existing normalization path.

## Tests Reviewed
N/A

## Release Risk
Medium

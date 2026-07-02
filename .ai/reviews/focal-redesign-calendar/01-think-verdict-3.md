# Review Verdict

Reviewer: GPT Codex
Step: think
Score: 8.7 / 10
Status: BLOCKED

## Reason
The doc is now mostly contract-grounded: `/api/bookings`, `BookingRead`, settings prime-time, the 8-slice structure, range-only bookings, and dnd-kit are all substantively anchored. However, the think doc still contains stale "only all-day is deferred" wording that contradicts its own marks-deferred classification and the requested correction.

## Must Fix
- `.ai/think/focal-redesign-calendar.md:114` and `:127-129` still state that all-day is the only backend-blocked/deferred item, despite `:39-40` and `:93-95` correctly deferring single-day marks because `BookingRead` has no `kind` discriminator. This leaves the success criteria inconsistent with the required marks-deferred scope.

## Should Consider
- `.ai/tasks/focal-redesign-calendar.md:68-69` says bookings data feeds the "calendar marks strip"; consider renaming that to "bookings strip" to avoid reintroducing the mark/bookings ambiguity.
- `.ai/think/focal-redesign-calendar.md:71-72` would be clearer if it cited `superapp/CLAUDE.md:57` for the dnd-kit floor, since that is where the Tooling anchor actually lives.

## Tests Reviewed
N/A

## Release Risk
Medium

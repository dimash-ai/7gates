# Review Verdict

Reviewer: GPT Codex
Step: think
Score: 8.2 / 10
Status: BLOCKED

## Reason
The revised doc mostly grounds bookings and prime-time in the OpenAPI contract and keeps all-day deferred, but it still carries stale and inconsistent scope language that can misdirect the epic decomposition. The slice order is broadly sound, but the "marks" part of the bookings slice is not clearly backed by the cited contract.

## Must Fix
- `.ai/think/focal-redesign-calendar.md:12`-`:15` still says golden-time bands and bookings are "mock-only richness" that the backend does not support, contradicting the corrected OpenAPI-backed classification at `:33`-`:41` and the actual contracts at `openapi.d.ts:512`, `:530`, and `:5045`-`:5058`.
- `.ai/think/focal-redesign-calendar.md:65` and `:102` call this a 6-slice cut, but the think doc and kickoff enumerate 8 slices at `:74`-`:85` and `.ai/tasks/focal-redesign-calendar.md:35`-`:58`.
- `.ai/think/focal-redesign-calendar.md:82`-`:83` and `.ai/tasks/focal-redesign-calendar.md:53` promise a "bookings/marks" strip as backed by `/api/bookings`, but `BookingRead` exposes booking fields only and no `kind`/mark discriminator at `openapi.d.ts:2712`-`:2750`, while the prototype's mark behavior depends on `kind === "mark"` at `Booking.jsx:1` and `:95`. Split "marks" from bookings or explicitly reduce that slice to backend-backed booking ranges/visual indicators.

## Should Consider
- Anchor the "dnd-kit is sanctioned" claim before slice 4; `package.json` has Framer Motion but not `@dnd-kit/*` today.

## Tests Reviewed
N/A

## Release Risk
Medium

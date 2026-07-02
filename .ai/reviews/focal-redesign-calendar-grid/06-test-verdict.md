# Review Verdict

Reviewer: Opus
Step: test
Score: 8.5 / 10
Status: BLOCKED

## Reason
Lane edge cases (end<start, zero-duration, day-end crossing, the 30-min footprint-vs-raw-times clamp) and wall-clock determinism are covered with meaningful, discriminating assertions, and the suite is green (323 passed). But the `EventBlock` variant suite under-asserts: all five variant cases — including the `isOrphan`-overrides-`confirmed` case — assert only the same generic "renders a clickable button with title+time and fires onSelect," so the override branch and the unknown-status fallback are executed but their distinctive behavior is never verified; the test would still pass if `variantOf` returned `'planned'` for every input.

## Must Fix
- `apps/focal/client/src/features/calendar/EventBlock.test.tsx:82-93` — the variant `it.each` (incl. `orphan-overrides-confirmed` and the `migrated` unknown-status case) asserts only button role + title text + start-time + `onSelect`; it asserts nothing that distinguishes one variant from another. The stated property "isOrphan overrides confirmed" is unverified — the orphan branch's observable signal (the `AlertTriangle` icon at `EventBlock.tsx:116`, and/or the orphan-only `border-destructive ring-destructive/25` className at `EventBlock.tsx:101-102`) must be asserted so the override is actually proven (both are DOM/className-observable without reading computed styles, so this is not a brittle style assertion).

## Should Consider
- `EventBlock.test.tsx:105-111` — the color-fallback `it.each` proves "no variant crashes on null/blank/padded/non-hex color" but not the discriminating behavior: the padded-hex case (`'  #3b82f6  '`) exercises `isUsableColor`'s `.trim()` (trim-then-test vs test-raw at `EventBlock.tsx:16,72`), and non-hex must fall to `fallbackColor`. Asserting the resolved background/text color for the padded-hex-usable vs non-hex-fallback pair would turn coverage into a behavior check.
- `CalendarPage.test.tsx:188-192` — the now-line test asserts presence on the current week but not `nowTop` position, and there is no negative test that the marker is absent on a non-today/other week (the `isToday` guard at `CalendarPage.tsx:499`). The fixed clock makes both deterministic and cheap to add.

## Tests Reviewed
`lanes.test.ts` (edge cases + clamp — well covered), `CalendarPage.test.tsx` (fixed-clock determinism — sound), `EventBlock.test.tsx` (right inputs, non-discriminating assertions — see Must Fix); run log + biome/tsc/vitest green (full 323), no production-code change.

## Release Risk
Low

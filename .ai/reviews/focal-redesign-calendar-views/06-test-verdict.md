# Review Verdict

Reviewer: Opus
Step: test
Score: 9.2 / 10
Status: APPROVED

## Reason
The suite runs green (71/71 in `src/features/calendar`; 351/351 full client) and the tests cover the
design's risky paths — behavior-preservation through the `TimeGrid` lift, per-view `listEvents`
windows asserted via the date helpers (not hard-coded edges), `addMonthsClamped` short-month rollover,
the now-line present/absent invariant incl. day-anchored-off-today, the keyboard guard, mini-month
isolation, and the 42-cell month grid with `+N more` and day-zoom. Hygiene is clean (no `.only`/
`.skip`, no spec-IDs in names, fake-timers correctly bridged to `userEvent`), and i18n is complete in
both ru+en with correct plural families.

## Must Fix
None

## Should Consider
- The keyboard-guard test conflates the two guard branches: on popover open, focus lands on the title
  `<input>`, so the no-op is satisfied by both `tagName === 'INPUT'` and `popover` being truthy.
- Month-view-never-shows-the-now-line had no explicit assertion.
- No explicit now-line-absent assertion for a 3-day/week window that excludes today.

## Tests Reviewed
- `CalendarPage.test.tsx` + `dates.test.ts` (read in full); cross-referenced all 4 source components.
- `pnpm test:run src/features/calendar` → 6 files, 71 passed; `pnpm test:run` → 47 files, 351 passed.
- Verified en/ru calendar keys + RU plural categories; greps for `.only`/`.skip`/spec-IDs → none.

## Release Risk
Low

---
_Post-verdict: the two cheap, high-value now-line Should-Considers were applied — a new test
`never shows the now-line in the month view and hides it in a 3-day window past today` asserts both
the month-never-shows-it case and a 3-day window stepped past today (today-excluded → absent), making
the now-line invariant explicit across month + 3-day, not only day. The keyboard-guard isolation
Should-Consider was **accepted, not applied**: the page chrome has no standalone text input (every
input lives inside the popover), so the typing-guard branch cannot be exercised in isolation without
contrived DOM, and the user-facing behavior (no view-switch while editing) is already proven. Calendar
suite now 72 passed; lint clean._

# Verification report — focal-parity-calendar-bookings (re-run #2)

GPT Codex verified the change against the design. The two production defects from re-run #1 were confirmed
fixed and it proceeded to strengthen the tests; the codex process was killed (exit 144) after writing the
tests but before printing its final stdout report, so this report is reconstructed from the committed test
additions + an independently-green suite (re-run #1's report is in this folder's history).

## Confirmed fixes (re-run #1 defects)
- Optimistic-create rollback: `CalendarPage` booking onError now restores `setQueryData(bookingsKey,
  context?.previous ?? [])` (no guard), so a failed create from an initially-empty cache removes the temp
  chip. Test: a failed create from an empty cache leaves no chip.
- Date validation: `BookingDialog.onSubmit` blocks `!startDate || !endDate || endDate < startDate`. Test:
  an empty start date is blocked.

## Tests added by the verify pass (all green)
- Bookings are fetched with the wide containment-safe window `('2000-01-01','2100-12-31')` + active calendar scope.
- A booking crossing the visible week marks every covered visible day (7 chips) — the containment trap is avoided.
- Read-only calendars render booking chips as informational `<span>`s (not buttons).
- A same-render double-create from the dialog issues exactly one `createBooking` (the synchronous guard).

## Suite (independently re-run by Opus reviewer below)
`pnpm typecheck` 0 · `pnpm lint` 0 (316 files) · `pnpm test:run` 102 files / 1214 tests · `pnpm build` OK.

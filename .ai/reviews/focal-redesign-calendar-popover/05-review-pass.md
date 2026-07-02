# Review Verdict

Reviewer: GPT Codex
Step: review
Score: 8.4 / 10
Status: BLOCKED

## Reason
The slice is mostly aligned with the task and preserves the mutation contracts, but the recurring-scope dialog breaks the required cancel/retry path. Opening the dialog from inside the Radix popover causes the popover to dismiss on focus-out, so canceling the scope dialog loses the staged edit instead of returning to the popover.

## Must Fix
- `CalendarPage.tsx` clears the popover on any `onOpenChange(false)`, while the recurring dialog mounts as a separate Radix `Dialog`; `EventPopover.tsx` does not prevent the popover focus-out dismiss when that dialog autofocuses. Reproduced with a minimal Radix Popover→Dialog focus test: opening the dialog fired `popover onOpenChange false`, unmounted the popover, and left only the dialog. Violates the plan/design requirement that scope cancel closes only the dialog and preserves the draft for retry.

## Should Consider
- Add gate-6 coverage for canceling the recurring scope dialog, mutation failure after scope confirm, update-side mark-done, and activity/link clearing on edit.
- `RecurringScopeDialog.tsx` `DialogContent` has no description or explicit `aria-describedby={undefined}`, triggering Radix's missing-description dev warning.

## Tests Reviewed
Inspected `CalendarPage.tsx`, `EventPopover.tsx`, `RecurringScopeDialog.tsx`, `CalendarPage.test.tsx`, `EventBlock.test.tsx`, docs, prior build verdicts; ran a read-only Radix Popover/Dialog focus reproduction.

## Release Risk
Medium

---
_Fixes applied (back to build): EventPopover `onFocusOutside` preventDefault; CalendarPage popover
`onOpenChange` guarded on `pendingOp` (won't close while the scope dialog is up); RecurringScopeDialog
`aria-describedby={undefined}`. New test "keeps the popover open … when the scope dialog is cancelled"
proves the cancel-retry path. Re-verified green (330 tests). Remaining Should-Consider tests → gate 6._

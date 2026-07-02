# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.7 / 10
Status: BLOCKED

## Reason
The slice matches the planned popover/dialog architecture and preserves the core create/update/delete payload contracts, including explicit recurrence targets and `completed` for mark-done. One recurring-operation edge regresses pending-state safety: the scope dialog can submit the same mutation more than once.

## Must Fix
- `apps/focal/client/src/features/calendar/RecurringScopeDialog.tsx:72` leaves the OK button enabled with no pending guard, while `apps/focal/client/src/features/calendar/CalendarPage.tsx:237` keeps `pendingOp` active until mutation success. A double-click on OK for recurring update/delete can send duplicate PATCH/DELETE requests, unlike the old inline buttons and the new popover buttons that disable while pending.

## Should Consider
- Add test coverage for update-side mark-done and activity/link clearing on edit; the code paths look correct, but current tests mostly prove create-side links and exact recurring update payloads.

## Tests Reviewed
Inspected `CalendarPage.test.tsx` and `EventBlock.test.tsx`; did not rerun commands in the read-only sandbox. Build author reports `pnpm lint`, `pnpm typecheck`, `pnpm test:run`, and `pnpm build` green.

## Release Risk
Medium

---
_Fix applied: `handleScopeConfirm` now captures the pending op and clears `pendingOp` synchronously
(closing the dialog) before firing the mutation, so a double-click on OK cannot double-submit. The
Should-Consider (update-side mark-done / link-clearing tests) is routed to gate 6._

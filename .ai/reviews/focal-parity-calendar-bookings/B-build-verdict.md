# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 7.6 / 10
Status: BLOCKED

## Reason
The main UI wiring is present, but there are concrete correctness gaps in the edit/error paths. One can silently clear stored booking project/product metadata, and rejected booking mutations do not surface the localized error in the active dialog.

## Must Fix
- `superapp-parity/apps/focal/client/src/features/calendar/BookingDialog.tsx:80` / `superapp-parity/apps/focal/client/src/features/calendar/BookingDialog.tsx:96`: saving derives `project`, `projectType`, and `product` only from async reference query results, then sends `null` when those options are unavailable or still loading. In shared-editor mode with `canViewOtherPages=false`, or if the user saves before project/product queries resolve, editing an unchanged linked booking clears denormalized labels; the backend applies every sent field in `superapp-parity/apps/focal/server/app/services/bookings.py:69`.
- `superapp-parity/apps/focal/client/src/features/calendar/CalendarPage.tsx:458`: booking mutation errors only call the page-level `onMutationError`, rendered behind the modal at `superapp-parity/apps/focal/client/src/features/calendar/CalendarPage.tsx:793`. `BookingDialog` receives no error prop at `superapp-parity/apps/focal/client/src/features/calendar/CalendarPage.tsx:943`, so create/update/delete rejection does not show the required localized message in the active dialog.

## Should Consider
- `superapp-parity/apps/focal/client/src/features/calendar/MonthView.tsx:79` and `superapp-parity/apps/focal/client/src/features/calendar/YearView.tsx:99` render the non-interactive markers inside the day zoom buttons. This is valid HTML for spans and does not hijack clicks, but it is worth reconciling with the design wording that markers should not be nested in the cell button.
- Add coverage for update preserving linked booking metadata while reference queries are disabled/loading, mutation rejection messaging, rollback, persisted filter reload at page level, read-only mode, and the synchronous double-create guard.

## Tests Reviewed
Inspected `BookingDialog.test.tsx`, `CalendarPage.test.tsx`, `TimeGrid.test.tsx`, `bookings.test.ts`, and `bookingsFilter.test.ts`; did not run commands due the read-only review sandbox.

## Release Risk
High

# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 7.0 / 10
Status: BLOCKED

## Reason
The slice plan is mostly well-structured and the per-day coverage rule matches the old rendering model, but the design misses a backend windowing contract that would silently hide valid multi-day bookings. It also underspecifies parity for the dialog field set and mini-month data flow.

## Must Fix
- The proposed `listBookings(visible range)` contract cannot satisfy `startDate ≤ day ≤ endDate`: the backend list call only returns bookings fully contained in the requested window (`Booking.start_date >= window_start` and `Booking.end_date <= window_end`), and the DB test explicitly asserts overlapping bookings are excluded: `superapp-parity/apps/focal/server/app/services/bookings.py:24`, `superapp-parity/apps/focal/server/app/services/bookings.py:33`, `superapp-parity/apps/focal/server/app/services/bookings.py:34`, `superapp-parity/apps/focal/server/tests/test_bookings_db.py:147`. The design must specify a fetch strategy that includes bookings starting before or ending after the visible window, with tests for both cases.
- The `BookingDialog` scope drops existing booking metadata supported by old-focal and the API: description, product/productId, tags, and projectType are part of the create/update contract and old dialog save payload: `superapp-parity/apps/focal/client/src/api/openapi.d.ts:2682`, `superapp-parity/apps/focal/client/src/api/openapi.d.ts:2688`, `superapp-parity/apps/focal/client/src/api/openapi.d.ts:2690`, `superapp-parity/apps/focal/client/src/api/openapi.d.ts:2694`, `superapp/apps/old-focal/client/src/components/BookingDialog.tsx:261`. For a “full bookings UI,” the design must either include these fields or explicitly preserve/justify the reduced parity.
- The mini-month plan incorrectly implies threading the page’s current bookings into `MiniMonth`; the component intentionally owns an independent displayed month and event query so browsing the mini-month ahead stays accurate: `superapp-parity/apps/focal/client/src/features/calendar/MiniMonth.tsx:24`, `superapp-parity/apps/focal/client/src/features/calendar/MiniMonth.tsx:54`. Booking dots need the same independent-window strategy or a callback/data contract for the mini-month display range.

## Should Consider
- Ensure the TimeGrid all-day strip renders when bookings exist even if no all-day events exist; today it is gated only by `allDayByDay.size > 0` at `superapp-parity/apps/focal/client/src/features/calendar/TimeGrid.tsx:106`.
- Define how project/filter options behave for shared-calendar editors who can edit calendar items but cannot read other-pages reference data.

## Tests Reviewed
N/A

## Release Risk
High

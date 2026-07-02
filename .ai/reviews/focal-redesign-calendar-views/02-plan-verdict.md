# Review Verdict

Reviewer: Opus
Step: plan
Score: 9.2 / 10
Status: APPROVED

## Reason
The plan is minimum-viable and reuse-first: it extracts `TimeGrid` behavior-preservingly before adding views, and every claim I checked against the real code holds — the named constants/functions all exist in `CalendarPage.tsx`, the `onEdit`/`onCreate` signatures match `EventBlock.onSelect`/`openCreate` exactly, the per-view query-window table reproduces the current week derivation so existing tests stay green, the keyboard guard is fully specified, and the two prototype divergences (mini-month preserves view; month groups by `event.date` with no recurrence expansion) are surfaced and justified against the think/task.

## Must Fix
None

## Should Consider
- **Now-line visibility ownership is soft.** Today the now-line is inside the per-day column and keys off `isToday` (`CalendarPage.tsx:386-395`); the existing test asserts presence-on-current-week / absence-after-prev (`CalendarPage.test.tsx:508-517`). Make "`TimeGrid` renders the now-line iff `todayIso ∈ days`" an explicit invariant (day-anchored-off-today and today-excluded 3-day/week windows must also hide it; month never shows it), and confirm whether the slice-1 now-line test assertion is broadened vs kept verbatim.
- **`prevWeek`/`nextWeek` key retention is load-bearing but implicit.** Three existing tests query by these exact keys (`CalendarPage.test.tsx:128,514,523`); state outright that week *keeps* them while day/3-day/month get *new* view-aware keys, so the doer doesn't rename them into a generic `prev`/`next` and break those tests.
- **`MonthView` `+N more` plural.** Specify whether the key uses i18next pluralization (repo uses `_few`/`_many` RU forms) or a flat `{count}` interpolation, so RU is grammatical.

## Tests Reviewed
N/A (plan step). Verified the plan's claims against `CalendarPage.tsx` (extraction targets, callback signatures, query window, popover/guard state), `CalendarPage.test.tsx` (the tests pinning `listEvents` window, `prevWeek`/`nextWeek`, now-line, popover), `EventBlock.tsx:63`, `dates.ts`, `EventPopover.tsx`, `lanes.ts`, the prototype `Calendar.jsx` (MonthView/MiniMonth/ViewSwitcher/view-window/mini-month `onPick`:919), and en/ru locale parity.

## Release Risk
Low

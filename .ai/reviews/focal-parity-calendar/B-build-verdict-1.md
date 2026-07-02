# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.6 / 10
Status: BLOCKED

## Reason
The six requested behaviors are mostly implemented correctly: scroll-to-now is guarded by `daysKey`/`lastScrolledKey` and uses `HOUR_HEIGHT`, mini-month dots use the displayed-month `withCal` query, color precedence matches old-focal, all-day partitioning excludes chips from lanes, priority is guarded, and EN/RU keys are paired. However, the TimeGrid refactor introduces a real responsive layout regression: the pinned header/all-day strip and the timed grid now have independent horizontal scroll containers, so week/3-day overflow can desynchronize headers/chips from timed lanes.

## Must Fix
- `apps/focal/client/src/features/calendar/TimeGrid.tsx:115` creates a separate horizontal scroll container for the header/all-day strip, while `apps/focal/client/src/features/calendar/TimeGrid.tsx:179` creates an independent `overflow-auto` body scroll container. On narrow viewports, horizontally scrolling `data-testid="calendar-scroll"` moves the timed columns without moving the day headers/all-day chips, breaking column alignment that the prior single `overflow-x-auto` grid preserved. Use one shared horizontal scroller or explicitly synchronize horizontal scroll while keeping the owned vertical scroll ref.

## Should Consider
- Add a focused regression test for “events refetch does not reset user scroll”; the implementation is correct by inspection (`TimeGrid.tsx:87-105`), but current scroll tests only assert the initial today/fallback offsets (`TimeGrid.test.tsx:81-99`).
- Mini-month calendarId scoping is correct in code (`MiniMonth.tsx:32,62-65`) but not directly covered by tests.

## Tests Reviewed
Inspected `CalendarPage.test.tsx`, `MiniMonth.test.tsx`, `TimeGrid.test.tsx`, `EventBlock.test.tsx`, and `dates.test.ts`; reviewed `git diff feature/focal-migration...HEAD`, `git show --stat HEAD`, `git diff --check` (no diff-check findings; sandbox emitted xcrun cache warnings). Reviewed reported green full suite: `pnpm test:run` 80 files / 945 tests; did not rerun gates in this read-only review.

## Release Risk
Medium

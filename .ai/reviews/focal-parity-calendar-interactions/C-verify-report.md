Verification report for `focal-parity-calendar-interactions`.

I scrutinized the production change against `.ai/design/focal-parity-calendar-interactions-design.md`, focusing on pointer capture/stale state, outside-drop cancellation, 15-minute snap/clamp, read-only gating, recurring scope routing, optimistic rollback, shared-calendar forwarding, all-day exclusion, and backend-valid time formatting. Key paths reviewed: `EventBlock.tsx:180`, `EventBlock.tsx:202`, `EventBlock.tsx:232`, `EventBlock.tsx:243`, `EventBlock.tsx:260`, `TimeGrid.tsx:98`, `CalendarPage.tsx:277`, `CalendarPage.tsx:391`, `CalendarPage.tsx:402`. I found no production-code defect requiring a gate-B stop.

Added/strengthened tests only:
- `CalendarPage.test.tsx:1241`: proves drag-to-move forwards active shared `calendarId`.
- `CalendarPage.test.tsx:1309`: proves open-ended drag preserves `endTime: null`.
- `CalendarPage.test.tsx:1328`: proves read-only page wiring exposes no resize handles and does not persist drag.
- `EventBlock.test.tsx:515`: proves pointer cancel clears active drag without stale move/click suppression.
- `EventBlock.test.tsx:601`: proves top-edge resize enforces the 15-minute minimum.
- `EventBlock.test.tsx:670`: proves completed resize outside a day column cancels without editing.
- `TimeGrid.test.tsx:191`: proves `elementFromPoint` drop geometry supports cross-column move.
- `TimeGrid.test.tsx:238`: proves read-only grid suppresses drag/resize affordances.

Verification:
- Initial required `pnpm` path was blocked: `pnpm` failed before scripts with `[ERROR] fetch failed` under the no-network sandbox.
- Local equivalent typecheck: passed.
- Local equivalent lint: passed, 300 files checked.
- Targeted calendar tests: passed, 3 files / 112 tests.
- Full tests first reproduced an environment issue: 986 passed / 134 failed due Node 25 `localStorage` missing methods.
- With `NODE_OPTIONS=--localstorage-file=/private/tmp/focal-vitest-localstorage`: full tests passed, 93 files / 1120 tests.
- Build: passed. Vite emitted only existing warnings for deprecated `advancedChunks` and large chunks.

Working tree changes are limited to:
- `apps/focal/client/src/features/calendar/CalendarPage.test.tsx`
- `apps/focal/client/src/features/calendar/EventBlock.test.tsx`
- `apps/focal/client/src/features/calendar/TimeGrid.test.tsx`

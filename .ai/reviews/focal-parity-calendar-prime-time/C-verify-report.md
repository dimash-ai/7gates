Verification report for `focal-parity-calendar-prime-time` re-run #3:

I scrutinized the diff against `.ai/design/focal-parity-calendar-prime-time-design.md`, focusing on `CalendarPage`, `TimeGrid`, `PrimeTimeDialog`, settings API use, i18n strings, cache behavior, and the two previously reported races. No remaining real production defect found.

Confirmed fixes:
- Loading race is closed: `CalendarPage` disables Golden hours until `settings.isSuccess`, so the dialog cannot seed from loading `null` settings.
- Refetch race is closed: `PrimeTimeDialog` writes `queryClient.setQueryData(['settings'], saved)` on success and does not invalidate, so cache transitions old to saved without a stale refetch window.

Tests added/tightened:
- [CalendarPage.test.tsx](/Users/allosta/Desktop/allosta/superapp-parity/apps/focal/client/src/features/calendar/CalendarPage.test.tsx:1547): proves the loading-state button is disabled and clicking it does not open a dialog.
- [PrimeTimeDialog.test.tsx](/Users/allosta/Desktop/allosta/superapp-parity/apps/focal/client/src/features/calendar/PrimeTimeDialog.test.tsx:66): proves save success writes the server response into `['settings']` and does not call `invalidateQueries`.
- [PrimeTimeDialog.test.tsx](/Users/allosta/Desktop/allosta/superapp-parity/apps/focal/client/src/features/calendar/PrimeTimeDialog.test.tsx:83): covers disable/clear persisting `null` bounds.
- [PrimeTimeDialog.test.tsx](/Users/allosta/Desktop/allosta/superapp-parity/apps/focal/client/src/features/calendar/PrimeTimeDialog.test.tsx:99): proves save failure leaves the dialog open and leaves cached settings unchanged.

Verification:
- `git -C superapp-parity --no-pager diff feature/focal-migration...HEAD`: ran.
- `git -C superapp-parity status`: initially clean; now only the two intended test files are modified.
- Exact `pnpm` invocation is blocked in this sandbox: even `pnpm --version` exits with `[ERROR] fetch failed`.
- Local script-equivalent checks passed:
  - `tsc -b --pretty`: pass.
  - `biome check .`: 309 files, pass.
  - targeted Vitest: 3 files, 87 tests passed.
  - full Vitest with `NODE_OPTIONS=--localstorage-file=/private/tmp/focal-vitest-ls`: 99 files, 1173 tests passed.
  - `tsc -b`: pass.
  - `vite build`: pass, with existing chunk-size/deprecated `advancedChunks` warnings.
  - `git diff --check`: pass.

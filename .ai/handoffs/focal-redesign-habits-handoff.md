# Stage

Step 7 (ship) — slice 2 of the `focal-redesign-pages` epic: the **Habits page**.
Worktree `/Users/allosta/Desktop/superapp-habits-wt`, branch `feat/focal-redesign-habits`, single
commit `7b03d43` (base: the shell foundation `feat/focal-redesign-shell`).

# What changed

Brought the new Focal **Habits page** to parity with `apps/old-focal`'s habits UI, reproduced on the
new stack over the existing habits API, on the shell-token foundation.

- **Page shell** — `HabitsPage.tsx` is now a thin controller: the shared `PageHeader` (Repeat icon +
  Add-habit button) + a two-tab layout (Журнал / Графики), owning the create-dialog state and the
  shared query invalidation.
- **Journal tab** (`HabitJournal.tsx`) — re-skinned to old-focal's look: a 7-day week navigator + day
  strip (today/selected highlight), compact habit rows with colour dot + 🔥 streak, per-day status
  cells. Existing behavior preserved (the `none→yes→no→skip→none` cycle, up/down reorder,
  archive/restore/delete). Cells stay disabled until the week's entries load, so a tap can't overwrite
  an unloaded entry.
- **Charts tab** (`HabitCharts.tsx`) — the previously-missing Графики view, ported from old-focal's
  `HabitCharts`: a Recharts `ComposedChart` (stacked yes/no bars + a completion-rate trend line),
  a habit selector, period buttons (1w/1m/3m/6m/1y/3y), a colour-coded completion-rate badge, and a
  per-habit summary table. Backed by the existing `/api/habit-entries/stats` (a thin typed
  `listHabitEntryStats` wrapper was the only API addition). A stats error stays isolated to the charts
  tab.
- **Create dialog** (`HabitCreateDialog.tsx`) — old-focal-styled (colour swatches, type/frequency)
  producing the existing create payload; a failed save shows a visible in-dialog error.
- Pure chart date/bucket math extracted to `habitChartUtils.ts` (unit-tested), and `ru`/`en` habit copy.

# Files touched

- `apps/focal/client/src/features/habits/HabitsPage.tsx` (controller refactor)
- `apps/focal/client/src/features/habits/HabitJournal.tsx` (new — journal)
- `apps/focal/client/src/features/habits/HabitCharts.tsx` (new — charts)
- `apps/focal/client/src/features/habits/HabitCreateDialog.tsx` (new — dialog)
- `apps/focal/client/src/features/habits/habitChartUtils.ts` (new — pure date/bucket/rate helpers)
- `apps/focal/client/src/api/habits.ts` (+`listHabitEntryStats` typed wrapper)
- tests: `HabitsPage.test.tsx`, `habitChartUtils.test.ts`, `api/habits.test.ts`
- `apps/focal/client/src/i18n/locales/{en,ru}.json` (habit keys)

# Tests run

```sh
cd /Users/allosta/Desktop/superapp-habits-wt/apps/focal/client
pnpm lint        # biome: 223 files, 0 errors
pnpm typecheck   # tsc -b: 0 errors
pnpm test:run    # 51 files, 399 tests passed
pnpm build       # production bundle built
```

# Verification output

```sh
$ pnpm test:run
 Test Files  51 passed (51)
      Tests  399 passed (399)
$ pnpm build
✓ built in ~230ms (chunk-size warning only — pre-existing)
```

# Still needs review

- **Manual visual QA** (the one thing unit tests can't assert) — compare against old-focal in light AND
  dark: the journal (week strip, rows, status fills, streaks, archived), the charts tab (bars+trend
  line, period buttons, completion badge, summary table), and the create dialog.
- Frontend-only: no server / API / schema / behaviour change beyond adding the (already-backed) charts
  view. The matrix from the mockup screenshots is intentionally **not** built — old-focal has no matrix
  component and the entry model has no numeric/partial values, so it would be faked.
- Two cosmetic, non-blocking notes (verified against old-focal): the create dialog has no
  Enter-to-submit (neither does old-focal's), and an in-dialog create error can persist across a
  close/reopen until the next submit.

# PR / release notes (for users)

**The Habits page now matches the established Focal design — with its charts back.** The journal is a
clean weekly grid (tap a day to mark a habit done / skipped, with streaks), and a new **Charts** tab
shows your completion rate over time (per habit or overall, across 1 week to 3 years) plus a summary
table. Light and dark mode both match the rest of Focal. Nothing about how your habit data works has
changed — this restyles the page and adds the charts view.

(No secrets, tokens, keys, or PII in this change — it is UI components, a typed API wrapper for an
existing endpoint, locale strings, and tests.)

# Status

CODEX APPROVED (9.2) — all 7 gates passed (think 9.2 · plan 9.3 · design 9.4 · build 9.3 ·
review 9.3 · test 9.5 · ship 9.2). Cleared for release. Remaining before merge: manual light/dark
visual QA, and pushing the branch + opening the PR.

---
Cleared for release.

# Review Verdict

Reviewer: Opus
Step: plan
Score: 9.3 / 10
Status: APPROVED

## Reason
Every load-bearing claim checks out against source: `/api/habit-entries/stats` exists with query `{start, end, granularity?: "day"|"month"}` (openapi.d.ts:8392-8398) returning `HabitEntryStatRead {habitId, period, yes, no, skip}` (openapi.d.ts:3615-3627), which is exactly what old-focal `HabitCharts` consumes (HabitCharts.tsx:35-41) — so per-habit completion-rate lines are genuinely API-backed, not faked. The plan reuses all nine existing `api/habits.ts` wrappers and all five page mutations, adds only the one missing typed wrapper, draws the re-skin-vs-port boundary correctly, and explicitly refuses to fabricate the matrix's numeric/partial cells because `HabitEntryRead` carries only `status`. Minimum-viable, surgical, with a thorough failure map and tests that each state what they prove.

## Must Fix
None.

## Should Consider
- **Matrix AC is partially unmeetable and the plan doesn't say so plainly.** `design/focal/screenshots/habits-matrix.png` shows numeric values (2, 1.75, 1.5; 60/30/45) and a 3-state legend "Цель выполнена / Частично / Пропущено". The new model has no quantity field and no "partial" state (status enum `yes|no|skip`), and there is no matrix component in old-focal `components/habits/` to port from. The plan correctly refuses to fake the numbers — but the task AC "visually matches apps/old-focal … verified by screenshots" cannot be literally met for the matrix. State explicitly that the status-only grid is the agreed substitute so the test/ship gates don't fail against an impossible bar.
- **Slice 5's final command set omits `pnpm install --frozen-lockfile`** that the task's verification block lists. Deps are unchanged so it's low-risk, but that step proves "no lockfile drift."
- The chart period buttons (`month/3m/6m/year`) and per-habit lines follow `habits-chart.png`, deliberately diverging from the live `HabitCharts.tsx` (stacked bars, `1w…3y`). Confirm at design which is the binding contract for the build reviewer.

## Tests Reviewed
N/A (plan step). Verified the plan's wrapper/endpoint, schema, mutation-handler names (`onMutationError`, `createMutation.onError`), `PageHeader` props, and `tabs.tsx`/`dialog.tsx` primitives all exist in the worktree; `recharts ^3.8.1` installed (no dep change).

## Release Risk
Low

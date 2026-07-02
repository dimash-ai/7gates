# Goal

**Slice 2 of the `focal-redesign-pages` epic** (running after slice 0 `shell`; `tags` is a parallel
slice). Bring the new Focal **Habits page** (`apps/focal/client/src/features/habits`) to **exact
visual parity with `apps/old-focal`'s habits UI**, reproduced in the new stack over the existing
habits API, on the already-landed shell foundation (PR #55 — tokens now match old-focal exactly).

> **Worktree:** this slice is built in the git worktree `/Users/allosta/Desktop/superapp-habits-wt`
> on branch `feat/focal-redesign-habits`, based off the shell foundation `feat/focal-redesign-shell`
> (afaaeba). `apps/old-focal` is untracked in `superapp` (reference only) — read it from the main
> checkout `/Users/allosta/Desktop/allosta/superapp/apps/old-focal`.

> **Binding visual contract** = `apps/old-focal/client/src/pages/Habits.tsx` (a `Tabs` page:
> Журнал → `<HabitJournal>`, Графики → `<HabitCharts>`, + a `<HabitCreateDialog>` and the title/Add
> header) and `apps/old-focal/client/src/components/habits/{HabitJournal,HabitCharts,HabitCreateDialog}.tsx`.
> **Thing changed** = `apps/focal/client/src/features/habits/HabitsPage.tsx` (+ any sub-components it
> grows), restyled — **behavior + data flow preserved**, over the existing `api/habits.ts`.

# Scope

- Restyle the new HabitsPage to old-focal's exact habits look in **both tabs**:
  - **Журнал (journal)** — the habit-rows × day-cells grid (week navigator, per-day completion
    toggles, streak/treatment indicators) to old-focal `HabitJournal`.
  - **Графики (charts)** — the habit analytics charts to old-focal `HabitCharts` (Recharts on both;
    match chart types, colours via the now-old-focal tokens, matrix/year views per the design
    screenshots `habits-chart`, `habits-chart-year`, `habits-matrix`).
- The page header (title + Add-habit button) and the **create-habit dialog** to old-focal.
- i18next `ru` + `en` (reuse old-focal's habit copy); light + dark.

# Out of scope

- Any **server / API / schema / behavior** change — frontend re-skin over the existing habits API.
- **Heatmap** (Тепловая карта) — its own later slice, even though it's habit-adjacent.
- Habit **creation/streak logic** changes — visual only.
- **Lifting** old-focal's Tailwind-3 components / stack verbatim — reproduce on the new stack
  (Tailwind 4 / shadcn / the shell tokens).
- The shell/tokens (done in slice 0) — this slice composes them, does not change them.

# Acceptance criteria

- [ ] From the worktree: `cd /Users/allosta/Desktop/superapp-habits-wt/apps/focal/client &&
      pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` all green.
- [ ] The Habits page — journal grid, charts tab, header, create dialog — visually matches
      `apps/old-focal` in **light and dark**, verified by screenshots.
- [ ] Behavior preserved: habit list, per-day toggles, streaks, chart data, create flow unchanged;
      existing `HabitsPage.test.tsx` still green.
- [ ] Diff is surgical (habits feature only); no API/behavior change; no hardcoded strings.

# Verification commands

```sh
cd /Users/allosta/Desktop/superapp-habits-wt/apps/focal/client
pnpm install --frozen-lockfile
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```

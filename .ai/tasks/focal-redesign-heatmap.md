# Goal

Slice 3 of the `focal-redesign-pages` epic. Bring the Focal **Heatmap page** (Тепловая карта,
`apps/focal/client/src/features/heatmap`) to **exact visual parity with `apps/old-focal`**'s
`pages/Heatmap.tsx`, reproduced in the new stack over the **existing** APIs, inheriting the slice-0
foundation tokens. Frontend-only re-skin; no behaviour change.

> **Worktree:** this slice is developed in an isolated git worktree at
> `/Users/allosta/Desktop/superapp-heatmap-wt` on branch `feat/focal-redesign-heatmap`, cut off the
> foundation branch `feat/focal-redesign-shell` (so it inherits old-focal's tokens). Deps installed.
> `.ai/` pipeline artifacts live in the outer repo as usual.

> **Binding visual contract** = `apps/old-focal/client/src/pages/Heatmap.tsx` (+ `Heatmap.test.ts`,
> and the shared `PageToolbar`/`SidebarToggle`, `ui/multi-select`, `HelpTooltip` it composes).
> **Thing changed** = `apps/focal/client/src/features/heatmap/HeatmapPage.tsx`. The pure logic
> (`heatmap.ts`) and its test stay; the API wiring stays.

> **Re-skin, not rebuild.** The new page is already a close functional port of old-focal's heatmap
> (same 12-month grid, filter modes, legend, per-day tooltips, year nav, persisted filters). The gap
> is **visual fidelity**: it renders a bespoke header instead of the shared `PageHeader`; colours the
> day cells with raw `bg-yellow-400/green-500/red-500` instead of old-focal's `getHeatmapColor`
> mapping; and uses chip buttons instead of old-focal's `MultiSelect`. Match old-focal exactly,
> reproduced on Tailwind 4 + the existing shadcn primitives.

# Scope

- Restyle `HeatmapPage.tsx` to old-focal's exact look: the header (title + year stepper + filter
  controls + legend), the month-card grid, the day-cell colour scale, weekday headers,
  weekend/today treatment, and the per-day tooltip — matching `apps/old-focal/.../Heatmap.tsx`.
- Replace the raw cell colours with old-focal's heatmap colour mapping (light/optimal/overload),
  and the filter chips with the shared `MultiSelect` primitive where old-focal uses it.
- Keep the existing API queries (`listEvents`/`getBudgetYear`/`listProjects`/`listSpheres`), the
  pure logic in `heatmap.ts`, the persisted-filters behaviour, and i18next strings (`ru` + `en`).

# Out of scope

- Any **server / API / schema / behaviour** change, and any change to `heatmap.ts` thresholds/logic
  (if old-focal's load thresholds differ, flag it — don't silently change behaviour).
- The shared shell (done in slice 0) beyond using `PageHeader` here.
- Other feature pages (their own slices). Lifting old-focal's Tailwind-3 / React-18 code verbatim.

# Acceptance criteria

- [ ] From the worktree: `cd /Users/allosta/Desktop/superapp-heatmap-wt/apps/focal/client && pnpm
      lint && pnpm typecheck && pnpm test:run && pnpm build` all green.
- [ ] The Heatmap page visually matches `apps/old-focal` in **light and dark** — header, filters,
      legend, month cards, day-cell colour scale, weekend/today, and tooltip.
- [ ] Behaviour preserved: filtering, year navigation, persisted filters, and the data shown are
      unchanged; `heatmap.test.ts` still green (logic untouched).
- [ ] Surgical diff (the heatmap feature + its tests only); no API/behaviour change; i18next `ru`+`en`.

# Verification commands

```sh
cd /Users/allosta/Desktop/superapp-heatmap-wt/apps/focal/client
pnpm install --frozen-lockfile
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```

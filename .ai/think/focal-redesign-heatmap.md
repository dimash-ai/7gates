# Problem

Slice 3 of `focal-redesign-pages`: bring the Focal **Heatmap page** to **exact visual parity with
`apps/old-focal`**'s `pages/Heatmap.tsx`, reproduced on the new stack over the **existing** APIs,
inheriting the slice-0 foundation tokens. Done in an isolated worktree
(`/Users/allosta/Desktop/superapp-heatmap-wt`, branch `feat/focal-redesign-heatmap` off
`feat/focal-redesign-shell`).

The favourable starting point: the new `HeatmapPage.tsx` is **already a close functional port** of
old-focal's heatmap — same 12-month card grid, the same filter modes
(`all/mission/provision/workTime/spheres/projects/products`), year stepper, light/optimal/overload
legend, per-day tooltip with the day's events, and persisted filters — all wired to the real
`events`/`budget`/`projects`/`spheres` queries with the pure math in `heatmap.ts`. So this is **not**
a rebuild; it is a **visual re-skin** of the parts that diverge from old-focal:

1. **Header** — the new page renders a bespoke `<header>` (title + subtitle + inline year nav +
   filters + legend). The redesign's shared `PageHeader` (landed slice 0, matching old-focal's
   per-page header) should host the title + collapse trigger; old-focal's Heatmap header layout is
   the contract for the year stepper + filter row + legend placement.
2. **Day-cell colour scale** — the new page uses raw `bg-yellow-400 / bg-green-500 / bg-red-500`
   (`HeatmapPage.tsx:47-52`); old-focal maps levels through `getHeatmapColor(level) → {bg, text}`
   (`Heatmap.tsx:182`). Match old-focal's exact colours.
3. **Multi-select** — the new page uses bespoke chip buttons (`multiSelectRow`); old-focal uses the
   shared `ui/multi-select` `MultiSelect` (`Heatmap.tsx:33`). Use the shared primitive where
   old-focal does.

# Assumptions

- **[confirmed — worktree]** The worktree is cut off the foundation and carries old-focal's tokens
  (8× `217 91% 48%` in its `index.css`); deps installed. So the cascade (palette/radius/shadows) is
  already old-focal; this slice only restyles the page's own structure/classes.
- **[confirmed — inspection]** `HeatmapPage.tsx` (455 lines) is functional over real APIs
  (`listEvents`/`getBudgetYear`/`listProjects`/`listSpheres`) with pure logic in `heatmap.ts` (130
  lines) + `heatmap.test.ts` (167) — a re-skin over working data, not a rebuild.
- **[confirmed — fs]** old-focal's contract is `pages/Heatmap.tsx` (35 KB) + `Heatmap.test.ts`; it
  composes `PageToolbar`/`SidebarToggle`, `ui/multi-select`, `HelpTooltip`, `Select`, `Tooltip`, and
  a `getHeatmapColor` level→colour map; structure (12-month grid, filters, legend, tooltips) already
  matches the new page closely.
- **[confirmed — repo CLAUDE.md]** new stack = React 19 + Tailwind 4 + shadcn + i18next; reproduce
  old-focal's look, don't lift its Tailwind-3 code.
- **[unverified — settle at the design gate by deep-reading old-focal `Heatmap.tsx`]** the exact
  `getHeatmapColor` values (light/optimal/overload bg+text) and whether they map onto the foundation's
  semantic tokens (`--warning`/`--success`/`--destructive`) or stay literal; whether old-focal hosts
  the title in the shared `PageHeader` or a custom band; the precise filter-row + legend layout; and
  whether old-focal's load thresholds match `heatmap.ts` (if not, that's a flagged behaviour question,
  not a silent change).

# Options considered

The design-source fork is settled (exact old-focal). The remaining fork is **how** to reach parity.

| # | Option | What it is | Pros | Cons |
|---|--------|-----------|------|------|
| **A — Re-skin in place (chosen)** | Restyle `HeatmapPage.tsx`'s chrome + colour scale + multi-select to old-focal, keep `heatmap.ts`, the queries, and the FilterMode logic. | Surgical; preserves the working data path + persisted-filters + tests; matches the slice-0/other-slice pattern; independently testable. | We hand-translate old-focal's classes onto the existing JSX. |
| **B — Rebuild from old-focal `Heatmap.tsx`** | Re-implement the page from old-focal's source. | Maximal literal fidelity. | Throws away a working, tested port; re-wires the data layer (old-focal's `apiRequest`/calendar-filter context differ from the new typed `api/*`); larger diff, higher regression risk. Rejected. |
| **C — Lift old-focal code** | Copy old-focal's page wholesale. | Fast. | Tailwind-3 + React-18 + old query layer (forbidden / wrong data layer). Rejected. |

# Recommendation

**Option A — re-skin in place.** Host the title (+ collapse trigger) in the shared `PageHeader`
(slice-0 chrome, matching old-focal's per-page header), keep the year stepper + filter row + legend
but restyled to old-focal's layout, swap the raw cell colours for old-focal's `getHeatmapColor`
mapping (re-anchored onto the foundation's semantic tokens where they correspond), and use the shared
`MultiSelect` where old-focal does. Keep `heatmap.ts`, the four queries, persisted filters, and the
i18n keys. Plan shape (settled at gate 2/3):
1. Deep-read old-focal `Heatmap.tsx` → exact colours, header layout, filter/legend structure.
2. Restyle the header (PageHeader + year stepper + filters + legend) to match.
3. Swap the day-cell colour scale to old-focal's mapping; restyle month cards / weekday / today /
   weekend / tooltip.
4. Replace chip filters with `MultiSelect` where old-focal uses it.
5. Keep/extend tests; `pnpm lint && typecheck && test:run && build` green in the worktree;
   screenshot light+dark vs old-focal.

# Out of scope

- Any server / API / schema / **behaviour** change; no change to `heatmap.ts` thresholds (a
  divergence from old-focal's thresholds is **flagged**, not silently applied).
- The shared shell beyond consuming `PageHeader`; other feature pages; lifting old-focal's stack.

# Open questions

- **Exact `getHeatmapColor` values** and whether to bind them to `--warning/--success/--destructive`
  (preferred, so dark mode + theme stay coherent) or keep old-focal's literals — settled at design by
  reading old-focal `Heatmap.tsx:182`.
- **Header**: adopt the shared `PageHeader` (consistent with the redesign + old-focal's per-page
  header) vs reproduce old-focal's exact custom band — settled at design.
- **Load thresholds**: confirm `heatmap.ts` matches old-focal's `getLoadLevel`; if not, raise a
  behaviour question rather than changing logic in a visual slice.

# Success criteria

- [ ] From the worktree: `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green.
- [ ] Heatmap matches `apps/old-focal` in light + dark — header, filters, legend, month cards,
      day-cell colour scale, weekend/today, tooltip — by screenshot.
- [ ] Behaviour preserved (filtering, year nav, persisted filters, data shown); `heatmap.test.ts`
      green with logic untouched.
- [ ] Surgical diff (heatmap feature + tests only); no API/behaviour change; i18next `ru` + `en`;
      reproduced on Tailwind 4 (no Tailwind-3 config/PostCSS).

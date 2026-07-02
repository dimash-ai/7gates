# Stage

Step 7 (ship) — slice 3 of the `focal-redesign-pages` epic: the Heatmap page.
Worktree `/Users/allosta/Desktop/superapp-heatmap-wt`, branch `feat/focal-redesign-heatmap`,
single commit `565071c` (base: slice-0 foundation `feat/focal-redesign-shell`).

# What changed

Re-skinned the Focal **Heatmap page** to exact `apps/old-focal` parity, reproduced on the new
Tailwind-4 / React-19 / shadcn stack, over the **existing** APIs (`listEvents`/`getBudgetYear`/
`listProjects`/`listSpheres`) with the pure logic in `heatmap.ts` untouched. Frontend-only re-skin.

- **Bespoke header** matching old-focal (a `hidden md:block` desktop layout + a `md:hidden` mobile
  layout): `SidebarTrigger` (`h-8 w-8`) + a year stepper + the shared `PageToolbar` + a help tooltip
  + subtitle; a filter row (mode `Select` + the conditional `MultiSelect` + reset + filtered/total
  count) + legend + per-day label; and the **no-time-budget warning** (`Alert`, shown when the budget
  query has no data, with an 8 h/day fallback).
- **Day-cell colour scale** = old-focal's `getHeatmapColor` literals (`bg-yellow-400`/`green-500`/
  `red-500`/`muted`); month cards/tooltip restyled to old-focal classes (`rounded-lg`, `p-2 md:p-3`,
  no shadow, tooltip `max-w-[280px] p-0`).
- **Weekday header labels** = old-focal's fixed `Пн/Вт/…` (ru) / `Mo/Tu/…` (en); the per-day **tooltip
  date** renders in old-focal's `d MMMM, EEEE` order with the grammatically-correct Russian **genitive**
  month ("6 января, вторник"), produced from `Intl` parts (no new dependency).
- **New generic `ui/multi-select` primitive** — the new client lacked one (old-focal's used `cmdk`,
  which isn't present). Built from existing `Popover`/`Badge`/`Input` primitives; controlled,
  searchable, with selected badges + "+N" overflow + clear-all, and an accessible (no nested-button)
  option list.
- **i18n**: added `focal.heatmap.*` keys (help, the no-budget warning, the multi-select copy) in both
  `en` and `ru`.

# Files touched

- `apps/focal/client/src/features/heatmap/HeatmapPage.tsx` (re-skin) + `HeatmapPage.test.tsx` (new)
- `apps/focal/client/src/components/ui/multi-select.tsx` (new generic primitive) + `multi-select.test.tsx` (new)
- `apps/focal/client/src/i18n/locales/en.json` + `ru.json` (new `focal.heatmap.*` keys)

# Tests run

```sh
cd superapp-heatmap-wt/apps/focal/client
pnpm lint        # biome: 220 files, 0 errors
pnpm typecheck   # tsc: 0 errors
pnpm test:run    # 51 files, 379 tests passed
pnpm build       # production bundle built
```

# Verification output

```sh
$ pnpm test:run
 Test Files  51 passed (51)
      Tests  379 passed (379)
$ pnpm build
✓ built (pre-existing chunk-size warning only)
```

# Still needs review

- **Manual visual QA** is the one thing unit tests can't assert — compare against old-focal in light
  AND dark, desktop + mobile: the header (filters, `MultiSelect`, legend, no-budget warning), the
  month-card grid, the day-cell colour scale (light/optimal/overload/empty), weekend/today, and the
  tooltip (incl. the Russian genitive date).
- Frontend-only: no server / API / schema / behaviour change. `heatmap.ts` thresholds confirmed
  identical to old-focal, so the data shown is unchanged.

# PR / release notes (for users)

**The Focal workload heatmap now matches the established Focal design.** The yearly heatmap — its
header, filters, colour scale, month cards, and per-day tooltip — now looks exactly like the proven
Focal app, in both light and dark mode, including the correct Russian date wording in tooltips. The
sphere/project/product filters use a cleaner multi-select. This is a visual change only; what the
heatmap shows and how it's calculated is unchanged.

(No secrets, tokens, keys, or PII — CSS/markup, a new UI component, tests, and translation strings.)

# Status

CODEX APPROVED (9.2) — all 7 gates passed (think 9.0 · plan 9.2 · design 9.6 · build 9.4 ·
review 9.4 · test 9.5 · ship 9.2). Cleared for release. Remaining before merge: manual light/dark
visual QA, and pushing the branch + opening the PR into `feature/focal-migration`.

---
Cleared for release.

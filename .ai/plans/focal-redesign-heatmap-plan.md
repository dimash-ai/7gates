# Summary

Reskin the new Focal Heatmap page in place over its existing typed API queries and pure
`heatmap.ts` logic. The gate-1 open questions are resolved from old-focal: `getHeatmapColor`
uses literal Tailwind classes (`light -> bg-yellow-400 text-gray-800`, `optimal -> bg-green-500
text-white`, `overload -> bg-red-500 text-white`, `empty -> bg-muted/30
text-muted-foreground`), old-focal's load thresholds match the current `loadLevel`, the binding
header is the custom desktop/mobile layout at `old-focal` `Heatmap.tsx:463` / `:588`, and the
no-time-budget warning at `:578` / `:705` is in parity scope. Keep behavior and data flow unchanged;
only translate the old visual contract onto the new Tailwind 4 / shadcn stack.

# Files to change

| path | change | why |
|------|--------|-----|
| `/Users/allosta/Desktop/superapp-heatmap-wt/apps/focal/client/src/features/heatmap/HeatmapPage.tsx` | Replace the bespoke header/filter/card classes with old-focal parity, consume `PageHeader` for the title/collapse/toolbar row, swap raw day-cell colors to old-focal's exact `getHeatmapColor` mapping, use `MultiSelect` for sphere/project/product filters, and render the missing-time-budget warning. | This is the binding UI surface for the heatmap slice; the existing queries, filters, year navigation, tooltip data, and day math stay intact. |
| `/Users/allosta/Desktop/superapp-heatmap-wt/apps/focal/client/src/features/heatmap/HeatmapPage.test.tsx` | Add page-level tests around header controls, warning fallback, exact load-color classes, filter controls, reset, and preserved year/data behavior. | Existing `heatmap.test.ts` covers pure logic only; the visual reskin needs component coverage for the behavior it could break. |
| `/Users/allosta/Desktop/superapp-heatmap-wt/apps/focal/client/src/components/ui/multi-select.tsx` | Add a small controlled shared `MultiSelect` primitive compatible with old-focal's props, implemented with current `Button`, `Badge`, `Popover`, `Input`, and `Checkbox` primitives. | The new client currently has no `ui/multi-select` and no `ui/command`; this is the smallest way to satisfy the explicit old-focal shared-primitive requirement without adding packages. |
| `/Users/allosta/Desktop/superapp-heatmap-wt/apps/focal/client/src/components/ui/multi-select.test.tsx` | Cover placeholder rendering, selected badges, search/empty state, option toggling, and clear-all behavior. | The added shared primitive should be independently reviewable and not rely only on the heatmap page tests. |
| `/Users/allosta/Desktop/superapp-heatmap-wt/apps/focal/client/src/i18n/locales/en.json` | Add missing `focal.heatmap` strings for no-time-budget warning and multi-select placeholders/search/empty text. | The warning and new accessible UI copy must not be hardcoded. |
| `/Users/allosta/Desktop/superapp-heatmap-wt/apps/focal/client/src/i18n/locales/ru.json` | Add the same `focal.heatmap` keys in Russian, matching old-focal copy where applicable. | RU and EN stay complete for the heatmap page. |

No `heatmap.ts`, API wrapper, generated OpenAPI, `PageHeader`, shell, package, or lockfile change is planned.

# Implementation slices

1. Add the missing reusable multi-select and locale keys.
   - Add `MultiSelectOption` and a controlled `MultiSelect` with the old-focal prop shape:
     `options`, `selected`, `onChange`, `placeholder`, `searchPlaceholder`, `emptyText`,
     `className`, `disabled`, and `maxDisplay`.
   - Use existing primitives only: `Popover`, `Button`, `Badge`, `Input`, `Checkbox`, `ScrollArea`
     if needed, and `cn`. Do not add `cmdk`, `ui/command`, or any package dependency.
   - Add EN/RU keys for `noTimeBudgetWarning`, sphere/project/product placeholders, search
     placeholder, empty text, and clear selection label.
   - Add `multi-select.test.tsx` before the heatmap page consumes it. Build should remain green
     because `HeatmapPage` has not changed yet.

2. Rebuild the header chrome to the resolved old-focal layout.
   - Import and use the shared `PageHeader` for title/collapse/help-adjacent title row and toolbar
     ownership; do not edit `PageHeader`.
   - Recreate old-focal's heatmap-specific controls around it: desktop title/header rhythm from
     `Heatmap.tsx:463-585` and mobile stacked rows from `:588-712`.
   - Desktop contract: year stepper with outline icon buttons and a `min-w-[60px]` year label; row
     below with filter select, conditional multi-select, icon-only reset, filtered/total count,
     flex spacer, three-item legend, per-day label, and `Alert` warning with `mt-2 py-2`.
   - Mobile contract: compact title row, year/toolbar row, subtitle/filter/legend row with tiny
     legend chips, and warning with `mx-3 mb-2 py-2`.
   - Keep `setYear`, query keys, `navigate('/calendar')`, `hasActiveFilters`, and persisted filter
     state unchanged.

3. Replace filter chips with the shared `MultiSelect`.
   - Delete the local `multiSelectRow` helper.
   - Build old-focal-equivalent options: spheres use `value: sphere.name` and label/name color
     fallback `#3b82f6`; root projects/products use ids, labels, and project colors when present.
   - Use desktop widths `w-[200px]` and mobile `min-w-0 flex-1 max-w-[160px]` to match old-focal.
   - Keep empty selection semantics unchanged: a sphere/project/product filter with no selected
     values passes all events for that mode.
   - Reset remains local: set mode to `all`, clear all selected arrays, and call `clearFilters()`.

4. Apply old-focal heatmap grid, cell, skeleton, legend, and tooltip classes.
   - Replace `LEVEL_CLASSES` with old-focal's exact `getHeatmapColor` mapping:
     `light: bg-yellow-400 text-gray-800`, `optimal: bg-green-500 text-white`,
     `overload: bg-red-500 text-white`, `empty: bg-muted/30 text-muted-foreground`.
   - Keep `heatmap.ts` load thresholds unchanged because old-focal's `getLoadLevel` uses the same
     `< workingHoursPerDay - 2`, `<= workingHoursPerDay`, and `> workingHoursPerDay` split.
   - Match old-focal grid rhythm: outer padding `p-2 md:p-4`, grid `gap-3 md:gap-4`, month card
     `p-2 md:p-3 rounded-lg border bg-card`, no extra shadow, month heading
     `text-sm md:text-base`, weekday labels `text-[8px] md:text-[10px]`, day labels
     `text-[8px] md:text-[10px]`, hover `transition-all hover:scale-125 hover:z-10`, today
     `ring-2 ring-primary ring-offset-1`, weekend empty `text-red-400`.
   - Match old tooltip padding: `TooltipContent className="max-w-[280px] p-0"` with an inner
     `p-2` wrapper, same total line, event list, and no-events copy.
   - Match skeleton sizing with old-focal's `p-2 md:p-3 rounded-lg border bg-card` and
     `gap-3 md:gap-4`.

5. Add the no-time-budget warning without changing the API contract.
   - Keep `getBudgetYear(year)` and the `BudgetYear` generated type unchanged.
   - Derive `workingHoursPerDay` with optional access and fallback `8`.
   - Render the old-focal warning when the budget query has settled without usable
     `settings` data, including a query error or a test/mock shape missing `settings`.
   - Do not introduce a blocking page error for budget failures; old-focal falls back to 8h/day and
     warns.

6. Final verification and screenshot parity.
   - Run focused tests first: `pnpm test:run src/components/ui/multi-select.test.tsx
     src/features/heatmap/HeatmapPage.test.tsx src/features/heatmap/heatmap.test.ts`.
   - Then run the required full client checks from the worktree:
     ```sh
     cd /Users/allosta/Desktop/superapp-heatmap-wt/apps/focal/client
     pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
     ```
   - Compare light and dark screenshots against
     `/Users/allosta/Desktop/allosta/superapp/apps/old-focal/client/src/pages/Heatmap.tsx`,
     covering desktop and mobile header rows, warning, legend, month cards, day colors, weekend,
     today, filters, and tooltip.

# Tests

- `components/ui/multi-select.test.tsx`: renders placeholder and collapsed trigger; proves the
  shared primitive has a stable accessible default state.
- `components/ui/multi-select.test.tsx`: toggles options and calls `onChange` with the next
  selected array; proves it is controlled and does not own heatmap filter state.
- `components/ui/multi-select.test.tsx`: shows selected badges plus `+N` overflow and clears all;
  proves old-focal selected-summary behavior without page coupling.
- `components/ui/multi-select.test.tsx`: filters options through the search input and renders empty
  text; proves large option lists remain usable without adding `cmdk`.
- `HeatmapPage.test.tsx`: renders the shared header title, year stepper, filter select, legend, and
  per-day label from mocked APIs; proves the new header still consumes the existing data path.
- `HeatmapPage.test.tsx`: previous/next year buttons refetch events and budget for the new year;
  proves year navigation behavior survived the header move.
- `HeatmapPage.test.tsx`: a budget response with no usable `settings` renders the
  no-time-budget warning and `8h/day`; proves the gate-1 warning requirement.
- `HeatmapPage.test.tsx`: mocked day events produce light, optimal, overload, and empty cells with
  the exact old-focal classes; proves the resolved `getHeatmapColor` mapping.
- `HeatmapPage.test.tsx`: sphere/project/product modes render `MultiSelect`, update selected values,
  and change the filtered/total count; proves old chip controls were replaced without changing
  filter semantics.
- `HeatmapPage.test.tsx`: reset clears mode/selections and removes persisted filters; proves the
  old-focal reset affordance still calls the existing persistence helpers.
- `HeatmapPage.test.tsx`: tooltip shows total hours, percentage, sorted event rows, duration text,
  and no-events copy; proves visual tooltip changes did not drop event data.
- Existing `heatmap.test.ts`: stays unchanged and green; proves load thresholds, storage migration,
  filter matching, duration math, and formatting remain behaviorally intact.

# Error & rescue map

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| `heatmap.budget.missingSettings` | No exception; settled budget data lacks `settings` | `HeatmapPage` derived budget state | Old-focal warning copy and fallback `8h/day`; heatmap still renders. |
| `heatmap.budget.queryFailed` | `getBudgetYear(year)` rejects through React Query | `HeatmapPage` budget query state | Same warning and fallback `8h/day`; no blocking error screen. |
| `heatmap.events.queryFailed` | `listEvents(start, end)` rejects through React Query | Existing `events.data ?? []` fallback in `HeatmapPage` | Heatmap renders empty-load cells and filters show `0/0`; no new error UI is introduced in this visual slice. |
| `heatmap.projects.queryFailed` | `listProjects()` rejects through React Query | Existing `projects.data ?? []` fallback and `MultiSelect` empty state | Project/product multi-selects show empty text; other modes and the heatmap remain usable. |
| `heatmap.spheres.queryFailed` | `listSpheres()` rejects through React Query | Existing `spheres.data ?? []` fallback and `MultiSelect` empty state | Sphere multi-select shows empty text; other modes and the heatmap remain usable. |
| `heatmap.filterStorage.unavailable` | `localStorage` get/set/remove throws | Existing `loadFilters`, `saveFilters`, and `clearFilters` catches in `heatmap.ts` | Defaults are used or reset is best-effort; no visible error, matching current behavior. |
| `heatmap.multiselect.noOptions` | No exception; options array is empty or search has no matches | `MultiSelect` render branch | Localized empty text inside the popover; selected filters remain unchanged. |

# Review lenses (pre-answer before gate2-plan)

- **Scope / strategy** - This is the minimum complete reskin: one page, a required shared
  multi-select primitive because the new client lacks one, tests, and locale copy. Existing
  `heatmap.ts`, API wrappers, query keys, route, shell, and tokens remain the behavioral base. The
  color-map question is settled in favor of old-focal's literal classes rather than semantic tokens
  because the task asks for exact parity.
- **Architecture** - Data still flows through `listEvents`, `getBudgetYear`, `listProjects`, and
  `listSpheres`. UI-only state stays in `HeatmapPage`: year, filter mode, selected ids/names, and
  persisted filters. `MultiSelect` is controlled and has no knowledge of heatmap filtering. Budget
  fallback is derived in the page and does not change the generated `BudgetYear` type or API
  wrapper.
- **Design** - Desktop and mobile header rows explicitly follow old-focal's resolved contract,
  including the warning. Loading, missing-budget, empty-option, no-event tooltip, weekend, today,
  light/optimal/overload/empty, and responsive month-grid states are covered. Controls remain
  keyboard-accessible through native buttons, Radix popover, input, and checkbox primitives.
- **DevEx** - No new package, route, backend call, generated type, shell edit, or Tailwind config
  change. Tests assert visible behavior, API calls, and targeted class contracts for the color map
  instead of broad snapshots.

# Risks & migrations

- No database migration, data backfill, server/API/schema change, generated OpenAPI change,
  environment variable, package dependency, or lockfile update.
- Main risk: old-focal's heatmap header is more custom than the shared `PageHeader` can express by
  itself. Mitigation: compose `PageHeader` only for the shared title/collapse/toolbar responsibility
  and keep heatmap-specific desktop/mobile control strips in `HeatmapPage`; do not edit
  `PageHeader`.
- Secondary risk: adding `ui/multi-select` is outside the heatmap feature folder. It is still the
  smallest honest implementation of the explicit shared-primitive requirement because the target
  client has no existing multi-select. Keep it generic, tested, and dependency-free.
- Rollback plan: revert the planned files only. No persistent data shape or API contract changes are
  introduced.

# Scope check

- [x] Matches the task's Scope and Out of scope.
- [x] Small enough to review in one sitting.
- [x] Size smell checked: the only non-heatmap implementation file is the missing shared
      `MultiSelect`; it is necessary for the old-focal parity requirement and is independently
      testable.

# Out of scope

- Any server, API, schema, generated OpenAPI, or `heatmap.ts` threshold/logic change.
- Tailwind config, foundation tokens, shared shell, `PageHeader`, or unrelated shadcn primitive
  changes.
- Cross-calendar/data-owner behavior from old-focal's `CalendarFilterContext`; the new app does not
  expose that context in this slice.
- Rebuilding or copying old-focal's full React 18/Tailwind 3 page.
- Other Focal pages or broader redesign cleanup.

# Design — focal-redesign-heatmap (slice 3)

Re-skin `apps/focal/client/src/features/heatmap/HeatmapPage.tsx` to exact `apps/old-focal`
`pages/Heatmap.tsx` parity, in the worktree (`/Users/allosta/Desktop/superapp-heatmap-wt`, branch
`feat/focal-redesign-heatmap`), over the existing queries + `heatmap.ts` logic (untouched). Adds one
shared primitive (`ui/multi-select`) the new client lacks. Reproduced on Tailwind 4 / shadcn — no
old-focal Tailwind-3 code lifted.

## 1. Header — reproduce old-focal's bespoke header (desktop + mobile), NOT the shared `PageHeader`

old-focal's Heatmap uses its **own** header band (`Heatmap.tsx:463`), not the shared page header — a
`hidden md:block` desktop layout and a separate `md:hidden` mobile layout with distinct stacked rows.
Exact parity requires reproducing **both** (the shared `PageHeader` is a single flex row and cannot
express old-focal's mobile stacking, so heatmap does not use it). Render `<header className="border-b
bg-card/50 shrink-0">` containing:

- **Desktop (`hidden md:block p-4 md:p-6`)** — row 1 (`flex items-center justify-between`): left =
  `SidebarTrigger` + `<h1 className="text-2xl font-bold">{title}</h1>` + a help tooltip (`HelpCircle`
  → `focal.heatmap.help`), with the subtitle below (`text-muted-foreground text-sm mt-1 ml-9`); right
  (`flex items-center gap-4`) = the year stepper (outline icon `ChevronLeft`/`ChevronRight` +
  `min-w-[60px] text-center text-lg font-semibold` year) + `<PageToolbar />`. Row 2 (`mt-3 flex
  flex-wrap items-center gap-2 md:gap-3`): `Filter` icon + `Select w-[160px] h-8 text-sm` (7
  `FILTER_MODES`) + conditional `MultiSelect className="w-[200px]"` + ghost reset (`X`, when
  `hasActiveFilters`) + `{filtered}/{total}` count (mode≠all); `flex-1`; legend (`h-3 w-3 rounded-sm`
  swatch + label + `(range)`); `{workingHoursPerDay}{hourUnit}/day`. Then the warning (§2).
- **Mobile (`md:hidden`)** — old-focal's stacked rows (`:588-712`): row 1 (`px-3 py-2 flex items-center
  gap-1.5`) `SidebarTrigger` + `<h1 className="text-lg font-bold truncate">` + help; row 2 (`px-3
  py-1.5 border-t border-border/50`, `justify-between`) year stepper with `h-8 w-8` buttons +
  `<PageToolbar />`; row 3 (`px-3 py-1.5 border-t border-border/50 space-y-2`) subtitle
  (`text-xs`) + filter (`Select h-8 w-[120px] max-w-[140px] text-xs`) + conditional `MultiSelect
  className="min-w-0 flex-1 max-w-[160px]"` + reset (`h-8 w-8 p-0`) + count + legend (`h-2.5 w-2.5`
  swatch, `text-[10px]`) + per-day. Then the warning (`mx-3 mb-2 py-2`).
- **Mappings:** `SidebarTrigger` (`ui/sidebar`) ≡ old-focal `SidebarToggle`; `<PageToolbar />` (the
  new app's consolidated toolbar) replaces old-focal's `AIAssistantHeaderButton` + `PageToolbar`
  pair. The collapse trigger + subtitle therefore live inside this custom header (subtitle is in the
  header, not a `PageHeader` prop). This is the one structural reconciliation — it matches old-focal's
  rendered layout exactly while using the new app's primitives.

## 2. No-time-budget warning (gate-1 + plan requirement)

old-focal renders an `Alert variant="default"` with `AlertCircle` + `noTimeBudgetWarning` when
`!timeBudgetData?.settings` (`:578`, `:705`). Port it under the sub-band:
`{!budget.data?.settings && <Alert variant="default" className="mt-2 py-2"><AlertCircle …/>
<AlertDescription>{t('focal.heatmap.noTimeBudgetWarning')}</AlertDescription></Alert>}`.
**Predicate = `!budget.data?.settings`** — under the new typed contract `TimeBudgetYearRead.settings`
is required+non-nullable (`openapi.d.ts:5024`), so the reachable trigger is `budget.data` undefined
(query error / not settled); do **not** test a type-impossible success-without-settings shape. Keep
the `workingHoursPerDay = budget.data?.settings.workingHoursPerDay ?? 8` fallback (already present).
Uses the shadcn `Alert` primitive — confirmed present (`components/ui/alert.tsx`); no new primitive
needed for the warning.

## 3. Day-cell colour scale — old-focal `getHeatmapColor` (exact literals)

Replace `LEVEL_CLASSES` (`HeatmapPage.tsx:47-52`) with old-focal's map (`Heatmap.tsx:182-194`,
verified): `light → "bg-yellow-400 text-gray-800"`, `optimal → "bg-green-500 text-white"`,
`overload → "bg-red-500 text-white"`, `empty → "bg-muted/30 text-muted-foreground"`. Literals (not
semantic tokens) — the task is exact parity and these are old-focal's actual classes. `heatmap.ts`
`loadLevel` thresholds are **unchanged** (confirmed identical to old-focal `getLoadLevel`
`:167-179`).

## 4. Month grid / cards / tooltip — old-focal classes

Outer `p-2 md:p-4`; grid `grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3 md:gap-4`; month card
`p-2 md:p-3 rounded-lg border bg-card` (drop the new page's `shadow-sm` + `rounded-xl` → old-focal
`rounded-lg`, no shadow); month heading `text-sm md:text-base`; weekday labels `text-[8px]
md:text-[10px]` (weekend index ≥5 → `text-red-500`); day cell keeps `aspect-square rounded-sm`,
hover `transition-all hover:scale-125 hover:z-10`, today `ring-2 ring-primary ring-offset-1`,
weekend-empty `text-red-400`; tooltip `max-w-[280px] p-0` with an inner `p-2` wrapper (total line,
event rows, no-events copy) — matching old-focal. Skeleton matches the same card sizing.

## 5. Shared `ui/multi-select` primitive (new file; generic, dependency-free)

The new client has no `ui/multi-select` and no `ui/command`/`cmdk`. Add a **controlled, generic**
`MultiSelect` (NOT heatmap-specific) from existing primitives — `Popover`, `Button`, `Badge`,
`Input`, `Checkbox`, `ScrollArea`, `cn`:
- `MultiSelectOption = {value, label, color?}`. **Scope out** old-focal's optional `icon?:
  ReactNode` (`old-focal/.../ui/multi-select.tsx:20`) — heatmap filters use no icons; the generic
  primitive omits it (add later only if a consumer needs it).
- Props: `options: MultiSelectOption[]`, `selected: string[]`,
  `onChange(next: string[])`, `placeholder`, `searchPlaceholder?`, `emptyText?`, `className?`,
  `disabled?`, `maxDisplay?` (matching old-focal's `ui/multi-select` prop shape).
- Trigger shows up to `maxDisplay` selected as `Badge`s + `+N`; popover has a search `Input`
  filtering options + a `Checkbox` row each + clear-all; empty → `emptyText`.
- No package added → `pnpm install --frozen-lockfile` stays valid.

## 6. Filters — swap chips → `MultiSelect`

Delete the local `multiSelectRow`. Build options exactly as old-focal: spheres `{value: name,
label: name, color: sphere.color || '#3b82f6'}`; root projects AND products both with the same
fallback `{value: id, label: name, color: project.color || '#3b82f6'}` — matching old-focal's `||`
(`Heatmap.tsx:390-403`), which also coerces an empty-string colour to the default; `ProjectRead.color`
is nullable (`openapi.d.ts:4136`), so the fallback is required for both parity and type-safety. Keep empty-selection semantics (a sphere/project/product mode with nothing
selected passes all events — already in `eventMatchesFilter`). Reset stays local (`setMode('all')` +
clear arrays + `clearFilters()`).

## 7. i18n (`focal.heatmap.*` namespace — not old-focal's `calendar.heatmap.*`)

Add to `i18n/locales/{en,ru}.json` under `focal.heatmap`: **`help`** (the header help-tooltip copy,
used by the desktop `:472` / mobile `:596` help affordance — title + short body), `noTimeBudgetWarning`,
`selectSpheresPlaceholder` / `selectProjectsPlaceholder` / `selectProductsPlaceholder`, and the
`MultiSelect` `searchPlaceholder` / `emptyText` / clear label. RU copy mirrors old-focal's
`calendar.heatmap.*` strings. No hardcoded text. (Confirm whether `focal.heatmap.title`/`subtitle`
already exist — they do, per `en.json` — and only add the missing keys.)

## 8. Tests

- `components/ui/multi-select.test.tsx` (new): placeholder/collapsed trigger; controlled `onChange`;
  selected badges + `+N` + clear-all; search filters + empty text. Proves the generic primitive in
  isolation.
- `features/heatmap/HeatmapPage.test.tsx` (new): header (title in the bespoke header band, year
  stepper, filter Select, legend, per-day label) over mocked APIs; prev/next year refetches; **no-budget warning +
  8h fallback when `budget.data` undefined**; light/optimal/overload/empty cells carry the exact
  `getHeatmapColor` classes; sphere/project/product mode renders `MultiSelect` + updates the
  filtered/total count; reset clears mode/selections + persistence; tooltip shows total/%/sorted
  rows/no-events copy.
- `features/heatmap/heatmap.test.ts`: unchanged + green (logic untouched).

## 9. Verify + visual QA

`cd /Users/allosta/Desktop/superapp-heatmap-wt/apps/focal/client && pnpm lint && pnpm typecheck &&
pnpm test:run && pnpm build`. Manual light+dark, desktop+mobile screenshots vs old-focal: header,
filters, `MultiSelect`, legend, no-budget warning, month cards, day-cell colours, weekend/today,
tooltip.

## 10. Files / risks / rollback

**Files:** `HeatmapPage.tsx` (re-skin), `components/ui/multi-select.tsx` (+ test), possibly
`components/ui/alert.tsx` (if absent), `HeatmapPage.test.tsx` (new), `i18n/locales/{en,ru}.json`.
**Not touched:** `heatmap.ts`, the API wrappers, the shared `PageHeader`/shell, tokens. **Risks:**
heatmap uses a **bespoke** header (old-focal does not use the shared header here) — reproduce its
`hidden md:block` desktop rows + `md:hidden` mobile rows exactly with the new app's primitives
(`SidebarTrigger` + year stepper + `<PageToolbar />` + help/subtitle/filter/legend), and verify
**both** desktop and mobile layouts by screenshot. **Rollback** = revert the listed files; no
data/API/contract state.

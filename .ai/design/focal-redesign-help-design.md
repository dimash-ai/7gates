# Design — focal-redesign-help

Traces to the approved think doc (`.ai/think/focal-redesign-help.md`, 9.3) and plan
(`.ai/plans/focal-redesign-help-plan.md`, 9.1). Re-skins the new Help page in place to old-focal's
**tabbed manual**. Presentation-only: no API, no data flow, no new files, no new deps/primitives.

## Architecture

Single component, `apps/focal/client/src/features/help/HelpPage.tsx` (rewrite of the outer layout,
preserve the six section bodies). New shape, mirroring old-focal `pages/Help.tsx:60-169`:

```
<div className="flex h-full flex-col overflow-hidden">
  <header className="border-b bg-background shrink-0">          // old-focal Help.tsx:63
    desktop one-row (hidden md:block): [SidebarTrigger] [BookOpen] {title}  ........ [AI/toolbar]
                                       {subtitle}
    mobile two-row (md:hidden):        row1 [SidebarTrigger][BookOpen]{title}…[AI]
                                       row2 {subtitle}
  </header>
  <div className="flex-1 min-h-0 flex flex-col p-4 md:p-6">
    <Tabs defaultValue={activeTab} className="flex-1 flex flex-col min-h-0">
      <TabsList className="grid w-full grid-cols-6 mb-4 shrink-0">   // 6, not 7
        <TabsTrigger value="system|calendars|planning|formulas|data|habits">
          <Icon className="h-4 w-4 mr-1 hidden sm:inline" /> {t(label)}
        </TabsTrigger> ×6
      </TabsList>
      <ScrollArea className="flex-1">
        <TabsContent value="…" className="mt-0 space-y-6"><Section/></TabsContent> ×6
      </ScrollArea>
    </Tabs>
  </div>
</div>
```

- **Header chrome**: reuse the shipped redesign pattern (tags/heatmap slices) — `useSidebarOptional()`
  gates a `SidebarTrigger`; the AI / theme / language cluster comes from `PageToolbar`. This matches
  old-focal's header *rhythm* (icon + title + subtitle, desktop one-row / mobile two-row) without
  porting old-focal's standalone `AIAssistantHeaderButton` / `SidebarToggle` widgets. (Plan
  Should-Consider #3: verify `PageToolbar`'s built-in theme/language controls don't visually double
  up — settle visually at build/QA.)
- **Section bodies** keep their existing content + `focal.help.*` lookups; only the **local helper
  components** are restyled to old-focal's shapes (next section). The generic `Sub`/`Step`/`Quote`/
  `Note` helpers are replaced/adjusted to the old-focal helper set where a section uses them.
- **No new files, no new primitive, no dep.** `Tabs*`, `ScrollArea`, `PageToolbar`, `SidebarTrigger`,
  `useSidebarOptional` all already exist in the client (verified at gate 2).

## Data model & state

Entirely local presentation state — **no queries, mutations, persistence, or props**:

- A tab descriptor list drives `TabsList`/`TabsContent` rendering:
  `const HELP_TABS = [{ value, labelKey: 'focal.help.tabs.<value>', Icon, Section }, …]` for the six
  tabs. Icons: Layers (system), Share2 (calendars), Target (planning), Calculator (formulas),
  Database (data), Repeat (habits) — matching the lucide icons old-focal uses (`Help.tsx:101-122`).
- Valid-value set for seed validation: `const TAB_VALUES = new Set<string>(HELP_TABS.map((tab) =>
  tab.value))`. Using a **`Set<string>`** (not an `as const` tuple) keeps the `.has(param)` check
  type-safe under the strict client config — it avoids the `readonly tuple.includes(string)` **TS2345**
  the gate-3 review flagged.
- `const [activeTab] = useState(() => { const param = new URLSearchParams(window.location.search)
  .get('tab'); return param != null && TAB_VALUES.has(param) ? param : 'system' })` — **seed-once,
  no write-back, no `useEffect`**, mirroring old-focal's seed-once pattern (`Help.tsx:57-58`,
  `defaultValue={activeTab}`). shadcn `Tabs` `defaultValue` takes a `string`, so no literal-union type
  is needed for the Tabs API. (Seeds from the `?tab=` query param — see the deep-link contract below.)

## Interfaces & contracts

**Deep-link contract (preserve — do not break).** The new app deep-links into Help via the **`?tab=`
query param**, not the `#hash` old-focal used: `PageHeader.helpHref` is documented as
`/help?tab=formulas` (`components/PageHeader.tsx:15`) and the Time Budgets page passes exactly that
(`features/budgets/TimeBudgetsPage.tsx:1926` — the only current caller). The tabbed page therefore
**seeds its active tab from `?tab=<value>`** (read seed-once from `window.location.search`); a value
outside the six tabs (or `?tab=ai-agents`) falls back to System. old-focal's `#hash` mechanism is not
used by any new-app caller, so it is not wired (see Alternatives). The current flat page does not
honor `?tab=` at all, so wiring it is a strict improvement, not a behavior change to preserve.

**i18n.** Namespace stays `focal.help.*` (new-app convention).
- **Add** `focal.help.tabs.{system,calendars,planning,formulas,data,habits}` to **both**
  `src/i18n/locales/en.json` and `ru.json` (RU values from old-focal `help.tabs.*`:
  Система / Календари / Планирование / Формулы / Данные / Привычки; EN equivalents).
- **Remove** the now-orphaned `focal.help.toc` from both locales (it is used only by the
  table-of-contents card at `HelpPage.tsx:211,215`, which this redesign deletes — old-focal has no
  TOC). Per Surgical Changes (plan Should-Consider #1). Net key-tree stays RU/EN-identical.
- Reuse all existing `focal.help.<section>.*` content keys unchanged; fill only gaps required for the
  old-focal visual helpers.

**Local helper components — restyle to old-focal's exact shapes** (`pages/Help.tsx`):
| helper | old-focal shape (binding) |
|---|---|
| `FilterTypeItem` | `flex items-start gap-3 p-3 rounded-lg hover:bg-muted/50` · `Badge variant="outline"` name · `<code>` filter chip · muted example (Help.tsx:686) |
| `RoleItem` | `p-3 rounded-lg border hover:shadow-sm` · colored icon · name + outline badge · 4 permission badges `default`/`secondary` with ✓/✗ (Help.tsx:698) |
| `DimensionCard` | `p-4 rounded-lg border bg-card hover:shadow-md` · colored icon · title · `text-primary` question · muted desc (Help.tsx:1475) |
| `LevelCard` | `p-4 rounded-lg border ${color}` · level/desc left · `Badge outline` horizon + question right (Help.tsx:1492) |
| `StepItem` | `flex items-start gap-3 p-3 rounded-lg hover:bg-muted/50` · `w-8 h-8 rounded-full bg-primary text-primary-foreground` number · icon + title · desc (Help.tsx:1515) |
| `DataSourceItem` | `p-4 rounded-lg border bg-card` · primary icon · `<code>` title · field `Badge outline`s · usage line (Help.tsx:1537) |
| `TipItem` | `flex items-start gap-2 p-2 rounded-lg hover:bg-muted/50` · yellow `Lightbulb` · title — desc (Help.tsx:2360) |
| `GlossaryItem` | `p-3 rounded-lg border bg-card hover:shadow-sm` · emoji · term + duration badge · def · italic example (Help.tsx:2372) |

All colors via theme tokens already provided by slice 0 (`bg-card`, `text-primary`, `text-muted-
foreground`, `border`, `bg-muted`) → light + dark both correct with no extra work.

## Happy flow

1. User opens `/help` → header (BookOpen + title + subtitle + sidebar toggle + toolbar) + 6-tab bar
   render; **System** tab active.
2. Click any tab → its `TabsContent` becomes visible (Radix Tabs), others unmount from the a11y tree.
3. Open `/help?tab=formulas` (the `PageHeader.helpHref` contract, e.g. the "Learn more" link from
   Time Budgets) → **Formulas** tab active on first paint (query-param seed).

## Unhappy flow

- **Unknown / absent `?tab=`** (`?tab=foo`, or no param) → not in `TAB_VALUES` → **System** (no blank panel).
- **`?tab=ai-agents`** (old-focal had that tab; deferred here) → not in `TAB_VALUES` → **System**; no
  unshipped `foc_` agent docs rendered.
- **Rendered outside the sidebar provider** (isolated tests / standalone) → `useSidebarOptional()`
  returns null → `SidebarTrigger` not rendered, no crash.
- **Missing locale key** → i18next would surface the raw `focal.help.*` key → caught by the RU + EN
  render tests and the key-tree parity test before release (no intended runtime fallback).
- **Dark mode** → every surface uses theme tokens (slice 0) → parity in both themes.

## Alternatives rejected

- **Verbatim rewrite from old-focal `Help.tsx`** — re-imports React-18 / Tailwind-3 idioms and
  duplicates already-ported content; larger, non-surgical diff. Rejected (plan Fork 2 → A).
- **Keep the flat stacked-section layout** — fails the exact-old-focal tabbed-manual contract.
- **Include the AI-agents (7th) tab now** — documents the unshipped, Phase-8 `foc_` agent API →
  misleads users + rework when the agent feature lands. Deferred (think Fork 1 → A); `TabsList`
  built 6-wide, trivially extended to 7 later.
- **Hash-based deep-linking (old-focal `#tab`)** — old-focal seeds the tab from `window.location.hash`,
  but the new app standardized its help deep-links on the `?tab=` query param (`PageHeader.helpHref`
  + the Time Budgets caller). We honor the new app's existing `?tab=` contract rather than re-introduce
  the hash; no new-app caller uses the hash. Seed-only (no write-back on tab click), matching
  old-focal's seed-once behavior.

## Test strategy

`HelpPage.test.tsx` (happy-dom), accessible queries (`role="tab"`, `role="heading"`, selected-tab
state, visible text), with the `?tab=` query param (`window.location.search`) set/cleared per test
and i18n language reset:
1. RU render — header + subtitle + 6 localized tabs + visible System panel, **no raw `focal.help.*`**.
2. EN render — same through the EN locale (not RU fallback).
3. Key-tree parity — RU vs EN `focal.help.*` identical **after** adding `tabs.*` and removing `toc`.
4. `?tab=formulas` → Formulas tab selected on load (query-param seed; the `PageHeader.helpHref` contract).
5. Unknown / absent `?tab=` → System selected (no empty panel).
6. Tab click switches the visible panel (Radix interactivity preserved post-move).
7. Exactly the six shipped tabs render; **no AI-agents tab**.
8. No deferred agent-API copy (`foc_`, scopes, token text) anywhere on the page.
9. The old table-of-contents card is gone (`focal.help.toc` no longer rendered).

Then the task checks in the worktree: `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.
Light/dark desktop+mobile screenshot parity vs old-focal `Help.tsx` is the manual QA step.

## Security notes

None applicable. Static documentation page: no user input, no network calls, no auth surface, no
secrets. Confirm no `dangerouslySetInnerHTML` is introduced (content is static JSX + i18n strings).
The deferred AI-agents content (which documented `foc_` token hashing) is **not** added, so no agent
auth detail is surfaced in the client.

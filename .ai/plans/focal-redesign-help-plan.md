# Summary

Reskin the new Focal Help page in place from a flat, stacked manual into the old-focal tabbed
in-app manual. The change stays presentation-only: keep the six already-ported non-AI help sections
and the `focal.help.*` namespace, add the old-focal header chrome, six-tab `Tabs` shell, hash-seeded
initial tab, `ScrollArea`, and old-focal section helper styling. The AI-agents tab remains deferred
because it documents the Phase 8 `foc_` agent API that is not shipped in the new app.

# Files to change

| path | change | why |
|------|--------|-----|
| `/Users/allosta/Desktop/allosta/superapp/apps/focal/client/src/features/help/HelpPage.tsx` | Replace the outer flat `main`/TOC/six stacked `<section>` layout with a custom old-focal-style header, `Tabs`, `TabsList`, `TabsContent`, and `ScrollArea`; preserve the existing six content sections and restyle local helper components to match old-focal's `RoleItem`, `FilterTypeItem`, `DimensionCard`, `LevelCard`, `StepItem`, `DataSourceItem`, `TipItem`, and `GlossaryItem` treatment. | This is the binding UI surface for the Help page redesign. |
| `/Users/allosta/Desktop/allosta/superapp/apps/focal/client/src/features/help/HelpPage.test.tsx` | Replace flat-section assertions with tabbed-manual assertions covering header copy, six tabs, hash defaults, tab switching, AI-agents deferral, and missing locale keys in both languages. | The current tests only prove the old stacked render resolves i18n keys; the redesign needs coverage for the new structure and behavior. |
| `/Users/allosta/Desktop/allosta/superapp/apps/focal/client/src/i18n/locales/en.json` | Add `translation.focal.help.tabs.{system,calendars,planning,formulas,data,habits}` and any missing helper labels needed by the old-focal visual components. | Tab labels and user-facing helper text must remain localized. |
| `/Users/allosta/Desktop/allosta/superapp/apps/focal/client/src/i18n/locales/ru.json` | Add the same `translation.focal.help.tabs.*` keys and matching helper labels in Russian. | Keeps the RU/EN help key tree identical. |

No API, schema, route, shell, package, lockfile, or generated OpenAPI change is planned.

# Implementation slices

1. Add tab metadata and locale keys.
   - Add a local `HELP_TABS`/`VALID_HELP_TABS` definition for the six shipped tabs only:
     `system`, `calendars`, `planning`, `formulas`, `data`, and `habits`.
   - Add EN/RU `focal.help.tabs.*` labels. Reuse existing `focal.help.<section>.title` for content
     headings; do not add `aiAgents` tab keys in this slice.
   - Keep existing `HelpPage` render unchanged until the keys exist so the build stays green.

2. Rebuild the page shell and tab behavior.
   - Import existing primitives only: `Tabs`, `TabsContent`, `TabsList`, `TabsTrigger`,
     `ScrollArea`, `PageToolbar`, `SidebarTrigger`, and `useSidebarOptional`; do not add a new UI
     primitive or import old-focal's `AIAssistantHeaderButton`.
   - Replace the current `main`/TOC/stacked-section wrapper with
     `div.flex.h-full.flex-col.overflow-hidden`, old-focal's desktop/mobile header rhythm, and a
     padded `Tabs` body.
   - Header contract: BookOpen icon, `focal.help.title`, `focal.help.subtitle`, optional
     `SidebarTrigger` when a sidebar provider exists, and `PageToolbar` as the new app's shipped
     AI/dark-mode/language control cluster.
   - Seed the initial tab from `window.location.hash.slice(1)` when it matches `VALID_HELP_TABS`;
     otherwise fall back to `system`. Keep this seed-only behavior because it matches old-focal's
     `defaultValue`/initial-state deep link contract.
   - Remove the table-of-contents card and render each existing section body inside one
     `TabsContent value="<tab>" className="mt-0 space-y-6"`.

3. Restore old-focal section visual components without changing content semantics.
   - Add/adjust imports for existing shadcn `CardDescription` and `Accordion` pieces where the
     old-focal contract uses them.
   - Convert local helper components from the generic `Sub`/`Panel` styling toward the old-focal
     component shapes: hoverable bordered glossary items, badge-led filter rows, icon-led role rows,
     colored dimension/level cards, numbered `StepItem` rows with icons, icon-led data sources, and
     lightbulb `TipItem` rows.
   - Preserve the current `focal.help.*` string lookups and already-ported six-section content; fill
     only small locale/helper-label gaps required to match the old-focal visual treatment.
   - Keep the AI-agents content absent. Do not add `Bot`, `Key`, agent-token copy, `foc_` endpoints,
     or a hidden/seventh tab.

4. Update focused tests alongside the structural change.
   - Change the render helper only as needed for `window.location.hash` setup/cleanup and i18n
     language reset.
   - Replace `container.querySelectorAll('section').length === 6` with role-based tab assertions and
     visible content checks.
   - Keep the existing locale-key tree parity test and extend it to cover the new `tabs` subtree.
   - Prefer accessible queries (`role="heading"`, `role="tab"`, selected tab state, visible text)
     over broad snapshots or fragile full-class assertions.

5. Final verification and screenshot parity.
   - Run the focused test first:
     ```sh
     cd /Users/allosta/Desktop/allosta/superapp/apps/focal/client
     pnpm test:run src/features/help/HelpPage.test.tsx
     ```
   - Then run the task-required client checks:
     ```sh
     cd /Users/allosta/Desktop/allosta/superapp/apps/focal/client
     pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
     ```
   - Compare light and dark desktop/mobile screenshots against
     `/Users/allosta/Desktop/allosta/superapp/apps/old-focal/client/src/pages/Help.tsx`, checking
     header rows, six-tab bar, active tab panel, section cards, accordion rows, badges, code blocks,
     and absence of the deferred AI-agents tab.

# Tests

- `renders the tabbed manual in Russian with every key resolved`: proves the new header, subtitle,
  six localized tabs, and visible default System panel render without raw `focal.help.*` keys.
- `renders the tabbed manual in English with every key resolved`: proves the same shell and content
  resolve through the EN locale file, not RU fallback text.
- `keeps the help-key tree identical across both locale files`: proves RU and EN stay structurally
  aligned after adding `focal.help.tabs.*` and any helper labels.
- `opens the Formulas tab from #formulas`: proves old-focal-style hash deep-linking seeds the
  initial selected tab from a valid URL hash.
- `falls back to System for an unknown hash`: proves invalid or stale hashes do not render an empty
  tab panel.
- `switches visible content when a tab is clicked`: proves the Radix tabs shell remains interactive
  after moving the existing section bodies into `TabsContent`.
- `renders exactly the six shipped help tabs`: proves System, Calendars, Planning, Formulas, Data,
  and Habits are present, and the deferred AI-agents tab is not exposed.
- `does not render deferred agent API copy`: proves the page does not document unshipped `foc_`
  endpoints, scopes, or agent-token behavior.
- `removes the old table-of-contents layout`: proves the old flat-scroll navigation card is gone and
  the manual is now tab driven.

# Error & rescue map

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| `help.hash.unknownTab` | No exception; `window.location.hash` is not one of `VALID_HELP_TABS`. | Initial-tab derivation in `HelpPage`. | System tab opens, matching a safe default instead of a blank panel. |
| `help.hash.deferredAiAgents` | No exception; hash is `#ai-agents`, which old-focal supports but this slice defers. | Same initial-tab derivation because `ai-agents` is intentionally absent from `VALID_HELP_TABS`. | System tab opens; no unshipped AI-agent documentation is shown. |
| `help.locale.missingKey` | No exception; i18next would render the raw `focal.help.*` key. | `HelpPage.test.tsx` RU/EN render and key-tree parity tests before release. | No intended runtime fallback; tests block the change before users see raw keys. |
| `help.sidebar.noProvider` | No exception when rendered outside the app shell. | `useSidebarOptional()` gating before rendering `SidebarTrigger`. | Header renders without a sidebar toggle in isolated tests/standalone render; inside the app shell the toggle appears. |
| `help.tabs.unmountedContent` | No exception; inactive Radix `TabsContent` is hidden/unmounted from the accessibility tree. | Role/visibility tests target the selected tab and visible tab panel. | Only the selected section is visible, with keyboard tab controls available. |

# Review lenses (pre-answer before gate2-plan)

- **Scope / strategy** - This is the minimum complete parity slice for Help: one page component,
  its tests, and two locale files. Existing six-section content and `focal.help.*` strings are the
  base; no backend, route, shell, token, package, or generated-client change is needed. The AI-agents
  tab remains deferred exactly as the approved think doc and task require.
- **Architecture** - All state is local presentation state: a hash-seeded initial tab handled by
  Radix Tabs. There are no queries, mutations, or persistence. `PageToolbar` owns the new app's
  shared right-side controls, and `useSidebarOptional` prevents coupling the page to a required
  sidebar provider.
- **Design** - Desktop and mobile header rows follow old-focal's Help header rhythm while using the
  new shell controls. The body becomes a six-column tab list with icons hidden on small screens and a
  `ScrollArea` for tab content. Per-section helper components are restored to old-focal visual
  treatments, including hover states, badges, code blocks, accordions, and cards. There are no
  loading or API error states because the page is static.
- **DevEx** - No new abstraction or dependency is introduced. Keep helpers local to `HelpPage.tsx`
  because they are page-specific documentation UI. Tests use accessible behavior and locale parity
  instead of screenshots or broad snapshots; screenshot parity remains a manual verification step.

# Risks & migrations

- No database migration, data backfill, server/API/schema change, generated OpenAPI change,
  environment variable, package dependency, lockfile update, or route change.
- Main risk: `HelpPage.tsx` is large, and moving six long section bodies can create noisy diffs.
  Mitigation: keep the content order and existing `focal.help.*` lookups intact, move one section at
  a time into `TabsContent`, and avoid unrelated copy edits.
- Secondary risk: exact old-focal header has a standalone `AIAssistantHeaderButton`, while the new
  client ships `PageToolbar`. Mitigation: use `PageToolbar` so the AI action is present through the
  established new-app header pattern without duplicating or porting old widget code.
- Rollback plan: revert the four planned files only. The change introduces no persistent data shape
  and no API contract.

# Scope check

- [x] Matches the task's Scope and Out of scope.
- [x] Small enough to review in one sitting.
- [x] Size smell checked: the component diff will be substantial because the page changes from flat
      scroll to tabbed manual, but it stays confined to one feature component plus tests and locale
      keys, with no shared primitive or service changes.

# Out of scope

- The old-focal AI-agents tab, `foc_` endpoints, MCP/agent scopes, token hashing, and agent error
  code documentation.
- Any server, API, schema, generated OpenAPI, auth, storage, query, mutation, or data-flow change.
- Global shell, `PageHeader`, `PageToolbar`, sidebar primitives, Tailwind tokens, or unrelated design
  system changes.
- Other Focal pages or broader redesign cleanup.
- Rewriting help content beyond small gaps needed for old-focal visual parity.

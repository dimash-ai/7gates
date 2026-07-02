# Goal

Re-skin the new Focal **Help page** (`superapp/apps/focal/client/src/features/help/HelpPage.tsx`) to
**exact visual parity with old-focal `client/src/pages/Help.tsx`** — a **tabbed in-app manual** with a
BookOpen header + subtitle, a tab bar, and old-focal's per-section styling — reproduced on the new
stack. Part of the `focal-redesign-pages` epic (binding contract = exact old-focal). This is a
**static, API-less page** → the lowest-risk slice: presentation only, no data or behavior.

> **Binding visual contract** = `superapp/apps/old-focal/client/src/pages/Help.tsx` (the tabbed
> layout, header chrome, and the per-section components: `RoleItem`/`FilterTypeItem`,
> `DimensionCard`/`LevelCard`/`StepItem`/`DataSourceItem`, `TipItem`/`GlossaryItem`). **Current
> state** = `features/help/HelpPage.tsx` (1378 lines) — the same 6 non-AI sections already
> **content-ported** but rendered as a **flat vertical card scroll** (`<section id="help-…">`), under
> the new app's `focal.help.*` i18n namespace.

# Scope

- Restructure `HelpPage.tsx` from the flat 6-`<section>` scroll into old-focal's **tabbed** layout:
  the header (BookOpen icon + `title` + `subtitle`, desktop one-row / mobile two-row, with the
  sidebar toggle + the AI-assistant button — matching the shell pattern shipped in the tags/heatmap
  slices), a `Tabs` + `TabsList` tab bar, and `TabsContent` per section, with old-focal's hash-tab
  deep-link behavior (`#system`, `#calendars`, …).
- Match old-focal's **per-section styling** for the 6 sections (System, Calendars, Planning,
  Formulas, Data, Habits) — the section sub-components and their visual treatment.
- Tab labels via i18n in the existing `focal.help.*` namespace (`ru` + `en`); reuse the already-ported
  section content/strings, filling only gaps needed to match old-focal.
- Keep the page **static** — no API calls, no new data, no behavior beyond tab switching.

# Out of scope

- **The AI-agents tab (old-focal's 7th tab).** It documents the `foc_` agent API + MCP, which is
  **Phase 8 — deferred** (not shipped in the new app); the new `HelpPage` already deliberately
  excludes it. **Defer it to ship with the agent-API / AI feature**, not faked here. The tab bar is
  built 6-wide now, extensible to 7 when that feature lands.
- Any **server / API / schema** change (the page has none).
- Restyling other pages, the global shell/tokens (done in slice 0), or other nav items.
- Rewriting the ported section **content** beyond what exact-old-focal parity needs.

# Acceptance criteria

- [ ] The Help page renders as old-focal's **tabbed manual** (6 tabs: System · Calendars · Planning ·
      Formulas · Data · Habits) with the BookOpen header + subtitle + sidebar toggle + AI button, in
      **light and dark**, matching old-focal by screenshot.
- [ ] Tab deep-linking via URL hash works as in old-focal (e.g. `/help#formulas` opens Formulas).
- [ ] All tab + section strings via i18next `focal.help.*` (`ru` + `en`); no hardcoded user-facing text.
- [ ] No API/behavior change; surgical diff confined to the help feature (+ locale files); existing
      `HelpPage.test.tsx` updated and green.
- [ ] Green from the worktree: `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.

# Verification commands

```sh
cd /Users/allosta/Desktop/allosta/.worktrees/focal-redesign-help/apps/focal/client
pnpm install --frozen-lockfile
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```

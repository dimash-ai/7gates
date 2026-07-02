# Stage

Stage 7: ship — `focal-redesign-help` (one slice of the `focal-redesign-pages` epic). Branch
`feat/focal-redesign-help`, cut off slice-0 `afaaeba` (already in `feature/focal-migration` via
PR #55); PR target = `feature/focal-migration`.

# What changed

Re-skinned the Focal **Help page** (`features/help/HelpPage.tsx`) to **exact visual parity with
old-focal `pages/Help.tsx`** — a tabbed in-app manual — reproduced on the new stack (React 19 /
Tailwind 4 / shadcn), over the existing (API-less) content. Presentation only: no API, route, or
behavior change beyond tab/accordion interaction.

- **Layout:** the flat single-scroll page + table-of-contents card became old-focal's **tabbed
  manual** — a BookOpen header with subtitle (desktop one-row / mobile two-row, sidebar toggle +
  `PageToolbar`), a 6-tab bar (System · Calendars · Planning · Formulas · Data · Habits) in a
  `ScrollArea`, with the active tab **seeded from the `?tab=` query param** (the app's existing
  `PageHeader.helpHref` deep-link contract, e.g. `/help?tab=formulas`; unknown/absent → System).
- **Per-section fidelity:** every old-focal helper shape reproduced with old-focal's exact icons +
  colors — `GlossaryItem` (hover-shadow card), `RoleItem` (colored role icon + outline badge +
  capability ✓/✗), `DimensionCard` (Compass/Zap/Clock/Scale/Rocket in purple/yellow/blue/green/red),
  `LevelCard` (colored surfaces), `StepItem` (numbered hover row + icon + title + description),
  `DataSourceItem` (primary icon), `FilterTypeItem` (badge + code chip), `TipItem` (lightbulb row),
  and a leading icon on all ~28 section-card titles. The **Planning analysis** is a
  multi-`Accordion` and the **Habit-tracker features** a single collapsible `Accordion`, matching
  old-focal.
- **Deferred (not faked):** the old-focal **AI-agents** 7th tab (it documents the Phase-8 `foc_`
  agent API, not shipped in the new app) — built 6-wide, extends to 7 when that feature lands.
- **i18n:** added `focal.help.tabs.*` (ru + en); removed the now-orphaned `focal.help.toc`. EN/RU
  `focal.help` trees stay identical (366 leaves each).

# Files touched

- `apps/focal/client/src/features/help/HelpPage.tsx` (modified — the re-skin)
- `apps/focal/client/src/features/help/HelpPage.test.tsx` (modified — 18 tests)
- `apps/focal/client/src/i18n/locales/en.json` (modified — `tabs.*` added, `toc` removed)
- `apps/focal/client/src/i18n/locales/ru.json` (modified — `tabs.*` added, `toc` removed)

# Tests run

```sh
cd /Users/allosta/Desktop/allosta/.worktrees/focal-redesign-help/apps/focal/client
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```

# Verification output

```sh
pnpm lint      -> PASS (biome, 217 files, no fixes)
pnpm typecheck -> PASS (tsc -b, exit 0)
pnpm test:run  -> PASS (49 files, 376 tests; help suite = 18)
pnpm build     -> PASS (vite build ok; pre-existing >500 kB chunk advisory only)
```

# Still needs review

- Visual QA against old-focal in a real authed client (light + dark) is pending — the gates verified
  structure/behavior/parity-by-source, not a live screenshot diff.

# PR / release notes (for users)

The **Help** page now matches the original Focal manual. Open **Справка / Help** and you get a
tabbed guide — **System, Calendars, Planning, Formulas, Data, Habits** — instead of one long scroll.
You can deep-link straight to a section (e.g. the "Learn more" link on Time Budgets opens
**Formulas**), the Planning and Habit-tracker sections expand/collapse, and everything renders in
both light and dark and in Russian and English. (The AI-agents help section will arrive with the AI
assistant feature.)

# Status

CODEX APPROVED (9.4) — final release gate cleared. All 7 gates ≥9.0 (think 9.3 · plan 9.1 ·
design 9.2 · build 9.3 · review 9.4 · test 9.5 · ship 9.4). Shipped as commit `380b1bf` →
**PR #65** (https://github.com/Allosta-Group/superapp/pull/65) — **MERGED 2026-06-23** into
`feature/focal-migration`; slice branch + worktree cleaned. Light/dark visual QA still pending.

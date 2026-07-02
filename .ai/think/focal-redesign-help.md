# Problem

The new Focal **Help page** must reach **exact visual parity with old-focal `pages/Help.tsx`** — the
binding contract for the `focal-redesign-pages` epic. old-focal's Help is a **tabbed in-app manual**:
a BookOpen header + subtitle, a 7-tab bar (System · Calendars · Planning · Formulas · Data · Habits ·
AI-agents), hash-deep-linkable, with bespoke per-section styling. The new app's
`features/help/HelpPage.tsx` (1378 lines) already **content-ported 6 of those sections**, but renders
them as a **flat vertical card scroll** (`<section id="help-system">` … stacked), not tabs, and its
header is a single `<h1>` — so it does not match old-focal's structure or chrome.

Two facts make this the **lowest-risk slice** in the epic:
1. **It is a static, API-less page** — no queries, no mutations, no data flow. The change is pure
   presentation (layout + styling) + tab state. Zero behavior/data risk.
2. **The content already exists** — the 6 non-AI sections are ported; the work is structural
   (flat → tabbed) + matching old-focal's exact look, reusing the existing `focal.help.*` strings.

The one real decision is the **AI-agents tab** (old-focal's 7th): it documents the `foc_` external
agent API (endpoints, scopes, token hashing, error codes) — a **Phase 8, explicitly-deferred** feature
not shipped in the new app, and the new `HelpPage` already deliberately omits it ("ships together with
the AI feature"). Framing whether to include it now is the substantive judgement here.

# Assumptions

- **[confirmed — user/epic]** Binding visual contract = exact old-focal; this slice matches
  old-focal `pages/Help.tsx` for the Help page, on the new stack, over the (non-existent) data layer.
- **[confirmed — inspection]** old-focal `Help.tsx` (2394 lines): `VALID_TABS = [system, calendars,
  planning, formulas, data, habits, ai-agents]`; header is desktop-one-row / mobile-two-row with
  `<BookOpen>` + `t("help.title")` + `t("help.subtitle")` + `SidebarToggle` + `AIAssistantHeaderButton`;
  body is `<Tabs>` → `<TabsList grid-cols-7>` (icon + label, icon hidden on mobile) → `<ScrollArea>`
  with 7 `<TabsContent>`; active tab seeds from `window.location.hash`. Section components:
  `SystemSection`, `CalendarsSection` (+ `RoleItem`/`FilterTypeItem`), `PlanningSection`,
  `FormulasSection`, `DataSection` (+ `DimensionCard`/`LevelCard`/`StepItem`/`DataSourceItem`),
  `HabitsSection`, `AiAgentsSection` (+ `ScopeRow`/`EndpointBlock`/`ErrorCodeRow`).
- **[confirmed — inspection]** new `HelpPage.tsx`: flat scroll of 6 `<section>`s (system, calendars,
  planning, formulas, data, habits) with `<h2 border-b>` headers + `Sub`/`Step`/`Quote`/`Note`
  helpers + shadcn `Card`; title via `t('focal.help.title')`; **no Tabs**; **AI-agents section
  intentionally excluded** (file comment). i18n namespace = `focal.help.*` (the new app's convention).
- **[confirmed — inspection/migration]** the `foc_` agent API is **Phase 8 — deferred** (no cross-app
  consumer until PA exists; no agent-token UI shipped in the new client). → documenting it in Help now
  would describe an unshipped feature.
- **[confirmed — habits slice]** the new app already has the shadcn **`Tabs`** primitive in use
  (habits = "PageHeader + Tabs controller"), and **`ScrollArea`** is a standard shadcn primitive →
  **no new UI primitive** is required (unlike the heatmap slice's multi-select). Keeps the slice simple.
- **[confirmed — slice-0/tags/heatmap]** the shipped header pattern for redesigned pages renders the
  `SidebarTrigger` (via `useSidebarOptional`) + the AI button through `PageToolbar`/`PageHeader`; this
  slice's header reuses that pattern to match old-focal's header while staying consistent with shipped
  slices.
- **[unverified — settle at design gate]** exact hash-routing fidelity (seed-from-hash only, vs
  also updating the hash on tab change — old-focal seeds from hash via `useState`); the precise
  mobile header rows; whether any of the 6 sections has minor content gaps vs old-focal to fill. None
  changes the slice's shape.

# Options considered

**Fork 1 — the AI-agents (7th) tab:**

| # | Option | Pros | Cons |
|---|--------|------|------|
| **A — Defer the AI-agents tab; ship 6 tabs (chosen)** | Honest — doesn't document a Phase-8 feature the new app hasn't shipped; preserves the new `HelpPage`'s existing deliberate decision; `TabsList` built 6-wide, trivially extended to 7 when the agent API/AI feature lands (its natural slice). | The Help page isn't byte-identical to old-focal's tab count **until** that feature ships. |
| **B — Port the AI-agents tab now (full 7 tabs)** | Literal old-focal tab parity immediately. | Documents `foc_` endpoints/scopes/tokens that **don't exist** in the new app yet → misleads users, and re-does work when the agent feature actually lands; contradicts the new app's standing decision and the epic's "don't fake what isn't there" principle (inverted here: don't *document* what isn't shipped). |

**Fork 2 — how to restructure:**

| # | Option | Pros | Cons |
|---|--------|------|------|
| **A — In-place restructure of `HelpPage.tsx` (chosen)** | One file (+ locales + test); reuses the already-ported section content/markup, re-homing each `<section>` body into a `<TabsContent>` and adding old-focal's header + `TabsList`; surgical, matches the per-slice pattern. | Touching a 1378-line file carefully. |
| **B — Rewrite from old-focal `Help.tsx` verbatim** | Maximal literal fidelity. | Re-imports old-focal's React-18/Tailwind-3 idioms + duplicates already-ported content; larger, less surgical diff; throws away the new app's working i18n wiring. **Rejected.** |

# Recommendation

**Fork 1 → A (defer AI-agents, ship 6 tabs).** **Fork 2 → A (in-place restructure).** Rationale: the
content is already ported and the page is static, so the cheapest faithful path is to re-home the
existing six section bodies into old-focal's tabbed shell + header and match its per-section styling —
not a verbatim rewrite (B) that re-litigates content and drags in the old stack. The AI-agents tab is
deferred because documenting the unshipped, Phase-8 `foc_` API would mislead users and duplicate work;
the new `HelpPage` already made this call, and a 6-wide `TabsList` extends to 7 when the agent feature
ships (its own slice). This keeps the slice surgical, zero-risk (no API/behavior), and exactly
old-focal in look for everything the new app actually has.

**Shape of the change (one build slice; settled at gate 2/3):** restructure `HelpPage.tsx` → old-focal
header (BookOpen + title + subtitle + sidebar toggle + AI button) + `Tabs`/`TabsList`(6)/`ScrollArea`/
`TabsContent`, hash-seeded active tab; match old-focal per-section styling; add `focal.help.tabs.*`
i18n (`ru` + `en`); update `HelpPage.test.tsx`. No new primitives, no API.

# Out of scope

- The **AI-agents tab** (deferred with the agent-API / AI feature — option A above; not faked).
- Any **server / API / schema** change — the page is static.
- The global shell/tokens (slice 0) and other nav pages (their own slices).
- Rewriting ported **content** beyond what exact-old-focal parity needs (no opportunistic edits).

# Open questions

- **Hash routing fidelity** — replicate old-focal's seed-active-tab-from-`#hash` (and decide whether
  tab clicks update the hash for shareable deep links). Settle at the design gate; default = match
  old-focal (seed from hash).
- **AI-agents tab** — confirmed deferred; if the user wants literal 7-tab parity now despite the
  unshipped `foc_` API, that's a one-tab content port flagged here (not the recommendation).
- **Content gaps** — whether any of the 6 ported sections is missing detail vs old-focal; fill only to
  reach parity, no rewrites. Per-section diff settled at build.

# Success criteria

- [ ] Help renders as old-focal's tabbed manual (6 tabs) with the BookOpen header + subtitle + sidebar
      toggle + AI button, **light + dark**, matching old-focal by screenshot.
- [ ] URL-hash tab deep-linking matches old-focal (`/help#formulas` → Formulas tab).
- [ ] All tab + section strings via `focal.help.*` (`ru` + `en`); no hardcoded user-facing text.
- [ ] Surgical, API-less diff confined to the help feature + locales; `HelpPage.test.tsx` updated;
      `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green in the worktree.
- [ ] The AI-agents tab is explicitly deferred (not faked); `TabsList` is extensible to 7 when the
      agent feature ships.

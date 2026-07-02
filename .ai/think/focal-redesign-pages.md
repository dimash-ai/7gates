# Problem

Every page in the new Focal app's **left nav** must reach **exact visual parity with the proven
production app `superapp/apps/old-focal`**. The new app (`superapp/apps/focal/client`) already has
each feature **functionally ported** onto real FastAPI APIs, but the pages wear a mix of a "baseline
migration" look and a half-finished **Allosta-mockup** redesign (only `foundation` (PR #50) +
`calendar` shipped, built against `superapp/design/focal/`). The user inspected the result, said the
new calendar "is different," and chose **"exact old-focal everywhere"** as the binding design
contract — match old-focal pixel-for-pixel for every left-nav page, **redo the calendar to
old-focal**, **even where that supersedes the merged Allosta foundation and the mockup**.

So this is **not** a continuation of the mockup redesign; it is a **pivot of the design source of
truth** from `design/focal/` (Allosta mockup) to `apps/old-focal` (the real app). The central facts
to manage:

1. **It is a re-skin over working features, not a rebuild.** The new app's `features/*` already run
   on the new typed `api/*` + the fully-ported backend. This epic changes **presentation only** —
   behavior and data flow stay.
2. **Exact look must be *reproduced*, not *copied*.** old-focal is **React 18 + Wouter +
   Tailwind 3.4 (config + PostCSS) + shadcn/ui (New York) + recharts 2 + i18next**; the new app is
   **React 19 + Tailwind 4 (CSS-first `@theme`, no `tailwind.config`, no PostCSS — Tailwind 3 is on
   the repo's *forbidden* list) + Biome + shadcn + i18next**. Lifting old-focal's CSS/config/
   components verbatim would drag in a banned toolchain and a different data layer. The look is
   re-expressed on the sanctioned stack.
3. **The pivot supersedes prior pipeline work — say so plainly.** old-focal's palette/shell become
   the target, so the PR #50 Allosta tokens/shell get **replaced** and the shipped mockup calendar
   gets **redone**. Framing this honestly (what is thrown away, in what order) is the job of this
   think doc.

The good news that de-risks scope: old-focal has a **real, shippable design for every left-nav item**
— including AI chat, Help, Integrations, Meeting Requests, and the admin Dashboard — so unlike the
Allosta mockup (which left those as placeholders), there is **no design gap** to invent.

# Assumptions

- **[confirmed — user]** Binding visual contract = `apps/old-focal`, **exact**, for **all** left-nav
  pages, **overriding** the Allosta foundation/shell where they differ; the calendar is **redone** to
  old-focal. (The `design/focal/` mockup is set aside for this epic.)
- **[confirmed — fs/git]** old-focal stack: React 18.3, Wouter 3.3, **Tailwind 3.4 + PostCSS +
  `tailwind.config.ts`**, shadcn/ui (New York), Framer Motion 11, recharts 2.15, i18next 25. Theme =
  HSL CSS vars in `client/src/index.css` — a full light `:root` set (`--primary 217 91% 48%`,
  `--sidebar*`, `--card*`, `--popover*`, chart + dashboard-heatmap ramps, `--font-sans InterVariable`,
  `--radius .5rem`, shadow scale) **and a `.dark` block (`index.css:97`)** → light **and** dark are
  both first-class and must both be reproduced.
- **[confirmed — repo CLAUDE.md]** new app stack: React 19, **Tailwind 4 (CSS-first `@theme`, no
  config, no PostCSS, no autoprefixer)**, Biome, shadcn, i18next, Wouter. → exact look is
  **reproduced** by porting old-focal's HSL token *values* into the Tailwind-4 `@theme` and matching
  each page's structure with the new app's primitives; old-focal's `@tailwind`/config/PostCSS are
  **not** transplanted.
- **[confirmed — fs]** Both apps already use **shadcn/ui + InterVariable + an HSL token model**, so
  the foundation port is largely a **token-value transfer**, and per-page work is structural matching
  — tractable, not a from-scratch redesign.
- **[confirmed — inspection]** The new app's features are **functional over real APIs** (e.g. `tasks`
  1.1k, `budgets` 3k, `goals` 2.6k, `settings` 2.9k lines of feature code; the backend Phases 1–7 are
  ported). → re-skin over working data; **no** API/logic rebuild.
- **[confirmed — fs]** old-focal's per-page binding contracts exist: `pages/{Tags,Habits,Heatmap,
  Tasks,MeetingRequestsPage,Calendars,TimeBudgets,Analytics,Goals,Events,Calendar,AIChat,Help,
  Integrations}.tsx` (+ `components/AppSidebar.tsx`, `CalendarViews.tsx`, `MiniCalendar.tsx`, the
  dialog set, `components/MindMap/*`). The live `focal.allosta.com` screenshots are this app.
- **[confirmed — fs]** The new app's `AppSidebar.tsx` **diverges** from old-focal's: old-focal nav =
  `/goals`,`/time-budgets` · `/`(calendar),`/tasks`,`/events`,`/meeting-requests`,`/habits`,`/tags` ·
  `/heatmap`,`/analytics`,`/dashboard` · `/ai-chat`,`/help` · `/calendars`,`/integrations` + a
  Personal-CRM external link, with **role-gated** items + orphan badges; the new sidebar merged
  "tasks/events", dropped a standalone Events page, renamed routes (`/aichat` vs `/ai-chat`,
  `/calendar` vs `/`), and omits Integrations/CRM. → matching old-focal includes reconciling the
  **shell + routes**, which is therefore **slice 0** (everything inherits it).
- **[unverified — settle at each slice's design gate]** the exact per-page component inventory and the
  one-to-one map from each old-focal page to the new `features/<x>` (esp. Goals ↔ MindMap, the
  dashboard's admin gating, the new app's missing `/events` route); whether "exact" includes reusing
  old-focal's RU/EN copy verbatim (assumed yes, via the new app's i18next). None blocks the framing.

# Options considered

The **source-of-truth fork is already decided** by the user (exact old-focal). The two remaining real
forks are **(1) how to reproduce** old-focal's look on the new stack, and **(2) how to sequence**.

| # | Option | What it is | Pros | Cons |
|---|--------|-----------|------|------|
| **A — Token-first foundation, then per-page restyle (chosen)** | Slice 0 ports old-focal's light+dark HSL tokens into the Tailwind-4 `@theme` and reconciles the shell/sidebar to old-focal; each later slice matches one old-focal page using the new app's shadcn primitives + ported tokens, over the existing APIs. | Tokens **cascade** — slice 0 re-skins every baseline screen at once; stays on the sanctioned stack; surgical, independently-testable per-page diffs; mirrors the proven calendar-epic shape. | We own the per-page structural translation (not a literal copy); many slices. |
| **B — Lift-and-shift old-focal client** | Copy old-focal's pages/components/CSS/config wholesale into the new app. | Fastest literal fidelity. | Drags in **Tailwind 3 + PostCSS (forbidden)**, React-18 patterns, old-focal's `apiRequest`/Wouter/query layer — a **different data layer** than the new typed `api/*`; would fork the app or need full rewiring anyway; violates the repo stack rules. **Rejected.** |
| **C — Continue the Allosta mockup, nudged toward old-focal** | Keep building `design/focal/` and tweak it to look more like old-focal. | Preserves in-flight work. | Directly **contradicts** the user's "exact old-focal" decision; the mockup and old-focal genuinely differ (the calendar complaint). **Rejected.** |

Sequencing (fork 2): **foundation/shell first** (all pages inherit the theme), then **small,
self-contained pages** (tags → habits → heatmap) to lock the per-page pattern cheaply, then the
**heavy** ones (tasks, time-budgets, analytics, goals), with the **calendar redo** and the
remaining nav items (events, ai-chat, help, integrations, dashboard) after the pattern is proven.

# Recommendation

**Option A — token-first foundation, then per-page restyle slices, on the new stack, over existing
APIs.** Rationale: the binding source is decided, so the only question is fidelity-vs-stack — and
because the new app must stay on Tailwind 4 / shadcn / typed `api/*`, a wholesale lift (B) imports a
forbidden toolchain and the wrong data layer, while continuing the mockup (C) defies the decision.
Option A gets exact-old-focal fidelity **and** stack-compliance: port the look, keep the wiring. The
two apps already sharing shadcn + InterVariable + HSL tokens is what makes A cheap — slice 0 is
mostly a token-value transfer that re-skins every baseline page in one shot.

**Slice order + dependencies** (each a standalone 7-gate feature tracing to this think doc; slugs +
boundaries are a proposal, settled per slice):

0. `…-shell` — old-focal light+dark tokens → Tailwind-4 `@theme` + sidebar/top-bar/route reconcile.
   **Supersedes PR #50.** (base — all depend on it.)
1. `…-tags` → 2. `…-habits` → 3. `…-heatmap` (small; lock the pattern).
4. `…-tasks` → 5. `…-meeting-requests` → 6. `…-calendars` → 7. `…-time-budgets` → 8. `…-analytics`.
9. `…-goals` (Goals + MindMap; heaviest).
10. `…-events` (old-focal standalone page; the new app must add the `/events` route to match).
11. `…-calendar` — **redo to old-focal; supersedes the shipped mockup calendar.**
12. `…-aichat` → 13. `…-help` → 14. `…-integrations` → 15. `…-dashboard` (admin-gated).

**Superseded, explicitly:** the PR #50 Allosta foundation (replaced by slice 0) and the mockup-driven
calendar (replaced by slice 11). No parallel design systems are kept; the `design/focal/` mockup is
out of the loop for this epic.

# Out of scope

- Any **server / API / schema / contract / migration** change — frontend-only; a needed backend
  field is a separate flagged handoff, never faked.
- **Behavior / logic** changes — presentation parity only; data flow and functional behavior preserved.
- **Lifting old-focal's stack verbatim** (option B): no Tailwind-3 config, no PostCSS, no React-18
  `apiRequest`/Wouter wiring ported.
- **old-focal pages without a left-nav entry** — `FocalLanding`, `Privacy`/`Terms` (legal exists),
  `LoginPage`/`ResetPassword` (auth). Their own slices if ever.
- **Re-deriving / continuing the Allosta mockup** (option C) and re-litigating the design source.

# Open questions

- **Dark mode** is in scope (old-focal ships `.dark`); confirm the new app reproduces both light and
  dark at slice 0's design gate.
- **Supersede mechanics** — confirm slice 0 **replaces** the PR #50 tokens (not layered beside them)
  and slice 11 **replaces** the mockup calendar; recommend a clean replace so no two themes coexist.
- **Shell/route reconciliation** — does the new app adopt old-focal's exact sections/items incl. the
  Personal-CRM external link, the standalone `/events` page, role-gated visibility, and orphan badges?
  Settled at slice 0.
- **Per-page mapping** where the new app's structure diverges (Goals ↔ MindMap components; the admin
  Dashboard; AI-chat route rename). Settled at each slice's gate 1.
- **Copy** — assume "exact" reuses old-focal's RU/EN strings via the new app's i18next; confirm at
  slice 0.

# Success criteria

- [ ] Epic framed as an ordered, dependency-aware set of independently-shippable per-page slices,
      each a 7-gate feature tracing to this think doc; **foundation/shell first**.
- [ ] Each slice at ship: `cd superapp/apps/focal/client && pnpm lint && pnpm typecheck &&
      pnpm test:run && pnpm build` green with its own tests; surgical diff; **no** server/API change;
      i18next `ru` + `en`; **light + dark**.
- [ ] Fidelity is **old-focal-exact** and **stack-compliant**: every left-nav page matches
      `apps/old-focal` by screenshot in light+dark, reproduced on Tailwind 4 (no Tailwind-3 config /
      PostCSS), over the **existing** APIs — behavior unchanged.
- [ ] The **supersede** is explicit and complete: old-focal tokens replace the Allosta foundation;
      the calendar is redone to old-focal; nothing fakes a design old-focal doesn't have (no gap —
      old-focal covers every nav item).

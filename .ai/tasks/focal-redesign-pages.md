# Goal

Bring **every page in the Focal left-nav** (`superapp/apps/focal/client`) to **exact visual
parity with the proven production app `superapp/apps/old-focal`** — the app that "works well" —
reproduced in the new stack over the new app's already-working FastAPI data layer. The user chose
**"exact old-focal everywhere"** as the binding design contract: match old-focal pixel-for-pixel,
including its own palette/shell, **even where that supersedes the merged Allosta foundation
(PR #50) and the mockup-driven calendar redesign**. This is an **epic delivered as an ordered set
of independently-shippable per-page slices**, each run through the full 7-gate pipeline.

> **This artifact is the EPIC kickoff** — it frames the whole left-nav parity effort and the slice
> breakdown. Each slice below (`focal-redesign-<page>`) gets its **own** task + think + plan +
> design + build + test + ship. The epic think doc (`.ai/think/focal-redesign-pages.md`) is the
> parent roadmap they trace back to.

> **Binding visual contract** = `superapp/apps/old-focal/client/src/` — the pages (`pages/*.tsx`),
> components (`components/*`, incl. its own `AppSidebar.tsx`, `CalendarViews.tsx`, the dialogs), and
> theme (`index.css` light **and** `.dark` HSL token sets, `tailwind.config.ts`). The live
> `focal.allosta.com` screenshots are this same app. **Behavioral / data base** = the new app's
> existing typed `api/*` + features (already functional on real APIs). The thing being changed is
> the **presentation** of `superapp/apps/focal/client/src/features/*` (+ the shell).

> **Re-skin, not rebuild, not copy.** The new app's features already work on real APIs; this epic
> changes **only their appearance** to match old-focal. old-focal is **React 18 + Wouter +
> Tailwind 3.4 (config + PostCSS) + shadcn/ui (New York) + recharts 2 + i18next**; the new app is
> **React 19 + Tailwind 4 (CSS-first `@theme`, no config, no PostCSS — Tailwind 3 is forbidden
> here) + Biome + shadcn + i18next**. So old-focal's look is **reproduced** in the new stack
> (porting its HSL tokens into the Tailwind-4 `@theme`, matching each page's component structure
> with the new app's primitives) — **not** lifted wholesale. Both apps already share shadcn/ui +
> InterVariable + an HSL token model, so the port is tractable.

# Scope (the epic surface, mapped to slices)

Every left-nav page, decomposed into ordered slices (each a future 7-gate feature). old-focal has a
real design for **all** of them (incl. AI chat, Help, Integrations, Meeting Requests, Dashboard) —
so unlike the Allosta mockup, there is **no design gap**.

0. **`focal-redesign-shell`** — port old-focal's **theme tokens** (light + `.dark` HSL palette,
   radius, shadows, fonts) into the new Tailwind-4 `@theme`, and reconcile the **sidebar + top bar**
   to old-focal's `AppSidebar.tsx` (its sections/items/badges/role-gating, Personal-CRM external
   link). Everything inherits this; it **supersedes the PR #50 Allosta foundation**. (base — all
   other slices depend on it.)
1. **`focal-redesign-tags`** — Управление тегами → old-focal `Tags.tsx` (smallest; locks the
   per-page pattern).
2. **`focal-redesign-habits`** — Привычки → `Habits.tsx` (+ its charts/matrix).
3. **`focal-redesign-heatmap`** — Тепловая карта → `Heatmap.tsx`.
4. **`focal-redesign-tasks`** — Задачи → `Tasks.tsx`.
5. **`focal-redesign-meeting-requests`** — Запросы на события → `MeetingRequestsPage.tsx`.
6. **`focal-redesign-calendars`** — Календари → `Calendars.tsx`.
7. **`focal-redesign-time-budgets`** — Бюджеты времени → `TimeBudgets.tsx`.
8. **`focal-redesign-analytics`** — Аналитика → `Analytics.tsx`.
9. **`focal-redesign-goals`** — Карта целей → `Goals.tsx` + the MindMap components (heaviest).
10. **`focal-redesign-events`** — События → `Events.tsx` (old-focal has a standalone events page;
    the new app has no `/events` route → the slice adds it to match old-focal).
11. **`focal-redesign-calendar`** — Календарь **redone to old-focal** (`Calendar.tsx` +
    `CalendarViews.tsx`). **Supersedes the shipped mockup-driven calendar.**
12. **`focal-redesign-aichat`** — Чат с ИИ → `AIChat.tsx`.
13. **`focal-redesign-help`** — Справка → `Help.tsx`.
14. **`focal-redesign-integrations`** — Интеграции → `Integrations.tsx`.
15. **`focal-redesign-dashboard`** — Дэшборд (admin-gated) → old-focal product-dashboard screens.

Slice **order is a proposal** (foundation first, then small→heavy); merge/reorder is settled at each
slice's own gate 1/2.

# Out of scope

- **Any server / API / schema / contract / migration change.** Frontend-only re-skin over the
  **existing** APIs. If a page needs a backend field old-focal had but the new app lacks, that is a
  **separate backend handoff** (flagged from the slice that wants it), never faked.
- **Behavior / logic changes.** Preserve the new app's data flow and current functional behavior;
  this epic changes presentation only.
- **Lifting old-focal's stack verbatim** — its Tailwind-3 config, PostCSS, React-18 patterns,
  `apiRequest`/Wouter wiring, and query hooks are **not** ported; the look is reproduced on the new
  stack.
- **old-focal pages with no left-nav entry** — `FocalLanding`, `Privacy`/`Terms` (legal already
  exists), `LoginPage`/`ResetPassword` (auth). Not "left-nav pages"; their own slices if ever.
- **Re-litigating the design source** — decided: exact old-focal (supersedes the `design/focal/`
  Allosta mockup + the merged foundation).

# Acceptance criteria (epic)

- [ ] Each slice ships green from the pipeline root: `cd superapp/apps/focal/client && pnpm lint &&
      pnpm typecheck && pnpm test:run && pnpm build`, with its own tests.
- [ ] On epic completion, **every left-nav page** visually matches `apps/old-focal` in **light and
      dark** — verified by screenshots against the old-focal app — reproduced in the new stack
      (Tailwind 4, **no** Tailwind-3 config / PostCSS), over the **existing** APIs.
- [ ] Behavior preserved: each page's data flow and functional behavior are unchanged; no
      regressions in existing `*.test.tsx`.
- [ ] The supersede is explicit and complete: old-focal tokens **replace** the Allosta foundation;
      the calendar is **redone** to old-focal; no parallel design systems remain.
- [ ] No hardcoded strings (i18next `ru` + `en`, reusing old-focal's copy); no server/API change;
      each slice's diff is surgical and traces to its own task.

# Verification commands

```sh
# per slice, from the pipeline root
cd superapp/apps/focal/client
pnpm install --frozen-lockfile
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```

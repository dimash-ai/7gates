# Problem

Bring the new Focal **Habits page** (`apps/focal/client/src/features/habits/HabitsPage.tsx`) to exact
visual parity with `apps/old-focal`'s habits UI, over the existing habits API, on the shell foundation
(slice 0, landed PR #55 — tokens now match old-focal). Built in the worktree
`/Users/allosta/Desktop/superapp-habits-wt` on `feat/focal-redesign-habits` (off the shell tip).

**The decisive finding (changes the slice's shape):** the two apps' habits surfaces are **not the same
shape**.
- old-focal `Habits.tsx` is a **two-tab page**: Журнал → `HabitJournal` (888 lines), Графики →
  `HabitCharts` (331 lines, **Recharts**), plus a `HabitCreateDialog` and a title/Add header.
- The new `HabitsPage.tsx` (396 lines) is **journal-only** — no `Tabs`, no charts, no Recharts; it
  renders the habit list + per-day toggles + streaks + archived + an inline create form, all on
  `api/habits.ts` (`listHabits`/`listStreaks`/`entries`/`archived`).

So "exact old-focal habits" is **two different kinds of work**:
1. **Re-skin the journal** (exists) → match old-focal's `HabitJournal` *look* — keeping the new app's
   existing journal *behavior* (this is visual parity, not a behavior port; old-focal's 888-line
   journal interactions are not transliterated).
2. **Port the charts tab** (missing) → add a Графики tab rendering old-focal's `HabitCharts` (Recharts)
   as a **net-new view** over the existing habit/entry data. This is the one part that is a *port*,
   not a re-skin — so it carries more risk and depends on the API exposing the chart data.

Framing which is re-skin vs port, and whether the charts belong in this slice or a follow-up, is the
job of this think doc.

# Assumptions

- **[confirmed — fs]** old-focal habits contract: `pages/Habits.tsx` (Tabs journal/charts +
  `HabitCreateDialog`) + `components/habits/{HabitJournal(888),HabitCharts(331,Recharts),HabitCreateDialog}.tsx`.
  Read from the main checkout (`apps/old-focal` is untracked in `superapp`, absent from the worktree).
- **[confirmed — fs]** new `features/habits/HabitsPage.tsx` (396) is journal-only over `api/habits.ts`
  (React Query: `listHabits`/`listStreaks`/`entries`/`archived` + an inline create form); shadcn
  Card/Badge/Button/Input/Label; **no Tabs, no Recharts**. `index.ts` + `HabitsPage.test.tsx` exist.
- **[confirmed — repo]** Recharts is the stack's sanctioned chart lib (`superapp/CLAUDE.md` Tooling:
  "Recharts ≥ 3 … add on first feature use"); the new client uses it for analytics/dashboard already,
  so the charts port stays on-stack.
- **[confirmed — slice 0]** the shell foundation is landed (PR #55): `index.css` tokens/radius/shadows
  now match old-focal, so this slice **composes** them — it does not re-derive the design language.
- **[unverified — design gate]** that `api/habits.ts` (or the existing `entries`/`streaks` queries)
  exposes the per-habit history `HabitCharts` needs (completion-rate over time, the matrix/year views
  in the `habits-chart`/`habits-chart-year`/`habits-matrix` screenshots). If a chart needs data the
  API doesn't return, that chart is a **flagged backend dependency**, not faked.
- **[unverified — design gate]** the exact journal grid layout (week navigator, day cells, streak
  badges) and the create-dialog; the new journal is simpler than old-focal's 888-line version — we
  match its **appearance**, not its full interaction set.

# Options considered

The fork is **scope**: does this one slice cover journal-reskin **and** the charts port, or split?

| # | Option | What | Pros | Cons |
|---|--------|------|------|------|
| **A — one slice: journal re-skin + charts port (chosen)** | Restyle the journal to old-focal AND add the Графики tab (Recharts) in this slice. | Delivers "exact old-focal habits" whole; the user asked for "the habits slice"; both touch only the habits feature. | Largest of the small slices; the charts port adds Recharts views + a data-availability risk. |
| **B — split: `habits-journal` (re-skin) then `habits-charts` (port)** | Two slices. | Each is smaller/surgical; the journal ships fast; the charts port is isolated with its own API check. | Two pipelines for one nav page; charts is the more valuable-looking half (the screenshots emphasize it). |
| **C — journal re-skin only, defer charts** | Restyle the journal; no charts tab. | Smallest. | Leaves the page **not** matching old-focal (no Графики) — fails the parity goal. Rejected. |

# Recommendation

**Option A — one slice**, but structure the **build** into two verified sub-steps so it stays
reviewable: (1) journal re-skin, gate-checked; (2) charts tab port, gate-checked — mirroring how the
calendar epic sliced internally. **Hold Option B (split) in reserve:** if the design gate finds the
charts port balloons (e.g. needs new API data, or the matrix/year views are large), split `…-charts`
into its own slice and ship `…-journal` first. The charts data-availability check is the first design
task; build only what `api/habits.ts` backs, flag any gap rather than faking a chart.

Plan shape (settled at gate 2):
1. Confirm the habits/entries API surface vs what `HabitCharts` needs (re-skin vs port boundary).
2. Re-skin the journal + header + create dialog to old-focal (over existing behavior).
3. Add the Графики tab: port old-focal `HabitCharts` (Recharts) for the backed charts; flag any
   unbacked view.
4. `pnpm lint && typecheck && test:run && build` green; screenshots light + dark vs old-focal.

# Out of scope

- Any **server / API / schema / behavior** change — visual parity over the existing API; a chart
  needing new data is a **flagged backend handoff**, not faked.
- **Heatmap** (Тепловая карта) — its own later slice, despite being habit-adjacent.
- Transliterating old-focal's 888-line journal **interactions** — we match its look, keep the new
  app's journal behavior.
- The shell/tokens (slice 0) — composed, not changed.
- **Lifting** old-focal's Tailwind-3 components verbatim.

# Open questions

- **Charts data availability** — does `api/habits.ts` expose the per-habit history the Графики views
  need? Decides re-skin-vs-port effort and whether any chart is backend-blocked. Settled at gate 3.
- **Slice size** — if charts balloons, split per Option B (`…-journal` ships first). Decided at gate 3.
- **Journal fidelity** — how close to old-focal's grid (week nav, day cells, streak badges, reorder)
  without changing behavior. Settled at gate 3.
- **Dark mode** + **i18n** (reuse old-focal's habit copy via the new app's i18next). Confirmed at gate 3.

# Success criteria

- [ ] One slice tracing to this think doc; build = `cd /Users/allosta/Desktop/superapp-habits-wt/apps/focal/client &&
      pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green with its own tests.
- [ ] The Habits page — journal, **charts tab**, header, create dialog — matches `apps/old-focal` in
      **light and dark** (screenshots), reproduced on the new stack over the existing API.
- [ ] Behavior preserved (toggles, streaks, create); re-skin vs port boundary is explicit and
      **API-grounded** — nothing faked, any unbacked chart flagged with its backend dependency.
- [ ] Surgical diff (habits feature only); no API/behavior change; i18next `ru` + `en`.

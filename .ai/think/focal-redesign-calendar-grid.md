# Problem

First slice of the approved `focal-redesign-calendar` epic (parent:
`.ai/think/focal-redesign-calendar.md`). Today's `CalendarPage.tsx` renders a functional but plain
week grid on the real events API; it must become the **visual + structural base** of the
Google-Calendar-style calendar — the styled hour grid, now-line, today highlight, day headers, and
**event blocks with state variants in overlap lanes** — without changing any behavior. Everything in
slices 2-8 (popover, views, drag, side panel, …) composes this grid and this event block, so getting
the block component, the lane layout, and the grid chrome right *first* is what makes the later slices
layout-only. The bar for the in-scope interactions is **Google Calendar** (Today/prev-next, now-line,
today highlight, click-to-start, side-by-side overlap); the prototype `Calendar.jsx` is the visual
skin.

# Assumptions

- **[confirmed — git]** The design foundation (PR #50, HEAD `99cfab4`) is merged: bridged tokens +
  restyled `PageHeader`/`PageToolbar` + `ui/` primitives are available to compose. The grid reuses the
  foundation `PageHeader` (it already matches the prototype TopBar).
- **[confirmed — contract]** Event state variants are driven by **real `EnrichedEventRead` fields**:
  `isOrphan: boolean` exists (so orphan is the contract field, not a `projectId` heuristic), plus
  `color`, `status`, `recurrence`/`recurringEventId` (repeat marker), and the
  `date`/`startTime`/`endTime` geometry the current `blockGeometry` already uses.
- **[confirmed — tests]** `CalendarPage.test.tsx` pins the behavior this slice must preserve — the week
  request, prev-week nav, create-from-form, delete-plain, and delete/edit-recurring-with-scope. The
  inline create/edit **forms are kept** this slice (the tests use them; the popover that replaces them
  is slice 2).
- **[unverified — confirm at this slice's design gate]** The `status` → variant map. `status` is a
  free-form string and only `'planned'` is in use today; the prototype shows confirmed (filled) /
  planned (tinted) / tentative (dashed). Proposed map: `'confirmed'`→filled, `'tentative'`→dashed,
  else→tinted; `isOrphan`→danger ring (overrides). Confirmed before build.
- **[unverified]** The prototype's `HOUR_PX = 48` equals the current `HOUR_HEIGHT = 48`, so geometry
  is unchanged; only styling + the now-line + lanes are added.

# Options considered

The one real fork is **how much to extract** while restyling (the rest — colors, grid lines, now-line
— is mechanical). Keeping the diff surgical (Surgical Changes) vs setting up reuse for slices 2-8.

| option | what it is | pros | cons |
|--------|-----------|------|------|
| **A — Extract `EventBlock` + a pure lane helper, keep the rest in `CalendarPage` (chosen)** | Pull the event block into `EventBlock.tsx` and the overlap math into a unit-tested `lanes.ts`; restyle the grid + top bar in place; keep the forms. | The block + lane layout are reused by every later slice (popover anchor, views, drag); the one piece worth a unit test (lanes) gets one; the page stays otherwise intact, so the diff is reviewable and the tests keep passing. | Two new small files; a little structure before its second consumer (justified — slice 2/3/4 are the consumers and they're committed). |
| **B — Monolithic restyle in place** | Restyle everything inside `CalendarPage.tsx`, extract nothing. | Smallest file count; nothing "speculative". | The block + lane logic get re-extracted under churn in slice 3/4 anyway; the lane math is untested inline; later slices fight a 600-line page. |
| **C — Full component split now** (`WeekGrid`, `TopBar`, `HourGutter`, `DayColumn`, …) | Break the page into the prototype's component tree up front. | Closest to the prototype's structure. | Speculative for slice 1 (only the week view exists); large diff touching everything at once; against Simplicity First / Surgical Changes for a single slice. |

# Recommendation

**Option A.** Extract exactly the two pieces with a *named second consumer* in the epic — the
`EventBlock` (used by the popover anchor in slice 2, every view in slice 3, and the drag ghost in
slice 4) and the **pure lane-layout helper** (the one bit of real logic, unit-tested) — and restyle
the grid + top bar in place, keeping the forms. This sets up reuse without the speculative full split
(C) or the re-extraction churn of the monolith (B). The tradeoff accepted: two new small files now,
which the next three slices immediately consume.

# Out of scope

- The popover + recurring-scope dialog (slice 2); day/3-day/month + view switcher + mini-month (slice
  3); drag/move/resize + 15-min snap (slice 4); side panel (5); cross-DnD (6); bookings (7);
  prime-time (8); all-day + marks (backend-blocked).
- **Keyboard shortcuts** — deferred to slice 3 so they land as one coherent set alongside the view
  shortcuts (`d/w/m`). This keeps slice 1 strictly behavior-preserving (no new behavior added).
- Any change to the events API, the create/edit/delete mutations, recurrence scope, or `ContactPicker`
  behavior — appearance only.
- A multi-view switcher (no dead chrome — it arrives functional in slice 3).

# Open questions

- **`status` → variant map** (assumption above) — confirm the backend `status` values and the
  confirmed/planned/tentative mapping at the design gate before building the block. *(The one open item
  that reaches build.)*

(Resolved, no longer open: **top bar** uses the shared foundation `PageHeader` — it already matches the
prototype TopBar (see Scope/Assumptions); **keyboard shortcuts** are deferred to slice 3 so this slice
stays behavior-preserving — see Out of scope.)

# Success criteria

- [ ] `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green.
- [ ] Week grid matches the prototype in light + dark: hour gutter + grid lines, day headers, today
      highlight, the now-line, and `EventBlock` rendering confirmed/planned/tentative/orphan
      (orphan ← `event.isOrphan`).
- [ ] Concurrent events lay out **side-by-side** via the unit-tested lane helper.
- [ ] `CalendarPage.test.tsx` stays green (behavior preserved); Today + prev/next nav and the now-line
      are exercised; no dead view-switcher chrome shipped.
- [ ] Surgical diff (only `features/calendar/*` + the new `EventBlock.tsx`/lane helper, + locale files
      if a label is added); i18next `ru` + `en`; before/after screenshots vs the prototype.

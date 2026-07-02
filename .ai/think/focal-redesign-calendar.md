# Problem

The Focal calendar must move from today's single week-grid (`CalendarPage.tsx`, ~508 lines on the
real events API) to **full parity** with the design prototype `design/focal/screens/Calendar.jsx` — a
Google-Calendar-class surface: day/3-day/week/month views, a now-line, styled event blocks with
state variants, multi-lane overlap, an event popover with recurring-scope editing, drag/move/resize,
a mini-month, and a left-rail side panel of tasks/habits/goals. The user chose **full parity (an
epic)**, explicitly accepting it is a feature build cut into several slices, each through the 7 gates.
**Crucially, the bar is Google Calendar:** users live in Google Calendar, so the calendar must
reproduce its interaction conventions (quick-create on slot-click, drag-to-create / move, edge-resize,
this/following/all recurring-edit scope, Today + prev/next, mini-month, now-line, side-by-side overlap,
view switching, the common keyboard shortcuts, 15-minute snap). The prototype is the **visual skin**;
**Google Calendar is the behavior reference** — where the two diverge on interaction, Google Calendar
wins.

The merged design foundation (PR #50, HEAD `99cfab4`) already gives the calendar a correct token +
primitive base, so this epic is about **structure, views, and interaction** on top of that base — not
re-deriving the design language. The risk to manage is scope: the prototype mixes genuinely-backable
features (events, recurrence, project links, tasks/habits/goals, **bookings**, **prime-time**) with a
little richness the backend does **not** carry — the **all-day lane** and the prototype's single-day
**"marks"** (which need a `kind` discriminator the contract lacks). Framing which is which **against
the OpenAPI contract** — and an honest slice order — is the job of this think doc.

# Assumptions

- **[confirmed — git]** The design foundation is **merged** (PR #50 at HEAD `99cfab4`): bridged
  Allosta tokens in `index.css` (incl. `--focal-*` raw palette, `success/warning/info`,
  `surface-raised/sunken`, `accent-subtle`, `overlay`, motion vars), restyled shell + 30 `ui/`
  primitives. The calendar composes these; it does not redo them.
- **[confirmed — user]** **Google Calendar is the interaction / UX contract.** Reproduce Google
  Calendar behavior maximally; the prototype `Calendar.jsx` governs *appearance* (the Allosta skin),
  Google Calendar governs *interaction* where the two differ. This raises the bar on every slice's
  interactions and makes the all-day row (a core GCal feature) a **priority** backend handoff (below),
  not an indefinite deferral.
- **[confirmed — inspection]** Events are **enriched + recurrence-capable**: `EnrichedEventRead` has
  `color`, `status`, `completed`/`completedAt`, `projectId`/`productId`/`activityId`,
  `recurrence`/`recurringEventId`/`recurrenceEndDate`/`recurrenceExceptions`/`recurrenceGroupId`,
  `tags`, `contactIds`, `priority*`; `api/events.ts` exposes `list/create/update/delete` with
  `recurrenceScope` = single/following/all. So event blocks (incl. the `orphan` state — at slice-1
  design/build prefer the contract's enrichment `isOrphan`/`orphanReason` over a raw `projectId`
  heuristic), the popover links, drag/resize→`updateEvent`, and the recurring-scope dialog are all
  backable.
- **[confirmed — inspection]** The side panel is **wireable to real data**: `api/tasks.ts`,
  `api/habits.ts`, `api/goals.ts`, `api/projects.ts`, `api/products.ts`, `api/activities.ts` exist.
- **[confirmed — OpenAPI contract]** Reclassified by reading `api/openapi.d.ts` itself, not just the
  hand-written typed wrappers (the earlier "no `api/<x>.ts`" check was wrong):
  - **Bookings are backend-backed** — `/api/bookings` + `/api/bookings/{id}` (`openapi.d.ts:512`,`:530`)
    with a rich `BookingRead` (`openapi.d.ts:2712`; `BookingCreate` at `:2678`: `title`, `startDate`/`endDate`, `color`,
    `project`/`product` + `projectId`/`productId`, `sourceType`/`sourceId`, `tags`). There is just **no
    typed `api/bookings.ts` wrapper yet** — adding that thin client is **frontend-only**. → **backable
    as date-range bookings** (the strip + mini-month range indicators). `BookingRead` has **no
    `kind`/mark discriminator** (`openapi.d.ts:2712`-`2750`), so the prototype's single-day **"marks"**
    (`Booking.jsx` `kind === "mark"`) are **not** backed — deferred with all-day.
  - **Prime / golden-time is partially backed** — `UserSettings.primeTimeStart`/`primeTimeEnd`
    (`openapi.d.ts:5045`-`5058`) via `api/settings.ts`. The prototype's golden bands can be driven by
    this prime-time window; a richer per-day focus/avoid model would be a model gap. → **backable from
    settings prime-time** (richer model flagged).
  - **All-day has no backend** — `EnrichedEventRead` carries no `allDay`/`all_day` field (contract grep
    empty). → **genuinely deferred** until a backend `allDay` field lands.
  Principle holds (gate-1 lesson): build what is backed, do not ship non-functional chrome.
- **[unverified — confirm at each slice's design gate]** The exact `status` string values the backend
  emits (the prototype's confirmed/planned/tentative mapping) and how "all-day" should be represented
  if introduced later. The current page treats `status: 'planned'` as the create default.
- **[unverified]** The prototype is the authoritative visual target; `apps/old-focal` is consulted for
  behavior only, and is **secondary to Google Calendar** where the two differ (GCal is the binding
  interaction contract).

# Options considered

Two real forks: **(1)** how to build the calendar surface, and **(2)** whether to do it as one build
or sliced. Fork 2 is settled (the user chose an epic of slices); fork 1 is the substantive technical
decision.

| option | what it is | pros | cons |
|--------|-----------|------|------|
| **A — Custom grid (chosen)** | Hand-build the time-grid, views, event blocks, popover, and DnD in React over the events API, exactly as the prototype does — using Framer Motion (already a dep) for motion and **dnd-kit** (the stack's chosen DnD lib, "add on first use") for drag/resize. | Pixel parity with the prototype; full control over the Allosta look and the custom event states (orphan/tentative/now-line/golden); no heavy calendar dep to theme-fight; matches how the prototype is written, so porting is direct. | We own all the calendar logic (overlap lanes, recurrence instancing, DnD math); more code than adopting a lib; must be carefully sliced + tested. |
| **B — Calendar library** | Adopt FullCalendar / react-big-calendar / Schedule-X for views + DnD, then theme it. | Views + drag/resize/overlap out of the box; less hand-written layout math. | Will **not** match the prototype's exact look without heavy override; fights the Allosta tokens; bends our data model to the lib's event shape; custom states (orphan ring, tentative dash, golden bands, side-panel cross-DnD) are awkward or impossible; a large dep outside the documented stack. |
| **C — `@xyflow/react`** | Reuse the graph lib already in the app (goals map). | Already installed. | Wrong tool — it is a node/edge canvas, not a time-grid; no calendar affordances. Rejected outright. |

# Recommendation

**Option A — custom grid, delivered as the 8 ordered slices** in the kickoff task. The prototype is
itself a custom build; pixel-parity, the Allosta design, and the bespoke event states make a library
(B) a net negative, and `@xyflow` (C) is the wrong primitive. We lean on **Framer Motion** (already a
dep) and add **dnd-kit** at the drag/resize slice (slice 4) — the stack's sanctioned DnD choice
(`superapp/CLAUDE.md` Tooling: "dnd-kit ≥ 6 … Install when the first consuming feature lands"), not
yet in `package.json`, added on first use. The tradeoff accepted: we own the calendar logic, which is
precisely why it is sliced and each slice is independently tested through the gates.

**Slice order + dependencies** (each a standalone 7-gate feature; this think doc is their parent):

1. `…-grid` — week time-grid + event blocks + top-bar chrome (base; everything depends on it).
2. `…-popover` — event create/edit popover + recurring-scope dialog (depends on 1).
3. `…-views` — day/3-day/month + mini-month + left-rail scaffold (depends on 1).
4. `…-dnd` — drag-create/move/resize → events API, recurring-scope prompt (depends on 1 **and 2** —
   drag-created events finish in the popover and a dragged recurring instance raises the scope dialog;
   richer with 3).
5. `…-sidepanel` — tasks/habits/goals side panel on real APIs (depends on 1/3 for the rail).
6. `…-cross-dnd` — event↔task/habit drag conversions (depends on 4 + 5).
7. `…-bookings` — the **bookings** strip + mini-month **booking-range indicators**, on a new thin
   **frontend-only** typed `api/bookings.ts` wrapper over `/api/bookings` (`BookingRead`:
   title/start-endDate/color/project). The prototype's single-day **"marks"** need a `kind`
   discriminator the contract lacks → deferred (depends on 1/3).
8. `…-prime-time` — the golden/prime-time bands on the grid, driven by `UserSettings.primeTimeStart`/
   `primeTimeEnd` via `api/settings.ts` (depends on 1); a richer focus/avoid model is a flagged gap.

**Deferred — genuinely backend-blocked, surfaced not faked:** the **all-day lane** (no `allDay` field
on `EnrichedEventRead`) and the prototype's single-day **"marks"** (no `kind` discriminator on
`BookingRead`). Each needs a backend field in a separate handoff before its UI. **Because all-day is
core to Google Calendar, the `allDay` backend handoff is a priority** — deferred only until it lands.

# Out of scope

- The **all-day lane** and the prototype's single-day **"marks"** (both backend-blocked, above), and
  the Booking / Events / meeting-Requests screens. (Booking *ranges* feed the calendar strip in slice
  7; the standalone Booking screen is a separate feature.)
- Any server / API / schema change. Frontend-only; a needed backend field (e.g. `allDay`) is a
  separate handoff, flagged from the slice that wants it.
- Re-deriving the design foundation (done in PR #50) or restyling other screens.
- A calendar **library** adoption (option B) — rejected above.

# Open questions

- **Slice boundaries are a proposal.** The 8-slice cut is this think doc's recommendation; the
  reviewer / user may merge or reorder (e.g. fold the mini-month into slice 1, or split month view
  out of slice 3). Settled per slice at its own gate 1/2.
- **`status` semantics.** Confirm the backend `status` values and map them to the prototype's
  confirmed/planned/tentative blocks at the slice-1 design gate (assumption above).
- **all-day and single-day "marks"** are the backend-blocked items — adding an `allDay` field (events)
  and a `kind` discriminator (bookings) are separate backend handoffs if the product wants the all-day
  lane and per-day marks. **Date-range bookings** and **prime-time** are in-epic slices (7, 8) on
  existing contracts; the only open question there is whether the prototype's richer per-day golden
  focus/avoid model is wanted beyond the single settings prime-time window (a possible later backend
  gap), settled at slice 8's design gate.
- **Google Calendar parity details (settled per slice's design gate).** The exact keyboard-shortcut
  set (`t`/`d`/`w`/`m`/`j`/`k`/`n`/`p`/`c`), the quick-create vs full-edit popover split, snap
  granularity (GCal = 15 min), and whether to also offer GCal's 4-day view alongside the prototype's
  3-day. None blocks the epic framing; each slice names the GCal behaviors it reproduces.
- **Start slice.** Recommend `focal-redesign-calendar-grid` first; confirm before its gate 1.

# Success criteria

- [ ] Epic framed as an ordered, dependency-aware set of independently-shippable slices, each a 7-gate
      feature, tracing to this think doc.
- [ ] Each slice, at ship: `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green with its
      own tests; surgical diff; no server/API change; i18next `ru` + `en`; light + dark.
- [ ] Backable vs deferred is explicit and **contract-grounded**: events/recurrence/links/tasks/
      habits/goals **and** range bookings (`/api/bookings`) + prime-time (`settings.primeTime*`) are
      built; the **all-day lane** (no `allDay` field) and single-day **marks** (no `kind` discriminator)
      are deferred with named backend dependencies. Nothing is faked.
- [ ] On epic completion, the calendar matches the prototype (minus deferred items) across views,
      event states, popover + recurring scope, drag/move/resize, and the side panel — verified by
      screenshots against `design/focal/screenshots/` + the prototype.
- [ ] Each slice verifies the **Google Calendar behaviors** it reproduces — not only prototype
      screenshot parity: the interaction conventions from the task's Google Calendar contract within
      that slice's scope (quick-create, drag-create / move, edge-resize, recurring scope, Today /
      prev-next navigation, view shortcuts, 15-min snap) are exercised in its tests / preview.

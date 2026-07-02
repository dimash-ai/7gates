# Problem

Slice 2 of the approved `focal-redesign-calendar` epic. Slice 1 gave the calendar a Google-Calendar
week grid + styled `EventBlock`, but creating/editing events still happens in the **inline forms**
left over from before the redesign (an always-visible create card above the grid + a conditional edit
card). The prototype — and Google Calendar — instead use a **focused popover** anchored to the click,
with a separate **recurring-scope dialog**. This slice replaces the inline forms with that popover +
dialog, moving the existing event create/edit/delete + recurrence-scope behavior into the
prototype/GCal interaction while surfacing the popover's backable fields (color, mark-done, goal-map
links). It matters now because every later slice (drag-create in slice 4, conversions in slice 6)
opens this same popover, so it must exist and own the create/edit contract first.

# Assumptions

- **[confirmed — git]** Slice 1 is in HEAD: `EventBlock` exposes `onSelect(event)` and `CalendarPage`
  has the `prefill(dateIso, hour)` slot-click hook — the two open points the popover hangs off.
- **[confirmed — contract]** `EventCreate` and `EventUpdate` (`api/openapi.d.ts`) accept every field
  the popover sets: `title`, `date`, `startTime`, `endTime`, `color`, `completed`, `status`,
  `recurrence`(+`recurrenceEndDate`/`recurrenceExceptions`), `projectId`, `productId`, `activityId`,
  `contactIds`. So nothing in the popover needs a backend change.
- **[confirmed — inspection]** The primitives exist (foundation-restyled): `components/ui/popover.tsx`,
  `dialog.tsx`, `select.tsx`, `switch.tsx`, `checkbox.tsx`. The link lists exist: `listProjects()`,
  `listProducts(projectId)` (products are child projects of the chosen project), `listActivities()`.
- **[confirmed — inspection]** The current `CalendarPage.test.tsx` drives the **inline forms** (create
  from the form; edit/delete a recurring occurrence via the edit card + scope radios). This slice
  **rewrites those tests to drive the popover + scope dialog** — the assertions on
  `createEvent`/`updateEvent`/`deleteEvent` payloads + `{ scope, occurrenceDate }` are preserved; only
  the UI path changes.
- **[unverified — confirm at design gate]** "Mark as done" maps to the real **`completed: boolean`**
  (the prototype conflates it with `status:"done"`; the real model carries both, and `completed` is
  the existing done-flag the create payload already sends).
- **[unverified]** The prototype is the visual target; Google Calendar is the interaction reference
  (one popover for create + edit, scope dialog on recurring save/delete).

# Options considered

| option | what it is | pros | cons |
|--------|-----------|------|------|
| **A — radix `Popover` + `Dialog`, one popover for create+edit (chosen)** | Reproduce the prototype `EventPopover` on the foundation radix `Popover` anchored to the clicked slot/event, and the scope dialog on radix `Dialog`; one popover serves both create and edit (as the prototype does). | Free a11y (focus trap, Escape, outside-click, ARIA) + collision-aware positioning (floating-ui) — exactly the prototype's manual clamp, without hand-rolling it; reuses foundation primitives; matches GCal's single edit surface. | One component handles two modes (new vs existing) — needs clear state; radix positioning must be anchored to a virtual point for slot-clicks. |
| **B — Custom fixed-position panel** | Port the prototype's literal fixed-position div + manual viewport clamp. | 1:1 with the prototype code. | Re-implements focus/escape/outside-click/positioning that radix already gives correctly; more code, more a11y risk; against Simplicity First when the primitive exists. |
| **C — GCal quick-create + separate full editor** | A minimal quick-create bubble (title+time) with "more options" → a full editor, like Google Calendar proper. | Closest to literal GCal. | The **prototype** (our visual contract) uses one richer popover, not a two-step quick-create; building two surfaces is more than this slice needs. Defer the quick-create/full split if ever wanted. |

# Recommendation

**Option A.** Build the popover on the foundation radix `Popover` (anchored at the click via a virtual
anchor for slot-clicks, the `EventBlock` element for edits) and the scope dialog on radix `Dialog`,
one popover for both create and edit — matching the prototype's single surface and GCal's single edit
popover, while getting a11y + positioning for free. The tradeoff accepted: one component carries a
`new | existing` mode, kept explicit in its state. Recurring edits/deletes route through the scope
dialog into the **existing** `RecurrenceScope` contract (no behavior change to the mutations).

**On scope size:** the popover is rich (title, time, recurrence, color, mark-done, **and** the
Project→Product→Activity goal-map selects with their three link queries). That is the faithful
prototype popover and all of it is backable, so it stays one slice — but if the plan gate judges it
too large to review in one sitting, the **clean cut is the goal-map link selects** into a focused
follow-up (`…-popover-links`), leaving the core create/edit/recurrence/color popover here. Flagged for
the plan gate to decide.

# Out of scope

- All-day toggle (no backend `allDay` — epic deferral); convert-to-task/habit (slice 6);
  description/location fields (kept minimal); day/3-day/month + mini-month (slice 3); drag/resize
  (slice 4); side panel (5); bookings (7); prime-time (8).
- Any server/API/schema change; the quick-create/full-editor split (option C).

# Open questions

- **Slice size / the goal-map link selects** — keep them in this slice (faithful, larger) or split to
  `…-popover-links`? Recommend keeping unless the plan gate prefers the split (above).
- **`ContactPicker` in the popover** — keep it (preserving today's UI-only participant picking, which
  does not yet persist pending the crm-boundary ADR) vs drop it. Recommend keep (no regression),
  placed in the popover; its non-persistence is unchanged from today, not new.
- **"Mark done" → `completed`** (assumption above) — confirm at the design gate vs writing `status`.
- **Anchoring (a concrete design-gate decision, not just open)** — slice 1's `prefill(dateIso, hour)`
  and `EventBlock.onSelect(event)` do **not** currently pass click coordinates or an anchor element, so
  the popover anchoring **requires extending those hooks** (pass the slot/event DOM element, or a
  virtual-anchor point/rect) — to be specified at the design gate. Radix `PopoverAnchor` at the clicked
  slot for create vs the `EventBlock` element for edit.

# Success criteria

- [ ] `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green.
- [ ] Slot-click → prefilled **create** popover → Save = `createEvent` (prior payload shape + any
      color/links); event-click → **edit** popover → Save = `updateEvent`, Delete = `deleteEvent`.
- [ ] Recurring save/delete opens the **scope dialog**; the chosen `single`/`following`/`all` reaches
      the mutation as `{ scope, occurrenceDate }` — proven by the rewritten `CalendarPage.test.tsx`
      recurring tests (payloads unchanged from slice-1 behavior).
- [ ] Project→Product(dependent)→Activity selects load from the real APIs; no-projects empty state, no
      crash.
- [ ] Popover + dialog match the prototype in light + dark; radix a11y (focus/Escape/outside-click);
      Enter saves; the inline forms are gone.
- [ ] i18next `ru` + `en`; surgical diff (`features/calendar/*` + the two new components + locales);
      before/after screenshots vs the prototype.

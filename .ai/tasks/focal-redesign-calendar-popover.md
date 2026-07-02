# Goal

**Slice 2 of the `focal-redesign-calendar` epic** (parent: `.ai/think/focal-redesign-calendar.md`;
builds on slice 1 `focal-redesign-calendar-grid`, the styled week grid + `EventBlock` now in HEAD
`9385f5a`/`9ce1a8b`). Replace the calendar's two **inline forms** (the always-visible create card and
the conditional edit card in `CalendarPage.tsx`) with a **Google-Calendar-style event popover** that
opens **on slot-click (create)** and **on event-click (edit)**, plus the **"this / following / all"
recurring-scope dialog**. After this slice, creating and editing events happens in a focused popover
matching the prototype, and the page body is just the grid.

> **Visual contract** = the prototype `design/focal/screens/Calendar.jsx` — `EventPopover` (`:1335`-
> `:1462`) and `RecurringScopeDialog` (`:1465`-`:1490`) + the foundation primitives. **Interaction
> contract = Google Calendar:** click an empty slot → popover prefilled with that time; click an event
> → popover with its details; editing a recurring event prompts the scope dialog on save **and**
> delete (this / this-and-following / all). **Behavioral base** = the current inline forms in
> `CalendarPage.tsx` (the `createEvent`/`updateEvent`/`deleteEvent` calls + `RecurrenceScope` they
> already drive) — that contract is preserved; only the UI driving it changes.

> **Frontend-only.** No server/API/schema change. The popover wires to the **existing** contracts —
> `api/events.ts` (`EventCreate`/`EventUpdate` already accept `title`, `date`, `startTime`, `endTime`,
> `color`, `completed`, `status`, `recurrence`(+`recurrenceEndDate`/`Exceptions`), `projectId`,
> `productId`, `activityId`, `contactIds`) and the link lists `api/projects.ts` `listProjects`,
> `api/products.ts` `listProducts(projectId)`, `api/activities.ts` `listActivities`. Strings via
> i18next (`ru` + `en`).

# Scope

**The popover** — new `features/calendar/EventPopover.tsx`, opened from `CalendarPage`

- Built on the foundation **radix `Popover`** (`components/ui/popover.tsx`) anchored at the
  clicked slot/event (collision-aware positioning), reproducing the prototype `EventPopover` look
  (~332px, color-dot + title, soft surface, `--shadow-xl`, divided sections). Autofocus the title;
  Enter saves; Escape closes (a titleless new draft is discarded).
- **Fields** (each wired to the real event payload):
  - **Title** (`title`).
  - **Time** — start + end (`startTime`/`endTime`), reproducing the prototype `GoogleWhen` date+time
    row idiomatically (shadcn inputs/`select`).
  - **Mark as done** — toggles `completed` (the real boolean; prototype uses `status:"done"` — mapped
    to `completed`).
  - **From the goal map** — Project / Product / Activity selects (`projectId`/`productId`/`activityId`),
    wired to `listProjects` / `listProducts(projectId)` (dependent on the chosen project) /
    `listActivities`. Empty state when a user has no projects.
  - **Repeat** — recurrence (`recurrence` over the existing `RECURRENCES` set; `recurrenceEndDate`
    preserved), reproducing the prototype `RepeatPicker` trigger.
  - **Color** — the `CAL_PALETTE` swatch row → `color` (the same local palette slice 1's `EventBlock`
    already uses).
  - **Participants** — keep the existing `ContactPicker` (PRIMA), preserving today's UI-only behavior
    (participants stay in component state; persistence still awaits the crm-boundary ADR — unchanged).
- **Create flow:** clicking an empty grid slot (the existing `prefill` hook) opens the popover for a
  **new** event prefilled with that date/time; Save → `createEvent` with the same payload shape as
  today plus the popover's fields.
- **Edit flow:** clicking an `EventBlock` (slice 1's `onSelect`) opens the popover for that event;
  Save → `updateEvent`; Delete → `deleteEvent`.

**Recurring-scope dialog** — new `features/calendar/RecurringScopeDialog.tsx`

- Built on the foundation **radix `Dialog`** (`components/ui/dialog.tsx`), reproducing the prototype
  `RecurringScopeDialog`: a "this / this and following / all" radio (`single` / `following` / `all`,
  the existing `RecurrenceScope`) + Cancel / OK. Shown on **save and delete of a recurring event**;
  the chosen scope feeds `updateEvent`/`deleteEvent`'s `{ scope, occurrenceDate }` exactly as the
  current edit card's scope radios do.

**`CalendarPage` rewire**

- Remove the inline create `Card` and edit `Card`; replace the `form`/`draft`/`scope` state with
  popover state (which event/new-draft is open, the anchor, the scope-dialog state). Keep the events
  query, the mutations (`createMutation`/`updateMutation`/`deleteMutation`), `invalidate`,
  `onMutationError`/error display, and loading states **unchanged**.

# Out of scope

- **All-day toggle** — the prototype shows it, but `EnrichedEventRead`/`EventCreate` have no `allDay`
  field (backend-blocked, epic deferral). Omitted, not faked.
- **Convert to task / habit** — the prototype's "Перенести: В задачу / В привычку" is a cross-feature
  conversion → slice 6 (`…-cross-dnd`).
- **Description / location fields** — not in today's forms or the prototype popover; keep the field
  set minimal (the API accepts them, but adding them is its own concern).
- **Day/3-day/month views, mini-month, left rail** (slice 3); **drag / move / resize** (slice 4);
  **side panel** (slice 5); **bookings** (7); **prime-time** (8).
- Any server / API / schema change.

# Acceptance criteria

- [ ] `cd superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`
      all green.
- [ ] Clicking an empty slot opens a **create** popover prefilled with that date/time; Save calls
      `createEvent` with the prior payload shape (title/date/startTime/endTime/status/completed/
      recurrence) plus any set `color`/`projectId`/`productId`/`activityId`.
- [ ] Clicking an event opens an **edit** popover; Save calls `updateEvent`; Delete calls
      `deleteEvent`; both carry `{ scope, occurrenceDate }` for recurring events.
- [ ] The **Mark as done** toggle sends `completed: true`/`false` on save (the real boolean field —
      not `status: "done"`) — verified in the popover create/edit test.
- [ ] Editing or deleting a **recurring** event opens the **scope dialog** (this/following/all) and the
      chosen `RecurrenceScope` reaches the mutation — matching today's behavior (covered by the ported
      `CalendarPage.test.tsx` recurring tests, rewritten to drive the popover + dialog).
- [ ] Project → Product (dependent) → Activity selects populate from the real link APIs; a user with no
      projects sees an empty state, not a crash.
- [ ] Popover matches the prototype in **light and dark**: header, sections, color swatches, footer;
      radix a11y (focus, Escape, outside-click) works; Enter saves.
- [ ] No hardcoded strings (i18next `ru` + `en`); the diff is surgical — `features/calendar/*`
      (+ the two new components) and locale files only; no server change.
- [ ] Before/after screenshots (create + edit popover + scope dialog, light + dark) vs the prototype.

# Verification commands

```sh
cd superapp/apps/focal/client
pnpm install --frozen-lockfile
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```

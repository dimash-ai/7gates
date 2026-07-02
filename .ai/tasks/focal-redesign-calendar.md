# Goal

Bring the Focal **calendar page** (`superapp/apps/focal/client/src/features/calendar`) to **full
visual + interaction parity** with the design prototype `superapp/design/focal/screens/Calendar.jsx`,
composing the **already-merged design foundation** (PR #50 — bridged Allosta tokens, restyled shell +
primitives at HEAD `99cfab4`) and the app's **real Focal APIs**. Because the prototype calendar is a
Google-Calendar-class surface (multi-view, drag/resize, event popover, recurring-scope, a left rail
with mini-month + a tasks/habits/goals side panel) and today's `CalendarPage.tsx` is a single
week-grid on the events API, this is an **epic delivered as an ordered set of independently-shippable
slices**, each run through the full 7-gate pipeline.

> **This artifact is the EPIC kickoff** — it frames the whole calendar-parity effort and the slice
> breakdown. Each slice below (`focal-redesign-calendar-<n>`) gets its **own** task + think + plan +
> design + build + test + ship. The epic think doc (`.ai/think/focal-redesign-calendar.md`) is the
> parent roadmap they trace back to.

> **Binding visual contract** = `superapp/design/focal/screens/Calendar.jsx` (+ `Primitives.jsx`,
> `app.css`, `colors_and_type.css`, and the reference images under `design/focal/screenshots/`:
> `cal-header.png`, `month*.png`, `01/02-event_popover.png`, `arrows*.png`, `golden*.png`).
> **Behavioral base / oracle** = the current `CalendarPage.tsx` (the real events API + recurrence
> scope it already drives) and `superapp/apps/old-focal` (the legacy calendar's behavior). The thing
> being changed is `superapp/apps/focal/client/src/features/calendar`.

> **Interaction / UX contract = Google Calendar.** Users live in Google Calendar, so this calendar
> must reproduce Google Calendar's interaction conventions: click an empty slot → quick-create;
> drag across slots → create with that duration; click an event → details popover; drag to move;
> drag the edges to resize; the this/following/all recurring-edit scope dialog; Today + prev/next +
> the date-range label; mini-month navigation; the now-line; side-by-side overlap of concurrent
> events; Day/Week/Month (+ the prototype's 3-day) view switching; and the common Google Calendar
> keyboard shortcuts (e.g. `t` today, `d/w/m` views, `j/k` or `n/p` prev/next, `c` create). The
> prototype `Calendar.jsx` is the **visual skin** (the Allosta look); **Google Calendar is the
> behavior reference** — where the prototype is silent on or diverges from an interaction, the Google
> Calendar convention wins. Each slice's design gate names the specific Google Calendar behaviors it
> reproduces and snaps to (15-minute slot granularity by default, like GCal).

> **Frontend-only.** No FastAPI/server, schema, or contract change. Slices wire to the **existing**
> APIs (`api/events.ts` enriched events + recurrence scope; `api/tasks.ts`, `api/habits.ts`,
> `api/goals.ts`, `api/projects.ts`, `api/products.ts`, `api/activities.ts` for the side panel +
> popover links). If a slice would need a new backend field (e.g. an `allDay` flag), that is a
> **separate backend slice handoff**, not done here — see Out of scope. All user-facing strings via
> i18next (`ru` + `en`).

# Scope (the epic surface, mapped to slices)

The prototype calendar, decomposed into ordered slices (each a future 7-gate feature):

1. **`focal-redesign-calendar-grid`** — the week time-grid restyled to the prototype: top bar
   (title + date stepper + Today + the view-switcher chrome + AI button), hour gutter, grid lines,
   **now-line**, today highlight, day-column headers, and the **event-block** component with the
   prototype's visual states — `confirmed` (filled `color`, white text), `planned` (tinted), `tentative`
   (dashed), `orphan` (no `projectId` → danger ring) — plus multi-lane overlap layout. Keeps the
   existing week data + events API and the current create/edit forms (lightly restyled) until slice 2.
2. **`focal-redesign-calendar-popover`** — the event **popover** (create on slot-click, edit on
   event-click) replacing the inline forms: title, time, recurrence + the **recurring-scope dialog**
   (this / following / all), color swatches, project/product/activity selects, completed toggle,
   delete. Wired to `events` + link APIs.
3. **`focal-redesign-calendar-views`** — **day / 3-day / month** views + the **mini-month** navigator
   and the left-rail scaffold. Pure client view logic over the events query (window per view).
4. **`focal-redesign-calendar-dnd`** — drag-to-create, **move**, and **resize** (top/bottom) of events
   → `createEvent`/`updateEvent`, with the recurring-scope prompt when a recurring instance is dragged.
5. **`focal-redesign-calendar-sidepanel`** — the left-rail **side panel**: tasks / habits / goals tabs
   wired to the real `tasks`/`habits`/`goals` APIs, with filters, create rows, and per-item menus.
6. **`focal-redesign-calendar-cross-dnd`** — drag **event ↔ task / habit** conversions between the
   side panel and the grid (depends on 4 + 5).
7. **`focal-redesign-calendar-bookings`** — the **bookings** strip + mini-month **booking-range
   indicators**, on a new thin **frontend-only** typed `api/bookings.ts` wrapper over the existing
   `/api/bookings` contract (`BookingRead`/`BookingCreate`). The prototype's single-day **"marks"**
   need a `kind` discriminator the contract lacks → deferred (depends on 1/3).
8. **`focal-redesign-calendar-prime-time`** — the golden/**prime-time** bands on the grid, driven by
   `UserSettings.primeTimeStart`/`primeTimeEnd` via `api/settings.ts` (depends on 1; a richer per-day
   focus/avoid model would be a flagged backend gap).

# Out of scope

- **Backend-blocked, deferred (flagged, not faked):** the **all-day lane** (`EnrichedEventRead` has no
  `allDay` field) and the prototype's single-day **"marks"** (`BookingRead` has no `kind`
  discriminator). Each needs a backend field via a separate handoff. **Because all-day events are core
  to Google Calendar, the `allDay` backend field is a recommended priority handoff** (deferred only
  until it lands, not indefinitely). **Date-range bookings** (`/api/bookings`) and **prime-time**
  (`settings.primeTime*`) are **in scope** (slices 7-8) on existing contracts.
- The standalone **Booking**, **Events**, and **meeting-Requests** screens — separate features/slices
  (the booking-range *data* still feeds the calendar bookings strip in slice 7).
- Any **server / API / schema / contract / migration** change. Frontend-only; a needed backend field
  is a separate handoff.
- Restyling other feature screens (their own redesign slices).

# Acceptance criteria (epic)

- [ ] Each slice ships green: `cd superapp/apps/focal/client && pnpm lint && pnpm typecheck &&
      pnpm test:run && pnpm build`, with its own tests.
- [ ] On epic completion, the calendar matches `Calendar.jsx` (minus the deferred **all-day lane** and
      single-day **marks**) in **light and dark** — week/day/3-day/month views, styled event blocks
      with all states, the event popover + recurring-scope dialog, drag/move/resize, the
      tasks/habits/goals side panel, the **bookings** (range) strip, and the prime-time bands —
      verified by screenshots against the prototype reference.
- [ ] Behavior preserved/extended on real data: events CRUD + recurrence scope still correct; the side
      panel reflects real tasks/habits/goals; no regressions in the existing `CalendarPage.test.tsx`.
- [ ] No hardcoded strings (i18next `ru` + `en`); no server/API change; each slice's diff is surgical
      and traces to its own task.

# Verification commands

```sh
# per slice, from the pipeline root
cd superapp/apps/focal/client
pnpm install --frozen-lockfile
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```

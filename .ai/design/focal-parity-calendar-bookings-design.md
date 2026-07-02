# Design: focal-parity-calendar-bookings

## Problem & decision

old-focal shows **bookings («пометки»)** on the calendar: titled, colored **multi-day date-spans**
(`startDate → endDate`, no clock time), optionally linked to a project/product + tags, rendered as marks
on every day they cover, with a `BookingDialog` to create/edit/delete them and filters
(`apps/old-focal/client/src/components/CalendarViews.tsx`, `BookingDialog.tsx`). The new app has the
**backend** — `BookingRead/Create/Update` + CRUD endpoints (`/api/bookings`, `/api/bookings/{id}`),
RLS — but **no bookings UI at all**: no api client, no overlay, no dialog.

**Decision:** build the full bookings UI as a frontend slice over the existing API:
- an **`api/bookings.ts`** client mirroring `api/events.ts` (list/create/get/update/delete);
- a **per-day overlay** — a booking covers a day when `startDate ≤ day ≤ endDate` (old-focal's rule),
  rendered as a small colored chip on each covered day in the **time-grid all-day strip** (day / 3-day /
  week, where the chip is **clickable to edit**), and as a **non-interactive marker** in **month** cells
  and a **dot** in **year** — those day cells are already zoom `<button>`s, so a nested clickable chip
  would be invalid HTML and would also fire the zoom; the marker is visual-only there, and editing happens
  from the strip or the New-booking entry;
- a **`BookingDialog`** with the core create/update field set (title, description, start/end date, color,
  project, product) for create / edit / delete, optimistic + rollback like events; **tags + activity are
  deferred** to a follow-up — their pickers (a `MultiSelect` with inline tag-create; an activity select
  dependent on product) are inline-coupled inside `EventDialog` and would need a shared extraction, which
  is out of scope here. A booking's defining fields (title, dates, color) + its main project/product link
  are all covered;
- **filters** — a persisted show/hide toggle (the most-felt declutter control); a per-project booking
  filter is a deferred follow-up (bookings are few; show/hide covers the core need).

**Fetch strategy (load-bearing — the backend list is containment-filtered).** The backend
`list_bookings` returns only bookings **fully contained** in the requested window
(`start_date ≥ window_start AND end_date ≤ window_end`; `server/app/services/bookings.py`,
`test_bookings_db.py:147` asserts overlapping ones are excluded), and a missing window falls back to
*today's month* (`domain/daterange.py` `get_date_range`). A naive `listBookings(visibleWindow)` would
therefore **silently drop** multi-day bookings that start before or end after the visible window. So the
client fetches with a **very wide explicit window** (`BOOKINGS_RANGE = 2000-01-01 → 2100-12-31`) — within
which every realistic booking is contained, so the call returns effectively all the user's bookings — and
then filters **client-side** by `coversDay` for the visible days. Bookings are few (vacations/sprints), so
fetching the full set is cheap; this sidesteps the containment limitation without a backend change.

**Reuse-first (CLAUDE.md #2):** the API exists; the all-day strip, month/year cells, the date helpers, the
shadcn dialog + the **project/product/tags pickers from `EventDialog`**, and the optimistic-mutation
pattern all already exist — this slice wires them to a new data type.

**Alternatives rejected:**
- **`listBookings(visible window)`** (containment): rejected — drops overlapping multi-day bookings (the
  blocker above). The wide-window + client-filter strategy is correct and simple.
- **Spanning bars** across covered columns: rejected for the first cut — old-focal marks each covered day
  independently (no cross-column geometry); a continuous bar is later polish.
- **Mini-month booking dots in this feature:** rejected — `MiniMonth` owns an **independent displayed
  month + its own event query** (it browses ahead of the main view), so it would need its own bookings
  fetch for its own range; deferred to a follow-up rather than mis-threading the page's bookings.

## Assumptions & scope

- **(confirmed — code)** `BookingRead`: `id,userId,title,description,startDate,endDate,color,project,
  projectType,product,projectId,productId,tags,sourceType,sourceId,...`. `BookingCreate/Update`:
  `title,description,project,projectId,projectType,product,productId,tags,startDate,endDate,color`.
  Endpoints: `GET/POST /api/bookings`, `GET/PATCH/DELETE /api/bookings/{id}`; list params
  `startDate/endDate/calendarId` all optional, **containment-filtered**, missing→today's month.
- **(confirmed — code)** old-focal `BookingDialog` saves the full field set (title, description, project +
  id + type, product + id, tags, start/end, color) — so "full parity" keeps all of them.
- **(confirmed — code)** the TimeGrid all-day strip exists but is gated on `allDayByDay.size > 0`; it must
  also render when bookings exist. MonthView/YearView render from the page's window; `MiniMonth` does not.
- **(confirm at build)** the `apiFetch` shape + whether bookings are calendar-scoped for shared calendars
  (pass `calendarId` like `listEvents` does); the project/product/tags picker reuse details. Settle in B1/B3.
- **Out of scope:** mini-month booking dots (independent-window follow-up); a continuous spanning-bar
  render; booking↔event/task conversion; recurring bookings (no recurrence in the model).
- **Open questions:** None blocking.

## Success criteria

- [ ] Bookings load via the wide-window fetch and render as a colored chip on **every day they cover**
      (`startDate ≤ day ≤ endDate`, both ends inclusive) in the day/3-day/week all-day strip (clickable),
      and as a non-interactive marker on covered month cells / a dot on covered year days. A booking that
      starts before / ends after the visible window still shows on its covered visible days.
- [ ] The calendar's **empty state** considers bookings: the "no events" overlay shows only when there are
      **no events AND no visible bookings** (a calendar with only bookings is not "empty").
- [ ] Booking markers in month / year are **non-interactive** — clicking a day cell still zooms; the marker
      never nests in the cell `<button>` nor hijacks the zoom.
- [ ] The all-day strip renders when there are all-day events **or** bookings.
- [ ] A **New booking** entry opens a dialog with the full field set; saving a valid booking (title +
      start ≤ end) persists via `createBooking` and the chip appears; an invalid range is blocked with a
      localized message.
- [ ] Clicking a booking chip opens the dialog to **edit** (`updateBooking`) or **delete**
      (`deleteBooking`); changes reflect optimistically and roll back on error with a localized message.
- [ ] A **show/hide filter** toggles bookings visibility; the choice persists across reloads (events untouched).
- [ ] On a **read-only** calendar (`!canEdit`), chips render (informational) but create/edit/delete are
      disabled.
- [ ] Booking chips never block event/slot interactions (they live in the all-day strip / cell margins).
- [ ] All strings i18next ru + en; the suite stays green (`pnpm lint && typecheck && test:run && build`).

## Build approach (slices)

| # | slice | files | main failure mode | what its test proves |
|---|-------|-------|-------------------|----------------------|
| B1 | API client + strip overlay | `api/bookings.ts` (CRUD, mirrors `events.ts`), `features/calendar/bookings.ts` (`BOOKINGS_RANGE`, pure `coversDay`/`bookingsOnDay`), `TimeGrid.tsx` (chips in the all-day strip; strip renders for bookings too), `CalendarPage.tsx` (wide-window bookings query; **empty-state counts visible bookings**) | containment drops overlapping bookings; off-by-one; strip hidden when only bookings; empty overlay over a bookings-only calendar | `coversDay` inclusive both ends + true for a span crossing the window; the strip shows a chip on each covered day (incl. a booking starting before the window), renders with no all-day events; a bookings-only calendar is not "empty" |
| B2 | Month / year overlay | `MonthView.tsx`, `YearView.tsx` (covered-day **non-interactive** marker/dot — never nested in the cell zoom `<button>`), `CalendarPage.tsx` (thread bookings) | nested button / zoom hijack; view off-by-one | a multi-day booking marks each covered month cell + year day as a non-interactive indicator; clicking the cell still zooms (the marker doesn't intercept) |
| B3 | BookingDialog (CRUD) | `features/calendar/BookingDialog.tsx` (title/description/start/end/color/project/product — native date inputs; project→product selects reusing `listProjects`/`listProducts`; tags+activity deferred), `CalendarPage.tsx` (New-booking entry, click-to-edit, optimistic create/update/delete + rollback) | invalid range persists; metadata dropped; **cleared field silently kept** (update preserves omitted keys); no rollback; double-create | create calls `createBooking` with the full payload; **update sends the full field set with explicit `null` for cleared optionals** (a removed project/product actually clears); edit/delete call update/delete; invalid range blocked; rejected save rolls back; gated by `canEdit`; a synchronous guard blocks a double-create |
| B4 | Filters | `features/calendar/bookingsFilter.ts` (persisted show/hide toggle), `CalendarPage.tsx` (apply + persist) | filter not persisted; hides events too | toggling off hides booking chips (events untouched); the choice persists across reload (project filter deferred) |

Each slice leaves `pnpm lint && typecheck && test:run && build` green and is committed on the branch.

## Architecture & contracts

```
api/bookings.ts: listBookings(range[, calendarId]) / createBooking / getBooking / updateBooking / deleteBooking   (mirrors events.ts)
features/calendar/bookings.ts: BOOKINGS_RANGE = ['2000-01-01','2100-12-31'] ; coversDay(b, dayIso) = b.startDate ≤ dayIso ≤ b.endDate ; bookingsOnDay(bookings, dayIso)
CalendarPage
  ├─ useQuery(bookingsKey) → listBookings(BOOKINGS_RANGE, calendarId) → Booking[]   // wide fetch, client-filtered per view
  ├─ filter (show/hide + project, persisted)                                        // B4
  ├─ <TimeGrid bookings onBookingSelect … />  → all-day strip chips (clickable)      // B1
  ├─ <MonthView|YearView bookings … />        → non-interactive markers (no select)  // B2
  └─ New-booking + click-chip → <BookingDialog> → create/update/delete (optimistic + rollback)   // B3
```

| entity / interface | change | notes |
|--------------------|--------|-------|
| `api/bookings.ts` (new) | CRUD over `/api/bookings`; types from `BookingRead/Create/Update` | mirror `events.ts` (apiFetch + optional `calendarId`) |
| `bookings.ts` (new, pure) | `BOOKINGS_RANGE`, `coversDay` (inclusive), `bookingsOnDay` | unit-tested; the one coverage rule reused by every view |
| `TimeGrid` | `bookings?` + `onBookingSelect`; strip gate becomes `allDayByDay.size > 0 || bookings.length > 0` | chips in the all-day strip; `aria`-labelled; don't intercept timed-lane clicks |
| `MonthView` / `YearView` props | `bookings?` only (no `onBookingSelect`) | covered-day **non-interactive** marker / dot — never nested in the cell's zoom `<button>` |
| `BookingDialog` (new) | full field set; reuse the `EventDialog` project/product/tags + color pickers, minus time/recurrence | parity with old-focal's save payload |
| `CalendarPage` | wide-window bookings query; **empty-state counts visible bookings**; optimistic create/update/delete + rollback; filter state; dialog wiring | mirrors the events pattern; update sends explicit `null` for cleared fields; a synchronous guard on create |
| data model | **None** | reuses the existing bookings API/backend |

## Flow (happy + unhappy)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| render | bookings query resolves | views | a chip on each covered visible day (incl. spans crossing the window); dot in year |
| create | New booking → valid save | `BookingDialog` → `createBooking` (optimistic) | chip appears; rollback + error on reject |
| edit/delete | click chip → edit/delete | `BookingDialog` → `update/deleteBooking` (optimistic) | reflects; rollback + error on reject |
| invalid range | end < start | `BookingDialog` validation | blocked, localized message, nothing persists |
| filter off | toggle bookings off | `CalendarPage` (persisted) | chips hidden; events untouched |
| read-only | `!canEdit` | dialog/entries disabled | chips show; no create/edit/delete |

## Test strategy, security & rollback

- **Test strategy.** Unit: `coversDay`/`bookingsOnDay` (inclusive endpoints, multi-day, **a span starting
  before / ending after the window still covers its in-window days**). Component (happy-dom): the all-day
  strip renders chips on covered days (and renders with bookings but no all-day events); month/year mark
  covered cells; `BookingDialog` validates the range + sends the full payload; the filter hides chips (not
  events) and persists. Integration (`CalendarPage`): create/edit/delete call the booking API optimistically
  and roll back on error; `canEdit=false` disables the entries; a double-create is guarded. "Verified" =
  those + `pnpm lint && typecheck && test:run && build` green.
- **Security.** No new surface; reuses the existing bookings API (server RBAC + RLS enforce ownership/
  sharing). The `canEdit` client gate is UX. The project filter only lists reference data the user can read;
  on a shared calendar where other-pages data isn't readable it degrades to no project options (no error).
  No secrets/PII; all strings i18n.
- **Rollback.** Pure frontend, no migration — revert the PR.

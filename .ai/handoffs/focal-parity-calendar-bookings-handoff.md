# Stage

3-Gate flow — Gate C (verify), release gate. Feature `focal-parity-calendar-bookings`.

# What changed

Restores old-focal's **bookings («пометки»)** — titled, colored multi-day date-spans — as a full
frontend UI over the existing bookings API:

- **B1** — `api/bookings.ts` CRUD client + a per-day overlay of colored chips in the day/3-day/week all-day strip.
- **B2** — non-interactive booking markers on month cells and a dot in year (the cell stays a zoom button).
- **B3** — a `BookingDialog` to create / edit / delete a booking (title, description, start/end date, color, project, product), with optimistic create/update/delete + rollback in `CalendarPage`.
- **B4** — a persisted show/hide toggle to declutter the calendar.

The backend list is **containment-filtered**, so the client fetches a wide window
(`2000-01-01 → 2100-12-31`) and filters to the visible days with an inclusive `coversDay` rule — a
booking spanning beyond the visible window still shows on its covered days. The verify pass found and the
build fixed four issues: cleared denormalized project/product labels on unchanged edits, save errors
rendered behind the modal, optimistic-create rollback missing on an empty cache, and unvalidated dates.

# Files touched

- `apps/focal/client/src/api/bookings.ts` (new) — CRUD client.
- `apps/focal/client/src/features/calendar/bookings.ts` + `bookingsFilter.ts` (new) — `coversDay`/`BOOKINGS_RANGE`; persisted show/hide.
- `apps/focal/client/src/features/calendar/BookingDialog.tsx` (new) — CRUD dialog.
- `apps/focal/client/src/features/calendar/{TimeGrid,MonthView,YearView,CalendarPage}.tsx` — overlays + mutations + filter + entry.
- `apps/focal/client/src/i18n/locales/{en,ru}.json` — `focal.calendar.bookings.*`.
- Tests: `bookings.test.ts`, `bookingsFilter.test.ts`, `BookingDialog.test.tsx`, `TimeGrid/CalendarPage.test.tsx`.

# Tests run

```sh
cd superapp-parity/apps/focal/client
pnpm typecheck   # 0 errors
pnpm lint        # 316 files, clean
pnpm test:run    # 102 files, 1214 tests passed
pnpm build       # OK
```

Gate A (design) APPROVED 9.3 (after fixing the backend containment trap + nested-buttons + empty-state) · Gate B APPROVED 9.1 (after metadata-clear + error-surfacing fixes) · Gate C (verify) APPROVED 9.5 (after rollback + date-validation fixes).

# Still needs review

- Deferred follow-ups: a per-project booking filter; booking tags + activity links (their pickers are inline-coupled in `EventDialog`); mini-month booking dots (independent-window fetch); a continuous spanning-bar render.

# PR / release notes (for users — stage 5)

The calendar gets **bookings («пометки»)** back — colored multi-day blocks for vacations, sprints, or any span of days:

- Bookings show as a colored chip on every day they cover (day / 3-day / week), and as markers in the month and year views.
- A **New booking** button — and clicking a booking chip — opens a dialog to create, edit, or delete one (title, dates, color, project / product).
- A **Show / Hide bookings** toggle declutters the calendar, and your choice is remembered.
- Read-only shared calendars show bookings but can't change them.

No secrets, tokens, keys, or PII in this text or the diff.

# Status

OPUS APPROVED (9.5) — release gate cleared.

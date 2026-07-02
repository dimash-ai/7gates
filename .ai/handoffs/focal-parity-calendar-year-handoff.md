# Stage

3-gate flow · **Slice complete** (Gate A design APPROVED 9.2 · Gate B build APPROVED 9.2 · Gate C verify
APPROVED 9.4). Branch `feat/focal-parity-calendar-year` → base `feature/focal-migration`. Frontend-only;
no server/API/schema/migration, no new dependency.

# What changed

A **Год/Year** view for the calendar — the lightweight 12-month navigator:
- `windowFor('year')` widens the calendar's existing single events query to **Jan 1–Dec 31** with a
  **±12-month** step; `'year'` added to `CalendarView`/`VIEW_TABS`; year range label; the `y` shortcut.
- New presentational **`YearView`** — a responsive 12-month grid; each day with events shows a
  **density dot**; clicking a **day** zooms to Day view, clicking a **month** header zooms to Month view.
  It reads the page's year-window events (no own query) and counts by `event.date`.
- Extracted a **`monthCells`** date helper, **adopted by `MiniMonth`** (reuse-first; behavior-identical).
- The page empty-overlay is suppressed for the year navigator (the grid stays usable when a year has no
  events).
- The **bookings** layer of old-focal's booking-centric year view is a deliberate, separate follow-up.

# Files touched
- `apps/focal/client/src/features/calendar/CalendarPage.tsx`
- `apps/focal/client/src/features/calendar/YearView.tsx` (new) + `YearView.test.tsx` (new)
- `apps/focal/client/src/features/calendar/dates.ts` (+ `dates.test.ts`)
- `apps/focal/client/src/features/calendar/MiniMonth.tsx` (+ `MiniMonth.test.tsx`)
- `apps/focal/client/src/features/calendar/CalendarPage.test.tsx`
- `apps/focal/client/src/i18n/locales/{en,ru}.json`

# Tests run
```sh
cd apps/focal/client
pnpm typecheck   # PASS (tsc -b)
pnpm lint        # PASS (biome, 300 files)
pnpm test:run    # PASS (93 files, 1076 tests)
pnpm build       # PASS (only the pre-existing >500 kB chunk-size warning)
```

# Verification output
```sh
 Test Files  93 passed (93)
      Tests  1076 passed (1076)
✓ built
```
Gate-C verify (GPT doer + fresh-context Opus reviewer) independently confirmed: the year window + ±12-month
step, the widened-query calendar scoping, day/month zoom, the `y` shortcut/Today, leap-year month cells, the
no-events navigator, and the `MiniMonth`-after-`monthCells` regression all hold; no production defect.

# Still needs review
- Frontend-only, **read-only navigation** — the year view has no create/write or new authz surface; the
  widened query reuses the same `listEvents` + calendar scoping as every other view.
- The **bookings** layer (booking spans/popovers — old-focal's "Booking Calendar" content) is deferred to
  its own slice; this ships the event-density navigator.

# PR / release notes (for users — stage 5)

Adds a **Year** view to the calendar — a 12-month overview of the whole year.

**What you can now do**
- Switch to **Year** (the new toggle, or press `y`) to see all 12 months at a glance.
- Days that have events show a small dot, so you can spot the busy stretches.
- Click any **day** to jump straight to it; click a **month** name to open that month.
- Prev/next steps a whole year; **Today** returns to the current year.

Frontend-only — reuses the calendar's existing data; no backend, schema, or dependency change. (The
shared-booking layer of the old year view is a separate follow-up.) No secrets, tokens, keys, or PII.

# Status
3-GATE C VERIFY APPROVED (Opus 9.4). Cleared to ship — open the PR.

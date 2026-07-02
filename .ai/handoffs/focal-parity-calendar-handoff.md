# Stage

3-gate · slice 6 of the `focal-parity` epic: **Calendar polish** (scoped subset of calendar-core
parity). Branch `feat/focal-parity-calendar` → base `feature/focal-migration` (one commit `db16a1a`).
Frontend-only; no server/API/schema/migration; no new dependency; no write path.

# What changed

Closes the safe, visible calendar-surface polish gaps (the event editor shipped in slice 5):
- **Scroll-to-now on mount** — day/3-day/week open scrolled near the current time (08:00 fallback when
  today isn't in view); guarded so it never re-scrolls on an events refetch.
- **Mini-month event-count dots** — per-day markers from a dedicated query on the mini-month's
  displayed month (correct even when browsed independently of the main view).
- **Color by project** — event blocks use old-focal's exact precedence
  (`productId ? projectColor||color : color||projectColor`, hashed fallback).
- **Event-block content** — a priority bar + a location line.
- **Loading skeleton + empty state** — a grid skeleton while loading, an empty state when a range has
  no events (mutually exclusive).
- **All-day events row** — a sticky all-day strip (00:00–23:59/24:00 convention) above the time grid;
  all-day events render as chips (opening the existing popover) and are excluded from the timed lanes.

The day-header row + all-day strip + timed lanes share ONE horizontal scroller (single CSS grid,
sticky rows) so columns stay aligned at any width, while scroll-to-now drives the single vertical
container.

# Files touched

All under `apps/focal/client/src/features/calendar/` (TimeGrid.tsx, EventBlock.tsx, MiniMonth.tsx,
CalendarPage.tsx, dates.ts + tests) and `i18n/locales/{en,ru}.json` (new `allDay`, `empty`,
`priority.*` keys).

# Tests run

```sh
cd apps/focal/client
pnpm typecheck   # 0 errors
pnpm lint        # biome: 0 errors (281 files)
pnpm test:run    # 80 files, 948 tests passed
pnpm build       # ✓
```

# Still needs review

- **Frontend-only** — no schema/migration/dep; no write path (so the existing `canEdit` gating is
  unaffected). Client scoping is not security (slice-2 RBAC/RLS is the boundary).
- **DEFERRED to own follow-up slices (flagged):** drag-to-move / drag-resize / ghost drag-to-create
  (needs dnd-kit), timezone threading into the grid, year view + bookings + booking filters, undo,
  task↔event drag, compressed non-work-hours + prime-time (prime-time persistence needs a settings
  field). The full calendar-core was ~15 gaps; this slice is the safe polish subset.
- Residual: sticky-row alignment is jsdom-level tested, not pixel-perfect — worth a quick manual smoke
  at narrow width post-merge.

# PR / release notes (for users)

The calendar now opens scrolled to the current time, shows little **dots on the mini-calendar** for
days with events, colors events by their **project**, shows each event's **location and priority**, has
proper **loading and empty states**, and pins an **all-day row** at the top for all-day events.

(No secrets, tokens, keys, or PII — client components, locale strings, and tests.)

# Status

OPUS VERIFY/RELEASE-GATE APPROVED (9.4). Gate-A design APPROVED 9.3 (2 passes) · Gate-B build APPROVED
9.5 (2 passes — fixed a header/column horizontal-scroll desync regression). Cleared for release; open
the PR.

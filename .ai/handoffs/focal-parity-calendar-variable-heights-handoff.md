# Stage

3-Gate flow — Gate C (verify), release gate. Feature `focal-parity-calendar-variable-heights`.

# What changed

Brings old-focal's **variable-height time grid** to the new focal calendar: working hours render tall and
the off-hours compress, so the day you plan in dominates the viewport (old-focal's `getRowHeight` —
`CalendarViews.tsx`). The new app drew all 24 hours at one `HOUR_HEIGHT = 48`.

- **B1 — geometry module.** A new pure `features/calendar/geometry.ts` owns the coordinate system:
  `rowHeight(hour)` (48 px within 06:00–21:59, 24 px outside), `DAY_HEIGHT`, `timeToY(minutes)` (cumulative
  sum of the variable rows), `yToMinutes(y)` (the inverse walk, clamped to the day bounds), and
  `MIN_DISPLAY_MINUTES`. Fully unit-tested (boundaries, intra-row, round-trip, the 1440→`DAY_HEIGHT` cap).
- **B2 — wire the grid.** `TimeGrid` renders each hour row at `rowHeight(hour)` (off-hours muted) and
  routes every former-linear pixel site through the module: event top, the now-line, the prime-band, the
  drag drop-resolution, and the on-mount auto-scroll. The event **min-height floor** moved to minute-space
  (`max(timeToY(end) − timeToY(start), timeToY(start + MIN_DISPLAY_MINUTES) − timeToY(start))`) and shares
  `MIN_DISPLAY_MINUTES` with `lanes.ts`, so a short off-hour block fills exactly the footprint lane-packing
  reserved for it (no overlap). The all-day strip / bookings are not time-positioned and are untouched.

Because the off-hours compress, a given pixel maps deeper into the day than before — the existing
drag/resize and scroll tests were recomputed for the variable model (e.g. a drop that landed on 11:00 on
the old linear grid now lands at ~14:00), and the 23:59 end-of-day clamp is preserved.

# Files touched

- `apps/focal/client/src/features/calendar/geometry.ts` + `geometry.test.ts` (new) — the model + its tests.
- `apps/focal/client/src/features/calendar/TimeGrid.tsx` — positions/rows/floor/drag/scroll via the module; off-hours muted.
- `apps/focal/client/src/features/calendar/lanes.ts` — import `MIN_DISPLAY_MINUTES` from geometry (one source).
- Tests: `TimeGrid.test.tsx` (variable-row + scroll + prime-band + no-overlap + now-line), `CalendarPage.test.tsx` (drag/resize times recomputed).

# Tests run

```sh
cd superapp-parity/apps/focal/client
pnpm typecheck   # 0 errors
pnpm lint        # 377 files, clean
pnpm test:run    # 132 files, 1610 tests passed
pnpm build       # OK
```

Gate A (design) APPROVED 9.3 (after adding the minute-space height floor + lane consistency, the initial-scroll site, and the bookings-are-all-day correction) · Gate B (build) APPROVED 9.2.

# Still needs review

- Deferred follow-ups: the interactive working-hour zoom (old-focal's `setWorkingHourHeight`); making the
  work-hours window (06–22) a user setting rather than a constant; a cleanup PR removing the now-orphaned
  `dates.ts:offsetToMinutes` (TimeGrid was its only caller; `yToMinutes` supersedes it).
- Next slice (drag-to-create) will consume `yToMinutes` from this module — built on the final geometry.

# PR / release notes (for users — stage 5)

The calendar's day / 3-day / week grid now emphasises your **working hours**: 06:00–22:00 render at full
height while the night hours compress, so the part of the day you actually plan in fills more of the
screen. Events, the now-line, the golden-hours band, drag-and-drop, and the open-to-now scroll all line up
with the new rows; short night-time events keep their own row and never overlap.

No secrets, tokens, keys, or PII in this text or the diff.

# Status

OPUS APPROVED (9.4) — release gate cleared. Based on origin/feature/focal-migration d54f288.

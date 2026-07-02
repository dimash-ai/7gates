# Design: focal-parity-calendar-variable-heights

## Problem & decision

old-focal's time grid does **not** draw all 24 hours at one height. Working hours are tall and the
off-hours are compressed, so the day you actually plan in dominates the viewport
(`apps/old-focal/client/src/components/CalendarViews.tsx:1969` — `getRowHeight(hour) = (WORK_START <= hour
< WORK_END) ? workingHourHeight : NON_WORK_HEIGHT`, with `WORK_START=6`, `WORK_END=22`,
`NON_WORK_HEIGHT=24`). Every pixel↔time computation there walks the **cumulative** sum of per-hour row
heights, not a single constant.

The new app draws a **uniform** grid: one `HOUR_HEIGHT = 48` drives every position
(`apps/focal/client/src/features/calendar/TimeGrid.tsx:20,28` and the linear
`offsetToMinutes(px, HOUR_HEIGHT)` in `dates.ts:94`). So the night hours take the same room as midday.

**Decision: replace the single linear constant with a per-hour height model, behind one small pure
geometry module, and route every position through it.** Concretely:
- A new pure module `features/calendar/geometry.ts` owns the model: `rowHeight(hour)`, `timeToY(minutes)`,
  `yToMinutes(y)`, and `DAY_HEIGHT`. Working hours (`WORK_START=6 ≤ hour < WORK_END=22`) keep today's
  **48** px (so working-hour events are visually unchanged); off-hours compress to **24** px. `timeToY`
  is the cumulative sum of row heights below the hour plus the fractional part within it; `yToMinutes` is
  its inverse walk. This is the one place the linear assumption dies.
- `TimeGrid` renders each hour row at `rowHeight(hour)` (off-hours muted), sizes the column to `DAY_HEIGHT`,
  and positions events / the now-line / the prime-band / the hour grid via `timeToY`; the existing drag
  move/resize maps the pointer back through `yToMinutes` (replacing the linear `offsetToMinutes`), and the
  on-mount auto-scroll targets `timeToY(scrollMinutes)` (`TimeGrid.tsx:153`). The **all-day strip** (all-day
  events **and bookings**) is not time-positioned and is untouched.
- **The event min-height stays consistent with lane packing.** Today the 24 px floor (`HOUR_HEIGHT/2`,
  `TimeGrid.tsx:29`) equals `lanes.ts`'s 30-min reservation (`MIN_DISPLAY_MINUTES`), so short adjacent events
  reserve separate lanes and never collide. A fixed-pixel floor breaks that on a 24 px off-hour row (a 30-min
  event would be floored to 24 px but its neighbour's top is only 12 px away → overlap). So the floor becomes
  **minute-space**: `height = max(timeToY(end) − timeToY(start), timeToY(start + MIN_DISPLAY_MINUTES) −
  timeToY(start))`. `MIN_DISPLAY_MINUTES` moves into `geometry.ts` as the single constant both `lanes.ts` and
  the floor import, so a floored block always occupies exactly the reserved lane footprint at its row size.

**Why a module (and why it matters beyond this feature):** the linear `HOUR_HEIGHT` is the exact
coordinate system the next two parity features stand on — **drag-to-create** computes a start/end from a
pointer drag (it will call `yToMinutes`), and **undo** is orthogonal to geometry. Extracting `timeToY` /
`yToMinutes` now means drag-to-create is built **once** on the final coordinate system instead of being
written against the linear model and reworked when this lands. A pure module is also unit-testable in
isolation — essential for cumulative geometry, where an off-by-one row silently mis-places every event.

**Scope: the static work/off-hours split only.** old-focal also has an interactive
`setWorkingHourHeight` zoom (`CalendarViews.tsx:1950`) — **deferred**; the parity core is the variable
grid, not the zoom gesture. `WORK_START`/`WORK_END` stay constants (6/22, as old-focal hardcodes them),
not a user setting.

**Alternatives rejected:**
- **Keep the linear grid, just shrink HOUR_HEIGHT** — rejected; it shrinks working hours too and doesn't
  achieve the "emphasise the working day" parity goal.
- **Per-hour heights inline in `TimeGrid`** (mirror old-focal's in-component math) — rejected; it would
  duplicate the cumulative walk at every call site and leave the risky math untested. One pure module is
  fewer lines and testable.
- **Make working hours taller (60, like old-focal) instead of keeping 48** — rejected for the first cut;
  keeping working hours at today's 48 makes the change surgical (working-hour event density is identical,
  only the off-hours compress), and avoids re-tuning every working-hour visual.

## Assumptions & scope

- **(confirmed — code)** `TimeGrid.tsx` is the only component doing pixel math, at **seven** sites: event
  `top` + the floored `height=max((…)*HOUR_HEIGHT, HOUR_HEIGHT/2)` (`:28-29`), the now-line (`:86`), the
  prime-band (`:93-94`), the per-hour cells (`:269,302`), the drag drop-resolution
  `offsetToMinutes(clientY-…, HOUR_HEIGHT)` (`:129`), and the **on-mount auto-scroll**
  `(scrollMinutes/60)*HOUR_HEIGHT` (`:153`). `lanes.ts` is **minute-space** (it packs against
  `MIN_DISPLAY_MINUTES=30`, not pixels), so its only change is to import that constant from `geometry.ts`
  instead of defining it locally — keeping the lane footprint and the render floor a single source.
- **(confirmed — code)** helpers live in `dates.ts`: `minutesOf`, `snapMinutes` (15-min), `clampMinutes`,
  `END_OF_DAY_MINUTES=1440`, `DEFAULT_DURATION_MINUTES`, and the linear `offsetToMinutes` (to be retired
  from the grid). Backend time validation accepts `00:00–23:59` only; `minutesToTime` already caps 1440→23:59.
- **(confirm at build)** the exact `TimeGrid` test expectations to update (they encode `HOUR_HEIGHT` math);
  whether the prime-band/bookings overlays need the same `timeToY` (yes — anything positioned by time);
  the off-hours visual treatment (muted background + drop the minute tick, per old-focal).
- **Out of scope:** the interactive working-hour zoom; making work hours a user setting; horizontal lane
  packing (unchanged); changing snap granularity (stays 15-min).
- **Open questions:** None blocking. (Working=48 / off=24 is a judgement call but reversible — one constant.)

## Success criteria

- [ ] Working hours (06:00–21:59) render at the current density (48 px/hour); off-hours render compressed
      (24 px/hour); the day column is `DAY_HEIGHT = 16·48 + 8·24` tall and off-hours are visually muted.
- [ ] Every time-positioned element — events, the now-line, the prime-time band, the hour grid — sits at
      `timeToY(minutes)`, exactly aligned to its hour row at every boundary (00:00, 06:00, 22:00, 23:59).
      (The all-day strip / bookings are not time-positioned and are unchanged.)
- [ ] Short adjacent off-hour events do **not** collide: the rendered floor equals `MIN_DISPLAY_MINUTES`
      worth of grid at the event's own row size, matching `lanes.ts`'s lane reservation.
- [ ] On mount the grid auto-scrolls to the same target time as today, computed via `timeToY`.
- [ ] Drag-move and drag-resize still land on the correct 15-min slot, mapping the pointer through
      `yToMinutes` (incl. dragging across the work/off-hours boundary), and never emit a time outside
      `00:00–23:59`.
- [ ] Unit tests assert `timeToY` exact pixels at 00:00/06:00/22:00/23:59, a representative intra-row
      inverse, the `yToMinutes∘timeToY` round-trip within one snap step across the day, and the `≥1440 →
      DAY_HEIGHT` / `y≥DAY_HEIGHT → END_OF_DAY_MINUTES` caps.
- [ ] No event create/edit/move/resize behaviour changes other than the vertical mapping; `pnpm lint &&
      typecheck && test:run && build` stays green (existing grid + scroll tests updated to the new geometry).

## Build approach (slices)

| # | slice | files | main failure mode | what its test proves |
|---|-------|-------|-------------------|----------------------|
| B1 | geometry module | `features/calendar/geometry.ts` (new): `WORK_START/END`, `WORKING_HOUR_HEIGHT=48`, `NON_WORK_HEIGHT=24`, `rowHeight`, `DAY_HEIGHT`, `timeToY`, `yToMinutes` | cumulative off-by-one row; fraction-within-hour wrong; 1440 not capped | `timeToY`/`yToMinutes` round-trip within a snap step; exact at 00:00/06:00/22:00/23:59; off-hour minutes map inside the compressed row; `y > DAY_HEIGHT → END_OF_DAY_MINUTES` |
| B2 | wire TimeGrid to it | `features/calendar/TimeGrid.tsx` (event top + minute-space floor, now-line, prime-band, drag drop, on-mount scroll via the module; rows via `rowHeight`; column `DAY_HEIGHT`; off-hours muted), `geometry.ts` (export `MIN_DISPLAY_MINUTES`), `lanes.ts` (import it), `TimeGrid.test.tsx` (geometry + scroll expectations → variable model) | an overlay still on `HOUR_HEIGHT` drifts from the rows; drag snaps to the wrong slot near the boundary; a floored off-hour block overlaps its neighbour; the mount scroll lands on the wrong time | events/now-line/prime-band align to rows; a drag across the 06:00 boundary lands on the right 15-min slot; two back-to-back 30-min off-hour events don't overlap; the on-mount scroll targets `timeToY`; off-hours rows muted |

Each slice leaves `pnpm lint && typecheck && test:run && build` green and is committed on the branch.

## Architecture & contracts

```
features/calendar/geometry.ts  (new, pure — the single coordinate system)
  WORK_START=6 WORK_END=22 WORKING_HOUR_HEIGHT=48 NON_WORK_HEIGHT=24 MIN_DISPLAY_MINUTES=30
  rowHeight(hour)            → 48 within [6,22), else 24
  DAY_HEIGHT                 → Σ rowHeight(0..23)  (= 16·48 + 8·24 = 960)
  timeToY(minutes)           → Σ rowHeight(h<hour) + (minInHour/60)·rowHeight(hour); ≥1440 → DAY_HEIGHT
  yToMinutes(y)              → inverse walk; y<0 → 0; y≥DAY_HEIGHT → END_OF_DAY_MINUTES (caller snaps)

TimeGrid.tsx  (HOUR_HEIGHT retired from positioning)
  rows                       → height rowHeight(hour); column = DAY_HEIGHT; off-hours muted
  event top                  → timeToY(start)
  event height               → max(timeToY(end)-timeToY(start), timeToY(start+MIN_DISPLAY_MINUTES)-timeToY(start))
  nowTop / primeBand         → timeToY(...)
  resolveDrop                → yToMinutes(clientY - columnTop - grab) → snapMinutes
  on-mount scroll            → timeToY(scrollMinutes) - clientHeight/3
lanes.ts                     → import MIN_DISPLAY_MINUTES from geometry.ts (was a local const)
```

| entity / interface | change | notes |
|--------------------|--------|-------|
| `geometry.ts` (new, pure) | `rowHeight`, `timeToY`, `yToMinutes`, `DAY_HEIGHT`, `MIN_DISPLAY_MINUTES` + constants | the only place the variable model lives; fully unit-tested |
| `TimeGrid` | positions + rows + the minute-space height floor + drop-resolution + on-mount scroll route through the module; off-hours muted | no prop/contract change; `HOUR_HEIGHT` retired from this file |
| `TimeGrid.test.tsx` | pixel + scroll expectations recomputed for the variable model; a no-overlap test for short off-hour events | the change alters geometry, so its geometry tests change with it |
| `dates.ts` `offsetToMinutes` | retired from the grid (kept only if another caller remains) | `yToMinutes` supersedes it for variable rows |
| `lanes.ts` | import `MIN_DISPLAY_MINUTES` from `geometry.ts` (1 line; was local) | keeps lane reservation + render floor one source; packing logic unchanged |
| data model / API | **none** | pure frontend rendering |

## Flow (happy + unhappy)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| render a working-hour event | query resolves | `TimeGrid` → `timeToY` | sits in a 48 px row, same density as today |
| render an off-hours event | query resolves | `TimeGrid` → `timeToY` | sits in a compressed 24 px row, muted band |
| drag within working hours | pointer move | `yToMinutes` → `snapMinutes` | lands on the right 15-min slot (as today) |
| drag across the 06:00 boundary | pointer crosses rows | `yToMinutes` walk | maps to the correct minute on the far side of the size change |
| drag past the bottom of the day | pointer below `DAY_HEIGHT` | `yToMinutes` → `END_OF_DAY_MINUTES` → cap | clamps to `23:59`, never an invalid time |
| short off-hour events back-to-back | render | `timeToY` floor = `MIN_DISPLAY_MINUTES` | each occupies its reserved footprint; no overlap |
| open the grid | mount | auto-scroll → `timeToY(scrollMinutes)` | same target time as today, on the variable grid |

## Test strategy, security & rollback

- **Test strategy.** Unit (`geometry.test.ts`): `rowHeight` at the boundaries (5→24, 6→48, 21→48, 22→24);
  `timeToY` **exact** at 00:00(0)/06:00(144)/22:00(912)/23:59(≈960) and a representative intra-row point;
  `yToMinutes` exact for an intra-row Y; `yToMinutes∘timeToY` round-trips within one snap step across all
  24 h; `y<0`→0 and `y≥DAY_HEIGHT`→`END_OF_DAY_MINUTES`. Component (`TimeGrid.test.tsx`): an
  event / now-line / prime-band aligns to its row; **two back-to-back 30-min off-hour events render without
  overlap** (floor = `MIN_DISPLAY_MINUTES`); a drag-move and a drag-resize across the work/off boundary land
  on the expected slot; the on-mount auto-scroll uses `timeToY`; off-hours rows render muted. "Verified" =
  those + `pnpm lint && typecheck && test:run && build` green.
- **Security.** Pure client-side rendering geometry; no new I/O, no auth surface, no secrets/PII. The
  `00:00–23:59` cap is preserved through `yToMinutes` → `snapMinutes`/`minutesToTime`.
- **Rollback.** Pure frontend, no migration — revert the PR; the geometry module is self-contained.

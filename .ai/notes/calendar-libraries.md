# Findings: calendar-libraries

> Output of the **explore gate** (`/gate-explore calendar-libraries`). Two independent takes — Opus
> (web-verified) and GPT Codex (offline, code-grounded) — synthesized. Not scored. Date: 2026-06-29.

## Questions

1. Which popular high-star React calendar/scheduler libraries could we reuse?
2. Do any fit Focal's specific requirements (variable per-hour heights, prime-time band, task-panel
   drag-to-schedule, booking year view, per-event tz, RBAC scoping) + the React 19 / Tailwind 4 stack
   + license?
3. Build-vs-adopt: given 100% parity with a bespoke old-focal, and new-focal already substantially
   built — adopt a framework or keep extending the hand-rolled calendar?
4. Any narrower single-purpose libraries (drag-drop, recurrence, date/tz) worth reusing without a
   full rewrite?

## Consensus

> Both models agree.

- **No mainstream calendar library fits the *parity* spec; the decisive blocker is variable per-hour
  row heights.** FullCalendar/react-big-calendar/schedule-x/Toast UI all use a **uniform slot-height**
  model. — confidence: High. Evidence: FullCalendar issues #265/#5603/#6581 + timeGrid docs
  (uniform rows expand equally); old variable geometry `apps/old-focal/.../CalendarViews.tsx:1982`
  (`getRowHeight`) vs new linear `apps/focal/client/src/features/calendar/TimeGrid.tsx:20`
  (`HOUR_HEIGHT=48`).
- **Recommendation: do NOT adopt a full framework for the parity goal — keep extending the hand-rolled
  calendar.** — confidence: High. Evidence: old target is bespoke ~4,930 LOC (`CalendarViews.tsx`);
  new is already ~3,973 calendar LOC + 13 test files, with day/3-day/week/month/year, lane packing,
  drag/resize, prime-time, recurring-scope, bookings, RBAC gating, task↔event convert already working.
- **A framework would replace only the visible grid; the hard parts stay custom** (variable heights,
  booking-year view, task drag, per-event tz display, recurrence-scope, RBAC/filter scoping). —
  confidence: High. Evidence: `YearView.tsx:27` (density dots) vs old booking calendar
  `CalendarViews.tsx:4647`; RBAC via `canEdit` `CalendarPage.tsx:251`.
- **Right reuse is at the primitive grain: `@dnd-kit/core` for task↔event drag + drag-create.** Old
  focal already used dnd-kit (`apps/old-focal/package.json:19`); plug into `TaskPanel` rows, `TimeGrid`
  day columns, and the existing drop geometry `TimeGrid.tsx:121`. — confidence: High. (= slice A4.)
- **Keep recurrence server-owned; no client rrule needed.** — confidence: High. Evidence:
  `server/app/domain/recurrence.py`; client only routes scope (`api/events.ts:9`,
  `CalendarPage.tsx:493`).
- **License/popularity (Opus web-verified — resolves GPT's offline open points):** FullCalendar ~19k★
  MIT core + **Premium $480/dev/yr** (timeline/resource views); react-big-calendar ~8.5k★ MIT free but
  **no built-in editor/DnD**; **schedule-x core MIT but drag/resize/drag-create/modal are PREMIUM**
  (paid per project); Toast UI ~12k★ MIT but React wrapper stale (React-19 doubtful); rrule ~3.7k★
  BSD-3; dnd-kit MIT, actively maintained (releases Apr 2026). — confidence: High (vendor + GH pages).

## Divergence

- **Timezone primitive (the CAL-7 gap)**
  - Opus: consider a small tz lib (date-fns-tz / Luxon / Temporal polyfill) behind the tz provider.
  - GPT (read the code): keep the existing **zero-dependency Intl-based** `lib/timezone.ts`; CAL-7 is a
    **wiring gap**, not a missing capability — `EventBlock.tsx:405` renders raw `startTime/endTime`
    instead of calling the helper old-focal used (`EventCard.tsx:92`).
  - **Decision needed:** default to **no new dependency** (GPT) — just wire `EventBlock` through the
    existing helper. Matters because it reclassifies CAL-7 from "needs a lib" to a cheap wiring fix.

## Open

- **`@dnd-kit` on React 19** — actively maintained (releases Apr 2026) and old-focal ran it on React
  18, but not yet proven on 19.2 here. To close: `pnpm add @dnd-kit/core` + typecheck/build in slice A4.
- **Is variable-height (CAL-1) truly required for "100% parity," or the one place to deviate** to a
  uniform grid? If relaxed, build cost drops sharply and a library even becomes thinkable. To close:
  product/owner decision (it is old-focal's signature look).

## Next

- Settles the calendar roadmap: **no framework adoption**; `@dnd-kit/core` is the single new dependency
  (slice A4 drag-convert, also supports A3 drag-create). **CAL-7 reclassified as a wiring gap** (cheaper
  than the ledger implies). Can seed `/gate-design` for the dnd-kit-based interaction slices.

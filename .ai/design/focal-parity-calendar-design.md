# Design — focal-parity slice 6: Calendar polish

3-gate flow · slice 6 of the `focal-parity` epic, **scoped to the safe "Calendar polish" subset**.
Branch `feat/focal-parity-calendar` → base `feature/focal-migration`. **Frontend-only** — every item
reads data the API already returns; no server/API/schema/migration, no new deps.

## Scope decision (read this first)

A full old-vs-new audit of the calendar surface found ~15 gaps spanning S→L. The large/risky ones —
**drag-to-move / drag-resize / ghost drag-to-create (needs dnd-kit)**, **undo**, **task↔event drag**,
**year view + bookings + booking filters**, **compressed non-work-hours + prime-time band**, and
**timezone threading into the grid** — are each their own slice and are **explicitly DEFERRED** (see
Out of scope). This slice takes only the safe, isolated, no-new-dep polish items that close the most
visible "feels unfinished" deltas without touching the high-risk interaction layer.

The event create/edit dialog already shipped (slice 5) and is **not** in scope. Shared-calendar
`canEdit` gating is already at parity in `CalendarPage` and is not re-touched (but every item below
that is interactive stays read-only-safe).

## In-scope items (6)

1. **Scroll-to-now on mount** — the time grid renders from 00:00 with no initial scroll
   (`TimeGrid.tsx`); old-focal scrolls to the work-start hour on mount (`CalendarViews.tsx:1959-1967`).
   Add an initial scroll so day/3-day/week open near the current time (fall back to a sensible
   work-start hour when "now" is outside the day being viewed).
2. **Mini-month event-count dots** — `MiniMonth.tsx` shows no per-day markers (its own comment defers
   them); old-focal shows per-day event-count dots built from an expanded event set
   (`Calendar.tsx:543-569`), NOT the main viewport. Because `MiniMonth` browses its displayed month
   **independently** of the main view (`MiniMonth.tsx:20-24,64-75`) while `CalendarPage` only fetches
   the active main-view window (`CalendarPage.tsx:178-187`), the dots must come from a **dedicated
   query scoped to the mini-month's currently-displayed month** — not from the main-view events.
3. **Color by project** — `EventBlock.tsx:74` colors only from `event.color` + a hashed fallback,
   ignoring `projectColor` which `EnrichedEventRead` already returns. **Match old-focal's exact
   precedence** (`CalendarViews.tsx:888-892`): for **product** events (`event.productId` set) →
   `projectColor || color || default`; otherwise → `color || projectColor || default`. (Keep the
   existing hashed fallback as the `default`.)
4. **Event-block content parity** — old-focal's block shows a **location** line and a **priority** bar
   (`CalendarViews.tsx:935-985`); the new `EventBlock` shows title/time/repeat/orphan only. Add the
   location line (when present) and the priority indicator, matching old-focal's treatment.
5. **Loading skeleton + empty state** — `CalendarPage.tsx:468-470` shows only a "Loading…" text line
   and no empty state; old-focal shows a skeleton (`Calendar.tsx:3305-3317`). Add a grid skeleton
   while loading and a simple empty state when a day/range has no events.
6. **All-day events row** — old-focal detects all-day by the `startTime==="00:00" &&
   endTime∈{"23:59","24:00"}` convention (`CalendarViews.tsx:588`) and renders a per-day all-day strip
   above the time grid in day/3-day/week (`:2367-2402, :3322`). The new app has no all-day detection
   or row. Add the same pure-frontend detection + an all-day strip; all-day events render as chips in
   the strip (opening the existing popover on click), excluded from the timed-lane layout.

## Assumptions

- All six items read fields the API already returns. **The generated client contract is camelCase**
  (`api/openapi.d.ts`): `EnrichedEventRead` carries `projectColor: string | null`, `sphere`,
  `productId`, `startTime`, `endTime: string | null`, `location`, and `priorityLevel`
  (`"high"|"medium"|"low"`). Use those exact names. No backend change. If any field turns out missing,
  **stop and flag** — do not stub.
- All-day is a pure frontend convention (`startTime==="00:00" && endTime∈{"23:59","24:00"}`), exactly
  as old-focal — no `all_day` API field is needed or added. Note `endTime` can be `null`; treat a
  `null` endTime as NOT all-day (or per old-focal's actual handling).
- Interactions stay read-only-safe: clicking an all-day chip opens the existing (read-only-aware)
  popover; nothing here adds a write path, so `canEdit` gating is unaffected.
- Reuse-first: skeleton uses the existing `components/ui/skeleton` (or the app's established skeleton
  pattern); the priority/location rendering mirrors the existing `EventBlock` style; the mini-month
  dot reuses `MiniMonth`'s existing day-cell render.

## Approach

All changes under `apps/focal/client/src/features/calendar/*` (+ tiny i18n if an empty-state/all-day
label is needed). Each item is independent and independently testable:

- **scroll-to-now**: a layout effect that, on mount / when the view's date includes today, sets the
  vertical scroll container's `scrollTop` to `now`'s offset (using the existing `HOUR_HEIGHT`), else a
  work-start offset. **Target the correct container:** vertical scrolling is owned by the surrounding
  calendar card (`CalendarPage.tsx:472`), NOT `TimeGrid`'s `overflow-x-auto` wrapper — so wire an
  explicit `ref` to that vertical-scroll element (lift the effect to `CalendarPage` with a ref on the
  card, or give `TimeGrid` its own vertical-scroll wrapper+ref). Guard against scroll-fighting (run on
  date/view change, not on every events refetch).
- **mini-month dots** (`MiniMonth.tsx` + a small query): add a lightweight events query keyed on the
  mini-month's **displayed month** range (the existing list-events endpoint, `withCal` +
  `currentCalendarId`-scoped, `enabled` whenever the mini-month is shown), refetched as the user
  navigates the mini-month; reduce its result to a `Map<ymd, count>` and render a dot (and/or small
  count) per day cell with events. This keeps markers correct when the mini-month is browsed to a
  different month than the main view (one small fetch per mini-month month change — faithful to
  old-focal's expanded-set approach).
- **color** (`EventBlock.tsx`): change the color resolution to old-focal's precedence —
  `event.productId ? (projectColor || color || fallback) : (color || projectColor || fallback)`; keep
  the existing contrast/text logic and the hashed value as `fallback`.
- **block content** (`EventBlock.tsx`): add the location line (truncated, when non-empty) and the
  priority indicator, matching old-focal's visual treatment and the existing block layout.
- **loading/empty** (`CalendarPage.tsx` + maybe a small `CalendarSkeleton`): render a skeleton grid
  while the events query is loading; render an empty-state message when the visible range/day has no
  events. New i18n key for the empty-state text (both locales).
- **all-day row** (`TimeGrid.tsx`/day-week views + a small `isAllDay(event)` helper in `dates.ts`):
  add the pure detection helper; partition events into all-day vs timed; render an all-day strip
  (per-day column in 3-day/week, single row in day) above the grid; timed events keep the existing
  lane layout. New i18n key for the "all-day" label if old-focal shows one.

## Out of scope / deferred (flagged for the user — each its own follow-up slice)

- **Drag interactions** (drag-to-move, drag-resize, ghost drag-to-create) — needs dnd-kit, 15-min
  snap, optimistic update, cross-column day reassignment, and routing recurring move/resize through
  the existing `RecurringScopeDialog`; all `canEdit`-gated. Backend already supports it
  (`EventUpdate` PATCH + recurrence scope). **Highest-risk surface — its own isolated slice.**
- **Timezone threading into the calendar surface** — the now-line position + block time display in the
  display timezone (and tz conversions once drag lands). The timezone slice shipped but isn't threaded
  into the grid; doing it touches `dates.ts`/now-line and risks subtle time-display regressions →
  deferred to its own slice.
- **Year view + bookings + booking filters** — one cohesive bookings slice (year view is meaningless
  without bookings; the API already returns `bookings` but the calendar never fetches them).
- **Undo** (event create/delete/update stack) and **task↔event drag** (cross-feature) — own slices.
- **Compressed non-work-hours + prime-time band** — frontend layout, but prime-time *persistence*
  needs a user-settings field (a separate backend handoff).

## Acceptance criteria

1. **Scroll-to-now:** opening day/3-day/week with today in range scrolls the grid near the current
   time on mount; does not fight the user's subsequent scrolling (no re-scroll on every events
   refetch). Covered by a test asserting initial `scrollTop` is set.
2. **Mini-month dots:** days with events in the mini-month's **displayed month** show a marker; days
   without don't — correct even when the mini-month is browsed to a different month than the main view
   (markers come from a query scoped to that month, not the main viewport). Covered by a test with
   mocked events.
3. **Color:** a product event (`productId` set) with a `projectColor` renders in that color; a
   non-product event prefers `color` then `projectColor`; both fall back to the hashed default when
   absent — matching old-focal's precedence. Covered by tests for both branches.
4. **Block content:** an event with a location shows it; the priority indicator renders per priority.
   Covered by a test.
5. **Loading/empty:** a skeleton shows while loading; an empty state shows when there are no events;
   neither appears when events are present. Covered by a test.
6. **All-day row:** an event matching the all-day convention renders in the all-day strip (not the
   timed lanes) and opens the popover on click; timed events stay in the lanes. Covered by a test for
   `isAllDay` + the partition.
7. **i18n parity:** any new EN key has an RU counterpart; no hardcoded user-facing strings.
8. **Green bar:** `pnpm typecheck`, `pnpm lint`, `pnpm test:run` (the new tests), `pnpm build` pass;
   diff confined to `features/calendar/*` + any new i18n keys. No new dependency added.

## Risk

Low–Medium. All frontend, no new deps, no write paths, no schema. The only layout-touching item is the
all-day row (bounded: a pure detection helper + a strip above the existing grid; timed-lane layout
unchanged); scroll-to-now is guarded against scroll-fighting. The riskiest calendar work (drag,
timezone threading) is explicitly deferred. Rollback = revert the client files.

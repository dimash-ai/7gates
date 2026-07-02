# Problem

Slice 10 of the `focal-redesign-pages` epic: bring the **События (Events)** page to **exact parity
with old-focal's `pages/Events.tsx`**. Events is the **filterable, searchable list view of calendar
events** — mission/provision + sphere + project/product/activity + tag + priority + orphan + date-
preset filters, search, localStorage-persisted, with create/edit/delete (recurring-scope aware). It
is the list counterpart to the calendar grid.

Unlike tags/heatmap/habits/tasks (re-skins of pages that already existed), **this page does not exist
in the new app** — there is no `features/events/`, no `/events` route, no nav item. So the slice both
**builds a new page** and **wires it into the shell**. The de-risking fact: the **data and the heavy
interactive pieces already exist** in the new app — `api/events.ts` (list/create/update/delete +
`recurrenceScope`), `features/calendar/EventPopover` (create/edit), and
`features/calendar/RecurringScopeDialog` (scope prompt). So this is **assemble old-focal's Events
list from existing event machinery + a new filter bar**, not a from-scratch feature, and **not** an
API/logic build. Two small primitives the filter bar needs are **absent from the base** and must be
built: a generic `ui/multi-select` and a date-preset→range util.

# Assumptions

- **[confirmed — epic decision]** Binding contract = exact `apps/old-focal/pages/Events.tsx`; re-skin/
  assemble over existing APIs; reproduce on the new stack (Tailwind 4 / React 19 / shadcn, no
  Tailwind-3 config/PostCSS); copy from old-focal `locales/{ru,en}.json`. See
  [`focal-redesign-pages` epic think](./focal-redesign-pages.md).
- **[confirmed — read]** old-focal `Events.tsx` (1337 lines) is a **list view**: `EventFilters` =
  `{orphanFilter: all|orphans|classified|completed|active, priorityFilter, projectType: all|mission|
  provision, sphereIds[], projectIds[], productIds[], activityIds[], tagIds[], searchQuery,
  datePreset (default thisMonth), dateFrom, dateTo}`, persisted to `localStorage["focal-events-
  filters"]` with single→multi migration; composes `EventDialog`, `EventCard`, `MultiSelect`,
  `RecurringEventDialogs`, date presets (`getDateRangeFromPreset`).
- **[confirmed — fs]** New app base (off shell `afaaeba`) already has the reusable machinery:
  `api/events.ts` (`listEvents(startDate,endDate)`, `createEvent`, `updateEvent`, `deleteEvent` with
  `RecurrenceTarget {scope, occurrenceDate}`); `features/calendar/EventPopover.tsx`;
  `features/calendar/RecurringScopeDialog.tsx`. → reuse, don't rebuild.
- **[confirmed — fs]** **Missing from the base** and therefore in-slice to build: `components/ui/
  multi-select.tsx` (the heatmap slice built one but is unmerged, so it is **not** in this base — do
  not assume it), and a date-preset→range util (no `lib/datePreset*`/`getDateRangeFromPreset` in the
  new app). old-focal's `MultiSelect` used `cmdk` (absent here); build from existing
  Popover/Badge/Input primitives with **no nested `<button>`** (the heatmap slice's documented
  pitfall).
- **[confirmed — fs/tags slice]** The new app has **no `CalendarFilterContext`** (the tags slice
  already deferred its `isViewingOtherCalendar`). → the "viewing another shared calendar" filter is
  **deferred + flagged**, not faked; the page shows the signed-in user's own events.
- **[confirmed — calendar epic think]** `EnrichedEventRead` carries the fields every filter needs —
  `status`, `completed`, `color`, `projectId/productId/activityId`, `tags`, `priority*`, `recurrence*`,
  and orphan enrichment (`isOrphan`/`orphanReason`) — so **all** old-focal filters are **backable
  client-side** over the fetched window; no API change.
- **[unverified — settle at design gate]** exact event-row layout/grouping + sort order (mirror
  old-focal `EventCard` + its list grouping; check whether `taskSort`-style ordering applies); which
  read APIs feed the sphere/project/product/activity/tag filter option lists (the new `api/*`
  wrappers exist for projects/activities/tags/spheres — confirm names); whether the new app already
  ports `shared/datePresetRange` elsewhere (grep says no — assume build it here).

# Options considered

The source-of-truth + re-skin posture are fixed by the epic. Real forks: **(1) data-fetch shape** for
the list, and **(2) the filter-primitive scope**.

| # | Fork | Option | Pros | Cons |
|---|------|--------|------|------|
| **A (chosen)** | fetch | **Window-fetch + client-side filter** — `listEvents(rangeStart, rangeEnd)` for the active date-preset window, then filter/search/sort in memory (exactly как old-focal). | Matches old-focal 1:1; one existing endpoint; instant filter response; no API work. | Large windows fetch more rows (acceptable; old-focal does the same). |
| B | fetch | Add server-side filter params to `/api/events`. | Less client work for huge datasets. | **Server/API change — out of scope**; over-engineered for the data size; diverges from old-focal. Rejected. |
| **C (chosen)** | primitives | **Build the minimal `ui/multi-select` + date-preset util in this slice** (Popover/Badge/Input, no nested buttons; port `datePresetRange` behavior). | The filters are the page's essence under "exact old-focal"; primitives are small + reusable by later slices. | Slightly enlarges the slice beyond a pure page. |
| D | primitives | Ship a reduced filter set (search + date only) now, multi-selects later. | Smaller diff. | Fails "exact parity"; the multi-select filters are core to old-focal Events. Rejected. |

# Recommendation

**A + C.** Reproduce old-focal's Events exactly: **window-fetch the events for the active date-preset
range via the existing `listEvents`, filter/search/sort client-side**, and **build the two small
primitives** the filter bar needs (`ui/multi-select` from Popover/Badge/Input — no nested `<button>`;
a `datePresetRange` util porting old-focal's preset→range behavior). **Reuse** `EventPopover` (create/
edit) and `RecurringScopeDialog` (scope) and `api/events.ts` untouched — true re-skin/assemble over
existing wiring. Wire the new page into the shell: `/events` route + **События** nav item (Исполнение
group), following the tags/tasks `PageHeader`/`PageToolbar`/`SidebarTrigger` pattern.

**Internal build order** (one slice, cohesive — primitives first so the filter bar can consume them):
1. `ui/multi-select` primitive (+ test).
2. `datePreset` → range util (+ test) porting old-focal behavior (default `thisMonth`).
3. `EventsPage` shell (header/toolbar, route, nav item) + the events list/rows over `listEvents`.
4. The filter bar + `localStorage` persistence + client-side filter/search/sort.
5. Wire create/edit/delete via the existing `EventPopover` + `RecurringScopeDialog`.

**Deferred, flagged (not faked):** the `CalendarFilterContext` "viewing another shared calendar"
filter (no such context in the new app yet) — same deferral the tags slice made.

# Out of scope

- Any server/API/schema/contract change (fork B rejected); a needed backend field is a separate handoff.
- The calendar grid / its popover restyle (reuse `EventPopover`/`RecurringScopeDialog` as-is).
- `CalendarFilterContext` cross-calendar filtering (deferred + flagged).
- Re-deriving slice-0 foundation or the Allosta mockup.

# Open questions

- **Event-row + grouping/sort fidelity** — match old-focal `EventCard` layout and list grouping/sort
  exactly; confirm at the design gate (read the full `Events.tsx` body + `EventCard`).
- **Filter-option sources** — confirm the new `api/*` wrappers for spheres/projects/products/
  activities/tags that feed the multi-selects (names + shapes); settle at design.
- **`datePresetRange` parity** — port old-focal's exact preset set + boundaries (timezone-aware via
  the app's existing tz handling); verify no preset util already exists before building.
- **Nav placement** — old-focal lists Задачи and События separately in Исполнение; confirm the new
  sidebar adds События there (vs a combined "Задачи и события" label) at the design gate.

# Success criteria

- [ ] `/events` renders `EventsPage`; **События** in the sidebar (Исполнение), active on `/events`;
      light + dark match old-focal.
- [ ] List + filter bar match `old-focal/pages/Events.tsx` (search, date-preset incl. custom, orphan/
      priority/projectType, multi-select sphere/project/product/activity/tags); filters persist via
      `localStorage` (default `thisMonth`).
- [ ] Create/edit/delete work over the **existing** `api/events.ts` incl. recurring-scope; no calendar
      test regressions; no server/API change.
- [ ] Surgical diff tracing to the task; i18next `ru`+`en` (old-focal copy); deferred cross-calendar
      filter flagged, not faked.
- [ ] Green: `pnpm lint && typecheck && test:run && build` with new tests (filtering, persistence,
      list render, multi-select, preset→range).

# Goal

Add the **События (Events)** page to the new Focal app at **exact visual + interaction parity with
old-focal's `pages/Events.tsx`** — a filterable, searchable **list of calendar events** (distinct
from the calendar grid), with create/edit/delete incl. recurring-scope. This is **slice 10** of the
`focal-redesign-pages` epic (binding source = exact `apps/old-focal`; re-skin/assemble over the new
app's existing APIs; reproduce on the new stack — Tailwind 4 / React 19 / shadcn, no Tailwind-3
config). Unlike most slices this page **does not exist yet** in the new app, so it also adds the
`/events` route + the **События** nav item.

> **Binding visual + behavior contract** = `apps/old-focal/client/src/pages/Events.tsx` (1337 lines)
> + the components it composes (`EventDialog`, `EventCard`, `RecurringEventDialogs`, `MultiSelect`)
> and `apps/old-focal/client/src/locales/{ru,en}.json` for copy. The live `focal.allosta.com`
> "События" screen is this page.
> **Data/behavior base** = the new app's existing `api/events.ts` (`listEvents(start,end)`,
> create/update/delete with `recurrenceScope` single/following/all) over `EnrichedEventRead`
> (carries `status`, `completed`, `color`, `projectId/productId/activityId`, `tags`, `priority*`,
> `recurrence*`, orphan enrichment) — **no server/API change**.

# Scope

- New `features/events/` page (`EventsPage`) + register `/events` in `App.tsx` + add the **События**
  item to `AppSidebar.tsx` (Исполнение group), mirroring the tags/tasks slice shell pattern
  (`PageHeader`/`PageToolbar` + `SidebarTrigger`, AI button preserved).
- **Events list** matching old-focal: event rows/cards with time, title, recurrence/orphan/priority
  badges, project/activity color, completed state; sorted + grouped as old-focal does.
- **Filter bar** matching old-focal `EventFilters`: search; date-preset (all/today/…/thisMonth
  default/custom from/to); orphan filter (all/orphans/classified/completed/active); priority;
  projectType (mission/provision); multi-select sphere / project / product / activity / tags.
  **Filters persist to `localStorage`** (key `focal-events-filters`) with the same defaults.
- **Reuse** the new app's existing pieces — do **not** rebuild them: `features/calendar/EventPopover`
  (create/edit), `features/calendar/RecurringScopeDialog` (edit/delete scope), `api/events.ts` +
  its React Query keys/mutations, and the project/activity/tag/sphere read APIs for filter options.
- **Build the two missing filter primitives** this page needs (absent from the base): a generic
  `ui/multi-select`, and a date-preset → range util (port old-focal's `shared/datePresetRange`
  behavior). Client-side filtering over the fetched events window.
- i18next `ru` + `en` (reuse old-focal copy); light + dark.

# Out of scope

- Any **server / API / schema / contract / migration** change. Frontend-only over existing endpoints;
  a missing backend field is a separate flagged handoff, never faked.
- **`CalendarFilterContext` / "viewing another (shared) calendar"** behavior — the new app has no such
  context (deferred in the tags slice too). The page renders the signed-in user's own events; the
  cross-calendar filter is **deferred + flagged**, not faked.
- Restyling the **calendar grid** or its popover (their own slices) — beyond reusing `EventPopover` /
  `RecurringScopeDialog` as-is.
- Re-deriving the design foundation (slice 0) or the Allosta mockup.

# Acceptance criteria

- [ ] `/events` route renders `EventsPage`; **События** appears in the sidebar (Исполнение) and is
      active on `/events`; light + dark match old-focal.
- [ ] The events list + filter bar visually match `apps/old-focal/pages/Events.tsx` (search, date
      preset incl. custom range, orphan/priority/projectType, multi-select sphere/project/product/
      activity/tags); filters persist across reload via `localStorage` with old-focal's defaults
      (datePreset = `thisMonth`).
- [ ] Create / edit / delete work over the **existing** `api/events.ts` (incl. the recurring-scope
      dialog for recurring events) — no API change, no behavior regression in calendar tests.
- [ ] No hardcoded strings (i18next `ru` + `en`); the diff is surgical and traces to this task; the
      deferred `CalendarFilterContext` cross-calendar filter is flagged, not faked.
- [ ] Green: `cd superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run &&
      pnpm build`, with new tests for the page (filtering, persistence, list rendering).

# Verification commands

```sh
cd superapp/apps/focal/client
pnpm install --frozen-lockfile
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```

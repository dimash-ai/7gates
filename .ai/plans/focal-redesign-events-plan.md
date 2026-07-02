# Summary

Add a new `EventsPage` that recreates old-focal's Events list view on the new Focal stack. The page will fetch a date window with the existing `listEvents(startDate, endDate)`, enrich/filter/sort/group events client-side, persist the old-focal filter model in `localStorage`, and reuse the existing `EventPopover`, `RecurringScopeDialog`, and `api/events.ts` mutations for create/edit/delete including recurring scope. The only new shared primitives are the missing `ui/multi-select` and a pure date-preset range utility; no backend, generated OpenAPI, package, or calendar-grid change is planned.

# Files to change

| path | change | why |
|------|--------|-----|
| `/Users/allosta/Desktop/allosta/superapp/apps/focal/client/src/components/ui/multi-select.tsx` | Add a generic controlled multi-select built from existing Popover/Badge/Input/Button primitives, with swatches, search, disabled state, clear-all, and no nested `<button>` markup. | Old-focal Events requires five multi-select filters and the new app has no primitive for them. |
| `/Users/allosta/Desktop/allosta/superapp/apps/focal/client/src/components/ui/multi-select.test.tsx` | Add focused component tests for selection, deselection, clear-all, search empty state, disabled state, and trigger/badge rendering. | Proves the new primitive works independently before the Events page consumes it. |
| `/Users/allosta/Desktop/allosta/superapp/apps/focal/client/src/lib/datePresetRange.ts` | Port old-focal's `addCalendarDays`, `DatePresetForRange`, `getDateRangeFromPreset`, and the Events "all/custom fallback" query range helper using string-calendar arithmetic. | Keeps date-preset behavior exact and testable without adding date-fns or timezone packages. |
| `/Users/allosta/Desktop/allosta/superapp/apps/focal/client/src/lib/datePresetRange.test.ts` | Port/extend old-focal preset tests for day/week/month/quarter/year boundaries plus `all`/`custom` query fallback. | Proves API query windows and client-side date filters match the binding page. |
| `/Users/allosta/Desktop/allosta/superapp/apps/focal/client/src/features/events/eventsFilters.ts` | Add `EventFilters`, defaults, localStorage load/save migration, event enrichment from projects/tags, filter predicates, grouping, sort helpers, active-filter counting, and event-draft/payload helpers local to the Events page. | Keeps the large filter model pure and reviewable, and avoids touching `CalendarPage` just to share local helpers. |
| `/Users/allosta/Desktop/allosta/superapp/apps/focal/client/src/features/events/eventsFilters.test.ts` | Add unit tests for storage defaults/migration, search, orphan, priority, project type, sphere/project/product/activity/tag/no-tag/date filtering, stale dependent selections, grouping, sorting, recurrence detection, and create/update/delete payload helpers. | Proves the core old-focal behavior without brittle DOM tests. |
| `/Users/allosta/Desktop/allosta/superapp/apps/focal/client/src/features/events/EventsPage.tsx` | Add the page shell, header controls, collapsible filter card, event list/cards, option queries, create/edit/delete popover wiring, recurring-scope dialog wiring, loading/empty/error states, and deferred cross-calendar note in code comments only. | This is the new user-facing `/events` surface. |
| `/Users/allosta/Desktop/allosta/superapp/apps/focal/client/src/features/events/EventsPage.test.tsx` | Add integration tests over mocked APIs for rendering, filters, persistence, create/edit/delete, recurring scope, option failures, and error states. | Proves the page composes the APIs, filters, popover, and query invalidation correctly. |
| `/Users/allosta/Desktop/allosta/superapp/apps/focal/client/src/features/events/index.ts` | Export `EventsPage`. | Matches existing feature export pattern. |
| `/Users/allosta/Desktop/allosta/superapp/apps/focal/client/src/App.tsx` | Import `EventsPage` and register `<Route path="/events" component={EventsPage} />`. | Adds the required route. |
| `/Users/allosta/Desktop/allosta/superapp/apps/focal/client/src/App.test.tsx` | Add a minimal route test with auth/shell mocked to prove `/events` renders the Events page through `App`. | Covers route wiring without broad shell coupling. |
| `/Users/allosta/Desktop/allosta/superapp/apps/focal/client/src/components/AppSidebar.tsx` | Add `events` to the Execution nav section with a calendar/list icon. | Adds the required sidebar item and active navigation target. |
| `/Users/allosta/Desktop/allosta/superapp/apps/focal/client/src/components/AppShell.test.tsx` | Extend shell/sidebar coverage to assert the localized Events nav item appears with `/events`. | Proves navigation wiring stays visible alongside existing dashboard/meeting badge behavior. |
| `/Users/allosta/Desktop/allosta/superapp/apps/focal/client/src/i18n/locales/en.json` | Add `focal.app.nav.events`, `focal.events`, `focal.events.filters`, `focal.events.orphan`, and action/error/accessibility keys, reusing old-focal copy where available and calendar error wording where old-focal had no equivalent. | No visible or accessible string is hardcoded. |
| `/Users/allosta/Desktop/allosta/superapp/apps/focal/client/src/i18n/locales/ru.json` | Add the same keys in Russian from old-focal where available. | Keeps RU and EN complete. |

No change is planned for `api/events.ts`, `api/openapi.d.ts`, backend code, package manifests, `features/calendar/EventPopover.tsx`, `features/calendar/RecurringScopeDialog.tsx`, `features/calendar/CalendarPage.tsx`, or shared shell components other than the sidebar nav list.

# Implementation slices

1. Add locale keys and route/sidebar placeholders.
   - Add the Events nav key and Events/filter/orphan/action/error keys to both locales, preserving current JSON structure.
   - Add `features/events/index.ts` and a minimal temporary `EventsPage` that renders the localized title through `PageHeader`.
   - Register `/events` in `App.tsx` and add the sidebar item in the Execution group.
   - Add/extend route and shell tests for `/events` and the nav item.
   - Build stays green because the page is a thin shell and no filters are wired yet.

2. Add the date-preset utility.
   - Port old-focal `datePresetRange` behavior into `src/lib/datePresetRange.ts`: `all` and `custom` produce `{ from: null, to: null }`; week ranges are Monday-Sunday; month/quarter/year boundaries use calendar-date string arithmetic.
   - Add an Events query-window helper that returns the preset range when bounded, custom `dateFrom/dateTo` when both exist, and old-focal's rest range (`2020-01-01` through end of current year + 2) for `all` and incomplete custom ranges.
   - Test leap/month/quarter/year boundaries and the rest-range fallback.
   - Keep this slice pure TypeScript; no UI and no dependency changes.

3. Add the multi-select primitive.
   - Build the trigger as one top-level button via `PopoverTrigger asChild`; render selected options as non-interactive badges inside it.
   - Use an `Input` inside `PopoverContent` for search and row buttons/divs for options, so clear/select controls do not create nested buttons.
   - Support `options`, `selected`, `onChange`, `placeholder`, `searchPlaceholder`, `emptyText`, `disabled`, `maxDisplay`, `className`, and optional `color`.
   - Add tests for keyboard/mouse-visible behavior that the Events page depends on.

4. Add pure Events filter, enrichment, persistence, and payload logic.
   - Define the exact old-focal filter shape and defaults: `orphanFilter=all`, `priorityFilter=all`, `projectType=all`, empty multi-select arrays/search, `datePreset=thisMonth`, null custom dates.
   - Implement storage load/save around `localStorage["focal-events-filters"]`, including single-value-to-array migration and the old-focal `datePreset=all` soft migration to `thisMonth` when no other filters are active.
   - Enrich events from existing API data only: root projects/products from `listProjects()` results, spheres from `listSpheres()` when present and project `sphere` fallback when needed, activities from `listActivities()`, tags from `listTags()`, and event-provided `isOrphan`/`orphanReason` when available.
   - Implement old-focal filters: title search, orphan/classified/completed/active, `priorityLevel ?? "medium"`, mission/provision, sphere/project/product/activity/tag/no-tag, and date range.
   - Group filtered events into upcoming/past date cards; sort dates ascending for upcoming, descending for past, and sort events within each day by `startTime`.
   - Add local event draft/payload helpers mirroring `CalendarPage`'s existing create/update semantics so `EventPopover` can be reused without editing the calendar grid.

5. Build the Events page list and filters.
   - Replace the temporary page with `PageHeader` using a Calendar/List icon, Add button, filter toggle with active-count badge, orphan select, priority select, and filtered/total count badge; `PageHeader` keeps the global `PageToolbar`.
   - Fetch events with `useQuery({ queryKey: ['events', startIso, endIso], queryFn: () => listEvents(startIso, endIso) })`.
   - Fetch filter option data with existing wrappers only: `listProjects`, `listSpheres`, `listActivities`, and `listTags`. Derive products from the full project list's `parentProjectId` rows first; use `listProducts(projectId)` only if implementation proves the full project list does not carry child rows.
   - Render the old-focal filter card: search, project type, sphere/project/product/activity/tag multi-selects, date preset, custom from/to dates, and reset.
   - Preserve dependent-filter cleanup: changing projects drops invalid products; changing products drops invalid activities.
   - Render loading, query error, empty, filtered-zero, upcoming, and past groups with old-focal row/card classes adapted to existing tokens.

6. Wire create/edit/delete through existing event machinery.
   - Add a header Add button that opens `EventPopover` in create mode anchored to the Add button, with today's local date and a sensible default time range matching the existing popover contract.
   - Open edit mode from each event row's Pencil button using that row as the popover anchor.
   - Use existing `createEvent`, `updateEvent`, and `deleteEvent`; invalidate `['events']` after successful mutations; keep mutation failures non-optimistic.
   - For recurring events (`event.recurrence !== 'none' || event.recurringEventId !== null`), stage update/delete in `RecurringScopeDialog` and pass `{ scope, occurrenceDate: event.occurrenceDate ?? event.date }` to the mutation.
   - Add title-required guard before save so a blank create/edit never sends a request.

7. Final parity pass and required verification.
   - Compare against `apps/old-focal/client/src/pages/Events.tsx` for header controls, filter options, row badges, upcoming/past grouping, completed opacity/line-through, orphan dashed treatment, recurrence badge, and count text.
   - Confirm the cross-calendar `CalendarFilterContext` branch is absent and not faked; the page shows the signed-in user's own events through existing endpoints.
   - Run focused tests first, then the required command set:
     `cd /Users/allosta/Desktop/allosta/superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.

# Tests

- `multi-select selects, deselects, and clears values`: component unit test proving `onChange` returns the exact selected value array and clear-all does not toggle the popover trigger accidentally.
- `multi-select filters options and shows empty text`: component unit test proving the search input limits visible options and renders the localized empty state.
- `multi-select renders selected color badges and disabled state`: component unit test proving selected swatches/count badges are visible and disabled triggers cannot open/change values.
- `date presets match old-focal boundaries`: pure unit test proving today/yesterday/tomorrow, Monday-first week, month, quarter, next quarter, and year ranges.
- `event query window uses thisMonth default and rest fallback`: pure unit test proving default `thisMonth`, `all`, and incomplete custom ranges call the same windows old-focal used.
- `loads event filters with defaults and migrates legacy storage`: pure unit test proving missing/invalid storage falls back safely, single IDs migrate to arrays, no-tag migrates, and old saved `all` date preset becomes `thisMonth` only when no other filters are active.
- `saves filters without crashing when storage throws`: pure unit test proving storage write failure does not break the page state.
- `filters events by search, orphan state, completion, priority, and project type`: pure unit test proving core old-focal filter semantics over enriched events.
- `filters events by sphere, project, product, activity, tag, and no-tag`: pure unit test proving all multi-select filters and tag-name/tag-id normalization.
- `filters events by date preset and custom dates`: pure unit test proving client-side date filtering uses event `date` and inclusive boundaries.
- `groups and sorts events into upcoming and past sections`: pure unit test proving date-card order and intra-day `startTime` order.
- `cleans invalid dependent filter selections`: pure unit test proving project/product changes drop no-longer-valid product/activity IDs.
- `builds create and update event payloads like CalendarPage`: pure unit test proving create includes required fields plus only selected optional links, and update includes dirty optional fields only.
- `renders /events through App`: route integration test proving the new route resolves to `EventsPage`.
- `shows Events in the sidebar`: shell/sidebar test proving the localized nav item links to `/events` in the Execution group.
- `requests the default month window and renders grouped event cards`: page integration test proving `listEvents(start,end)` receives the `thisMonth` window and visible rows include time, title, priority stripe, project-type badge, recurrence marker, and status/completed treatment.
- `toggles the filter panel and applies persisted filters`: page integration test proving filter controls update the list, count badge, active-filter badge, and `localStorage["focal-events-filters"]`.
- `resets advanced filters while preserving orphan and priority selects`: page integration test proving old-focal reset behavior.
- `creates an event from the Add button popover`: page integration test proving `createEvent` is called with the popover draft payload and event queries invalidate on success.
- `edits a non-recurring event from the row popover`: page integration test proving `updateEvent(id, patch, undefined)` is called and the popover closes only on success.
- `deletes a non-recurring event from the row popover`: page integration test proving `deleteEvent(id, undefined)` is called and the row remains on failure because delete is not optimistic.
- `asks for recurring update scope`: page integration test proving editing a recurring event opens `RecurringScopeDialog` and sends `updateEvent(id, patch, { scope, occurrenceDate })` after confirmation.
- `asks for recurring delete scope`: page integration test proving deleting a recurring event opens `RecurringScopeDialog` and sends `deleteEvent(id, { scope, occurrenceDate })` after confirmation.
- `keeps drafts open on mutation failure`: page integration test proving create/update/delete errors render a localized alert and keep the popover/draft available for retry.
- `shows option-query failures without hiding events`: page integration test proving failed projects/spheres/activities/tags queries show localized filter-option failure feedback or disabled empty controls while event rows still render.
- `shows list load error and empty state`: page integration test proving `listEvents` rejection renders the localized load error, and a successful empty list renders old-focal "No events" copy.
- Final command set: `cd /Users/allosta/Desktop/allosta/superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.

# Error & rescue map

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| `events.filters.storage_unreadable` | `localStorage.getItem` throws or stored JSON parse fails | `loadEventFilters` catch in `eventsFilters.ts` | Events page opens with default filters (`thisMonth`) and no blocking error. |
| `events.filters.storage_write_failed` | `localStorage.setItem` throws | `saveEventFilters` catch in `eventsFilters.ts` | Current filters still work for the session; no crash or blocking banner. |
| `events.date.invalid_custom_range` | No exception; `datePreset=custom` lacks both dates | query-window helper in `datePresetRange.ts` | The page uses the old-focal rest range and keeps the custom date inputs visible. |
| `events.list.failed` | `listEvents(start,end)` rejects through React Query | `EventsPage` event query error branch | Localized `focal.events.errors.load`; header/filter controls remain available. |
| `events.filter_options.projects_failed` | `listProjects()` rejects | filter option query branch in `EventsPage` | Existing events still render; project/product filters are empty or disabled with localized option-load feedback. |
| `events.filter_options.spheres_failed` | `listSpheres()` rejects | filter option query branch in `EventsPage` | Existing events still render; sphere filter falls back to project-derived spheres when possible, otherwise shows empty/disabled feedback. |
| `events.filter_options.activities_failed` | `listActivities()` rejects | filter option query branch in `EventsPage` | Existing events still render; activity filter is empty or disabled with localized option-load feedback. |
| `events.filter_options.tags_failed` | `listTags()` rejects | filter option query branch in `EventsPage` | Existing events still render; tag filter keeps the "No tag" option and shows localized option-load feedback. |
| `events.filter.no_matches` | No exception; derived `filteredEvents` is empty | list render branch after a successful event query | Old-focal empty copy (`focal.events.noEvents`) with filters still visible and reset available. |
| `event.blank_save` | No exception; trimmed title is empty | `handleSave` guard before create/update mutation | Localized title-required alert; no API request is sent and the popover stays open. |
| `event.create.failed` | `createEvent(input)` rejects | create mutation `onError` in `EventsPage` | Localized save alert with backend detail; create popover remains open with the draft. |
| `event.update.failed` | `updateEvent(id, patch, target)` rejects | update mutation `onError` in `EventsPage` | Localized save alert with backend detail; edit popover remains open with the draft. |
| `event.delete.failed` | `deleteEvent(id, target)` rejects | delete mutation `onError` in `EventsPage` | Localized save/delete alert with backend detail; event row remains because deletion is not optimistic. |
| `event.recurring_scope.cancelled` | No exception; user cancels the scope dialog | `RecurringScopeDialog.onCancel` in `EventsPage` | Scope dialog closes and the event popover/draft remains available; no mutation is sent. |
| `event.popover.anchor_missing` | No exception; Add/row element ref is unavailable | popover open helper builds a zero-rect fallback anchor | Popover still opens in a safe default position instead of crashing. |
| `events.cross_calendar.deferred` | No exception; no `CalendarFilterContext` exists in the new app | Not implemented by design | Page shows the signed-in user's own events; no shared-calendar filter is displayed or faked. |

# Review lenses (pre-answer before gate2-plan)

- **Scope / strategy** — This is the minimum exact-parity implementation for a page that does not exist yet: one new feature folder, one missing UI primitive, one missing date utility, route/sidebar wiring, locale keys, and tests. Existing `api/events.ts`, `EventPopover`, `RecurringScopeDialog`, query client invalidation, and option-list API wrappers are the behavior base. The decision is reversible by removing the new feature/utility/primitive files plus the route/nav/locale additions.
- **Architecture** — Data enters through existing React Query wrappers. Date windows are pure utility output; filters are pure derived state over fetched events and option lists; localStorage persistence is isolated. `EventsPage` owns only UI state: filter panel open, filters, popover/draft/dirty fields, pending recurring operation, participants, and mutation error. Upstream failures are handled per query/mutation without changing backend contracts.
- **Design** — The page uses `PageHeader` so the sidebar trigger and global toolbar stay consistent. The old-focal controls are preserved: filter toggle, orphan/priority selects, count badge, collapsible advanced filters, custom range, upcoming/past date cards, orphan dashed rows, completed opacity/line-through, recurrence/status/project-type badges, and responsive wrapping. Loading, empty, filtered-zero, option-error, mutation-error, create, edit, delete, and recurring-scope states are explicit.
- **DevEx** — No new dependency, codegen, schema, service, global context, or package change. Complex filter/date behavior is extracted only because it is independently testable and mirrors an existing old-focal contract. Tests should assert visible behavior, API payloads, query keys/windows, and pure filter output rather than full class snapshots.

# Risks & migrations

- No database migration, backend/API/schema change, generated OpenAPI change, package/lockfile change, environment variable, or data backfill.
- Main risk: `EventPopover` was built for a calendar-grid anchor. Rescue: anchor it to the Add button or row action element with a measured fallback rect; do not change the popover component unless a real bug appears.
- Main UI risk: the new `MultiSelect` can accidentally create nested interactive elements inside the trigger. Rescue: badges and clear affordance inside the trigger must be non-button elements with explicit pointer handling; option rows live only inside popover content.
- Data risk: `listProjects()` may or may not include child product rows in all environments. Rescue: derive products from `parentProjectId` when available; if absent, fetch products for selected root projects via existing `listProducts(projectId)` only, still with no new endpoint.
- Parity risk: old-focal used `CalendarFilterContext` for shared calendars. Rescue: keep that path explicitly deferred and do not add partial or fake calendar-scope query params.
- Rollback plan: revert the new Events feature files, `multi-select`, date utility, tests, locale additions, and the `/events` route/sidebar item. No persisted data shape beyond the existing localStorage key is required by the backend.

# Scope check

- [x] Matches the task's Scope and Out of scope.
- [x] Small enough to review in one sitting if implemented in the ordered slices above.
- [x] Size smell checked: this touches several files because the page is new and needs two missing primitives, route/nav, locales, and tests. The diff remains frontend-only and avoids backend, codegen, package, calendar-grid, and shell refactors.

# Out of scope

- Any server/API/schema/migration/generated OpenAPI change.
- Any change to `api/events.ts` or existing event write contract.
- Restyling or behavior changes for the calendar grid, `EventPopover`, `RecurringScopeDialog`, `CalendarPage`, `TimeGrid`, `MonthView`, or calendar tests beyond confirming no regressions.
- `CalendarFilterContext`, shared-calendar viewing filters, `dataOwnerId`, `calendarId`, or read-only role behavior; this slice shows the signed-in user's own events only.
- Tailwind 3 config/PostCSS work, new packages, new global state providers, design-foundation changes, or unrelated page cleanup.

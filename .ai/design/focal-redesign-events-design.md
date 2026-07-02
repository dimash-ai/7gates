# Design — focal-redesign-events

Traces to [`tasks/focal-redesign-events.md`](../tasks/focal-redesign-events.md),
[`think/focal-redesign-events.md`](../think/focal-redesign-events.md), and
[`plans/focal-redesign-events-plan.md`](../plans/focal-redesign-events-plan.md). Binding visual/
behavior contract: `apps/old-focal/client/src/pages/Events.tsx` (read in full). Frontend-only;
re-skin/assemble over existing APIs on the new stack (Tailwind 4 / React 19 / shadcn).

## Architecture

New self-contained `features/events/` folder; the calendar grid and its components are untouched
(only **reused**). Component + state tree:

```
App.tsx  ──<Route path="/events">── EventsPage              (owns ALL page state)
AppSidebar.tsx ──"События" nav item (Исполнение group) ─────────────┘
EventsPage
  ├─ PageHeader (existing) → SidebarTrigger + PageToolbar (AI button preserved)
  │    title, Add button, filter toggle (active-count badge), orphan select, priority select, count badge
  ├─ Filter card (collapsible)  → search · projectType · MultiSelect×5 · date preset · custom range · reset
  ├─ Event list  → upcoming/past date-group cards → event rows (time, title, badges, color, actions)
  ├─ EventPopover (REUSED, features/calendar)        ← controlled by EventsPage draft state
  └─ RecurringScopeDialog (REUSED, features/calendar) ← controlled by EventsPage pending-op state
```

**State ownership** — `EventsPage` replicates `CalendarPage`'s exact popover ownership
(`CalendarPage.tsx:487-516`): `filters` (persisted), `showFilters`, a `popover` state
(`{mode:'create'|'edit', anchor, event}`), the controlled `draft: EventDraft`, a
`participants: PrimaContact[]` state, a `pendingOp` (`{mode:'update'|'delete', …}`) that gates
`RecurringScopeDialog`, and the create/update/delete mutations. `isSaving`/`isDeleting` are the
mutations' `isPending`. The popover's `onOpenChange` keeps it open while a `pendingOp` is active and
closes only on a genuine dismiss — `if (!next && !pendingOp) closePopover()` — the documented guard
(`CalendarPage.tsx:501-505`) that preserves the draft while the scope dialog steals focus. Everything
else is **derived** (pure) or **server state** (React Query). No new global context/provider.

**Data flow** — all reads go through existing typed wrappers; the active date-preset maps to a
bounded `[start,end]` window → `listEvents`; events are enriched + filtered + grouped purely in
memory; writes reuse `api/events.ts` mutations and invalidate `['events']`. No `api/events.ts`,
OpenAPI, backend, or package change.

## Data model

```ts
// features/events/eventsFilters.ts  (pure; mirrors old-focal EventFilters 1:1)
type OrphanFilter   = 'all' | 'orphans' | 'classified' | 'completed' | 'active'
type PriorityFilter = 'all' | 'high' | 'medium' | 'low'
type ProjectTypeF   = 'all' | 'mission' | 'provision'
interface EventFilters {
  orphanFilter: OrphanFilter; priorityFilter: PriorityFilter; projectType: ProjectTypeF
  sphereIds: string[]; projectIds: string[]; productIds: string[]; activityIds: string[]; tagIds: string[]
  searchQuery: string
  datePreset: DatePreset          // = DatePresetForRange (14 values, below)
  dateFrom: string | null; dateTo: string | null
}
const DEFAULTS: EventFilters = { orphanFilter:'all', priorityFilter:'all', projectType:'all',
  sphereIds:[],projectIds:[],productIds:[],activityIds:[],tagIds:[], searchQuery:'',
  datePreset:'thisMonth', dateFrom:null, dateTo:null }
const STORAGE_KEY = 'focal-events-filters'
```

`DatePresetForRange` (ported verbatim — **all 14**, resolving the gate-2 enumeration note):
`all · today · yesterday · tomorrow · thisWeek · lastWeek · nextWeek · thisMonth · lastMonth ·
nextMonth · thisQuarter · nextQuarter · thisYear · custom`.

**Event row data** = `CalendarEvent` (`EnrichedEventRead`) used directly. Old-focal re-derived
`projectType/sphere/color/isOrphan/orphanReason` client-side from the project list; the new app's
events are **already server-enriched** (carry `isOrphan`/`orphanReason`, and `projectType`/`sphere`/
color per the calendar contract). **Decision:** consume the event's own enriched fields where the
schema exposes them; only the `sphere`/`projectType` *filter option lists* derive from project data.
(Field-presence on `EnrichedEventRead` is confirmed at build via `openapi.d.ts`; any genuinely
absent field falls back to a project-id lookup — never faked.)

## Interfaces & contracts

**New — `components/ui/multi-select.tsx`** (generic, built from Popover/Badge/Input/Button; **no
nested `<button>`** — the documented heatmap-slice pitfall):
```ts
interface MultiSelectOption { value: string; label: string; color?: string }
interface MultiSelectProps {
  options: MultiSelectOption[]; selected: string[]; onChange: (next: string[]) => void
  placeholder?: string; searchPlaceholder?: string; emptyText?: string
  disabled?: boolean; maxDisplay?: number; className?: string
}
```
Trigger = single `PopoverTrigger asChild` button; selected shown as non-interactive `<span>`
badges; option rows + clear-all live only inside `PopoverContent`.

**New — `lib/datePresetRange.ts`** (pure; ports old-focal `shared/datePresetRange.ts` +
`lib/calendarRanges.ts`):
```ts
export function addCalendarDays(ymd: string, delta: number): string
export type DatePresetForRange = /* the 14 above */
export function getDateRangeFromPreset(preset, todayYmd): { from: string|null; to: string|null }
export function getRestRangeFromTodayYmd(todayYmd): { startDate: string; endDate: string } // 2020-01-01 → (year+2)-12-31
// the API-window helper (resolves the gate-1 `all`-preset note):
export function getEventsQueryRange(filters, todayYmd): { startDate: string; endDate: string }
//   all                       → getRestRangeFromTodayYmd            (BOUNDED, not unbounded)
//   custom with both dates    → { dateFrom, dateTo }
//   custom missing a date     → getRestRangeFromTodayYmd
//   any other preset          → getDateRangeFromPreset (→ {startDate,endDate}); rest-range if null
```
Week math is Monday-first; month/quarter/year use calendar-string arithmetic (no date-fns/tz dep).

**`todayYmd` source (resolves the gate-3 Should-Consider):** `toIsoDate(new Date())` (browser-local),
matching `CalendarPage` (`CalendarPage.tsx:178`). The new app has **no** display-timezone helper yet
(old-focal's `getNowInTimezone(displayTimezone)` is unported), so browser-local "today" is the
intentional, consistent choice across calendar + events — flagged for a future shared tz helper if
tz-anchored "today" is needed. No tz drift vs the rest of the new app.

**Reused (unchanged) contracts:**
- `EventPopover` (`features/calendar/EventPopover.tsx:43`) — **full required contract**, every prop
  supplied by EventsPage: `{ open, mode:'create'|'edit', anchor:AnchorSource|null, draft:EventDraft,
  recurring:boolean, participants:PrimaContact[], isSaving:boolean, isDeleting:boolean,
  onParticipantsChange, onPatch, onSave, onDelete, onOpenChange }`, where
  `EventDraft = { title, date, startTime, endTime, recurrence, recurrenceEndDate, color, completed,
  projectId, productId, activityId }` and `AnchorSource = { element: HTMLElement|null; rect: DOMRect }`.
  EventsPage owns the draft + participants + mutations and wires `onOpenChange` with the keep-open-
  while-`pendingOp` guard, **exactly** as `CalendarPage` does (`CalendarPage.tsx:487-507`) — the
  popover is reused **without editing it**. `recurring = isRecurring(popover.event)` in edit mode
  (`false` on create); `isSaving = create/updateMutation.isPending`, `isDeleting =
  deleteMutation.isPending`. Participants start `[]` on **both** create and edit (matching
  `CalendarPage.tsx:253,261`) — the popover takes `PrimaContact[]`, not event `contactIds`; this
  slice introduces **no** contact hydration or persistence (same posture as `CalendarPage`).
- `RecurringScopeDialog` — `{ open, mode:'update'|'delete', onConfirm:(scope)=>void, onCancel }`.
- `api/events.ts` — `listEvents(start,end)`, `createEvent`, `updateEvent(id,patch,target?)`,
  `deleteEvent(id,target?)` with `RecurrenceTarget {scope, occurrenceDate}`.
- Option lists — `listProjects`, `listSpheres`, `listActivities`, `listTags`. **Products decision
  (resolves gate-2 note):** derive products from `listProjects()` child rows
  (`parentProjectId != null`) exactly as old-focal does (`Events.tsx:319-323`) — `ProjectRead`
  carries `parentProjectId`; **no** per-project `listProducts` fan-out.

**Query keys:** events `['events', startIso, endIso]` (matches `CalendarPage`); options `['projects']`,
`['spheres']`, `['activities']`, `['tags']`. Mutations invalidate `['events']`.

**Nav (resolves gate-2 nav-label note):** old-focal lists **Задачи** (`/tasks`) and **События**
(`/events`) as separate items. The new sidebar's `tasks` label is currently the interim "Задачи и
события"/"Tasks & events" (events had no page). This slice restores old-focal parity: add an
`events` item (icon `CalendarDays`/list) to the Исполнение group **and** retune the `tasks` nav
**label** back to "Задачи"/"Tasks" (i18n string only — the tasks page/route/behavior is untouched;
its internal events tab is the tasks slice's concern, explicitly out of scope here).

## Happy flow

1. Open `/events` → `filters` load from `localStorage` (or `DEFAULTS`, `thisMonth`).
2. `getEventsQueryRange(filters, today)` → `listEvents(start,end)`; options fetched in parallel.
3. Events enriched → predicate chain (search → orphan → priority → projectType → sphere → project →
   product → activity → tag/no-tag → date-range) → grouped into upcoming (asc) / past (desc) date
   cards, intra-day by `startTime`. Count + active-filter badges update; filters persist on change.
4. Add → `EventPopover` (create) anchored to the Add button, default today + time range. Save →
   `createEvent` → invalidate `['events']` → popover closes.
5. Row Pencil → `EventPopover` (edit) anchored to the row. Save/Delete on a **recurring** event
   (`recurrence !== 'none' || recurringEventId != null`) → `RecurringScopeDialog` →
   `updateEvent`/`deleteEvent(id, {scope, occurrenceDate: event.occurrenceDate ?? event.date})`.

## Unhappy flow (full table in plan §"Error & rescue map")

- `localStorage` read/parse throws → `loadEventFilters` catch → `DEFAULTS`, no banner.
- `localStorage` write throws → `saveEventFilters` catch → session continues.
- `all`/incomplete-custom range → bounded rest-range (never an unbounded fetch).
- `listEvents` rejects → localized load error; header/filters stay usable.
- An option query rejects → events still render; that one filter shows empty/disabled feedback
  (sphere falls back to project-derived values).
- Empty filter result → old-focal "no events" copy with filters + reset still visible.
- Blank title on save → localized required-alert, **no** request sent, popover stays open.
- create/update/delete rejects → localized alert; draft/row preserved (delete is **not** optimistic).
- Recurring scope cancelled → dialog closes, draft preserved, no mutation.
- No `CalendarFilterContext` → signed-in user's own events only; cross-calendar filter **deferred +
  flagged**, never faked (parity with the tags slice).

## Alternatives rejected

- **Server-side event filtering** (add query params to `/api/events`) — out of scope (API change),
  over-built for the data size, diverges from old-focal's client-filter model. Window-fetch +
  client-filter chosen (1:1 with old-focal).
- **Reduced filter set now, multi-selects later** — fails "exact parity"; the multi-selects are the
  page's essence. Rejected.
- **Per-project `listProducts` fan-out** for the product filter — old-focal derives products from the
  single project list; fan-out is more requests + diverges. Rejected.
- **Re-deriving orphan/projectType/sphere client-side** like old-focal — unnecessary in the new app
  (events are server-enriched); consume the enriched fields, fall back only if a field is absent.

## Test strategy (Vitest + Testing Library; the gate-6 author owns final tests)

- **`lib/datePresetRange.test.ts`** — all 14 presets incl. leap/month/quarter/year boundaries +
  Monday-first weeks; `getEventsQueryRange` for `thisMonth` default, `all`→rest-range, custom
  (both/one date). *Proves the API window + client date filter match old-focal exactly.*
- **`components/ui/multi-select.test.tsx`** — select/deselect/clear, search empty-state, disabled,
  color-badge render, single top-level trigger button. *Proves the primitive before consumption.*
- **`features/events/eventsFilters.test.ts`** — storage defaults/migration (single→array, no-tag,
  `all`→`thisMonth` only when no other filters active), every predicate, dependent-filter cleanup,
  grouping/sort, recurrence detection, create/update payload helpers. *Proves the core behavior
  without brittle DOM tests.*
- **`features/events/EventsPage.test.tsx`** — default month window requested; grouped cards render;
  filter toggle + persistence; reset preserves orphan/priority; create/edit/delete payloads + query
  invalidation; recurring scope (update/delete); mutation-failure keeps draft; option-failure still
  renders events; load-error + empty states.
- **Route/shell** — `/events` resolves to `EventsPage`; "События" nav item links `/events` in the
  Исполнение group; existing dashboard/meeting-badge nav unaffected.
- **Gate command:** `cd superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run
  && pnpm build`.

## Security notes

- No auth/tenant change: reuses `apiFetch` (bearer JWT) + existing endpoints; events are tenant-
  scoped server-side (RLS) — the page never sends a client-supplied `userId`/`calendarId` (the
  old-focal assistant `dataOwnerId`/`calendarId` params are part of the deferred `CalendarFilterContext`
  and are **not** reintroduced).
- `localStorage` holds only non-sensitive filter UI state.
- Search/filter is client-side over already-authorized data; no injection surface (no `dangerouslySetInnerHTML`).
- No secrets, no new external calls, no new dependency.

# Design — focal-parity slice 13: Cleanup sweep

3-gate flow · slice 13 (final) of the `focal-parity` epic. Branch `feat/focal-parity-cleanup` → base
`feature/focal-migration`. **Frontend-only** — all four items' backing endpoints already exist in the
new app (audit-confirmed). No server/API/schema/migration. This is the residual-minors sweep defined
in `.ai/plans/focal-parity-plan.md:195-198`; **no opportunistic refactors** (plan `:199`).

## Problem / intent

Four small, concrete parity gaps the area slices didn't cover:

1. **Meeting-accept → invalidate calendar events** — after accepting a meeting request the backend
   creates the event, but the new app's accept mutations never invalidate the events query, so the
   calendar stays stale until manual refresh. Old-focal invalidated `["/api/calendar/events"]` on
   accept (`old-focal/.../MeetingRequestsPage.tsx:83-85,129-131`).
2. **Theme + language toggles on public Privacy/Terms pages** — these render outside the authed shell,
   so old-focal gave them standalone theme + language toggles
   (`old-focal/pages/{Privacy,Terms}.tsx`). The new legal pages have none.
3. **Type-to-confirm on calendar delete** — old-focal requires typing the word `Удалить`/`Delete`
   before the delete button enables (`old-focal/pages/Calendars.tsx:1333-1362`); the new app has a
   plain yes/no dialog.
4. **Tasks/Events orphan-count sidebar badges** — old-focal shows a red `AlertTriangle` badge with the
   orphan count on the Tasks and Events nav items (`old-focal/components/AppSidebar.tsx:477-485`); the
   new sidebar has none, despite the `/api/stats/orphans` endpoint already being ported.

## Assumptions

- Every backing endpoint already exists in the new app (POST accept; theme=localStorage,
  language=i18next; DELETE shared-calendar; GET `/api/stats/orphans`) — this slice only wires client
  UI/cache behavior. If any item turns out to need a backend change, **stop and flag** rather than
  editing the server.
- "Orphan" keeps old-focal's exact definition (audit-confirmed identical in the new backend service):
  an item is orphan if it has **no project**, or — when its project has products — **no product**
  (tasks `server/app/services/tasks.py`, events `server/app/services/calendar.py`).
- Reuse-first: theme/language toggles reuse the existing `lib/theme.ts` `useTheme()` + the
  `PageToolbar` language-dropdown pattern; the orphan badge mirrors the sidebar's existing
  `meetingBadge` query+render pattern; the type-to-confirm reuses the existing `AlertDialog` + `Input`.

## Approach

All changes under `apps/focal/client/src/`. Four focused, independent edits.

### 1. Meeting-accept invalidates events (`features/meetings/MeetingRequestsPage.tsx`)

The events query key is `withCal(['events', startIso, endIso], currentCalendarId)`, and TanStack
Query prefix-matches, so `queryClient.invalidateQueries({ queryKey: ['events'] })` covers all
date-range + calendar variants (`withCal` appends the calendar segment AFTER the prefix — confirm in
`api/queryKeys.ts` — so the bare `['events']` prefix matches).

**Scope the invalidation to event-creating actions only.** The shared `onActionSuccess` callback is
ALSO used by decline / tentative / delete (`features/meetings/MeetingRequestsPage.tsx`), and those do
NOT create a calendar event — invalidating `['events']` there is a wasted refetch. So gate the events
invalidation to **accept + reschedule-accept only**: pass an explicit flag from those two call sites
(e.g. `onActionSuccess({ invalidateEvents: true })`) and only invalidate `['events']` when set; the
meeting-requests-key invalidation stays unconditional for every action. No i18n.

### 2. Theme + language toggles on legal pages (`features/legal/PrivacyPage.tsx`, `TermsPage.tsx`)

Add a small right-aligned header to each page wiring two reused affordances:
- **Theme:** `useTheme()` from `lib/theme.ts` (`{ theme, toggle }`, manages localStorage `theme` +
  `.dark` class) + a Moon/Sun icon button (the `PageToolbar` icon-button pattern).
- **Language:** the `PageToolbar` language-dropdown pattern — `LANGUAGES` const, `useTranslation()`,
  current `i18n.language?.slice(0,2)`, `i18n.changeLanguage(code)`.

**Reuse caution (design decision):** do NOT mount the full `PageToolbar` on a public page (it bundles
page-title/shell assumptions). Either inline the two ~10-line toggle snippets, or — preferred for DRY
— extract a tiny shared `PublicToggles` component (theme + language only) and use it on both legal
pages. Pick the extract if both pages need it (they do). i18n: reuse the toggle-label keys
`PageToolbar` already uses (no new content keys; the `focal.privacy.*`/`focal.terms.*` content keys
already exist).

### 3. Type-to-confirm calendar delete (`features/calendars/CalendarsPage.tsx`)

In the existing delete `AlertDialog` (the one gated on `confirm.kind === 'delete'`):
- Add `const [deleteConfirmText, setDeleteConfirmText] = useState('')`.
- Render an `Input` (from `components/ui/input`) inside the dialog, only for the delete kind, with the
  instruction text + placeholder.
- Disable `AlertDialogAction` until `deleteConfirmText === t('focal.calendars.confirm.deleteConfirmWord')`.
- Reset `deleteConfirmText` whenever the dialog closes (and on open).
- New i18n keys under `focal.calendars.confirm` in BOTH locales: `deleteConfirmWord`
  (`Удалить`/`Delete`), `confirmDeleteTyping` (instruction), `deleteConfirmPlaceholder`.

This applies wherever the owner sees the delete action (the existing `isOwner`/delete gating is
unchanged — only the confirm step gains the typed gate). The leave/remove kinds keep the plain
confirm.

### 4. Orphan-count sidebar badges (`components/AppSidebar.tsx`)

Mirror the existing `meetingBadge` pattern, with the corrected client contract + RBAC gating + date
window:
- Add `orphanBadge?: boolean` to the `NavItem` interface; set it on the Tasks + Events items.
- Add one `useQuery` for `GET /api/stats/orphans`. **Client contract (camelCase, generated):**
  `OrphanStatsRead = { orphanTasks: number; orphanEvents: number; total?: number }`
  (`api/openapi.d.ts:4022-4026`) — NOT snake_case. Call shape mirrors the meeting-count query
  (`apiFetch('/api/stats/orphans', { query: { calendarId, startDate, endDate } })`, key
  `withCal(['stats','orphans', startDate, endDate], currentCalendarId)`).
- **Date window (critical — avoids undercount):** the stats service defaults to the CURRENT MONTH when
  no window is given (`server/app/services/stats.py`), which would undercount vs old-focal. Old-focal
  sends a rest-of-period window. Reuse the existing helper `getRestRangeFromTodayYmd(todayYmd)` from
  `lib/datePresetRange.ts:153` (returns `{ startDate, endDate }`) and pass those as the query params —
  same window old-focal used.
- **RBAC `enabled` gating (critical — avoids 403):** `/api/stats/orphans` is `DataDomain.OTHER_PAGES`,
  readable only by owner/full_access/developer (`server/app/data_scope.py`). The
  `CalendarFilterContext` already exposes the matching capability `canViewOtherPages`
  (`features/calendars/CalendarFilterContext.tsx:206` — role owner/full_access/developer), and
  `AppSidebar` already destructures it. Gate the query with `enabled: canViewOtherPages` so limited
  shared-calendar users (viewer/requester) never fire the request — matching old-focal disabling this
  query for the limited menu. Hiding the badge alone is NOT enough; the query itself must be disabled.
- Add a render branch alongside the existing `meetingBadge` block: a small `AlertTriangle` + count
  badge on the Tasks item (`orphanTasks`) and Events item (`orphanEvents`), shown only when the count
  > 0 (and, like the rest of the non-limited nav, only when `canViewOtherPages`). No i18n (numeric
  badge).

## Out of scope

- Anything beyond these four items — no opportunistic refactors (plan `:199`).
- The other explicitly-punted items (Goals heavier interactions, Habits dnd-kit drag, CRM
  contact-picker, Events custom-recurrence interval, shared-calendar AI mode) are tracked as their own
  follow-ups — NOT folded in here.

## Acceptance criteria

1. **Meeting accept:** accepting (and reschedule-accepting) a meeting request invalidates the calendar
   events query so the new event would refetch; the existing meeting-requests invalidation still
   fires for every action; **decline/tentative/delete do NOT invalidate events** (no event created).
   Covered by tests asserting events are invalidated on accept but not on decline.
2. **Legal toggles:** Privacy + Terms each render a theme toggle (flips `.dark` + persists) and a
   language toggle (switches i18n language); reused from existing hooks, full `PageToolbar` not
   mounted. Covered by a test that toggling theme/language updates state.
3. **Type-to-confirm:** the delete dialog's action stays disabled until the user types the confirm
   word, enables when matched, and resets on close; the DELETE mutation is unchanged. Covered by a
   test (disabled→type wrong→still disabled→type word→enabled).
4. **Orphan badges:** Tasks/Events nav items show the orphan count (`orphanTasks`/`orphanEvents`,
   camelCase contract) from `/api/stats/orphans` when > 0, hidden when 0; calendarId-scoped; the query
   sends the rest-of-period window (`getRestRangeFromTodayYmd`) so it doesn't undercount; and the query
   is **disabled (not fired) when `!canViewOtherPages`** (limited shared-calendar users). Covered by
   tests: badge shows a mocked count; query disabled for a viewer role.
5. **i18n parity:** new `focal.calendars.confirm.*` keys mirrored EN↔RU; no hardcoded user-facing
   strings; legal toggle labels reuse existing keys.
6. **Green bar:** `pnpm typecheck`, `pnpm lint`, `pnpm test:run` (the 4 new tests), `pnpm build` pass.
   Diff confined to the four touch-points + the locale file(s).

## Risk

Low. Four small, independent, frontend-only changes, each reusing an established pattern in the
codebase; no schema/migration; the destructive action (calendar delete) gets a STRONGER guard, not a
weaker one. Rollback = revert the client files.

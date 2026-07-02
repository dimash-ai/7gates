# Summary

Restyle the new Focal meeting requests page in place to match the old-focal `MeetingRequestsPage` and `MeetingRequestCard` contract while keeping the current React Query/API mutation wiring. The calendar filter is in scope: `MeetingRequestRead.sharedCalendarId` is present in the generated OpenAPI type and `listAccessibleCalendars()` already exists, so the implementation should add the old-focal search, calendar, type, and status-tab controls over the loaded request list instead of deferring that filter.

Use the shell-owned `PageHeader` rather than adding a page-local AI button: it already carries the sidebar trigger and shared toolbar/AI entry point, and can reproduce the old page title/icon/pending badge through `icon` and `rightActions`. Keep the implementation frontend-only, localized in RU/EN, and scoped to the meeting requests feature, its tests, and locale keys.

# Files to change

| path | change | why |
|------|--------|-----|
| `/Users/allosta/Desktop/wt-focal-meeting-requests/apps/focal/client/src/features/meetings/MeetingRequestsPage.tsx` | Replace the bespoke header with `PageHeader`; add accessible-calendars query; add old-focal search/calendar/type filter row; replace status buttons with `Tabs`; restyle the request card markup to old-focal parity while preserving existing accept/decline/tentative/reschedule/delete mutations. | This is the page surface under redesign. |
| `/Users/allosta/Desktop/wt-focal-meeting-requests/apps/focal/client/src/features/meetings/requests.ts` | Add small pure helpers/types for request type filters, calendar filters, search matching, combined filtering, and calendar-filter validation; keep existing status/type normalization and date formatting. | Keeps filtering testable and prevents JSX-only filtering logic from growing inside the page. |
| `/Users/allosta/Desktop/wt-focal-meeting-requests/apps/focal/client/src/features/meetings/MeetingRequestsPage.test.tsx` | Mock `api/sharedCalendars`; update existing assertions for the old-focal structure; add coverage for search, type, calendar, status tabs, card states, and preserved mutations. | Current tests pin the old button-row/inline-card behavior and must prove the new contract. |
| `/Users/allosta/Desktop/wt-focal-meeting-requests/apps/focal/client/src/i18n/locales/ru.json` | Add missing RU keys for search placeholder/clear label, calendar/type filter labels, calendar-load error, search empty copy, status-tab accessible labels if needed, and any new card accessible labels. | All visible and accessible text must stay localized, reusing old-focal RU copy where it maps. |
| `/Users/allosta/Desktop/wt-focal-meeting-requests/apps/focal/client/src/i18n/locales/en.json` | Add the same keys in English. | Keep locale parity and avoid missing-key output. |

No change is planned for `api/meetingRequests.ts`, `api/sharedCalendars.ts`, `api/openapi.d.ts`, `PageHeader`, `PageToolbar`, shared UI primitives, backend files, package manifests, or lockfiles.

# Implementation slices

1. Add filter primitives and locale scaffolding.
   - In `requests.ts`, add `REQUEST_TYPE_FILTERS = ['all', 'new', 'reschedule', 'cancel']`, `RequestTypeFilter`, `CalendarFilterValue`, and a combined helper such as `filterMeetingRequests(requests, { status, type, calendar, search })`.
   - Preserve old-focal semantics: status counts are computed from the full loaded request list, not from search/type/calendar-filtered results; search matches `title`, `organizerName`, and `organizerEmail`; calendar `main` means `sharedCalendarId === null`; any other calendar value matches `request.sharedCalendarId`.
   - Add a helper to validate the selected calendar filter against `['all', 'main', ...accessibleIds]` so the page can reset stale selections to `all` after accessible calendars change.
   - Add RU/EN keys before consuming them. Reuse existing keys for title, status/type labels, actions, empty statuses, pending badge, and request card details.
   - Build stays green because the existing page can continue using the old status-only flow until the next slice consumes the helpers.

2. Add old-focal header, filter row, and status tabs over the existing cards.
   - Import `PageHeader`, `Input`, `Select`, `Tabs`, and the needed lucide icons (`CalendarClock`, `Search`, `X`, `Calendar`, `Plus`, `RefreshCw`, `Trash2`, `Inbox`, `Check`, `XCircle`, `HelpCircle`).
   - Replace the local `<header>` with `<PageHeader icon={CalendarClock} title={t('focal.meetingRequests.title')} rightActions={pendingBadge}>`; keep the AI control in the shared `PageToolbar`, not duplicated in this page.
   - Add `listAccessibleCalendars` query with key `['shared-calendars', 'accessible']`. Render calendar options for `all`, `main`, and every accessible calendar using `calendar.name` and `calendar.color ?? '#3b82f6'`.
   - Add local state for `searchQuery`, `typeFilter`, and `calendarFilter`, then derive `visibleRequests` through the helper from slice 1.
   - Replace the status `Button` row with old-focal `Tabs` and a five-column responsive `TabsList` for all/pending/accepted/declined/tentative, including the old-focal icons and count badges.
   - Keep the existing message/error banners, request loading/error states, and mutation setup unchanged in this slice.

3. Restyle the request card to old-focal parity while preserving behavior.
   - Rework the card markup inside `MeetingRequestsPage.tsx` as a local subcomponent or local render helper; do not add a new file unless the implementation becomes unreviewably large.
   - Match old-focal card structure: status-colored left border, title plus type/status badges, time row, orange previous-slot row for reschedules, location row, organizer row, optional two-line description, and action/footer row.
   - Use old-focal visual mappings with localized text: status badges yellow/green/red/blue; type badges creation/изменение/удаление with their distinct icon/color treatment; accepted note and tentative note as compact badges.
   - Preserve current backed behavior: pending requests still support accept, decline, tentative for `new`; reschedules route accept/decline to the reschedule endpoints; cancel requests use the existing accept/decline endpoints; declined requests can delete; no optimistic updates are introduced.
   - Keep duplicate-submit protection. If adding per-action loading visuals, track only the clicked request/action and still prevent duplicate calls while the relevant mutation is pending.

4. Finish empty/loading/error polish and responsive behavior.
   - Match old-focal content width (`max-w-4xl`), scrollable shell layout (`flex h-full flex-col overflow-hidden` plus content `overflow-auto p-4 md:p-6`), filter row wrapping, and the mobile-friendly tabs grid.
   - Empty state keeps the old-focal `CalendarClock` card and hint. If `searchQuery.trim()` is non-empty and filters produce zero rows, use the old-focal search-empty copy; otherwise use the status-specific empty copy.
   - Calendar-list failure is non-blocking: requests still render, `all` and `main` remain usable, and a small localized warning/alert explains that shared calendars could not be loaded.
   - Clear search with an icon button that has a localized accessible label; rely on Radix Select/Tabs keyboard behavior for filter controls.
   - Run focused tests before the full client gate.

5. Final verification and visual pass.
   - Run the focused test file while iterating, then the required command set:
     `cd /Users/allosta/Desktop/wt-focal-meeting-requests/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.
   - Verify screenshots in light and dark against `/Users/allosta/Desktop/allosta/superapp/apps/old-focal/client/src/pages/MeetingRequestsPage.tsx` and `components/meeting-requests/MeetingRequestCard.tsx`.
   - Fix only regressions in this page: header, filter row, tabs/counts, cards, empty/loading/error states, and existing mutation behavior.

# Tests

- `renders the old-focal header, shared toolbar, and pending badge`: proves `PageHeader` shows the `CalendarClock` title and localized pending badge, and the page does not add a second page-local AI button beyond the shared toolbar.
- `loads accessible calendars and renders the calendar filter`: proves `listAccessibleCalendars()` is called, `all`, `main`, and shared-calendar options render with localized labels, and the filter control is keyboard-accessible through the Select primitive.
- `filters by search across title and organizer`: proves search matches title, organizer name, and organizer email, and the clear button resets the result list without another API request.
- `filters by request type`: proves `new`, `reschedule`, and `cancel` type options use `requestTypeOf(...)` normalization and show only matching rows while `all` restores them.
- `filters by calendar including main calendar`: proves `main` shows requests with `sharedCalendarId === null`, a shared calendar id shows only matching requests, and `all` restores the full loaded set.
- `resets a stale selected calendar`: start with a selected shared id, resolve accessible calendars without that id, and prove the page returns to `all` instead of keeping a Select value with no option.
- `renders status tabs with old-focal counts and filtering`: proves all/pending/accepted/declined/tentative tabs show icons and badges based on the full request list, and each tab filters by normalized status.
- `shows the old-focal search empty state`: with non-empty search text and zero matches, proves the search-specific empty copy appears with the standard CalendarClock empty card and hint.
- `shows the status empty state when no search is active`: proves the existing localized status-specific empty copy still appears for empty all/pending/accepted/declined/tentative states.
- `renders old-focal card details for a normal request`: proves title, type badge, status badge, time, location, organizer name/email, and description render in the expected card structure.
- `renders old-focal reschedule details`: proves reschedule requests show the current time and the localized `was` row for `originalStartTime`/`originalEndTime`.
- `renders accepted, tentative, and declined footers`: proves accepted shows the added-to-calendar badge, tentative shows a tentative badge, and declined exposes the delete action only.
- `accepts a pending request and refetches the list`: preserves `acceptMeetingRequest(id)` and query invalidation.
- `declines a pending request and refetches the list`: preserves `declineMeetingRequest(id)` and query invalidation.
- `marks a pending new request as tentative`: preserves `tentativeMeetingRequest(id)` for `requestType === 'new'`.
- `accepts and declines reschedules through reschedule endpoints`: preserves `acceptMeetingReschedule(id)` / `declineMeetingReschedule(id)` and proves the normal accept/decline endpoints are not called for reschedules.
- `deletes a declined request and refetches the list`: preserves `deleteMeetingRequest(id)` and query invalidation.
- `shows the request-list load error`: rejected `listMeetingRequests()` renders localized `focal.meetingRequests.errors.load`.
- `shows the calendar-list warning without blocking requests`: rejected `listAccessibleCalendars()` renders the non-blocking localized calendar warning while loaded meeting requests remain visible and filterable by `all`/`main`.
- `shows mutation errors with backend detail`: rejected action mutation renders the existing localized alert with the backend error detail and leaves the row visible.
- Final command set: `cd /Users/allosta/Desktop/wt-focal-meeting-requests/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.

# Error & rescue map

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| `meetingRequests.list.failed` | `listMeetingRequests()` rejects through React Query | Existing `requests.isError` branch in `MeetingRequestsPage` | Localized destructive load message; filters/header remain mounted. |
| `meetingRequests.calendars.failed` | `listAccessibleCalendars()` rejects through React Query | New `accessibleCalendars.isError` branch near the filter row | Non-blocking localized warning that shared calendars could not load; request list remains usable with `all` and `main`. |
| `meetingRequests.calendarFilter.stale` | No exception; selected shared calendar id is no longer in accessible calendars | Calendar-filter validation effect/helper in `MeetingRequestsPage` | Selection resets to `all`; no empty Select value or broken option remains. |
| `meetingRequests.filter.zeroSearchMatches` | No exception; derived filtered list is empty with non-empty search | Empty-state branch after filtering | Old-focal CalendarClock empty card with search-specific no-results copy and the standard hint. |
| `meetingRequests.filter.zeroStatusMatches` | No exception; derived filtered list is empty with no active search text | Empty-state branch after filtering | Old-focal CalendarClock empty card with the localized status-specific empty copy and hint. |
| `meetingRequests.accept.failed` | `acceptMeetingRequest(id)` rejects | Existing `acceptMutation.onError -> onActionError` | Localized alert with backend detail; no optimistic row removal. |
| `meetingRequests.decline.failed` | `declineMeetingRequest(id)` rejects | Existing `declineMutation.onError -> onActionError` | Localized alert with backend detail; no optimistic row removal. |
| `meetingRequests.tentative.failed` | `tentativeMeetingRequest(id)` rejects | Existing `tentativeMutation.onError -> onActionError` | Localized alert with backend detail; no optimistic row change. |
| `meetingRequests.rescheduleAccept.failed` | `acceptMeetingReschedule(id)` rejects | Existing `acceptRescheduleMutation.onError -> onActionError` | Localized alert with backend detail; previous/current time rows remain visible. |
| `meetingRequests.rescheduleDecline.failed` | `declineMeetingReschedule(id)` rejects | Existing `declineRescheduleMutation.onError -> onActionError` | Localized alert with backend detail; previous/current time rows remain visible. |
| `meetingRequests.delete.failed` | `deleteMeetingRequest(id)` rejects | Existing `deleteMutation.onError -> onActionError` | Localized alert with backend detail; declined row remains visible. |
| `meetingRequests.duplicateAction` | No exception; user clicks while a mutation is pending | Button disabled/loading state in `MeetingRequestsPage`/card helper | Relevant action controls are disabled or show loading until the mutation settles; duplicate API calls are not sent. |

# Review lenses (pre-answer before gate2-plan)

- **Scope / strategy** — This is the minimum parity cut: keep the working `api/meetingRequests` data/mutation layer, add the old-focal filter/tab UI, and restyle the card. The confirmed calendar filter is included through existing `sharedCalendarId` and `listAccessibleCalendars`; no backend/API handoff is needed.
- **Architecture** — Data enters through two React Query reads: `listMeetingRequests()` and `listAccessibleCalendars()`. All filtering is local, pure, and derived from loaded data. Mutations remain the existing page-owned React Query mutations with the same invalidation path. Stale calendar selection is handled locally; upstream query/mutation failures flow to explicit UI branches.
- **Design** — The visible contract follows old-focal: title/icon/pending badge, search/calendar/type row, status tabs with icons and counts, status-colored cards, reschedule previous-slot row, old empty card, and responsive wrapping. Shell consistency comes from `PageHeader`/`PageToolbar`; no duplicate AI button is added.
- **DevEx** — No new dependency, generated type edit, API wrapper change, shared primitive change, or shell refactor. Tests should use accessible names/roles and API call assertions rather than class snapshots; screenshots cover final light/dark visual parity.

# Risks & migrations

- No database migration, backend/API schema change, generated OpenAPI change, environment variable, package dependency, lockfile change, or data backfill.
- Main risk: exact old-focal desktop/mobile header split differs from shared `PageHeader`. Mitigation: use `PageHeader` first because it is the shell contract; adjust only this page's `rightActions` wrappers if wrapping is off, and do not edit shared shell components.
- Secondary risk: adding the accessible-calendars query introduces a second load/error path. Mitigation: make it non-blocking, keep `all`/`main` usable, and test the warning path.
- Tertiary risk: old-focal hardcoded color classes can drift from shell tokens. Mitigation: use the inherited shell tokens where equivalent, but keep old-focal semantic color intent for yellow pending, green accepted, red declined/cancel, blue tentative/new, and orange reschedule.
- Rollback plan: revert the planned meeting requests page, helper, test, and locale changes. No persisted data or backend behavior changes are introduced.

# Scope check

- [x] Matches the task's Scope and Out of scope.
- [x] Small enough to review in one sitting if implemented in the ordered slices above.
- [x] Size smell checked: the page change is structural because filters/tabs/cards are rebuilt, but it remains contained to one feature component, its helper file, its test file, and locale keys. Calendar filtering is not deferred because the required frontend/API types already exist.

# Out of scope

- Server, schema, migration, API endpoint, generated OpenAPI, package, or lockfile changes.
- Porting old-focal `apiRequest`, `fetchWithAuth`, `CalendarFilterContext`, `useToast`, old routing, or Tailwind-3-era wiring.
- Shared shell, `PageHeader`, `PageToolbar`, sidebar, or global AI-assistant behavior changes.
- Other Focal pages, shared UI primitive changes, new design tokens, or unrelated redesign cleanup.
- Any fake calendar data or hardcoded shared calendar list; the filter must use `listAccessibleCalendars()` and `MeetingRequest.sharedCalendarId`.

# Design — focal-redesign-meeting-requests

Restyle `apps/focal/client/src/features/meetings/MeetingRequestsPage.tsx` in place to old-focal's
`MeetingRequestsPage.tsx` + `MeetingRequestCard.tsx`, keeping the existing `api/meetingRequests`
react-query wiring (accept/decline/tentative/reschedule-accept/reschedule-decline/delete) and
i18next. Filtering helpers go in `features/meetings/requests.ts`. Ships in the worktree
`/Users/allosta/Desktop/wt-focal-meeting-requests` (branch off `feat/focal-redesign-shell`, inherits
the tokens). Contracts read from the main checkout (`apps/old-focal` is untracked).

## 1. Header — shared `PageHeader` (not a bespoke header)

`<PageHeader icon={CalendarClock} title={t('focal.meetingRequests.title')} rightActions={<pending badge>}/>`.
PageHeader already renders the sidebar trigger (`h-8 w-8` from slice 0) + the shared `PageToolbar`
(AI button → `/aichat`), so **no page-local AI button** (old-focal's `AIAssistantHeaderButton` is the
shell toolbar's job here). Pending badge reproduces old-focal exactly (literal, dark-safe):
`<Badge variant="secondary" className="bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400">{t('focal.meetingRequests.pendingBadge',{count})}</Badge>`, shown only when `counts.pending > 0`.
Drop the page's own `<header>` + `<main className="min-h-screen">`; use the shell layout
(`flex h-full flex-col overflow-hidden`, content `overflow-auto`), content width `max-w-4xl`.

## 2. Filter row (`features/meetings/requests.ts` helpers + the page)

Helpers (pure, unit-tested): `REQUEST_TYPE_FILTERS = ['all','new','reschedule','cancel']`,
`RequestTypeFilter`, `CalendarFilterValue = 'all' | 'main' | <id>`, and
`filterMeetingRequests(list, {status,type,calendar,search})`. Semantics (match old-focal):
- **counts** computed from the **full** loaded list (not the filtered view).
- **search** matches `title`, `organizerName`, `organizerEmail` (case-insensitive, trimmed).
- **calendar**: `'main'` ⇒ `sharedCalendarId == null`; an id ⇒ `sharedCalendarId === id`; `'all'` ⇒ no filter.
- **type**: via `requestTypeOf(...)`. `validateCalendarFilter(value, accessibleIds)` → resets a stale id to `'all'`.

Page row (old-focal layout, `flex gap-3 flex-wrap`):
- **Search** `Input` (relative; `Search` icon left; clear `X` ghost button right when non-empty,
  `aria-label` = `focal.meetingRequests.search.clear`), placeholder `focal.meetingRequests.search.placeholder`.
- **Calendar** `Select` (`w-[180px]`, `Calendar` icon): options `all` (`filters.calendar.all`),
  `main` (`filters.calendar.main` — **named key**, no `CalendarFilterContext`), then
  `listAccessibleCalendars()` (key `['shared-calendars','accessible']`) each with a color dot
  (`calendar.color ?? '#3b82f6'`) + `calendar.name`.
- **Type** `Select` (`w-[150px]`): `all` + `new`(Plus, blue) / `reschedule`(RefreshCw, orange) /
  `cancel`(Trash2, red), labels `filters.type.*`.

## 3. Status Tabs (replaces the Button row)

`Tabs value={statusFilter}` with `TabsList` `grid grid-cols-3 sm:grid-cols-5`; triggers
all / pending / accepted / declined / tentative. Icons per old-focal: pending `Inbox`, accepted
`Check`, declined `XCircle`, tentative `HelpCircle` (all none). Each shows a count `Badge` from the
full-list counts; pending badge uses the yellow literal classes. Single `TabsContent` renders the
filtered list (the page already derives `visibleRequests`).

## 4. Request card — exact old-focal `MeetingRequestCard`

Render as a **local subcomponent** in the page file (no new file unless it grows unreviewable); keep
the existing mutation routing (page decides reschedule-accept vs accept by `type`). Reproduce
old-focal **literal** classes (dark-safe — do NOT swap to semantic tokens; this is the explicit
gate-2 color decision):
- Card: `border-l-4` + status border `border-l-{yellow|green|red|blue}-400` (pending/accepted/declined/tentative), `hover:shadow-md transition-shadow`, `CardContent` `p-4`.
- Header: title `font-semibold text-base truncate` + **type badge** `variant="outline"` with
  `requestTypeConfig` colour (`new` blue `bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400` + Calendar icon; `reschedule` orange + RefreshCw; `cancel` red + X) + **status badge**
  `variant="outline"` with `statusColors` (yellow/green/red/blue, each with the `dark:` + border variants from MeetingRequestCard.tsx:44-49).
- Rows: time (`Clock` + range), reschedule "Было" row (`bg-orange-50 dark:bg-orange-950/20`, RefreshCw orange) when `type==='reschedule'` + original times, location (`MapPin`, truncate), organizer (`User`, name + dim `(email)`), description (`line-clamp-2`).
- Footer (`border-t pt-2`): **pending** → green accept (`bg-green-600 hover:bg-green-700`, Check / Loader2 spin) with label by type (`actions.accept.{new|reschedule|cancel}`) + destructive decline (XCircle / Loader2) `actions.decline.{...}` + a **tentative** button for `type==='new'` **only** (`variant="outline"`, `actions.tentative` → `tentativeMutation`) — this preserves the existing wired action (MeetingRequestsPage.tsx:316; not in old-focal's card but it is existing new-app behaviour we must keep, styled to old-focal's button idiom); **declined** → ghost red delete `actions.delete`; **accepted** → green "Добавлено в календарь" badge (`acceptedNote`); **tentative** status → blue badge (`status.tentative`). Per-card `loadingAction` state guards duplicate submits; also disable while any list mutation is pending (`isResponding`).

**Date format:** `date-fns` is **NOT** a dependency of the new client (`apps/focal/client/package.json`)
and must **not** be added (no new dep). Use the existing Intl-based `formatDateTimeRange(locale,
start, end)` from `requests.ts` (already consumed by the page). **Pin** its expected output shape — a
localized weekday + date + `HH:mm – HH:mm` range (ru ≈ "чт, 15 янв. 2026 г., 10:00 – 11:00"; pin the
fixture to a date whose real weekday matches) — and
assert it in a `requests.ts` helper unit test. If the current output diverges materially from
old-focal's intent, tune `formatDateTimeRange` (used only by this feature); still no `date-fns`.

## 5. Empty / loading / error / calendar-warning

- Loading: `focal.meetingRequests.loading`. List error: `errors.load` (role=alert).
- Empty: old-focal CalendarClock Card + hint — if `search.trim()` non-empty and zero rows →
  `focal.meetingRequests.empty.search`; else status-specific `empty.{statusFilter}` (existing keys).
- Calendar-list failure is **non-blocking**: requests still render, `all`/`main` usable, a small
  localized warning (`errors.calendars`) shows. (Failure-mode map in the plan.)
- Keep the existing success/error message banners + mutation `onError` detail alerts.

## 6. New i18n keys (ru + en; ru reproduces old-focal copy)

Under `focal.meetingRequests.`: `search.placeholder` ("Поиск по названию или организатору…"),
`search.clear`; `empty.search` ("Ничего не найдено по вашему запросу") — added alongside the existing
`empty.{status}` keys, matching §5; `filters.calendar.all`
("Все календари"), `filters.calendar.main` ("Личный календарь"), `filters.calendar.label`;
`filters.type.all`/`new`/`reschedule`/`cancel` ("Все типы"/"Создание"/"Изменение"/"Удаление");
`errors.calendars` ("Не удалось загрузить общие календари"). Reuse existing `title`, `status.*`,
`type.*`, `actions.*`, `empty.*`, `emptyHint`, `pendingBadge`, `organizer*`, `location`, `was`,
`acceptedNote`. Both `ru.json` and `en.json` get every new key (no missing-key output).

## 7. Tests (`MeetingRequestsPage.test.tsx` — mock `api/sharedCalendars`)

The plan's 20 tests: header+pending badge (no 2nd AI button); accessible-calendars load + render;
search across title/organizer + clear; type filter; calendar filter incl. `main`; stale-calendar
reset → `all`; status tabs counts + filtering; search-empty vs status-empty; card details; reschedule
"Было"; accepted/tentative/declined footers; accept/decline/tentative/reschedule-accept/
reschedule-decline/delete preserved (+ reschedule routes to reschedule endpoints, not the normal
ones); list-load error; non-blocking calendar warning; mutation-error detail. Assert by role/text,
not class snapshots. Plus helper unit tests for `filterMeetingRequests` + `validateCalendarFilter`.

## 8. Verification + rollback

From the worktree: `cd apps/focal/client && pnpm install --frozen-lockfile && pnpm lint &&
pnpm typecheck && pnpm test:run && pnpm build` (the worktree needs a one-time install — no
node_modules). After slice 1 (helpers + keys only, no consumer) confirm `pnpm lint`+`typecheck` stay
green (gate-2 SC). Visual QA: light + dark vs old-focal — header, filter row, tabs+counts, each card
state (pending/accepted/declined/tentative + reschedule), empty/search-empty. **Rollback** = revert
the meetings page, `requests.ts`, its test, and the added locale keys; no API/behaviour/data change.
Diff scoped to `features/meetings/*` + `i18n/locales/{ru,en}.json`.

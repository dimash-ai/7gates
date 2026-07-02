# Goal

Bring the new Focal **Calendars page** (`superapp/apps/focal/client/src/features/calendars`,
route `/calendars`) to **exact visual parity with old-focal's `pages/Calendars.tsx`** — the
shared-calendars manager from the live screenshots (the accordion calendar card with **«Что
показывается»** filter / **«Участники и их права»** / **«Правила синхронизации с Google»**, the
**«Владелец»** owner badge, the **«Мои календари» / «Доступные мне»** two-section layout, create +
join-by-code) — reproduced on the new stack over the **existing** `api/sharedCalendars.ts`. A slice
of the `focal-redesign-pages` epic; inherits slice-0's old-focal tokens/shell.

> **Binding visual contract** = `superapp/apps/old-focal/client/src/pages/Calendars.tsx` (its
> `CalendarsPage` + nested `CalendarCard`) and the live `focal.allosta.com/calendars` screenshot.
> **Behavioral / data base** = the new app's existing `features/calendars/CalendarsPage.tsx` +
> `api/sharedCalendars.ts` (already wired). The thing being changed is the **presentation** of
> `features/calendars`.

> **Re-skin, not rebuild — and fully backable.** `api/sharedCalendars.ts` already exposes every
> needed call (list mine/accessible, create, update, delete, join, participants list/invite/
> role-update/remove); `GoogleSyncPanel` already exists. The page currently hardcodes
> `filterType: 'all'`, but `SharedCalendarCreate`/`Update` carry `filterType` + `filterValue` +
> `filterRules` (openapi.d.ts), so old-focal's **«Что показывается»** filter editor is **backed** —
> wired from existing fields, **no API change**. **Leave-calendar** = self-removal via the existing
> `removeParticipant` (`DELETE .../participants/{id}`) using the user's own participant id from the
> existing `GET /api/shared-calendars/my-participation` endpoint — a thin frontend-only wrapper
> (`listMyParticipation`) to add, **no server change**. **Copy-invite-code** = clipboard of the
> already-rendered per-participant `inviteCode` (no API call; `SharedCalendarRead` has no
> calendar-level code). The new app already ships the `accordion`, `collapsible`, `select`, `dialog`,
> `popover` shadcn primitives the design needs.

# Scope

- Re-skin `features/calendars/CalendarsPage.tsx` to old-focal `Calendars.tsx`: the page header
  (icon + title + AI button cluster per the shell), the **«Мои календари»** section (create +
  per-calendar **accordion card**: «Что показывается» filter editor, «Участники и их права»
  participants+roles, «Правила синхронизации с Google» = the existing `GoogleSyncPanel`, rename,
  delete, copy invite code, the **«Владелец»** badge), the **join-by-code** control, and the
  **«Доступные мне»** section (role badge, participant count, **leave-calendar** self-removal,
  empty state).
- Wire old-focal's **«Что показывается»** filter editor (all / workTime / personalTime / mission /
  provision) onto the already-backed `filterType`/`filterValue`/`filterRules` fields (replacing the
  hardcoded `'all'`).
- Restyle `GoogleSyncPanel` to old-focal's «Правила синхронизации с Google» look (no behavior change).
- All strings via i18next (`ru` + `en`), reusing old-focal's copy; light **and** dark.

# Out of scope

- Any **server / API / schema / contract** change. The page wires **existing** endpoints (adding only
  thin frontend-only client wrappers, e.g. `listMyParticipation` over the existing
  `GET /api/shared-calendars/my-participation`) + already-present `SharedCalendarCreate/Update` fields.
  A field old-focal shows that the contract lacks → flag as a separate handoff, never faked.
- **Behavior / data-flow** changes — query keys, mutations, invalidation stay; presentation only.
- The **calendar VIEW's** filter behavior (the `/calendar` page's per-calendar show/hide) — that's a
  calendar-slice concern; here we only edit a calendar's stored filter config.
- Google sync **internals** (`GoogleSyncPanel` logic) — restyle only.
- Other left-nav pages (their own slices).

# Acceptance criteria

- [ ] `/calendars` visually matches old-focal `Calendars.tsx` in **light and dark** — accordion
      calendar card (filter / participants / Google-sync sections), owner badge, «Мои календари» /
      «Доступные мне» layout, create + join, empty states — verified by screenshot.
- [ ] Behavior preserved: create / rename / delete / join / participant invite-role-remove all still
      work against `api/sharedCalendars.ts`; the «Что показывается» editor persists `filterType`/
      `filterValue`/`filterRules`; no regressions in `CalendarsPage.test.tsx`.
- [ ] Surgical diff: only `features/calendars/*` (+ any new i18n keys, + a `ui/*` primitive only if
      genuinely missing); **no** server/API change; no `any`; i18next `ru` + `en`.

# Verification commands

```sh
cd superapp/apps/focal/client
pnpm install --frozen-lockfile
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```

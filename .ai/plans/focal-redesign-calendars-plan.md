# Summary

Re-skin the new Focal `/calendars` page in place against the old-focal `Calendars.tsx` visual
contract while preserving the existing shared-calendar data layer. The page keeps using
`api/sharedCalendars.ts` for list/create/update/delete/join/participant mutations, adds only the
thin frontend `listMyParticipation` wrapper over the existing
`GET /api/shared-calendars/my-participation`, and uses the already-present shadcn primitives
(`accordion`, `collapsible`, `select`, `dialog`, `popover`, plus existing cards/buttons/badges).
The one substantive behavior addition is surfacing the backed `filterType`/`filterValue`/
`filterRules` fields through the «Что показывается» editor; no server, schema, or endpoint changes.

# Files to change

| path | change | why |
|------|--------|-----|
| `superapp/apps/focal/client/src/api/sharedCalendars.ts` | modify | Add typed `MyParticipation`/`MyParticipationItem` aliases and `listMyParticipation()` for the existing `/api/shared-calendars/my-participation` route; keep all existing functions and query contract intact. |
| `superapp/apps/focal/client/src/api/sharedCalendars.test.ts` | add | Prove the new wrapper calls the existing route with `GET` and preserves typed `apiFetch` behavior. |
| `superapp/apps/focal/client/src/features/calendars/calendarFilters.ts` | add | Keep the five UI filter options (`all`, `workTime`, `personalTime`, `mission`, `provision`) and payload/display normalization out of JSX; encode them only through backed `filterType`/`filterValue`/`filterRules`. |
| `superapp/apps/focal/client/src/features/calendars/CalendarsPage.tsx` | modify | Re-skin the page layout, create/join controls, owned calendar accordion card, filter editor, participants/roles, copy invite code, accessible calendars, and leave-calendar flow. |
| `superapp/apps/focal/client/src/features/calendars/GoogleSyncPanel.tsx` | modify | Restyle the existing panel to the old-focal «Правила синхронизации с Google» section without changing its Google status/connect/disconnect logic. |
| `superapp/apps/focal/client/src/features/calendars/CalendarsPage.test.tsx` | modify | Update moved-DOM assertions and add coverage for filter persistence, clipboard copy, and leave-calendar. |
| `superapp/apps/focal/client/src/i18n/locales/ru.json` | modify | Add old-focal Russian copy for the new controls, section headings, statuses, clipboard, leave, and filter labels. |
| `superapp/apps/focal/client/src/i18n/locales/en.json` | modify | Add matching English keys for every new Russian key. |

# Implementation slices

1. **Typed client wrapper + filter helpers.** Add `listMyParticipation()` in `api/sharedCalendars.ts`,
   the API wrapper test, and `calendarFilters.ts` with a reversible mapping between UI options and the
   existing fields:
   - `all` -> `filterType: "all"`, no value/rules.
   - `workTime` / `personalTime` -> the old-focal work-time encoding in `filterType`/`filterValue`.
   - `mission` / `provision` -> the old-focal project-type encoding in `filterType`/`filterValue`.
   Unknown existing filter shapes render as a custom/read-only summary and are not overwritten unless
   the user explicitly chooses a supported option. Verify with focused API/helper tests and typecheck.
2. **Old-focal page frame.** Replace the plain centered stack with the inherited page shell/header
   pattern and old-focal two-section layout: create and join controls, «Мои календари», «Доступные
   мне», loading/error/empty states, old-focal card density, light/dark token usage. Keep existing
   create/join mutations and invalidation. Update existing render/join/create tests for the moved DOM.
3. **Owned calendar accordion card.** Convert each owned calendar into the polished collapsible card:
   color dot, calendar name, «Владелец» role badge, rename/delete actions, and the three sections
   «Что показывается», «Участники и их права», «Правила синхронизации с Google». Keep participants
   on the existing `listParticipants` query and keep invite, role update, and remove on existing
   mutations. Verify participant invite/role/remove tests still prove the same API calls.
4. **Filter editor wiring.** Add create/edit filter state and persist changes through existing
   `createCalendar`/`updateCalendar` calls using the normalized payload from `calendarFilters.ts`.
   The editor must update only backed fields (`filterType`, `filterValue`, `filterRules`) and must not
   change unrelated calendar fields. Add tests proving create no longer hardcodes only `'all'` when a
   supported option is selected, and edit persists `filterType`/`filterValue`/`filterRules`.
5. **Copy invite code.** Add the old-focal copy affordance beside pending participant invite codes.
   It calls `navigator.clipboard.writeText(participant.inviteCode)` for the already-rendered
   per-participant code only; there is no calendar-level invite-code API call and no synthetic code.
   Add success/error banners and tests for the clipboard call and denied clipboard path.
6. **Accessible calendars + leave.** Add the `listMyParticipation` query and a leave action on
   accessible calendar cards. Use the approved path: resolve the current user's participation for the
   calendar from existing frontend data and call existing `removeParticipant(calendarId, participantId)`;
   invalidate `['shared-calendars']`, participants, and my-participation keys on success. If the
   generated `MyParticipationRead` type still lacks a participant id at build time, resolve the current
   user's row through the already-existing `listParticipants(calendarId)` call and authenticated user id;
   do not add or change a server/API route. Add tests proving leave calls `removeParticipant` with the
   current user's participant id and refreshes the accessible list.
7. **Google sync restyle + visual pass.** Restyle `GoogleSyncPanel` inside the third accordion section,
   preserving current status/connect/disconnect behavior. Run the full client checks and verify
   `/calendars` screenshots in light and dark against old-focal: card sections, owner badge, create/join,
   empty states, responsive wrapping, and no overlapping text.

# Tests

- `superapp/apps/focal/client/src/api/sharedCalendars.test.ts`
  - `listMyParticipation` calls `GET /api/shared-calendars/my-participation`; proves leave-calendar uses
    the existing endpoint through the frontend wrapper only.
- `superapp/apps/focal/client/src/features/calendars/CalendarsPage.test.tsx`
  - Renders owned and accessible calendars after the re-skin; proves the old data queries still populate
    the moved layout and role badge.
  - Joins by trimmed invite code; proves the join mutation and success message survived the layout move.
  - Creates a calendar with a selected supported filter option; proves `filterType`/`filterValue`/
    `filterRules` are sent from UI state instead of a hardcoded `'all'`.
  - Edits an existing calendar filter in «Что показывается»; proves `updateCalendar` persists only the
    backed filter fields plus intentional name/color changes.
  - Shows participants, pending invite codes, and invites a participant; proves existing participant
    query and invite mutation still work in the accordion section.
  - Changes a participant role; proves the shadcn select still calls `updateParticipantRole` with the
    same calendar and participant ids.
  - Copies a pending invite code; proves clipboard copy uses the rendered per-participant `inviteCode`
    and no API call.
  - Handles clipboard rejection; proves the user sees a localized error and the page does not crash.
  - Leaves an accessible calendar; proves `listMyParticipation`/existing participant data resolve the
    current user's participant id, `removeParticipant` is called, and shared-calendar queries invalidate.
  - Handles missing self-participation; proves no delete is attempted and a localized error is shown.
- Manual/visual verification after implementation:
  - `cd superapp/apps/focal/client && pnpm install --frozen-lockfile`
  - `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`
  - Run the app and screenshot `/calendars` in light and dark; compare against old-focal for the
    accordion card, «Мои календари» / «Доступные мне», owner badge, create/join, empty/loading/error
    states, and Google section.

# Error & rescue map

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| `CalendarsLoadFailed` | `listMyCalendars` or `listAccessibleCalendars` rejects through React Query | Page query `isError` branches | Localized calendar load error in the affected section; other already-loaded sections remain visible. |
| `ParticipantsLoadFailed` | `listParticipants(calendarId)` rejects | Participants accordion query `isError` branch | Localized participants load error inside «Участники и их права»; card actions outside that section remain usable. |
| `SaveMutationFailed` | `createCalendar`, `updateCalendar`, `deleteCalendar`, `joinByInviteCode`, `inviteParticipant`, `updateParticipantRole`, or `removeParticipant` rejects | Shared mutation `onError` handler | Localized save error banner with backend detail when available. |
| `MyParticipationLoadFailed` | `listMyParticipation` rejects | My-participation query `isError` branch and leave handler guard | Leave controls are disabled or show a localized leave-unavailable error; accessible calendars still render from `listAccessibleCalendars`. |
| `SelfParticipationMissing` | Leave handler cannot resolve the current user's participant id for the target calendar | Leave handler before calling `removeParticipant` | Localized error banner; no delete request is sent. |
| `ClipboardUnavailable` | `navigator.clipboard` is missing or `writeText` rejects | Copy invite code handler `try/catch` | Localized clipboard error banner; the invite code remains visible for manual copying. |
| `UnsupportedFilterShape` | Existing calendar has a `filterType`/`filterValue` combination outside the five supported UI options | `calendarFilters.ts` normalization | Read-only custom summary for the current value; no filter fields are overwritten until the user chooses a supported option. |
| `GoogleStatusLoadFailed` | `getGoogleStatus(calendarId)` rejects | `GoogleSyncPanel` query error branch | Localized Google sync status error inside «Правила синхронизации с Google»; calendar management stays usable. |

# Review lenses (pre-answer before gate2-plan)

- **Scope / strategy** — This is the minimum viable change for the task: re-skin `features/calendars`
  over the existing `api/sharedCalendars.ts`, add only the named `listMyParticipation` wrapper, wire the
  already-backed filter fields, and reuse existing shadcn primitives. The decision is reversible because
  it does not alter server contracts, generated schemas, migrations, query keys, or Google sync logic.
- **Architecture** — Data flow stays React Query + existing mutations. New state is local UI state for
  dialogs, accordion sections, selected filter options, banners, and clipboard/leave actions. Query
  invalidation remains under `['shared-calendars']` plus participants/my-participation keys. Unhappy
  paths are explicit: failed queries render section-local errors, failed mutations use the shared banner,
  missing self-participation blocks the delete call, and unsupported filter shapes are displayed without
  destructive normalization.
- **Design** — Match old-focal card density and section names while using the new app's tokens so light
  and dark themes both work. Use shadcn dialog/select/accordion/collapsible semantics for keyboard
  behavior. Empty, loading, error, pending invite, connected/disconnected Google, owner, accessible, and
  responsive wrapping states are all part of the implementation, not follow-up work.
- **DevEx** — No new UI primitive, package, server route, schema, or abstraction layer. `calendarFilters.ts`
  is the only helper because it prevents JSX from owning contract encoding and gives tests a stable place
  to verify filter payloads. The next developer should be able to trace every changed line to old-focal
  parity, backed filter editing, copy invite code, or leave-calendar.

# Risks & migrations

- No database migrations, data backfills, config changes, package installs, or server/API changes.
- Main risk: local generated `MyParticipationRead` must expose enough data to resolve self-removal as
  assumed by the approved think doc. Rescue stays frontend-only and contract-safe: use
  `listMyParticipation` for the leave surface and the existing participants endpoint/current user id to
  resolve the participant id if needed; if neither existing source can resolve it, block leave with
  `SelfParticipationMissing` and flag a separate contract handoff rather than changing the API in this
  slice.
- Rollback plan: revert the frontend files above; because no server/schema migration is made, rollback is
  a client-only revert.

# Scope check

- [x] Matches the task's Scope and Out of scope.
- [x] Small enough to review in one sitting, but the build should land in the implementation slices above
      so the large visual diff stays reviewable.
- [x] Size smell addressed: this touches the calendars feature, two locale files, one API wrapper, and
      tests. The API file is included only because the task explicitly names `listMyParticipation`; no
      new services, routes, primitives, or packages are added.

# Out of scope

- Server, API, OpenAPI schema, database, RBAC, or migration changes.
- Calendar event filtering behavior on the `/calendar` view; this slice only edits a shared calendar's
  stored filter configuration.
- Google sync internals beyond styling `GoogleSyncPanel` in the old-focal section.
- Calendar-level invite-code generation or any fake invite code; copy uses only rendered participant
  `inviteCode` values.
- New shadcn primitives or package installs; required primitives already exist.
- Other left-nav pages or unrelated redesign work.

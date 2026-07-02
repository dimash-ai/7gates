# Design summary

Re-skin `features/calendars` in place to old-focal `pages/Calendars.tsx`, preserving the existing
`api/sharedCalendars.ts` data layer. Three decisions everything hinges on:

1. **«Что показывается» ships full 6-type parity** (not the plan's reduced 3). old-focal's filter is
   `all` · `isWorkTime`(true/false) · `sphere`(name) · `project`/`product`(project id) ·
   `projectType`(mission/provision) (`apps/old-focal/.../Calendars.tsx:575-593,954-959`). All are
   **backed** — `SharedCalendarCreate/Update` carry `filterType`/`filterValue`/`filterRules`, and the
   new app already exposes `listSpheres()` + `listProjects()` (split by `parentProjectId` → projects vs
   products, exactly as old-focal). This **ratifies the gate-2 reviewer's Should-Consider #1 toward
   full parity** — the binding mandate is *exact* old-focal and nothing here is unbacked, so the
   page fetches spheres + projects for the sphere/project/product sub-selects rather than degrading the
   editor. The plan's `calendarFilters.ts` helper architecture is **preserved and extended** to all 6,
   not contradicted.
2. **Leave-calendar resolves the self participant id from `listParticipants(calendarId)` + the auth
   `user.id`**, then calls the existing `removeParticipant(calendarId, selfId)`. `listMyParticipation()`
   (the thin wrapper) supplies the *leave-surface scoping* on accessible cards (which calendars I'm in +
   my role), **not** the id (gate-2 reviewer #2: `MyParticipationRead` carries no participant-row id).
   The backend self-removal branch (`role != "owner" and participant.user_id != user_id`) enforces it.
3. **Copy invite code = `navigator.clipboard.writeText(participant.inviteCode)`** on the already-rendered
   per-participant pending code — no API call, no calendar-level code (none on `SharedCalendarRead`).

No server / API / schema / migration change. Inherits slice-0 tokens; light + dark; i18next ru+en.

# Architecture

Single page, in place; data flow stays React Query + the existing mutations.

```
CalendarsPage  (features/calendars/CalendarsPage.tsx — re-skinned)
├─ <header>  bespoke desktop-one-row / mobile-two-row (SidebarTrigger via useSidebarOptional
│            + icon + title «Календари» + subtitle + AI button + PageToolbar)   ← matches old-focal 613-649
├─ banners (status/alert)  — existing message/errorMessage state
├─ grid lg:grid-cols-2
│   ├─ «Мои календари» section
│   │   ├─ Create control  (name + «Что показывается» FilterEditor + color → createCalendar)
│   │   └─ owned[] → CalendarCard (Accordion-based)
│   │        • color dot · name · «Владелец» Badge · rename · delete (Trash)
│   │        • Accordion (collapsible, multi-open) with 3 items:
│   │            – «Что показывается»  → FilterEditor (read current + edit → updateCalendar)
│   │            – «Участники и их права» → participants (listParticipants) + role Select
│   │                 + remove + copy-invite-code; invite form (email + role → inviteParticipant)
│   │            – «Правила синхронизации с Google» → <GoogleSyncPanel> (restyled, logic unchanged)
│   └─ «Доступные мне» section
│        accessible[] → card (color · name · role Badge · participant count · «Покинуть» leave)
├─ helper: features/calendars/calendarFilters.ts   (pure; the filterType/value contract encoder)
└─ api: sharedCalendars.ts gains listMyParticipation() over GET /my-participation (thin wrapper)
```

Queries (all existing endpoints): `listMyCalendars`, `listAccessibleCalendars`,
`listParticipants(selectedId)`, **`listMyParticipation`** (new wrapper), **`listSpheres`**,
**`listProjects`** (the last two only to populate/resolve the sphere/project/product filter
sub-selects). **«Доступные мне»** = `listAccessibleCalendars()` **filtered to `userId !== user.id`**
(the accessible endpoint also returns owned calendars — `AccessibleSharedCalendarRead.userId` exists —
so owned are excluded here, exactly as old-focal splits `Calendars.tsx:596-597`); a «Покинуть» action
shows only where `listMyParticipation().participatingCalendars` has a matching `!isOwner` entry.
Invalidation stays under `['shared-calendars']` + participants + a new
`['shared-calendars','my-participation']` key. New local UI state: open accordion sections, the
create/edit filter `{type,value}`, dialogs, banners — no new global/context state.

# Data model

| entity | change | notes |
|--------|--------|-------|
| (none) | none   | No persistent state added. Re-skin wires **existing** `filterType`/`filterValue`/`filterRules` columns (already on `SharedCalendarCreate/Update/Read`) — no schema/migration. |

# Interfaces & contracts

**`api/sharedCalendars.ts`** — add only:
```ts
// Real generated shape (openapi.d.ts): NOT a flat calendar list.
//   MyParticipationRead  = { participatingCalendars: MyParticipationItem[]; isOnlyParticipant: boolean; ownCalendarsCount: number }
//   MyParticipationItem  = { calendar: SharedCalendarRead; role: string; isOwner: boolean }   // ← carries NO participant-row id
export type MyParticipation = Schemas['MyParticipationRead']
export const listMyParticipation = (): Promise<MyParticipation> =>
  apiFetch<MyParticipation>('/api/shared-calendars/my-participation')   // GET, existing route
```
All existing functions/signatures unchanged. Because `MyParticipationItem` has **no participant-row id**,
the leave id is still resolved from `listParticipants(calendarId)` + the auth `user.id`; `participatingCalendars`
(filtered to `!isOwner`) only scopes **which** accessible cards expose a «Покинуть» action.

**`features/calendars/calendarFilters.ts`** (new, pure — keeps contract encoding out of JSX). The draft
is a **discriminated union** so a stored filter outside the six is represented as-is and **never
normalized**:
```ts
export type FilterType = 'all' | 'isWorkTime' | 'sphere' | 'project' | 'product' | 'projectType'
export type FilterDraft =
  | { kind: 'supported'; filterType: FilterType; filterValue: string }       // '' for 'all'
  | { kind: 'unsupported'; rawType: string | null; rawValue: string | null } // stored shape ∉ the 6 — read-only, preserved
// stored calendar → editor draft; returns 'unsupported' when c.filterType is not one of the 6
export const fromCalendar = (c: SharedCalendar): FilterDraft
// UI → backed payload (only filterType/filterValue; never name/color/isActive). NULL for 'unsupported' → NO write.
export const toFilterPayload = (d: FilterDraft): Pick<SharedCalendarUpdate,'filterType'|'filterValue'> | null
// human label for the collapsed summary, resolving sphere/project names from fetched lists (raw value for 'unsupported')
export const filterDisplay = (c: SharedCalendar, ctx: { spheres: Sphere[]; projects: Project[] }, t): string
// default filterValue when switching to a supported type: all→'' · isWorkTime→'true' · projectType→'mission' · else ''
export const defaultValueForType = (t: FilterType): string
```
A calendar whose stored `filterType` is outside the six round-trips through `fromCalendar → 'unsupported'`,
renders a **read-only** custom summary, and `toFilterPayload` returns `null` so it is **never overwritten**
until the user explicitly picks a supported type (which sets `kind:'supported'`).
Encoding table (mirrors old-focal exactly):

| UI type | filterType | filterValue | sub-select source |
|--------|-----------|-------------|-------------------|
| all | `all` | `''` | — (no value control) |
| isWorkTime | `isWorkTime` | `'true'` \| `'false'` | static work/personal |
| sphere | `sphere` | `sphere.name` | `listSpheres()` |
| project | `project` | `project.id` | `listProjects()`, `!parentProjectId` |
| product | `product` | `project.id` | `listProjects()`, `parentProjectId` |
| projectType | `projectType` | `'mission'` \| `'provision'` | static mission/provision |

`filterRules` is passed through untouched (read-modify-write preserves it); the editor only sets
`filterType`/`filterValue`, so an unknown stored shape is **displayed, never silently rewritten**
unless the user picks a supported type.

# Flow (happy + unhappy paths)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| happy — create with filter | submit create with a chosen filter type/value | `createMutation` → `toFilterPayload` | `createCalendar({name,color,filterType,filterValue,...})` sends real fields, not hardcoded `'all'`; list invalidates |
| happy — edit filter | change «Что показывается» on an owned card | `updateMutation` | `updateCalendar(id,{filterType,filterValue})` (+ name/color only if changed); summary re-resolves |
| happy — invite / role / remove | participant controls | existing mutations | unchanged behavior, restyled |
| happy — copy code | click copy beside a pending invite | copy handler | `clipboard.writeText(participant.inviteCode)`; success banner; **no API** |
| happy — leave | «Покинуть» on an accessible card | leave handler | resolve self id = `listParticipants(id).find(p=>p.userId===user.id)`, then `removeParticipant(id, selfId)`; invalidate accessible + participants + my-participation |
| unhappy — calendars load fail | `listMyCalendars`/`listAccessible` reject | query `isError` | section-local localized error; other sections still render |
| unhappy — participants load fail | `listParticipants` rejects | accordion query `isError` | error inside «Участники»; rest of card usable |
| unhappy — mutation fail | any create/update/delete/join/invite/role/remove reject | shared `onError` | localized banner with backend detail |
| unhappy — self id missing | leave can't find own row | leave handler guard (before delete) | localized error; **no** delete sent |
| unhappy — clipboard blocked | `clipboard` absent / `writeText` rejects | copy `try/catch` | localized error; code stays visible to copy manually |
| unhappy — unsupported filter shape | stored `filterType`/value outside the 6 | `calendarFilters.filterDisplay` | read-only summary of the raw value; not overwritten until user picks a supported type |
| unhappy — spheres/projects load fail | `listSpheres`/`listProjects` reject | their query branches | sphere/project/product sub-selects show a hint (like old-focal's "create spheres first"); other types still selectable |

# Alternatives rejected

- **Ship only 3 filter types (the plan's 5-option set).** Rejected: `sphere`/`project`/`product` are
  backed (existing `listSpheres`/`listProjects` + the `filterValue` field) and the mandate is *exact*
  old-focal; degrading the page's central control is a visible parity miss. Full parity costs only two
  already-app-wide queries.
- **Wholesale port of old-focal `Calendars.tsx` + `CalendarCard`.** Rejected (think doc option B): drags
  Tailwind-3/React-18 idioms + old-focal's `apiRequest`/Wouter data layer; large non-surgical diff.
- **A server self-leave endpoint.** Rejected: the existing `DELETE participants/{id}` already permits
  self-removal (backend branch + test); no API change needed.
- **`listProducts(projectId)` for the product sub-select.** Rejected in favor of splitting `listProjects()`
  by `parentProjectId` — one query, exactly old-focal's approach (`Calendars.tsx:999,1019`).

# Test strategy

Vitest + Testing Library (component) and a focused api-wrapper unit — the levels the risky paths need:
- **`calendarFilters.ts` unit** — `toFilterPayload`/`fromCalendar` round-trip for all 6 types; `'all'`→empty
  value; unknown shape preserved. Proves the contract encoder is reversible and non-destructive.
- **`sharedCalendars.test.ts`** — `listMyParticipation` GETs the existing `/my-participation` route. Proves
  leave-scoping uses the existing endpoint via the wrapper only.
- **`CalendarsPage.test.tsx`** — re-skinned render (owned+accessible, owner badge); create sends real
  `filterType`/`filterValue` (not hardcoded `'all'`); edit persists only backed filter fields; invite/role/
  remove still call the same APIs; copy uses the rendered `inviteCode` with no API; clipboard-reject shows a
  localized error; leave resolves self id via `listParticipants`+`user.id` and calls `removeParticipant`;
  missing-self blocks the delete. Each asserts the **API call/shape**, not backend behavior.
- **Verified before ship** = `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green + a manual
  light/dark screenshot pass of `/calendars` against old-focal (accordion card, 3 sections, owner badge,
  «Мои» / «Доступные», create/join, empty/loading/error states).

# Security & release notes

- **Authz unchanged** — the client only surfaces controls; the backend RBAC (`require_role`) + the
  self-removal branch enforce every write. Leave can only remove the **caller's own** row (backend
  rejects removing others unless owner). No new privileged surface.
- **Clipboard** runs on a user gesture; copies only an already-displayed invite code. No secrets, no
  injection surface (no `dangerouslySetInnerHTML`, no eval, no URL building from user input).
- **No** new endpoint/SSRF/rate-limit surface; no migration. **Rollback = client-only revert** of the
  listed frontend files (no server/schema change).

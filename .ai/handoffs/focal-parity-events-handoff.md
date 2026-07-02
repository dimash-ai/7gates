# Stage

3-gate · slice 5 of the `focal-parity` epic: **Events editor parity**. Branch
`feat/focal-parity-events` → base `feature/focal-migration` (one commit). Frontend-only; no
server / API / schema / migration change.

# What changed

The Events page used the calendar grid's lightweight `EventPopover` to create/edit, which could only
set title/date/time/recurrence/color/links. This slice adds a full feature-local **`EventDialog`**
(presentational modal; the page keeps owning mutations + the recurring-scope dialog) that brings the
editor to old-focal parity: **description, location, status (planned/confirmed), per-event timezone,
tags (multi + inline create), recurrence + end date, project→product→activity, color, free-text other
participants**, and the CRM `ContactPicker` (UI-only). All fields already exist on the backend
`EventCreate`/`EventUpdate` contract, so this only wires them up.

- `EventDialog.tsx` (new) — the full modal; `canEdit`-gated, `calendarId`-scoped; never closes on a
  save error.
- `TimezoneSelector` — gained a backward-compatible **controlled mode** (`value`/`onValueChange`) for
  the per-event timezone; it never mutates the user's global display-timezone preference.
- `eventsFilters.ts` — `createDraft`/`editDraft`/`createPayload`/`updatePatch` carry the new fields
  (create: when set + always `status`; update: only when dirty); `editDraft` normalizes legacy
  name-tags → ids; `contactIds` is never persisted (CRM stays UI-only pending the crm-boundary ADR).
- `EventsPage.tsx` swaps `EventPopover` → `EventDialog`; `EventPopover`/the calendar grid is unchanged.
- ru + en locale keys for every new label.

# Files touched

- `apps/focal/client/src/features/events/EventDialog.tsx` (new)
- `apps/focal/client/src/features/events/eventsFilters.ts`, `eventsFilters.test.ts`
- `apps/focal/client/src/features/events/EventsPage.tsx`, `EventsPage.test.tsx`
- `apps/focal/client/src/features/calendar/EventPopover.tsx` (extend `EventDraft` only)
- `apps/focal/client/src/components/TimezoneSelector.tsx`, `TimezoneSelector.test.tsx`
- `apps/focal/client/src/i18n/locales/en.json`, `ru.json`

# Tests run

```sh
cd apps/focal/client
pnpm typecheck   # 0 errors
pnpm lint        # biome: 0 errors
pnpm test:run    # 78 files, 938 tests passed
pnpm build       # production build ✓
```

# Verification output

```sh
$ pnpm test:run
 Test Files  78 passed (78)
      Tests  938 passed (938)
$ pnpm build
✓ built in ~260ms
```

# Still needs review

- **Frontend-only** — no schema/migration. Client scoping is not security; slice-2 backend RBAC + RLS
  enforce shared-calendar writes.
- Out of scope (future): custom-recurrence intervals (needs a backend field) and CRM contact
  persistence (the crm-boundary ADR's `external_contacts`). Read-only of the two picker buttons relies
  on `<fieldset disabled>`; a passthrough `disabled` prop is a possible later hardening.

# PR / release notes (for users)

Creating or editing an event now opens a full editor: add a **description and location**, mark it
**planned or confirmed**, set the event's **own timezone**, attach **tags** (or create a tag inline),
set **recurrence** and an end date, link it to a **project / product / activity**, pick a **color**,
and note **participants**. (Choosing an event's timezone no longer changes your app-wide display
timezone.) When you're viewing a calendar shared with you read-only, the editor opens but every field
is locked.

(No secrets, tokens, keys, or PII in this change — client components, a React modal, locale strings,
and tests.)

# Status

OPUS VERIFY/RELEASE-GATE APPROVED (9.4). Gate-A design APPROVED 9.4 · Gate-B build APPROVED 9.1.
Cleared for release. Remaining: open the PR into `feature/focal-migration`.

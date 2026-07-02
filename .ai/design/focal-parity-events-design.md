# Combined design — focal-parity slice 5 (Events editor parity)

3-gate A artifact (folds think + plan + design). The builder (gate B) and verifier (gate C) work
from this alone.

---

## Problem & decision

The new Events page (`features/events/EventsPage.tsx`) is at full parity for its **list, grouping,
filters, search, orphan/priority selects, persistence, and add/edit/delete + recurring-scope** — but
its create/edit surface reuses the **calendar grid's lightweight `EventPopover`**, which only edits
`title · date · start/end · recurrence · recurrenceEndDate · color · completed · project/product/
activity`. Against old-focal `components/EventDialog.tsx` the editor is missing: **description,
location, status (planned/confirmed), event timezone, tags (+ inline create), and persisted
"other participants"**. So an event created here can never carry notes, a place, a confirmed status,
a non-default timezone, tags, or named participants.

**Decision.** Add a feature-local **`EventDialog`** (a full modal, mirroring old-focal `EventDialog`
and the slice-4 `TaskDialog` pattern) and have the Events page use it instead of `EventPopover` for
create/edit. The calendar grid keeps `EventPopover` untouched (its richer editor is slice 6). The
shared `EventDraft` type + the `createPayload`/`updatePatch` encoders (`eventsFilters.ts`) gain the
missing fields; `EventPopover` simply doesn't surface them, so the calendar path is unchanged.

**Frontend-only — confirmed.** The backend `EventCreate`/`EventUpdate`/`EventRead`
(`api/openapi.d.ts`) **already carry** `description, location, status, timezone, otherParticipants,
tags, contactIds, recurrenceEndDate, recurrenceExceptions`. No model/migration handoff is needed —
this slice only wires existing contract fields into a richer editor. (Slice 2's data-scope writes
through the same `createEvent`/`updateEvent(calendarId)` wrappers, so the calendar scope-invariant
already covers these payloads server-side.)

**Main alternative rejected.** Expanding `EventPopover` itself to hold all fields — rejected: it
bloats the compact anchored grid popover and couples slice 5 to the calendar editor (slice 6). A
separate modal is what old-focal ships and what slice 4 established.

## Assumptions & scope

- Assumption (confirmed — openapi): `description/location/status/timezone/otherParticipants/tags/
  contactIds/recurrenceEndDate/recurrenceExceptions` all exist on `EventCreate`/`EventUpdate`; this
  slice is frontend-only.
- Assumption (confirmed — slice 2): `EventsPage` already consumes `canEdit`/`currentCalendarId`; the
  dialog must early-return on `!canEdit`, disable controls, and thread `calendarId` through every call.
- Assumption (confirmed — slice 3): the timezone foundation (`useTimezone`, `TimezoneSelector`,
  `lib/timezone.ts`) exists. **`TimezoneSelector` is currently bound to the GLOBAL `displayTimezone`**
  (`setDisplayTimezone`, no controlled props), so the per-event timezone field must NOT reuse it
  as-is — it would mutate the user's display preference. The fix (see Architecture) is a small
  backward-compatible **controlled-mode extension** to `TimezoneSelector`.
- Assumption (confirmed — slice 4): CRM participants are **UI-only** pending the crm-boundary ADR —
  the `ContactPicker` renders but `contactIds` is **not** persisted; the free-text **`otherParticipants`
  DOES persist** (full parity for that field). Tags persist.
- Out of scope: **custom-recurrence intervals** (old-focal's `recurrence:'custom'` with interval+unit) —
  the new schema has only the enum `none|daily|weekly|monthly|yearly` + `recurrenceEndDate`; an
  interval needs a backend field → a **future handoff**, not this slice (mirrors slice 4 deferring this
  exact gap). The calendar grid editor (slice 6), `EventInfoDialog` copy/convert-to-task (a calendar
  detail surface, slice 6), AI-assistant, offline.
- Open questions: None (schema confirmed; CRM/custom-recurrence decisions inherited from slice 4).

## Success criteria

- [ ] Events page create/edit opens a full `EventDialog` with: title, date, start/end time,
      description, location, status (planned/confirmed), event timezone, tags (multi + inline create),
      recurrence + recurrence-end, project→product→activity cascade, color, free-text other
      participants, and the CRM `ContactPicker` (UI-only).
- [ ] Saving persists the new fields (description/location/status/timezone/tags/otherParticipants) via
      `createEvent`/`updateEvent`; editing preserves untouched fields (exact-patch contract).
- [ ] All writes are `canEdit`-gated (no API call when read-only) and `calendarId`-scoped; the list,
      filters, recurring-scope dialog, and delete keep working unchanged.
- [ ] ru + en locale keys for every new label; client `lint · typecheck · test:run · build` green;
      surgical diff (no calendar-grid behavior change).

## Build approach (slices)

| # | slice | files | main failure mode | what its test proves |
|---|-------|-------|-------------------|----------------------|
| 5.1 | Draft + encoders | `features/calendar/EventPopover.tsx` (extend `EventDraft` with optional `description/location/status/timezone/tags/otherParticipants`), `features/events/eventsFilters.ts` (`createDraft`/`editDraft`/`createPayload`/`updatePatch` carry the new fields), `eventsFilters` test | wrong-key drop (`extra=ignore` silently swallows a typo); update sends a field the user didn't touch | create payload includes set fields + omits unset; update patches only dirty fields; editDraft round-trips an event's description/location/status/tz/tags/otherParticipants |
| 5.2 | `EventDialog` + controlled tz | `features/events/EventDialog.tsx` (new), `components/TimezoneSelector.tsx` (backward-compatible controlled-mode extension) + its test, ru/en locales | blank title; save reject closes dialog losing input; **an event-tz pick mutating the global display preference**; tag-create reject | required-title guard blocks submit; dialog stays open on save error with draft intact; status/tz/tags/description/location/otherParticipants render + edit; **picking an event timezone updates the draft, NOT `displayTimezone`**; `canEdit=false` disables all controls |
| 5.3 | Page wiring | `features/events/EventsPage.tsx` (swap `EventPopover`→`EventDialog`; keep filters/rows/delete/scope), `EventsPage.test.tsx` | calendarId not threaded → 403 in shared mode; recurring edit skips scope dialog | open create/edit via dialog; payload carries new fields + `calendarId`; recurring edit still routes through `RecurringScopeDialog`; `!canEdit` fires no write |

Each slice leaves the client green and is committed separately (gate B reviews each).

## Architecture & contracts

```
EventsPage (consumes useCalendarFilter→canEdit/currentCalendarId, useTimezone→displayTimezone)
 ├─ eventsFilters.ts  (pure: filters + createDraft/editDraft/createPayload/updatePatch  ← extended)
 ├─ EventDialog (PRESENTATIONAL modal; all fields; project→product→activity; tags+inline; controlled
 │     TimezoneSelector; ContactPicker UI-only) — emits onPatch/onSave/onDelete, makes NO API calls
 │  EventsPage OWNS the mutations (createEvent/updateEvent(calendarId)) + the recurring-scope routing,
 │  exactly as it does today with EventPopover (handleSave → RecurringScopeDialog for recurring edits)
 └─ RecurringScopeDialog (unchanged), list/rows/delete (unchanged)
Calendar grid keeps EventPopover (unchanged — shares the extended EventDraft but surfaces only basics)
```

| entity / interface | change | notes |
|--------------------|--------|-------|
| `EventDraft` (calendar/EventPopover.tsx) | extend | add optional `description?, location?, status?, timezone?, tags?: string[], otherParticipants?` — `EventPopover` ignores them; the calendar create path is unchanged |
| `eventsFilters.createDraft/editDraft` | extend | seed/round-trip the new fields (`status` default `'planned'`, `tags` `[]`) |
| `eventsFilters.createPayload/updatePatch` | extend | send `description/location/status/timezone/tags/otherParticipants` (create: include when set; update: only when dirty) |
| `EventDialog.tsx` | add | **presentational** full modal (callbacks only — the page owns mutations); reuses shadcn `Dialog/Input/Textarea/Select`, the controlled `TimezoneSelector` for per-event tz, the tag picker + inline `createTag`, `ContactPicker` (UI-only) |
| `components/TimezoneSelector.tsx` | extend (backward-compatible) | add optional controlled `value?: string \| null` + `onValueChange?: (tz: string) => void`. When BOTH provided → **controlled per-event mode**: it reads/writes those props and **never** touches `displayTimezone`/`setDisplayTimezone`. When absent → unchanged global-display-tz control (slice-3 behavior). Reuses the existing popular-zones list + Cyrillic-transliteration search |
| `eventsFilters.editDraft` | extend | round-trips the new fields; **normalizes `event.tags` → ids via the existing `normalizeEventTags`** so a legacy name-tagged event edits correctly |
| data model | None | no schema/migration — all fields exist on the backend contract |
| i18n `focal.events.dialog.*` | add | ru + en labels (description/location/status/timezone/participants/tags) |

## Flow (happy + unhappy)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| happy create | Add → dialog → save | `EventDialog` → `createEvent(payload, calId)` | new event with all fields; invalidate `['events']`; dialog closes |
| happy edit | row pencil → dialog → save | `updateEvent(id, patch, target, calId)` | exact-patch update; recurring → `RecurringScopeDialog` first |
| read-only | `!canEdit` (shared calendar) | dialog handlers `if(!canEdit) return` + disabled controls | no write fires; fields render read-only |
| blank title | empty title on save | dialog submit guard | localized "title required"; no API call |
| save reject | `createEvent`/`updateEvent` rejects (`ApiError`) | mutation `onError` | localized error; dialog stays open; draft kept |
| tag-create reject | `createTag` rejects | inline mutation `onError` | localized inline error; dialog stays open |
| invalid event timezone | a bad IANA value | `TimezoneSelector` (validated, slice 3) | falls back; stored event tz unchanged |
| options load fail | projects/activities/tags query rejects | existing panel/dialog branch | localized notice; dialog still usable for the core fields |

## Test strategy, security & rollback

- Test strategy — **Unit** (`eventsFilters.test.ts`): createPayload includes set new fields + omits
  unset; updatePatch sends only dirty fields incl. the new ones; editDraft round-trips
  description/location/status/timezone/otherParticipants **and normalizes legacy name-tags → ids**.
  **Controlled `TimezoneSelector`** (`TimezoneSelector.test.tsx`): in controlled mode a pick calls
  `onValueChange` and does **not** call `setDisplayTimezone`; uncontrolled mode still drives the
  global preference (no regression). **Component** (`EventsPage.test.tsx`): open create/edit dialog,
  the payload carries the new fields + `calendarId`, `canEdit=false` gates every write, recurring edit
  routes through the scope dialog, save-error keeps the dialog open, inline tag-create. "Verified" =
  client `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green.
- Security — client scoping is **not** security; slice-2 backend RBAC + the calendar scope-invariant
  enforce shared-calendar writes server-side. `otherParticipants` is free text (rendered as text, no
  HTML injection surface). No secrets/PII in code, tests, or PR text.
- Rollback — frontend-only: revert the slice's client files; no migration, no data change.

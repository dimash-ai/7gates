# Combined design — focal-parity slice 7 (Habits parity)

3-gate A artifact (folds think + plan + design). Frontend-only; the builder (gate B) and verifier
(gate C) work from this alone.

---

## Problem & decision

The new Habits feature has the page, charts, week-cell tracking, archive, and chevron reorder, but
against old-focal it is missing, per the audit: **editing a habit** (`HabitCreateDialog` is
create-only — name/type/color/frequency only), **per-day notes**, **recommended-habit presets**, the
**category / description / project-link** fields, **explicit Yes/No/Skip/Erase** entry buttons, and a
**delete confirmation**. Every one of these is backed by the existing API — confirmed:
`HabitCreate`/`HabitUpdate` carry `description, color, type, category, frequency, targetDaysPerWeek,
projectId`; `HabitEntryUpsert`/`HabitEntryRead` carry `note`; `updateHabit`, `deleteHabit`,
`upsertEntry`, `deleteEntry`, `reorderHabits` all exist in `api/habits.ts`. So this slice is
**frontend-only** — wire the missing fields/affordances into the existing dialog + journal.

**Decision.** (1) Turn `HabitCreateDialog` into a unified **create/edit** dialog (accept an optional
`habit`; submit routes to `updateHabit` when editing, `createHabit` when not) and add the
category select, description input, project-link select, and a recommended-habits preset row.
(2) In `HabitJournal`, add a per-habit expand panel with a **note** textarea (persisted via
`upsertEntry`'s `note`), **explicit Yes/No/Skip/Erase** buttons for the selected day, and a
**delete-confirmation** `AlertDialog`. All `canEdit`-gated and `calendarId`-scoped (slice-2 contract).

**Out of scope / rejected:** **true drag-reorder via dnd-kit** — old-focal used dnd-kit grip handles,
but the new app already reorders functionally via up/down chevrons; adding dnd-kit is a new dependency
for a cosmetic interaction change. Keep the chevrons; note the drag affordance as a later optional
hardening (the reorder *function* is at parity). Also out: category-filter badge row beyond what the
journal needs, AI assistant, offline.

## Assumptions & scope

- Assumption (confirmed — openapi): habit category/description/projectId + entry note all exist; no
  schema/migration needed.
- Assumption (confirmed — slice 2): `HabitsPage`/`api/habits.ts` already thread `canEdit` +
  `currentCalendarId`; the new dialog/journal affordances consume them (disable + early-return on
  `!canEdit`; `calendarId` on every call).
- Assumption (confirmed — source): `HabitCreateDialog` is create-only today; `HabitJournal` cycles a
  week cell none→yes→no→skip and reorders via chevrons, with no expand/notes/explicit-button panel.
- Out of scope: dnd-kit drag-reorder, category global-filter UI, AI, offline.
- Open questions: None.

## Success criteria

- [ ] The habit dialog edits an existing habit (name/type/color/frequency/targetDays + **category,
      description, project link**) and creates with the same fields; a **recommended-presets** row
      prefills name+type(+category) on click.
- [ ] The journal lets a user set an explicit **Yes / No / Skip / Erase** state for the selected day
      and write a **note** (persisted), and deleting a habit asks for confirmation first.
- [ ] All writes are `canEdit`-gated (no API call when read-only) and `calendarId`-scoped; charts,
      archive, streaks, and existing week-cell cycling keep working.
- [ ] ru + en keys for every new label; client `lint · typecheck · test:run · build` green; surgical.

## Build approach (slices)

| # | slice | files | main failure mode | what its test proves |
|---|-------|-------|-------------------|----------------------|
| 7.1 | Create/edit dialog + fields + edit trigger | `features/habits/HabitCreateDialog.tsx` (→ create/edit; +category/description/project/presets), `HabitJournal.tsx` (row **Edit** button → `onEditHabit(habit)`), `HabitsPage.tsx` (holds `editTarget`; `onEditHabit` opens the dialog with that habit; clears on close), ru/en | edit submits a create (duplicates); preset overwrites a half-typed habit silently; project list 403 in shared mode; edit button has no path to the dialog | clicking a row's Edit opens the dialog pre-filled and save calls `updateHabit(id,…)` with the new fields; creating calls `createHabit`; a preset prefills name/type/category; `canEdit=false` disables the Edit button + submit; reference list gated by `canViewOtherPages` |
| 7.2 | Journal notes + explicit states + delete-confirm | `features/habits/HabitJournal.tsx`, ru/en | erasing fires the wrong status; note lost on collapse; delete with no confirm | Yes/No/Skip/Erase call `upsertEntry`/`deleteEntry` with the right status; a note round-trips via `upsertEntry.note`; delete opens an `AlertDialog` and only deletes on confirm; `!canEdit` disables all |
| 7.3 | tests + i18n sweep | `HabitsPage.test.tsx` / new `HabitJournal.test.tsx`, locales | — | the above behaviors covered; ru/en parity |

## Architecture & contracts

```
HabitsPage (consumes canEdit/currentCalendarId; owns `dialogOpen` + `editTarget: Habit|null`)
 ├─ HabitCreateDialog (create OR edit; name/type/color/frequency/targetDays + category/description/
 │     project + recommended presets) → createHabit/updateHabit(calendarId)
 └─ HabitJournal (rows: existing week cells + a NEW per-row Edit button → onEditHabit(habit) up to
       HabitsPage, which sets editTarget + opens the dialog; per-habit expand: note textarea,
       Yes/No/Skip/Erase buttons, delete-confirm AlertDialog) → upsertEntry/deleteEntry/deleteHabit(calId)
All via existing api/habits wrappers (already accept calendarId). No new deps; no schema change.
```
The habit rows live in `HabitJournal`, so the **edit entry point is there**: a row Edit button calls
the new `onEditHabit(habit: Habit)` prop, `HabitsPage` stores it in `editTarget` and opens
`HabitCreateDialog` with `habit={editTarget}`. Closing the dialog clears `editTarget`.

| entity / interface | change | notes |
|--------------------|--------|-------|
| `HabitCreateDialog` | create→create/edit | optional `habit?: Habit`; preloads fields when editing; submit → `updateHabit` else `createHabit`; adds `category` (select of old-focal's set), `description` (Input), `projectId` (select via `listProjects(calendarId)`, gated by `canViewOtherPages`), recommended presets row |
| `HabitJournal` | add expand panel + edit trigger | per-row **Edit** button → `onEditHabit(habit)`; expand panel: note textarea, explicit Yes/No/Skip/Erase, delete-confirm `AlertDialog` (shadcn `alert-dialog`) wrapping `deleteHabit`. **Note rule:** `upsertEntry` carries both `status`+`note`, so the panel reads the day's existing entry and sends them together — saving a note preserves the current status and vice versa; a note saved with no prior status records a neutral `status:'skip'`. Erase = `deleteEntry`. |
| recommended presets | add (client const) | old-focal's 8 chips, each `{nameKey, type, category}`: Workout (positive/sport), Drink water (positive/health), Gym (positive/sport), Meditation (positive/mind), No soda (negative/food), No alcohol (negative/food), Running (positive/sport), Reading (positive/mind); a click prefills name+type+category and leaves color/frequency at defaults (does not submit) |
| data model | None | all fields/endpoints exist; no migration |
| i18n `focal.habits.dialog.*` / `journal.*` / `categories.*` / `presets.*` | add | ru + en |

## Flow (happy + unhappy)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| happy edit | row edit → dialog → save | `HabitCreateDialog` → `updateHabit(id, …, calId)` | invalidate `['habits']`; dialog closes |
| happy note | expand → type note → save | `HabitJournal` → `upsertEntry({…, note}, calId)` | note persisted; entry status preserved |
| happy explicit state | Yes/No/Skip → button | `upsertEntry({status}, calId)`; Erase → `deleteEntry(calId)` | cell + streak update |
| read-only | `!canEdit` | every handler early-returns + disabled UI | no write fires; data still renders |
| save/entry/delete reject | mutation rejects (`ApiError`) | mutation `onError` | localized error; dialog/panel stays open; no optimistic overwrite |
| project list fails | `listProjects` rejects | dialog branch | localized notice; the other fields still save |
| delete confirm | trash → AlertDialog | confirm/cancel | only deletes on confirm |

## Test strategy, security & rollback

- Test strategy — **Component** (`HabitsPage.test.tsx` extend + `HabitJournal.test.tsx` new):
  editing calls `updateHabit` with category/description/projectId; creating calls `createHabit`; a
  preset prefills; Yes/No/Skip/Erase send the right `upsertEntry`/`deleteEntry`; a note round-trips;
  delete requires the AlertDialog confirm; `canEdit=false` fires no write; `calendarId` threaded.
  "Verified" = client `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green.
- Security — client scoping is not security (slice-2 RBAC/RLS authoritative); the note is free text
  rendered as text (no HTML sink). No secrets/PII.
- Rollback — frontend-only: revert the slice's client files; no migration, no data change.

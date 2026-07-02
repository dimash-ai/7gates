# Design: focal-parity-calendar-buttons

3-gate flow · Slice A of the calendar create/year follow-up. Branch `feat/focal-parity-calendar-buttons`
→ base `feature/focal-migration`. **Frontend-only** — reuses existing components, mutations, and the
existing `EventCreate` contract; no server/API/schema/migration, no new dependency.

## Problem & decision

Old-focal's calendar gave two prominent left-rail create buttons — **«Новое событие»** (opening the
full event dialog: title, participants-from-CRM, start/end, event timezone, location, project, tags,
repeat) and **«Новая задача»** (the full task dialog). The migrated calendar dropped both: today an
event is created only by clicking a grid slot (which opens the *lean* `EventPopover`), and a task only
on the `/tasks` page. The user wants the old-focal buttons back, while **keeping** the lean grid-click
popover.

**Decision.** Add the two buttons to the calendar's left rail and wire them to the **already-built full
dialogs**: «Новое событие» opens `EventDialog` (`features/events/EventDialog.tsx` — the Events-page full
editor, every old-focal field) in create mode; «Новая задача» opens `TaskDialog`
(`features/tasks/TaskDialog.tsx`) in create mode. The grid-click → lean `EventPopover` path is left
untouched. This is pure reuse: both dialogs and CalendarPage's create wiring already exist.

**Alternatives rejected.**
- *Button opens the lean `EventPopover` anchored to the button* (cheapest). Rejected: the user asked for
  the **full** old-focal dialog (location/timezone/tags/participants); the popover surfaces none of
  those. `EventsPage` itself uses the full `EventDialog` for its "Add" button — matching it is the
  consistent choice.
- *Build a new shared `EventCreateButton`/`useEventEditor` hook used by both EventsPage and CalendarPage*
  (DRYest). Rejected for this slice: refactoring the working EventsPage create flow is out of scope and
  adds blast radius; CalendarPage already owns equivalent wiring, so the button reuses it directly.
- *Place the buttons in the `PageHeader` (always visible, like EventsPage's Add)*. Rejected: the user
  showed and asked for old-focal's **left-rail** placement. (Mobile, where the rail is hidden, is handled
  under Scope.)

## Assumptions & scope
- Assumption (confirmed): `EventDialog` uses the same `EventDraft` type and a **compatible, near-identical
  superset** of `EventPopover`'s props (it adds `errorMessage`, omits `anchor`) — presentational/
  parent-driven (`EventDialog.tsx:27,38-56,67-82`). So CalendarPage's existing
  `draft`/`patchDraft`/`participants`/`handleSave`/mutations drive it as-is (no `anchor` needed — it's a
  centered modal).
- Assumption (confirmed): the full `createPayload`/`createDraft` in `eventsFilters.ts:337-399` persist
  the optional fields (description, location, timezone, tags, otherParticipants, status) and
  `EventCreate` accepts them — EventsPage persists them and its tests assert
  `location`/`timezone`/`otherParticipants` in the payload (`EventsPage.test.tsx`). **→ frontend-only.**
- Assumption (confirmed): CalendarPage's local `createDraft`/`createPayload` (`CalendarPage.tsx:109-150`)
  are exact **subsets** of the `eventsFilters` versions; for a lean (grid-popover) draft the full
  `createPayload` emits a byte-identical payload (every optional spread is a no-op; `status` defaults to
  `'planned'`). So swapping the calendar's create helpers to the shared ones does not change the existing
  popover-create behavior or its tests.
- Assumption (confirmed): `TaskDialog` is self-contained (owns its create mutation, ContactPicker, tags);
  create mode = `task={null}` (`TaskDialog.tsx:131-345,353-355`; trigger pattern `TasksPage.tsx:375-376`).
- Assumption (confirmed): **the two buttons gate on different permissions.** Events are the calendar
  write domain → gate on `canEdit`. **Tasks are the OTHER_PAGES write domain**, and OTHER_PAGES *write*
  is **owner/full_access only** — a `developer` is other-pages read-only, an `editor` can't view other
  pages at all (`server/app/data_scope.py:14-16,56`; `create_task` uses that `_owner_write` gate,
  `server/app/api/tasks.py:36-43`). The frontend equivalent is **`canEdit && canViewOtherPages`** (=
  owner/full_access, plus the own/owned calendar which grants both — `CalendarFilterContext.tsx:178-179,205-206`).
  Gating on `canEdit` alone (lets in `editor`) or `canViewOtherPages` alone (lets in `developer`) would
  each open a dialog that can only 403 on save.
- Assumption (confirmed): CalendarPage's create save has **no blank-title guard** today — the guard lives
  only in `EventsPage` (`EventsPage.tsx:307-310`; `CalendarPage.tsx:296-300` posts unguarded). This slice
  adds the guard to CalendarPage's create path so the new full dialog (and the existing popover) never
  POST an empty title.
- Assumption (confirmed): CRM participants (`ContactPicker` → PRIMA via `primaContacts.ts`) are **UI-only**
  on both dialogs today — the link is not persisted pending the crm-boundary `external_contacts` field
  (`CalendarPage.tsx:212-215`, `TaskDialog.tsx:151-154`). This slice does not change that.
- Out of scope: the grid-click lean `EventPopover` (unchanged); the popover **edit** path and its lean
  `editDraft`/`updatePatch` (kept as-is — `eventsFilters.editDraft` needs a tags query the calendar edit
  path doesn't load); a **mobile** entry point (the rail is `hidden lg:block`; mobile create stays via
  grid-tap — a FAB is a later follow-up); the **year view** (Slice B, its own design); persisting CRM
  contact links.
- Open questions: None.

## Success criteria
- [ ] A **«Новое событие»** button in the calendar left rail opens `EventDialog` in create mode (all
  fields present: location, event timezone, tags, participants).
- [ ] Saving from that dialog with a location/timezone/tag set calls `createEvent` with those fields in
  the payload (not dropped), then closes and refreshes the calendar.
- [ ] A **«Новая задача»** button in the left rail opens `TaskDialog` in create mode; saving creates a
  task and closes.
- [ ] The **event** button is disabled when the user can't edit the calendar (`!canEdit`); the **task**
  button is disabled unless the user can write other-pages data (`canEdit && canViewOtherPages`, =
  owner/full_access) — a shared-calendar `editor` *and* a `developer` both see «Новое событие» but **not**
  «Новая задача».
- [ ] Saving the event dialog with a **blank title** shows a required-title error and makes **no**
  `createEvent` call.
- [ ] Grid-click still opens the **lean** `EventPopover` (no regression); existing calendar tests stay
  green.
- [ ] `pnpm typecheck`, `pnpm lint`, `pnpm test:run`, `pnpm build` all pass; new EN keys have RU
  counterparts; diff confined to `features/calendar/*` + i18n + tests.

## Build approach (slices)

| # | slice | files | main failure mode | what its test proves |
|---|-------|-------|-------------------|----------------------|
| 1 | «Новая задача» button → `TaskDialog` create | `CalendarPage.tsx`, `i18n/locales/{en,ru}.json`, `CalendarPage.test.tsx` | wrong gate → opens a dialog that 403s on save | button gates on **`canEdit && canViewOtherPages`** (owner/full_access only — for an `editor` and a `developer` the button is shown but **disabled**); click opens the create `TaskDialog` (`dialog-task`); fill+save calls `createTask` |
| 2 | «Новое событие» button → `EventDialog` create surface | `CalendarPage.tsx`, `i18n/locales/{en,ru}.json`, `CalendarPage.test.tsx` | full fields silently dropped; blank title posted; grid popover regressed | button opens `EventDialog` (`dialog-event`); save with a set `location`/`tag` calls `createEvent` **with** them; blank title → no call + error; grid-click still opens the lean `EventPopover` |

Each step leaves the tree green and is independently revertible.

## Architecture & contracts

CalendarPage gains one discriminator on its existing editor state — which **surface** a create uses —
plus a boolean for the task dialog. Everything else (draft, dirty, participants, mutations, error,
`RecurringScopeDialog`) is reused unchanged.

```
left rail (CalendarPage.tsx:461) ── «Новое событие» → openCreateDialog()  → editor={surface:'dialog'} → <EventDialog mode="create" .../>
                                 └─ «Новая задача»   → setTaskDialogOpen(true)                          → <TaskDialog task={null} .../>
grid slot click (TimeGrid) ─────── openCreate(date,hour,anchor) → editor={surface:'popover'} ───────── → <EventPopover mode="create" .../>   (UNCHANGED)
all event creates ─── handleSave → createMutation.mutate( createPayload(draft) )  // shared full payload, identical for the lean popover draft
```

| entity / interface | change | notes |
|--------------------|--------|-------|
| `EventCreate` / API / DB | **None** | full field set already supported (EventsPage persists it) |
| `CalendarPage` editor state | extend to a discriminated union `{surface:'popover'; mode; event; anchor} \| {surface:'dialog'; mode:'create'; event:null}` | grid keeps `'popover'`; the button uses `'dialog'` (no anchor — `EventDialog` is a centered modal) |
| `CalendarPage` create helpers | replace local lean `createDraft`+`createPayload` with the shared `eventsFilters` ones (import) | output-identical for the popover path; removes duplication (reuse-first). `editDraft`/`updatePatch` (edit path) stay local — out of scope |
| `CalendarPage` new handlers/state | add `openCreateDialog()` and `const [taskDialogOpen,setTaskDialogOpen]=useState(false)` | `openCreateDialog` guards `!canEdit`, seeds `createDraft(todayIso, 9)` (09:00 default, matches old-focal + EventsPage) |
| **permission gating** | event button `disabled={!canEdit}`; task button `disabled={!(canEdit && canViewOtherPages)}` | OTHER_PAGES write = owner/full_access; pass `canEdit={canEdit && canViewOtherPages}` into `TaskDialog`. A `developer` (other-pages *read* only) and an `editor` are both correctly excluded |
| **create title guard** | add `if (mode==='create' && !draft.title.trim()) { setErrorMessage(titleRequired); return }` to `handleSave` | covers the new dialog **and** the existing popover; mirrors `EventsPage.tsx:307-310` |
| `EventDialog`, `TaskDialog` | **reused as-is** | imported into CalendarPage; no change to either component |
| keyboard-shortcut guard | also no-op while `taskDialogOpen` (dialog surface already covered by the editor state) | prevents `d/m/w` switching the view behind an open task modal |
| i18n | add `focal.calendar.newEvent`, `focal.calendar.newTask`, `focal.calendar.errors.titleRequired` (ru+en) | reuse if an equivalent key already exists; no hardcoded strings |

## Flow (happy + unhappy)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| happy — new event | click «Новое событие» | `openCreateDialog` → `EventDialog` create | full dialog opens; save → `createEvent(full payload)` → invalidate `['events']` → closes |
| happy — new task | click «Новая задача» | `setTaskDialogOpen(true)` → `TaskDialog` | create dialog opens; save → `createTask` → invalidate `['tasks']` → closes |
| happy — grid create (unchanged) | click a grid slot | `openCreate` → `EventPopover` | lean popover as today |
| empty — blank title | save with empty title from `EventDialog` | **new** `handleSave` create-title guard (mirrors EventsPage) | no `createEvent` call; required-title error shown in the dialog |
| upstream — createEvent rejects | API 4xx/5xx | `createMutation.onError` → `errorMessage` | localized error shown inside `EventDialog` (it takes `errorMessage`); dialog stays open |
| upstream — createTask rejects | API error | `TaskDialog`'s own `saveMutation.onError` | `TaskDialog` shows its own form error; stays open |
| edge — restricted role | event needs `canEdit`; task needs `canEdit && canViewOtherPages` | each button `disabled` on its own gate; `openCreateDialog` early-returns on `!canEdit` | the disallowed surface never opens — a shared `editor` (and a `developer`) get event-create but not task-create |
| edge — recurring scope | N/A on create | — | create never triggers `RecurringScopeDialog` (recurring scope is edit/delete only) |

## Test strategy, security & rollback
- Test strategy (Vitest + Testing Library, the calendar/events suites' existing pattern):
  - **Step 1** — render CalendarPage, click «Новая задача», assert the `dialog-task` create dialog
    appears, then fill a title + save and assert `createTask` is called (the save path, not just open).
    Assert the task button is gated on **`canEdit && canViewOtherPages`**: for both a shared-calendar
    `editor` (`canEdit:true, canViewOtherPages:false`) and a `developer` (`canEdit:false,
    canViewOtherPages:true`) the «Новая задача» button is rendered but **disabled**; an owner/own calendar
    has it enabled. Also assert the «Новое событие» button is **disabled** when `!canEdit` (a calendar
    viewer) — both buttons are shown-but-disabled (not hidden) for consistent, discoverable affordances.
  - **Step 2** — click «Новое событие», assert `dialog-event` opens in create mode; fill title + location
    + an event timezone (+ a tag), save, assert `createEvent` was called with `location`, `timezone`, and
    `tags` present in the payload — the regression guard against the lean-payload drop. Assert saving with
    a **blank title** makes no `createEvent` call and shows the required-title error. Separately assert a
    grid-slot click still opens the lean `EventPopover` (not `EventDialog`).
  - "Verified" = `pnpm typecheck && pnpm lint && pnpm test:run && pnpm build` green, plus a manual smoke
    (desktop ≥lg): both buttons open their dialog, a created event/task appears.
- Security: none new. No new endpoint, query, or secret; the same `createEvent`/`createTask` mutations and
  the same `canEdit` gating. Client gating is UX, not the tenant boundary — the slice-2 RBAC/RLS layer
  remains the authority. CRM contacts stay UI-only (no new cross-app data path).
- Rollback: revert `CalendarPage.tsx`, the i18n additions, and the test delta. No migration, no data, no
  config — instant revert.

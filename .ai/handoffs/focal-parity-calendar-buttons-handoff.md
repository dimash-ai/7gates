# Stage

3-gate flow · **Slice A complete** (Gate A design APPROVED 9.1 · Gate B build APPROVED 9.4 + 9.4 · Gate
C verify APPROVED 9.4). Branch `feat/focal-parity-calendar-buttons` → base `feature/focal-migration`.
Frontend-only; no server/API/schema/migration, no new dependency.

# What changed

Two prominent left-rail create buttons on the Focal calendar (old-focal parity), reusing the existing
dialogs end-to-end:
- **«Новое событие»** (primary) → the full `EventDialog` (the Events-page editor) in create mode — every
  old-focal field (title, participants from PRIMA CRM / other, start & end, event timezone, location,
  project→product→activity, tags, repeat).
- **«Новая задача»** → the existing self-contained `TaskDialog` in create mode.
- The grid-click lean `EventPopover` is **unchanged**.
- A **blank-title guard** on create now covers both the popover and the full dialog.
- CalendarPage's local lean `createDraft`/`createPayload` were swapped for the shared
  `../events/eventsFilters` ones (output-identical for the lean popover draft; the full dialog's optional
  fields — location/timezone/tags/other-participants — now persist).
- **Permission gates:** the event button is gated on `canEdit`; the task button on
  `canEdit && canViewOtherPages` (tasks are the OTHER_PAGES write domain = owner/full_access).

# Files touched
- `apps/focal/client/src/features/calendar/CalendarPage.tsx`
- `apps/focal/client/src/features/calendar/CalendarPage.test.tsx`
- `apps/focal/client/src/i18n/locales/en.json`
- `apps/focal/client/src/i18n/locales/ru.json`

# Tests run
```sh
cd apps/focal/client
pnpm typecheck   # PASS (tsc -b)
pnpm lint        # PASS (biome, 298 files)
pnpm test:run    # PASS (92 files, 1072 tests)
pnpm build       # PASS (only the pre-existing >500 kB chunk-size warning)
```

# Verification output
```sh
 Test Files  92 passed (92)
      Tests  1072 passed (1072)
✓ built in ~0.3s
```
Gate-C verify (GPT doer + fresh-context Opus reviewer) independently confirmed: permission gates resolve
to exactly {owner, full_access} for tasks and {owner, full_access, editor} for events against the real
`CalendarFilterContext`; the full dialog's optional fields persist through the shared `createPayload`; no
production-code defect; suite green.

# Still needs review
- Frontend-only: no write path beyond the existing `createEvent`/`createTask` mutations + the
  `canEdit`/`canViewOtherPages` gating. Client gating is UX — the slice-2 RBAC/RLS layer is the boundary.
  CRM participants stay UI-only (the contact link awaits the crm-boundary `external_contacts` field).
- Mobile: the left rail is `hidden lg:block`, so the buttons are desktop-only; create on mobile remains via
  grid-tap (a mobile FAB is a deliberate follow-up, out of scope here).

# PR / release notes (for users — stage 5)

Adds the two prominent left-sidebar create buttons from old Focal to the migrated calendar.

**What you can now do**
- **New event** (primary button) — opens the full event form: title, participants (from PRIMA CRM or
  free-text), start & end time, event timezone, location, project, tags, and repeat.
- **New task** — opens the task form (title, due date/time, project, tags, notes, participants).
- Clicking an empty time slot still opens the quick event popover, unchanged.

The **New task** button appears only when you can create tasks on the current calendar (your own, or a
shared calendar where you're owner / full-access) and is disabled otherwise. Saving with an empty title is
blocked with a clear message.

Frontend-only — reuses the existing event/task dialogs and the shared create payload; no backend, schema,
or dependency change. (No secrets, tokens, keys, or PII in this text.)

# Status
3-GATE C VERIFY APPROVED (Opus 9.4). Cleared to ship — open the PR.

# Stage

3-Gate flow — Gate C (verify), release gate. Feature `focal-parity-calendar-event-actions`.

# What changed

Adds two of old-focal's `EventInfoDialog` quick-actions to the new app's event popover:

- **B1 — status:** a `Planned / Confirmed` select in the edit popover, seeded from the event, persisted
  through the existing save path (`updateEvent`, dirty-gated, scope-dialog-aware for recurring events);
  the block restyles to the chosen variant. Reuses the Events dialog's `STATUS_OPTIONS` + `focal.events.status.*` labels.
- **B2 — duplicate:** a Duplicate action that creates a standalone copy of the event through `createEvent`
  — a dedicated `duplicatePayload` copies every copyable field and **strips recurrence** (a copy is a
  single event, per old-focal). A synchronous `duplicatingRef` guard prevents a same-render double-click
  from issuing two creates.

`convert-to-task` is intentionally deferred to the task-panel feature (it owns both convert directions).
The GPT verify pass found and the build fixed a real **double-create race** (the `isPending` guard was a
render snapshot; replaced with the synchronous ref guard).

# Files touched

- `apps/focal/client/src/features/calendar/EventPopover.tsx` — status select + Duplicate button (edit mode, read-only gated).
- `apps/focal/client/src/features/calendar/CalendarPage.tsx` — `editDraft` seeds status; `updatePatch` sends status when dirty; `handleDuplicate` (ref-guarded) + `onDuplicate` wiring.
- `apps/focal/client/src/features/events/eventsFilters.ts` — `duplicatePayload(event)` (full-field, recurrence-stripped).
- `apps/focal/client/src/i18n/locales/{en,ru}.json` — `focal.calendar.edit.duplicate`.
- `apps/focal/client/src/features/{calendar/CalendarPage,events/eventsFilters}.test.tsx` — coverage.

# Tests run

```sh
cd superapp-parity/apps/focal/client
pnpm typecheck   # tsc -b: 0 errors
pnpm lint        # biome: 309 files, clean
pnpm test:run    # 99 files, 1184 tests passed
pnpm build       # production build OK
```

# Verification output

```sh
Test Files  99 passed (99)
     Tests  1184 passed (1184)
✓ built
```

Gate A (design) APPROVED 9.5 · Gate B APPROVED 9.0 (after a stale-base false positive + double-create + recurrence-field fixes) · Gate C (verify) APPROVED 9.5 (double-create race found + fixed).

# Still needs review

- None blocking. `convert-to-task` and a one-click no-open status pill are deferred follow-ups.

# PR / release notes (for users — stage 5)

Events get two quick actions back, right in the event popover:

- **Set a status** — Planned or Confirmed — and the event restyles to match.
- **Duplicate** an event in one click — the copy keeps all its details, and a repeating event copies as a
  single standalone event.
- Both respect read-only shared calendars (the controls are disabled there).

No secrets, tokens, keys, or PII in this text or the diff.

# Status

OPUS APPROVED (9.5) — release gate cleared.

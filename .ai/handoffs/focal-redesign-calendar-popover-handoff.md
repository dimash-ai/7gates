# Stage

Stage 7 (ship) — **slice 2 of the `focal-redesign-calendar` epic**: the event create/edit popover.
Replaces the calendar's inline forms with a Google-Calendar-style popover + a recurring-scope dialog,
preserving the existing event create/edit/delete + recurrence-scope behaviour.

# What changed

- **`EventPopover.tsx`** (new) — a Radix-`Popover` event editor anchored (via `PopoverAnchor` +
  virtual ref) to the clicked slot/event: title, date + start/end time, a **mark-as-done** toggle
  (→ the real `completed` field, never `status:"done"`), the **goal-map** Project → Product →
  Activity selects (dependent queries: products load only after a project, activities after a
  product), recurrence, a **colour** swatch row, and the existing `ContactPicker`. Save / Delete in
  the footer.
- **`RecurringScopeDialog.tsx`** (new) — a Radix-`Dialog` "this event / this and following / all"
  chooser, shown when saving or deleting a **recurring** event; the choice drives the mutation's
  `{ scope, occurrenceDate }`.
- **`CalendarPage.tsx`** — the always-visible create card and the conditional edit card are gone;
  clicking an empty slot opens the **create** popover (prefilled with that time), clicking an event
  opens the **edit** popover. Mutations take an explicit per-operation recurrence target (no stale
  page-level scope). Payload contract preserved: create sends the legacy core fields + the optional
  ones only when set; update always sends the five core fields and `completed`/`colour`/link-ids only
  when the user changed them (auto-cleared child links are sent as `null`).
- **`EventBlock.tsx`** — `onSelect` now passes the clicked element + rect so the edit popover anchors
  to it. **`ui/popover.tsx`** — exports `PopoverAnchor`.
- **i18n** — added `focal.calendar.popover.*` and `focal.calendar.scopeDialog.*` keys (en + ru).
- **Tests** — `CalendarPage.test.tsx` rewritten to drive the popover + dialog while preserving every
  create/update/delete + `{scope,occurrenceDate}` payload assertion, plus new coverage: mark-done on
  create **and** update, dependent link loading + ids in the payload, no-projects empty state,
  scope-dialog **cancel** keeps the popover, **double-click OK** fires once, **activity gating**,
  **cleared links → `null` in the patch**, **mutation failure** keeps the popover + shows the alert,
  and **outside-click** dismiss. `EventBlock.test.tsx` updated for the new `onSelect` signature.

# Files touched

- `apps/focal/client/src/features/calendar/EventPopover.tsx` (new)
- `apps/focal/client/src/features/calendar/RecurringScopeDialog.tsx` (new)
- `apps/focal/client/src/features/calendar/CalendarPage.tsx` (rewired off the inline forms)
- `apps/focal/client/src/features/calendar/EventBlock.tsx` (onSelect anchor)
- `apps/focal/client/src/components/ui/popover.tsx` (export `PopoverAnchor`)
- `apps/focal/client/src/features/calendar/{CalendarPage,EventBlock}.test.tsx`
- `apps/focal/client/src/i18n/locales/{en,ru}.json` (`popover.*` + `scopeDialog.*`)

# Tests run

```sh
cd superapp/apps/focal/client
pnpm lint        # biome — 0 errors
pnpm typecheck   # tsc -b — 0 errors
pnpm test:run    # vitest — 47 files, 336 passed
pnpm build       # tsc -b && vite build — OK
```

# Verification output

```sh
 Test Files  47 passed (47)
      Tests  336 passed (336)
# calendar subset: 6 files, 56 tests passed · lint/typecheck/build EXIT 0
```

# Still needs review

- **Not yet committed.** The slice is in the working tree (the two new components staged, the rest
  modified). Per `apps/focal/CLAUDE.md` ("one task = one slice branch = one PR"), it should land via a
  `feat/focal-calendar-popover` branch → PR into `feature/focal-migration`. Awaiting the go to commit.
- **Two real defects were caught + fixed during review** (kept here for transparency): a recurring
  scope-dialog **double-submit** (fixed by clearing `pendingOp` synchronously on confirm) and a nested
  Radix **popover-dismiss on dialog focus-out** that lost the staged edit on cancel (fixed via
  `onFocusOutside` preventDefault + the `!pendingOp` close guard). Both are now regression-tested.
- **Visual evidence:** light/dark screenshots not captured (the calendar is behind the Supabase auth
  gate; a fresh preview context has no session). The running local app (`localhost:5173/calendar`)
  reflects the change via HMR for a manual eyeball.

# PR / release notes (for users — stage 5)

Creating and editing calendar events now happens in a focused **Google-Calendar-style popover**:

- **click an empty time slot** to add an event, or **click an existing event** to edit it — no more
  always-on form taking up the page;
- set the time, give it a **colour**, **mark it done**, and link it to a **project / product /
  activity** from your goal map;
- editing or deleting a **repeating** event asks whether to change **this event, this and following,
  or all** — just like Google Calendar;
- everything you could do before still works exactly the same — only the editing surface changed.

_(Contains no secrets, tokens, keys, or PII.)_

# Status

CODEX APPROVED (9.2) — all 7 gates cleared (think 9.1 · plan 9.3 · design 9.2 · build 9.3 ·
review 9.4 · test 9.5 · ship 9.2). Cleared for release; awaiting the go to commit.

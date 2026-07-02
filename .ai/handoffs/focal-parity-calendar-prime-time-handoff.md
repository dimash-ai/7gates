# Stage

3-Gate flow — Gate C (verify), release gate. Feature `focal-parity-calendar-prime-time`.

# What changed

Restores old-focal's **prime-time ("golden hours")** on the calendar:

- **B1 — band overlay:** the day / 3-day / week time grid paints a gold band over the user's
  golden-hours window (read from settings), behind events, inert to pointers, only where there's a time
  axis (not month/year).
- **B2 — golden-hours dialog:** a "Golden hours" control opens a dialog to set the window (from / to) or
  turn it off, reusing the existing settings rules and `updateSettings`. It edits the signed-in user's
  own settings, so it's available on read-only shared calendars too.

The GPT verify pass found and the build fixed **two self-data-loss races**: opening the dialog before
settings loaded could seed a null window and clear it on save (now the control waits for
`settings.isSuccess`); and an invalidate-then-refetch window could let a reopened dialog clear a
just-saved window (now the success path writes the server response straight into the `['settings']`
cache with `setQueryData`, no refetch window).

# Files touched

- `apps/focal/client/src/features/calendar/TimeGrid.tsx` — band overlay per day column (geometry, z-order, pointer-events).
- `apps/focal/client/src/features/calendar/CalendarPage.tsx` — settings query; pass window to the grid; toolbar control (gated on `settings.isSuccess`) + dialog mount.
- `apps/focal/client/src/features/calendar/PrimeTimeDialog.tsx` — the set/clear dialog (reuses `settings.ts` rules + `updateSettings`; `setQueryData` on success).
- `apps/focal/client/src/i18n/locales/{en,ru}.json` — `focal.calendar.primeTime.*` strings.
- `apps/focal/client/src/features/calendar/{TimeGrid,CalendarPage,PrimeTimeDialog}.test.tsx` — unit + integration coverage.

# Tests run

```sh
cd superapp-parity/apps/focal/client
pnpm typecheck   # tsc -b: 0 errors
pnpm lint        # biome: 309 files, clean
pnpm test:run    # 99 files, 1173 tests passed
pnpm build       # production build OK
```

# Verification output

```sh
Test Files  99 passed (99)
     Tests  1173 passed (1173)
✓ built
```

Gate A (design) APPROVED 9.4 · Gate B B1 APPROVED 9.1, B2 APPROVED 9.0 · Gate C (verify) APPROVED 9.4 (two data-loss races found + fixed across three verify rounds).

# Still needs review

- None blocking. The prime-time band shows the **current user's** window on every calendar; per-owner
  prime-time on a shared calendar (old-focal's `effectiveUserId`) needs a backend param and is out of
  scope for this frontend slice.

# PR / release notes (for users — stage 5)

Your calendar now shows your **golden hours** again:

- The day, 3-day, and week views highlight your most-productive window with a soft gold band.
- A **Golden hours** button opens a dialog to set the window (from / to) or switch it off — it applies to
  your own calendar view, so it works even when you're viewing a shared calendar.
- Changes apply immediately; if a save fails you keep the dialog and a message, and nothing is lost.

No secrets, tokens, keys, or PII in this text or the diff.

# Status

OPUS APPROVED (9.4) — release gate cleared.

# Stage

Stage 7 (ship) — **slice 1 of the `focal-redesign-calendar` epic**: the week time-grid foundation.
Restyles the Focal calendar's week view to the Google-Calendar / Allosta-prototype look and extracts
the reusable event block + lane layout every later calendar slice builds on, with **no behavior
change**.

# What changed

- **`lanes.ts`** — a pure overlap-lane packer: same-day events that overlap are laid out side by side
  in parallel lanes; a lane is reused once its event ends. Packs against the **displayed footprint**
  (`MIN_DISPLAY_MINUTES = 30`, matching the 24px / `HOUR_HEIGHT/2` minimum block height) so short
  back-to-back events never visually collide.
- **`EventBlock.tsx`** — a presentational event block with the prototype's state variants driven by
  the real `EnrichedEventRead` fields: **orphan** (`event.isOrphan` → danger ring + alert icon,
  overrides all), **confirmed** (filled colour), **tentative** (dashed/muted), **planned/default**
  (tinted); a repeat marker for recurring events; a deterministic palette fallback for null/unusable
  colours; danger via the bridged `--color-destructive` token.
- **`CalendarPage.tsx`** — restyled in place: the top bar now uses the shared `PageHeader` (week
  stepper + Today + the standard toolbar), the time grid gets a styled hour gutter, tokenised grid
  lines, day-column headers, a **today** highlight, and a **now-line**; events render through the lane
  helper + `EventBlock`. The events query, create/update/delete mutations, recurrence-scope handling,
  `ContactPicker`, and the inline create/edit forms are **unchanged**.
- **i18n** — filled the `focal.calendar.untitled` value (en `Untitled` / ru `Без названия`) for empty
  event titles.
- **Tests** — new `lanes.test.ts` (overlap/cluster/flush/immutability/determinism + edge cases:
  end<start, zero-duration, day-end crossing, sub-30-min split) and `EventBlock.test.tsx` (variant
  resolution incl. the orphan override, colour trim-vs-fallback); `CalendarPage.test.tsx` pinned to a
  fixed clock with a now-line presence/absence pair, existing behaviour assertions preserved.

# Files touched

- `apps/focal/client/src/features/calendar/lanes.ts` (new)
- `apps/focal/client/src/features/calendar/lanes.test.ts` (new)
- `apps/focal/client/src/features/calendar/EventBlock.tsx` (new)
- `apps/focal/client/src/features/calendar/EventBlock.test.tsx` (new)
- `apps/focal/client/src/features/calendar/CalendarPage.tsx` (restyled, behaviour-preserving)
- `apps/focal/client/src/features/calendar/CalendarPage.test.tsx` (pinned clock + now-line tests)
- `apps/focal/client/src/i18n/locales/{en,ru}.json` (the `focal.calendar.untitled` value only)

# Tests run

```sh
cd superapp/apps/focal/client
pnpm lint        # biome — 210 files, 0 errors
pnpm typecheck   # tsc -b — 0 errors
pnpm test:run    # vitest — 47 files, 326 passed
pnpm build       # tsc -b && vite build — OK
```

# Verification output

```sh
 Test Files  47 passed (47)
      Tests  326 passed (326)
# calendar subset: 6 files, 46 tests passed
# lint EXIT 0 · typecheck EXIT 0 · build EXIT 0
```

# Still needs review

- **Commit hygiene:** the slice's production code + first tests already landed (committed by a parallel
  session) inside `9385f5a` ("feat(focal): goal-map edit/create flows … and calendar event lanes"),
  **co-bundled with an unrelated goal-map slice**. The gate-6 test hardening
  (`EventBlock.test.tsx` + the `CalendarPage.test.tsx`/`lanes.test.ts` strengthening) is **uncommitted**
  in the working tree, ready to commit as a focused follow-up. Flagging so the calendar slice can be
  attributed/committed cleanly.
- **Visual evidence:** light/dark before/after screenshots were **not** captured — the calendar is
  behind the Supabase auth gate and a fresh preview context has no session (credentials are not
  entered programmatically). The running local app (`localhost:5173/calendar`) reflects the redesign
  via HMR for a manual eyeball.
- **Durability nit (non-blocking):** `EventBlock.test.tsx` keys two icon assertions on lucide's
  internal class names (`.lucide-triangle-alert` / `.lucide-repeat`); a future lucide major could
  rename them. An `aria`/`data-*` hook would be more durable.

# PR / release notes (for users — stage 5)

The Focal **weekly calendar** has a redesigned, Google-Calendar-style week view:

- a cleaner time grid with hour lines, a highlighted **today** column, and a **current-time line**;
- **colour-coded events** that reflect their state — confirmed, planned, tentative, and a clear
  warning style for events not linked to a project — with overlapping events shown **side by side**
  instead of stacked;
- the same calendar you already use: creating, editing, deleting, and repeating events all work
  exactly as before — only the look changed.

_(Contains no secrets, tokens, keys, or PII.)_

# Status

AWAITING CODEX REVIEW

---
Do not continue implementation until Codex review is complete.

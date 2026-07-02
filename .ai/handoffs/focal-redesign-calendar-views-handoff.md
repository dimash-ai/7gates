# Stage

Stage 4 (build) — **slice 3 of the `focal-redesign-calendar` epic**: day / 3-day / month calendar
views + a left-rail mini-month navigator + keyboard shortcuts. Adds the GCal-style view switcher on
top of the slice-1 week grid and the slice-2 popover, all from one `view` + `anchor` controller.

# What changed

- **`TimeGrid.tsx`** (new) — a **behavior-preserving lift** of the slice-1 week grid into a
  presentational component parametrized by the visible `days` (1 = day, 3 = 3-day, 7 = week). Renders
  the hour gutter, sticky day headers, today tint, click-to-create slots, lane-laid-out `EventBlock`s,
  and the now-line. **Dynamic column count uses inline `style.gridTemplateColumns`** (`"3.5rem
  repeat(N, minmax(0, 1fr))"`) — not a Tailwind arbitrary class from a runtime `N` (JIT can't generate
  it). **Now-line invariant:** rendered only on the column whose `toIsoDate(day) === todayIso`, which
  exists only when today is among `days` — so day-off-today / today-excluded windows show none, and
  month never does.
- **`MonthView.tsx`** (new) — read-only 6×7 grid: weekday headers, in/out-of-month + weekend +
  today styling, ≤3 event previews/day (dot + title) + a localized **`+N more`** overflow. Day cells
  are buttons → `onPickDay(date)`; groups events by `toIsoDate(day)` (no client recurrence expansion —
  renders exactly what `listEvents` returns).
- **`MiniMonth.tsx`** (new) — compact left-rail navigator with its **own** displayed month
  (re-synced to `anchor` via `useEffect` when the anchor's month changes), own prev/next-month
  chevrons (which move only the mini display, never the main grid), today/selected styling, day pick →
  `onPick(date)`. No booking marks (a later slice).
- **`CalendarPage.tsx`** — refactored into the single controller. Adds `view` state (default
  `week`) and a pure **`windowFor(view, anchor)` → `{ days, startIso, endIso, step }`**; the events
  query, range label, nav, and grid all flow from it. **The `week` row reproduces the original
  derivation exactly**, so the slice-1/2 query + nav tests pass unchanged. New: the view switcher
  (header `rightActions`), per-view prev/next using `step(dir)`, the left rail (`MiniMonth`, hidden
  below `lg` so it never crushes the grid + a region reserved for the slice-5 side panel), the
  conditional `MonthView`/`TimeGrid`, and page-scoped **keyboard shortcuts** (`d`/`3`/`w`/`m`,
  `t`=today, `n·j`=next, `p·k`=prev) with a guard (no-op when typing in INPUT/TEXTAREA/SELECT/
  contentEditable, on modified keys, or while a popover / scope dialog is open). Popover/scope/
  mutation/error wiring is unchanged from slice 2. `MiniMonth.onPick` sets `anchor` **preserving
  view**; `MonthView.onPickDay` sets `anchor` + `view='day'` (zoom).
- **`dates.ts`** — added `firstOfMonth`, `addMonthsClamped` (clamps the day to the target month's
  last day — Jan 31 +1mo → Feb 28, no double-rollover), `monthGridDays` (42 Monday-first dates).
- **Nav labels (i18n):** week keeps the existing `prevWeek`/`nextWeek` keys verbatim (three tests
  pin them); day/3-day/month use new `nav.prev`/`next` interpolated with `units.{day,3day,month,week}`.
- **i18n** — added `views.*`, `nav.*`, `units.*`, `miniMonth.*`, `month.dayCell` (count-pluralized),
  `monthMore` (count-pluralized) for both `en` and `ru`. `untitled` already existed.

# Files touched

- `apps/focal/client/src/features/calendar/TimeGrid.tsx` (new)
- `apps/focal/client/src/features/calendar/MonthView.tsx` (new)
- `apps/focal/client/src/features/calendar/MiniMonth.tsx` (new)
- `apps/focal/client/src/features/calendar/CalendarPage.tsx` (controller refactor)
- `apps/focal/client/src/features/calendar/dates.ts` (+3 helpers)
- `apps/focal/client/src/features/calendar/CalendarPage.test.tsx` (+10 view tests)
- `apps/focal/client/src/features/calendar/dates.test.ts` (+3 helper tests)
- `apps/focal/client/src/i18n/locales/{en,ru}.json` (views/nav/units/miniMonth/month/monthMore)

# What did NOT change

- The events API, mutations, recurrence-scope flow, `EventPopover`, `RecurringScopeDialog`,
  `EventBlock`, `lanes.ts` — untouched. No schema / migration / backend change. Frontend-only.

# Tests run

```sh
cd superapp/apps/focal/client
pnpm lint          # biome check . — 0 errors (215 files)
pnpm typecheck     # tsc -b — 0 errors
pnpm test:run      # vitest — 47 files, 353 passed
pnpm build         # tsc -b && vite build — OK
pnpm check:i18n    # i18next-cli extract --ci — no files updated (en/ru in sync)
```

# Verification output

```
 Test Files  47 passed (47)
      Tests  353 passed (353)
# calendar subset: 6 files, 73 tests passed
# lint / typecheck / build / check:i18n all EXIT 0
```

# Visual verification — DEFERRED to the user's local authenticated session (not done by the agent)

Task AC "before/after screenshots (each view + mini-month, light + dark)" is **NOT satisfied by this
handoff** and is **not claimed as done**. The Focal preview is **auth-gated** — a fresh preview renders
the Supabase login screen (verified this slice: `preview_start` → snapshot shows "Вход" / email +
password), and the agent must not enter credentials. There is no front-end demo-auth bypass
(`DEMO_AUTH_ENABLED` is a backend header flag; the SPA still requires the login UI). So per-view
light/dark screenshots can only be captured from an authenticated session.

**This is the standing visual-QA process for the whole Focal-migration epic** (every prior slice
shipped the same way): the engineer runs `pnpm --dir apps/focal/client dev` (or the `focal-preview`
launch config on :5199), logs in, and eyeballs each view + the mini-month in light + dark against the
prototype. Recorded here as an explicit **user-owned follow-up**, not silently dropped. The automated
gates above are the agent-verifiable surface; the visual pass is the human-verifiable surface.

# Review focus (build / step 4)

- **Behavior preservation of the TimeGrid extraction** — the slice-1/2 tests must still assert the
  same `listEvents(weekStartIso, weekEndIso)` window, `prevWeek`/`nextWeek`, now-line present/absent,
  and the full popover/scope flow.
- **`windowFor` correctness** per view (day/3day/week/month) — query window + `step(dir)`, esp. the
  month grid window and `addMonthsClamped` rollover clamp.
- **Now-line invariant** across views (present only when today ∈ visible days).
- **Keyboard guard** — no shortcut fires while typing or with a popover/dialog open.
- **i18n** — ru plural forms for `monthMore` / `month.dayCell`; no hardcoded strings.
```

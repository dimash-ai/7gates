# Design: focal-parity-calendar-prime-time

## Problem & decision

old-focal highlights a **prime-time ("golden hours")** band on the day / 3-day / week time grid — a
tinted window from `primeTimeStart` to `primeTimeEnd` marking the user's most-productive hours
(`apps/old-focal/client/src/components/CalendarViews.tsx` `usePrimeTime` / `getPrimeTimeInfo`), with a
`PrimeTimeDialog` to set the window from the calendar. The new app already has the **backend + the pure
rules** — `settings.ts` ports the legacy validation (`isValidWindow` / `correctedEnd` /
`availableEndTimes`, `DEFAULT_PRIME_START/END`, `START_TIMES` / `END_TIMES`) and the backend persists
`primeTimeStart`/`primeTimeEnd` (`UserSettingsRead`, both `string | null`) — but **no UI renders any of
it**: the calendar shows no band, and there is no prime-time picker anywhere (`SettingsPage` imports only
the backup/ical helpers from `settings.ts`).

**Decision:** render a single absolutely-positioned **band overlay per day column** in `TimeGrid`,
computed from the user's settings via the **existing linear geometry** (`top/height` from minutes, the
same math event blocks use), painted **behind** events and slots; show it only in the time-grid views
(day / 3-day / week). Read settings through the **existing** `getSettings` API with one TanStack Query.
Add a small **"golden hours" control** on the calendar toolbar that opens a dialog to set / clear the
window, **reusing** `settings.ts`'s pure rules + the `updateSettings` mutation — the dialog is the first
consumer of those rules; no new settings logic.

**Reuse-first (CLAUDE.md #2):** the settings API (`getSettings`/`updateSettings`), the validation rules
(`settings.ts`, currently unused — the dialog is their first consumer), and the linear pixel↔minute
geometry (`HOUR_HEIGHT`, `minutesOf`) all already exist — this slice is one overlay div + one thin dialog
wrapper, no new dependency or backend change.

**Alternatives rejected:**
- **Per-hour highlight (old-focal's `getPrimeTimeInfo(hour)` returning top/height per hour cell):** the
  new grid positions everything absolutely, so a single band (`top = startMin/60·HOUR_HEIGHT`,
  `height = (endMin−startMin)/60·HOUR_HEIGHT`) is simpler than 24 per-hour fragments and pixel-identical.
- **A second prime-time picker built fresh:** rejected — the dialog reuses the `settings.ts` pure rules
  and the `updateSettings` mutation; no duplicate validation.

## Assumptions & scope

- **(confirmed — code)** `getSettings()` → `UserSettings` with `primeTimeStart`/`primeTimeEnd` as
  `string | null` ("HH:MM" or null = off). `updateSettings(patch)` PATCHes them.
- **(confirmed — code)** `settings.ts` holds the legacy rules — `isValidWindow(start,end)`,
  `correctedEnd(start,end)`, `availableEndTimes(start)`, `START_TIMES`/`END_TIMES`,
  `DEFAULT_PRIME_START/END`, `timeToMinutes` — but **no UI consumes them yet**; the dialog is their first
  consumer.
- **(confirmed — code)** `TimeGrid` uses uniform `HOUR_HEIGHT = 48` linear geometry; day columns carry
  `data-day-column`; events render as absolutely-positioned blocks over the hour slots.
- **(confirm at build)** whether to introduce a shared `['settings']` query key in `api/queryKeys.ts` vs
  inline; the exact toolbar slot for the control. Settle in B1/B2.
- **Out of scope:** showing **another user's** prime-time on a shared calendar — old-focal passed
  `effectiveUserId` to `usePrimeTime`, but the new `getSettings()` has no user param (it returns the
  signed-in user's settings); per-owner prime-time on shared calendars needs a backend param and is a
  separate slice. The band shows the **current user's** window on every calendar. Month / year views
  (no time axis) never render the band.
- **Open questions:** None blocking.

## Success criteria

- [ ] With `primeTimeStart`/`primeTimeEnd` both set, the day / 3-day / week grid shows a tinted band
      spanning exactly that window in **every** day column, positioned by the same geometry as events.
- [ ] When either bound is null (off), **no** band renders.
- [ ] The band sits **behind** events and the now-line and **never** intercepts pointer events (clicks
      on slots / events / drag-to-move still work through it).
- [ ] Month and year views render **no** band.
- [ ] A "golden hours" control on the calendar toolbar opens a dialog; saving a valid window persists via
      `updateSettings` and the band updates without a manual refresh; an invalid window (start ≥ end) is
      rejected with a localized message and nothing persists.
- [ ] The dialog can **turn golden hours off** — persisting `{primeTimeStart: null, primeTimeEnd: null}` —
      after which no band renders.
- [ ] If `updateSettings` **fails**, the dialog stays open with a localized error and the band is left
      **unchanged** (no stale optimistic update — the band reflects the query cache, which changes only on
      success-invalidate).
- [ ] The band edits the **signed-in user's own** settings, so the edit control is **always available**
      (independent of the viewed calendar's `canEdit`), and the band renders on read-only shared calendars
      too — it's informational.
- [ ] All strings are i18next ru + en; the suite stays green (`pnpm lint && typecheck && test:run && build`).

## Build approach (slices)

| # | slice | files | main failure mode | what its test proves |
|---|-------|-------|-------------------|----------------------|
| B1 | Band overlay (read-only) | `features/calendar/dates.ts` (reuse `minutesOf`; add a band-geometry helper if it de-dupes), `TimeGrid.tsx` (band div per column, behind events, `pointer-events:none`), `CalendarPage.tsx` (`useQuery(['settings'], getSettings)`; pass `primeStart/End`) | band offset off-by-one; band steals pointer events; band leaks into month/year | a set window renders one band per column at the geometry-correct top/height, behind events, `pointer-events:none`; null bounds → no band; band absent in month/year |
| B2 | Golden-hours dialog (set / clear) | `features/calendar/PrimeTimeDialog.tsx` (thin — first consumer of `settings.ts` rules: `isValidWindow`/`correctedEnd`/`availableEndTimes` + `updateSettings`, writing the saved settings into the `['settings']` cache on success), `CalendarPage.tsx` (toolbar control disabled until `settings.isSuccess`, open/close) | invalid/empty window persists; band doesn't refresh; a failed save loses the dialog or stales the band | a valid edit calls `updateSettings` + refreshes the band; an invalid window is blocked with a message; a **disable** action persists `null,null` (band off); on `updateSettings` failure the dialog stays open with an error and the band is unchanged |

Each slice leaves `pnpm lint && typecheck && test:run && build` green and is committed on the branch.

## Architecture & contracts

```
CalendarPage
  ├─ useQuery(['settings'], getSettings) → { primeTimeStart, primeTimeEnd }
  ├─ <TimeGrid primeStart primeEnd … />              // band overlay (B1)
  └─ <PrimeTimeButton disabled until settings load> → <PrimeTimeDialog>   // edit (B2) — edits the signed-in user's OWN settings
                              └─ settings.ts rules + updateSettings mutation → setQueryData(['settings'], saved)
TimeGrid
  └─ per day column: <div data-prime-band aria-hidden style={top,height} pointer-events:none />  (behind events)
dates.ts: top = minutesOf(start)/60·HOUR_HEIGHT ; height = (minutesOf(end)−minutesOf(start))/60·HOUR_HEIGHT
```

| entity / interface | change | notes |
|--------------------|--------|-------|
| `CalendarPage` | add a settings query; pass `primeStart`/`primeEnd` to `TimeGrid`; (B2) toolbar button + dialog state | query key `['settings']`; band purely derived (no B1 mutation); the edit control is **not** gated on calendar `canEdit` (it edits the user's own settings) but **is** disabled until `settings.isSuccess`, so the dialog never opens from a loading/stale window (a self-data-loss race) |
| `TimeGrid` props | add `primeStart?: string \| null`, `primeEnd?: string \| null` | render one band per day column when both set; `aria-hidden`, `pointer-events:none`, low z (under events) |
| `dates.ts` | reuse `minutesOf`; the band's top/height is the existing event geometry (extract a tiny helper only if it de-dupes) | keep math in one place |
| `PrimeTimeDialog` (new, B2) | thin wrapper: reuse `settings.ts` rules (`isValidWindow`/`correctedEnd`/`availableEndTimes`) + `updateSettings`; supports set + clear/disable (null,null); `onError` keeps the dialog open; ru/en strings | first consumer of the prime-time rules; no new validation logic |
| data model | **None** | no schema/API change — reads `getSettings`, writes `updateSettings` (both exist) |

## Flow (happy + unhappy)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| band render | settings query resolves with both bounds | `TimeGrid` | one tinted band per day column at the window |
| band off | either bound null / query loading/error | `TimeGrid` | no band (absence is the safe default) |
| click through band | click a slot/event over the band | band is `pointer-events:none` | the slot/event handles it; band is inert |
| edit window | open dialog, pick valid start<end, save | `PrimeTimeDialog` → `updateSettings` → `setQueryData(['settings'], saved)` | persists; band re-renders to the new window with no refetch window |
| disable | open dialog, choose "off" / clear, save | `PrimeTimeDialog` → `updateSettings({primeTimeStart:null, primeTimeEnd:null})` | persists null,null; band disappears |
| invalid window | start ≥ end | `settings.ts` `isValidWindow` in the dialog | save blocked, localized message, nothing persists |
| save fails | `updateSettings` rejects | dialog `onError` | dialog stays open, localized error, band unchanged (cache untouched) |
| read-only calendar | viewing another's calendar (`!canEdit`) | `CalendarPage` | band still shows (informational); edit control still available — it edits **your own** settings |
| month/year | view has no time axis | `CalendarPage`/views | band not rendered |

## Test strategy, security & rollback

- **Test strategy.** Unit: band geometry (minutes→top/height) if a helper is added; reuse of `isValidWindow`.
  Component (happy-dom): `TimeGrid` renders a band per column for a set window at the right top/height,
  behind events, with `pointer-events:none`; renders none when bounds are null; `CalendarPage` wires the
  settings query and hides the band in month/year. Dialog (B2): a valid edit calls `updateSettings` and the
  band refreshes; an invalid window is blocked; a **disable** action persists `null,null` (band off); on
  `updateSettings` **failure** the dialog stays open with an error and the band is unchanged. The edit
  control is available regardless of calendar `canEdit`. "Verified" = those + `pnpm lint && typecheck &&
  test:run && build` green.
- **Security.** No new surface or data. The band reads the signed-in user's own settings; the dialog edits
  the signed-in user's own settings (not the viewed calendar owner's), so it is **not** gated on calendar
  `canEdit` — the server enforces ownership on `updateSettings`. No secrets/PII; all strings i18n.
- **Rollback.** Pure frontend, no migration — revert the PR.

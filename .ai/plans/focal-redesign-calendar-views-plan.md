# Summary

Add calendar views by first extracting the current week grid into a behavior-preserving `TimeGrid`, then letting `CalendarPage` own one `view` and one `anchor` that derive the visible days and `listEvents(startIso, endIso)` window. Day, 3-day, and week reuse `TimeGrid`; month uses a new read-only `MonthView`; the left rail starts with a new `MiniMonth` and room for the later side panel. `EventBlock`, `EventPopover`, recurring scope behavior, and the existing mutations stay intact.

Recommendation on slice size: keep `MonthView` and `MiniMonth` in this slice. They are explicit acceptance criteria, they establish the left-rail scaffold needed by slice 5, and they share the same `view`/`anchor`/query-window machinery as day and 3-day. If the reviewer forces a split, the clean smaller cut is day/3-day/week view switching plus shortcuts first, then month/mini-month/rail in a follow-up; that is the fallback, not the recommendation.

# Files to change

| path | change | why |
|------|--------|-----|
| `superapp/apps/focal/client/src/features/calendar/TimeGrid.tsx` | Add a presentational extraction of the current hour gutter, sticky day headers, slot buttons, today column tint, now-line, lane layout, and `EventBlock` rendering. Props include `days`, `events`, `todayIso`, locale, `onCreate`, and `onEdit`. | Day, 3-day, and week are the same grid with a different day list. Extracting this first preserves slice 1/2 behavior and avoids duplicating grid logic. |
| `superapp/apps/focal/client/src/features/calendar/MonthView.tsx` | Add a 6x7 month grid with weekday headers, in-month/out-of-month styling, today highlight, up to 3 event previews per day, localized `+N more`, and day-cell click -> `onPickDay(date)`. | Month is the only non-time-grid view and should remain read-only preview UI. Editing/creation continues through time-grid popovers after switching to day. |
| `superapp/apps/focal/client/src/features/calendar/MiniMonth.tsx` | Add the compact month navigator with its own previous/next month controls, weekday headers, today/selected styling, and day pick callback. Omit booking marks. | The left rail needs a real navigator now and an empty scaffold for later side-panel content. Mini-month date picks must preserve the current main view. |
| `superapp/apps/focal/client/src/features/calendar/CalendarPage.tsx` | Refactor into the controller for `view`, `anchor`, derived query window, topbar navigation, view switcher, left rail, conditional `TimeGrid`/`MonthView` rendering, popover wiring, and keyboard shortcuts. | This page already owns React Query, mutations, error handling, `openCreate`/`openEdit`, and the popover/dialog state that every time-grid view must reuse. |
| `superapp/apps/focal/client/src/features/calendar/dates.ts` | Add small local-date helpers such as `addMonthsClamped`, `firstOfMonth`, and `monthGridDays`/equivalent built on `mondayOf` and `addDays`. | Query-window derivation and month/mini-month grids need reusable local-date math without UTC/epoch drift or JS month rollover bugs. |
| `superapp/apps/focal/client/src/features/calendar/CalendarPage.test.tsx` | Preserve the existing week/grid/now-line/popover tests through the `TimeGrid` extraction, then add view-switching, per-view query window, month grid, mini-month, and shortcut coverage. | Page-level tests are the behavioral contract for `listEvents`, popover wiring, navigation, and keyboard guards. |
| `superapp/apps/focal/client/src/i18n/locales/en.json` | Add labels for views, view-aware prev/next controls, mini-month controls, month day cells, and `+N more`; keep existing keys where possible. | No visible or accessible text should be hardcoded. Existing week labels should keep default-week tests stable. |
| `superapp/apps/focal/client/src/i18n/locales/ru.json` | Add the same keys as `en.json`. | Keep i18n parity and avoid missing-key output. |

No server/API/OpenAPI files should change. No `EventBlock.tsx` or `EventPopover.tsx` change is expected; `TimeGrid` should call their existing public props.

# Implementation slices

1. Extract `TimeGrid` behavior-preservingly.
   - Move `HOUR_HEIGHT`, `HOURS`, `DEFAULT_DURATION_MINUTES`, `blockGeometry`, header/day-column JSX, `eventsOn`, `layoutEventLanes(...)`, slot buttons, now-line, and `EventBlock` rendering out of `CalendarPage.tsx`.
   - Keep `CalendarPage` deriving the same `weekStart`, `days = weekDays(weekStart)`, `startIso`, `endIso`, `todayIso`, and `events` query as today.
   - `TimeGrid` should accept `onCreate(dateIso, hour, anchorSource)` and `onEdit(event, anchorSource)` so the existing popover opens from slots/events with no behavioral change.
   - Preserve existing accessible slot labels, event text, `data-testid="calendar-now-line"`, and default week navigation labels.
   - Run `cd superapp/apps/focal/client && pnpm typecheck && pnpm test:run CalendarPage.test.tsx` or the repo-supported targeted Vitest command before continuing. No test rewrite should be required for this slice.

2. Add view state, date-window derivation, and time-grid navigation.
   - Add `type CalendarView = 'day' | '3day' | 'week' | 'month'` in `CalendarPage.tsx`, defaulting to `week`.
   - Add date helpers in `dates.ts` before using them in the page: `addMonthsClamped` for prev/next month and `monthGridDays(anchor)` returning the 42 visible month-grid dates.
   - Derive one window object from `view` + `anchor`:

     | view | visible days/main grid | query start | query end | prev/next step |
     |------|------------------------|-------------|-----------|----------------|
     | `day` | `[anchor]` | `toIsoDate(anchor)` | `toIsoDate(anchor)` | `addDays(anchor, +/-1)` |
     | `3day` | `anchor..+2` | `toIsoDate(anchor)` | `toIsoDate(addDays(anchor, 2))` | `addDays(anchor, +/-3)` |
     | `week` | `mondayOf(anchor)..+6` | `toIsoDate(mondayOf(anchor))` | `toIsoDate(addDays(mondayOf(anchor), 6))` | `addDays(anchor, +/-7)` |
     | `month` | `monthGridDays(anchor)` | first grid cell | last grid cell | `addMonthsClamped(anchor, +/-1)` |

   - Wire `eventsKey = ['events', startIso, endIso]` and `queryFn: () => listEvents(startIso, endIso)` from the derived window.
   - Add the topbar segmented view switcher using localized labels. Expose day/3-day/week first if needed to keep this interim slice fully usable; expose month once `MonthView` is wired in slice 3.
   - Update prev/next and Today to use the derived step. Keep week's accessible labels compatible with existing `prevWeek`/`nextWeek` tests, and add view-aware labels for day/3-day/month.
   - Add range labels with `Intl.DateTimeFormat(i18n.resolvedLanguage, ...)`: day shows one full date, 3-day/week show a date range, month shows month + year.
   - Run typecheck and `CalendarPage.test.tsx`, then add focused tests for day and 3-day query windows/navigation before continuing.

3. Add `MonthView` and expose the month view.
   - `MonthView` receives `anchor`, `days`/month grid dates, `events`, `todayIso`, `locale`, and `onPickDay(date)`.
   - Group events by `event.date` using the same `toIsoDate(day)` local-date keys. Do not add client-side recurrence expansion; render exactly what `listEvents` returned for the month window.
   - Render 42 day cells with weekday headers, today highlighting, in-month/out-of-month styling, weekend treatment, up to 3 event previews, and localized `+N more`.
   - Day cells are buttons. Clicking any day, including a day containing event previews, runs `setAnchor(day); setView('day')`. Month event previews are not edit buttons in this slice.
   - Expose the month tab in the view switcher and verify month prev/next steps by clamped month, not by 30 days.
   - Add tests proving the month query window is the 6-week grid window, the grid renders 42 cells, event overflow renders `+N more`, and clicking a month day switches to day view with that day as the next query window.

4. Add `MiniMonth` and the left rail scaffold.
   - Add a left rail around the main calendar surface, roughly the prototype's 290px rail on desktop, with responsive behavior that does not crush the grid on narrow screens.
   - `MiniMonth` keeps its own displayed month/year state for chevrons and re-syncs when the main `anchor` changes.
   - Mini-month day click only calls `setAnchor(day)` and preserves the current `view`: day stays day, 3-day stays 3-day, week stays week, and month stays month. This intentionally differs from the prototype snippet, where mini-month click leaves month for day.
   - Omit booking mark dots and side-panel task/habit/goal content. Leave only the rail structure needed by later slices.
   - Add tests proving mini-month chevrons change the mini-month month without changing the main query window, and picking a date preserves the current view while updating the derived query window.

5. Add keyboard shortcuts in `CalendarPage`.
   - Add a page-scoped `window` keydown listener with a small guard:
     - return if `event.defaultPrevented`;
     - return for modifier chords (`metaKey`, `ctrlKey`, `altKey`);
     - return if target is `INPUT`, `TEXTAREA`, `SELECT`, or content-editable;
     - return while `popover` or `pendingOp` is open.
   - Map `d` -> day, `3` -> 3-day, `w` -> week, `m` -> month, `t` -> today, `n`/`j` -> next, and `p`/`k` -> previous. Do not implement `c` here.
   - Use the same navigation helpers as the buttons so shortcuts cannot drift from click behavior.
   - Add tests for view switching, Today, prev/next pairs, and the guard: with the create popover open and the title input focused, pressing `m` or `n` should neither switch views nor change the query window.

6. Final cleanup and verification.
   - Remove now-unused week-only constants/imports from `CalendarPage.tsx` after `TimeGrid` owns them.
   - Keep loading and load-error messages at the page level above the grid/rail so they apply to every view.
   - Run `cd superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.
   - Capture final light/dark screenshots for day, 3-day, week, month, and mini-month if browser access is available during build. Fix only regressions introduced by this slice.

# Tests

- `CalendarPage.test.tsx`: keep the existing default-week request test green through the extraction; it should still prove `listEvents(weekStartIso, weekEndIso)` is called and week events render.
- `CalendarPage.test.tsx`: keep the existing previous-week, Today, and now-line tests green through extraction. After view state lands, update/add assertions so the default week still steps by 7 days and the now-line only renders when today's column is visible in a time-grid view.
- `CalendarPage.test.tsx`: keep the existing create/edit/delete/popover/recurring-scope tests green. Add one time-grid view-switch path, such as switching to 3-day and opening a slot, to prove the same `openCreate` popover works outside the default week.
- `CalendarPage.test.tsx`: view switching test clicks day, 3-day, week, and month controls and proves the selected view changes and the expected grid type renders: 1/3/7 time-grid day headers for time-grid views and a month grid for month.
- `CalendarPage.test.tsx`: per-view query-window tests assert `listEvents` receives the derived start/end for day, 3-day, week, and month. Use the same date helpers in expected values instead of hard-coding month edges.
- `CalendarPage.test.tsx`: navigation tests prove prev/next step by the active view's unit and Today resets `anchor` to the fixed system date.
- `CalendarPage.test.tsx`: month-grid test renders at least 4 events on one day, proves only 3 previews are shown plus localized `+1 more`, proves 42 day-cell buttons exist, and proves clicking a month day switches to day view for that date.
- `CalendarPage.test.tsx`: mini-month test proves chevrons change only the mini-month display month, then picking a date updates `anchor` while preserving the current view and sending the matching `listEvents` window.
- `CalendarPage.test.tsx`: shortcut tests prove `d`/`3`/`w`/`m`, `t`, `n`/`p`, and `j`/`k` call the same view/navigation paths as buttons. The guard test opens the popover, focuses the title input, presses a shortcut, and asserts view/query state does not change.
- Final command set: `cd superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.

# Error & rescue map

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| Events fail to load for any view window | Rejection from `listEvents(startIso, endIso)` | Existing `events.isError` branch in `CalendarPage`, now fed by the derived window | Existing localized load alert; the calendar shell remains mounted. |
| Create, update, or delete fails from a time-grid popover | Rejection from `createEvent`, `updateEvent`, or `deleteEvent` | Existing mutation `onMutationError` in `CalendarPage` | Existing localized save alert with detail when available; the popover draft remains available. |
| Time-grid popover anchor disconnects after a slot/event click | No new exception; `EventPopover` virtual anchor falls back to its captured rect | Existing `EventPopover` anchor helper | Popover remains positioned from the captured click rect, as in slice 2. |
| Active window contains no events | No exception; query returns `[]` | `TimeGrid`/`MonthView` render from `events.data ?? []` | Empty time grid or month previews, with the same loading/error messaging outside the grid. |
| Month has fewer leading/trailing days than the 6-week grid | No exception; `monthGridDays(anchor)` always returns 42 local dates | `dates.ts` helper used by `CalendarPage` and `MonthView` | Stable 6x7 month grid with out-of-month days muted. |
| Month navigation starts from a day that does not exist in the target month | No exception; helper clamps to target month's last day | `addMonthsClamped` in `dates.ts` | Navigation lands in the adjacent month instead of rolling into a second month. |
| Mini-month chevrons move away from the selected month | No exception; display month is local to `MiniMonth` | `MiniMonth` state, re-synced when `anchor` changes | Main calendar does not navigate until the user picks a date. |
| User presses a shortcut while typing or while a popover/dialog is open | No exception; shortcut handler returns early | Keyboard guard in `CalendarPage` | The key is handled by the focused input/dialog; calendar view and query window do not change. |
| User presses an unsupported key | No exception; no action maps to the key | Keyboard handler in `CalendarPage` | Nothing changes. |
| Month event has null/unusable color | No exception; MonthView uses a token fallback for the preview dot/tint | `MonthView` event-preview rendering | Event preview remains visible with a fallback color. |

# Review lenses (pre-answer before gate2-plan)

- **Scope / strategy** - This is the minimum viable view machinery for slice 3: extract the existing grid once, add one controller-owned `view`/`anchor`, then add the one new month grid and one mini-month navigator. It deliberately avoids year view, bookings, side-panel content, drag, all-day lanes, recurrence expansion, and API changes. Keeping month plus mini-month in-slice is the recommended cut because they are part of the same query-window/navigation surface.
- **Architecture** - `CalendarPage` remains the only stateful owner of query windows, mutations, invalidation, errors, popover/dialog state, view, anchor, navigation, and shortcuts. `TimeGrid`, `MonthView`, and `MiniMonth` are presentational and callback-driven. Date math lives in `dates.ts` to avoid ad hoc month rollover logic in JSX. Unhappy paths still flow through the existing query/mutation branches.
- **Design** - Loading and error states remain visible across all views. Time-grid views preserve the current grid, now-line, today highlight, lanes, slot buttons, and event popover behavior. Month view is read-only preview with clear day-cell navigation to day view. Mini-month highlights today and selected date, preserves current view on pick, and sits in a restrained rail that leaves space for slice 5.
- **DevEx** - The extraction order keeps existing tests useful while the page grows. The per-view window table should become a small helper or memo in `CalendarPage`, making tests straightforward. No new calendar library, global store, backend contract, or broad abstraction is introduced.

# Risks & migrations

- No database migration, API migration, generated OpenAPI change, config change, or backend rollout.
- Main risk is regressing slice 1/2 week-grid behavior during extraction. Mitigation: extract `TimeGrid` first with no test rewrites and run the existing page tests before adding new behavior.
- Secondary risk is wrong date windows, especially month rollover and 6-week month boundaries. Mitigation: centralize local-date helpers in `dates.ts` and assert every view's `listEvents` start/end in tests.
- Tertiary risk is shortcuts hijacking typing or popover/dialog interactions. Mitigation: explicit target/open-state guard plus tests.
- Rollback is local to `CalendarPage.tsx`, `TimeGrid.tsx`, `MonthView.tsx`, `MiniMonth.tsx`, `dates.ts`, locale additions, and `CalendarPage.test.tsx`.

# Scope check

- [x] Matches the task's Scope and Out of scope
- [x] Small enough to review in one sitting if built in the ordered slices above
- [x] Size smell checked: this adds three local calendar components and date helpers, but no new service/API/library. Recommendation is to keep month plus mini-month in this slice; fallback split is time-grid views/shortcuts first, month/mini-month/rail second.

# Out of scope

- Year view and Booking screen routing.
- Booking marks in mini-month or month cells.
- Side-panel task/habit/goal content; this slice only adds the rail scaffold.
- Drag, move, resize, all-day lanes, drag-to-side-panel conversions, and golden/prime-time bands.
- New client-side recurrence expansion.
- Server/API/schema changes, generated OpenAPI edits, or event payload changes.

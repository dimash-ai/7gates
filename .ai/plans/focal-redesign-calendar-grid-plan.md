# Summary

Restyle the existing week calendar in place while preserving its current data flow and mutations. The implementation should adopt the shared `PageHeader`, extract only the reusable event block, add one pure overlap-lane helper with focused tests, and keep the inline create/edit forms working until the popover slice replaces them. No API, schema, recurrence, contact picker, or server behavior changes are planned.

Assumptions to carry into build:
- `CalendarEvent` is `Schemas['EnrichedEventRead']`; `isOrphan`, `status`, `color`, `recurrence`, `recurringEventId`, `date`, `startTime`, and `endTime` are the real fields to drive the block and geometry.
- `HOUR_HEIGHT = 48` stays unchanged because it matches the prototype `HOUR_PX`.
- The existing create/edit/delete flows and accessible labels in `CalendarPage.test.tsx` remain the behavior contract.
- The status-to-variant map below must be confirmed before styling the final block states.

# Files to change

| path | change | why |
|------|--------|-----|
| `superapp/apps/focal/client/src/features/calendar/CalendarPage.tsx` | Replace the local header with `PageHeader`; restyle the week grid, day headers, today column, hour gutter, and inline forms; compute/render the now-line; route each day through the lane helper; render `EventBlock` while preserving the existing `select`, `prefill`, create, update, delete, and recurrence-scope flows. | This is the user-facing slice and already owns the real API behavior that must stay intact. |
| `superapp/apps/focal/client/src/features/calendar/EventBlock.tsx` | Add a small reusable event block component with status/orphan variants, title truncation, time line, repeat marker, lane positioning props, and click-to-edit callback. | The event block is the structural base for later popover/view/drag slices, and extracting it keeps `CalendarPage` from absorbing the visual variant logic. |
| `superapp/apps/focal/client/src/features/calendar/lanes.ts` | Add a pure helper that converts same-day events into `{ event, lane, laneCount }` layout records without mutating the input events. | Overlap packing is the only new calendar logic in this slice and needs a narrow, testable home. A new file keeps `dates.ts` focused on date/time conversion. |
| `superapp/apps/focal/client/src/features/calendar/lanes.test.ts` | Add unit tests for overlap clusters, lane reuse, non-overlap, deterministic ordering, and input immutability. | Proves concurrent events render side by side and later isolated events return to one lane. |
| `superapp/apps/focal/client/src/features/calendar/CalendarPage.test.tsx` | Keep existing behavior tests green; update only structural selectors if needed; add small coverage for Today navigation/now-line with a fixed system clock if the DOM needs a stable assertion. | The task explicitly requires existing calendar behavior to stay green and the now-line to be exercised. |

No locale file change is expected because the current keys already cover title, Today, prev/next week, slot labels, form labels, loading, and errors. Add `i18n/locales/{en,ru}.json` only if the build introduces a new visible or accessible string that cannot reuse an existing key.

# Implementation slices

1. Add `lanes.ts` and `lanes.test.ts`.
   - Shape: `layoutEventLanes(events: CalendarEvent[]): Array<{ event: CalendarEvent; lane: number; laneCount: number }>` or equivalent.
   - Internals: sort by start minutes, then end minutes, then stable id/date/title; group transitive overlaps into clusters; assign the first available lane whose end is `<=` the next start; stamp the final cluster lane count onto every returned record.
   - End-time fallback must match current `blockGeometry`: missing `endTime` means `start + DEFAULT_DURATION_MINUTES`.
   - Leave the app unchanged and run the targeted unit test plus typecheck before wiring it into the page.

2. Extract `EventBlock.tsx` from the inline absolute event button.
   - Preserve the current behavior surface: it is a `button`, clicking calls the existing `select(event)`, and the visible title text remains queryable by tests.
   - Props should stay narrow: `event`, `top`, `height`, `lane`, `laneCount`, and `onSelect`.
   - Use existing utilities/tokens (`cn`, Tailwind token classes, CSS variables, inline `event.color` only where a real event color is required).
   - Do not add popover, drag handles, resize handles, keyboard shortcuts, or all-day support.

3. Confirm and implement the status-to-variant map in `EventBlock`.
   - `event.isOrphan === true` -> orphan/danger variant; overrides all other variants and does not infer from `projectId`.
   - `status === 'confirmed'` -> filled block using `event.color` or the event palette fallback, white text.
   - `status === 'tentative'` -> muted/dashed block.
   - `status === 'planned'` or any unknown status -> tinted planned/default block using `event.color` or the event palette fallback.
   - Repeat marker appears when `event.recurrence !== 'none' || event.recurringEventId !== null`.
   - If confirmation changes this map, update only this slice of the plan before build.

4. Wire lanes into `CalendarPage`.
   - Replace `eventsOn(dateIso).map(...)` with `layoutEventLanes(eventsOn(dateIso)).map(...)`.
   - Keep `blockGeometry(event)` or move the same math beside the lane helper, but keep the current pixel output: `top = minutes / 60 * HOUR_HEIGHT`; minimum height `HOUR_HEIGHT / 2`.
   - Apply lane layout with prototype-style spacing: width is based on `laneCount`, left is based on `lane`, with a small horizontal inset so adjacent events do not touch.
   - Re-run `CalendarPage.test.tsx` here because this is where click-to-edit can regress.

5. Restyle the shell, header, forms, and grid chrome in `CalendarPage`.
   - Use the existing page pattern: root `flex h-full flex-col overflow-hidden bg-background text-foreground`, `PageHeader` with a calendar icon badge, and the shared `PageToolbar` via `PageHeader`.
   - Put prev/range/next and Today into `centerActions` or adjacent header actions without adding a dead view switcher.
   - Keep the create and edit cards present, with existing labels, recurrence scope radios, ContactPicker, and mutation buttons.
   - Restyle the scrollable week grid to match the prototype: sticky day header row, 56px-ish hour gutter, subtle tokenized grid lines, today header/date highlight, today column tint, `min-w-[840px]` or equivalent responsive constraint.

6. Add the now-line.
   - Derive from `new Date()` at render time; no interval is needed in this behavior-preserving slice.
   - Render only in the visible today column.
   - Position with the same hour geometry as events and use the prototype's danger/accent red line plus dot.
   - Add a stable test hook or aria-hidden marker only if needed for the test; avoid new user-visible text.

7. Final verification and screenshots.
   - Run `cd superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.
   - Capture before/after or final screenshots for light and dark week grid/event states if a browser is available in the build step.
   - Do not broaden the slice if screenshots expose unrelated page issues; fix only calendar-grid regressions introduced by this work.

# Tests

- `lanes.test.ts` unit: two overlapping events at `09:00-10:00` and `09:30-10:30` receive `laneCount = 2` and different lanes, proving side-by-side overlap.
- `lanes.test.ts` unit: a transitive cluster such as `09:00-10:00`, `09:30-10:30`, `10:00-11:00` stays one cluster with reusable lanes, proving the helper matches the prototype cluster behavior rather than only pairwise overlap.
- `lanes.test.ts` unit: a later non-overlapping event gets `lane = 0` and `laneCount = 1`, proving clusters flush and isolated events keep full width.
- `lanes.test.ts` unit: input events are not mutated, proving the helper is safe to reuse with React Query data.
- `CalendarPage.test.tsx`: preserve existing tests for visible week request, previous-week nav, create-from-form payload, delete plain event, delete recurring with scope, and edit recurring with scope.
- `CalendarPage.test.tsx`: add or update assertions for Today navigation and now-line only as needed. Use `vi.setSystemTime(...)` so the expected visible week/today column is deterministic.
- Final command set: `cd superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.

# Status-to-variant map to confirm

| event condition | variant | visual result | note |
|-----------------|---------|---------------|------|
| `event.isOrphan === true` | `orphan` | danger ring, danger-tinted background, danger text/icon | Overrides status and color; do not infer orphan from `projectId`. |
| `event.status === 'confirmed'` | `confirmed` | filled event color, white text, subtle shadow | Uses `event.color` or the palette fallback. |
| `event.status === 'tentative'` | `tentative` | muted fill/text, dashed border, no strong shadow | Matches prototype tentative treatment. |
| `event.status === 'planned'` | `planned` | tinted event color background, colored text/border | Matches current create default. |
| any other `status` string | `planned` fallback | same as planned | Keeps free-form backend status values from breaking rendering. |

Palette fallback: copy the prototype calendar palette locally in the calendar feature and use a single deterministic fallback color from it unless the confirmed design gate requires id-based palette assignment. Do not add user-facing color selection in this slice.

# Error & rescue map

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| Week events fail to load | Rejection from `listEvents(startIso, endIso)` | Existing `events.isError` branch in `CalendarPage` | Existing localized load alert; create/edit controls and grid shell remain mounted. |
| Create, update, or delete fails | Rejection from the existing mutation API call | Existing `onMutationError` callback in `CalendarPage` | Existing localized save alert with the error detail when available. |
| Event has no `endTime` | No exception; lane/geometry code normalizes to `start + DEFAULT_DURATION_MINUTES` | `lanes.ts` and `blockGeometry`/shared geometry | Event renders as a one-hour block, preserving current behavior. |
| Event has unknown `status` | No exception; status resolver falls back to planned/default | `EventBlock` variant resolver | Event renders as a planned/tinted block. |
| Event has null or unusable `color` | No exception; color resolver uses the palette fallback | `EventBlock` color resolver | Event renders with the fallback event color instead of disappearing. |
| Current day is outside the visible week | No exception; now-line render guard returns null | `CalendarPage` now-line conditional | No now-line is shown for non-current weeks. |

# Review lenses (pre-answer before gate2-plan)

- **Scope / strategy** - This is the minimum viable structural slice: one page restyle, one reusable event block, one pure lane helper, and focused tests. Existing API hooks, mutations, forms, recurrence scope handling, ContactPicker, and route exports stay intact. The decision is reversible because the helper/component are small and local to `features/calendar`.
- **Architecture** - Data flow remains React Query -> `CalendarPage` -> presentational `EventBlock`; unhappy paths stay in the page's existing loading/error/mutation branches. The helper is pure and does not mutate React Query objects. The event block receives already-computed layout props rather than reading page state.
- **Design** - Light/dark styling uses merged foundation tokens and `PageHeader`. Empty/loading/error states remain visible. The grid keeps horizontal overflow for narrow screens, stable hour sizing, day headers, today highlight, and now-line. Event text truncates inside a fixed block and adjacent lane blocks use stable width/left math.
- **DevEx** - The next developer gets a named lane unit and an event block ready for the popover/view/drag slices without a full speculative calendar component split. Tests document the non-obvious overlap behavior.

# Risks & migrations

- No database migration, API migration, generated schema change, config change, or backend rollout.
- Main risk is visual/layout regression in the calendar page. Rollback is limited to reverting `CalendarPage.tsx`, `EventBlock.tsx`, `lanes.ts`, and the two related tests.
- Secondary risk is brittle DOM tests after the event block extraction. Keep accessible names from event titles and existing form labels stable to avoid test-only rewrites.

# Scope check

- [x] Matches the task's Scope and Out of scope
- [x] Small enough to review in one sitting
- [x] Size smell checked: this touches one feature folder plus tests only; the extraction is limited to the event block and the overlap helper because both are immediate inputs to later calendar slices.

# Out of scope

- Event popover and recurring-scope dialog replacement.
- Day, 3-day, month views, mini-month, and view switcher.
- Drag, move, resize, 15-minute snap, drag ghost, or cross-DnD.
- Side panel, bookings strip, prime-time bands, all-day lane, and single-day marks.
- Keyboard shortcuts.
- Server/API/schema changes, generated OpenAPI edits, event payload changes, recurrence behavior changes, or ContactPicker persistence changes.

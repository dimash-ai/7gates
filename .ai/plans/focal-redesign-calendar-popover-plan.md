# Summary

Replace the calendar inline create/edit cards with one controlled, Radix-backed event popover plus a separate recurring-scope dialog. The key design choice is anchoring: extend the slot click and `EventBlock.onSelect` paths to capture the clicked element plus its fallback rect, then render `PopoverAnchor` with a `virtualRef` so the popover can be positioned against the real grid click without moving grid cells/events inside the popover tree. The existing `createEvent`, `updateEvent`, `deleteEvent`, and recurrence target contracts stay intact; mark-done maps only to `completed`, not `status`.

Recommendation on slice size: keep the Project -> Product -> Activity link selects in this slice. They are explicitly in the task, already backed by existing APIs, and are small if implemented with the same React Query pattern used by the time budgets page. If the build reviewer decides the slice is too large, the clean follow-up cut is only those three link selects and their tests; do not split the core popover, anchoring, recurrence scope, color, or mark-done behavior.

# Files to change

| path | change | why |
|------|--------|-----|
| `superapp/apps/focal/client/src/components/ui/popover.tsx` | Export `PopoverAnchor` from `@radix-ui/react-popover` alongside the existing `Popover`, `PopoverContent`, and `PopoverTrigger`. | The local wrapper currently hides Radix's anchor primitive. The popover needs `PopoverAnchor virtualRef` to anchor to a clicked calendar slot/event rect without custom positioning code. |
| `superapp/apps/focal/client/src/features/calendar/EventBlock.tsx` | Extend `onSelect` to pass the click anchor source (`event.currentTarget` plus captured rect, or a narrow `AnchorSource` type imported from `CalendarPage`/local type file if extracted). Keep all visual behavior unchanged. | Slice 1's `onSelect(event)` is not enough to position the edit popover at the clicked event. |
| `superapp/apps/focal/client/src/features/calendar/EventBlock.test.tsx` | Update the click assertion to expect the selected event plus an anchor argument, and keep all existing variant/color/repeat assertions. | The callback signature change is intentional and should be covered without weakening slice 1's tests. |
| `superapp/apps/focal/client/src/features/calendar/EventPopover.tsx` | Add the controlled create/edit popover component: title, date/start/end time, recurrence, color swatches, completed toggle, ContactPicker, Project/Product/Activity selects, save/delete buttons, and payload/draft helpers. | This replaces the inline form UI while preserving the event payload contract and matching the prototype surface. |
| `superapp/apps/focal/client/src/features/calendar/RecurringScopeDialog.tsx` | Add the Radix `Dialog` scope chooser for `single`, `following`, and `all`, using the existing `RecurrenceScope` type and `radio-group` primitive. | Recurring save/delete must ask for scope in a focused dialog instead of inline radios. |
| `superapp/apps/focal/client/src/features/calendar/CalendarPage.tsx` | Remove the inline create card and edit card; replace `form`/`draft`/`scope` UI state with popover state, anchor state, participants state scoped to the popover, and pending recurring operation state. Keep events query, invalidation, loading/error rendering, and mutations. | This is the only page that owns the calendar grid and existing mutation behavior. |
| `superapp/apps/focal/client/src/features/calendar/CalendarPage.test.tsx` | Rewrite form-driven create/edit/delete tests to click slots/events, drive the popover and scope dialog, and preserve the `createEvent`/`updateEvent`/`deleteEvent` payload assertions including `{ scope, occurrenceDate }`. Mock projects/products/activities APIs for link-select tests. | The UI path changes; the behavioral contract must remain tested at the page level. |
| `superapp/apps/focal/client/src/i18n/locales/en.json` | Add popover, link-select, completed toggle, color, scope-dialog, and link-query error/empty strings under `focal.calendar`. Reuse existing form/edit/recurrence strings where they still fit. | No new visible or accessible text should be hardcoded. |
| `superapp/apps/focal/client/src/i18n/locales/ru.json` | Add the same keys as `en.json`. | Keep i18n parity and avoid runtime missing-key output. |

No API files, server files, generated OpenAPI types, `dates.ts`, or `lanes.ts` should change.

# Implementation slices

1. Add anchor plumbing while leaving the inline forms in place.
   - Export `PopoverAnchor` from `components/ui/popover.tsx`.
   - Define a small local anchor shape in `CalendarPage.tsx` or `EventPopover.tsx`: `{ element: HTMLElement | null; rect: DOMRect }`.
   - Capture anchors with a helper that stores `event.currentTarget` and a copied `getBoundingClientRect()` result. The virtual measurable should return `element.getBoundingClientRect()` while connected, otherwise the stored rect.
   - Change `EventBlockProps.onSelect` from `(event) => void` to `(event, anchor) => void` and call it from the block button click.
   - Change slot buttons from `onClick={() => prefill(dateIso, hour)}` to pass the clicked slot anchor into `prefill(dateIso, hour, anchor)`, even if `prefill` still only updates the old form in this slice.
   - Run `pnpm typecheck` and `pnpm test:run CalendarPage.test.tsx EventBlock.test.tsx` or the Vitest equivalent supported by the repo.

2. Add `RecurringScopeDialog.tsx` without wiring it to mutations yet.
   - Use `Dialog`, `DialogContent`, `DialogHeader`, `DialogTitle`, `DialogFooter`, `Button`, and existing `RadioGroup`/`RadioGroupItem`.
   - Props: `open`, `mode: 'update' | 'delete'`, `defaultScope?: RecurrenceScope`, `onCancel`, `onConfirm(scope: RecurrenceScope)`.
   - Use real scope values: `single`, `following`, `all`. Do not use the prototype's `"one"` value in real state.
   - Escape/outside/cancel resolves as cancel with no mutation.
   - Add locale keys, then run typecheck.

3. Add the core `EventPopover.tsx` as a typed but not-yet-wired component.
   - Props should stay explicit: `open`, `mode: 'create' | 'edit'`, `anchor`, `event` or create draft seed, `participants`, `onParticipantsChange`, `isSaving`, `isDeleting`, `onOpenChange`, `onSave(draft, dirtyFields)`, `onDelete(event)`.
   - Render `<Popover open={open} onOpenChange={...}>`, `<PopoverAnchor virtualRef={...} />`, and `<PopoverContent side="right" align="start" sideOffset={8} collisionPadding={12} className="w-[332px] ...">`.
   - Autofocus the title through `onOpenAutoFocus` or a title input ref. Enter in the title saves. Escape/outside close discards an untitled new draft and preserves existing mutation behavior by not firing any mutation.
   - Draft fields: `title`, `date`, `startTime`, `endTime`, `recurrence`, `recurrenceEndDate`, `color`, `completed`, `projectId`, `productId`, `activityId`, and local participants.
   - Payload helpers must preserve current shapes: create sends `title`, `date`, `startTime`, `endTime: value || null`, `status: 'planned'`, `completed`, `recurrence`, plus optional `color`, `projectId`, `productId`, `activityId` only when set/backed. Update sends the same core fields the edit card sends today (`title`, `date`, `startTime`, `endTime`, `recurrence`) and adds new fields only when the user changed them.
   - ContactPicker stays UI-only exactly as today: keep participants in component state, clear them after successful create, and do not add `contactIds` persistence in this slice.
   - Mark-done maps to `completed: true/false` only. Do not write `status: 'done'`; leave `status` unchanged on edit and `planned` on create.
   - Color uses the prototype palette already copied in `EventBlock`; either share a local constant in `EventPopover.tsx` or extract a tiny `calendarPalette.ts` only if duplication becomes noisy. Do not refactor `EventBlock` beyond what this slice needs.
   - Run typecheck.

4. Wire create flow and remove only the always-visible create card.
   - In `CalendarPage`, replace `form` create state with an open popover state seeded from `prefill(dateIso, hour, anchor)`: title empty, clicked date, clicked hour start, one-hour duration using `DEFAULT_DURATION_MINUTES`, recurrence `none`, completed `false`, color `null`.
   - Save calls the existing `createMutation.mutate(payload)`. On success: close popover, clear participants, clear `errorMessage`, invalidate `['events']`.
   - Keep the edit card temporarily in this slice so the tree can stay green while create tests move first.
   - Rewrite the create test from "creates an event from the form" to "creates an event from a slot popover"; preserve the payload assertion for date/start/end/status/completed/recurrence.
   - Run the rewritten `CalendarPage.test.tsx` and typecheck.

5. Wire edit/delete flow, remove the edit card, and route recurring operations through the dialog.
   - `select(event, anchor)` opens the popover in edit mode seeded from the clicked event.
   - Plain save calls `updateMutation.mutate({ event, patch, target: undefined })`; plain delete calls `deleteMutation.mutate({ event, target: undefined })`.
   - Recurring save/delete does not mutate immediately. It stores a pending operation `{ mode, event, patch?, occurrenceDate }`, opens `RecurringScopeDialog`, and waits for OK.
   - `occurrenceDate` should be `event.occurrenceDate ?? event.date`; this preserves current test payloads while using the enriched occurrence field when present.
   - On scope OK, pass `{ scope, occurrenceDate }` into `updateEvent`/`deleteEvent`. On cancel, close only the dialog and return to the popover with the draft intact.
   - Change the mutation functions so the recurrence target is explicit per operation instead of reading a page-level `scope` state. This avoids stale scope values and keeps create/edit/delete independent.
   - Rewrite the plain delete, recurring delete, and recurring update tests to click an `EventBlock`, drive the popover, drive the scope dialog, and keep the existing payload assertions.
   - Run `CalendarPage.test.tsx`, `EventBlock.test.tsx`, and typecheck.

6. Add the Project -> Product -> Activity link selects in the popover.
   - Mock and import `listProjects`, `listProducts`, and `listActivities`; do not change API modules.
   - Query projects while the popover is open: `queryKey: ['projects']`, `queryFn: listProjects`.
   - Project options should use root projects (`!parentProjectId`) so product rows returned by the broad projects endpoint do not appear twice.
   - Query products with `queryKey: ['products', draft.projectId]`, `queryFn: () => listProducts(draft.projectId)`, `enabled: open && !!draft.projectId`. Disable/empty the product select until a project is chosen.
   - Query activities with `queryKey: ['activities']`, `queryFn: listActivities`, `enabled: open && !!draft.productId`, then filter `activity.productId === draft.productId`.
   - When `projectId` changes, clear `productId` and `activityId`. When `productId` changes, clear `activityId`.
   - Existing event IDs should remain in draft even if option loading fails; do not silently null a saved link because a list request failed.
   - Add tests that verify `listProducts` waits for the selected project and that selected project/product/activity IDs reach the create or update payload.
   - Run `CalendarPage.test.tsx` and typecheck.

7. Final cleanup and verification.
   - Remove now-unused `CardHeader`, `CardTitle`, `Label`, `fieldClass`, `EventDraft`, `SCOPES`, old `form`, old `draft`, and old `scope` state if no longer referenced.
   - Confirm the page body is just the grid plus existing error/loading messages and the popover/dialog portals.
   - Run `cd superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.
   - Capture light/dark screenshots for create popover, edit popover, and recurring-scope dialog if the build step has browser access. Fix only regressions introduced by this slice.

# Tests

- `CalendarPage.test.tsx`: keep the existing visible-week request, previous-week navigation, now-line, and Today navigation tests.
- `CalendarPage.test.tsx`: rewrite create from form to create from slot popover. Click a known slot by `focal.calendar.slot`, enter a title in the popover title input, save, and assert `createEvent` receives the prior core payload: `title`, clicked `date`, clicked `startTime`, computed `endTime`, `status: 'planned'`, `completed: false`, `recurrence: 'none'`.
- `CalendarPage.test.tsx`: add/keep mark-done coverage. Toggle the popover completed control and assert create/update sends `completed: true` or `false`; assert no payload writes `status: 'done'`.
- `CalendarPage.test.tsx`: rewrite plain delete to click the event block, click the popover delete button, and assert `deleteEvent(id, undefined)`.
- `CalendarPage.test.tsx`: rewrite recurring delete to click the event block, click popover delete, choose `following` in `RecurringScopeDialog`, confirm, and assert `deleteEvent(id, { scope: 'following', occurrenceDate: weekStartIso })`.
- `CalendarPage.test.tsx`: rewrite recurring update to click the event block, edit title in the popover, click save, confirm the default `single` scope in `RecurringScopeDialog`, and assert `updateEvent(id, { title, date, startTime, endTime, recurrence }, { scope: 'single', occurrenceDate: weekStartIso })` with the same core patch fields as today.
- `CalendarPage.test.tsx`: mock `../../api/projects`, `../../api/products`, and `../../api/activities`; prove product loading is dependent on the chosen project and selected link IDs are included in a create/update payload.
- `CalendarPage.test.tsx`: cover empty projects or failed link-list loading only at the UI level needed to prove no crash; mutation API failure remains covered by the existing save alert path if already present.
- `EventBlock.test.tsx`: update the click callback assertion to include the anchor argument while preserving all variant, color fallback, orphan, and repeat-marker checks.
- Final command set: `cd superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.

# Error & rescue map

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| Visible week events fail to load | Rejection from `listEvents(startIso, endIso)` | Existing `events.isError` branch in `CalendarPage` | Existing localized load alert; grid shell remains mounted. |
| Create, update, or delete fails | Rejection from `createEvent`, `updateEvent`, or `deleteEvent` | Existing `onMutationError`, reused by all three mutations | Existing localized save alert with detail when available; popover/draft stays available so the user can retry or close. |
| Recurring scope dialog is canceled | No exception; user cancels pending operation | `RecurringScopeDialog.onCancel` in `CalendarPage` | Dialog closes, no mutation runs, edit popover remains open with staged draft. |
| Anchor element disconnects before placement | No exception; stored element is not connected | `EventPopover` virtual anchor helper | Popover uses the captured fallback rect; if no rect exists, close the popover without mutating. |
| Projects fail to load | Rejection from `listProjects()` | `EventPopover` projects query `isError` | Inline localized project-load error in the goal-map section; save remains possible with existing/null IDs. |
| Products fail to load for selected project | Rejection from `listProducts(projectId)` | `EventPopover` products query `isError` | Inline localized product-load error; product/activity selects disabled or keep current saved values. |
| Activities fail to load | Rejection from `listActivities()` | `EventPopover` activities query `isError` | Inline localized activity-load error; save remains possible without changing activity. |
| User has no projects | Successful `listProjects()` returns empty/root-filtered empty | `EventPopover` project select rendering | Empty-state text in the goal-map section; product/activity selects disabled; no crash. |
| Project changes while product/activity are selected | No exception; dependent selection becomes invalid | `EventPopover` project change handler | Product and activity fields clear to `null`; product options reload for the new project. |
| Product changes while activity is selected | No exception; activity belongs to previous product | `EventPopover` product change handler | Activity clears to `null`; activity options filter for the new product. |
| ContactPicker PRIMA lookup fails | Existing `PrimaContactsError` or generic error | Existing `ContactPicker` error handling | Existing localized ContactPicker error inside its nested popover; event save payload remains unchanged. |
| Untitled new popover is dismissed | No exception; user closes before save | `EventPopover.onOpenChange`/Escape handling | Popover closes and the unsaved draft is discarded; no mutation runs. |

# Review lenses (pre-answer before gate2-plan)

- **Scope / strategy** - This is the minimum viable replacement for the inline calendar forms: one popover, one scope dialog, one anchor extension, and tests that preserve the existing mutation contract. The link selects stay in-slice because they are backable, already requested, and reuse existing APIs/patterns. The only reasonable split is the link-select block if review size becomes the blocker.
- **Architecture** - `CalendarPage` remains the owner of events query, mutations, invalidation, error alert, and open state. `EventPopover` owns only draft UI and link-list queries. Recurrence targets become explicit mutation variables instead of shared page-level `scope` state, which removes stale-scope coupling. Virtual anchoring uses Radix/Floating UI instead of manual viewport clamp code.
- **Design** - The popover follows the prototype dimensions and section rhythm while using foundation primitives. Focus lands on title, Escape/outside close, Enter saves from the title, and the recurring dialog is keyboard navigable. Loading, empty, and error states are localized in the goal-map section. The grid keeps its existing responsive overflow.
- **DevEx** - The next slice gets a reusable `EventPopover` entry point that slot click, event click, drag-create, and later conversions can open. Payload helpers in the popover make the create/update contract explicit and keep tests readable. No new services, schemas, or broad abstractions are introduced.

# Risks & migrations

- No database migration, API migration, generated OpenAPI change, config change, or backend rollout.
- Main risk is popover anchoring inside a scrollable grid. Mitigation: use Radix `PopoverAnchor virtualRef` with a live element measurement and captured fallback rect; add manual/browser verification for create and edit anchors.
- Secondary risk is widening update payloads accidentally. Mitigation: centralize payload helpers and keep existing `CalendarPage.test.tsx` assertions for core update/delete payloads.
- Tertiary risk is query churn from link selects. Mitigation: enable products only with `projectId`, activities only with `productId`, and clear dependent IDs on parent changes.
- Rollback is limited to reverting `CalendarPage.tsx`, `EventPopover.tsx`, `RecurringScopeDialog.tsx`, `EventBlock.tsx`, the popover wrapper export, locale additions, and the related tests.

# Scope check

- [x] Matches the task's Scope and Out of scope
- [x] Small enough to review in one sitting if built in the ordered slices above
- [x] Size smell checked: this touches one feature folder, one foundation wrapper export, two locale files, and tests. The goal-map selects are the only optional split point; recommendation is to keep them in this slice because the task explicitly asks for them and the implementation reuses existing list APIs.

# Out of scope

- All-day toggle; there is no backend field to preserve it.
- Convert to task or habit; that belongs to the later cross-DnD/conversion slice.
- Description and location fields; not part of the current inline forms or required prototype slice.
- Day, 3-day, month views, mini-month, left rail, side panel, bookings, prime-time, drag, move, resize, and cross-feature drag/drop.
- Server/API/schema changes or generated OpenAPI edits.
- ContactPicker persistence beyond today's local UI behavior; do not invent a PRIMA persistence bridge in this slice.

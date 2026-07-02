# Design summary

Replace the calendar's inline create/edit cards with one controlled, Radix-backed **`EventPopover`** +
a separate **`RecurringScopeDialog`**, anchored to the clicked slot/event. `CalendarPage` stays the
owner of the events query, the three mutations, invalidation, and error/loading UI; the popover owns
only its draft + the link-list queries. The two hinge decisions: (1) **anchoring** via a captured
`AnchorSource` (the clicked element + a fallback rect) fed to Radix `PopoverAnchor virtualRef`, so the
popover positions against the real grid click without wrapping grid cells in the popover tree; (2) a
**payload partition** — the five core fields (`title`/`date`/`startTime`/`endTime`/`recurrence`) are
always sent on update (today's behavior), while `completed`/`color`/`projectId`/`productId`/
`activityId` are sent **only when the user changed them** — so the existing payload-shape tests stay
green while new fields are added cleanly. Traces to `.ai/think/…-popover.md` + `.ai/plans/…-popover-plan.md`.

# Architecture

```
CalendarPage  (owns: events query, createMutation/updateMutation/deleteMutation, invalidate,
   │           onMutationError, loading/error UI, popover-open state, anchor state, pending-op state)
   │  slot click → prefill(dateIso, hour, anchor)  → open popover (mode 'create')
   │  EventBlock.onSelect(event, anchor)            → open popover (mode 'edit')
   ▼
EventPopover  (Radix Popover + PopoverAnchor virtualRef; owns draft + link-list queries)
   │  onSave(draft, dirtyFields) / onDelete(event)
   ▼
CalendarPage → mutate:  plain → mutate now;  recurring → stage pending-op + open ▼
RecurringScopeDialog  (Radix Dialog; single/following/all) → onConfirm(scope) → mutate with {scope, occurrenceDate}
```

- **`components/ui/popover.tsx`** — add `PopoverAnchor` to the re-exports (currently only
  `Popover`/`PopoverContent`/`PopoverTrigger`; the Radix primitive at `@radix-ui/react-popover 1.1.16`
  supports `virtualRef`). No other primitive change.
- **`EventPopover.tsx`** (new) — presentational + its own link-list queries; receives the anchor +
  mode + draft seed; reports `onSave`/`onDelete`/`onOpenChange`. Owns NO mutations.
- **`RecurringScopeDialog.tsx`** (new) — Radix `Dialog` + `RadioGroup`; pure chooser.
- **`EventBlock.tsx`** — `onSelect` widens to `(event, anchor: AnchorSource) => void` (the only change;
  visuals untouched). The **`AnchorSource` type is co-located in `EventPopover.tsx`** and imported by
  both `EventBlock` and `CalendarPage` — avoids a `CalendarPage`→`EventBlock` import cycle.
- **`CalendarPage.tsx`** — inline cards removed; `form`/`draft`/`scope` UI state replaced by
  `popover` (mode + draft + anchor), `participants`, and `pendingOp` state. Mutations keep their
  bodies but take the **recurrence target as an explicit per-call variable** (not the old page-level
  `scope` closure) — required because scope is chosen *after* the mutation is requested (in the dialog).

# Data model

| entity | change | notes |
|--------|--------|-------|
| — | **None** | No persistent state, schema, migration, or API change. `EventCreate`/`EventUpdate` already accept every field the popover sets; `EnrichedEventRead.occurrenceDate?` is read for the recurrence target. |

# Interfaces & contracts

**`AnchorSource`** (in `EventPopover.tsx`)
- `type AnchorSource = { element: HTMLElement | null; rect: DOMRect }`.
- A `getBoundingClientRect`-shaped virtual ref returns `element.getBoundingClientRect()` while the
  element `isConnected`, else the captured `rect`. Captured at click time from `event.currentTarget`
  (slot button or event block) + a copied rect.

**`EventPopover`** props
- `{ open; mode: 'create' | 'edit'; anchor: AnchorSource; event?: CalendarEvent; seed?: CreateSeed;
  participants: PrimaContact[]; onParticipantsChange; isSaving; isDeleting; onOpenChange(open);
  onSave(draft, dirtyFields: Set<keyof Draft>); onDelete(event) }`.
- Draft fields: `title, date, startTime, endTime, recurrence, recurrenceEndDate, color, completed,
  projectId, productId, activityId`. `dirtyFields` tracks which the user touched (for the partition).
- Renders `<Popover open onOpenChange><PopoverAnchor virtualRef={…}/><PopoverContent side="right"
  align="start" sideOffset={8} collisionPadding={12} className="w-[332px] …">`. Title autofocus;
  Enter saves; Escape/outside close (discards an untitled new draft, fires no mutation).

**`RecurringScopeDialog`** props
- `{ open; mode: 'update' | 'delete'; defaultScope?: RecurrenceScope; onCancel; onConfirm(scope) }`,
  scope ∈ `single | following | all` (the **real** `RecurrenceScope` — never the prototype's `"one"`).

**Payload helpers** (the contract the tests pin):
- **create** → `{ title, date, startTime, endTime: endTime || null, status: 'planned', completed,
  recurrence }` + `color`/`projectId`/`productId`/`activityId` **only when set**. (Same core shape as
  today.)
- **update patch** → **always** `{ title, date, startTime, endTime: endTime || null, recurrence }`;
  **plus** `completed` / `color` / `projectId` / `productId` / `activityId` / `recurrenceEndDate`
  **only when in `dirtyFields`**. (So the recurring-update test's exact-5-field patch still holds,
  while a toggled mark-done adds `completed` and a changed recurrence end adds `recurrenceEndDate`.)
  **Auto-clears count as dirty:** when changing the project clears `productId`/`activityId` (below),
  those keys are **marked dirty** so the patch sends `productId: null`/`activityId: null` — otherwise
  the "only-when-dirty" rule would silently drop a link the user just cleared.
- **mark-done** → `completed: true/false` **only**; never write `status:'done'`; `status` stays
  `planned` on create and unchanged on edit.
- **recurrence target** → `{ scope, occurrenceDate: event.occurrenceDate ?? event.date }`, passed to
  `updateEvent`/`deleteEvent` for recurring events; `undefined` for non-recurring.

**Link queries** (in `EventPopover`): `['projects']`→`listProjects` (filter `!parentProjectId`);
`['products', projectId]`→`listProducts(projectId)`, `enabled: open && !!projectId`;
`['activities']`→`listActivities`, `enabled: open && !!productId`, filtered `productId===draft.productId`.
Changing `projectId` clears `productId`+`activityId` (and marks them dirty — see the update partition);
changing `productId` clears `activityId` (likewise dirty).

# Flow (happy + unhappy paths)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| happy — create | slot click → popover → title → Save | `createMutation.mutate(payload)` | event created; popover closes; participants cleared; `['events']` invalidated |
| happy — edit (plain) | event click → popover → Save/Delete | `updateMutation`/`deleteMutation` with `target: undefined` | updated/deleted |
| happy — edit (recurring) | recurring event → Save/Delete | stage `pendingOp` → `RecurringScopeDialog` → `onConfirm(scope)` → mutate with `{scope, occurrenceDate}` | updated/deleted at chosen scope |
| unhappy — load error | `listEvents` rejects | existing `events.isError` | existing load alert; grid stays |
| unhappy — mutation error | create/update/delete rejects | existing `onMutationError` (reused by all three) | existing save alert; popover/draft stays for retry |
| unhappy — scope cancel | dialog Cancel/Escape/outside | `onCancel` | dialog closes, no mutation, popover stays with draft |
| edge — anchor disconnected | element not connected at placement | virtual-anchor helper | uses captured `rect`; if none, close popover without mutating |
| unhappy — projects/products/activities load error | link list rejects | per-query `isError` in `EventPopover` | inline localized error in the goal-map section; save still possible with existing/null IDs (a failed list never nulls a saved link) |
| edge — no projects | `listProjects` empty | project-select render | localized empty state; product/activity disabled; no crash |
| edge — parent change | project/product changed | change handlers | dependent IDs cleared; child options reload |
| edge — untitled dismiss | close before save | `onOpenChange`/Escape | draft discarded; no mutation |

# Alternatives rejected

- **Custom fixed-position panel** (the prototype's literal manual viewport clamp) — rejected for Radix
  `Popover`+`PopoverAnchor` which gives focus-scope/Escape/outside-click/collision positioning for free
  (think Option B).
- **GCal quick-create + separate full editor** — rejected; the prototype (visual contract) uses one
  richer popover (think Option C).
- **Page-level `scope` state driving the mutations** (today's coupling) — rejected for an explicit
  per-operation target, since scope is now chosen after the mutation is requested (avoids stale scope).
- **Writing `status:'done'`** (the prototype's conflation) — rejected for the real `completed` boolean.

# Test strategy

- **`CalendarPage.test.tsx`** (rewritten to drive the popover, payloads preserved): keep week-request /
  prev-week / now-line / Today; **create-from-slot-popover** (assert the prior core create payload);
  **mark-done** (toggle → `completed: true/false`, assert no `status:'done'`); **plain delete**
  (`deleteEvent(id, undefined)`); **recurring delete** (dialog `following` → `deleteEvent(id, {scope:'following', occurrenceDate: weekStartIso})`);
  **recurring update** (edit title, dialog default `single` → `updateEvent(id, {title,date,startTime,endTime,recurrence}, {scope:'single', occurrenceDate: weekStartIso})` — exact-5 patch proves the partition);
  **link selects** (mock `api/{projects,products,activities}`; prove products wait for the chosen
  project and selected IDs reach the payload); **no-projects/list-error** (no crash, save still works).
- **`EventBlock.test.tsx`**: update the click assertion to expect `(event, anchor)`; keep all slice-1
  variant/color/orphan/repeat assertions.
- **"Verified"** = `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green + before/after
  screenshots (create popover, edit popover, scope dialog — light + dark) vs the prototype.
- **Build-time watch (from the plan review):** the nested `ContactPicker` (its own Radix popover)
  inside the event `Popover` can contend on outside-click/Escape focus-scope — exercise opening the
  ContactPicker inside the popover during manual/preview verification.

# Security & release notes

- **None.** Frontend-only, presentational; no authz/injection/secret surface; no migration. The events
  API, mutations, recurrence-scope contract, and `ContactPicker` (UI-only, non-persisting — unchanged)
  are untouched. Release risk **Low**; rollback = revert `CalendarPage.tsx`, `EventPopover.tsx`,
  `RecurringScopeDialog.tsx`, `EventBlock.tsx`, the `popover.tsx` export, the locale additions, and the
  tests.

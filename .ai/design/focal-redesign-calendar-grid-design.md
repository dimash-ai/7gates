# Design summary

Restyle the week calendar **in place**, changing only appearance + the event-block structure, never
data flow. Three concrete pieces: (1) a **pure** `layoutEventLanes` helper (overlap packing,
unit-tested); (2) a presentational **`EventBlock`** component (status/orphan variants, lane geometry);
(3) `CalendarPage` re-chromed onto the foundation `PageHeader` + restyled grid + now-line, with the
existing events query, mutations, recurrence-scope, `ContactPicker`, and inline create/edit forms
**unchanged**. Traces to `.ai/think/focal-redesign-calendar-grid.md` + `.ai/plans/…-grid-plan.md`.
The one hinge decision: the event block reads **real `EnrichedEventRead` fields** (esp. `isOrphan`)
and is fed already-computed layout props, so it stays dumb and reusable by slices 2-4.

# Architecture

```
React Query (listEvents week)            ── unchanged data source
   │  events.data: CalendarEvent[]  (= EnrichedEventRead[])
   ▼
CalendarPage  (owns state, mutations, forms, errors — unchanged behavior)
   │  per day:  layoutEventLanes(eventsOn(dateIso))  → [{event, lane, laneCount}]
   │  per event: blockGeometry(event)                → {top, height}   (existing math, kept)
   ▼
EventBlock  (presentational; props in, onSelect out)  → calls existing select(event)
```

- **`lanes.ts`** — pure, no React, no mutation of inputs. Sits beside `dates.ts` (which keeps
  date/time conversion); lanes owns overlap packing only.
- **`EventBlock.tsx`** — presentational `<button>`; receives `{event, top, height, lane, laneCount,
  onSelect}`; resolves its visual variant from `event` fields; no data fetching, no popover/drag.
- **`CalendarPage.tsx`** — unchanged controller (query + `createMutation`/`updateMutation`/
  `deleteMutation` + `select`/`prefill`/`closeEditor` + scope radios + `ContactPicker`); only its JSX
  chrome (header, grid, blocks, now-line) changes. Top bar becomes the shared `PageHeader`
  (`icon`, `title`, `leftActions` = the week stepper + Today; `PageToolbar` auto-mounts on the right).
- Coupling stays one-way (page → block); no new context, store, or cross-feature import.

# Data model

| entity | change | notes |
|--------|--------|-------|
| — | **None** | No persistent state, schema, migration, or API-payload change. `CalendarEvent` = `Schemas['EnrichedEventRead']` is consumed as-is; the fields read (`isOrphan`, `status`, `color`, `recurrence`, `recurringEventId`, `date`, `startTime`, `endTime`) already exist on the contract. |

# Interfaces & contracts

**`layoutEventLanes(events: CalendarEvent[]): LaidOutEvent[]`** — `lanes.ts`
- `type LaidOutEvent = { event: CalendarEvent; lane: number; laneCount: number }`
- Pure: does **not** mutate `events` or any element. Returns one record per input event.
- Algorithm: sort by start-minute, then end-minute, then a stable key (`id`/`date`/`title`); group
  **transitive** overlaps into clusters; within a cluster assign the first lane whose last event ends
  `<=` this event's start (reuse freed lanes); stamp the cluster's final lane count onto every record.
- End-time fallback identical to `blockGeometry`: missing `endTime` ⇒ `start + DEFAULT_DURATION_MINUTES`
  (60). Minutes via the existing `minutesOf` (`dates.ts`).

**`EventBlock`** — `EventBlock.tsx`
- Props: `{ event: CalendarEvent; top: number; height: number; lane: number; laneCount: number;
  onSelect: (event: CalendarEvent) => void }`.
- Renders an absolutely-positioned `<button>`; `onClick` ⇒ `onSelect(event)` (the page passes its
  existing `select`). Width/left from `lane`/`laneCount` with a small inset so neighbors don't touch.
- **Variant resolver (confirmed map — this is the design-gate confirmation the think doc deferred):**

  | condition (first match wins) | variant | visual |
  |---|---|---|
  | `event.isOrphan === true` | `orphan` | `--color-destructive` ring + tinted danger bg + danger text/alert icon. **Overrides** color/status; never inferred from `projectId`. |
  | `event.status === 'confirmed'` | `confirmed` | filled `event.color` (or palette fallback), white text, `--shadow-xs`. |
  | `event.status === 'tentative'` | `tentative` | muted fill + dashed border, no strong shadow. |
  | `event.status === 'planned'` **or any other string** | `planned` | tinted `event.color` (or fallback) bg + colored text/border (today's create default). |

- Repeat marker shown when `event.recurrence !== 'none' || event.recurringEventId !== null`.
- Colors come from `event.color` or a **locally-copied** `CAL_PALETTE` fallback (a single deterministic
  color) when `event.color` is **null or unusable** (empty / not a valid CSS color); danger uses the
  **bridged `--color-destructive` token**, never the prototype's literal `#ef4444` /
  `--color-state-danger`. No user color-picker in this slice.

**`CalendarPage` top bar** — uses `PageHeader` (`PageHeader.tsx`: accepts `icon`,`title`,`leftActions`,
`centerActions`,`rightActions`, always mounts `PageToolbar`). `icon = Calendar`, `title =
t('focal.calendar.title')`, `leftActions =` the week stepper (prev / range-label / next) + Today. **No
view switcher** (slice 3). Geometry constant `HOUR_HEIGHT = 48` is unchanged; block min-height stays
`HOUR_HEIGHT / 2` (24px) — the **current** pixel output, not the prototype's `Math.max(16,…)`.

# Flow (happy + unhappy paths)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| happy — render week | `listEvents(start,end)` resolves | `CalendarPage` + `layoutEventLanes` + `EventBlock` | styled grid; concurrent events side-by-side in lanes; now-line on today |
| happy — edit | click a block | `EventBlock.onSelect` → existing `select(event)` | existing inline edit card opens (unchanged) |
| happy — create | click empty slot | existing `prefill(dateIso,hour)` | existing create form prefilled (unchanged) |
| unhappy — load error | `listEvents` rejects | existing `events.isError` branch | existing localized load alert; grid shell + forms stay mounted |
| unhappy — mutation error | create/update/delete rejects | existing `onMutationError` | existing localized save alert |
| edge — no `endTime` | event has `endTime === null` | `lanes.ts` + `blockGeometry` | 1-hour block (`start + 60`) — current behavior |
| edge — unknown `status` | free-form status value | `EventBlock` resolver | falls back to `planned` tinted — never throws |
| edge — null/unusable `color` | `event.color` null, empty, or not a valid CSS color | `EventBlock` color resolver | palette fallback color — never invisible |
| edge — non-today week | today outside visible week | `CalendarPage` now-line guard | now-line returns null |

# Alternatives rejected

- **Monolithic restyle / full component split** — rejected in the think doc (re-extraction churn vs
  speculative split); extract only `EventBlock` + `lanes`.
- **Interval timer to animate the now-line** — not needed this slice; compute from `new Date()` at
  render (the week view re-renders on navigation/data). A live ticking line can come with a later
  slice if wanted. Avoids a `setInterval` lifecycle in a behavior-preserving slice.
- **Infer `orphan` from `projectId`** (the prototype's `!e.project` heuristic) — rejected for the real
  `event.isOrphan` contract field (more correct; the contract already computes it).
- **Prototype literal danger color** (`#ef4444` / `--color-state-danger`) — rejected for the bridged
  `--color-destructive` token (foundation consistency, dark-mode correct).

# Test strategy

- **`lanes.test.ts`** (unit, the risky new logic): (a) `09:00-10:00` + `09:30-10:30` ⇒ `laneCount 2`,
  distinct lanes (side-by-side); (b) transitive cluster `09:00-10:00`/`09:30-10:30`/`10:00-11:00` ⇒
  one cluster, lanes reused; (c) a later non-overlapping event ⇒ `lane 0`, `laneCount 1` (flush to
  full width); (d) input array + elements **not mutated** (safe on React Query data); (e) **stable
  ordering** — events with equal start/end resolve to a deterministic lane order via the tiebreak key
  (`id`/`date`/`title`), regardless of input order. Each asserts the stated property.
- **`CalendarPage.test.tsx`** (integration, behavior preserved): keep all existing assertions green —
  visible-week request, prev-week nav, create-from-form payload, delete plain, delete/edit recurring
  with scope. Add a Today-navigation + now-line assertion using `vi.setSystemTime(...)` for a
  deterministic today column (aria-hidden marker if a stable hook is needed).
- **"Verified"** = `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green + before/after
  screenshots (light + dark) of the week grid + the four event-block states vs the prototype.

# Security & release notes

- **None.** Frontend-only, presentational; no authz, input parsing, injection, SSRF, or secret surface;
  no migration. The events API, mutations, and recurrence scope are untouched. Release risk **Low**;
  rollback = revert `CalendarPage.tsx`, `EventBlock.tsx`, `lanes.ts`, `lanes.test.ts`, and any
  `CalendarPage.test.tsx` delta.

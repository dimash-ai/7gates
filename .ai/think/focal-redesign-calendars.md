# Problem

The new Focal **Calendars page** (`features/calendars/CalendarsPage.tsx`, ~493 lines, route
`/calendars`) is a **fully functional but plain** shared-calendars manager: a join-by-code card, a
«Мои календари» section (create form + owned-calendar cards whose expanded body shows rename,
participants with role-select/remove, an invite form, and `GoogleSyncPanel`), and a «Доступные мне»
section. It must reach **exact visual parity with old-focal's `pages/Calendars.tsx`** (1,690 lines:
`CalendarsPage` + a nested `CalendarCard`) — the polished accordion design from the live screenshot:
each owned calendar is a **card with collapsible sections** «Что показывается» (filter editor),
«Участники и их права» (participants + roles), «Правила синхронизации с Google» (Google sync), an
**«Владелец»** owner badge, rename/delete/copy-invite-code, plus the «Мои календари» / «Доступные
мне» two-section layout and create/join controls.

This is a `focal-redesign-pages` slice: **re-skin only**, over the **existing** API, inheriting
slice-0's old-focal tokens/shell. The job of this think doc is to confirm it is genuinely a pure
re-skin (no backend gap) and frame the one real decision (the filter editor) against the contract.

# Assumptions

- **[confirmed — user/epic]** Binding contract = exact old-focal `Calendars.tsx`; reproduce on the
  new stack (Tailwind 4 / React 19 / shadcn), light **and** dark, strings via i18next `ru`+`en`
  reusing old-focal copy, **no** server/API change. (See `.ai/think/focal-redesign-pages.md`.)
- **[confirmed — fs]** The new page is **fully wired** to `api/sharedCalendars.ts`: `listMyCalendars`,
  `listAccessibleCalendars`, `createCalendar`, `updateCalendar`, `deleteCalendar`, `joinByInviteCode`,
  `listParticipants`, `inviteParticipant`, `updateParticipantRole`, `removeParticipant` — with query
  keys `['shared-calendars', …]` and invalidation. `GoogleSyncPanel` already exists. → re-skin keeps
  all wiring; **no** data-layer work.
- **[confirmed — openapi.d.ts]** Old-focal's **«Что показывается» filter editor is backed**:
  `SharedCalendarCreate`/`SharedCalendarUpdate` carry `filterType: string`, `filterValue?: string|null`,
  `filterRules?: {…}` (+ `name`, `color`, `isActive`). The new page currently **hardcodes
  `filterType: 'all'`** on create and never edits it → the re-skin wires the **already-present** fields
  into old-focal's filter editor (all / workTime / personalTime / mission / provision). **No API
  change**, just surfacing backed fields. This is the slice's one substantive addition.
- **[confirmed — fs]** The new app already ships the primitives the design needs — `ui/accordion.tsx`,
  `ui/collapsible.tsx`, `ui/select.tsx`, `ui/dialog.tsx`, `ui/popover.tsx`, `ui/switch.tsx`,
  `ui/badge.tsx`, `ui/card.tsx`, `ui/button.tsx`, `ui/input.tsx` → no new primitive expected (unlike
  the heatmap slice, which had to add `multi-select`).
- **[confirmed — fs/screenshot]** old-focal `Calendars.tsx` features: create / join / delete / rename,
  participant invite + **role change** + remove, **copy invite code**, **leave calendar**, the filter
  editor, the **«Владелец»** badge, and the collapsible «Что показывается» / «Участники и их права» /
  «Правила синхронизации с Google» card layout (matches `focal.allosta.com/calendars`).
- **[confirmed — app CLAUDE.md]** Roles = the 6 RBAC roles `owner / full_access / editor / developer /
  viewer / requester`; invite assigns the non-owner five (the page's `INVITE_ROLES` already reflects
  this). Role **labels** come from i18next `focal.calendars.roles.*`.
- **[confirmed — openapi.d.ts / old-focal]** Both remaining affordances are **backed**:
  - **«Leave calendar»** = a participant removing **their own** row. old-focal's leave is its
    `removeParticipantMutation` with `isSelf` against `DELETE .../participants/{id}` — the new app's
    existing `removeParticipant(calendarId, participantId)` hits the same route. The user's own
    participant id comes from the existing `GET /api/shared-calendars/my-participation` endpoint (in the
    contract) via a **thin frontend-only wrapper** to add (`listMyParticipation`) — **no server change**.
  - **«Copy invite code»** = a clipboard copy (`navigator.clipboard.writeText`) of the **per-participant
    pending `inviteCode`** the page already renders as a Badge — **no API call**. `SharedCalendarRead`
    carries **no calendar-level `inviteCode`** (confirmed: `id`/`userId`/`name`/`googleCalendarId`…), so
    if old-focal also exposes a *calendar-level* share code that specific control is **not backed** and
    is **flagged/deferred, not faked** (settled at gate 3).
- **[unverified — settle at design gate]** the exact `filterRules` shape for the mission/provision
  sub-options, and the accordion open/close defaults. Neither blocks the re-skin; both resolved against
  `openapi.d.ts` + old-focal at gate 3.

# Options considered

The source + "re-skin, not rebuild" are decided by the epic; the real forks are **(1)** how to build
the card and **(2)** how to treat the filter editor.

| # | Option | What it is | Pros | Cons |
|---|--------|-----------|------|------|
| **A — In-place re-skin over the existing API (chosen)** | Restyle `CalendarsPage.tsx` to old-focal's structure using the new app's existing shadcn primitives (Card + Accordion/Collapsible + Badge + Select + Dialog) + slice-0 tokens; keep every `api/sharedCalendars.ts` call, query key, and mutation; wire the backed filter fields into the «Что показывается» editor. | Surgical; no data-layer churn; uses primitives already present; exact-old-focal look; independently testable. | We translate old-focal's 1,690-line structure by hand into the new component tree. |
| **B — Port old-focal's `Calendars.tsx` + `CalendarCard` wholesale** | Copy the old component tree and rewire its `apiRequest`/Wouter/query calls to the new `api/*`. | Maximal literal fidelity fast. | Drags React-18 / Tailwind-3 idioms and old-focal's data layer; large non-surgical diff; rewiring cost ≈ option A anyway. **Rejected.** |

**Filter editor (sub-fork):** since `filterType`/`filterValue`/`filterRules` are **backed**, **include
it** (option A wires it). The only open part is the exact `filterRules` mission/provision shape, settled
at the design gate against the schema; if any sub-control turns out unbacked it is **flagged, not faked**.

# Recommendation

**Option A — in-place re-skin over the existing API**, primitives already present, the **«Что
показывается» filter editor wired onto the backed `filterType`/`filterValue`/`filterRules` fields**.
Rationale: the page is already fully wired and every old-focal affordance maps to an existing endpoint
(leave-calendar via a thin `my-participation` wrapper, copy-code via clipboard of the rendered
per-participant `inviteCode`) or a backed field, so a wholesale port (B) only adds churn and
stack-mismatch for no fidelity gain. The slice is a true presentation change plus surfacing
backed-but-hidden filter fields.

# Out of scope

- Any **server / API / schema / contract** change. A field old-focal shows that the contract lacks →
  separate handoff, flagged, never faked.
- **Behavior / data-flow** changes — query keys, mutations, invalidation preserved.
- The **`/calendar` view's** per-calendar show/hide filtering (a calendar-slice concern); here we only
  edit a calendar's **stored** filter config.
- `GoogleSyncPanel` **internals** — restyle only.
- Other left-nav pages.

# Open questions

- **`filterRules` shape** for the mission/provision sub-options — read the schema at gate 3 and wire only
  what's backed.
- **Accordion defaults** (which sections open by default; single vs multi-open) — match old-focal at gate 3.
- **Role labels / set** — reuse `focal.calendars.roles.*`; confirm the i18n keys exist or add them.

# Success criteria

- [ ] `/calendars` matches old-focal `Calendars.tsx` by screenshot in **light + dark** — page header
      (icon + title; the AI button + sidebar trigger are supplied by the inherited shell
      `PageHeader`/`PageToolbar`), accordion card (filter / participants / Google-sync), «Владелец»
      badge, «Мои календари» / «Доступные мне» layout, create + join, empty states.
- [ ] Behavior preserved: create / rename / delete / join / participant invite-role-remove still work;
      **leave-calendar** (self-removal via `my-participation` + `removeParticipant`) and
      **copy-invite-code** (clipboard of the rendered per-participant `inviteCode`) work; the «Что
      показывается» editor persists `filterType`/`filterValue`/`filterRules`; existing
      `CalendarsPage.test.tsx` still green (updated only where the DOM it asserts moved).
- [ ] Surgical: only `features/calendars/*` (+ i18n keys; a `ui/*` primitive only if one is genuinely
      missing — none expected); **no** server/API change; no `any`; i18next `ru` + `en`.

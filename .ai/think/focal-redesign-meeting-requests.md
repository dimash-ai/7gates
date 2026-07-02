# Problem

Bring the new Focal **Запросы на события** page to exact parity with `apps/old-focal`'s
`MeetingRequestsPage.tsx`, on the shell foundation (slice 0), over the existing `api/meetingRequests`.
Unlike slice 0 (a pure token cascade), this is a **per-page re-skin that also closes structural
gaps**: the new page is functionally complete but visually + structurally diverges from old-focal.

Read both: the new `features/meetings/MeetingRequestsPage.tsx` is a single functional component
(i18next throughout, react-query over `api/meetingRequests` with accept/decline/tentative/
reschedule-accept/reschedule-decline/delete mutations, semantic tokens, inline request cards). The
old-focal contract has more UI: a **search + calendar + type filter row**, **status Tabs** with
per-tab icons + count badges, and a dedicated **`MeetingRequestCard`**. So the slice = restyle the
existing page to old-focal's look **and** add its missing filter/tab UI, while keeping the working
data layer.

The honest scope tension to manage: old-focal's **calendar filter** needs accessible-calendars data
plus a `sharedCalendarId` on each request. If the new `api/meetingRequests` request shape / API does
not carry that, the calendar filter is **backend-blocked** and must be flagged (surfaced, not faked)
— the search + type filters (pure client-side over the loaded list) and the status Tabs are
unconditionally backable. Also, old-focal's header embeds an AI-assistant button; the new app routes
AI through the shared shell toolbar, so whether the page header carries an AI control is a design
decision, not an assumed port.

# Assumptions

- **[confirmed — git]** The slice branch `feat/focal-redesign-meeting-requests` is cut off
  `feat/focal-redesign-shell` (HEAD `afaaeba`) in a dedicated worktree, so it inherits old-focal's
  exact tokens/radius/shadows from slice 0. (old-focal is untracked in superapp → absent from the
  worktree; its contract is read from the main checkout.)
- **[confirmed — inspection]** New `features/meetings/MeetingRequestsPage.tsx` is functional: all
  strings via `t(...)` (`focal.meetingRequests.*`), react-query over `api/meetingRequests`, the full
  mutation set, status filter as a **Button row** (no Tabs/icons), **no** search/calendar/type
  filters, **inline** cards (status left-border, type/status badges, time/reschedule-was/location/
  organizer/description, accept/decline/tentative + delete), `bg-primary/10` badges, `max-w-3xl`.
- **[confirmed — inspection]** old-focal `pages/MeetingRequestsPage.tsx` (465 lines): header
  (CalendarClock + title + yellow pending badge + AIAssistantHeaderButton, desktop-1-row/mobile-2-row);
  search Input + calendar Select + type Select; status **Tabs** (all/pending/accepted/declined/
  tentative) with Inbox/Check/XCircle/HelpCircle icons + count Badges; `MeetingRequestCard` list;
  CalendarClock empty Card; `max-w-4xl`.
- **[confirmed — inspection]** The new request object already carries `title`, `startTime`/`endTime`,
  `originalStartTime`/`originalEndTime`, `location`, `organizerName`/`organizerEmail`, `description`,
  and status/type — so the **card** and the **search + type** filters are fully backable on existing
  data.
- **[unverified — settle at design gate]** whether the new `api/meetingRequests` request carries a
  `sharedCalendarId` (+ an accessible-calendars source) for the **calendar filter**; whether the
  page should keep its own header or adopt the shared `PageHeader`; and the exact `MeetingRequestCard`
  visual details. Resolved by reading `api/meetingRequests` (`requests.ts`) + old-focal's
  `MeetingRequestCard.tsx` at design.

# Options considered

Source of truth is fixed (exact old-focal). The real forks: **(1)** how to converge the page, and
**(2)** how to handle the calendar filter's data dependency.

| # | Option | What it is | Pros | Cons |
|---|--------|-----------|------|------|
| **A — Restyle in place (chosen)** | Keep the existing component's data/mutation/i18n wiring; restyle header + cards to old-focal, and add the search + type filters and the status Tabs (icons + counts) over the already-loaded list. | Surgical (one feature dir); preserves the working API/mutations/tests; the added filters are pure client-side over loaded data; stays on the new stack + shell tokens. | We hand-map old-focal's structure onto the new component; the calendar filter may be data-blocked. |
| **B — Port old-focal's page + MeetingRequestCard wholesale** | Copy old-focal's page + card component in. | Fastest literal fidelity. | Drags in `apiRequest`/`fetchWithAuth`/wouter coupling + a different request shape + Tailwind-3 idioms + `useToast`/`CalendarFilterContext` deps the new app doesn't have; would need full rewiring. **Rejected.** |

Calendar-filter fork (2): **(a)** include it if `api/meetingRequests` exposes `sharedCalendarId` +
accessible calendars; **(b)** otherwise flag it backend-blocked and ship the search + type filters +
Tabs (the backable majority), with the calendar filter deferred to a named handoff. Decided at the
design gate after reading `requests.ts`. Default: **(b)** unless the data is already there.

# Recommendation

**Option A — restyle in place**, with the calendar filter gated on real data (fork 2b by default).
Rationale: the page already works on the new API with full i18n and the complete mutation set, so the
minimal change that reaches "exact old-focal" is to converge *presentation + the backable filter/tab
UI* — not to re-port the page and its data layer (B), which imports a foreign stack. Search + type
filters + status Tabs + the card restyle are all backable on the data the new page already loads; the
calendar filter is the only piece with a possible backend dependency, and it is flagged, not faked.

Plan shape (settled at gate 2):
1. Read `api/meetingRequests` (`requests.ts`) + old-focal `MeetingRequestCard.tsx` → confirm the
   request shape (esp. `sharedCalendarId`) and the exact card visuals.
2. Header → old-focal (CalendarClock + title + pending badge); decide PageHeader vs bespoke.
3. Add search + type filters (client-side); status Button row → Tabs with icons + counts.
4. Restyle the card to `MeetingRequestCard`; match empty/loading.
5. Calendar filter only if backable; else flag. i18next ru + en (reproduce old-focal copy).
6. `pnpm lint && typecheck && test:run && build` green in the worktree; screenshot light + dark.

# Out of scope

- Any server / API / schema / behaviour change (frontend-only; a missing field is a flagged handoff).
- The shell (slice 0, inherited); other pages; porting old-focal's Tailwind-3 / `apiRequest` / wouter
  / context wiring wholesale.

# Open questions

- **Calendar filter data** — does `api/meetingRequests` carry `sharedCalendarId` + an
  accessible-calendars source? If not → defer that one filter (flagged), ship the rest. (Gate 2/3.)
- **Header** — adopt the shared `PageHeader` (consistent with the redesigned shell) or reproduce
  old-focal's bespoke desktop-1-row/mobile-2-row header? (Gate 3.)
- **AI control** — old-focal's header has an AI-assistant button; the new app routes AI via the shell
  toolbar. Keep it out of the page header unless the shell doesn't already surface it. (Gate 3.)
- **Card parity** — exact `MeetingRequestCard` details (spacing, badge colours) confirmed against
  the component at design.

# Success criteria

- [ ] From the worktree: `cd apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run &&
      pnpm build` green with the existing + any added tests.
- [ ] The page matches old-focal's MeetingRequestsPage in light + dark — header, filter row, status
      tabs with counts, cards (all states incl. reschedule-was), empty/loading — by screenshot.
- [ ] Behaviour preserved: accept/decline/tentative/reschedule/delete still work over the existing
      API; no regression in `MeetingRequestsPage.test.tsx`.
- [ ] Backable vs deferred is explicit: search + type + tabs + card shipped; the calendar filter
      either backed by real data or flagged backend-blocked. No hardcoded strings; surgical diff.

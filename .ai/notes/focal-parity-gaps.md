# Findings: focal-parity-gaps

> Output of the **explore gate** (`/gate-explore focal-parity-gaps`). Two independent takes — Opus
> and GPT — synthesized. Raw per-model answers in `.ai/scratch/focal-parity-gaps-{opus,gpt}.md`
> (gitignored). Not scored. Date: 2026-07-02.

## Questions

1. Frontend: which user-visible functional differences remain today between `apps/focal/client`
   and `apps/old-focal/client`?
2. Backend: which API/business-logic differences remain beyond the deliberate divergences
   documented in `PARITY.md`?
3. Database: which schema differences remain (Drizzle `shared/schema.ts` vs SQLAlchemy
   `server/app/models`), and which block parity features?
4. What is the ranked shortest path to 100% functional parity?

Baseline: `apps/focal/docs/contract-freeze/FRONTEND_PARITY.md` (2026-06-29) is the gap ledger;
both models re-verified every row against current code (~15 commits landed after it). Paths below:
OLD = `apps/old-focal/`, NEW = `apps/focal/`.

## Consensus

### Ledger rows CLOSED since 2026-06-29 (strike them in FRONTEND_PARITY.md)

Confidence: High — both models verified in current code.

- **CAL-1 variable row heights** — `client/src/features/calendar/geometry.ts:6-36`.
- **CAL-2 undo** (stack + toolbar + Cmd/Ctrl+Z, create/delete/edit/move/resize/convert) —
  `CalendarPage.tsx:411-417,1001-1035,1135-1138`.
- **CAL-3 drag-create** with ghost + 15-min snap — `TimeGrid.tsx:195-302`.
- **CAL-4 task↔event drag conversion** on dnd-kit — `dnd.ts`, `TaskPanel.tsx:62-90`,
  `CalendarPage.tsx:910-1000`.
- **SHARE-1 invite code** generated/displayed/copied — `CalendarsPage.tsx:529-540`.
- **OFF-1/TSK-3 (queue part)** offline queue covers events/tasks/projects/goal-map —
  `offline/queue.ts:17-25` (`/api/spheres` excluded deliberately, comment at :18-20).
- **OFF-4** OfflineIndicator popover with pending count/last-sync/manual sync —
  `offline/OfflineIndicator.tsx:68-141`.
- **GS-2** Google hub — function moved to Calendars page (`MainCalendarGoogleSection.tsx` is rich:
  status/select/sync), not missing.
- **GOAL-9 partial** — undo/redo now covers move+reparent+rename; still not create/delete.

### Still OPEN — High severity

Confidence: High — both models, current-code evidence.

- **XCUT-1/2 no ErrorBoundary / ErrorFallback / Toaster in the shell** — grep = 0 hits; old
  mounted route-level boundary + Toaster (`OLD client/src/App.tsx:221,234`). A render error
  white-screens the new app; success feedback (INT-1/TSK-4/GS-3 toasts) is the same missing
  shell piece. Unplanned in the epic.
- **XCUT-3 HelpTooltip** — ~3 ad-hoc `/help?tab=` links vs 33 old call sites; no reusable
  component. Unplanned.
- **AI-1 chat ignores selected calendar + data-owner** — `AIChatPage.tsx` never imports
  `useCalendarFilter`; body = message/currentEvent/userToday/displayTimezone only
  (`api/aichat.ts:68-72`). Backend is ready (`api/ai_chat.py:70,204` + `data_scope.py:182`
  resolve_ai_data_owner) — pure client wiring. Doubles as the cutover data-scope audit item.
- **GS-5 (NEW, found by GPT, verified by Opus): auto Google push on event CRUD lost** — old
  fire-and-forget synced every create/update/delete (`OLD server/routes.ts:2820,2867,2943`
  `syncSingleEventToGoogle`); new `services/calendar.py` has zero Google side-effects, outbound
  sync is manual/explicit only (`api/integrations.py`), and no Celery task does periodic outbound
  push. Google-connected users silently diverge. Not in any ledger/design → needs decision
  (restore vs documented deferral), see Open.
- **EVT-2 EventInfoDialog** (read-only view + inline date/time/status edit + copy/convert) —
  absent; click opens the edit dialog directly.
- **EVT-1 custom recurrence — reframed**: legacy **never persisted or honored it**. Old schema has
  no interval/unit columns (`OLD shared/schema.ts:303-307`); old server strips the field on PATCH
  (`routes.ts:2890`) and omits it on POST (`routes.ts:2772`); and old expansion recognizes only
  daily/weekly/monthly/yearly (`OLD server/utils/recurrence.ts:18-19` `isRecurringType`), so an
  event saved with `recurrence="custom"` behaved as a **one-off** — the old UI
  (`EventDialog.tsx:969-999`) was a placebo end-to-end. Both models found this independently.
  So EVT-1 is "build a feature the reference only pretended to have" — product decision, not a
  parity port (see Open). ETL note regardless of the decision: NEW API **rejects** "custom"
  (`domain/recurrence.py:7`, `schemas/calendar.py` `_check_recurrence_value` → 422), so legacy
  rows must be normalized `custom → none` at migration (behaviorally identical to old).

### Still OPEN — Medium

Confidence: High unless noted.

- **EVT-3 + TSK-2 contact pickers don't persist** — both dialogs collect PRIMA contacts but omit
  `contactIds` from save payloads (`eventsFilters.ts:409,496`; `TaskDialog.tsx:113-116,297`);
  backend schemas already accept them (`schemas/calendar.py:84,154`, `schemas/tasks.py:49`).
  → **DECIDED: wire now** (PRIMA CRM live and ready — see Decisions).
- **INT-2** month-view / all-day drag-move (MonthView is read-only, `MonthView.tsx:26-30`).
- **EVT-4/INT-5** recurring-scope dialog never suppresses "this event" (`RecurringScopeDialog.tsx:17,55`
  vs OLD `RecurringEventDialogs.tsx:91,123` allowSingle).
- **EVT-5** convert/duplicate not on Events page. **TSK-1** no tags entry from Tasks header.
- **GOAL-1/2/3/6** graph editing still read-only vs old editor: `nodesConnectable`/
  `elementsSelectable={false}` (`GoalsPage.tsx:762-763`), no edge dialog (old `MindMap.tsx:2181,4407`),
  no budget money fields (`NodeEditModal.tsx:56` vs old `PyramidNode.tsx:573`). **GOAL-4** move
  preview lacks events/tasks/bookings counts; **GOAL-5** no sphere reassign on reparent.
- **HAB-1** category chips; **HAB-2** reorder (no dnd, no arrows — old `HabitJournal.tsx:606,798`).
- **SHARE-2 partial** — join-by-code works (`api/sharedCalendars.ts:31-35`), server accepts
  email-less invites (`schemas/shared_calendar.py:127`), but the owner UI still requires email
  (submit disabled without it, `CalendarsPage.tsx:1445-1473`). **SHARE-3** join-error
  disambiguation missing.
- **OFF-2** SyncStatusIndicator (Google last-sync in sidebar) absent. **TSK-3 tail**: tasks still
  plain mutations (`TasksPage.tsx:354,364`); `offlineAwareMutation.ts:14` is explicitly
  per-feature adoption — tasks/events pages haven't adopted optimistic paths.
- **SET-1** agent-token rename — server endpoint exists (`api/agent_tokens.py:64`), client API
  (`api/agentTokens.ts:11`) and UI lack it. **SET-2** push scope badges. **SET-3** backup
  calendarId scope + replaceExisting.
- **SPH-1** `/spheres` orphaned from sidebar nav (`AppSidebar.tsx:75`).
- **CAL-6** year view: dots only, bookings non-interactive (`YearView.tsx:27,117` vs OLD
  `CalendarViews.tsx:4712-4842` popovers/dbl-click/segmented fills). **CAL-7** dual-timezone
  display absent (`EventBlock.tsx:366` renders raw times vs OLD `EventCard.tsx:92-102`).
- **AI-2 voice robustness partial** — continuous re-arm exists (`VoiceControl.tsx:16,219-241`);
  missing 30s inactivity stop, 5s network backoff, iOS premature-onend recovery, mic watchdog,
  Chrome interim fallback; top-level chat voice is single-shot (`VoiceInput.tsx:9,59`).
  **AI-4** hands-free clarify loop partial. **BK-1/2** booking tags + activity link (deferred
  comment `BookingDialog.tsx:43-46`).

### Still OPEN — Low (polish sweep)

CAL-8 now-line text label, CAL-11 :30 gridline, CAL-12 weekend shading, CAL-13 ISO week label,
CAL-14 day-header inline prime-time, INT-3 click minute-snap (arguably superseded by CAL-3
drag-create), INT-6 prime-time band click-to-open (`pointer-events-none`), INT-7 grid-drag date
nav, EVT-6 end-date guard, EVT-7 inline field errors (server validates,
`schemas/calendar.py:136-139`), EVT-9 converted-time preview, TSK-5/6, OFF-3 PullToRefresh
targeted refetch (now generic `PullToRefresh.tsx:21`), OFF-5 iOS splash/tile meta partial,
GS-3 OAuth-return toast. (GOAL-7/8 moved into the strict-parity goals cluster per Decisions.)

**Retired as accepted deviations (semantics decision, 2026-07-02):** CAL-5, CAL-9, CAL-10, INT-4,
ANL-1, GS-4, EVT-8, HAB-3, TB-1.

### Backend (Q2)

- **Route parity done and CI-gated**: 193/193 kept routes served or allow-listed (`PARITY.md:9`);
  19 documented divergences stand (health/status, project-move fold, CRM→PRIMA interim path,
  sync-settings deferred, admin fix-event-times + push cron dropped/relocated — the two "dropped"
  still want one-line product acks, `PARITY.md:30-33`).
- **All background jobs mapped to Celery Beat** (`celery_app.py:24-45`): watch renewal 1h,
  cohort-MV 15m, identity-sync 6h, push sweep 60s, + new AI conversation sweep. Leader-election
  correctly dropped.
- The only undocumented behavioral deltas found: **GS-5 auto-Google-push** (above) and
  recurrence-scope moved to query params (documented intentional, `api/calendar.py:74`).
- AI data-owner RBAC resolution exists server-side; gap is client wiring (AI-1).

### Database (Q3)

- **All 37 kept legacy tables are modeled** — verified by matching `tables.json` kept names
  against `__tablename__` across `server/app/models/*.py` (38 modeled); "2 unmodeled" was an
  artifact of `tables.json`'s **stale per-table `model.status` snapshot** (flag for cleanup — it
  misleads audits). `calendar.py:50-57` carries the full recurrence set + `CalendarEventOverride`.
- **New is ahead of legacy**: tasks persist `recurrence`/`contact_ids`/`other_participants`
  (`models/tasks.py:26+` — legacy silently dropped these), `Project.icon`, composite per-user
  mindmap keys; bookings at/above legacy (tags+source present — frontend is the blocker);
  mindmap **edge schema** matches old styling fields (`models/mindmap.py:30`) — only the UI
  disables edge mutation.
- **Intentional**: `sessions` dropped (Supabase JWT); users = shadow id/email (auth externalized);
  events dropped legacy denormalized `project`/`product` text + `crmInteractionId`
  (`OLD schema.ts:293,330`) — keeps FKs instead; only affects ETL of text-only legacy rows.
- **No schema gap blocks any open frontend gap** except EVT-1 *if* we decide to build real custom
  recurrence (then: interval/unit columns + expansion + UI, developer-owned migration handoff).

## Divergence

- **Priority order for the remaining work** — *resolved 2026-07-02*: the user's decisions
  (restore GS-5, wire contacts now, data-migration safety as the hard bar) select the
  data-integrity-first merge; final order lives in Next. (Original stances: Opus led with
  safety-net + authz; GPT led with persistence mismatches — the merged order takes both tops.)

## Decisions (2026-07-02, user)

- **GS-5 Google auto-push: RESTORE.** Port the fire-and-forget single-event push on event
  create/update/delete into the new calendar flow (parity with `OLD routes.ts:2820,2867,2943`),
  async and non-blocking; scope in a dedicated slice (recurring-scope edits + delete semantics
  need the old mapping).
- **Goals graph: STRICT parity.** GOAL-1..8 are all in scope (manual edge drawing + edge-edit
  dialog + line-type toggle, budget money fields, move-preview counts, sphere reassign,
  pan/box-select, drag-out create, snap-to-grid), plus finish GOAL-9 (undo for create/delete).
  The read-only-graph simplification is rejected as a parity substitute.
- **EVT-1 custom recurrence: SKIP now, post-cutover backlog.** Not part of the parity epic (the
  reference never persisted or honored it). The build-for-real version (interval/unit columns +
  expansion + UI, migration handoff) goes to the post-cutover backlog. Binding ETL guardrail
  stays: normalize legacy `recurrence="custom"` → `none` (new API 422s on "custom").
- **"100%" semantics: SUPERSETS ACCEPTED — frontend follows best practices; the hard bar is
  "nothing breaks the data migration".** The nine same-capability-different-mechanism rows are
  retired as accepted deviations: INT-4 single-click create, CAL-9 scroll anchor, CAL-5 scaling
  algorithm, CAL-10 fixed zoom, ANL-1 shared period selector, GS-4 unified sync button, EVT-8
  6-color palette, HAB-3 immediate writes, TB-1 sphere-add on `/spheres`. Information/affordance
  gaps (CAL-8/11/12/13 etc.) remain real Low gaps.
- **TSK-2 + EVT-3 contacts persistence: WIRE NOW.** The deferral reason is gone — **PRIMA CRM is
  live and ready for use** (`superapp/apps/prima`, user-confirmed 2026-07-02). Send `contactIds`
  from both TaskDialog and EventDialog save payloads (backend schemas already accept them); drop
  the "UI-only pending crm-boundary" comments. This also downgrades the PARITY.md cutover risk
  "interim PRIMA contacts path depends on PRIMA being live" — it is.

## Open

- Last three acks (proposed defaults; treated as confirmed unless vetoed): **admin
  fix-event-times** — confirm drop (one-off admin repair tool, never user-facing);
  **push check-reminders** — confirm drop of the HTTP hook (Celery Beat runs the sweep; disable
  the external cron at cutover); **BK-1/2 booking tags + activity link** — pull into the Med
  sweep (columns exist, frontend-only; consistent with the strict-parity course).
- Data-migration guardrails to carry into the ETL plan: `recurrence="custom"` → `none`;
  mapping policy for legacy events' denormalized `project`/`product` text columns +
  `crmInteractionId` (new model keeps FKs instead — `OLD schema.ts:293,330`).
- Housekeeping: update `FRONTEND_PARITY.md` (strike closed rows, add GS-5, record the accepted
  deviations), fix stale `tables.json` model.status fields.

## Next

**Confirmed order** (all decisions in): 1) AI-1 chat calendar/data-owner wiring + **GS-5
auto-push restore slice** (data-integrity first); 2) shell slice — ErrorBoundary/Fallback + toast
infra (unlocks INT-1/TSK-4/GS-3) + HelpTooltip; 3) persistence fixes — EVT-3/TSK-2 contactIds
(PRIMA live), SET-1 rename UI, SHARE-2 code-only invite; 4) EVT-2 InfoDialog + recurring-scope
suppress (EVT-4/INT-5); 5) **goals strict-parity cluster (GOAL-1..8 + undo completion)**;
6) Med sweep (OFF-2, SPH-1, SET-2/3, HAB-1/2, CAL-6/7, BK-1/2, voice AI-2/4); 7) Low polish sweep
(trimmed list above); 8) ledger + `tables.json` housekeeping. Post-cutover backlog: EVT-1
build-for-real custom recurrence. Each slice seeds `/gate-design <slug>` as usual.

# Findings: focal-calendar-parity

> Output of the **explore gate** (`/gate-explore focal-calendar-parity`). Two independent takes —
> Opus (incl. live side-by-side of both productions in the user's Chrome) and GPT (static code
> audit) — synthesized. Raw answers in `.ai/scratch/focal-calendar-parity-{opus,gpt}.md`
> (gitignored). Calendar-scoped follow-up to `focal-parity-gaps.md` (2026-07-02). Not scored.
> Date: 2026-07-02.

## Questions

1. Frontend: which calendar-related user-visible deltas remain (grid/views, /calendars page,
   events/recurrence, bookings, meeting requests, google, offline)?
2. Backend: which calendar-domain API/business-logic deltas remain?
3. Database: which column-level diffs remain on calendar tables; which block behavior or ETL?
4. **Assurance: what repeatable harness guarantees full calendar parity through cutover?**

Productions compared live: OLD `focal.allosta.com/calendars` vs NEW `focal-prod.pages.dev/calendars`,
same signed-in account. OLD = `apps/old-focal/`, NEW = `apps/focal/`.

## Consensus

### /calendars page — new gaps (both models independently; Opus verified live)

- **SHARE-4 (Med-High): participating-calendar card stripped.** Old renders calendars you
  participate in with the same expandable card as owned ones — filter summary («Что показывается»),
  member list, per-calendar Google rules (`OLD Calendars.tsx:887-907`; verified live on old prod).
  New shows a flat row: dot, name, role, count, «Покинуть» (`CalendarsPage.tsx:1274-1320`; verified
  live on new prod). A participant can no longer inspect any of the three sections.
- **SHARE-5 (Med): participant names not rendered — root cause is the backend serializer.** Old
  shows firstName+lastName when known (`OLD Calendars.tsx:1568-1578`); new shows email only, and
  the new API serializes only `user.email` (`services/shared_calendars.py:604-623`) — fix is
  backend+frontend, not UI-only.
- SHARE-2 (settled: wire) — invite email-gated vs old code-only invite+display
  (`OLD Calendars.tsx:1125-1205` vs `CalendarsPage.tsx:1436-1476`). SHARE-3 join-error
  disambiguation still open (Low). Participant count "(n)" in owned-card section header missing
  (Low, `OLD Calendars.tsx:1504-1508`); 8-color preset palette → native picker (Low).
- **New is AHEAD:** filter EDITING on existing owned calendars (`CalendarsPage.tsx:431-443` —
  old set filters only at create), visible load/error states, better ARIA. Everything else on the
  page at parity: main-calendar card (localStorage keys, badge, `mainCalendarUpdated`),
  create/join/edit/delete/leave dialogs, 5 invite roles, pending badges + code copy, filter
  display resolution, typed-confirm delete.

### Calendar grid/views (imported from `focal-parity-gaps.md`, re-confirmed)

Closed since 29.06: variable row heights, undo, drag-create + snap + ghost, task↔event dnd
convert, view persistence. Open: CAL-6 year-view booking interactivity (both models re-confirmed:
dots non-interactive, `YearView.tsx:117-134` vs `OLD CalendarViews.tsx:4718-4884`), CAL-7
dual-timezone display, CAL-8/11/12/13/14 Lows, INT-1 toasts, INT-2 month-drag, INT-3 minute-snap,
INT-5 allowSingle, INT-6/7 Lows. EVT-2 InfoDialog, EVT-3 contacts (settled: wire), EVT-4/5/6/7/9.
BK-1/2 deferred in dialog. EVT-1 custom recurrence: GPT independently re-confirmed the legacy
placebo (`OLD routes.ts:2886-2892`) — settled SKIP stands.

### Backend (verified; four explorer false-alarms refuted first-hand)

At parity: **recurrence-scoped mutations fully ported** (query params `api/calendar.py:74-124`;
single/following/all + series split `services/calendar.py:72,228-247`); **iCal export+import
wired** (`api/ical.py:19-39` → `services/ical.py`); **RSVP propagation exists**
(`services/meeting_requests.py:12` → `google_meetings.propagate_*`); webhook→Celery + watch
renewal 1h + server-side shared-calendar filter (`domain/shared_calendar_filter.py:50-74`).

Real deltas:
- **GS-5 (settled: RESTORE): auto Google push on event CRUD lost** (`OLD routes.ts:2820,2867,2943`
  vs zero google side-effects in `services/calendar.py`; no outbound Beat task).
- **GS-6 (NEW, both models): the auto-sync INTERVAL is a placebo in BOTH apps.** No scheduler or
  client timer consumes `auto_sync_interval` anywhere (old: stored/round-tripped only,
  `OLD googleCalendar.ts:1335,1375`; new: `services/google_integration.py:173-174`; Beat list
  `celery_app.py:24-45` has no sync task). Nuance (GPT): old's `autoSync`/`syncMode` FLAGS did
  gate the per-CRUD push (`OLD googleCalendar.ts:1447-1457`) — the boolean mattered, the interval
  never did. → Decide inside the GS-5 slice: implement the interval for real (Beat task) or drop
  the control.
- **MEET-1 (NEW, GPT found, Opus verified): meeting-accept event loses linkage.** New accept
  creates the focal event WITHOUT `source_type="meeting_request"`/`source_id`/`google_event_id`
  (`services/meeting_requests.py:95-105`); old wrote all three
  (`OLD googleCalendarMeetings.ts:313-325`). Once GS-5 restores push, the unlinked event can't be
  deduped against the original Google event → duplicate meetings in Google. Fix belongs WITH the
  GS-5 slice (or before).
- **ICAL-1 (Low-Med, GPT): shape deltas** — new export lacks `startDate/endDate` params; import
  result `imported/skipped` vs old `success/imported/skipped/total` (`api/ical.py:19-39` vs
  `OLD routes.ts:6243-6324`).
- **GS-1 depth confirmed (documented deferral):** new `/google/sync-settings` reads/writes ONLY
  the main token even though status/select accept `sharedCalendarId`
  (`api/integrations.py:58-112`, `services/google_integration.py:164-207`); old had per-calendar
  `/api/shared-calendars/:id/sync-settings` + the full advanced panel per filter calendar.

### Database (column-level; confidence High)

The 8 calendar-domain tables are **column-complete** (events+overrides incl. full recurrence set +
`other_participants` on master AND override `models/calendar.py:30,98`; shared_calendars incl.
`filter_type/filter_value/filter_rules` `shared_calendar.py:24` honored server-side; participants
6 roles + invite_code; bookings; google_tokens all ~25 settings incl. the TEXT-JSON `selected_*`
quirk kept 1:1; watches; meeting_requests; event_contacts; push_subscriptions). Intentional/ETL
deltas only: events drop legacy denormalized `project`/`product` text + `crm_interaction_id`
(`OLD schema.ts:293-330`) — mapping policy needed for text-only legacy rows; `recurrence="custom"`
→ `none` (settled); GPT flags some nullable→non-null tightening — verify against real legacy rows
during ETL rehearsal. No schema gap blocks any open frontend gap.

### Data observation (Opus, live)

**DATA-1: orphan badges diverge on the same account** — old prod «Задачи 1 / События 158» vs new
prod «Задачи 4 / События 1019». Both compute via `/api/stats/orphans` over the rest-of-range
window (`OLD AppSidebar.tsx:311-326`, NEW `AppSidebar.tsx:148-153`). Candidates: stale/rehearsal
data in new prod DB, counting-logic delta (new "avoids undercounting"), or viewing-context
difference. Must reconcile before cutover — exactly what the data-parity layer catches.

### Q4 — the assurance harness (both models converged; merged plan)

Layered; 1/2/7 exist, 3–6 are the build:
1. **Route gate (exists, CI)** — `check_parity.py` 193/193 incl. calendar routes.
2. **Behavior ledger (exists — refresh)** — `FRONTEND_PARITY.md` + this note's new rows
   (SHARE-4/5, MEET-1, ICAL-1, GS-6, DATA-1); one row per old behavior, file:line both sides,
   strike on close. The completeness backbone.
3. **Column gate (build)** — calendar-tables comparator: old `shared/schema.ts` snapshot vs
   SQLAlchemy metadata vs live DDL, with an allowlist for the intentional deltas. Also fix
   `tables.json` stale `model.status` (misled two audits).
4. **Dual-app behavioral tests (build)** — (GPT's strongest addition) seed identical fixtures,
   run the same API operations against old and new, compare normalized rows/responses for all
   calendar tables ("golden DB replay"); reuse the existing fake-Google/push test patterns
   (`server/tests/test_google_integration_db.py`, `test_push_db.py`) and Beat-registration
   assertions (`test_push_db.py:395-402`).
5. **E2E golden flows (build; repo standard Playwright, currently absent)** — ~12 flows on the
   local stack: click/drag create, move/resize, undo chain, recurring create + edit in all 3
   scopes + exception, task↔event convert, booking CRUD, share→join-by-code→viewer read-only,
   filtered calendar scoping, meeting accept → linked focal event, offline replay.
6. **Visual side-by-side (the user's screenshot instinct, made systematic)** — per-view checklist
   day/3-day/week/month/year × /calendars owner-vs-participant × ru/en × light/dark, old vs new
   **on identical seeded data** (prod-vs-prod today is NOT comparable — see DATA-1). Manual first;
   Playwright screenshot fixtures as the upgrade.
7. **Authz layer (exists)** — `test_calendar_scope_db.py` + route-partition guard.
8. **Data-parity at ETL** — per-table row counts + per-user checksums + the guardrails
   (custom→none, text-column mapping, nullability probe); then **re-run this explore gate once
   before DNS cutover** as the final sign-off.

## Divergence

- **MEET-2: RSVP ordering** — new commits the local response first and swallows a Google failure
  (`services/meeting_requests.py:95-120`, `google_meetings.py:23-60`); old required the Google
  patch to succeed before the DB update (`OLD googleCalendarMeetings.ts:67-127`).
  - Opus: new order is arguably better UX (local truth survives Google flaps) — keep, but log
    loudly + reconcile in the sync slice.
  - GPT: flags it as a possible parity break to decide explicitly.
  - **Decision needed:** bless the new ordering (+ add retry/reconcile in GS-5) or restore
    old strict ordering.

## Open

- **DATA-1 root cause** — is 1019-vs-158 data staleness or logic? To close: run the same
  `/api/stats/orphans` query against both DBs for one user, or diff orphan definitions.
- **GS-1 revisit** — per-shared-calendar sync panel stays deferred? The user is actively looking
  at the old panel in prod; if participants/owners need it at cutover, it graduates from
  "deferred" to a slice (backend pair exists in the allowlist).
- **GS-6 decision** — implement auto-sync interval for real in the GS-5 slice, or drop the
  control (old never executed it).
- ETL nullability probe (GPT) — verify tightened columns against real legacy rows at rehearsal.

## Next

Feeds three things: (1) the **GS-5 slice design** now must include MEET-1 linkage + the GS-6
decision + MEET-2 reconcile (`/gate-design focal-gsync-autopush`); (2) a **calendars-page slice**
for SHARE-4/5 (+2/3 leftovers) (`/gate-design focal-parity-calendars-page`); (3) the **assurance
build**: column gate + golden replay + Playwright flows + visual checklist
(`/gate-design focal-calendar-parity-harness`). Ledger housekeeping: add SHARE-4/5, MEET-1/2,
ICAL-1, GS-6, DATA-1 to `FRONTEND_PARITY.md`.

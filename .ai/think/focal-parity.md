# Problem

The new Focal client (`superapp/apps/focal/client`) must reach **100% user-facing functional
parity** with the proven production app `superapp/apps/old-focal/client`. The just-completed
re-skin epic (`focal-redesign-pages`) deliberately scoped itself to **presentation only —
"behavior / logic changes … out of scope … presentation parity only; data flow and functional
behavior preserved"** (see `.ai/think/focal-redesign-pages.md` "Out of scope"). So the pages now
*look* like old-focal but, per a full old-vs-new audit run this session, are **missing substantial
user-facing functionality**. The user has now set a new, broader contract: the new app must *do*
everything old-focal does.

This is therefore a **distinct epic from the re-skin**, not a continuation: the re-skin pivoted the
*visual* source of truth to old-focal; this epic pivots the *functional* source of truth to
old-focal and closes the behavior gap the re-skin explicitly left open. Three facts shape the work:

1. **The gap is real, large, and uneven.** The audit compared every left-nav area and graded each:
   **major** gaps in Calendar, Tasks, AI chat/assistant, and Google two-way-sync (plus Auth — see
   the scope note below); **partial** gaps in Shell/PWA/offline, the Events editor, the Goals graph,
   Habits, and Analytics; and **full parity** in Time Budgets, Dashboard, Heatmap, Help, Tags,
   Legal, and Meeting Requests. It is not a uniform "finish the port" — each area needs its own
   scoped slice.
2. **Four gaps are *systemic* — they recur across many pages from one missing foundation.** Fixing
   them once, centrally, is far cheaper and more consistent than patching each page:
   - **Shared-calendar read-only (`canEdit`).** old-focal gates every mutation on a calendar role
     via `CalendarFilterContext`; the new app has **no such context at all**, so Tasks, Events,
     Calendar, Time Budgets, Goals, Tags, and Analytics all silently lack the read-only/viewing
     behavior (and the "assistant mode" that scopes data to another owner).
   - **Display timezone.** old-focal ships a `TimezoneProvider` + selector + per-event timezone with
     DST-aware conversion; the new app has none — Calendar, Events, and AI-chat cards render raw
     wire times. (A `focal-timezone-port` task already exists in `.ai/tasks/`.)
   - **Global AI assistant + voice.** old-focal mounts a floating `AIAssistantWidget` on every page
     plus a voice clarification/TTS create flow and voice navigation; the new app only has a button
     that routes to the full `/aichat` page (`PageToolbar.tsx`).
   - **Offline / PWA.** old-focal has an IndexedDB read-cache (`OfflineSync`), a rich offline
     indicator, install/update prompts, pull-to-refresh, and `offlineAwareMutation` optimistic
     writes; the new app has only a minimal pending-mutation badge and plain mutations.
3. **Unlike the re-skin, this epic is *not* frontend-only.** A few parity items need a backend
   field that the new FastAPI schema dropped — confirmed: **task recurrence and multi-participant
   are absent from the new task schema** (`server/.../schemas/tasks.py`), and **event custom
   recurrence is absent** from `EventCreate`/`EventUpdate`. Those parity items require a SQLAlchemy
   model + Alembic migration (developer-owned, per repo rules), flagged inside their slice — never
   faked client-side. Most other gaps are pure UI (the new backend already models the fields, e.g.
   Habits' `note`/`category`/`description`/`project_id`).

The de-risking fact: old-focal is the exact, shippable functional spec for every area, and the new
app's APIs + typed `api/*` already exist — so most slices are "wire the missing UI to data that is
already there," not invention.

# Assumptions

- **[confirmed — user]** Target = **100% functional parity** with `apps/old-focal`; "all slices,
  all areas" (this session's scoping answers). The binding behavioral spec is old-focal.
- **[confirmed — `.ai/think/focal-redesign-pages.md`]** The re-skin epic was presentation-only and
  explicitly deferred behavior — so the missing functionality is *expected leftover scope*, not a
  regression introduced by the re-skin.
- **[confirmed — audit, this session]** The new app lacks `CalendarFilterContext`/`canEdit`
  entirely; `TasksPage.tsx`'s edit pencil is hardcoded `disabled` with no `TaskDialog`/
  `TaskInfoDialog`; the calendar `EventBlock` is "no drag/resize"; `GoogleSyncPanel.tsx` (~67 lines)
  replaces old-focal's `GoogleCalendarSyncAdvanced.tsx` (~1145 lines); no `AIAssistantWidget`/
  `VoiceControl`/`AIClarificationDialog` exist in the new client.
- **[confirmed — `superapp/CLAUDE.md` Hostnames/Auth]** Shared login/registration is moving to a
  shared `@allosta/auth` UI + `core.auth` verifier with cross-app SSO. → **Auth, password reset,
  and the marketing landing are assumed out of scope for the focal client** and are not parity
  slices here. (Surfaced as an open question, not silently dropped — the audit graded Auth "major,"
  so the user must confirm this exclusion.)
- **[confirmed — root `CLAUDE.md` / superapp `CLAUDE.md`]** Backend schema changes go
  models → autogenerated Alembic migration → PR, done by the developer / interactive Claude Code;
  unattended agents edit models only. → backend-touching parity items are developer-owned handoffs
  inside their slice.
- **[confirmed — audit]** Some new-app behaviors are **net-new vs old-focal** (e.g. `/spheres` and
  `/projects` CRUD pages, the Time-Budgets Reserve % row, the meeting "tentative" action, explicit
  error states). Parity = "do everything old-focal does"; these extras are **kept**, not stripped.
- **[unverified — settle at each slice's plan/design gate]** Exact slice boundaries and whether a
  large area (Calendar, the shared-calendar systemic slice) must itself split; the precise
  old→new component map per area; whether any old-focal behavior is intentionally obsolete under the
  superapp architecture (e.g. in-process schedulers → Celery already covered server-side). None of
  these block the framing.

# Options considered

The source-of-truth fork is settled (old-focal, functional). The real forks are **(1) sequencing**
— systemic foundations first vs page-by-page — and **(2) how to treat backend-touching items**.

| # | Option | What it is | Pros | Cons |
|---|--------|-----------|------|------|
| **A — Systemic foundations first, then per-area parity (chosen)** | Build the cross-cutting bases that per-area work depends on (shared-calendar `canEdit`, display timezone) first; then close each area's functional gap as its own slice, consuming the shared bases; group the independent systemic items (offline/PWA, AI widget) and a cleanup slice at the end. | The two foundation slices **cascade** (every later page inherits `canEdit` + timezone instead of re-adding them) → less rework, consistent behavior; per-area slices stay small and independently shippable; mirrors the proven re-skin epic shape. | Two foundation slices land before the most-visible per-area wins; the shared-calendar slice is itself large and may split. |
| **B — Page-by-page, full parity per page** | Take one area at a time (Tasks, then Events, …) and close *all* its gaps, systemic concerns included, inside that page. | Each slice ships a fully-complete page; easy to reason about one page. | Re-implements `canEdit`/timezone/offline **per page** → duplication, drift, guaranteed rework when the 4th page wants the same context; contradicts Simplicity/Surgical. **Rejected.** |
| **C — Strict severity order, ignore grouping** | Just do "most broken first" (Calendar → Tasks → AI → Google-sync → …) regardless of shared foundations. | Ships the worst gaps first. | Tangles systemic concerns into whichever page comes first; the same `canEdit`/timezone work gets done ad hoc mid-Calendar then redone for Tasks. **Rejected** in favor of A's foundation-first ordering. |

On fork (2): **backend-touching items stay developer-owned handoffs *inside* their owning slice**
(not a separate backend epic, not faked in the client) — so a slice that needs a field (task
recurrence) carries the model+migration as its first step and the UI as the rest. Alternative
(batch all backend gaps into one migration epic up front) was rejected: it front-loads schema risk
with no UI to exercise it and breaks the "one task = one slice = one PR" discipline.

# Recommendation

**Option A — systemic foundations first, then per-area parity slices, each a standalone 7-gate
feature tracing to this think doc.** Rationale: the audit's four systemic gaps are the high-leverage
root causes, and two of them (`canEdit`, timezone) are *consumed* by the per-area pages — building
them first means each per-area slice is a small, surgical "wire the missing UI" change against a
stable base, instead of every page re-inventing the same context (option B) or doing it ad hoc
(option C). It also keeps the proven epic rhythm: foundation slices that cascade, then independent
per-area slices.

**The four systemic gaps split by *dependency*, not priority** — reconciling with the kickoff's
"systemic foundations" contract. `canEdit`/shared-calendar and timezone are **consumed by** the
per-area pages, so they are true prerequisites and lead in Phase A. Offline/PWA and the AI-assistant
widget are cross-cutting but **nothing in the per-area parity depends on them**, so they are
sequenced last (Phase C) as *independent* work — late by dependency order, not deprioritised. All
four are still addressed **once**, centrally; "foundations-first" therefore means
*dependency-ordered*, not "every systemic concern before any page."

**Proposed slice order + dependencies** (slugs/boundaries settled per slice at its own gate 1/2):

*Phase A — systemic foundations (consumed by per-area work; do first):*

0. `focal-parity-shared-calendar` — introduce `CalendarFilterContext` + `canEdit`/role plumbing and
   apply read-only gating across Tasks, Events, Calendar, Time Budgets, Goals, Tags, Analytics;
   sidebar "limited menu" + viewing banner; assistant data-owner scoping. **Largest foundation —
   may split at its plan gate** (context+sidebar first, then per-page gating). *(base — Phase B depends on it.)*
1. `focal-parity-timezone` — `TimezoneProvider` + selector + per-event timezone + DST-aware
   conversion (Calendar, Events, AI-chat cards). *(reuses the existing `focal-timezone-port` task.)*

*Phase B — per-area functional parity (severity/visibility order; consume Phase A):*

2. `focal-parity-tasks` — `TaskDialog` (create/edit) + `TaskInfoDialog` + filter/search panel +
   schedule-to-calendar + tag manager + drag-drop. **Backend handoff:** task recurrence +
   `contactIds` fields (model + migration).
3. `focal-parity-events` — full event editor (description, location, tags, participant persistence,
   status, event timezone) on the Events page. **Backend handoff:** event `customRecurrence`.
4. `focal-parity-calendar` — year view, prime-time, drag-to-move + resize, all-day band, variable
   row heights + scroll-to-work, task panel + task↔event convert, undo stack, bookings/notes layer
   + filters, mini-month event dots, the read-only `EventInfoDialog` action set, recurrence-end UI.
   **Heaviest area — expected to split at its plan gate.**
5. `focal-parity-habits` — edit habit, per-day notes, recommended presets, category/description/
   project link, explicit Yes/No/Skip/Erase, delete confirm, drag reorder. *(frontend-only — the
   new backend already models every field.)*
6. `focal-parity-goals` — drag-to-reparent + move-preview/affected-counts, edge styling editor,
   budget/finance node fields, schedule-to-calendar from a node, full-description editor,
   multi-select/group-move, drag-to-create-child, full undo/redo coverage; **fix the regression:
   an activity cannot be added to a product-less project.**
7. `focal-parity-analytics` — PDF export, the 4 per-section insight blocks, Spheres summary cards +
   totals footer, per-metric help popovers, per-section collapse (+ Dashboard export
   localization/timeout/abort hardening).
8. `focal-parity-google-sync` — restore the advanced two-way Google-sync panel (direction, modes
   all/work/custom, custom filters, inbound/outbound request settings, notifications, auto-sync
   interval, "sync now", delete-imported) + the main-calendar Google section + the invite-code
   reveal/copy flow + OAuth success/error toast.

*Phase C — independent systemic + cleanup (do not block visible parity):*

9. `focal-parity-offline-pwa` — `OfflineSync` read-cache, rich offline indicator popover, PWA
   install + update prompts, pull-to-refresh, `offlineAwareMutation` optimistic writes + rollback,
   Google sync-status indicator in the sidebar.
10. `focal-parity-ai-assistant` — global floating `AIAssistantWidget` + per-page Sparkles entry +
    recommended-questions, the voice clarification/TTS create flow, continuous voice mode, and
    voice navigation.
11. `focal-parity-cleanup` — residual minors: invalidate calendar events after a meeting-request
    accept; theme/language toggles on the public Privacy/Terms pages; type-to-confirm on calendar
    delete; Tasks/Events orphan-count sidebar badges; any stragglers found during Phase A/B.

# Out of scope

- **Auth / registration / password-reset / marketing landing** — per `superapp/CLAUDE.md` these move
  to the shared `@allosta/auth`; not focal-client parity slices (see Open questions).
- **Visual / token redesign** — owned by `focal-redesign-pages`; this epic changes behavior, not look.
- **Net-new beyond old-focal** — no features old-focal lacks; the new app's existing extras are kept.
- **Server architecture changes already settled by the migration** (e.g. Celery Beat replacing
  in-process schedulers) — not re-litigated here; only *user-facing* behavior parity.
- **Faking backend-dependent UI** — a missing field is a flagged model+migration handoff, never a
  client-side stub.

# Open questions

- **Auth/landing exclusion** — confirm Auth, password reset, and the marketing landing are delivered
  by `@allosta/auth` and thus **not** in this epic. The audit graded Auth "major," so this is the
  one exclusion that needs an explicit user yes/no before Phase B planning. (If "in scope," it
  becomes its own epic, not a focal-client slice.)
- **Shared-calendar slice size** — does `focal-parity-shared-calendar` need to split into
  context+sidebar vs per-page gating? Settle at its plan gate.
- **Calendar slice size** — `focal-parity-calendar` is the heaviest; confirm its sub-slicing
  (grid interactions vs editor vs bookings) at its plan gate.
- **Backend-field ownership** — confirm the developer applies the task-recurrence and
  event-customRecurrence model+migration (agents edit models only) before the consuming UI lands.
- **Any intentionally-obsolete old-focal behavior** — flag per slice if an old behavior is
  superseded by the superapp architecture rather than a true gap.

# Success criteria

- [ ] This epic is framed as an ordered, dependency-aware set of independently-shippable parity
      slices, **systemic-first**, each a 7-gate feature tracing to this think doc and to a per-slice
      task seeded from the audit.
- [ ] Each slice at ship: `cd superapp/apps/focal/client && pnpm lint && pnpm typecheck &&
      pnpm test:run && pnpm build` green with its own tests; surgical diff; i18next ru + en; light +
      dark; the area's user-facing behavior matches `apps/old-focal`.
- [ ] The four systemic gaps are each addressed **once** (shared context/provider/widget), not
      re-implemented per page.
- [ ] Every backend-touching parity item ships as an explicit developer-owned model + Alembic
      migration handoff inside its slice — none faked client-side.
- [ ] At epic completion, the audit's gap inventory is closed: no area remains "major" or "partial"
      except behaviors explicitly confirmed out of scope (auth/landing) or intentionally obsolete.

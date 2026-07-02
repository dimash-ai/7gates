# Design summary

Slice 2 of the focal-parity epic — **shared-calendar read-only gating + assistant-mode data
scoping**. It splits into three independently-shippable parts; the decision that everything hinges
on is **the security model**: serving calendar-owner O's data to caller C is authorized **only** by
an app-layer RBAC check (RLS faithfully serves whatever owner id the app picks), so a single
**RBAC-gated `resolve_data_owner` dependency** is the load-bearing boundary.

- **2a — client read-only gating (no backend dep, ships first).** Each mutating page consumes
  `canEdit` from the slice-1 `CalendarFilterContext`: disable every create/edit/delete/toggle
  control when `!canEdit`, early-return mutation handlers with a visible read-only notice. Pages:
  Tasks, Events, Calendar, Time Budgets, Goals, Tags (Analytics has no mutations).
- **2b — backend assistant-mode owner scoping (security-critical).** A shared, RBAC-gated
  `resolve_data_owner` FastAPI dependency replaces `get_current_user_id` on domain read/write
  endpoints (behind an optional `calendarId` query param). **It also closes a live IDOR**: the
  existing `app/ai/chat_support.py:148` `resolve_data_owner` trusts any UUID with **no RBAC** —
  `/api/ai/chat` currently lets any authenticated caller read any user's data by passing their
  `userId`. This work makes that path RBAC-gated.
- **2c — client wiring.** Thread `currentCalendarId` into the typed `api/*` modules' query params +
  React Query keys so pages load/write the owner's data in assistant mode; shared-calendar event
  reads call `GET /api/shared-calendars/{id}/events` (server-side filter). `matchesFilter` stays a
  client-side UX narrowing for the user's **own** filter-calendars only — never the shared-calendar
  security boundary (which is enforced server-side).

Traces to: `.ai/think/focal-parity.md`, `.ai/plans/focal-parity-plan.md` (slice 2 "Shared calendar
data scope and read-only gates"), and `.ai/design/focal-parity-design.md` (which deferred scoping to
"where backend supports it" — it does not yet, so 2b designs that support).

# Architecture

```
Client (2a/2c)                         Backend (2b)
─────────────                          ───────────
useCalendarFilter() → canEdit          resolve_data_owner(calendarId?, caller, *, domain, action)
  → disable controls, guard handlers     ├─ no calendarId → caller.id  (own data, today's behavior)
  → read-only notice                     └─ calendarId → load SharedCalendar → owner = calendar.user_id
useCalendarFilter() → currentCalendarId       check caller's accepted role vs the (domain, action) gate:
  → api/*.ts pass calendarId on              calendar    READ viewer+            WRITE {owner,full_access,editor}
    read query + write body                  other-pages READ {owner,FA,developer} WRITE {owner,full_access}
  → query keys include calendarId            else → PermissionDeniedError (403)
  → matchesFilter() on event lists           return owner id  → service(owner_id, …) unchanged
```

- **Backend injection point:** the first arg to every service method (already a plain `user_id`
  param). For **other-pages** domains, swapping `get_current_user_id` → `resolve_data_owner` is a
  **zero service-layer change** (services take `user_id` as a parameter, and the whole owner dataset
  is what a `canViewOtherPages` role may see). The **calendar** domain is NOT a bare swap: a
  shared-calendar event read must apply the calendar's saved **filter server-side**, so it routes
  through the existing `SharedCalendarsService.list_events` (`shared_calendars.py:204` — RBAC-checks
  viewer+, fetches the owner's events, **applies the calendar filter**) rather than raw
  `CalendarService.list_events(owner)` which returns ALL owner events. **All** calendar event writes —
  create (`POST /api/events`, `calendar.py:32`) **and** by-id (`PATCH`/`DELETE /api/events/{id}`,
  `calendar.py:55`) — must verify the event matches the selected calendar's filtered scope + the
  caller's calendar write role, not merely match owner id (else an editor could create/move owner
  events outside the shared calendar's filter).
- **Reuse, don't reinvent:** build `resolve_data_owner` from existing blocks —
  `SharedCalendarsService._resolve_access` (`shared_calendars.py:220`, owner lookup + accepted-role
  fetch + rank gate for writes), `rbac.get_resource_role` (`rbac.py:27`), the `can_view_other_pages`
  set (`shared_calendars.py:201`) for the read gate, and `PermissionDeniedError` (`errors.py:40`).
- **One dependency, applied uniformly:** ~all `app/api/*` routers share the
  `get_current_user_id → user_id → WHERE user_id ==` shape, so the dependency retrofits them
  endpoint-by-endpoint without per-domain bespoke logic.
- **Client (2a) is page-local:** each page imports `useCalendarFilter`, gates its own controls; no
  cross-page coupling. (2c adds `calendarId` to the `api/*` modules the pages already call.)

# Data model

| entity | change | notes |
|--------|--------|-------|
| (none — no schema change) | — | Owner-only domain tables stay owner-keyed. **The cross-tenant boundary is the app-layer filter, not RLS:** the domain-router service sessions run under the owner DB role and **bypass RLS** (the `app.user_id` GUC is pinned only on the auth heal-session, never on the domain service sessions — `db.py:81`, `auth.py:111`). Assistant mode therefore changes the effective `user_id` passed into the service (the `WHERE user_id == owner` filter), chosen by `resolve_data_owner`. **No schema change, no migration.** |
| optional RLS hardening (deferred) | additive `sharing_select` policies on domain tables via `SECURITY DEFINER` participation helpers, mirroring the calendar tables | defense-in-depth only; the app-RBAC gate is sufficient and is the load-bearing boundary. A separate hand-written migration if ever wanted. **Out of scope for 2b.** |

# Interfaces & contracts

**Backend — `resolve_data_owner` (new shared dependency, `app/deps.py` or `app/auth.py`):**
- `resolve_data_owner(calendar_id, caller, session, *, domain, action) -> owner_id`. Returns `caller`
  when `calendar_id` is None (own data, backward-compatible). Else resolves the calendar
  (`owner = calendar.user_id`) and checks the caller's **accepted** participant role against the gate
  for `(domain, action)`. **The gates are NOT uniform — they split by domain**, tracking slice-1's two
  permission dimensions (`canEdit` = event editing; `canViewOtherPages` = access to non-calendar pages):

  | domain | READ roles | WRITE roles |
  |---|---|---|
  | **calendar** (events, calendar_init, bookings, meeting_requests) | any accepted participant (viewer+) — the shared calendar's purpose; matches the existing `list_events` `_resolve_access(.., "viewer")` | `{owner, full_access, editor}` (= `canEdit`) |
  | **other-pages** (tasks, projects, activities, activity_instances, mindmap/goals, spheres, time_budgets, tags, habits, habit_entries, stats, analytics) | `{owner, full_access, developer}` (= `canViewOtherPages`) | `{owner, full_access}` (= `canViewOtherPages` ∩ write) |

  Raises `PermissionDeniedError` (403) when the role isn't in the gate. **Crux — the write gate is NOT
  uniform:** an `editor` (`canEdit=true`, `canViewOtherPages=false`) may write the owner's calendar
  events but is **denied** reads AND writes on the owner's non-calendar data (it cannot even view those
  pages); a `developer` reads non-calendar data but **never writes** it. Checks are **set-membership,
  not rank** (`developer`/`viewer`/`requester` share rank 10 yet differ across these sets).
- **AI-chat fix (read/write split — the AI route does BOTH):** `/api/ai/chat` resolves the data-owner
  scope once (`ai_chat.py:204`) and then dispatches **both** read intents (query/analytics) **and**
  write intents — the create/update/delete entity handlers write owner-scoped rows
  (`app/ai/entity_handlers.py` create paths ~997/1320/1415). So one gate is not enough: apply the
  **other-pages read gate** (`owner/full_access/developer` — the AI surfaces the owner's
  tasks/goals/activities) to authorize the owner-scoped read, and before any create/update/delete
  entity handler mutates owner data apply the **write gate of that entity's domain** (calendar event
  → `{owner, full_access, editor}`; non-calendar entity like task/goal → `{owner, full_access}`) — a
  `developer` (read-only) is **forbidden to write** (403), and an `editor` is denied **non-calendar**
  entity writes (it cannot view those pages). Replace the UUID-only
  `app/ai/chat_support.py:resolve_data_owner` (the IDOR) with the read-gated resolver, and add the
  write-gate check at the create-intent dispatch in `ai_chat.py` before owner-scoped mutation.

**Per-endpoint contract:** read endpoints gain an optional `calendarId` query param + their **domain's
read gate**; write endpoints accept `calendarId` (query or body) + their **domain's write gate**.
Absent `calendarId` → unchanged own-data behavior (backward compatible).

**Scoped endpoints — a closed partition by domain (so no route leaks AND the right gate applies):**
A route is *scoped* iff it reads/writes per-user domain data via `Depends(get_current_user_id)`.
Slice 2b converts **every** such route to `resolve_data_owner` with its **domain's** gate (the table
above): the read gate on every `GET`, the write gate on every mutation (`POST`/`PATCH`/`PUT`/`DELETE`,
incl. the non-CRUD `POST /api/activity-instances/sync` and `POST /api/mindmap-nodes/batch`, and the
full `time_budgets.py` write surface). Every `get_current_user_id`-injecting router is classified into
**exactly one** of three buckets:
- **calendar-domain** (read = viewer+, write = `canEdit`) — `calendar` (events), `bookings`,
  `meeting_requests`. **Scope invariant — covers EVERY route (list / by-id / aggregate / create /
  write), no per-path exceptions:** in shared mode every calendar-domain **READ** returns only
  objects within the selected calendar's **filtered scope** — list reads route through the filtered
  shared path (`GET /api/shared-calendars/{id}/events`), and a **by-id** read of an object outside
  the filter → **404** (not visible in this calendar), never raw `CalendarService.get_event(owner,
  id)` (`calendar.py:139`); every calendar-domain **WRITE** — create (`POST /api/events`), by-id
  (`PATCH`/`DELETE /api/events/{id}`), bookings, and accept-request — validates the object is within
  the filtered scope + the caller's calendar write role, else **403**. So neither a viewer (by-id
  read) nor an editor (create/move) can reach owner objects outside the shared calendar's filter.
- **mixed aggregate** — `calendar_init`: returns events/bookings (**calendar** gate, filtered) **and**
  tasks/projects (**other-pages** gate). In shared mode each payload part is gated by its own domain;
  the tasks/projects keys are returned as **empty arrays** (the response schema requires the keys —
  they are not omitted) unless the caller satisfies the other-pages read gate (`canViewOtherPages`),
  so an editor/viewer/requester never receives non-calendar data through it.
- **other-pages-domain** (read = `canViewOtherPages`, write = `{owner, full_access}`): `tasks`,
  `projects`, `activities`, `activity_instances`, `mindmap` (collection + standalone nodes/edges),
  `goals`, `spheres`, `time_budgets`, `tags`, `habits`, `habit_entries`, `stats`, `analytics`. (No
  `/api/products` route — products are modeled on `projects`/`activities`.)
- **ai-domain** — `ai`, `ai_chat`: per-intent — owner-scoped reads via the **other-pages** read gate
  (the AI surfaces the owner's tasks/goals/activities); entity writes via **that entity's domain**
  write gate (calendar event → calendar write; task/goal → other-pages write). The route threads the
  selected `calendarId` into the entity context so **event-backed** intents honor the calendar filter
  server-side: event reads use the filtered shared-calendar path (not raw
  `CalendarService.list_events` at `entity_handlers.py:411`), and event writes validate against the
  calendar's filtered scope. A **mixed** AI answer that combines events + tasks includes the owner's
  tasks **only if** the caller satisfies the other-pages read gate (`canViewOtherPages`) — a
  viewer/editor gets the filtered events but **not** the owner's tasks. This bucket replaces the
  UUID-only `resolve_data_owner` (the IDOR fix). Classified explicitly so the guard passes.

  > **Slice-2 scope refinement (2026-06-26):** only the **IDOR fix** ships in slice 2 — the AI's
  > `resolve_data_owner` is replaced by the RBAC-gated `resolve_ai_data_owner` + the create-intent
  > write gate, closing the live cross-user hole. The remaining AI shared-calendar **assistant mode**
  > — deriving the data owner from the selected `calendarId`, the event-vs-other-pages **domain-split
  > gating** (filtered events for a viewer, owner tasks only for `canViewOtherPages`), filtered AI
  > event reads, and `calendarId`-scoped AI event **create** — is **deferred to slice 12 (AI
  > assistant + voice)**, where the AI surface is built out in full. It requires splitting the AI's
  > single data-owner into per-domain owners (events vs other-pages) through the entity context, a
  > redesign that belongs with that slice rather than the data-scope foundations here. Slice 2 leaves
  > the AI strictly own-data (plus the IDOR gate); it does **not** thread `calendarId` into the chat
  > path, so there is no partially-wired assistant surface to mis-scope.
- **self-only** (stays on `get_current_user_id`, never owner-scoped): `me`, `settings`,
  `integrations`, `push`, `agent_tokens`, `user_account`, `backup`, `dashboard`, `ical` (the caller's
  own account/admin/export surfaces) and `shared_calendars` (already RBAC-gated).

**Completeness is a closed-partition build check:** grep `Depends(get_current_user_id)` across
`app/api/`, then assert (a) every calendar/other-pages route routes through `resolve_data_owner` with
the **correct domain gate**, (b) self-only routes intentionally remain, and **(c) every matched route
is classified into one bucket** — an **unclassified** `get_current_user_id` route fails the build,
forcing a deliberate calendar/other-pages/self-only decision for any route added later. A scoped
route still on `get_current_user_id`, on the wrong domain gate, or unclassified, is a build-blocking
leak.

**Client — `api/*.ts`:** read functions accept an optional `calendarId` appended as a query param; mutation functions pass it where the endpoint supports it; React Query keys include `calendarId` so a calendar switch refetches. Pages read `currentCalendarId` from `useCalendarFilter`.

# Flow (happy + unhappy paths)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| happy — own data | no `calendarId` | `resolve_data_owner` | caller's id → unchanged behavior |
| happy — assistant read | full_access/developer views owner's calendar | `resolve_data_owner` read gate | returns owner id → service serves owner's rows |
| happy — assistant write | owner/full_access/editor | write gate | owner id → write applies as owner |
| read-only control | `!canEdit` (viewer/developer/requester) | page (2a) | control disabled + read-only notice; handler early-returns |
| unauthorized scope | caller has no / insufficient role on `calendarId` | `resolve_data_owner` | `PermissionDeniedError` → 403 |
| IDOR attempt | caller passes a victim `userId`/`calendarId` they don't participate in | RBAC gate | 403 (was: silently served — the bug being fixed) |
| missing calendar | bad `calendarId` | `_resolve_access` | 404 |
| stale/revoked role | role removed after selection | RBAC gate (per request) | next request 403; client fails closed (slice 1) |

# Alternatives rejected

- **Per-endpoint ad-hoc owner checks** — duplicates the RBAC across ~15 endpoints, drift-prone and
  a security risk. Rejected for one shared dependency.
- **RLS-enforced cross-domain sharing policies now** (additive `sharing_select` on every domain
  table) — real defense-in-depth, but adds a hand-written migration per table and isn't required
  for correctness (the app-RBAC gate is the boundary). Deferred, not in 2b.
- **Trust a client-supplied owner/userId (the current AI-chat behavior)** — that *is* the IDOR.
  Rejected; replaced by the RBAC gate.
- **Faking `calendarId`/owner params client-side without backend support** — explicitly forbidden by
  the epic (no faked params). 2b adds the real backend support first.

# Test strategy

- **Backend authz (the load-bearing tests), split by domain:**
  - *other-pages* (tasks/goals/time-budgets/tags/…): READ by owner/full_access/developer → 200; READ
    **denied (403)** for editor/viewer/requester/non-participant; WRITE by owner/full_access → 200;
    WRITE **denied** for developer/editor/viewer/requester — incl. the non-CRUD sync/batch routes and
    the full Time Budgets write surface.
  - *calendar* (events/bookings/meeting_requests): READ by **any accepted participant (viewer+)** →
    200 and returns **only objects matching the calendar's filter**; a **by-id** read of an object
    outside the filter → **404**; denied for non-participant. WRITE — event **create AND** by-id
    edit/delete (and accept-request) — by owner/full_access/editor → 200 **only when the object
    matches the calendar's filtered scope**; a create/move/edit that would fall outside the filter →
    403; all writes **denied** for developer/viewer/requester.
  - *calendar_init mixed aggregate*: a viewer/editor (no `canViewOtherPages`) gets filtered events but
    **empty** `tasks`/`projects` arrays; a full_access/developer gets the owner's tasks/projects too.
  - *AI event intents*: an owner-scoped AI event read returns only filter-matching events (uses the
    filtered shared path, not raw `list_events`); an AI event write outside the filter → 403.
  - no `calendarId` → own data unchanged (backward compat).
  - **IDOR regression:** a non-participant passing a victim's `userId`/`calendarId` to `/api/ai/chat`
    and to scoped domain endpoints gets 403; an `editor` writing a **non-calendar** entity via
    `/api/ai/chat` is denied; a `developer` writing anything via `/api/ai/chat` is denied.
  - **closed-partition guard:** a test asserts every `Depends(get_current_user_id)` route in `app/api/`
    is classified (calendar / other-pages / self-only) — no route left unclassified.
  - Real-DB transaction-rollback fixtures (per repo test rules).
- **Client 2a:** per-page — a `!canEdit` render disables every mutating control and the handler does
  not call its API (mirrors slice-1's read-only gate tests).
- **Client 2c:** the api modules append `calendarId`; query keys include it; `matchesFilter` narrows
  the Calendar/Events list to the selected calendar.
- **Verified:** `cd apps/focal/server && make verify && uv run alembic check` (no migration, so
  `alembic check` stays clean) + `cd apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.

# Security & release notes

- **The RBAC gate is the entire cross-user boundary.** The domain service sessions **bypass RLS**
  (the GUC is never pinned on them), so the app-layer `WHERE user_id == effective_owner` filter is
  the only tenant boundary — and `resolve_data_owner` chooses `effective_owner`. So the resolver
  must be correct: **accepted** participation only, the right role **sets** (set-membership, **not**
  rank — `developer` vs `viewer` share rank 10), and distinct read vs write thresholds (a
  `developer` reads but must not write). Every scoped endpoint (incl. aggregate routes like
  `/api/calendar/init`, `/api/stats/*`, `/api/analytics/*`) MUST route through it; a missed endpoint
  is a leak. (RLS stays a dormant backstop on these sessions; activating it on owner data is the
  deferred defense-in-depth hardening above, not required for correctness.)
- **Two gate domains close the `editor` over-grant.** `editor` has `canEdit` but **not**
  `canViewOtherPages`, so it is permitted only on the **calendar** write gate (event edits) and is
  **denied** the owner's non-calendar data entirely (no read, no write); `developer` gets non-calendar
  **reads** but no writes; `viewer`/`requester` keep read access to the shared calendar's events (the
  existing viewer+ path) and nothing else. A single uniform write gate would have let an `editor`
  mutate the owner's hidden tasks/goals/time-budgets — the domain split prevents that.
- **Fixes a live IDOR** (`app/ai/chat_support.py:148` + `ai_chat.py`/`ai.py`): currently any
  authenticated user can read another user's activities/events via `/api/ai/chat` by supplying their
  UUID. 2b closes it. This is the highest-priority item and could be hotfixed ahead of the rest.
- **Backward compatible / no migration:** absent `calendarId`, every endpoint behaves exactly as
  today; rollback = revert the code (no schema state to undo). Backend model edits are limited to
  api/deps/auth + service call-sites; **no SQLAlchemy model or Alembic change** — so this stays
  inside interactive-Claude-Code's lane (not an unattended-agent migration).
- **Developer-owned review:** 2b changes the auth/RBAC surface; it ships with the authz tests above
  and a security pass before merge.

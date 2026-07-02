# Handoff — focal migration current state

**Repo:** `superapp` · **App:** `apps/focal` · **Branch:** `feature/focal-migration` @ `64af0b4` ·
**Tests:** 905 passing (`make verify`) · **Migration head:** `d8b68f67f1d5` · **Routers wired:** 18

## Since the last handoff (Jun 7) — data-migration modeling

The branch advanced `13f6712` → `713f246` (data-migration modeling; webhook **slice 3b** later
landed on top at `64af0b4` — see Phase 8); the **migration head is now `d8b68f67f1d5`** (`acb242a1f541`
+4 migrations, single linear chain). Only **two** commits touch `apps/focal/` in this window:
`2ffc81a` (disable the asyncpg statement cache for the Supavisor transaction pooler, `app/db.py`, via
PR #5) and `713f246` **"model the remaining keeper tables for the data migration"** — 8 models + 4
migrations, **no routers, no endpoints** (`make verify` still 886 tests / 18 routers, API surface
byte-identical). The bulk of repo activity this window was the sibling **PRIMA** app, not focal.

**Keeper tables ported (DB only — "table + ETL fidelity; the feature is a later phase"):**
`activity_instances`, `google_tokens`, `google_calendar_watches`, `push_subscriptions`, `contacts`,
`interactions`, `event_contacts`, `user_activity_logs`. These give the §6 ETL its load targets; **no
ETL scripts exist yet** — only the frozen `docs/contract-freeze` mapping (39 tables / 536 cols).

**CRM is not a reversal of "CRM → PRIMA":** under the still-open `crm-boundary` ADR, CRM *routes*
relocate to PRIMA while CRM *tables* (`contacts`/`interactions`/`meeting_requests`) stay focal-local
for legacy-data parity/ETL. The table stays; the boundary owner is undecided.

**Flags:** (1) `713f246` shipped **outside the per-slice Gate pipeline** — no `.ai/tasks|plans|reviews`
artifacts, so there is no Codex ≥9.0 paper trail for the 8 tables. (2) `_tables_mapping.py` still marks
those tables `status='pending'` (now stale; `check_tables.sh` reconciliation would flag them). (3)
`meeting_requests` is named a keeper table but was **not** modeled in `713f246` (only
`contacts`/`interactions`/`event_contacts`) — still pending.

## Where we are — Phase 4 backend done; data-migration modeling current

- **Phase 0 (foundation/auth)** ✅ · **Phase 1 (MindMap core)** ✅ · **Phase 2 (Calendar)** ✅ (events,
  recurrence, init, bookings, shared calendars, timezone).
- **Phase 3 (Google)** ▶ — meeting-requests **read surface** done (`0b9e99a`); OAuth / two-way sync /
  watch / the 5 RSVP actions + ingestion are **credential-blocked**. (Jun 7: `google_tokens` +
  `google_calendar_watches` tables/models ported in `713f246` — DB only, no OAuth/sync/watch code.)
- **Phase 4 (habits / time-budgets / analytics / dashboard)** ▶ **current**:
  - ✅ Habits — lifecycle (`d98ba2f`) + entries/streaks/stats (`a46f1d0`).
  - ✅ Time-budgets — settings + `GET /{year}` aggregate (`f9456b4`, merge `40812e3`) + category /
    subcategory / item CRUD (`39460fd`, merge `536f812`).
  - ✅ **analytics** — life-sphere plan-vs-fact (`85a88a6`, merge `12cc941`). The "heatmap" is an
    AI/client analysis concept (no REST endpoint), so it is not a backend slice.
  - ⬜ **dashboard** — product analytics; **blocked**: needs the `dashboard_cohort_retention`
    materialized-view + its refresh scheduler (a hand-written-migration + Celery-Beat handoff). (Jun 7:
    `user_activity_logs` table/model ported in `713f246` — the per-request audit feed for the MV; the MV
    + refresh scheduler themselves remain a later phase.)
  - ⇒ **Phase 4 backend is effectively complete** — only the MV-blocked dashboard remains.
- **Phase 8 (`foc_` agent API + MCP)** ▶ — ✅ **slice 1: token lifecycle** (`b42a23f`, merge `c67df8e`):
  `ai_agent_tokens` model + migration `3574970012f6`, pure token domain (`foc_`+64hex, sha256 hash-only),
  JWT-scoped CRUD under `/api/ai-agent/tokens` (create/list/rotate/rename/scopes/delete), per-user cap
  of 20, expiry ≤2yr, `IntegrityError`→409 on the unique race. ✅ **slice B1: `focal-agent-events`**
  (`277c767`, merge `638c5e9`) — the X-Focal-Token auth dep + `require_scope` + the `{ok,data,meta}`
  envelope via `AgentApiError` (its own handler, resolved ahead of `app_error_handler` by MRO) + `GET
  /api/ai-agent/v1/events/today` & `/events` (raw `CalendarEvent` projection, manual tz/date/range
  validation, best-effort `last_used_at` touch, single shared per-request session). Rate-limiting +
  `ai_agent_logs` + the `X-OpenClaw-Token` alias stay deferred. ✅ **slice B2: `focal-agent-tasks`**
  (`74e65e5`, merge `1a74dda`) — `GET /v1/tasks` (status/due/tz filtered) + `PATCH
  /v1/tasks/{id}/complete` (idempotent atomic flip, completion webhook deferred). ✅ **slice B3:
  `focal-agent-goals-budgets`** (`360bb02`, merge `29a777c`) — `GET /v1/goals` + `GET /v1/time-budgets`
  (active projects). **⇒ the agent `/v1` DATA surface is complete** (events, tasks, goals, budgets). ⬜
  ✅ **`focal-agent-logs`** (`64682d1`, merge `71e474b`) — `ai_agent_logs` table (migration
  `acb242a1f541`) + `log_agent_event` (structlog + best-effort durable row, never raises) wired into the
  auth/scope deps for `ACCESS`/`AUTH_FAILED`/`SCOPE_DENIED`; a conftest autouse fixture points
  agent-logging at a NullPool sessionmaker (loop-safe). ✅ **`focal-agent-token-logs`** (`ff225b1`, merge
  `a9837f1`) — control-plane events `TOKEN_CREATED`/`ROTATED`/`REVOKED`/`AGENT_RENAMED` emitted at the
  token router (success-only). **⇒ the `logAgentEvent` port is complete** (data + control plane). ⬜
  ✅ **`focal-agent-rate-limit`** (`a32e0c5`, merge `3bbc7d3`) — per-token **60/min** in-process
  fixed-window limiter (`app/rate_limit.py`) wired into `get_agent_principal` (after resolve+expiry,
  before the `last_used_at` touch) → 429 + the `RATE_LIMITED` event; the **distributed Redis backend is
  Gate-1-ratified DEFERRED** (pre-prod single-process; `check_rate_limit()` encapsulates the backend). ⬜
  ✅ **`focal-ical-serializer`** (`04c051e`, merge `9c8d870`) — the pure RFC 5545 serializer
  (`app/domain/icalendar.py`: `generate_ical_file(events)` + `IcalEvent`; injectable UTC `DTSTAMP`,
  wall-clock `DTSTART`, all-day heuristic, char-based 75/74 folding, backslash-first escaping; 20 unit
  tests). Ships unused — the feed consumes it next. ✅ **`focal-agent-ical-alias`** (slice 2a, `076dd39`, merge
  `9038a3c`) — `POST`/`DELETE /tokens/{name}/ical-token` (issue/revoke a 64-hex feed alias, sha256 in
  `ical_token_hash`, returned once; `ICAL_TOKEN_CREATED`/`REVOKED` audit). ✅ **`focal-agent-ical-feed`**
  (slice 2b, `308a44b`, merge `1b0aaf2`) — `GET /v1/calendar.ics?ical_token=` (sha256-vs-`ical_token_hash`
  auth, **plain-text 401** / `text/calendar` via a bare `Response` — the one agent endpoint NOT using the
  `{ok}` envelope; best-effort `last_used_at` touch with fields captured before the rollback-capable
  touch; `ACCESS`/`AUTH_FAILED` audit; `CalendarEvent` −30d/+60d UTC → `IcalEvent` → `generate_ical_file`).
  **⇒ the iCal feature is complete** (serializer + alias + feed). **webhooks** ◐ in progress: ✅ **`focal-webhook-ssrf`** (slice 1/3,
  `00d37eb`, merge `fd29493`) — the pure SSRF validator `app/domain/webhook.py:validate_webhook_url`
  (HTTPS-only; rejects internal hostnames + private/reserved IP literals; closed **5** probed bypasses —
  non-canonical IPv4 via `inet_aton`, trailing-dot, IDNA Unicode-dots/fullwidth/%2e via NFKC, `%00`
  crash+truncation, literal tab/CR/LF strip; 53 tests). ✅ **slice 2/3: webhook-URL CRUD**
  (`accff2b`, merge `ccc4e50`) — `PUT`/`DELETE /tokens/{name}/webhook`: `_require` 404 → `.strip()` →
  empty-guard 422 → `validate_webhook_url` 422 → same-URL **zero-mutation no-op** (no secret rotation,
  no audit — protects the agent's stored `X-Focal-Signature` key) → else rotate `webhook_url` + a new
  **recoverable** `whs_<48hex>` `webhook_secret` (returned once, never on a read) + `fail_count=0`;
  DELETE nulls all three; `WEBHOOK_UPDATED` audit success-and-change-only. **Slice 3 (delivery) =
  Celery — user chose to wire it properly** (the monorepo's FIRST Celery surface), split into 3a + 3b:
  ✅ **slice 3a: `focal-webhook-delivery-foundation`** (`3b26c18`, merge `13f6712`) — the Celery
  scaffold (`app/celery_app.py`: `Celery("focal", broker=redis_url)` + a module-level `CELERY_CONFIG`
  applied via `conf.update` — json-only, UTC, `task_ignore_result`, **no** result backend, **no**
  autodiscover, **no** env-gated eager; a `focal.ping` task; `app/celery_signals.py`: correlation_id
  via `before_task_publish`/`task_prerun`/`task_postrun`) + the **pure, ORM-free delivery domain**
  extending `app/domain/webhook.py` (`build_webhook_payload`, one canonical `serialize_payload` for
  sign+wire, `sign_payload` HMAC-SHA256, `build_webhook_headers`, `resolve_and_check_host` → the
  connect-time DNS-rebinding SSRF re-check returning `(ip,hostname)`, scan-all/any-blocked-or-
  unverifiable rejects via the reused `_is_blocked_ip`, `_RESOLVE_ERRORS=(OSError,UnicodeError)`;
  `decide_delivery_outcome`/`DeliveryAction` with 3xx-as-transient + transient-never-mutates-fail_count).
  Dep `celery[redis]` (5.6.3; redis pinned 6.4.0) + a `celery.*`/`kombu.*` mypy override; eager-in-tests
  via an autouse conftest fixture; prod-safety asserted on the shipped `CELERY_CONFIG`. Ships
  consumer-less (slice-1 style). ✅ **slice 3b: `focal-webhook-delivery-task`** (`5c9a4e0`, merge
  `64af0b4`; Codex build-gate **9.1 APPROVED**, [reviews/](../reviews/focal-webhook-delivery-task/)) —
  the async delivery task in `app/tasks/webhook.py`: a fresh-OS-thread `asyncio.run` dispatch
  (eager-safe), a dedicated **NullPool** `_task_sessionmaker` (loop-safe per worker invocation),
  `httpx.AsyncClient` POSTing `content=serialize_payload(...)` bytes — never `json=`; a **pre-connect
  `resolve_and_check_host` SSRF gate** (reject-if-blocked, then connect **by hostname** with
  `follow_redirects=False` — the IP-pinned custom transport stays deferred, named-TOCTOU residual
  accepted); the retry/backoff loop over `decide_delivery_outcome`; the action→DB map (2xx reset / 4xx
  atomic `webhook_fail_count` increment-or-disable / transient retry-then-give-up with **no**
  `fail_count` mutation); best-effort audit. Import-driven registration via `app/tasks/__init__.py` +
  `autodiscover_tasks`; the `notifyAgent` fan-out; the single first-flip `task.completed` trigger
  (`complete_task` → `(exists, newly_completed)`, `data={"id": task_id}` per legacy `ai-agent.ts:859`,
  contextvars-scoped enqueue); the `WEBHOOK_DELIVERED`/`FAILED`/`DISABLED` log levels. 19 new DB tests;
  `make verify` 905 passing. **⇒ the webhook feature (SSRF + URL CRUD + delivery) is complete.**
  `sanitize_task_for_webhook` + the `task.created`/`updated`/`deleted` + `calendar_event.*` triggers
  belong to the **regular `routes.ts` CRUD** surfaces (a later cut), NOT this agent-API path.
  Deploy-time deferred: the Railway Celery worker service + Flower + Beat. Deferred prod-readiness: the
  **Redis rate-limit backend** (+ feed rate-limiting). One open Codex *Should-Consider*: the contextvars
  test pins `_preserve_contextvars()` directly rather than via a route/eager-path assertion.
- **Phases 5–7** ⬜ — push (VAPID), cutover/ETL (prod+Railway-PG), AI chat (OpenAI+Qdrant). Mostly
  credential-blocked; the agent-API *structure* (the scoped data endpoints) is buildable. (Jun 7:
  `push_subscriptions` + CRM `contacts`/`interactions`/`event_contacts` tables/models ported in
  `713f246` for ETL fidelity — the features themselves are still not started. ETL execution is gated on
  open ADRs **D1** (identity continuity) and **crm-boundary**; no ETL scripts exist yet.)

## Decisions locked

- **CRM → PRIMA** (legacy step 7 dropped; focal keeps only opaque `contactId`/`crmInteractionId`
  refs). **Meeting-requests → Phase 3** (Google-coupled).
- **Tenant hardening convention:** every private-resource get/update/delete is JWT-`sub`-scoped and
  404s cross-tenant (the legacy often returned any-row-by-id or 403); creates validate owned parent
  links (→ 404). Pydantic validation → 422 (not the legacy 400). Status: create 201 / update 200 /
  delete + bulk-action 204.
- **Per-slice git flow:** `feat/focal-<slice>` → push → `git merge --no-ff` into
  `feature/focal-migration` → push → delete branch (remote + local). GitHub **PR objects are
  unavailable** from this environment (`gh` + API both 404 the repo; only `git push` works), so it's a
  git-only `--no-ff` merge. Commit contribution-boxes light up retroactively when
  `feature/focal-migration` merges to the default branch; author email `d.dzhunusov@allosta.com`.

## Process (every slice)

`.ai/tasks/<slice>.md` → Gate 1, `.ai/plans/<slice>-plan.md` → Gate 2, implement → Gate 3 (code),
Gate 4 (tests), Gate 5 (final), each re-run until Codex ≥ **9.0 APPROVED** (`.ai/reviews/<slice>/`),
then the branch flow above. **No AI attribution; commit = one sentence; no spec/phase/slice IDs in
code comments or test names** (the recurring Gate-5 catch — keep docstrings clean). Codex runs from the
repo root; `make verify` + `alembic` from `apps/focal/server/`. The pipeline creates/reviews the
Alembic migration in-slice (deviation from the repo's "developer autogenerates after merge" rule).

# Goal

Port the agent **access audit log** (Phase 8 hardening): the `ai_agent_logs` table + a `log_agent_event`
helper, wired into the X-Focal-Token auth/scope path so every agent access is recorded — `ACCESS` (a
successful scoped call), `AUTH_FAILED` (missing/invalid/expired token), `SCOPE_DENIED` (missing scope).
Builds on the shipped agent-auth foundation. Legacy: `agentLogging.ts`, `schema.ts:1692` (ai_agent_logs).

# Scope

- **`app/models/agent_log.py`** — `AiAgentLog` (`ai_agent_logs`), extends `Base` (only `created_at`, **no**
  `updated_at`): String uuid PK; `created_at` (tz-aware, default `utcnow`, **indexed**); `event_type`
  (String(50), **indexed**); `level` (String(10) — `info`/`warn`/`error`); `user_id` (String, nullable,
  **indexed** — the token owner); `agent_name` (String(100), nullable, **indexed**); `endpoint`
  (String(255), nullable — `"GET /v1/events"`); `status` (Integer, nullable — 401/403); `details`
  (JSONB, nullable — the variable per-event context: denial reason, required/granted scope); `type`
  (SmallInt default 1, product-analytics parity). Register in `app/models/__init__.py`; migration
  in-slice. Four indexes: `created_at`, `event_type`, `user_id`, `agent_name`.
- **`app/agent_logging.py`** — `AGENT_EVENT_LEVELS` (this slice: `ACCESS=info`, `AUTH_FAILED=warn`,
  `SCOPE_DENIED=warn`); `async def log_agent_event(event_type, *, user_id=None, agent_name=None,
  endpoint=None, status=None, details=None) -> None`:
  1. emit a **structlog** line at the event's level (`log.info/warning/error("ai_agent_event",
     event_type=…, user_id=…, …)`) — always, per the superapp logging convention;
  2. **best-effort** durable write: open a **fresh** session (`get_sessionmaker()`), insert the row,
     commit, swallowing `SQLAlchemyError` (rollback). **Never raises** — a logging failure must not
     affect the agent request. Structlog is emitted even if the DB write fails.
- **`app/agent_auth.py`** (modify) — wire the data-plane events:
  - `get_agent_principal`: before each `AgentApiError(401)`, `await log_agent_event("AUTH_FAILED",
    status=401, details={"reason": …})` (`missing_token` / `invalid_token`); the **expired** branch logs
    with the token's `user_id` + `agent_name`.
  - `require_scope`: it gains a `request: Request` param; on the 403 branch
    `await log_agent_event("SCOPE_DENIED", user_id, agent_name, endpoint=f"{method} {path}", status=403,
    details={"required": scope, "granted": principal.scopes})`; on success `await
    log_agent_event("ACCESS", user_id, agent_name, endpoint=…)` (logged after the scope check passes,
    before the handler — matching the legacy).
- **Tests.**

# Decisions (design rulings to confirm at Gate 1)

- **structlog + domain log table** — the legacy `console.* + DB insert` becomes the superapp pattern:
  structlog for the immediate structured line (correlation_id already bound by the middleware) and the
  typed `ai_agent_logs` table for the durable audit. `details` is JSONB only for the genuinely variable
  context (denial reason, scope sets) — every fixed attribute is a typed column.
- **Best-effort, await-inline (a deliberate, safer deviation from the legacy fire-and-forget)** — the
  insert runs on a **fresh** session (decoupled from the request transaction, which on `AUTH_FAILED`/
  `SCOPE_DENIED` is about to raise) and is **awaited** with `SQLAlchemyError` swallowed. Chosen over a
  floating `create_task`/promise for safety (no session-lifetime, cancellation, or GC-of-orphan-task
  risk) and deterministic testability. Cost: one INSERT per logged event; an async-queue optimization is
  out of scope.
- **Events this slice:** `ACCESS`, `AUTH_FAILED`, `SCOPE_DENIED`. `AUTH_FAILED` carries no `endpoint`
  (auth precedes routing, matching the legacy); `ACCESS`/`SCOPE_DENIED` carry `endpoint`. **`ACCESS`
  means "scoped ingress accepted"** — it is logged when the token + scope check pass, *before* the
  handler runs, so it records that the agent was let in, **not** that the handler returned 2xx (a
  handler that later errors still has its `ACCESS` row; this matches the legacy ordering).
- **Tenant of the log row** — `user_id` is the token owner (for `ACCESS`/`SCOPE_DENIED`/expired); a
  pre-identification `AUTH_FAILED` (missing/invalid) has `user_id = null`.

# Out of scope

- The **control-plane** token events (`TOKEN_CREATED`/`TOKEN_ROTATED`/`TOKEN_REVOKED`/`AGENT_RENAMED`) —
  a follow-on logs slice over the token service.
- `RATE_LIMITED` (the rate-limit slice), `ICAL_TOKEN_*` (iCal), `WEBHOOK_UPDATED` (webhook), `DB_ERROR`
  (unhandled DB errors already surface via structlog/Sentry); a read/query API for logs; retention.

# Acceptance criteria

- [ ] A request with no / an oversized / an unknown `X-Focal-Token` writes an `AUTH_FAILED` row
      (`level=warn`, `status=401`, `details.reason`), and the request still returns 401; an **expired**
      token writes `AUTH_FAILED` carrying the token's `user_id` + `agent_name`.
- [ ] A valid token lacking the endpoint scope writes a `SCOPE_DENIED` row (`warn`, `status=403`,
      `endpoint`, `details.required` + `details.granted`) and still 403s; a valid + scoped call writes an
      `ACCESS` row (`info`, `endpoint`, `user_id`, `agent_name`) and still 200s.
- [ ] `log_agent_event` never raises: if the durable insert fails, the agent request still succeeds and
      the structlog line is still emitted (covered by a fault-injection test).
- [ ] `ai_agent_logs` is created with the four indexes; `alembic upgrade head` + `alembic check` clean;
      `make verify` green.

# Verification commands

```sh
make verify
docker exec focal-local-postgres-1 psql -U focal -d focal_dev -c "DROP SCHEMA IF EXISTS focal CASCADE; CREATE SCHEMA focal; DROP TABLE IF EXISTS public.alembic_version;"
DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev uv run --frozen alembic upgrade head
DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev uv run --frozen alembic check
```

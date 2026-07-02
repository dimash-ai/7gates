# Summary

Implement `focal-agent-logs` (Phase 8 hardening): the `ai_agent_logs` audit table + a best-effort
`log_agent_event` helper (structlog + a durable row), wired into the X-Focal-Token auth/scope path for
the data-plane events `ACCESS`, `AUTH_FAILED`, `SCOPE_DENIED`. Control-plane token events and
RATE_LIMITED/iCal/webhook events are deferred. Task:
[focal-agent-logs.md](../tasks/focal-agent-logs.md). Legacy: `agentLogging.ts`, `schema.ts:1692`.

## Decisions (design + the Gate-1 ruling)

- **`app/models/agent_log.py`** — `AiAgentLog` (`ai_agent_logs`), extends `Base` (only `created_at`):
  String uuid PK; `created_at` (tz-aware, `default=utcnow`, `index=True`); `event_type` (String(50),
  `index=True`); `level` (String(10)); `user_id` (String, nullable, `index=True`); `agent_name`
  (String(100), nullable, `index=True`); `endpoint` (String(255), nullable); `status` (Integer,
  nullable); `details` (JSONB, nullable — `dict[str, Any] | None`); `type` (SmallInteger, default 1).
  `__table_args__ = {"schema": "focal"}`. Registered in `app/models/__init__.py`; migration in-slice.
  The four `index=True` give `ix_focal_ai_agent_logs_{created_at,event_type,user_id,agent_name}`.
- **`app/agent_logging.py`** — `log = structlog.get_logger(__name__)`; `AGENT_EVENT_LEVELS = {"ACCESS":
  "info", "AUTH_FAILED": "warn", "SCOPE_DENIED": "warn"}`. `async def log_agent_event(event_type, *,
  user_id=None, agent_name=None, endpoint=None, status=None, details=None) -> None`:
  1. `level = AGENT_EVENT_LEVELS.get(event_type, "warn")`; dispatch `{"info": log.info, "warn":
     log.warning, "error": log.error}[level]("ai_agent_event", event_type=…, user_id=…, agent_name=…,
     endpoint=…, status=…, details=…)` — **always** (the structured line; `details` passed as one nested
     field, no kwargs spread, to avoid key collisions).
  2. best-effort durable write in a **fresh** session: `try: async with get_sessionmaker()() as
     session: session.add(AiAgentLog(...)); await session.commit() except SQLAlchemyError:
     log.error("ai_agent_log_write_failed", event_type=event_type)`. **Never raises.**
- **`app/agent_auth.py`** (modify) —
  - `get_agent_principal`: `await log_agent_event("AUTH_FAILED", status=401, details={"reason":
    "missing_token"})` before the missing-token raise; `"invalid_token"` for the oversized + not-found
    raises; the **expired** branch logs `user_id=token.user_id, agent_name=token.name, status=401,
    details={"reason": "expired"}`. No `endpoint` (auth precedes routing).
  - `require_scope`: the inner dep gains `request: Request`; `endpoint = f"{request.method}
    {request.url.path}"`. On the missing-scope branch `await log_agent_event("SCOPE_DENIED", user_id=…,
    agent_name=…, endpoint=…, status=403, details={"required": scope, "granted": principal.scopes})`
    then raise; on pass `await log_agent_event("ACCESS", user_id=…, agent_name=…, endpoint=…)` then
    return. Imports add `Request` (fastapi) + `log_agent_event`.

# Files to change

| path | change | why |
|------|--------|-----|
| `app/models/agent_log.py` | add | the `AiAgentLog` model |
| `app/models/__init__.py` | modify | register `AiAgentLog` |
| `alembic/versions/<rev>_ai_agent_logs.py` | add | the new-table migration |
| `app/agent_logging.py` | add | `AGENT_EVENT_LEVELS` + `log_agent_event` |
| `app/agent_auth.py` | modify | emit AUTH_FAILED / SCOPE_DENIED / ACCESS |
| `tests/test_agent_logs_db.py` | add | rows per event + never-raises |
| `tests/test_migration.py` | modify | assert the table + the four indexes |

# Implementation slices

1. **Model + registration + migration + `log_agent_event`.** *Verify:* reset → `alembic upgrade head` →
   `alembic check`; imports + ruff/mypy.
2. **Wire `agent_auth.py`.** *Verify:* `make verify`.
3. **Tests.** *Verify:* full `make verify` green.

# Tests (`tests/test_agent_logs_db.py`, DB-backed; queries `ai_agent_logs` after each call)

- **AUTH_FAILED:** no token → 401 **and** one `AUTH_FAILED` row (`level=warn`, `status=401`,
  `details={"reason":"missing_token"}`, `user_id` null, `endpoint` null); an oversized and an unknown
  token → `reason="invalid_token"`; an **expired** token → `AUTH_FAILED` with the token's `user_id` +
  `agent_name` + `reason="expired"`.
- **SCOPE_DENIED:** a token without `events:read` → 403 **and** a `SCOPE_DENIED` row (`warn`,
  `status=403`, `endpoint="GET /api/ai-agent/v1/events/today"`, `details.required="events:read"`,
  `details.granted=<scopes>`).
- **ACCESS:** a valid scoped token → 200 **and** an `ACCESS` row (`info`, `endpoint`, `user_id`,
  `agent_name`, `status` null).
- **never-raises (+ structlog survives):** monkeypatch `app.agent_logging.get_sessionmaker` to raise
  `SQLAlchemyError`; inside a `structlog.testing.capture_logs()` block a valid agent call still returns
  200, **and** the captured events still include the `ai_agent_event` line with `event_type="ACCESS"`
  (the structlog emit precedes and survives the swallowed durable write); no `ai_agent_logs` row is
  written for that call.
- **migration:** `test_migration.py` asserts `CREATE TABLE focal.ai_agent_logs` + the four
  `ix_focal_ai_agent_logs_*` indexes; downgrade drops it.

# Error & rescue map

| failure | handling |
|---------|----------|
| the durable `ai_agent_logs` insert fails | `SQLAlchemyError` swallowed; a structlog `ai_agent_log_write_failed` is emitted; the agent request is unaffected |
| any agent auth/scope failure | logged (AUTH_FAILED/SCOPE_DENIED) **then** the existing `AgentApiError` propagates unchanged |

# Risks

- **Logging must not change auth behavior** — every `log_agent_event` is `await`ed **before** the
  existing raise/return, on a separate session, and never raises; the auth/scope status codes are
  unchanged. Pinned by the existing auth tests (still green) + the never-raises test.
- **One INSERT per logged event** (incl. `ACCESS` on every accepted call) — accepted; an async-queue
  optimization is out of scope and noted.
- **Migration** adds `ai_agent_logs`; `alembic check` clean after.

# Scope check

- [x] Matches the task (data-plane access audit; control-plane/RATE_LIMITED/iCal/webhook deferred).
- [x] Reviewable in one pass — one model + migration + one logging module + the auth-dep wiring + tests.
- [x] Size smell: a table + a helper + ~6 one-line call sites.

# Out of scope

Control-plane token events (`TOKEN_CREATED`/`ROTATED`/`REVOKED`/`AGENT_RENAMED`); `RATE_LIMITED`;
`ICAL_TOKEN_*`; `WEBHOOK_UPDATED`; `DB_ERROR`; a log read/query API; retention/rotation.

# Summary

Implement `focal-agent-events` (Phase 8, slice B): the **X-Focal-Token agent-auth foundation** + the two
read-only **events** endpoints under `/api/ai-agent/v1`. An incoming `X-Focal-Token` is sha256'd and
matched against `ai_agent_tokens.token_hash`; on success it resolves to an `AgentPrincipal`
(`user_id`/`agent_name`/`scopes`) and touches `last_used_at`. `require_scope` gates each endpoint. The
agent surface uses its own envelope — success `{ok,data,meta?}`, error `{ok:false,error}` — via a new
`AgentApiError` + handler. Tasks/goals/budgets `/v1` endpoints reuse this foundation later. No schema
change (the table already exists). Task: [focal-agent-events.md](../tasks/focal-agent-events.md). Legacy:
`ai-agent-auth.ts:103-181`, `ai-agent.ts:104-128`, `ai-agent.ts:691-773`.

## Decisions (design + the Gate-1 rulings)

- **One overridable session for the request.** `get_agent_session` (a generator dep over
  `get_sessionmaker()`) is depended on by **both** the auth dep and the data service, so FastAPI caches
  it once per request → a single session does the `last_used_at` touch and the events query. Tests
  override this one dep.
- **`app/agent_auth.py`** —
  - `AgentPrincipal` (frozen dataclass): `token_id`, `user_id`, `agent_name`, `scopes` (str).
  - `get_agent_principal(x_focal_token: Annotated[str | None, Header(default=None)], session=Depends(
    get_agent_session))`: header missing → 401; `len > 128` → 401; sha256 → lookup `token_hash`; not
    found → 401; `expires_at` set and `< datetime.now(UTC)` → 401. On success, read the fields into
    locals, then **best-effort** touch `last_used_at = utcnow()` + commit wrapped in `try/except
    SQLAlchemyError: rollback()` (a telemetry write must never 500 the call), and return the principal.
  - **The header MUST be optional (`Header(default=None)`)** — a *required* `Header()` would make a
    missing token raise FastAPI's `RequestValidationError` → 422 via the global handler, leaking the
    wrong (non-agent) envelope; optional lets a missing header reach our code and raise
    `AgentApiError(401)`. FastAPI case-insensitively maps `x_focal_token` → `x-focal-token`.
  - `require_scope(scope) -> dep`: a factory whose dep `Depends(get_agent_principal)` and raises
    `AgentApiError(403)` if `scope` ∉ `principal.scopes.split(" ")`, else returns the principal.
- **`app/errors.py`** — add `AgentApiError(AppError)` and `agent_error_handler` →
  `JSONResponse(status_code=exc.status_code, content={"ok": False, "error": exc.message})`. Registered in
  `main.py`; Starlette resolves the most-specific handler by MRO, so `AgentApiError` renders the agent
  envelope while every other `AppError` keeps the standard `{error:{code,message}}`.
- **`app/schemas/agent_api.py`** — `AgentEventRead(_Camel, from_attributes=True)` with exactly the
  agent-facing fields: `id, title, date (date), start_time, end_time, description, location, priority,
  status, tags (list[str]), recurrence, timezone, project_id, product_id` (camelCase out; **no**
  `user_id`/`activity_id`/internal columns). Envelopes (plain `BaseModel`, `ok` defaults true):
  `EventsTodayEnvelope{ok, data: list[AgentEventRead], meta: {timezone: str, date: date}}` and
  `EventsEnvelope{ok, data}`.
- **`app/services/agent_data.py`** — `AgentDataService(session)`: `events_today(user_id, day)` selects
  `CalendarEvent` where `user_id == ` + `date == day`, ordered by `start_time`; `events_range(user_id,
  frm, to)` selects `date` in `[frm, to]` ordered by `date, start_time`. Raw rows → `AgentEventRead`
  (no recurrence expansion). Tenant = the token's `user_id`.
- **`app/api/agent_data.py`** — router **prefix `/api/ai-agent/v1`**; module helpers `resolve_timezone`
  and `parse_event_range` raise `AgentApiError(400)`:
  - `GET /events/today` (`Depends(require_scope("events:read"))`) — `tz` (default `Asia/Almaty`,
    validated via `ZoneInfo` → 400); `day = datetime.now(ZoneInfo(tz)).date()`; returns
    `EventsTodayEnvelope(data=…, meta={timezone: tz, date: day})`.
  - `GET /events` — `tz`, `from`, `to` (str query, no Pydantic coercion); defaults `from = today-in-tz`,
    `to = +7d`; `YYYY-MM-DD` shape via regex (→ 400), `date.fromisoformat` (invalid calendar date → 400),
    `frm > to` → 400, `(to - frm).days > 366` → 400; returns `EventsEnvelope`.
- **English error messages** (consistent with the rest of the new app), not the legacy Russian strings —
  the `ok:false` flag is the client contract, not the human string. Manual validation (not Pydantic
  query coercion) keeps every failure in the agent envelope (no 422 leak).
- **Deferred (not built here):** per-token rate-limiting (Redis, 60/min → 429); `ai_agent_logs` writes;
  the `X-OpenClaw-Token` alias; tasks/goals/budgets endpoints; iCal; webhooks.

# Files to change

| path | change | why |
|------|--------|-----|
| `app/agent_auth.py` | add | `get_agent_session`, `AgentPrincipal`, `get_agent_principal`, `require_scope` |
| `app/errors.py` | modify | `AgentApiError` + `agent_error_handler` |
| `app/main.py` | modify | register the handler + the agent-data router |
| `app/schemas/agent_api.py` | add | `AgentEventRead` + the two envelopes |
| `app/services/agent_data.py` | add | `AgentDataService` (events_today / events_range) |
| `app/api/agent_data.py` | add | the `/api/ai-agent/v1` router + tz/range validation |
| `tests/test_agent_events_db.py` | add | auth, scope, both endpoints, tenant, last_used_at, envelope |

# Implementation slices

1. **Auth foundation.** `errors.py` (`AgentApiError` + handler) → `agent_auth.py` (`get_agent_session`,
   `AgentPrincipal`, `get_agent_principal`, `require_scope`) → register the handler. *Verify:* imports +
   ruff/mypy.
2. **Schemas + service + router + main.** *Verify:* `make verify`.
3. **Tests.** *Verify:* full `make verify` green.

# Tests (`tests/test_agent_events_db.py`, DB-backed; seeds tokens + events via the test sessionmaker)

- **auth:** no `X-Focal-Token` → 401 `{ok:false,error}`; a >128-char token → 401; an unknown token →
  401; a row with `expires_at` in the past → 401; a valid token → 200. Each error body is the agent
  envelope (not `{error:{code…}}`).
- **scope:** a token whose `scopes` omit `events:read` → 403; including it → 200.
- **events/today:** seeds events on several dates; returns only today-in-`tz` ordered by `start_time`;
  body is `{ok, data, meta:{timezone, date}}`; the item carries camelCase agent fields and asserts the
  omitted internals are **absent** — no `userId`, `activityId`, `tokenHash`, `createdAt`/`updatedAt`; an
  invalid `tz` → 400.
- **events range:** default window (no `from`/`to`); explicit `from`/`to` inclusive, ordered by
  `date` then `start_time`; malformed date → 400; `from > to` → 400; span > 366 days → 400.
- **tenant:** a token for user-A never returns user-B's events.
- **last_used_at:** null before the first call, set after a successful call.
- **last_used_at failure is swallowed:** override the session so the touch's `commit` raises
  `SQLAlchemyError`; assert the events call still returns **200** with the `{ok,data}` success envelope
  (the shared session is rolled back and the SELECT still runs — a telemetry failure never 500s).

# Error & rescue map

| failure | error | response |
|---------|-------|----------|
| missing / >128 / unknown / expired token | `AgentApiError` | 401 `{ok:false,error}` |
| token lacks the endpoint scope | `AgentApiError` | 403 `{ok:false,error}` |
| bad tz / bad date / from>to / span>366 | `AgentApiError` | 400 `{ok:false,error}` |
| `last_used_at` touch fails | swallowed (`SQLAlchemyError` → rollback) | request still 200 |

# Risks

- **Two envelopes coexist** — `AgentApiError` must resolve to its own handler. Pinned by the test that
  asserts a 401/403/400 body is `{ok:false,error}` while the rest of the app keeps `{error:{…}}`.
- **No Pydantic coercion on query params** — `tz`/`from`/`to` are `str | None`; all validation is manual,
  so no 422 escapes the agent envelope. Pinned by the 400 tests.
- **Best-effort telemetry** — a `last_used_at` write failure is swallowed, never failing the data call.
- **No migration / no behavior change** to existing endpoints — additive only.

# Scope check

- [x] Matches the task (auth foundation + events; tasks/goals/budgets/rate-limit/logs/iCal deferred).
- [x] Reviewable in one pass — one auth module + one service + one router + one error subclass + tests.
- [x] Size smell: ~3 small modules + a focused test file; no schema change.

# Out of scope

Rate-limiting (Redis) + 429; `ai_agent_logs` + `logAgentEvent`; `X-OpenClaw-Token`; `/v1/tasks`,
`/v1/tasks/{id}/complete`, `/v1/goals`, `/v1/time-budgets`; iCal; webhooks; FastMCP; React UI; ETL.

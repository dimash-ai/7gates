# Goal

Port the **X-Focal-Token agent-auth foundation** + the first agent **data endpoints** (Phase 8, slice B
of the `foc_` agent API): an `X-Focal-Token` authentication dependency, scope enforcement, the agent
`{ok,data,meta}` response envelope, and the two read-only **events** endpoints under
`/api/ai-agent/v1`. Tasks read/write, goals, time-budgets are later slices that reuse this foundation.
Builds on the token lifecycle (already shipped). Legacy: `ai-agent-auth.ts:103-181`,
`ai-agent.ts:104-128` (`requireScope`), `ai-agent.ts:691-773` (events).

# Scope

- **`app/agent_auth.py`** — the agent authentication surface (the bot-facing counterpart to the user
  JWT dep):
  - `AgentPrincipal` (frozen dataclass / Pydantic): `token_id`, `user_id`, `agent_name`, `scopes` (the
    space-separated string).
  - `get_agent_principal(x_focal_token, session) -> AgentPrincipal` — reads the `X-Focal-Token` header:
    missing → **401**; length > 128 → **401**; sha256 the raw token and look up `ai_agent_tokens.token_hash`;
    not found → **401**; `expires_at` set and in the past (vs `datetime.now(UTC)`) → **401**; on success
    touch `last_used_at` (best-effort — telemetry, must not fail the request) and return the principal.
  - `require_scope(scope) -> dependency` — a factory returning a FastAPI dependency that resolves
    `get_agent_principal` and checks `scope` ∈ the token's space-split scopes; missing → **403**. Returns
    the principal so handlers get the `user_id` for free.
- **Agent error envelope** — the agent API uses a different envelope from the rest of the app
  (`{ok:false, error}` not `{error:{code,message}}`). Add `AgentApiError(AppError)` + an exception
  handler that renders `{"ok": false, "error": <message>}` at the error's status; register it in
  `app/main.py`. The auth/scope deps and the endpoints raise `AgentApiError` (401/403/400). Success
  responses are `{"ok": true, "data": ..., "meta"?: ...}`.
- **`app/schemas/agent_api.py`** — the per-event projection the agent sees (`id, title, date, startTime,
  endTime, description, location, priority, status, tags, recurrence, timezone, projectId, productId` —
  camelCase, **never** the internal columns) and the typed envelope models.
- **`app/api/agent_data.py`** — the agent-data router, **prefix `/api/ai-agent/v1`** (so the route paths
  below are relative — they must NOT repeat `/v1`, else the public path doubles to `/v1/v1/...`):
  - `GET /events/today` → public `/api/ai-agent/v1/events/today` (`require_scope("events:read")`) — `tz`
    query (default `Asia/Almaty`, validated → 400); selects the caller's `CalendarEvent` rows whose
    stored `date` equals today-in-`tz`, ordered by start time; returns `{ok, data, meta:{timezone, date}}`.
  - `GET /events` → public `/api/ai-agent/v1/events` (`require_scope("events:read")`) — `tz`, `from`, `to` queries (`from` default
    today-in-`tz`, `to` default +7d); validate `YYYY-MM-DD` format (→ 400), `from <= to` (→ 400), span
    ≤ **366** days (→ 400); selects the caller's rows in `[from, to]` ordered by `date`, start time;
    returns `{ok, data}`.
  - Raw stored rows only — **no** recurrence expansion (faithful to the legacy; the agent sees the
    `recurrence` rule string). Tenant = the token's `user_id`. Registered in `app/main.py`.
- **Tests.**

# Decisions (design rulings to confirm at Gate 1)

- **Agent auth is a separate dependency from the user JWT** — same domain/services underneath, a
  different adapter (`X-Focal-Token` → token-hash lookup), exactly as the legacy keeps the agent API and
  the user API as separate adapters over one service layer.
- **Distinct response envelope** for `/v1/*`: success `{ok:true,data,meta?}`, error `{ok:false,error}`.
  This is intentional divergence from the app's standard `{error:{code,message}}` shape, scoped to the
  agent surface, for client (OpenClaw etc.) + ETL fidelity. Implemented via `AgentApiError` + its own
  handler — **not** by changing the app-wide handler.
- **Manual input validation** (tz / date format / range) raising `AgentApiError(400)` rather than
  Pydantic query coercion, so every failure renders the agent envelope (not a 422 from the global
  validation handler). Faithful to the legacy's explicit checks.
- **`last_used_at` is best-effort** — a telemetry touch; a failure there must never 500 the data call.
- **Hash-only auth** — the incoming token is sha256'd and matched against `token_hash`; the raw token is
  never stored or logged. Length is capped at 128 before hashing (cheap junk-rejection).
- **Deferred, explicitly not built here:** per-token rate-limiting (Redis, 60/min) — the agent calls
  succeed without it this slice; the `ai_agent_logs` audit writes (`AUTH_FAILED`/`ACCESS`/`SCOPE_DENIED`);
  the `X-OpenClaw-Token` alias (the legacy now accepts only `X-Focal-Token`); tasks/goals/time-budgets
  endpoints; iCal; webhooks.

# Out of scope

- Tasks (`/v1/tasks`, `/v1/tasks/{id}/complete`), goals (`/v1/goals`), time-budgets
  (`/v1/time-budgets`) endpoints — later slices over the same foundation.
- Per-token rate-limiting (Redis sliding window) + the `429` path; the `ai_agent_logs` table +
  `logAgentEvent`; iCal `/v1/calendar.ics`; webhook delivery; the FastMCP adapter; React UI; ETL.

# Acceptance criteria

- [ ] A request to a `/v1` endpoint with **no** `X-Focal-Token` → 401 `{ok:false,error}`; a token > 128
      chars → 401; a well-formed-but-unknown token → 401; an **expired** token → 401.
- [ ] A valid token whose `scopes` lack the endpoint's scope → 403 `{ok:false,error}`; a token that has
      it → 200.
- [ ] `GET /v1/events/today` returns the caller's events for today-in-`tz` as `{ok,data,meta:{timezone,
      date}}`; an invalid `tz` → 400; the event projection carries only the agent-facing fields (no
      `userId`/`tokenHash`/internal columns).
- [ ] `GET /v1/events` honours `from`/`to`/`tz` with the documented defaults; a malformed date → 400,
      `from > to` → 400, a span > 366 days → 400; the happy path returns `{ok,data}` ordered by date then
      start time, scoped to the caller.
- [ ] A successful call updates the token's `last_used_at`; if that telemetry touch itself fails it is
      swallowed and the data response still succeeds (best-effort, never 500s the call). A token
      belonging to another user never surfaces that user's events (tenant isolation via the token's
      `user_id`).
- [ ] `make verify` green; no new migration (additive code only — the table already exists).

# Verification commands

```sh
make verify
```

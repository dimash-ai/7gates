# Summary

Implement `focal-agent-rate-limit` (Phase 8 hardening): a per-token **60/min** in-process limiter on the
agent API — an over-limit request gets **429** + a `RATE_LIMITED` audit row. Wired into
`get_agent_principal` after token validation. The distributed Redis backend is a deferred prod-readiness
follow-on (Gate-1 ratified). No schema change. Task:
[focal-agent-rate-limit.md](../tasks/focal-agent-rate-limit.md). Legacy: `ai-agent-auth.ts`.

## Decisions (design + the Gate-1 rulings)

- **`app/rate_limit.py`** — `RATE_LIMIT_MAX = 60`, `RATE_LIMIT_WINDOW_S = 60.0`; a module-level
  `dict[str, _Bucket]` (`_Bucket(count, reset_at)`). `check_rate_limit(token_id) -> bool` (synchronous):
  `now = time.monotonic()`; if no bucket or `now >= bucket.reset_at` → start a fresh window
  `{count: 1, reset_at: now + WINDOW}` and return `True`; elif `bucket.count >= MAX` → return `False`;
  else `bucket.count += 1` and return `True`. A faithful port of the legacy `checkRateLimitLocal`.
  `reset_rate_limiter()` clears the dict (tests). Uses `from time import monotonic` (interval-safe; the
  module-level `monotonic` binding is monkeypatchable for the window-expiry test).
- **`app/agent_logging.py`** (modify) — add `"RATE_LIMITED": "warn"` to `AGENT_EVENT_LEVELS`.
- **`app/agent_auth.py`** (modify) — in `get_agent_principal`, **after** the expiry block and **before**
  the `AgentPrincipal` build + `last_used_at` touch: `if not check_rate_limit(token.id):` → `await
  log_agent_event("RATE_LIMITED", user_id=token.user_id, agent_name=token.name, status=429)` then
  `raise AgentApiError("Rate limit exceeded (60 requests per minute)", status_code=429)`. So a 429
  raises before the telemetry touch (the limited request does **not** update `last_used_at`). Import
  `check_rate_limit`.

# Files to change

| path | change | why |
|------|--------|-----|
| `app/rate_limit.py` | add | the in-process fixed-window limiter |
| `app/agent_logging.py` | modify | `RATE_LIMITED` → `warn` |
| `app/agent_auth.py` | modify | enforce the limit + emit `RATE_LIMITED` |
| `tests/test_agent_rate_limit.py` | add | unit + integration (429, no-touch, 401-first) |

# Implementation slices

1. **Limiter + level.** *Verify:* unit tests + ruff/mypy.
2. **Wire `agent_auth.py`.** *Verify:* `make verify`.
3. **Integration tests.** *Verify:* full `make verify`.

# Tests (`tests/test_agent_rate_limit.py`; an autouse fixture calls `reset_rate_limiter()`)

- **unit (no DB):** `check_rate_limit("a")` → `True` for 60 calls, `False` on the 61st; after
  `reset_rate_limiter()` → `True` again; `check_rate_limit("a")` and `check_rate_limit("b")` keep
  independent counts.
- **unit — natural window expiry (no DB):** monkeypatch `app.rate_limit.monotonic` to a controllable
  clock; fill the window to the limit (`False` on the 61st), advance the clock past
  `RATE_LIMIT_WINDOW_S`, then `check_rate_limit` → `True` again (the window reset by time, not by
  `reset_rate_limiter()`).
- **integration — at limit (DB):** seed a token (capture its `id`); fill its bucket with 60
  `check_rate_limit(id)` calls; one `GET /v1/events/today` → **429** + one `RATE_LIMITED` row
  (`level=warn`, `status=429`, `user_id`, `agent_name`); the token's `last_used_at` is still **null**.
- **integration — under limit (DB):** a fresh token → `GET /v1/events/today` → **200** (no `RATE_LIMITED`
  row); its `last_used_at` is set (normal traffic unaffected).
- **integration — invalid first (DB):** an unknown `X-Focal-Token` → **401** and **no** `RATE_LIMITED`
  row (the limiter is past the token lookup).

# Error & rescue map

| condition | handling |
|-----------|----------|
| token over 60/min | `RATE_LIMITED` row + `AgentApiError(429)`; `last_used_at` untouched |
| invalid / expired token | 401 before the limiter (no `RATE_LIMITED`) |
| the `RATE_LIMITED` log write fails | swallowed inside `log_agent_event`; the 429 still returns |

# Risks

- **Per-process state** — a single instance is fully limited; multi-replica prod under-counts until the
  deferred Redis backend lands. Encapsulated behind `check_rate_limit()`; noted.
- **Test isolation** — the in-memory dict is process-global; `reset_rate_limiter()` (autouse) clears it
  between the rate-limit tests. Other agent suites use unique token ids (uuid) so they never approach
  the cap; the whole suite stays green (normal traffic is unaffected).
- **No migration / no schema change.**

# Scope check

- [x] Matches the task (in-memory 60/min limiter + 429 + `RATE_LIMITED`; Redis backend deferred).
- [x] Reviewable in one pass — one small module + one level + one auth-path insert + tests.
- [x] Size smell: tiny, pure-Python limiter.

# Out of scope

The distributed **Redis** backend (deferred prod-readiness follow-on); iCal; webhooks; any global /
per-tier limit beyond the fixed 60/min/token.

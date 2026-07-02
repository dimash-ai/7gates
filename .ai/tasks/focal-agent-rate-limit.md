# Goal

Port per-token **rate limiting** for the agent API (Phase 8 hardening): cap each `foc_` token at
**60 requests / minute**; an over-limit agent request gets **429** and a `RATE_LIMITED` audit row. Wires
into the X-Focal-Token auth path. Legacy: `ai-agent-auth.ts:43-99,164-169` (`checkRateLimit`).

# Scope

- **`app/rate_limit.py`** — `check_rate_limit(token_id: str) -> bool` (a synchronous, in-process
  fixed-window counter: `RATE_LIMIT_MAX = 60`, `RATE_LIMIT_WINDOW_S = 60`; returns `False` when the
  window's count exceeds the max, else records the hit and returns `True` — a faithful port of the
  legacy `checkRateLimitLocal`), plus `reset_rate_limiter()` for test isolation.
- **`app/agent_logging.py`** (modify) — add `RATE_LIMITED` → `warn` to `AGENT_EVENT_LEVELS`.
- **`app/agent_auth.py`** (modify) — in `get_agent_principal`, after the token is resolved + **not
  expired** and **before** the `last_used_at` touch (matching the legacy order — only authenticated
  tokens are limited; an invalid/expired token already 401s): `if not check_rate_limit(token.id):` →
  `await log_agent_event("RATE_LIMITED", user_id=token.user_id, agent_name=token.name, status=429)` then
  `raise AgentApiError("Rate limit exceeded (60 requests per minute)", status_code=429)`.
- **Tests.**

# Decisions (design rulings to confirm at Gate 1)

- **In-memory fixed-window now; the distributed Redis backend is deferred.** This is the design call to
  ratify:
  - The legacy's *own* fallback is the in-memory limiter; Upstash Redis is used only when configured.
  - The app is **pre-prod** (scaffold stage — no CI, no traffic; one dev process). In-process limiting is
    the full behavior for a single instance and a real per-token abuse cap now.
  - A Redis backend would bind a cached async client to one event loop — the same cross-loop test
    headache we already hit with the DB engine — and forces a fail-open-vs-closed policy on Redis
    outages. That is a **prod-readiness** change, best done when multi-replica correctness is the focus.
  - `check_rate_limit()` **encapsulates the backend**, so swapping in Redis later is a localized change
    behind the same call site — no auth-path churn.
  - **Known limitation (noted):** per-process (multi-replica prod under-counts) and the in-memory dict is
    not evicted (stale buckets for inactive tokens linger, as in the legacy) — both resolved by the
    deferred Redis/TTL backend.
- **Limit boundary** — only a *validated* token reaches the limiter (placed after resolve + expiry,
  before the telemetry touch), so the `RATE_LIMITED` row always carries the token's `user_id` +
  `agent_name`. `RATE_LIMITED` is `warn`, `status=429`.

# Out of scope

- The **distributed Redis** rate-limit backend (the legacy's Upstash path) — a deferred prod-readiness
  follow-on; iCal; webhooks; any per-tier/global limit (this is the fixed 60/min/token only).

# Acceptance criteria

- [ ] `check_rate_limit(id)` returns `True` for the first 60 calls in a window and `False` on the 61st;
      after `reset_rate_limiter()` (or a new window) the count restarts; two different ids are
      independent.
- [ ] A token already at the limit → the next `/v1` request returns **429** and writes one
      `RATE_LIMITED` audit row (`level=warn`, `status=429`, `user_id`, `agent_name`); the request does
      **not** 500.
- [ ] A token under the limit → its `/v1` requests still 200 (no behavior change for normal traffic).
- [ ] An invalid/expired token still 401s **before** the limiter (no `RATE_LIMITED` row for it).
- [ ] A rate-limited (429) request does **not** update the token's `last_used_at` (the limiter precedes
      the telemetry touch).
- [ ] `make verify` green; no migration.

# Verification commands

```sh
make verify
```

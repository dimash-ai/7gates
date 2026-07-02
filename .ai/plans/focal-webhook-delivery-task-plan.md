# Summary

Implement `focal-webhook-delivery-task` (Phase 8, webhook slice 3b of 3 — the second delivery cut):
the impure orchestration consuming the merged slice-3a foundation. New `app/tasks/webhook.py` holds
the first real Celery task — `deliver_webhooks(user_id, event, data)` — which runs the async
`notifyAgent` fan-out on **a fresh OS thread with its own event loop** (NOT `asyncio.run` on the
caller's thread — that crashes under the eager-endpoint path), POSTs the **exact `serialize_payload`
bytes** 3a produces (`content=body`, never `json=`), drives 3a's `decide_delivery_outcome` across the
3-attempt retry/backoff loop, and maps each `DeliveryAction` to its DB side effect (2xx→reset,
4xx→atomic increment-or-disable, 3xx/5xx/network→transient retry-then-give-up with **no** `fail_count`
mutation). A pre-connect `resolve_and_check_host` gate (3a's deferred connect-time SSRF check) rejects
private-resolving hosts before any POST; `follow_redirects=False` preserves legacy `redirect:"error"`.
The single `task.completed` trigger is wired into `complete_task`, firing **only on the first
idempotent flip** — which requires the one minimal cross-file change: `complete_task` now returns
`(exists, newly_completed)` instead of a conflated `bool`, and the router unpacks it (the old
`if not await ...` truthiness test must be rewritten, since a 2-tuple is always truthy). An
in-request-enqueue contextvars wrap snapshots and **fully** restores the request's bound context
(`correlation_id` + `path` + `method`) so 3a's `task_postrun` global clear — which fires on the request
thread even with the fresh-thread dispatch — does not wipe the request trace. Task registration is
guaranteed by an explicit `from app.tasks import webhook` in `app/tasks/__init__.py` (Celery's
`autodiscover_tasks(["app.tasks"])` looks for `app.tasks.tasks`, which does not exist, so it would not
register the task in the real worker). `agent_logging.py` gains
`WEBHOOK_DELIVERED`/`WEBHOOK_FAILED`/`WEBHOOK_DISABLED` levels. DB-backed tests with
`httpx.MockTransport` — every one stubbing `app.domain.webhook.socket.getaddrinfo` to a public IP so
the SSRF gate does not silently skip delivery — prove every branch non-vacuously. No new dep, no
migration. Task: [focal-webhook-delivery-task.md](../tasks/focal-webhook-delivery-task.md). Foundation
it consumes: [focal-webhook-delivery-foundation.md](../tasks/focal-webhook-delivery-foundation.md).
Legacy: `ai-agent-webhook.ts` (`notifyAgent`/`fireWebhook`) + `ai-agent.ts:832-862` (the first-flip
trigger).

## Decisions (design + the Gate-1 rulings)

- **`app/tasks/__init__.py`** (new) — `"""..."""` + `from app.tasks import webhook  # noqa: F401` so
  importing the package registers the task (import-driven, worker-safe), independent of autodiscover.
- **`app/tasks/webhook.py`** (new):
  - `@celery_app.task(name="focal.deliver_webhooks") def deliver_webhooks(user_id: str, event: str,
    data: dict[str, Any]) -> None:` — sync entrypoint; body is
    `try: _run_in_fresh_loop(_deliver_all(user_id, event, data)) except Exception: log.error(...)` (the
    outermost best-effort swallow — never re-raises; legacy `notifyAgent` never throws into the caller).
  - `def _run_in_fresh_loop(coro) -> None:` — spawns a `threading.Thread` whose target runs
    `asyncio.run(coro)`, captures any exception in a box, `join()`s, and re-raises the boxed exception
    on the calling thread (so the outer swallow still catches it). Uniform across the eager-endpoint
    path (request thread has a running loop → bare `asyncio.run` would raise) and prod prefork (no loop).
  - `async def _deliver_all(user_id, event, data, *, client=None)`: `body =
    serialize_payload(build_webhook_payload(event, data, user_id, now=_now()))` where `_now() ->
    datetime` is a one-line module seam (`return datetime.now(UTC)`) the signed-body test patches to a
    frozen value; read the user's webhook-enabled agents into plain frozen dataclasses inside one
    session (`SELECT id, name,
    webhook_url, webhook_secret, webhook_fail_count … WHERE user_id = :uid AND webhook_url IS NOT
    NULL`); early-return if empty; `c = client or _make_client()`; `async with c:` →
    `await asyncio.gather(*[_deliver_to_agent(a, body, c) for a in agents], return_exceptions=True)`.
  - `def _make_client() -> httpx.AsyncClient:` — the single client factory (real `AsyncClient`); the
    in-request/trigger tests monkeypatch this to return a `MockTransport`-backed client; the branch
    tests pass `client=` directly to `_deliver_all`.
  - `async def _deliver_to_agent(agent, body, client)`: parse `webhook_url`; **pre-connect gate**
    `resolve_and_check_host(host, port=parsed.port or 443)` → if `None`, log `WEBHOOK_FAILED`
    `{"reason": "blocked_host"}` and return (no DB write, no POST); `signature = sign_payload(secret,
    body) if agent.webhook_secret else None`; `headers = build_webhook_headers(agent.name, uuid4().hex,
    signature)`; loop `for attempt in range(WEBHOOK_MAX_RETRIES + 1)`:
    `await asyncio.sleep(WEBHOOK_RETRY_DELAY_S * attempt)` (no-op on attempt 0); `try: r =
    await client.post(url, content=body, headers=headers, timeout=WEBHOOK_TIMEOUT_S,
    follow_redirects=False); status = r.status_code except httpx.HTTPError: status = None`;
    `action = decide_delivery_outcome(status=status, is_last_attempt=(attempt == WEBHOOK_MAX_RETRIES),
    fail_count=agent.webhook_fail_count)`; dispatch the action→side-effect map below; `RETRY` continues
    the loop, every other action returns.
  - **Action→side-effect map** (each DB write best-effort `try/except SQLAlchemyError: rollback`, like
    `touch_token_last_used`):
    - `RESET` → if `fail_count > 0`: `UPDATE … SET webhook_fail_count = 0`; `WEBHOOK_DELIVERED`.
    - `INCREMENT` → `UPDATE … SET webhook_fail_count = webhook_fail_count + 1` (atomic SQL);
      `WEBHOOK_FAILED`.
    - `DISABLE` → `UPDATE … SET webhook_url = NULL, webhook_secret = NULL, webhook_fail_count = 0`;
      `WEBHOOK_DISABLED`.
    - `GIVE_UP` → `WEBHOOK_FAILED` (no DB write — transient-no-mutation).
    - `RETRY` → continue (no DB write).
  - Sessions via a dedicated NullPool `_task_sessionmaker()` (NOT the app's pooled
    `get_sessionmaker()` — the worker's fresh per-invocation loop crashes on a pooled connection; see
    Decisions: session-nullpool); per-agent write opens its own short session; the audit passes
    `sessionmaker=_task_sessionmaker()` to `log_agent_event`.
- **`app/celery_app.py`** (modify) — add `celery_app.autodiscover_tasks(["app.tasks"])` after app
  creation (belt-and-suspenders; real registration is the init import); everything else unchanged.
- **`app/services/agent_data.py`** (modify) — `complete_task` returns `tuple[bool, bool]`
  `(exists, newly_completed)`: flip path → `(True, True)`; fallback-`select` path →
  `(existing is not None, False)`. The write is untouched.
- **`app/api/agent_data.py`** (modify) — `exists, newly_completed = await
  service.complete_task(...)` (replacing the truthiness `if not await ...`); `if not exists: raise
  AgentApiError("Task not found", 404)`; then `if newly_completed: with _preserve_contextvars(): try:
  deliver_webhooks.delay(user_id, "task.completed", {"id": task_id}) except Exception:
  log.error(...)`; `return OkEnvelope()`. `_preserve_contextvars()` snapshots
  `dict(structlog.contextvars.get_contextvars())` and on `__exit__` does
  `clear_contextvars(); bind_contextvars(**snapshot)` (the FULL dict).
- **`app/agent_logging.py`** (modify) — add `WEBHOOK_DELIVERED: "info"`, `WEBHOOK_FAILED: "warn"`,
  `WEBHOOK_DISABLED: "warn"` to `AGENT_EVENT_LEVELS`; add an optional
  `sessionmaker: async_sessionmaker[AsyncSession] | None = None` param (`sm = sessionmaker or
  get_sessionmaker()`) so the worker can pass its loop-safe NullPool sessionmaker. Default `None` →
  every existing request-path caller is unchanged.
- **Gate-1 rulings (flagged for the reviewer):**
  - **Fresh-thread `asyncio.run` in the sync task body** — eager runs the task on the request thread,
    which under `TestClient` + an `async def` endpoint has a **running** loop (verified empirically:
    bare `asyncio.run` there raises `RuntimeError: ... cannot be called from a running event loop`).
    `_run_in_fresh_loop` always starts a clean loop on a child thread, correct in both eager and prod.
    The trigger-path tests assert a **real POST**, not just a 200.
  - **Import-driven task registration** — `autodiscover_tasks(["app.tasks"])` searches `app.tasks.tasks`
    (default `related_name='tasks'`), which does not exist; `app/tasks/__init__.py`'s
    `from app.tasks import webhook` is what registers `focal.deliver_webhooks` in the real worker. The
    registration acceptance imports only the package (not the task module directly).
  - **Every delivery test stubs `app.domain.webhook.socket.getaddrinfo`** to a public IP so the
    pre-connect gate passes and the `MockTransport` is exercised (else the gate skips delivery on a real
    DNS lookup and the whole matrix passes vacuously). The SSRF-gate test stubs it to `10.0.0.5` and
    asserts zero POSTs.
  - **One client seam** — `_make_client()` factory + a `client=` kwarg on `_deliver_all`; branch tests
    pass `client=` directly, endpoint/trigger tests patch `_make_client`. The never-raises test injects
    the failure **above the gather** (`_make_client` or `_task_sessionmaker` itself raising, so
    `_deliver_all` raises before the per-agent `gather`) to reach the task's outer swallow — a failure
    inside `_deliver_to_agent` is collected by `gather(return_exceptions=True)` (the isolation test).
  - **Dedicated NullPool `_task_sessionmaker` (session-nullpool)** — the task must NOT use the app's
    pooled `get_sessionmaker()`: the worker runs each delivery on a fresh per-invocation loop and a
    pooled connection bound to a closed loop crashes the next invocation (verified: two sequential
    `asyncio.run`s on one pooled engine → `RuntimeError: Event loop is closed`; NullPool succeeds).
    `_task_sessionmaker()` is NullPool on `get_settings().database_url`, so the **tests exercise the
    real prod path with NO task-sessionmaker monkeypatch** (a patch would mask the bug). The audit uses
    `log_agent_event(..., sessionmaker=_task_sessionmaker())`. The autouse conftest logging patch still
    covers request-path `log_agent_event`.
  - **`complete_task → (exists, newly_completed)`** — the minimal faithful port of legacy's "did the
    `WHERE … completed=false` update match" branch (legacy comment: the guard prevents a duplicate
    webhook). The router unpacks the tuple and branches on `exists` (the old truthiness test would never
    404, since a non-empty tuple is truthy). The trigger fires iff `newly_completed`.
  - **Contextvars wrap restores the FULL dict** — `task_postrun`'s global clear fires on the request
    thread (verified, even with the fresh-thread dispatch); the middleware binds `correlation_id` +
    `path` + `method`, so a correlation_id-only restore loses `path`/`method`. Snapshot+restore the
    whole dict at the one in-request enqueue site (not a change to 3a's handler).
  - **Pre-connect SSRF gate, hostname connect, `follow_redirects=False`** — 3a's named TOCTOU residual
    accepted (no custom IP-pinned transport this slice); blocked host → logged `WEBHOOK_FAILED`
    `blocked_host` (a distinct alertable signal), no `fail_count` change. The gate's `getaddrinfo` and
    httpx's connect-time lookup are two independent resolutions (the residual is named in Risks).
  - **`content=body`, never `json=`** — the 3a acceptance row landing on 3b; signature verified from
    the captured POST body.
  - **`RETRY`/`GIVE_UP` write nothing; only `RESET`/`INCREMENT`/`DISABLE` mutate `fail_count`** — the
    3a transient-no-mutation contract; flaky 5xx/timeout/3xx never auto-disables (tests seed a non-zero
    `fail_count` and assert it is unchanged).
  - **`DISABLE` nulls url + secret and zeroes the counter** (`ai-agent-webhook.ts:193-196`).
  - **Fan-out `asyncio.gather(return_exceptions=True)`** — one agent's failure does not block others.
  - **Concurrent double-`DISABLE` accepted** — atomic increment + idempotent disable keep the counter
    correct; `SELECT … FOR UPDATE` out of scope.
  - **Audit logs carry no secret/signature** — only `delivery_id`/`status`/`agent_name`/`user_id`.
  - **The enqueue is best-effort, nested inside the contextvars `with`** — `task_eager_propagates=True`
    in the fixture means the call-site swallow is load-bearing; the `try` is inside the `with` so the
    rebind always runs.
  - **No `AppError` in the task** — the deliberate fire-and-forget exception 3a named; the task's edge
    is `except Exception → log → return`. The only typed error is the unchanged router 404.
  - **No migration** (columns on head `acb242a1f541`); **no new dependency**.

# Files to change

| path | change | why |
|------|--------|-----|
| `app/tasks/__init__.py` | new | `from app.tasks import webhook` — import-driven task registration (autodiscover alone looks for `app.tasks.tasks`, which doesn't exist) |
| `app/tasks/webhook.py` | new | the `deliver_webhooks` task + `notifyAgent` fan-out: fresh-thread async dispatch, a dedicated NullPool `_task_sessionmaker`, pre-connect SSRF gate, signed `content=body` POST, retry loop driving `decide_delivery_outcome`, the action→DB-write map, best-effort swallow, `_make_client` seam |
| `app/celery_app.py` | modify | add `autodiscover_tasks(["app.tasks"])` (belt-and-suspenders) |
| `app/services/agent_data.py` | modify | `complete_task` → `(exists, newly_completed)` so the trigger fires only on the first flip |
| `app/api/agent_data.py` | modify | unpack the tuple + branch on `exists`; the `task.completed` trigger (enqueue on first flip only, contextvars-scoped, best-effort); `_preserve_contextvars` helper |
| `app/agent_logging.py` | modify | `WEBHOOK_DELIVERED`/`WEBHOOK_FAILED`/`WEBHOOK_DISABLED` levels + an optional `sessionmaker` param (default `None` → pooled, unchanged for request-path callers) |
| `tests/test_webhook_delivery_db.py` | new | DB-backed `MockTransport` tests for every `DeliveryAction` branch, fan-out, SSRF gate (+ the getaddrinfo public-IP stub on all delivery tests), signature-over-wire-bytes, trigger-once-real-POST, contextvars-survive-full-set, never-raises-deep, registration-without-direct-import |

`tests/test_agent_tasks_db.py` is **not** modified (its `test_complete_*` cases assert HTTP status
only, so the `(exists, newly_completed)` change needs no edit there).

# Implementation slices

1. **Log levels + service signature + router unpack.** Add the three `AGENT_EVENT_LEVELS` rows; change
   `complete_task` to return `(exists, newly_completed)`; rewrite the router call from
   `if not await service.complete_task(...)` to `exists, newly_completed = await ...` + branch on
   `exists`. *Verify:* ruff/mypy; existing `test_agent_tasks_db.py` complete/idempotent/404/403/
   cross-tenant cases still green (they assert HTTP status, so the 404 path must still 404 — this is the
   highest-risk mechanical edit).
2. **The task + package.** `app/tasks/__init__.py` (`from app.tasks import webhook`),
   `app/tasks/webhook.py` (`_make_client`, `_run_in_fresh_loop`, `_deliver_all`, `_deliver_to_agent`,
   the gate, retry loop, action map, swallow). Add `autodiscover_tasks` to `celery_app.py`. *Verify:*
   import + ruff/mypy; `"focal.deliver_webhooks" in celery_app.tasks` after importing only the package.
3. **Trigger wiring.** `_preserve_contextvars` (full-dict snapshot/restore) + the first-flip
   contextvars-scoped best-effort enqueue in the router. *Verify:* ruff/mypy + import.
4. **Tests + full run.** `tests/test_webhook_delivery_db.py` (the getaddrinfo public-IP stub helper on
   every delivery test; patch `asyncio.sleep`/`WEBHOOK_RETRY_DELAY_S` for the retry tests; **no**
   task-sessionmaker patch — `_task_sessionmaker()` is already NullPool on the test DB, so tests run the
   real prod path; `MockTransport` per scenario; the in-request seam via `_make_client` patch).
   *Verify:* full `make verify`.

# Tests

**`tests/test_webhook_delivery_db.py`** (DB-backed; mirrors `test_agent_tasks_db.py` scaffold —
`_run`/`asyncio.run`, NullPool `_engine`/`_sessionmaker`, module `_schema`, autouse `_truncate` of
`ai_agent_tokens, tasks, ai_agent_logs`; `TestClient(app)` with `get_agent_session` overridden;
**no** task-sessionmaker monkeypatch — the task's own `_task_sessionmaker()` is already NullPool on the
test DB's `DATABASE_URL`, so its writes land there on the real prod path):

- **Helpers:**
  - `_public_dns(monkeypatch)` — patches `app.domain.webhook.socket.getaddrinfo` to return a single
    public address (`93.184.216.34`, documentation range) so the pre-connect gate passes; **applied by
    every delivery test** (the SSRF-gate test overrides it to `10.0.0.5`).
  - `_seed_agent(user_id, *, webhook_url, webhook_secret, fail_count)` inserts an `AiAgentToken` with
    the webhook columns set; `_agent_row(agent_id)` reads back
    `(webhook_url, webhook_secret, webhook_fail_count)`.
  - `_mock_client(handler)` → `httpx.AsyncClient(transport=httpx.MockTransport(handler))`; `handler`
    factories return a sequence of `httpx.Response`s (or raise `httpx.ConnectError`/`TimeoutException`)
    and record each request (URL host + headers + body) into a counter list.
  - Branch tests call `_run(_deliver_all(uid, "task.completed", {"id": tid}, client=_mock_client(...)))`;
    trigger/contextvars tests drive `client.patch(.../complete)` with `_make_client` monkeypatched to
    return the mock client.
- **Registration without direct import:** in a subprocess or via importlib, import only `app.celery_app`
  and `app.tasks` (the package), then assert `"focal.deliver_webhooks" in app.celery_app.celery_app.tasks`
  — proving the init import (not a `from app.tasks.webhook import …`) registers it.
- **Signature over the wire bytes (non-vacuous):** seed secret; `_public_dns`; **patch
  `app.tasks.webhook._now` → `frozen`**; deliver `200`; recompute
  `"sha256=" + hmac.new(secret.encode(), captured_body, sha256).hexdigest()`, assert it equals the
  captured `X-Focal-Signature`, **and** `captured_body == serialize_payload(build_webhook_payload(
  "task.completed", {"id": tid, "т": "значение"}, uid, now=frozen))` — proves `content=body` + raw
  UTF-8 survives.
- **2xx reset (seed fail_count=2 → 0):** assert row `0`, `WEBHOOK_DELIVERED` logged with delivery_id +
  status 200.
- **Two sequential deliveries both write (cross-loop / NullPool guard):** complete two different
  pending tasks in turn (agent seeded `fail_count=2`, `200` each); assert both reset to `0` (two
  `WEBHOOK_DELIVERED` rows). Runs the real `_task_sessionmaker()` (no patch), so reverting to the
  pooled `get_sessionmaker()` makes the second delivery's fresh loop crash and the test fails. Pins
  session-nullpool.
- **2xx with fail_count already 0 (writes nothing, positively observed):** seed `0`, deliver `200`;
  attach a SQLAlchemy `after_cursor_execute` listener on the task engine counting `UPDATE
  ai_agent_tokens` statements; assert the count is 0, the row is still `0`, and `WEBHOOK_DELIVERED`
  logged — fails if the `if fail_count > 0` guard is removed.
- **4xx increment (seed 0 → 1, exactly 1 POST):** counter == 1; `WEBHOOK_FAILED` logged.
- **4xx disable (seed 2 → url/secret NULL, count 0, 1 POST):** `WEBHOOK_DISABLED` logged.
- **5xx retry→give-up (seed fail_count=1; 503 always; sleep patched):** counter == 3; `fail_count`
  still 1; url still set; `WEBHOOK_FAILED` once.
- **Network/timeout retry→give-up (seed fail_count=1):** transport raising `httpx.ConnectError` (and a
  second case `httpx.TimeoutException`); counter == 3; `fail_count` still 1; `WEBHOOK_FAILED`.
- **3xx not followed, not disabled (seed fail_count=1):** `302 Location: https://127.0.0.1/` always;
  assert every captured request host is the original webhook host (never `127.0.0.1`), counter == 3,
  `fail_count` still 1, `WEBHOOK_FAILED` (not `WEBHOOK_DISABLED`).
- **Pre-connect SSRF gate:** monkeypatch `app.domain.webhook.socket.getaddrinfo` so the host resolves
  to `10.0.0.5`; assert counter == 0 (no POST), `fail_count` unchanged, `WEBHOOK_FAILED`
  `{"reason": "blocked_host"}`.
- **Unsigned when no secret:** seed `webhook_secret=NULL`, `_public_dns`, deliver `200`; assert no
  `X-Focal-Signature` header, the other 4 headers present, `User-Agent == "Focal-Webhook/1.0"`.
- **Fan-out isolation:** two agents (A fail=1→400, B fail=2→200) + a third with `webhook_url=NULL`;
  `_public_dns`; one `_deliver_all`; assert A `fail_count==2`, B `fail_count==0`, the third never POSTed.
- **Trigger once on first flip, REAL POST (via TestClient + eager):** seed pending task + a webhook
  agent; `_public_dns`; patch `_make_client` → the mock client; first `PATCH …/complete` → 200 + counter
  == 1 (a real POST happened); second `PATCH` → 200 + counter unchanged (0 further); `PATCH` on
  missing/cross-tenant id → 404 + counter unchanged.
- **Contextvars survive the enqueue, full set:** inside a `complete_task` request under eager (with the
  route emitting a structlog line after the enqueue, or asserting via `capture_logs`), assert the line
  carries `correlation_id` AND `path` AND `method` — fails if `_preserve_contextvars` is removed or
  narrowed to one key.
- **Never raises into `complete_task` (above the gather):** patch `_make_client` (or
  `_task_sessionmaker`) to **itself raise** `RuntimeError`, so `_deliver_all` raises before the
  per-agent `gather(return_exceptions=True)`; assert the `PATCH` still returns 200 and a structlog
  error line was emitted by the task's **outer** swallow. (A failure inside `_deliver_to_agent` is
  collected by the gather — that's the fan-out-isolation test, not this one.)
- **No secret in logs:** assert no captured `WEBHOOK_*` row's `details`/fields contain the seeded
  secret value.

# Error & rescue map

| failure | error / exception | caught where | what the user sees |
|---------|-------------------|--------------|--------------------|
| webhook host resolves to a private/rebinding IP (or NXDOMAIN/IDNA) | none (gate returns `None`) | `_deliver_to_agent` pre-connect gate → log `WEBHOOK_FAILED` `blocked_host`, no POST, no DB write | nothing (request already 200); delivery skipped, `fail_count` untouched |
| webhook endpoint returns 4xx | none (a `Response`) | `decide_delivery_outcome` → `INCREMENT`/`DISABLE` → best-effort `UPDATE` | nothing; `fail_count` incremented or webhook disabled |
| webhook endpoint returns 5xx / 3xx / times out / connection refused | `httpx.HTTPError` → `status=None`, or a 3xx/5xx `Response` | the retry loop; transient → `RETRY` then `GIVE_UP` → `WEBHOOK_FAILED`, **no** DB write | nothing; retried up to 3 attempts, then given up, `fail_count` untouched |
| per-agent DB write fails (reset/increment/disable) | `SQLAlchemyError` | per-write `try/except SQLAlchemyError: rollback` → log, swallow | nothing; the write is best-effort, request unaffected |
| one agent throws unexpectedly in the fan-out | any `Exception` | `asyncio.gather(return_exceptions=True)` → the exception is collected, the other agents proceed | nothing; sibling deliveries unaffected |
| the whole task body throws unexpectedly (incl. a fresh-loop dispatch error) | any `Exception` (re-raised from the delivery thread) | the task's outer `try/except Exception: log.error` (and the call-site enqueue swallow) | nothing; `complete_task` still returns 200 — legacy `notifyAgent` never throws into the caller |
| broker/serialization failure at `.delay()` (or an eager task-body exception under `task_eager_propagates`) | `kombu` `OperationalError`/`EncodeError` / any re-propagated `Exception` | the call-site `try/except Exception` nested inside `_preserve_contextvars` | nothing; the 200 still returns (fire-and-forget), and the contextvars rebind still runs |
| task not found / already completed on `PATCH …/complete` | none | `complete_task` returns `(exists, newly_completed)`; router maps `not exists → 404`, fires no webhook when `not newly_completed` | 404 for missing/cross-tenant; 200 with **no** webhook for a repeat-complete |

(3b adds **no** new `AppError` path; the only typed error is the unchanged router
`AgentApiError("Task not found", 404)`. The delivery task swallows all failures best-effort — the
deliberate fire-and-forget exception 3a's task Decisions named.)

# Risks & migrations

- **`asyncio.run` from the eager-endpoint thread crashes (the highest-severity correctness trap) —
  mitigated by the fresh-thread dispatch.** Under `task_always_eager`, the task body runs on the
  request thread, which under `TestClient` + an `async def` endpoint has a **running** event loop;
  bare `asyncio.run` there raises `RuntimeError` (verified empirically), the task's outer swallow eats
  it, the `PATCH` still returns 200, and **zero** bytes are POSTed — every endpoint-triggered delivery
  silently dead-on-arrival. `_run_in_fresh_loop` runs the coroutine on a child thread with its own
  loop, correct in both eager and prod. The trigger-path tests assert a **real POST** (counter == 1),
  so a regression fails the suite.
- **Worker never registers the task (prod-only `NotRegistered`) — mitigated by import-driven
  registration.** `autodiscover_tasks(["app.tasks"])` looks for `app.tasks.tasks`, not
  `app.tasks.webhook`, so the real worker would not register `focal.deliver_webhooks`. Masked in tests
  by the router/test explicit imports. `app/tasks/__init__.py`'s `from app.tasks import webhook` fixes
  it; the registration acceptance imports only the package.
- **Happy-path delivery tests pass vacuously if the SSRF gate is not stubbed — mitigated by the
  getaddrinfo public-IP stub on every delivery test.** `_deliver_to_agent` calls the real
  `socket.getaddrinfo` before the POST; an un-stubbed host NXDOMAINs (gate → `None`, no POST) and the
  `MockTransport` is never hit, so every "fail_count unchanged" case would pass for the wrong reason.
  Every delivery test patches `app.domain.webhook.socket.getaddrinfo` to a public IP; the SSRF-gate
  test patches it to a private one and asserts zero POSTs.
- **Signature byte-instability (no error surface) — mitigated by reuse.** If the POST sent
  `json=payload`, httpx would re-encode the dict and break the agent's `X-Focal-Signature` with no
  error in Focal. 3b POSTs `content=body` (the exact `serialize_payload` bytes 3a signs), pinned by the
  recompute-from-captured-body test.
- **Double-delivery on repeat-complete — mitigated by the first-flip contract.** Firing on the
  conflated `bool` would double-deliver on every repeat `PATCH …/complete`. The
  `(exists, newly_completed)` return + the `if newly_completed` guard match legacy's "fire only when the
  `WHERE … completed=false` update matched". The router rewrite (unpack the tuple, branch on `exists`)
  is the single highest-risk mechanical edit — a leftover truthiness test would never 404; pinned by the
  trigger-once test plus the unchanged `test_complete_missing_is_404` / cross-tenant cases.
- **`task_postrun` global clear wiping the request's FULL contextvars (the 3a-named footgun, now
  realized) — mitigated by a full-dict snapshot/restore.** Under eager the in-request enqueue runs
  `task_postrun` on the request thread (verified, even with the fresh-thread delivery dispatch); 3a's
  `_clear` would strip `correlation_id`, `path`, AND `method`. A correlation_id-only restore (the
  draft's approach) silently drops `path`/`method`. `_preserve_contextvars` snapshots and restores the
  whole dict; pinned by the full-set contextvars test (fails if removed or narrowed). 3a's handler is
  left correct for the real prefork-worker case.
- **TOCTOU between the SSRF gate and the socket connect (accepted, documented).** The gate's
  `getaddrinfo` and httpx's connect-time `getaddrinfo` are two independent resolutions, so a rebinding
  resolver returning public-then-private on consecutive lookups can defeat the gate even within a single
  attempt. This slice does **not** add a custom IP-pinned transport (3a deferred it; simplicity-first,
  no consumer evidence); the residual window is named, not built. `follow_redirects=False` still blocks
  the 3xx redirect-to-internal vector, and the gate blocks the direct private-resolving case — a net
  improvement over legacy (which had no connect-time gate). Worth a line in the PR description.
- **Auto-disable as denial-of-delivery if transient failures counted — mitigated by the action map.**
  Only `INCREMENT`/`DISABLE` touch `fail_count`; `RETRY`/`GIVE_UP` (3xx/5xx/network/timeout) write
  nothing, so a flaky endpoint never auto-disables. Pinned by the 5xx- and timeout-exhaust tests
  (seeding a non-zero `fail_count`) asserting it is unchanged.
- **Concurrent double-`DISABLE` (rare, accepted).** Two parallel events both reading `fail_count = 2`
  both increment to 3 and both run the disable write. The atomic SQL increment keeps the counter
  correct, and `DISABLE` is idempotent (nulling already-null columns + unconditional
  `SET webhook_fail_count = 0`), so the extra write is wasteful but harmless and cannot leave
  `fail_count > 0` with `webhook_url` still set — matching legacy's lock-free `sql\`webhook_fail_count +
  1\``. `SELECT … FOR UPDATE` is out of scope.
- **Eager `task_eager_propagates=True` makes the call-site enqueue swallow load-bearing.** Any
  exception escaping the task body re-raises out of `.delay()` into `complete_task`; the
  `try/except Exception` around the enqueue (nested inside `_preserve_contextvars`) keeps the 200 and
  ensures the rebind runs. The never-raises test injects the failure **above the per-agent gather**
  (`_make_client`/`_task_sessionmaker` itself raising) so it exercises the task's outer swallow, not the
  gather's `return_exceptions` collection or the `asyncio`/dispatch path.
- **Retry-loop wall-clock in tests.** The linear backoff sleeps up to 1s+2s per failing agent; tests
  patch `asyncio.sleep` (or `WEBHOOK_RETRY_DELAY_S`) to no-op. Production keeps the real backoff.
- **NullPool sessionmaker for the worker's fresh loops (session-nullpool).** The task uses its own
  `_task_sessionmaker()` (NullPool on `get_settings().database_url`), **not** the app's pooled engine,
  because each delivery runs on a fresh per-invocation event loop and a pooled connection bound to a
  closed loop crashes the next invocation (verified). Tests run this **real** path with no
  task-sessionmaker patch (a patch would mask the prod bug); the audit passes
  `sessionmaker=_task_sessionmaker()` to `log_agent_event`. The conftest autouse fixture still patches
  `app.agent_logging.get_sessionmaker` for the request-path `log_agent_event` calls.
- **No migration / no schema change** (`webhook_*` columns on head `acb242a1f541`); **no new
  dependency** (httpx, celery, redis already pinned). Rollback = revert the new files + the small edits
  to `celery_app.py`/`agent_data.py` (service + router)/`agent_logging.py`; no data to undo.

# Scope check

- [x] Matches the task: the delivery task + fan-out, the SSRF-gated signed POST, the
      `decide_delivery_outcome`-driven retry loop, the action→DB-write map, the first-flip
      `task.completed` trigger, the contextvars fix, the import-driven registration + the `autodiscover`
      line, and the three `WEBHOOK_*` levels — all consuming 3a. The other triggers/sanitizers,
      Flower/Beat, the worker deploy, the IP-pinned transport, and a result backend are out of scope.
- [x] Reviewable in one pass — one new task module + one package init + four small edits (1-line
      `celery_app`, a 2-return `complete_task`, the router unpack + trigger block, three log-level rows)
      + one DB test file. The pure decision/serialization/SSRF core is already proven in 3a; 3b is thin
      mockable orchestration over it.
- [x] Size smell: moderate, cohesive — the task body, fan-out, and trigger are one feature sharing the
      one `make verify` surface; the only cross-file ripple is the minimal `complete_task` signature
      change (+ the forced router unpack), justified and flagged. No speculative surface.

# Out of scope

The other event triggers + their field-subset sanitizers (`task.created`/`task.updated` →
`sanitize_task_for_webhook`, `task.deleted` → `{id}`, `calendar_event.*` →
`sanitize_event_for_webhook`) — they fire from the regular `routes.ts` CRUD surfaces, a later cut.
Flower, Celery Beat, the Railway worker-service/Dockerfile and worker entrypoint deploy wiring. An
IP-pinned custom httpx transport and TOCTOU hardening beyond the single `resolve_and_check_host` gate.
Application-layer encryption of `webhook_secret`. A result backend / task-result polling
(`task_ignore_result=True` stays). `SELECT … FOR UPDATE` locking around the fail-count
read-decide-write (the atomic increment + idempotent disable suffice, per legacy). No new migration;
no new dependency.

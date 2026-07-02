# Goal

Build the **webhook-delivery task + trigger** (Phase 8, webhook slice 3b — the second of the two
delivery cuts), the impure orchestration that **consumes** the just-merged slice-3a foundation
(`app/celery_app.py`, `app/celery_signals.py`, the pure `app/domain/webhook.py`). This is the first
real Celery task in the monorepo: the async HTTP delivery worker plus the legacy `notifyAgent`
fan-out, fired by the single `task.completed` trigger wired into `complete_task`. The task POSTs the
canonical signed bytes 3a produces, drives the 3a `decide_delivery_outcome` decision tree across the
retry loop, maps each `DeliveryAction` to its DB side effect (2xx reset / 4xx increment-or-disable /
transient no-op), and audits each outcome — all best-effort, **never raising into `complete_task`**
(legacy `notifyAgent` never throws into the caller). Legacy source of truth:
`focal/server/ai-agent-webhook.ts` (`notifyAgent` fan-out + `fireWebhook` retry/decision/DB tree) and
`focal/server/ai-agent.ts:832-862` (the `task.completed` trigger fired **only** on the first
idempotent flip — the legacy comment is explicit: the `completed = false` guard ensures a repeat call
"не перезапишет completedAt **и не вышлет дублирующий webhook**" — with payload `{ id: taskId }`).

# Scope

- **`app/tasks/__init__.py`** (new) — the package 3a deliberately deferred. It **must** import the
  task module so registration is import-driven, not autodiscover-dependent: a one-line docstring plus
  `from app.tasks import webhook` (re-exported, `# noqa: F401`). (See Decisions: autodiscover — the
  default `autodiscover_tasks(["app.tasks"])` looks for `app.tasks.tasks`, which does not exist, so
  the package init is what actually guarantees `focal.deliver_webhooks` registers in the real worker.)
- **`app/tasks/webhook.py`** (new) — the delivery task + fan-out, consuming 3a end-to-end:
  - `@celery_app.task(name="focal.deliver_webhooks") def deliver_webhooks(user_id: str, event: str,
    data: dict[str, Any]) -> None` — the **sync** Celery entrypoint. Args are **JSON primitives only**
    (`str`/`str`/`dict`) — never an ORM `Task`/`AiAgentToken` (3a's `EncodeError` test pins this). The
    body runs the async delivery via **a fresh OS thread that owns its own event loop**
    (`_run_in_fresh_loop(_deliver_all(...))` — see Decisions: asyncio-in-celery) and **swallows every
    exception** at its outermost edge (`try/except Exception` → best-effort `structlog` error, no
    re-raise) so a delivery failure never propagates into the enqueuing request.
  - `def _run_in_fresh_loop(coro) -> None` — spawns a `threading.Thread` whose target is
    `asyncio.run(coro)`, then `join()`s it; an exception raised inside the coroutine is captured and
    re-raised on the calling thread (so the task's own outer swallow still sees it). This dispatch is
    **uniform** across both call paths: under eager the task body runs on the request thread (which
    already has a running loop — `asyncio.run` there would raise `RuntimeError`), and in production it
    runs in a prefork worker (no loop); the fresh thread always starts a clean loop. (See Decisions:
    asyncio-in-celery — verified empirically: `asyncio.run` from inside an async FastAPI endpoint under
    `TestClient` raises `asyncio.run() cannot be called from a running event loop`.)
  - `async def _deliver_all(user_id, event, data, *, client=None) -> None` — the `notifyAgent` fan-out
    (`ai-agent-webhook.ts:104-134`): build the envelope **once**
    (`build_webhook_payload(event, data, user_id, now=_now())` → `serialize_payload(...)` → the body
    bytes), where `_now() -> datetime` is a one-line module seam (`return datetime.now(UTC)`) so the
    signed-body test can freeze the timestamp by patching `app.tasks.webhook._now` (the full-body
    equality assertion needs a deterministic `now`). Then open the httpx client (a real
    `httpx.AsyncClient` when
    `client is None`, else the injected one — see Decisions: client-seam), `SELECT` the user's agents
    `WHERE webhook_url IS NOT NULL`, and `asyncio.gather(*[_deliver_to_agent(...)],
    return_exceptions=True)` so one agent's failure does not block the others. Returns early (no error)
    when the user has no webhook-enabled agents. The agent rows are read into **plain frozen
    dataclasses** (`id, name, webhook_url, webhook_secret, webhook_fail_count`) inside the session, so
    no ORM object is touched outside the session and each per-agent DB write opens its **own** short
    session.
  - `async def _deliver_to_agent(agent, body, client) -> None` — the `fireWebhook` port
    (`ai-agent-webhook.ts:136-219`):
    - **Pre-connect SSRF gate (runs before the attempt loop, once per agent):** parse the agent's
      `webhook_url`; call `resolve_and_check_host(host, port=parsed.port or 443)`. If it returns
      `None` → do **not** POST; log `WEBHOOK_FAILED` with `details={"reason": "blocked_host"}` and
      return (no `fail_count` mutation — a blocked host is not an agent-side 4xx). The gate is the
      **entire** SSRF defense at delivery time: `follow_redirects=False` only stops chasing a 3xx, it
      does not stop the initial connect, so the `None` result **must** `return` before any
      `client.post`. (See Decisions: pre-connect-gate.)
    - **Signature:** `signature = sign_payload(secret, body) if agent.webhook_secret else None`;
      `headers = build_webhook_headers(agent.name, uuid4().hex, signature)`. A fresh `delivery_id` per
      agent (legacy `randomUUID()` per `fireWebhook`).
    - **Attempt loop** `for attempt in range(WEBHOOK_MAX_RETRIES + 1)` (3 attempts):
      `await asyncio.sleep(WEBHOOK_RETRY_DELAY_S * attempt)` before attempts 2+ (linear 0/1s/2s, legacy
      `ai-agent-webhook.ts:155-157`); POST `client.post(webhook_url, content=body, headers=headers,
      timeout=WEBHOOK_TIMEOUT_S, follow_redirects=False)`; on `httpx.HTTPError` set `status = None`
      (timeout, connect, network — legacy's `AbortError`/`catch` both map to the transient path); else
      `status = response.status_code`.
    - **Decision:** `action = decide_delivery_outcome(status=status,
      is_last_attempt=(attempt == WEBHOOK_MAX_RETRIES), fail_count=agent.webhook_fail_count)`. Map:
      - `RESET` → if `agent.webhook_fail_count > 0`, `UPDATE … SET webhook_fail_count = 0`; audit
        `WEBHOOK_DELIVERED` (status code, delivery_id); **return** (done).
      - `INCREMENT` → atomic `UPDATE … SET webhook_fail_count = webhook_fail_count + 1`
        (`ai-agent-webhook.ts:202-205`); audit `WEBHOOK_FAILED`; **return** (4xx is not retried).
      - `DISABLE` → `UPDATE … SET webhook_url = NULL, webhook_secret = NULL, webhook_fail_count = 0`
        (`ai-agent-webhook.ts:193-196`); audit `WEBHOOK_DISABLED`; **return**.
      - `RETRY` → continue the loop (no DB write).
      - `GIVE_UP` → audit `WEBHOOK_FAILED` (last transient attempt exhausted); **return** (no DB
        write — the load-bearing transient-no-mutation contract from 3a).
    - All DB writes are **best-effort**: wrapped in `try/except SQLAlchemyError` with `rollback`, like
      `touch_token_last_used` (`services/agent_data.py:97-107`) — a write failure is logged and
      swallowed, never raised (legacy `db?.update(...).catch(() => {})`).
  - Session acquisition uses a **dedicated NullPool sessionmaker** `_task_sessionmaker()` (lru-cached,
    `async_sessionmaker(create_async_engine(get_settings().database_url, poolclass=NullPool))`), **not**
    the app's pooled `get_sessionmaker()` — the worker runs each delivery on a fresh per-invocation
    event loop (the fresh-thread + `asyncio.run` dispatch), and a pooled asyncpg connection bound to
    one (now-closed) loop crashes the next invocation with `RuntimeError: Event loop is closed` (see
    Decisions: session-nullpool, verified empirically). NullPool opens a fresh connection per checkout,
    so it is loop-safe across the worker's per-invocation loops. The fan-out SELECT and every
    `webhook_fail_count` write go through `_task_sessionmaker()`; the durable audit goes through
    `log_agent_event(..., sessionmaker=_task_sessionmaker())` (the new optional param — below).
- **`app/celery_app.py`** (modify — one line) — add `celery_app.autodiscover_tasks(["app.tasks"])`
  after app creation. Real task registration is guaranteed by `app/tasks/__init__.py`'s explicit
  import (above); this line is belt-and-suspenders for any future `app.tasks.tasks` module and keeps
  the deferred-from-3a wiring present. `ping` and the signal-import line are unchanged. (See Decisions:
  autodiscover.)
- **`app/services/agent_data.py`** (modify — minimal) — change `complete_task` so the router can fire
  the trigger **only on the first flip**, not on a repeat-complete. The current return conflates
  "newly flipped" with "already-completed" (both → `True`). **Ruling:** return a 2-tuple
  `tuple[bool, bool]` of `(exists, newly_completed)` (see Decisions: first-flip). Body unchanged except
  the return statements: the flip path returns `(True, True)`; the fallback-`select` path returns
  `(existing is not None, False)`. No behavior change to the write itself.
- **`app/api/agent_data.py`** (modify — the trigger site) — in `complete_task`:
  `exists, newly_completed = await service.complete_task(principal.user_id, task_id)`; `if not exists:
  raise AgentApiError("Task not found", status_code=404)`; then **only if `newly_completed`**, enqueue
  the webhook **with contextvars scoped** (see Decisions: contextvars-scope):
  ```python
  if newly_completed:
      with _preserve_contextvars():
          try:
              deliver_webhooks.delay(principal.user_id, "task.completed", {"id": task_id})
          except Exception:  # noqa: BLE001
              log.error("webhook_enqueue_failed", task_id=task_id)
  return OkEnvelope()
  ```
  The enqueue is wrapped in `try/except Exception` **inside** the `with` (so the rebind in
  `__exit__` always runs, and a broker/serialization failure never breaks the 200 response — under the
  test fixture's `task_eager_propagates=True`, the call-site swallow is load-bearing, not mere defence;
  see Decisions: enqueue-best-effort). `OkEnvelope()` is returned unchanged.
- **A `_preserve_contextvars()` contextmanager** (in `app/api/agent_data.py`) — snapshots the
  **entire** bound structlog context (`dict(structlog.contextvars.get_contextvars())`) before the
  enqueue and **fully** rebinds it after (`clear_contextvars()` then `bind_contextvars(**snapshot)`),
  so that under eager (and any in-request enqueue) the `task_postrun` global `clear_contextvars()`
  (3a `celery_signals.py:31-33`) does not wipe the **request's** correlation_id **— nor its `path` and
  `method`** — mid-request. (The request middleware binds all three: `middleware.py:18-22`. A
  correlation_id-only restore would silently drop `path`/`method` from every later log line — see
  Decisions: contextvars-scope. Verified: `task_postrun` fires on the request thread even after the
  fresh-thread dispatch, so this wrap is still required.)
- **`app/agent_logging.py`** (modify) — (a) extend `AGENT_EVENT_LEVELS` with
  `WEBHOOK_DELIVERED: "info"`, `WEBHOOK_FAILED: "warn"`, `WEBHOOK_DISABLED: "warn"` (mirrors the
  existing `WEBHOOK_UPDATED` style; the module comment already says "webhook events land with their own
  slices"); (b) add an **optional** `sessionmaker: async_sessionmaker[AsyncSession] | None = None`
  parameter — `sm = sessionmaker or get_sessionmaker()` — so the worker can pass its loop-safe NullPool
  sessionmaker. Default `None` preserves every existing request-path caller unchanged (they keep using
  the pooled `get_sessionmaker()`); only the delivery task passes `sessionmaker=_task_sessionmaker()`,
  because `log_agent_event`'s durable write would otherwise hit the same pooled-engine cross-loop crash
  in the worker (see Decisions: session-nullpool). `log_agent_event` stays best-effort / never-raises.
- **Tests:**
  - **`tests/test_webhook_delivery_db.py`** (new, DB-backed, `httpx.MockTransport`) — seeds tokens with
    real `webhook_url`/`webhook_secret`/`webhook_fail_count` and drives the task through every
    `DeliveryAction` branch, the fan-out, the trigger, the SSRF gate, and the contextvars fix. Every
    assertion seeds a **non-vacuous** precondition (see Acceptance). **Every delivery test monkeypatches
    `app.domain.webhook.socket.getaddrinfo`** so the pre-connect gate resolves to a public IP and the
    `MockTransport` is actually exercised (see Decisions: getaddrinfo-stub — without this the gate
    skips delivery on a real DNS lookup and the whole matrix passes vacuously). Patches `asyncio.sleep`
    (or `WEBHOOK_RETRY_DELAY_S`) so the retry tests do not block ~3 s of real time. **No** patch of the
    task's sessionmaker: `_task_sessionmaker()` is already NullPool on the test DB's `DATABASE_URL`, so
    the task's writes + audit land in the test DB on the **real** prod path (see Decisions:
    session-nullpool).
  - The trigger-fires-once coverage lives in this same file (the new module owns the trigger), driven
    through `TestClient` `PATCH …/complete` with the eager fixture: it asserts a **real POST** happened
    (the `MockTransport` request counter), not merely a 200, so the `asyncio`-dispatch fix is pinned.
    `tests/test_agent_tasks_db.py` is **not** modified (its `test_complete_*` cases assert HTTP status
    only, so the `(exists, newly_completed)` change needs no edit there).

# Decisions (design rulings to confirm at Gate 1)

- **(asyncio-in-celery) The sync task body runs the async delivery on a FRESH OS THREAD that owns its
  own event loop — NOT `asyncio.run` directly, and NOT a reused loop.** *(Corrected from the draft,
  which ruled `asyncio.run(...)` directly — that is wrong and was verified to crash.)* Under
  `task_always_eager` the task body runs **inside the request thread**, and FastAPI dispatches an
  `async def` endpoint directly on the portal thread's **running** event loop (Starlette `TestClient`
  drives the ASGI app via a blocking portal). Empirically, `asyncio.run(...)` called from inside an
  async endpoint under `TestClient` raises `RuntimeError: asyncio.run() cannot be called from a running
  event loop` — so the draft's pattern would silently kill **every** endpoint-triggered delivery (the
  task's outer swallow eats the `RuntimeError`, the `PATCH` still returns 200, but **zero** bytes are
  POSTed). **Ruling:** `def deliver_webhooks(...): try: _run_in_fresh_loop(_deliver_all(...)) except
  Exception: log.error(...)`, where `_run_in_fresh_loop` spawns a `threading.Thread` running
  `asyncio.run(coro)` and joins it (capturing+re-raising the coroutine's exception so the outer swallow
  still sees it). The fresh thread always starts a clean loop, so this is uniform and correct in **both**
  the eager-endpoint path (request thread has a running loop) and production (prefork worker, no loop).
  The direct `_deliver_all` unit tests call it via the suite's `_run`/`asyncio.run` from the test
  thread (no loop) — unaffected. **The endpoint-trigger acceptance tests MUST assert a real POST
  (request-counter == 1), not just a 200, so a regression back to bare `asyncio.run` fails the suite.**
  **Flagged for the reviewer.**
- **(autodiscover) Task registration is guaranteed by an explicit import in `app/tasks/__init__.py`,
  NOT by `autodiscover_tasks` alone.** *(Corrected from the draft, which relied on
  `autodiscover_tasks(["app.tasks"])`.)* Celery's `autodiscover_tasks(packages, related_name='tasks')`
  searches each package for a submodule literally named `tasks` — i.e. it imports `app.tasks.tasks`,
  which does **not** exist (the module is `app.tasks.webhook`). So autodiscover alone never imports
  `webhook.py`, and the real worker (`celery -A app.celery_app worker`) would not register
  `focal.deliver_webhooks` → a real broker dispatch raises `NotRegistered`. This is **masked** in tests
  because (a) autodiscover is lazy/worker-bootstrap-only (it never fires in pytest/the FastAPI process)
  and (b) the router and test file both `from app.tasks.webhook import deliver_webhooks`, whose
  `@celery_app.task` decorator registers on import — so `"focal.deliver_webhooks" in celery_app.tasks`
  is true for the wrong reason. **Ruling:** `app/tasks/__init__.py` does `from app.tasks import webhook
  # noqa: F401` so registration is import-driven and worker-safe; `autodiscover_tasks(["app.tasks"])`
  stays in `celery_app.py` as harmless belt-and-suspenders. The registration acceptance is checked in a
  way that does **not** depend on the test file's own explicit import (it imports only
  `app.celery_app`/`app.tasks` package, which triggers the init-driven registration, then asserts
  `"focal.deliver_webhooks" in celery_app.tasks`). **Flagged for the reviewer.**
- **(getaddrinfo-stub) Every delivery test MUST monkeypatch `app.domain.webhook.socket.getaddrinfo`
  to return a public IP, or the pre-connect gate silently skips the POST.** `_deliver_to_agent` calls
  `resolve_and_check_host(host, port=...)` → the real module-level `socket.getaddrinfo`
  (`app/domain/webhook.py:143`) **before** touching the httpx client. Under `make verify` a seeded
  `example`/non-existent host either NXDOMAINs (gate → `None`, delivery skipped, `MockTransport` never
  hit) or resolves to something unexpected — so a happy-path test would either go RED for the wrong
  reason or, worse, every "fail_count unchanged" case would pass **vacuously** (blocked-host skip, not
  transient give-up). **Ruling:** the test file provides a helper that monkeypatches
  `app.domain.webhook.socket.getaddrinfo` to return a single public address (e.g. `93.184.216.34`,
  documentation-range); every delivery test applies it so the gate passes and the transport is
  exercised. The dedicated SSRF-gate test instead patches it to a **private** address (`10.0.0.5`) and
  asserts **zero** POSTs. Patch target is the `app.domain.webhook.socket` binding (where the gate looks
  it up), never `app.tasks.webhook`'s namespace. **Flagged for the reviewer** as the load-bearing
  non-vacuity guard for the entire delivery matrix.
- **(client-seam) The httpx client is injected through a single seam: `_deliver_all(..., *,
  client=None)` defaults to a real `httpx.AsyncClient`, and the test passes a
  `MockTransport`-backed client.** *(One seam, not the draft's "either a `_make_client()` monkeypatch
  OR a defaulted param".)* `_deliver_all` opens the client when `client is None` and otherwise uses the
  injected one; `deliver_webhooks` (the sync entrypoint) never threads a client (it always builds a
  real one via `_deliver_all(...)`). Tests exercise the task by calling `_deliver_all(...)` directly
  via `_run` with `client=` a `httpx.AsyncClient(transport=httpx.MockTransport(handler))` for the
  branch matrix, and by driving the **endpoint** (`PATCH …/complete`, eager) for the trigger/contextvars
  cases — for those, the client is injected by monkeypatching the module-level default factory the task
  uses so the in-request `deliver_webhooks` also gets the mock transport (a single
  `app.tasks.webhook._make_client` factory the task calls; the test patches it to return the
  MockTransport client). **Ruling:** one factory seam `_make_client() -> httpx.AsyncClient` that
  `_deliver_all` calls when `client is None`; tests either pass `client=` directly (branch tests) or
  patch `_make_client` (endpoint/trigger tests). The "never raises into `complete_task`" test injects
  the failure **above the per-agent gather** — a `_make_client` (or `_task_sessionmaker`) that **itself
  raises** `RuntimeError`, so `_deliver_all` raises **before** the `asyncio.gather(...,
  return_exceptions=True)` and the exception propagates through `asyncio.run` → `_run_in_fresh_loop` →
  the task's **outer** `except Exception`. (A failure raised *inside* `_deliver_to_agent` would instead
  be collected by `gather(return_exceptions=True)` and never reach the outer swallow — that path is
  covered by the separate fan-out-isolation test, where one agent's failure doesn't block the others.)
  **Flagged for the reviewer.**
- **(session-nullpool) The delivery task owns a dedicated NullPool sessionmaker; it must NOT use the
  app's pooled `get_sessionmaker()`, and tests must NOT paper over this with a monkeypatch.** The task
  runs each delivery on a **fresh per-invocation event loop** (the fresh-thread + `asyncio.run`
  dispatch). A pooled asyncpg connection binds to the loop that created it; the next invocation's fresh
  loop reuses the (now-closed) connection and crashes — **verified empirically**: two sequential
  `asyncio.run`s reusing one lru-cached pooled engine raise `RuntimeError: Event loop is closed` on the
  second, while a NullPool engine succeeds. So the app's request-path pool (loop-stable, one persistent
  loop) is **wrong** for the worker. **Ruling:** `app/tasks/webhook.py` builds its own lru-cached
  `_task_sessionmaker()` = `async_sessionmaker(create_async_engine(get_settings().database_url,
  poolclass=NullPool), expire_on_commit=False)` and uses it for the fan-out SELECT and every
  `webhook_fail_count` write; the audit goes through `log_agent_event(..., sessionmaker=
  _task_sessionmaker())` (the new optional param) so the durable log row is also loop-safe in the
  worker. Because `_task_sessionmaker()` is NullPool on `get_settings().database_url` (= the test DB's
  `DATABASE_URL` under `make verify`), **the tests exercise the REAL prod code path with no
  task-specific monkeypatch** — a key correctness point: a test that patched the task's sessionmaker to
  NullPool would be testing different behavior than prod runs, masking exactly this bug. (The autouse
  `_agent_logging_test_engine` conftest patch still covers the **request-path** `log_agent_event` calls,
  which pass no `sessionmaker`.) **Flagged for the reviewer** as the correction of the draft's
  pooled-`get_sessionmaker`-plus-test-patch approach, which would crash the deployed worker on the
  second delivery.
- **(first-flip) `complete_task` returns `(exists, newly_completed)`; the trigger fires only when
  `newly_completed`.** Legacy fires `notifyAgent(userId, "task.completed", { id: taskId })` **only**
  after the `WHERE … completed = false` update matched (`ai-agent.ts:843-862`): the legacy comment is
  explicit that the idempotency guard prevents a duplicate webhook, and a repeat-complete falls into the
  `if (!updated)` branch and returns `{ ok: true }` **without** a webhook. The current Python
  `complete_task` returns a single `bool` that is `True` for **both** the fresh flip **and** the
  already-completed fallback (`services/agent_data.py:58-74`) — firing on every `True` would
  double-deliver on a repeat call. **Ruling:** change the return to `tuple[bool, bool]`
  `(exists, newly_completed)`. The router unpacks it, maps `not exists → 404`, fires the trigger iff
  `newly_completed`, and returns `OkEnvelope()` otherwise unchanged. **Note the mechanical risk:** the
  current router does `if not await service.complete_task(...)`; a 2-tuple is **always truthy**, so the
  router MUST be rewritten to `exists, newly_completed = ...` and branch on `exists` — leaving the old
  truthiness test would make a missing task never 404. This is the **minimal** service change (the write
  is untouched; only the two `return` statements change). **Flagged for the reviewer** as the one
  cross-file service-signature change 3b requires. *(Alternative considered: return `completed_at |
  None` tri-state — rejected as a wider signature change; the bool-pair is the smallest faithful port of
  the legacy's "did the update match" branch.)*
- **(contextvars-scope) The in-request enqueue is wrapped so `task_postrun`'s global
  `clear_contextvars()` does not wipe the request's FULL contextvars (`correlation_id` + `path` +
  `method`).** *(Corrected from the draft, which restored only `correlation_id`.)* 3a's `_clear`
  handler (`celery_signals.py:31-33`) clears **all** contextvars on `task_postrun`; verified that under
  eager `task_postrun` fires **on the request thread** (in the `finally` of the eager `apply()`),
  **even with** the fresh-thread delivery dispatch (the async body runs on the child thread, but the
  signal fires on the parent). The request middleware binds **three** contextvars
  (`middleware.py:18-22`), so a `correlation_id`-only snapshot/restore permanently loses `path` and
  `method` for every log line emitted after the enqueue (response-side logging, the access log). **Ruling:**
  `_preserve_contextvars()` snapshots `dict(structlog.contextvars.get_contextvars())` before the
  enqueue and restores the **whole** dict after (`clear_contextvars()` + `bind_contextvars(**snapshot)`)
  — scoped to the **one** in-request enqueue site (not a change to 3a's handler, which is correct for
  the real prefork-worker case). The fix is **non-vacuously tested**: after a real `complete_task`
  request under eager, the request's `correlation_id` **and** `path`/`method` are asserted still bound
  (a test that fails if the wrap is removed or narrowed to one key). **Flagged for the reviewer.**
- **(pre-connect-gate) `resolve_and_check_host` is used as a pre-connect SSRF gate, then connect by
  hostname with `follow_redirects=False` — the named TOCTOU residual is accepted, not hardened.** 3a's
  Decisions (resolve-returns-tuple) explicitly scope full IP-pinned-custom-transport hardening to
  "3b/out-of-scope, residual named". **Ruling:** call `resolve_and_check_host(host, port=...)` as a
  reject-if-`None` gate **before** the attempt loop (once per agent — the URL is fixed per agent); on a
  non-`None` result, connect to the **original hostname** with standard TLS verification and
  `follow_redirects=False` (so httpx returns a 3xx rather than chasing it — legacy `redirect:"error"`
  parity). The IP returned by the gate is **not** used to rewrite the connection this slice (no custom
  transport); the returned `validated_ip` is intentionally discarded at this call site. The documented
  TOCTOU window — the gate's `getaddrinfo` and httpx's connect-time `getaddrinfo` are two independent
  lookups, so a rebinding resolver can defeat the gate within a single attempt — is named in Risks. This
  is a net SSRF **improvement** over legacy (which had no connect-time gate at all, only
  `redirect:"error"`), not a regression. A blocked/`None` host maps to a logged `WEBHOOK_FAILED` with
  `details={"reason": "blocked_host"}` (a distinct, alertable signal) and **no** `fail_count` mutation —
  it is not an agent-side 4xx. **Flagged for the reviewer** as the deliberate divergence from full
  IP-pinning (faithful to legacy, simplicity-first, no consumer evidence for a custom transport).
- **(content-not-json) The POST sends `content=body` (the exact `serialize_payload` bytes), NEVER
  `json=payload`.** This is the 3a acceptance row that lands on 3b: re-encoding the dict via httpx's
  `json=` would change separators/escaping and silently break the agent's `X-Focal-Signature` check
  (3a `serialize_payload` is the single canonical encoder). **Ruling:** `client.post(url,
  content=body, …)`; pinned by a test that recomputes the signature from the **captured POST body
  bytes** and asserts it equals the `X-Focal-Signature` header.
- **(transient-no-mutation, mapping) `RETRY`/`GIVE_UP` map to NO `fail_count` write; only
  `RESET`/`INCREMENT`/`DISABLE` touch the DB.** This is the 3b mapping contract 3a stated and pinned in
  its truth table. A flaky-but-transient endpoint (5xx/timeout/3xx) must **never** auto-disable (legacy
  touches `webhook_fail_count` only on 4xx). **Ruling:** the action→side-effect map has DB writes for
  exactly three actions; `RETRY` loops, `GIVE_UP` returns, neither writes. Pinned by a 5xx-exhausts and
  a timeout-exhausts test (each seeding a **non-zero** `fail_count`) asserting it is **unchanged**.
- **(disable-clears-both) `DISABLE` nulls `webhook_url` **and** `webhook_secret` and zeroes
  `webhook_fail_count`** (`ai-agent-webhook.ts:193-196`) — not just the URL. After disable the agent
  has no delivery target and no stale secret. Pinned by a test seeding `fail_count = 2`, sending a 4xx,
  and asserting all three columns are reset.
- **(fanout-isolation) `asyncio.gather(..., return_exceptions=True)` per agent; one agent's failure
  does not block the others.** Legacy `Promise.allSettled` (`ai-agent-webhook.ts:133`). **Ruling:** the
  fan-out gathers per-agent coroutines with `return_exceptions=True`; `_deliver_to_agent` additionally
  swallows its own DB/HTTP errors, so a gathered exception is a last-resort guard, not the primary
  path. Pinned by a two-agent test where agent A 4xx-increments and agent B 2xx-resets in the same
  fan-out, asserting both DB effects land.
- **(concurrent-disable, accepted) The INCREMENT-vs-DISABLE decision reads the stale `fail_count`
  snapshotted at fan-out time, so two parallel events both reading `fail_count = 2` both DISABLE.** The
  atomic SQL `webhook_fail_count = webhook_fail_count + 1` keeps the counter correct, and `DISABLE` is
  idempotent (nulling already-null columns + unconditional `SET webhook_fail_count = 0`), so the extra
  write is wasteful but harmless and cannot leave `fail_count > 0` with `webhook_url` still set. **Ruling:**
  accept it (matches legacy's lock-free `sql\`webhook_fail_count + 1\``); `SELECT … FOR UPDATE` is out
  of scope. Named in Risks.
- **(audit-no-secret) Audit events log `status`, `delivery_id`, `agent_name`, `user_id` — NEVER the
  `webhook_secret` or signature.** `log_agent_event(details=...)` carries only non-sensitive fields
  (the existing token tests forbid secret keys in output, `test_agent_tokens_db.py:_SECRET_KEYS`).
  **Ruling:** `details` is `{"delivery_id": ..., "status": ...}` (and `{"reason": "blocked_host"}` for
  the SSRF-gate case); no secret/signature ever in a log. Pinned by a test asserting no logged row's
  serialized form contains the seeded secret.
- **(enqueue-best-effort) The `.delay()` enqueue is wrapped in `try/except Exception` INSIDE the
  contextvars `with`, so a broker/serialization failure never breaks the 200 AND the rebind always
  runs.** The conftest fixture sets `task_eager_propagates = True`, so under eager any exception that
  escapes the task body re-raises out of `.delay()` into `complete_task`; the call-site swallow is
  therefore **load-bearing**, not mere defence-in-depth. **Ruling:** the enqueue is
  `with _preserve_contextvars(): try: deliver_webhooks.delay(...) except Exception: log.error(...)` —
  the `try` is nested inside the `with` so the contextmanager `__exit__` rebind runs even if `.delay()`
  raises. `complete_task` always returns `OkEnvelope()` after a successful flip. **Flagged for the
  reviewer.**
- **(no AppError in the task) The delivery task and fan-out raise NO `AppError`; they swallow
  best-effort.** The monorepo rule "typed `AppError`, never catch-and-swallow" applies to business
  request paths; this task is the deliberate fire-and-forget exception (3a's task Decisions named this:
  "3b's task swallows all delivery failures best-effort … the typed-`AppError` rule applies to 3b's
  edges"). The **only** typed-error surface 3b touches is the existing
  `AgentApiError("Task not found", 404)` in the router (unchanged). **Ruling:** the task's outer edge is
  `except Exception → log → return`; named so the reviewer does not read the broad catch as a rule
  violation. **Flagged for the reviewer.**
- **No migration.** `webhook_url`/`webhook_secret`/`webhook_fail_count` exist on head `acb242a1f541`;
  3b adds no columns. The `.ai` migration-in-slice rule does not fire.
- **`task.completed` event name + `{"id": task_id}` payload confirmed from legacy**
  (`ai-agent.ts:859`) — only the id, **not** a sanitized task. `sanitize_task_for_webhook` is **not**
  built here (3a's completed-payload Decision; it belongs to the `task.created`/`updated` CRUD surface,
  out of scope).

# Out of scope

- **The other event triggers + their field-subset sanitizers** — `task.created`/`task.updated`
  (`sanitize_task_for_webhook`, `ai-agent-webhook.ts:69-85`), `task.deleted` (`{id}`), and
  `calendar_event.*` (`sanitize_event_for_webhook`, `ai-agent-webhook.ts:47-63`). These fire from the
  regular task/calendar CRUD surfaces (`routes.ts`), not this agent-API `task.completed` path — a later
  cut.
- **Flower, Celery Beat, the Railway worker-service / Dockerfile-for-worker, and the worker
  entrypoint deploy wiring** — deploy-time, out of scope (the worker runs
  `celery -A app.celery_app worker`; documented, not wired into deploy here).
- **An IP-pinned custom httpx transport / TOCTOU hardening beyond the single `resolve_and_check_host`
  gate**, and **application-layer encryption of `webhook_secret`** — named in Risks, not built (3a
  deferred these).
- **A result backend / task-result polling** — fire-and-forget stays (3a's `task_ignore_result=True`,
  no backend). Nothing here reads a task result.
- **`SELECT … FOR UPDATE` row locking around the fail-count read-decide-write** — the atomic SQL
  increment + idempotent disable suffice; the rare double-`DISABLE` is accepted (Decisions:
  concurrent-disable), matching legacy's lock-free `sql\`webhook_fail_count + 1\``.

# Acceptance criteria

- [ ] `from app.tasks.webhook import deliver_webhooks` imports cleanly; `app/tasks/__init__.py` exists
      and imports `webhook` so importing the **package** (`import app.tasks`) registers the task;
      `app/celery_app.py` has `celery_app.autodiscover_tasks(["app.tasks"])`; and
      `"focal.deliver_webhooks" in celery_app.tasks` holds **after importing only
      `app.celery_app` + `app.tasks`** (the package init, not a direct `from app.tasks.webhook import`)
      — proving registration does not depend on the test file's own explicit import (pins the
      autodiscover/worker-registration fix).
- [ ] **Signed bytes are the wire bytes (non-vacuous):** a `MockTransport` captures the POST; the test
      recomputes `"sha256=" + hmac.new(secret.encode(), captured_body, sha256).hexdigest()` and asserts
      it **equals** the captured `X-Focal-Signature` header **and** that `captured_body ==
      serialize_payload(build_webhook_payload("task.completed", {"id": tid, "т": "значение"}, uid,
      now=frozen))` where the test **patches `app.tasks.webhook._now`** to `frozen` — proving
      `content=body` (not `json=`) and that the agent can
      verify. The Cyrillic field proves raw-UTF-8 transport survives the round-trip.
- [ ] **2xx resets a non-zero fail_count (non-vacuous):** seed `webhook_fail_count = 2`; deliver to a
      `MockTransport` returning `200`; assert the row's `webhook_fail_count == 0` and a
      `WEBHOOK_DELIVERED` log row exists with the delivery_id and status 200. (Seeding 2, not 0, makes
      the reset observable.)
- [ ] **Two sequential deliveries both write (the cross-loop / NullPool regression guard):** complete
      **two** different pending tasks in turn (each on the agent with a seeded `webhook_fail_count = 2`,
      `200` responses), and assert **both** deliveries reset the count to `0` (two `WEBHOOK_DELIVERED`
      rows). Because the tests run the **real** `_task_sessionmaker()` (no patch), this fails if the task
      is reverted to the app's pooled `get_sessionmaker()`: the second delivery runs on a fresh
      per-invocation event loop and the pooled connection from the first (now-closed) loop crashes
      (`RuntimeError: Event loop is closed`), so the second reset never lands. Pins the session-nullpool
      decision.
- [ ] **2xx with fail_count already 0 writes nothing (positively observable):** seed `0`, deliver
      `200`; assert `0`, a `WEBHOOK_DELIVERED` log row exists, **and** no `UPDATE` to
      `ai_agent_tokens` was issued — observed via a SQLAlchemy `before_execute`/`after_cursor_execute`
      event listener (or an execute-spy) on the task's engine asserting zero `UPDATE ai_agent_tokens`
      statements — so the `if fail_count > 0` guard is pinned (the test fails if the guard is removed).
- [ ] **4xx below threshold increments:** seed `fail_count = 0`; deliver `400`; assert `fail_count ==
      1`, **no** retry (a request-counting `MockTransport` sees exactly **1** POST), `WEBHOOK_FAILED`
      logged.
- [ ] **3 consecutive 4xx disables (post-increment boundary):** seed `fail_count = 2`; deliver `403`;
      assert `webhook_url IS NULL`, `webhook_secret IS NULL`, `webhook_fail_count == 0`, exactly **1**
      POST, and `WEBHOOK_DISABLED` logged. (Seeds 2 so `+1` reaches `WEBHOOK_DISABLE_AFTER = 3`.)
- [ ] **5xx retries then gives up, leaving fail_count untouched:** seed `fail_count = 1`; a
      `MockTransport` returning `503` on every call; with `asyncio.sleep` patched to no-op, assert
      exactly **3** POSTs (1 + 2 retries), `webhook_fail_count` **still 1** (no mutation),
      `webhook_url` still set, and `WEBHOOK_FAILED` logged once on give-up.
- [ ] **Network error / timeout retries then gives up, fail_count untouched:** seed `fail_count = 1`;
      a transport raising `httpx.ConnectError` (and a separate case `httpx.TimeoutException`) on every
      call; assert **3** POST attempts, `webhook_fail_count` still 1, `WEBHOOK_FAILED` logged. (Pins
      timeout/network → `status=None` → transient path, no auto-disable.)
- [ ] **3xx is not followed and does not disable:** seed `fail_count = 1`; a transport returning `302`
      with `Location: https://127.0.0.1/` on every call; assert the redirect is **not** followed (every
      captured request host is the original webhook host, never `127.0.0.1`), exactly **3** attempts
      (3xx is transient), `webhook_fail_count` **still 1**, and `WEBHOOK_FAILED` (not `WEBHOOK_DISABLED`)
      logged — proving 3xx never reaches the 4xx branch.
- [ ] **Pre-connect SSRF gate rejects a private-resolving host with NO POST:** monkeypatch
      `app.domain.webhook.socket.getaddrinfo` so the host resolves to `10.0.0.5`; deliver; assert the
      `MockTransport` recorded **zero** requests, `webhook_fail_count` **unchanged** (a blocked host is
      not a 4xx), and `WEBHOOK_FAILED` with `details == {"reason": "blocked_host"}` logged.
- [ ] **Unsigned delivery when the agent has no secret:** seed `webhook_secret = NULL`; deliver `200`;
      assert the captured request has **no** `X-Focal-Signature` header and the other 4 headers are
      present (`Content-Type`, `User-Agent: Focal-Webhook/1.0`, `X-Focal-Agent`, `X-Focal-Delivery`).
- [ ] **Fan-out isolation (non-vacuous):** seed **two** agents for the same user — agent A (`fail_count
      = 1`, transport → `400`) and agent B (`fail_count = 2`, transport → `200`) — plus a third agent
      with `webhook_url = NULL`; run one `_deliver_all`; assert A's `fail_count == 2` (incremented)
      **and** B's `fail_count == 0` (reset) — both effects land despite being in the same fan-out, and
      the third (no `webhook_url`) is never POSTed.
- [ ] **Trigger fires exactly once, on the first flip, with a REAL delivery (non-vacuous):** with the
      eager fixture and the mock transport injected at the in-request seam, a real
      `PATCH /api/ai-agent/v1/tasks/{id}/complete` on a seeded **pending** task delivers exactly **one**
      webhook (the `MockTransport` request counter == 1 — asserting an actual POST, not just a 200, so
      the asyncio-dispatch fix is pinned); a **second** `PATCH` on the now-completed task returns 200
      but delivers **zero** further webhooks; a `PATCH` on a missing/cross-tenant id returns 404 and
      delivers **zero**. (Pins the `(exists, newly_completed)` first-flip contract — fails if the
      trigger fires on the fallback branch or if delivery is dead-on-arrival.)
- [ ] **Contextvars survive the in-request enqueue, FULL set (non-vacuous):** during a real
      `complete_task` request under eager, a structlog line emitted by the route **after** the enqueue
      (captured via `structlog.testing.capture_logs`) carries `correlation_id` **and** `path` **and**
      `method` — a test that fails if `_preserve_contextvars` is removed **or** narrowed to only
      `correlation_id` (proving `task_postrun`'s global clear did not wipe the request trace and the
      full context is restored).
- [ ] **The task never raises into `complete_task` (failure above the gather):** with the in-request
      seam patching `_make_client` (or `_task_sessionmaker`) to **itself raise** an unexpected
      `RuntimeError` — so `_deliver_all` raises **before** the per-agent
      `asyncio.gather(return_exceptions=True)` — the `PATCH` still returns **200** and the task swallows
      the failure (asserted via a captured structlog error line from the task's **outer** `except
      Exception`, request unaffected) — legacy `notifyAgent` never throws into the caller. (A failure
      *inside* `_deliver_to_agent` would be collected by the gather, not the outer swallow; that path is
      the fan-out-isolation test. This test deliberately injects above the gather so the outer swallow —
      not the gather and not the `asyncio`/dispatch path — is what catches it.)
- [ ] **No secret in any log:** across the above, assert no `WEBHOOK_*` log row's serialized
      `details`/fields contain the seeded `webhook_secret` value.
- [ ] `AGENT_EVENT_LEVELS` includes `WEBHOOK_DELIVERED: "info"`, `WEBHOOK_FAILED: "warn"`,
      `WEBHOOK_DISABLED: "warn"`; `log_agent_event`'s new `sessionmaker` param defaults to `None` so
      every existing caller is unchanged (proven by the full existing suite staying green — the param
      is additive/backward-compatible).
- [ ] **No new dependency** (httpx, celery, redis already present); **no migration**; existing
      `test_agent_tasks_db.py` `test_complete_*` cases still green (untouched); `make verify` green.

# Verification commands

```sh
cd superapp/apps/focal/server && DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev make verify
```

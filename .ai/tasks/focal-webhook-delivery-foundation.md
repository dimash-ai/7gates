# Goal

Lay the **webhook-delivery foundation** (Phase 8, webhook slice 3a of the 3-part webhook feature, the
first of two delivery cuts): the **Celery infrastructure scaffold** plus the **pure delivery domain**
that the actual delivery task (slice 3b) will consume. This is the **first Celery surface in the whole
monorepo** (the stack mandates Celery for background jobs — "never in the app process"). Like slice
1's SSRF validator, the domain half ships **consumer-less this slice**: it is the exhaustively
unit-testable security/correctness core (canonical payload serialization, HMAC signing, the
connect-time DNS-rebinding SSRF re-check slice 1 explicitly deferred, and the response→action
decision as a pure function), each of which slice 3b's `task.completed` delivery consumes. No HTTP
POST, no DB writes, no event triggers, no fan-out — those are slice 3b. Legacy source of truth:
`focal/server/ai-agent-webhook.ts` (the `fireWebhook` constants, headers, HMAC, response decision
tree) and `focal/server/ai-agent.ts:859` (the `task.completed` event name **and** its `{ id: taskId }`
payload — see Decisions: completed-payload).

# Scope

- **`app/celery_app.py`** (new) — the shared Celery app, first in the monorepo:
  - `settings = get_settings()`; `celery_app = Celery("focal", broker=settings.redis_url)`; a
    module-level `CELERY_CONFIG: dict[str, Any] = {"task_serializer": "json", "accept_content":
    ["json"], "result_serializer": "json", "timezone": "UTC", "enable_utc": True, "task_ignore_result":
    True}` applied via `celery_app.conf.update(CELERY_CONFIG)`. `CELERY_CONFIG` is the **fixture-immune**
    view of the shipped config (it contains **no** `task_always_eager`) that the prod-safety test
    asserts against (see Acceptance / Decisions: eager). **No `backend=`** is configured (the result
    backend is omitted, not pointed at Redis — nothing reads results, and writing throwaway result
    keys into the shared Redis is unnecessary surface; see Decisions: no-result-backend).
  - **No `autodiscover_tasks` this slice.** The `app/tasks/` package does not exist yet; slice 3b
    creates it **and** adds the `autodiscover_tasks(["app.tasks"])` line when it adds the first real
    task. Shipping the autodiscover call now would be dead forward-wiring for a package with nothing
    to discover (the one task here, `ping`, registers via its decorator on `celery_app`, not via
    autodiscover). (See Decisions: no-autodiscover.)
  - **No `env`-gated eager block.** Eager mode is enabled **only** by the test conftest fixture (see
    Tests, Decisions: eager). The repo never sets `ENV=test` (the Makefile `verify` target exports
    only `DATABASE_URL`/`REDIS_URL`; `config.py` defaults `env="local"`), so an
    `if settings.env == "test":` branch would be **dead code that fires in no environment** — exactly
    the speculative, untraceable code the repo CLAUDE.md (Simplicity First / Surgical Changes) forbids.
    The single real eager mechanism is the conftest fixture, mirroring the existing
    `_agent_logging_test_engine` autouse-monkeypatch pattern.
  - One trivial verifiable task `@celery_app.task(name="focal.ping") def ping() -> str: return "pong"`
    — the smoke surface proving the app is importable, registered, and runs eagerly under the fixture.
  - `from app import celery_signals  # noqa: E402,F401` **after** app creation, so importing the app
    registers the signal handlers (no separate wiring).
- **`app/celery_signals.py`** (new) — `correlation_id` propagation request→task→worker (the stack
  requires correlation_id to propagate into Celery task headers). Three `celery.signals` handlers,
  **each written as a plain function so it is directly unit-testable** (the publish handler is **not**
  exercised by eager-mode `apply_async`; see Decisions: eager-untestable + Tests):
  - `before_task_publish` handler — read `correlation_id` from
    `structlog.contextvars.get_contextvars()` and, when present **and** the `headers` dict is not
    `None`, set `headers["correlation_id"] = cid`. No-op (no `KeyError`) when absent. This fires on a
    **real** broker publish (slice 3b's production enqueue path), **not** under `task_always_eager`.
  - `task_prerun` handler — read `correlation_id` from the running task's `request.headers` (default
    to `{}`) and, if present, `structlog.contextvars.bind_contextvars(correlation_id=...)` so every
    worker log line carries it.
  - `task_postrun` handler — `structlog.contextvars.clear_contextvars()` so a pooled prefork worker
    does not leak one task's correlation_id into the next. **Flagged for 3b:** under eager mode the
    task runs inside the request's contextvars stack, so this clear would wipe the *request's*
    correlation_id mid-request when 3b enqueues from inside `complete_task` — 3b's trigger wiring must
    scope/restore contextvars rather than rely on this global clear (named in Risks; nothing in 3a
    enqueues from a request).
  - Imported by `app/celery_app.py` so registering the app registers the signals.
- **`app/domain/webhook.py`** (modify — extend the slice-1 pure module; still **no** HTTP client,
  **no** DB, **no** Celery import):
  - Module constants (legacy `ai-agent-webhook.ts:31-40`): `WEBHOOK_TIMEOUT_S = 5.0`
    (legacy `WEBHOOK_TIMEOUT_MS=5_000`, expressed in seconds for httpx), `WEBHOOK_MAX_RETRIES = 2`,
    `WEBHOOK_RETRY_DELAY_S = 1.0` (linear: attempt 1 → 1 s, attempt 2 → 2 s),
    `WEBHOOK_DISABLE_AFTER = 3`.
  - `build_webhook_payload(event: str, data: dict, user_id: str, *, now: datetime) -> dict` — the
    legacy envelope `{"event": event, "data": data, "user_id": user_id, "timestamp": now.isoformat()}`
    (legacy `ai-agent-webhook.ts:125-130`). `now` is **injected** (caller passes `datetime.now(UTC)`)
    so the function is deterministic/unit-testable; the timestamp is generated at fire time, not
    task-completion time (see Decisions: timestamp).
  - `serialize_payload(payload: dict) -> bytes` — the **single** canonical JSON encoder used for both
    signing and the wire body, so the bytes the agent verifies are byte-identical to the bytes signed:
    `json.dumps(payload, separators=(",", ":"), ensure_ascii=False, sort_keys=True).encode("utf-8")`
    (see Decisions: signature-stability).
  - `sign_payload(secret: str, body: bytes) -> str` — `"sha256=" +
    hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()` (legacy `ai-agent-webhook.ts:150-151`).
  - `build_webhook_headers(agent_name: str, delivery_id: str, signature: str | None) -> dict[str, str]`
    — `Content-Type: application/json`, `User-Agent: Focal-Webhook/1.0`, `X-Focal-Agent: <name>`,
    `X-Focal-Delivery: <delivery_id>`, and `X-Focal-Signature: <signature>` **only when** signature is
    not `None` (legacy `ai-agent-webhook.ts:142-152`). `delivery_id` is injected (caller passes a
    fresh `uuid4().hex`) so the function stays pure/deterministic.
  - `resolve_and_check_host(host: str, *, port: int) -> tuple[str, str] | None` — the **connect-time**
    SSRF re-check slice 1 deferred (`webhook.py:15` "No DNS — connect-time checks at delivery").
    Returns **`(validated_ip, host)`** — both the resolved IP and the original hostname — so slice 3b
    can connect to the pinned IP **while preserving SNI/cert verification against the hostname** (all
    targets are HTTPS-only per `validate_webhook_url`; returning the bare IP would force 3b to either
    re-resolve, re-opening the rebinding window, or disable TLS verification — see Decisions:
    resolve-returns-tuple). Behavior:
    - `try: infos = socket.getaddrinfo(host, port, type=socket.SOCK_STREAM)` / `except
      _RESOLVE_ERRORS: return None` where `_RESOLVE_ERRORS = (OSError, UnicodeError)` — covers both
      `gaierror` (NXDOMAIN / resolution failure; a `socket.gaierror` is an `OSError`) **and**
      `UnicodeError` (IDNA encoding, e.g. a DNS label > 63 chars that `validate_webhook_url` still
      accepts — without this it would raise instead of returning `None`). Hoisted to a module constant
      like `_INET_ATON_ERRORS`.
    - **Scan every returned address before returning any** (dual-stack: A **and** AAAA) — track the
      first safe IP in a local, but do **not** early-return on it. For each address, parse `sockaddr[0]`
      via `ipaddress.ip_address(...)` **inside a `try/except ValueError`**; on a `ValueError` (a
      scoped/unverifiable form we cannot prove safe, e.g. some `fe80::1%eth0` representations) → return
      `None` (reject the whole host — never let the `ValueError` escape). If a parsed address is
      `_is_blocked_ip(ip)` → return `None` **immediately**. This any-blocked / any-unverifiable rejection
      is the DNS-rebinding defence: a host whose resolution set contains a blocked or unprovable address
      (e.g. public A **then** loopback AAAA) must be rejected, even if a safe address appeared first — so
      the scan cannot short-circuit on the first safe entry.
    - After the full scan with no rejection, return `(str(first_safe_ip), host)`; `None` if the set was
      empty.
    - Reuses the shipped `_is_blocked_ip` (no duplicated blocklist). It touches the resolver — the one
      unavoidable I/O — isolated here so 3b's task and the tests mock `socket.getaddrinfo`.
  - `DeliveryAction` (a `StrEnum`: `RESET`, `RETRY`, `INCREMENT`, `DISABLE`, `GIVE_UP`) and
    `decide_delivery_outcome(*, status: int | None, is_last_attempt: bool, fail_count: int) ->
    DeliveryAction` — the pure response decision tree (legacy `ai-agent-webhook.ts:174-218`):
    - `status` is 2xx (`200 <= status < 300`) → `RESET`.
    - `status` is **3xx** (`300 <= status < 400`) → `RETRY` if not `is_last_attempt`, else `GIVE_UP`
      (treated exactly like a network error, **never** the 4xx increment/disable branch, and **never**
      mutates `fail_count`; 3b sets `follow_redirects=False` so httpx returns the 3xx rather than
      chasing it). See Decisions: 3xx-transient.
    - `status` is 4xx (`400 <= status < 500`) → `DISABLE` if `fail_count + 1 >= WEBHOOK_DISABLE_AFTER`,
      else `INCREMENT` (legacy disables on the **post-increment** count, `ai-agent-webhook.ts:187-188`).
    - `status` is 5xx (`status >= 500`) → `RETRY` if not `is_last_attempt`, else `GIVE_UP`.
    - `status is None` (network error / timeout) → `RETRY` if not `is_last_attempt`, else `GIVE_UP`.
    - **Semantic contract (load-bearing for the abuse control):** only `INCREMENT`/`DISABLE` persist a
      `fail_count` change; `RESET` zeroes it; **`RETRY` and `GIVE_UP` must leave `fail_count`
      untouched.** This is the legacy invariant that a flaky 5xx/timeout endpoint is **not**
      auto-disabled (legacy never touches `webhook_fail_count` on 5xx/network, only on 4xx). The enum
      collapses two give-up causes (4xx-path side effects vs transient-path no-op), so this function
      owns **only the decision**; slice 3b owns mapping each action to its side effect, and must map
      `RETRY`/`GIVE_UP` to "do nothing to `fail_count`". Pinned by the truth-table test asserting the
      action **and** stated as the 3b contract.
- **`pyproject.toml` + `uv.lock`** (modify, via `uv add`) — `uv add 'celery[redis]'` (adds
  `celery[redis]>=5.4`, updating **both** files, both committed). `redis>=5.2` and `httpx>=0.28` are
  already present. **Flower and Beat are NOT added** — Flower is a deploy-time monitoring dashboard and
  Beat is for recurring schedules (this feature is event-triggered); both are out of scope (see Out of
  scope). `celery>=5.4` is the floor the monorepo stack pins, not a training default.
- **Tests:**
  - **`tests/test_webhook_delivery_domain.py`** (new, pure — no DB, no network, like
    `test_webhook_ssrf.py`): every domain function, with no vacuous assertions (see Acceptance).
  - **`tests/test_celery_app.py`** (new, DB-free): the `ping` task runs eagerly; the JSON-arg
    contract (a non-JSON `object()` arg raises `EncodeError` under eager); the json-only serialization
    config (`task_serializer`/`accept_content`) + broker URL read **dynamically** from
    `get_settings()`; the shipped-`CELERY_CONFIG` prod-safety check; and the three signal handlers
    **unit-tested as plain functions** (not via the eager `apply_async` pipeline, which does not fire
    `before_task_publish` — eager skips the broker publish, though it still serializes the args).

# Decisions (design rulings to confirm at Gate 1)

- **One combined slice (Celery scaffold + pure domain), not two micro-slices, and not folded into
  3b.** The domain half is the security/correctness core (signing, the SSRF re-check, the decision
  tree) and is exhaustively unit-testable in isolation — the exact shape the pipeline approved for
  slice 1 (a pure function shipped consumer-less, then consumed by a later slice). The Celery scaffold
  is too thin to review alone and shares the one `make verify` surface; pairing them gives 3a a real
  runnable smoke test (eager `ping` + the json-only config + directly-tested signal handlers) instead
  of unused-only code, and leaves 3b a thin, mockable orchestration over already-proven parts.
  **Flagged for the reviewer** as the headline scoping decision.
- **(eager-untestable) The correlation-id propagation is verified by unit-testing the signal handlers
  directly, NOT by an eager round-trip.** Under `task_always_eager` (the only mode the suite runs in),
  `apply_async` short-circuits to `Task.apply()` and **never publishes**, so `before_task_publish`
  **never fires** (the known, unresolved celery/celery#3864). A "bind correlation_id → `delay()` →
  assert the worker saw it" eager test would pass even if `_carry_cid` never wrote the header — it is
  vacuous. **Fix:** test each handler as a plain function — call the publish handler with a synthetic
  `headers={}` dict and assert it mutated it; call the prerun handler with a fake task whose
  `.request.headers` carries the id and assert `get_contextvars()` bound it; call the postrun handler
  and assert `clear_contextvars()` ran. The eager `ping` test proves the app is importable/registered/
  runnable and that args are JSON-clean — **not** that publish-time header injection works (that is the
  handler unit tests' job, and a true non-eager broker round-trip is a 3b/integration concern). **The
  earlier draft's "eager gives a real correlation-id-propagation surface" claim is retracted** and
  flagged for the reviewer.
- **(eager) Eager-in-tests is enabled ONLY by the conftest fixture; no `env`-gated block ships.** A
  `task_always_eager=True` reaching production would run every "background" job synchronously in the
  request handler, silently defeating the queue — a real trap. But the `if settings.env == "test":`
  guard the earlier draft proposed is **dead code**: nothing in the repo sets `ENV=test` (Makefile
  `verify` exports only `DATABASE_URL`/`REDIS_URL`; `config.py` default `env="local"`; no
  conftest/pyproject sets it), so that branch fires in **no** environment and the conftest fixture is
  the only thing that actually enables eager. Shipping both a never-firing gate and a fixture, then
  calling the gate a "prod-safety guard", is safety theater that asserts nothing. **Ruling:** delete
  the env gate; the **single** eager mechanism is an autouse conftest fixture (mirroring
  `_agent_logging_test_engine`) that sets `celery_app.conf.task_always_eager = True` /
  `task_eager_propagates = True` in setup and restores in teardown. Production safety comes from the
  **absence** of any eager-enabling code outside the test fixture — asserted **non-vacuously** by a
  test reading the shipped module-level `CELERY_CONFIG` dict (the source of `conf.update`) and proving
  `"task_always_eager" not in CELERY_CONFIG`. This is fixture-immune: the autouse fixture mutates the
  live `celery_app.conf` singleton, so by the time any test body runs the singleton is already eager —
  only the `CELERY_CONFIG` dict still reflects what the module ships (a throwaway `Celery("probe")`
  would prove Celery's defaults, not Focal's). **Flagged for the reviewer.**
- **(no-result-backend) Fire-and-forget: no result backend, `task_ignore_result=True`.** Legacy
  `notifyAgent` returns nothing and stores no result; neither 3a nor 3b reads a task result. Pointing
  `backend=` at the shared Railway Redis would write throwaway result keys into an instance already
  serving rate-limit/sessions/quotas (a capacity risk the plan itself flags) for zero consumers. The
  `ping.delay().get()` smoke test works in eager mode **without** a backend (eager stores the result
  in-process as an `EagerResult`). **Ruling:** omit `backend=`, set `task_ignore_result=True`; if a
  future slice needs results, it adds the backend then. **Flagged for the reviewer.**
- **(no-autodiscover) `autodiscover_tasks` is 3b's line, not 3a's.** `app/tasks/` does not exist this
  slice; `ping` registers via its decorator, not via autodiscover. Shipping
  `autodiscover_tasks(["app.tasks"])` now is forward-wiring for a slice that has no consumer and is
  unverifiable (it discovers nothing). **Ruling:** 3b adds both the `app/tasks/` package and the
  autodiscover call in the same slice. (Per surgical-changes / simplicity-first.)
- **(signature-stability) One canonical serializer for both signing and the wire — the byte-stability
  footgun.** `serialize_payload` is the single source of the payload bytes; slice 3b must sign **and**
  POST the exact bytes it returns (3b must use `httpx ... content=body`, **never** `json=payload`,
  which would let httpx re-encode the dict with different separators/escaping and break the agent's
  `X-Focal-Signature` check with **no error surfaced in Focal**). We pin
  `sort_keys=True, separators=(",", ":"), ensure_ascii=False` for a stable, compact, UTF-8
  deterministic encoding. **Divergence from legacy flagged:** legacy used `JSON.stringify` (insertion
  order, no sort, ASCII-escaped); a JS agent recomputing over the **raw body it receives** still
  verifies (it signs whatever bytes arrive), so cross-impl verification is preserved — but a
  Focal↔Focal re-sign is now order-independent and emits raw UTF-8 (realistic for RU-facing Cyrillic
  payloads). Pinned by a determinism test (incl. nested-dict reverse-key-order and a Cyrillic string)
  and an independent-recompute HMAC test over those exact bytes. The "3b sends `content=body`, not
  `json=`" rule is an **acceptance row on 3b** since 3a owns `serialize_payload`.
- **(resolve-returns-tuple) The connect-time SSRF re-check lands here and returns `(ip, hostname)`,
  fulfilling slice 1's deferral.** Slice 1 (`webhook.py:15`) explicitly deferred the resolved-IP check
  to delivery. All webhook targets are **HTTPS** (`validate_webhook_url` enforces `scheme == "https"`).
  To pin the connection to the validated IP **without re-resolving** (the whole point), 3b must connect
  to the IP while presenting the **original hostname** for TLS SNI + certificate verification.
  Returning a bare IP string discards the hostname and would push 3b toward re-resolution (re-opening
  the rebinding window) or `verify=False` (catastrophic). **Ruling:** `resolve_and_check_host` returns
  `tuple[str, str]` of `(validated_ip, hostname)`; the **3b connection contract** is *connect to the
  IP, set SNI/Host to the hostname, verify the cert against the hostname, `follow_redirects=False`*.
  It reuses the shipped `_is_blocked_ip` (no duplicated blocklist), iterates **dual-stack** results,
  rejects if **any** parseable address is blocked, and treats an unparseable scoped IPv6 as blocked.
  The residual TOCTOU (DNS may change between this check and 3b's socket connect) is named in Risks;
  full IP-pinned-custom-transport hardening is 3b/out-of-scope. The redirect-blocking second layer
  (`follow_redirects=False`) is 3b, but its **decision** is already encoded here (3xx → transient
  `RETRY`/`GIVE_UP`).
- **(3xx-transient) `decide_delivery_outcome` classifies 3xx as a transient `RETRY`/`GIVE_UP`,
  matching legacy parity — NOT an immediate hard-fail, and NOT the 4xx branch.** Legacy
  `fetch(redirect:"error")` *rejects the promise* on any 3xx, which falls into the `catch` block
  (`ai-agent-webhook.ts:212-217`) — the same path as a network error/timeout — and that path
  **retries until the last attempt, then returns, never touching `fail_count`**. So the faithful port
  treats a 3xx exactly like `status is None`: `RETRY` if not `is_last_attempt`, else `GIVE_UP`. The
  load-bearing invariant (both the legacy and the port agree) is that a 3xx must **not** fall into the
  `status < 500` 4xx increment/disable branch — an attacker's `Location: https://127.0.0.1` neither
  gets followed (3b's `follow_redirects=False` returns the 3xx) nor counts toward auto-disable.
  **Flagged for the reviewer** (the earlier draft wrongly classified 3xx as immediate `GIVE_UP` and
  mis-cited it as legacy parity; legacy retries). The truth table includes 3xx rows at both
  `is_last_attempt` values.
- **(transient-no-mutation) `RETRY`/`GIVE_UP` must not mutate `fail_count`.** The legacy auto-disable
  control increments/disables **only** on 4xx; 5xx/network/timeout retry and then give up **without
  touching** `webhook_fail_count`. If 3b ever treated `GIVE_UP` like `INCREMENT`, a flaky endpoint
  (transient 5xx/timeouts) would be auto-disabled after 3 transient failures — a denial-of-delivery
  legacy explicitly avoids. The decision function returns the action; the **"transient actions leave
  `fail_count` untouched" rule is a 3b mapping contract**, asserted in 3a by the truth table proving
  5xx/None/3xx → `RETRY`/`GIVE_UP` (never `INCREMENT`/`DISABLE`). **Flagged for the reviewer.**
- **(timestamp / delivery_id injected, not generated inside the pure functions.** Passing `now` and
  `delivery_id` keeps `build_webhook_payload`/`build_webhook_headers` deterministic and unit-testable
  without freezing the clock or patching `uuid4`. Legacy generated both at fire time
  (`new Date().toISOString()`, `randomUUID()`); slice 3b supplies `datetime.now(UTC)` and `uuid4().hex`
  at the same fire-time point — semantics preserved, testability gained.
- **(completed-payload) The `task.completed` webhook sends `{"id": task_id}`, not a sanitized task —
  so `sanitize_task_for_webhook` is NOT built this slice.** Legacy `ai-agent.ts:859` fires
  `notifyAgent(userId, "task.completed", { id: taskId })` — the completion event carries only the id
  (the agent re-fetches via `GET /v1/tasks` if it wants detail). The legacy `sanitizeTaskForWebhook`
  whitelist is used **only** by `task.created`/`task.updated` (`routes.ts:3038,3081`) — the **regular**
  task-CRUD surface, not the agent API, and not the delivery path this slice's 3b wires. Building it
  here would be a pure helper that **neither 3a nor 3b consumes** — unlike slice 1's validator, which
  the immediately-following slice 2 consumed; this would be genuinely consumer-less speculative code
  (Simplicity First / Surgical Changes). **Ruling:** drop `sanitize_task_for_webhook` from 3a; 3b's
  trigger builds `data = {"id": task_id}` directly. The `sanitize_*` subsets + the
  `task.created`/`updated`/`deleted` + `calendar_event.*` triggers land with the `routes.ts` CRUD
  surfaces in a later cut (see Out of scope). **Flagged for the reviewer** as the divergence from the
  draft's scope.
- **No migration.** `webhook_url`/`webhook_secret`/`webhook_fail_count` already exist on head
  `acb242a1f541`; this slice adds no columns. The `.ai` migration-in-slice rule does not fire.
- **No `AppError` raised in this slice.** These are pure helpers + scaffold; they return values
  (`tuple | None`, enums, dicts/bytes), they do not raise into business code. Slice 3b's task swallows
  all delivery failures best-effort (legacy `notifyAgent` never throws into the caller), so the
  typed-`AppError` rule applies to 3b's edges, not 3a's pure core. Named so the reviewer does not read
  the absence of `AppError` as an omission.
- **`task.completed` event name confirmed from legacy** (`ai-agent.ts:859`,
  `notifyAgent(userId, "task.completed", ...)`) — **not** `calendar_task.completed`. This only matters
  in 3b's trigger, but is fixed here so 3a's payload/sanitize test fixtures use the literal string
  without later rework.

# Out of scope

- **Slice 3b (the delivery task + trigger):** `app/tasks/webhook.py` (the async task,
  `httpx.AsyncClient(follow_redirects=False)` POST **pinned to the resolved IP with SNI/Host =
  hostname** and `content=serialize_payload(...)` bytes — **never** `json=`, the retry/backoff loop
  driving `decide_delivery_outcome`, the atomic `webhook_fail_count + 1` increment / threshold
  auto-disable / 2xx reset, with `RETRY`/`GIVE_UP` mapped to **no** `fail_count` mutation, best-effort
  `log_agent_event`), the `autodiscover_tasks(["app.tasks"])` line + the `app/tasks/` package, the
  `notifyAgent` fan-out (`SELECT … WHERE webhook_url IS NOT NULL`, `asyncio.gather(return_exceptions=
  True)`), the single `task.completed` trigger in `complete_task` (fired only on the first idempotent
  flip; passing **JSON primitives** `token_id: str`/`event: str`/`data: dict` — **never** an ORM
  `Task`/`AiAgentToken` instance), the contextvars-scoping fix so the in-request enqueue does not wipe
  the request's correlation_id via `task_postrun`, and the new
  `WEBHOOK_DELIVERED`/`WEBHOOK_FAILED`/`WEBHOOK_DISABLED` log levels — all slice 3b.
- **The other event triggers and their field-subset sanitizers** — `task.created`/`task.updated`
  (`sanitize_task_for_webhook`), `task.deleted` (`{id}`), and `calendar_event.*`
  (`sanitize_event_for_webhook`). These fire from the **regular** task/calendar CRUD surfaces
  (`routes.ts`), not the agent API's `task.completed` path, so they land with those surfaces in a later
  cut — neither 3a nor 3b touches them.
- **Flower** (deploy-time monitoring dashboard) and **Celery Beat** (recurring schedules) — deferred,
  documented, not built. **No Railway worker-service / Dockerfile-for-worker** definition — deploy-time,
  out of scope (the app `Dockerfile` is unchanged; the worker entrypoint `celery -A app.celery_app
  worker` is documented in the plan, not wired into deploy here).
- **Application-layer encryption** of `webhook_secret`, **IP-pinned custom httpx transport**, and
  **TOCTOU-hardening** beyond the single `resolve_and_check_host` check — named in Risks, not built.
- No schema change / no migration; no change to `complete_task`, `AgentDataService`, or any router
  this slice.

# Acceptance criteria

- [ ] `from app.celery_app import celery_app, ping` imports cleanly with no Redis connection at import
      time (Celery is lazy). Under the conftest eager fixture, `ping.delay().get(timeout=1) == "pong"`.
      The app's broker is `get_settings().redis_url`, serialization is json-only
      (`task_serializer == "json"`, `accept_content == ["json"]`), and **no result backend** is set
      (`celery_app.conf.result_backend` is falsy / unset) with `task_ignore_result is True`.
- [ ] **No `autodiscover_tasks` call exists** in `app/celery_app.py` and `app/tasks/` is **not**
      created this slice (both are 3b).
- [ ] **JSON-arg contract:** enqueuing a one-arg task with a **truly non-JSON-serializable** value
      (a plain `object()` / an ORM instance — **not** a `datetime`) under the eager fixture raises
      `kombu.exceptions.EncodeError`, pinning 3b's "pass JSON primitives, never ORM objects" rule.
      Eager **does** serialize task args with the configured `json` serializer (verified — a plain
      `object()` raises `EncodeError`); a `datetime` would be a false negative because kombu's JSON
      encoder special-cases `datetime`/`uuid`, so the vector must be a value the JSON serializer truly
      cannot encode. (This is distinct from `before_task_publish`, which genuinely does NOT fire under
      eager — eager skips the broker publish but still serializes the args.) Plus the config is
      asserted directly: `task_serializer == "json"`, `accept_content == ["json"]`.
- [ ] **Signal handlers (unit-tested as plain functions, not via the eager pipeline):**
      `before_task_publish` handler called with `headers={}` and a bound `correlation_id` sets
      `headers["correlation_id"]`; called with **no** bound id leaves `headers` unchanged (no
      `KeyError`); called with `headers=None` is a no-op. `task_prerun` handler with a fake task whose
      `.request.headers == {"correlation_id": "cid-xyz"}` binds `cid-xyz` into
      `structlog.contextvars.get_contextvars()`; with `.request.headers == {}` binds nothing; and a
      task with **no** `.request` (`task=object()`) is a safe no-op (binds nothing, raises nothing —
      pins the nested-`getattr` guard). `task_postrun` handler clears contextvars. (No test asserts
      `before_task_publish` fired via `delay()`/`apply_async` — that path does not run under eager.)
- [ ] **Prod-safety (non-vacuous, checks the shipped config):** the module-level `CELERY_CONFIG` dict
      that `app/celery_app.py` applies via `celery_app.conf.update(CELERY_CONFIG)` does **not** contain
      `task_always_eager` (`"task_always_eager" not in CELERY_CONFIG` and
      `CELERY_CONFIG.get("task_always_eager") in (None, False)`) — proving the shipped module never
      enables eager, independent of the autouse fixture's runtime mutation of the live
      `celery_app.conf` singleton.
- [ ] `serialize_payload` is deterministic: two dicts (incl. a **nested** dict) with the same entries
      in **reverse** key order produce **identical** bytes (proves `sort_keys`), the bytes have **no**
      space after `:`/`,` (proves compact separators), and a **Cyrillic** string round-trips as raw
      UTF-8 (proves `ensure_ascii=False`, not `\uXXXX`).
- [ ] `sign_payload(secret, body)` equals an **independently recomputed** `"sha256=" +
      hmac.new(secret.encode(), body, sha256).hexdigest()` (recomputed in the test, not copied), and
      signing the **exact bytes** `serialize_payload` returns (incl. the Cyrillic/nested payload)
      round-trips — proving the signed bytes are the wire bytes.
- [ ] `build_webhook_headers` includes `X-Focal-Signature` **iff** a signature is passed; always
      includes `Content-Type: application/json`, `User-Agent: Focal-Webhook/1.0`, `X-Focal-Agent`,
      `X-Focal-Delivery`.
- [ ] `build_webhook_payload("task.completed", {...}, "u1", now=<fixed dt>)` has keys
      `{event, data, user_id, timestamp}` with `timestamp == fixed_dt.isoformat()` (injected clock).
- [ ] `resolve_and_check_host` (with `socket.getaddrinfo` monkeypatched): host → public IPv4
      `8.8.8.8` returns `("8.8.8.8", host)` (a genuinely globally-routable address — `203.0.113.x`
      TEST-NET is `is_private` in Python and would be wrongly blocked); host → private `10.0.0.5`
      returns `None`; host → **mixed with the safe address FIRST** — public-IPv4 `8.8.8.8` **then**
      private-IPv6 `fc00::1` — returns `None` (the load-bearing **no-early-return** case: the scan must
      reach the second, blocked entry and reject the host even though a safe address appeared first —
      dual-stack AAAA-rebinding defence); host → an IPv6 sockaddr with a **scope id**
      (`fe80::1%eth0`) returns `None` (a link-local — blocked whether `ipaddress.ip_address` parses it
      as link-local or the `ValueError` guard rejects it; no `ValueError` escapes); an **unparseable**
      `sockaddr[0]` (a stubbed `getaddrinfo` returning a bogus `"garbage"` string) returns `None`,
      distinctly exercising the `except ValueError: return None` guard (the `fe80::1%eth0` case may
      *parse* on 3.14 and prove only `_is_blocked_ip`); a public **IPv6** (`2606:4700::1111`) returns
      `("2606:4700::1111", host)`; `getaddrinfo` raising `socket.gaierror` (NXDOMAIN) returns `None`.
      Plus a **regression** test on the **real** `getaddrinfo`: a host with a label > 63 chars
      (`"a"*64 + ".com"`) is accepted by `validate_webhook_url` but makes `getaddrinfo` raise
      `UnicodeError` at IDNA encoding (offline, no DNS query) → `resolve_and_check_host` returns `None`,
      not a raised `UnicodeError`. Uses the **real** `_is_blocked_ip` (rebinding proven against the
      shipped blocklist).
- [ ] `decide_delivery_outcome` truth table (parametrized, including boundaries): `200`→`RESET`;
      `204`→`RESET`; `299`→`RESET`; `300`/`301`/`302` @ `is_last_attempt=False`→`RETRY`, @ `True`→
      `GIVE_UP` (3xx is transient like a network error — **never** INCREMENT/DISABLE); `400` @
      `fail_count=0`→`INCREMENT`; `499` @ `fail_count=0`→`INCREMENT`; `400` @ `fail_count=2`
      (so `+1` reaches `WEBHOOK_DISABLE_AFTER=3`)→`DISABLE`; `500` @ `is_last_attempt=False`→`RETRY`,
      @ `True`→`GIVE_UP`; `503` @ `False`→`RETRY`; `status=None` @ `False`→`RETRY`, @ `True`→`GIVE_UP`.
      The disable boundary uses `fail_count=2` (not 0/3) to prove the **post-increment** rule. The 3xx/
      5xx/None rows assert the action is `RETRY`/`GIVE_UP` — never `INCREMENT`/`DISABLE` — pinning the
      "transient failures don't mutate `fail_count`" contract.
- [ ] `uv.lock` and `pyproject.toml` both updated with `celery[redis]` (via `uv add`, no manual edit /
      no `pip`); Flower and Beat absent.
- [ ] `make verify` green; **no migration**.

# Verification commands

```sh
cd superapp/apps/focal/server && DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev make verify
```

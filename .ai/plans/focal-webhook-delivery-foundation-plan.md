# Summary

Implement `focal-webhook-delivery-foundation` (Phase 8, webhook slice 3a of 3 — the first of two
delivery cuts): the **first Celery surface in the monorepo** plus the **pure delivery domain** that
slice 3b's delivery task will consume. The Celery half is a minimal `app/celery_app.py`
(broker = `settings.redis_url`, **no result backend**, json-only, UTC, `task_ignore_result=True`, a
trivial `ping` task) plus `app/celery_signals.py` carrying `correlation_id` request→task→worker. **No
`autodiscover_tasks` and no `env`-gated eager block** — both would be unverifiable forward-wiring /
dead code this slice; eager is enabled solely by a conftest fixture, and `autodiscover` + the
`app/tasks/` package are 3b's. The pure half extends the slice-1 `app/domain/webhook.py` (no HTTP, no
DB, no Celery import) with the legacy `fireWebhook` constants,
`build_webhook_payload`/`serialize_payload` (one canonical encoder for sign +
wire), `sign_payload` (HMAC-SHA256), `build_webhook_headers`, `resolve_and_check_host` (the
connect-time DNS-rebinding SSRF re-check slice 1 deferred — returns `(ip, hostname)` so 3b can pin the
IP while keeping SNI=hostname; reuses `_is_blocked_ip`; dual-stack any-blocked rejects), and
`decide_delivery_outcome` (the 2xx/3xx/4xx/5xx/network decision as a pure enum; 3xx is transient like
a network error — `RETRY`/`GIVE_UP`, never the 4xx branch; transient → no `fail_count` mutation). The domain ships consumer-less this slice, exactly like slice
1's validator. No schema change (columns exist on head `acb242a1f541`). Task:
[focal-webhook-delivery-foundation.md](../tasks/focal-webhook-delivery-foundation.md). Legacy:
`ai-agent-webhook.ts` + `ai-agent.ts:859`. Sibling precedent: the SSRF validator slice
([focal-webhook-ssrf.md](../tasks/focal-webhook-ssrf.md)).

## Decisions (design + the Gate-1 rulings)

- **`app/celery_app.py`** (new):
  - `settings = get_settings()`; `celery_app = Celery("focal", broker=settings.redis_url)`; a
    module-level `CELERY_CONFIG = {"task_serializer": "json", "result_serializer": "json",
    "accept_content": ["json"], "timezone": "UTC", "enable_utc": True, "task_ignore_result": True}`
    applied via `celery_app.conf.update(CELERY_CONFIG)`. `CELERY_CONFIG` is the fixture-immune view of
    the shipped config the prod-safety test asserts against (it contains **no** `task_always_eager`).
    **No `backend=`** (fire-and-forget; nothing reads results).
  - `@celery_app.task(name="focal.ping") def ping() -> str: return "pong"`.
  - `from app import celery_signals  # noqa: E402,F401` after app creation (importing the app registers
    the signals).
  - **No `autodiscover_tasks` line; no `env`-gated eager block** (both 3b / conftest-only — see rulings).
- **`app/celery_signals.py`** (new) — three `celery.signals` handlers, each a plain function so it is
  directly unit-testable:
  - `@before_task_publish.connect def _carry_cid(headers=None, **_):` read
    `structlog.contextvars.get_contextvars().get("correlation_id")`; if set **and** `headers is not
    None`, `headers["correlation_id"] = cid`. No-op otherwise.
  - `@task_prerun.connect def _bind_cid(task=None, **_):`
    `cid = (getattr(getattr(task, "request", None), "headers", None) or {}).get("correlation_id")`
    (nested `getattr` so a task without `.request` is a safe no-op); if `cid:
    structlog.contextvars.bind_contextvars(correlation_id=cid)`.
  - `@task_postrun.connect def _clear(**_): structlog.contextvars.clear_contextvars()`.
- **`app/domain/webhook.py`** (modify — extend the pure slice-1 module; new imports limited to
  `hashlib`, `hmac`, `json`, `datetime.datetime`, `enum.StrEnum`, `typing.Any`; `ipaddress`/`socket`
  already imported. **No `app.models` import** — the domain stays ORM-free; the only `dict`-shaped
  input is `build_webhook_payload`'s `data`, supplied by 3b's caller, not read off a `Task`):
  - Constants `WEBHOOK_TIMEOUT_S = 5.0`, `WEBHOOK_MAX_RETRIES = 2`, `WEBHOOK_RETRY_DELAY_S = 1.0`,
    `WEBHOOK_DISABLE_AFTER = 3` (legacy `ai-agent-webhook.ts:31-40`, ms→s for httpx).
  - `build_webhook_payload(event, data, user_id, *, now) -> dict` →
    `{"event": event, "data": data, "user_id": user_id, "timestamp": now.isoformat()}`.
  - `serialize_payload(payload) -> bytes` →
    `json.dumps(payload, separators=(",", ":"), ensure_ascii=False, sort_keys=True).encode("utf-8")`.
  - `sign_payload(secret, body) -> str` → `"sha256=" + hmac.new(secret.encode(), body,
    hashlib.sha256).hexdigest()`.
  - `build_webhook_headers(agent_name, delivery_id, signature) -> dict[str, str]` — 4 fixed headers +
    `X-Focal-Signature` only when `signature is not None`.
  - `resolve_and_check_host(host, *, port) -> tuple[str, str] | None` —
    `try: infos = socket.getaddrinfo(host, port, type=socket.SOCK_STREAM) except _RESOLVE_ERRORS:
    return None` with `_RESOLVE_ERRORS = (OSError, UnicodeError)` — `gaierror` (NXDOMAIN; an
    `OSError`) AND `UnicodeError` (IDNA encoding, e.g. a > 63-char DNS label `validate_webhook_url`
    accepts; otherwise it would raise rather than return `None`). **Scan EVERY address before returning any** (one loop, deferred return): track the
    first safe IP, but on **any** address that `_is_blocked_ip(ip)` is True **or** fails
    `ipaddress.ip_address(sockaddr[0])` with `ValueError` (a scoped/unparseable form we cannot verify)
    → `return None` immediately (any-blocked / any-unverifiable rejects — the DNS-rebinding defence:
    never connect to a host whose resolution set contains an address we can't prove is safe). After
    the loop, return `(first_safe_ip, host)` or `None` if the set was empty. **Not** an early return on
    the first safe address — a later blocked/AAAA entry must still reject the whole host. Reuses
    `_is_blocked_ip` — no duplicated blocklist.
  - `class DeliveryAction(StrEnum): RESET; RETRY; INCREMENT; DISABLE; GIVE_UP` and
    `decide_delivery_outcome(*, status, is_last_attempt, fail_count) -> DeliveryAction` — 2xx→RESET;
    **3xx→RETRY** if not `is_last_attempt` else GIVE_UP (legacy parity: `redirect:"error"` made
    `fetch` *reject*, which fell into the catch-and-retry path, `ai-agent-webhook.ts:212-217`, retrying
    until the last attempt and **never** touching `fail_count` — so a 3xx is treated exactly like a
    network error, NOT a 4xx; 3b sets `follow_redirects=False` so httpx returns the 3xx rather than
    chasing it); 4xx→DISABLE if `fail_count+1 >= WEBHOOK_DISABLE_AFTER` else INCREMENT; 5xx/None→RETRY
    (or GIVE_UP on last attempt). Only INCREMENT/DISABLE/RESET imply a `fail_count` write; RETRY/GIVE_UP
    imply **none** (the 3b mapping contract — 3xx/5xx/network never auto-disable).
- **`pyproject.toml` / `uv.lock`** — `uv add 'celery[redis]'` (floor `>=5.4`); both committed. No
  Flower, no Beat, no separate result-backend dep.
- **Gate-1 rulings (flagged for the reviewer):**
  - **One combined 3a (scaffold + pure domain), consumer-less domain** — the slice-1 shape; gives 3a a
    real `make verify` surface (eager `ping` + json-only config + directly-tested handlers) and leaves
    3b thin. Headline scoping call.
  - **Correlation-id propagation is proven by unit-testing the three signal handlers directly, not by an
    eager round-trip** — `before_task_publish` does **not** fire under `task_always_eager`
    (celery/celery#3864), so an eager "delay→assert" test is vacuous. The earlier draft's "eager gives a
    real propagation surface" claim is retracted.
  - **No `env`-gated eager block; eager is conftest-fixture-only** — the `env=="test"` branch is dead
    code (nothing sets `ENV=test`; Makefile/`config.py`/conftest confirmed). Prod safety = absence of
    shipped eager-enabling code, asserted on the shipped `CELERY_CONFIG` dict (fixture-immune).
  - **No result backend (`task_ignore_result=True`, `backend` unset)** — fire-and-forget; nothing reads
    results; avoids throwaway keys in the shared Redis.
  - **No `autodiscover_tasks` this slice** — 3b adds it with the `app/tasks/` package.
  - **One canonical `serialize_payload` for sign + wire** — the byte-stability footgun; `sort_keys` +
    compact separators + `ensure_ascii=False`. Divergence from legacy `JSON.stringify` flagged;
    cross-impl JS-agent verification still holds (it signs the raw body it receives). 3b must POST
    `content=body`, never `json=` (acceptance row on 3b).
  - **`resolve_and_check_host` returns `(ip, hostname)`** so 3b pins the IP while keeping SNI/cert =
    hostname (all targets HTTPS); reuses `_is_blocked_ip`; dual-stack any-blocked rejects; scoped IPv6
    treated as blocked. Residual TOCTOU named in Risks.
  - **`decide_delivery_outcome` classifies 3xx as transient `RETRY`/`GIVE_UP`** (legacy parity:
    `redirect:"error"` rejected → catch-and-retry; never the 4xx branch) and keeps all transient
    (3xx/5xx/None) failures off the `fail_count` path.
  - **`celery[redis]>=5.4` coded to the monorepo pin**; **Flower/Beat deferred**, documented not dropped.
  - **No `AppError` in 3a** (pure helpers return values; 3b owns best-effort swallowing) — named so its
    absence is not read as an omission.
  - **No migration** (columns on head `acb242a1f541`).
  - **`task.completed` event name confirmed** (`ai-agent.ts:859`).

# Files to change

| path | change | why |
|------|--------|-----|
| `app/celery_app.py` | new | the monorepo's first Celery app: broker = `redis_url`, no backend, json-only, `task_ignore_result`, `ping` task, signal import (no autodiscover, no env gate) |
| `app/celery_signals.py` | new | `correlation_id` request→task→worker via `before_task_publish`/`task_prerun`/`task_postrun`, as directly-testable plain functions |
| `app/domain/webhook.py` | modify | constants + `build_webhook_payload`, `serialize_payload`, `sign_payload`, `build_webhook_headers`, `resolve_and_check_host` (→ `(ip, hostname)`), `DeliveryAction`/`decide_delivery_outcome` (pure; reuses `_is_blocked_ip`) |
| `pyproject.toml` | modify (`uv add`) | `celery[redis]>=5.4` |
| `uv.lock` | modify (`uv add`) | pinned resolution for celery + transitive deps |
| `tests/test_webhook_delivery_domain.py` | new | pure unit tests for every domain function (no vacuous assertions) |
| `tests/test_celery_app.py` | new | DB-free: eager `ping`, JSON-arg contract (`object()` arg → `EncodeError`), json-only serializer config, dynamic broker wiring, signal handlers as plain functions, prod-safety on the shipped `CELERY_CONFIG` dict |

# Implementation slices

1. **Deps.** `uv add 'celery[redis]'`; confirm `pyproject.toml` + `uv.lock` updated. *Verify:*
   `uv sync --frozen` clean.
2. **Pure domain.** Constants + the functions/enum in `app/domain/webhook.py`. *Verify:* ruff/mypy +
   the domain test file.
3. **Celery scaffold + signals.** `app/celery_app.py`, `app/celery_signals.py`. *Verify:* import +
   ruff/mypy + the celery test file.
4. **Tests + full run.** *Verify:* full `make verify`.

# Tests

**`tests/test_webhook_delivery_domain.py`** (pure — no DB, no network; mirrors `test_webhook_ssrf.py`):

- **serialize determinism + encoding:** `serialize_payload({"b":1,"a":{"y":2,"x":1}}) ==
  serialize_payload({"a":{"x":1,"y":2},"b":1})` (proves recursive `sort_keys`); assert the exact byte
  string for a known payload has no space after `:`/`,` (compact separators); assert a Cyrillic title
  serializes as **raw UTF-8** bytes, not `\uXXXX` (proves `ensure_ascii=False`).
- **sign round-trips the wire bytes:** `body = serialize_payload(payload)` (use the Cyrillic/nested
  payload); assert `sign_payload(s, body) == "sha256=" + hmac.new(s.encode(), body,
  sha256).hexdigest()` recomputed independently — proves the signed bytes are the wire bytes and the
  digest is correct.
- **headers:** with a signature → `X-Focal-Signature` present and equal; with `None` → key absent; the
  4 fixed headers always present, `User-Agent == "Focal-Webhook/1.0"`.
- **payload envelope:** `build_webhook_payload("task.completed", {...}, "u1", now=<fixed dt>)` keys
  `{event, data, user_id, timestamp}` and `timestamp == fixed_dt.isoformat()` (injected clock).
- **`resolve_and_check_host` (monkeypatch `socket.getaddrinfo`)** — a helper builds `getaddrinfo`-shape
  tuples `(family, type, proto, canonname, sockaddr)` with IPv4 sockaddr `(ip, port)` and IPv6 sockaddr
  `(ip, port, flowinfo, scope)`:
  - public IPv4 `8.8.8.8` (globally routable, `is_private`/`is_global` clean — `203.0.113.x` TEST-NET
    is `is_private` in Python and would be wrongly blocked) → `("8.8.8.8", host)`;
  - private `10.0.0.5` → `None`;
  - **mixed, safe-listed FIRST:** public-IPv4 `8.8.8.8` **then** private-IPv6 `fc00::1` (the blocked
    entry second in the resolution list) → `None`. This is the load-bearing **no-early-return** case:
    an implementation that returned on the first safe address would wrongly pass `8.8.8.8`; the scan
    must reach the second (blocked) entry and reject the whole host (dual-stack AAAA-rebinding defence);
  - scoped IPv6 `fe80::1%eth0` → `None` (a link-local — blocked whether `ipaddress.ip_address` parses
    it as link-local on 3.14 or the `ValueError` guard rejects the unverifiable form; either way no
    `ValueError` escapes);
  - **an unparseable `sockaddr[0]`** (a stubbed `getaddrinfo` returning a bogus `"garbage"` string)
    → `None` — this vector distinctly exercises the `except ValueError: return None` guard, since
    `fe80::1%eth0` may *parse* as link-local on 3.14 and thus prove `_is_blocked_ip`, not the
    exception path;
  - public IPv6 `2606:4700::1111` (Cloudflare, `is_global`) → `("2606:4700::1111", host)`;
  - `getaddrinfo` raising `socket.gaierror` → `None`;
  - **regression (real `getaddrinfo`, no monkeypatch):** a host with a label > 63 chars
    (`"a"*64 + ".com"`) — accepted by `validate_webhook_url` — makes `getaddrinfo` raise `UnicodeError`
    at IDNA encoding (offline) → `None`, not a raised `UnicodeError`.
  Uses the real `_is_blocked_ip`, so rebinding is proven against the shipped blocklist, not a stub.
- **`decide_delivery_outcome` truth table (parametrized, with boundaries):** `200`/`204`/`299`→`RESET`;
  `300`/`301`/`302` @ `is_last_attempt=False`→`RETRY`, @ `True`→`GIVE_UP` (3xx treated as a transient
  like a network error, per legacy's redirect-error→catch→retry — **never** the 4xx increment branch);
  `400`@`fail_count=0`→`INCREMENT`; `499`@`0`→`INCREMENT`;
  `400`@`fail_count=2`→`DISABLE` (the `+1`-reaches-3 post-increment boundary — using 2, not 0/3);
  `500`@`is_last_attempt=False`→`RETRY`, @`True`→`GIVE_UP`; `503`@`False`→`RETRY`; `None`@`False`→
  `RETRY`, @`True`→`GIVE_UP`. Assert every 3xx/5xx/None row yields `RETRY`/`GIVE_UP` (never
  `INCREMENT`/`DISABLE`) — pins "transient failures don't mutate `fail_count`".

**`tests/test_celery_app.py`** (DB-free):

- autouse fixture forces `celery_app.conf.task_always_eager = True` /
  `task_eager_propagates = True` in setup, restores both in teardown — mirrors the existing
  `_agent_logging_test_engine` monkeypatch pattern; no live worker / no Redis needed.
- **ping:** `ping.delay().get(timeout=1) == "pong"` (eager `EagerResult`; the `timeout` is inert under
  eager — noted, harmless) — proves the app is importable, registered, runnable.
- **JSON-arg contract:** define a tiny one-arg eager task; enqueuing it with a **truly
  non-JSON-serializable** value (a plain `object()`, standing in for an ORM instance — **not** a
  `datetime`) raises `kombu.exceptions.EncodeError`, pinning 3b's "JSON primitives only, never ORM
  objects" rule. Eager **does** serialize args with the configured `json` serializer (verified — a
  plain `object()` raises); a `datetime` is the wrong vector because kombu's JSON encoder special-cases
  `datetime`/`uuid`, so it would pass and give a false negative. (Eager still skips the broker publish,
  so `before_task_publish` does not fire — that is a separate fact; arg serialization does happen.)
  Plus assert the config directly: `task_serializer == "json"`, `accept_content == ["json"]`.
- **config (read dynamically):** `celery_app.conf.task_serializer == "json"`,
  `celery_app.conf.accept_content == ["json"]`, `celery_app.conf.broker_url == get_settings().redis_url`
  (read `get_settings()`, **not** a hardcoded URL — under `make verify` the Makefile exports
  `REDIS_URL=...:6380`, so a literal `6379` would mismatch), `celery_app.conf.result_backend` falsy,
  `celery_app.conf.task_ignore_result is True`.
- **signal handlers as plain functions (the real propagation coverage):** import `_carry_cid`,
  `_bind_cid`, `_clear`. `bind_contextvars(correlation_id="cid-xyz")`, call `_carry_cid(headers=h)`
  with `h={}`, assert `h["correlation_id"] == "cid-xyz"`; with no bound id assert `h` stays `{}` and no
  error; `_carry_cid(headers=None)` is a no-op. Build a fake task object with
  `.request.headers = {"correlation_id": "cid-xyz"}`, call `_bind_cid(task=fake)`, assert
  `structlog.contextvars.get_contextvars().get("correlation_id") == "cid-xyz"`; with
  `.request.headers = {}` assert nothing bound; and **`_bind_cid(task=object())`** (a task with **no**
  `.request`) is a safe no-op — binds nothing, raises nothing — pinning the nested-`getattr` guard.
  Call `_clear()`, assert `get_contextvars() == {}`. (No test asserts `before_task_publish` fires via
  `delay()` — it does not under eager.)
- **prod-safety gate (non-vacuous, checks the SHIPPED config):** `app/celery_app.py` applies its
  settings from a module-level `CELERY_CONFIG: dict` (via `celery_app.conf.update(CELERY_CONFIG)`); the
  test asserts `"task_always_eager" not in CELERY_CONFIG` **and**
  `CELERY_CONFIG.get("task_always_eager") in (None, False)` — proving the shipped module never enables
  eager, regardless of what the autouse fixture later does to the live `celery_app.conf` singleton.
  (A throwaway `Celery("probe")` was rejected — it asserts Celery's own defaults, not Focal's shipped
  app; the autouse fixture has already mutated the real `celery_app.conf` by the time any test body
  runs, so the `CELERY_CONFIG` dict is the only fixture-immune view of what the module ships.)

# Error & rescue map

| failure | error / exception | caught where | what the user sees |
|---------|-------------------|--------------|--------------------|
| webhook host does not resolve (NXDOMAIN) or fails IDNA encoding (overlong label) | `socket.gaierror` / `UnicodeError` | inside `resolve_and_check_host` (`except _RESOLVE_ERRORS = (OSError, UnicodeError)` → `None`) | nothing this slice (3b treats `None` as "do not deliver") |
| webhook host resolves to a private/rebinding IP (incl. dual-stack AAAA) | none (no raise) | `resolve_and_check_host` returns `None` | the resolved IP is rejected; 3b skips delivery |
| `getaddrinfo` returns a scoped/unverifiable IPv6 (`fe80::1%eth0`) | `ValueError` from `ipaddress.ip_address` | per-address `try/except ValueError` → **`return None` immediately** (any-unverifiable rejects the whole host, NOT skip) | the host is rejected; 3b skips delivery |
| correlation_id absent when enqueuing | none (no raise) | `_carry_cid` no-op branch | task runs without a bound id; no `KeyError` |
| non-JSON-serializable task arg (e.g. a plain `object()`/ORM instance) | `kombu.exceptions.EncodeError` at serialize | the configured `json` serializer rejects it — under eager too (eager serializes args, though it skips the broker publish) | the JSON-arg contract test asserts it raises (pins 3b's input rule) |
| broker (Redis) down at enqueue, real (non-eager) prod | `kombu.exceptions.OperationalError` | **not** in this slice — 3a enqueues only under eager (in-process); the prod enqueue path + its best-effort swallow is 3b | n/a here |

(3a introduces **no** new `AppError` path — the pure helpers return values; the best-effort swallowing
of delivery failures lives on 3b's task edge, matching legacy `notifyAgent` never throwing into the
caller.)

# Risks & migrations

- **Signature byte-instability (highest severity, no error surface).** If 3b signs bytes other than
  what `serialize_payload` returns and POSTs (e.g. lets httpx re-encode the dict via `json=`), the
  agent's `X-Focal-Signature` verification fails silently. Mitigated by making `serialize_payload` the
  single canonical encoder, pinned by the determinism + Cyrillic/nested + independent-recompute HMAC
  tests; 3b's contract is "sign and POST the exact `content=body` bytes — never `json=`" (an acceptance
  row on 3b).
- **HTTPS SNI/cert vs IP-pinning (the reason `resolve_and_check_host` returns `(ip, hostname)`).** All
  targets are HTTPS; connecting to a bare IP would fail TLS hostname verification, tempting 3b to
  re-resolve (re-opening rebinding) or disable `verify`. Returning `(ip, hostname)` lets 3b connect to
  the validated IP with SNI/Host/cert-verify = hostname. The custom-transport plumbing to do that
  cleanly in httpx is **3b/out-of-scope**; 3a fixes the **contract** (the tuple shape + the documented
  3b connection rule).
- **TOCTOU between `resolve_and_check_host` and 3b's connect (accepted, documented).** DNS may change
  between this check and the socket connect in 3b. Returning the validated IP lets 3b pin the
  connection to it rather than re-resolve, closing most of the window; full IP-pinned custom transport
  is out of scope; low-latency eager/worker execution keeps the window small. Named, not built.
- **Dual-stack rebinding via AAAA.** A host with a public A record but a private/loopback AAAA record
  would bypass an IPv4-only check. `resolve_and_check_host` iterates **all** `getaddrinfo` results and
  rejects if **any** is blocked — pinned by the mixed public-IPv4 + private-IPv6 test row.
- **3xx silently dropping the `redirect:"error"` guarantee.** `follow_redirects=False` (3b) returns,
  not raises, a 3xx; if the decision tree let 3xx fall into the `status < 500` branch it would
  wrongly increment/disable. `decide_delivery_outcome` classifies 3xx as a transient
  `RETRY`/`GIVE_UP` (legacy parity — `redirect:"error"` rejected into the catch-and-retry path, never
  touching `fail_count`), pinned by 3xx truth-table rows at both `is_last_attempt` values. Mitigated
  in 3a.
- **Auto-disable as a denial-of-delivery if transient failures counted.** Counting 5xx/timeouts toward
  the disable threshold would let a flaky endpoint auto-disable a healthy webhook. The enum keeps
  transient outcomes (`RETRY`/`GIVE_UP`) off the `fail_count` path; 3b must map them to **no** mutation
  (asserted by the truth table, stated as the 3b contract).
- **`task_postrun` global clear wiping the request's correlation_id under eager (3b footgun, named
  now).** The app middleware binds `correlation_id` per request; under eager the task runs inside that
  contextvars stack, so `_clear()` on `task_postrun` would strip the request's id mid-request when 3b
  enqueues from inside `complete_task`. 3a has **no** enqueue-from-request path, so it is latent here;
  flagged so 3b's trigger scopes/restores contextvars rather than relying on the global clear.
- **`task_always_eager` leaking into production (eliminated, not merely guarded).** No shipped module
  code enables eager (the dead `env=="test"` gate is removed); eager exists only in the test fixture.
  Asserted by the prod-safety test on the shipped `CELERY_CONFIG` dict (fixture-immune).
- **Redis shared (broker + rate-limit + sessions + quotas) — capacity, not correctness.** Mitigated
  partly by `task_ignore_result=True`/no backend (no throwaway result keys). A delivery burst pressure
  is a 3b/ops concern (monitor memory, `maxmemory-policy`), named here, nothing built in 3a.
- **New dependency surface (`celery[redis]` + transitives).** First Celery in the monorepo; `uv add`
  pins it in `uv.lock` so prod resolves the same tree. Floor `>=5.4` per the stack, coded to the repo
  pin.
- **No migration / no schema change** (`webhook_*` columns exist on head `acb242a1f541`); no behavior
  change to any existing endpoint or service. Rollback = revert the new files + the two-line
  `pyproject.toml`/`uv.lock` dep, no data to undo.

# Scope check

- [x] Matches the task: Celery scaffold (no autodiscover, no env gate, no backend) + the pure delivery
      domain only; the delivery task, fan-out, trigger, fail-count read/increment/auto-disable,
      `autodiscover`/`app/tasks/`, and `WEBHOOK_*` log levels are all slice 3b.
- [x] Reviewable in one pass — one Celery app + one signals module + ~7 pure functions/enum extending an
      existing file + two test files + one dep. The domain half is unit-testable in isolation (the
      slice-1 precedent); the trimmed scaffold (no dead gate, no premature autodiscover, no unused
      backend) is tighter than the draft.
- [x] Size smell: moderate but cohesive (the scaffold and the domain share the one `make verify` surface
      and the consumer-less-core pattern); splitting further would leave a near-empty scaffold-only
      review. Justified above and flagged for the reviewer.

# Out of scope

Slice 3b — `app/tasks/webhook.py` (the async delivery task: `httpx.AsyncClient(follow_redirects=False)`
POST **pinned to the resolved IP with SNI/Host=hostname** and `content=serialize_payload(...)` bytes
**not** `json=`, the retry/backoff loop driving `decide_delivery_outcome`, the atomic
`webhook_fail_count + 1` increment / threshold auto-disable / 2xx reset with `RETRY`/`GIVE_UP` mapped to
**no** `fail_count` mutation, best-effort `log_agent_event`), `autodiscover_tasks(["app.tasks"])` + the
`app/tasks/` package, the `notifyAgent` fan-out (`SELECT … WHERE webhook_url IS NOT NULL`,
`asyncio.gather(return_exceptions=True)`), the single `task.completed` trigger in `complete_task`
(first-flip only, JSON-primitive args, `data = {"id": task_id}` per legacy parity), the
contextvars-scoping fix for the in-request enqueue, and the
`WEBHOOK_DELIVERED`/`WEBHOOK_FAILED`/`WEBHOOK_DISABLED` levels. The other event triggers + their
sanitizers (`task.created`/`updated` → `sanitize_task_for_webhook`, `calendar_event.*` →
`sanitize_event_for_webhook`) fire from the regular `routes.ts` CRUD surfaces, not this agent-API
path — a later cut. Flower, Celery Beat, the Railway worker-service/Dockerfile, application-
layer secret encryption, an IP-pinned custom transport, and TOCTOU hardening beyond the single
resolve-and-check. No new migration.

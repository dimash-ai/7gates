# Summary

Implement `focal-webhook-url-crud` (Phase 8, webhook slice 2/3): `PUT`/`DELETE
/api/ai-agent/tokens/{name}/webhook` — set/replace or clear the delivery webhook URL on a `foc_`
token, generating the per-agent HMAC secret `whs_<48hex>` (stored **recoverable**, returned once)
on an actual URL change, with the input trimmed (legacy `.trim()`) and SSRF-validated by the shipped
`validate_webhook_url` before any write. JWT-authed control plane; delivery/HMAC-signing is slice 3.
No schema change (columns exist on head `acb242a1f541`). Task:
[focal-webhook-url-crud.md](../tasks/focal-webhook-url-crud.md). Legacy: `ai-agent.ts:495-550`.
Direct template: the ical-alias slice ([focal-agent-ical-alias.md](../tasks/focal-agent-ical-alias.md)).

## Decisions (design + the Gate-1 rulings)

- **`app/domain/agent_token.py`** (modify) — `generate_webhook_secret() -> str`: `return "whs_" +
  secrets.token_hex(24)` (48 hex after the prefix; legacy `whs_${randomBytes(24).hex}`). **Raw
  string only — no hash pair** (the secret is stored recoverable so the server can re-sign at
  delivery; this is the deliberate departure from the hash-only `generate_agent_token`/
  `generate_ical_alias`).
- **`app/services/agent_tokens.py`** (modify):
  - `set_webhook(user_id, name, payload: WebhookUrlSet) -> WebhookSet`:
    1. `token = await self._require(user_id, name)` (404 missing/cross-tenant) **first**.
    2. `url = payload.webhook_url.strip()` (legacy `.trim()`); `if not url: raise
       ValidationError("webhookUrl must not be empty; use DELETE to clear")` (422).
    3. `if (msg := validate_webhook_url(url)) is not None: raise ValidationError(msg)` (422, domain
       wording verbatim).
    4. **Idempotency no-op (zero ORM mutation):** `if url == token.webhook_url: return WebhookSet(
       webhook_url=token.webhook_url, webhook_secret=None)` — no secret assignment, no
       `commit`/`refresh`, so the stored secret is provably unchanged.
    5. Else (URL changed): `token.webhook_url = url`; `token.webhook_secret =
       generate_webhook_secret()`; `token.webhook_fail_count = 0`; `await self.session.commit()`;
       `await self.session.refresh(token)`; `return WebhookSet(webhook_url=token.webhook_url,
       webhook_secret=<raw>)`. The non-null `webhook_secret` is the router's "URL changed" signal.
  - `clear_webhook(user_id, name) -> bool`: `token = await self._require(...)`; `changed =
    token.webhook_url is not None`; `token.webhook_url = None`; `token.webhook_secret = None`;
    `token.webhook_fail_count = 0`; `await self.session.commit()`; `return changed`. Idempotent on an
    owned token. (Plain `commit` — no `_commit_unique`; these columns carry no unique constraint.)
  - Imports: `validate_webhook_url` (from `app.domain.webhook`), `generate_webhook_secret`,
    `ValidationError`, `WebhookUrlSet`, `WebhookSet`.
- **`app/schemas/agent_token.py`** (modify):
  - `WebhookUrlSet(_Camel)`: `webhook_url: str = Field(min_length=1, max_length=2048)` (wire
    `webhookUrl`). No `field_validator` — trimming + SSRF check are the single service layer.
  - `WebhookSet(_Camel)`: `webhook_url: str` (**non-optional** — clear is DELETE/204, so a PUT body
    always carries the submitted URL), `webhook_secret: str | None` (the once-only raw on a change,
    `None` on the no-op; Pydantic v2 serializes it as `webhookSecret: null` key-present, matching
    legacy `ai-agent.ts:524` — **no** `exclude_none`). `AgentTokenRead` unchanged (it already
    exposes `webhook_url`, never the secret).
- **`app/api/agent_tokens.py`** (modify), placed next to the ical routes (literal `/webhook` suffix
  is shadow-safe under the bare `/tokens/{name}`):
  - `PUT /tokens/{name}/webhook` (`response_model=WebhookSet`, status 200 — FastAPI default,
    inherited from the ical-`POST` precedent; no `status_code` kwarg, stated here so it is not read
    as forgotten) — `result = await service.set_webhook(user_id, name, payload)`; `if
    result.webhook_secret is not None: await log_agent_event("WEBHOOK_UPDATED", user_id=user_id,
    agent_name=name, details={"removed": False})`; `return result`. No `Request` param.
  - `DELETE /tokens/{name}/webhook` (204) — `changed = await service.clear_webhook(user_id, name)`;
    `if changed: await log_agent_event("WEBHOOK_UPDATED", user_id=user_id, agent_name=name,
    details={"removed": True})`; `return Response(status_code=status.HTTP_204_NO_CONTENT)`.
  - Imports: `WebhookUrlSet`, `WebhookSet`. Audit is **after** the awaited service call (success
    -only; a 404/422 raises first), like the other control-plane events.
- **`app/agent_logging.py`** (modify) — add `"WEBHOOK_UPDATED": "info"` to `AGENT_EVENT_LEVELS`
  (an unregistered type defaults to `warn`, so the explicit `info` registration is required).
- **Gate-1 rulings (flagged for the reviewer):**
  - **Trimming = legacy `.trim()`** in the service before validate + no-op compare + store; the
    slice-1 validator does not strip whitespace, so without this a trailing-space resubmit silently
    rotates the secret (the headline footgun).
  - **Empty/whitespace PUT body → 422**, not a clear (PUT/DELETE separation over legacy's nullable
    PATCH). `min_length=1` catches `""`; the service `.strip()` guard catches `"   "`.
  - **422 over legacy 400** for an invalid/SSRF URL (port taxonomy; legacy 400 was tied to the
    forbidden `{ok:false}` envelope). Acknowledged: `errors.py` also has 400-coded domain errors;
    webhook-URL rejection follows `ValidationError`(422) because it is single-field body validation,
    not a cross-entity conflict. Override to `status_code=400` only if strict parity is mandated; no
    new exception class.
  - **`_require` (404) before validation** (reordered from legacy) so a non-owner never receives
    validation feedback. Pinned by a cross-tenant test with an SSRF body asserting 404 (not 422).
  - **`webhook_fail_count = 0` on set-change and on clear** — minor divergence from legacy's
    set-path (legacy reset only on delivery auto-disable); this slice owns the write that creates the
    secret, so it owns the column's `count==0` invariant and prevents slice-3 immediately re-tripping
    the disable threshold. Slice-3 read/increment/auto-disable stays out of scope.
  - **Recoverable (un-hashed) secret** — the load-bearing, deliberate deviation from the hash-only
    token/alias rule (the server is the HMAC signer).
  - **Last-writer-wins on concurrent set** — accepted, documented in Risks (legacy had the same
    gap); no row lock added.

# Files to change

| path | change | why |
|------|--------|-----|
| `app/domain/agent_token.py` | modify | `generate_webhook_secret()` (raw `whs_<48hex>`, no hash) |
| `app/services/agent_tokens.py` | modify | `set_webhook` (require → trim → validate → no-op/rotate, zero fail-count on change), `clear_webhook` (nulls all three columns, returns `changed`) |
| `app/schemas/agent_token.py` | modify | `WebhookUrlSet` (input), `WebhookSet` (output, `webhook_url` non-optional) |
| `app/api/agent_tokens.py` | modify | the two `/webhook` routes + change-only audit on both |
| `app/agent_logging.py` | modify | `"WEBHOOK_UPDATED": "info"` |
| `tests/test_agent_tokens_db.py` | modify | webhook set/idempotent(+whitespace)/rotate/clear/empty/422/404(+SSRF)/401/no-leak + audit tests, `_stored_webhook` reader |

# Implementation slices

1. **Domain + schemas + level.** `generate_webhook_secret`, `WebhookUrlSet`/`WebhookSet`,
   `WEBHOOK_UPDATED` level. *Verify:* imports + ruff/mypy.
2. **Service.** `set_webhook` (require → trim → validate → no-op/rotate, zero fail-count) +
   `clear_webhook` (nulls all three, returns `changed`). *Verify:* ruff/mypy.
3. **Router.** the two routes + change-only audit on both. *Verify:* `make verify`.
4. **Tests.** *Verify:* full `make verify`.

# Tests (extend `tests/test_agent_tokens_db.py`; add `_stored_webhook(name, user) -> tuple[str | None, str | None, int]`)

Reader SQL: `SELECT webhook_url, webhook_secret, webhook_fail_count FROM focal.ai_agent_tokens WHERE
user_id = :u AND name = :n` — one reader for all three webhook columns (returns `(None, None, 0)`
for a never-set / cleared row, since `webhook_fail_count` is `NOT NULL default 0`), so every
persistence assertion below pins the fail-count in the same tuple, no separate query.

Also add a raw-SQL seed helper `_set_fail_count(name, user, n)` — `UPDATE focal.ai_agent_tokens SET
webhook_fail_count = :n WHERE user_id = :u AND name = :n_` (same `_sessionmaker` + `text()` pattern
as the readers, `await session.commit()`). The reset tests **must** start from a non-zero count;
without seeding, every row sits at the `default 0` and a `== 0` assertion would pass even if the
implementation forgot to reset, proving nothing.

- **set valid:** `PUT …/webhook` with `https://hooks.example.com/focal` on an owned token → 200;
  `webhookUrl == <url>`; `re.fullmatch(r"whs_[0-9a-f]{48}", webhookSecret)`; `_stored_webhook(...)
  == (url, webhookSecret, 0)` (stored secret equals the returned value, fail-count zero); one
  `WEBHOOK_UPDATED` row with strict `row.details == {"removed": False}` and `level == "info"`.
- **set trims on first write:** `PUT {"webhookUrl": f"  {url}  "}` (surrounding whitespace) on a
  fresh token → 200 with `webhookUrl == url` (trimmed) and `_stored_webhook(...)[0] == url` — the
  **stored** value is the normalized URL, not the padded input, proving `.strip()` runs before the
  write (so a later clean re-PUT is a true no-op rather than a phantom change).
- **idempotent same-URL (the critical HMAC-stability case):** `r1 = PUT(url); s1 =
  r1.json()["webhookSecret"]; assert _stored_webhook(...) == (url, s1, 0)`; then `r2 = PUT(url);
  assert r2.json()["webhookSecret"] is None and "webhookSecret" in r2.json(); assert
  _stored_webhook(...) == (url, s1, 0)` (stored secret still `s1`, byte-identical) and
  `len(_logs("WEBHOOK_UPDATED")) == 1`.
- **idempotent same-URL with trailing whitespace:** after the set above, `PUT(f"{url} ")` → 200,
  `webhookSecret is None`, `_stored_webhook(...) == (url, s1, 0)` (stored secret unchanged), audit
  count still 1 — proves normalization, not byte-equality, drives the no-op.
- **changed URL rotates + resets a non-zero fail-count:** after the set, `_set_fail_count(name,
  user, 3)` (seed a stale delivery-failure count), then `PUT` with a different valid URL → 200, a new
  `whs_<48hex>` secret `s2` (`!=` `s1`); `_stored_webhook(...) == (url2, s2, 0)` — the `0` now proves
  the rotate path **reset** the count from 3, not merely that it stayed at the default; a further
  `WEBHOOK_UPDATED` row.
- **sequential audit count (success-AND-change-only across the lifecycle):** in one test/transaction
  — set (assert `len(_logs("WEBHOOK_UPDATED")) == 1`) → same-URL re-PUT (still `1`) → changed-URL PUT
  (`== 2`).
- **empty / whitespace-only body:** `PUT {"webhookUrl": ""}` → 422 `validation_error`; `PUT
  {"webhookUrl": "   "}` → 422 `validation_error`; both leave `_stored_webhook == (None, None, 0)`
  and `_log_count` unchanged.
- **invalid/SSRF (parametrized: `http://example.com`, `https://localhost/`, `https://127.0.0.1/`,
  and an embedded control-byte form `"https://127.0.0.1\t.example.com/"`):** `PUT` → 422,
  `error.code == "validation_error"`, `_stored_webhook == (None, None, 0)`, `_log_count` unchanged.
  (The tab is mid-string so `.strip()` cannot remove it; it reaches the validator's raw-control-byte
  reject — proving the service trim only touches surrounding whitespace, no pre-strip bypass.)
- **clear + resets a non-zero fail-count:** after a set, `_set_fail_count(name, user, 3)`, then
  `DELETE` → 204; `_stored_webhook == (None, None, 0)` — the `0` proves DELETE **zeroed** the count
  from 3 (not just that url/secret nulled); one `WEBHOOK_UPDATED` row with strict
  `details == {"removed": True}`.
- **clear idempotent (already-null):** `DELETE` on an owned token with no webhook set → 204 and
  `len(_logs("WEBHOOK_UPDATED")) == 0` (silent, matching legacy).
- **404 missing / cross-tenant (parametrized `method=["put","delete"]`):** the cross-tenant case
  **seeds the owner first** — `user-a` creates `planner` and sets its webhook (`url_a`, secret `s_a`),
  then `_set_fail_count("planner", "user-a", 2)` — so the owner row is fully populated
  `(url_a, s_a, 2)`. Then `user-b` (who owns no `planner`) calls `PUT` (valid body) / `DELETE` on
  `planner` → 404, audit count unchanged, and `_stored_webhook("planner", "user-a") == (url_a, s_a,
  2)` byte-for-byte — proving the unscoped-clear/write bug (a `_require`/`clear` that filtered on
  `name` alone) cannot silently wipe or mutate another tenant's webhook. The missing-name leg (a name
  no user owns) → 404 with no row to inspect.
- **404 cross-tenant with an SSRF body (the ownership-before-validation pin):** cross-tenant `PUT`
  with `https://127.0.0.1/` on another user's token → 404 `not_found` (NOT 422), proving validation
  never runs for a non-owner and no validation feedback leaks.
- **401 no-auth (parametrized `method=["put","delete"]`):** with the `get_current_user_id` override
  popped; the `PUT` case sends a **valid** body (`{"webhookUrl": "https://hooks.example.com/x"}`) so
  the only failure is auth → 401 (`auth_required`), audit count unchanged.
- **no secret leak:** `GET /tokens` after a set → the `planner` item has `webhookUrl == <url>` and
  none of `_SECRET_KEYS` (incl. `webhookSecret`/`webhook_secret`) present.

# Error & rescue map

| failure | error | response |
|---------|-------|----------|
| `PUT`/`DELETE` a missing / other-user token | `NotFoundError` (via `_require`) | 404 `{error:{code}}` |
| empty / whitespace-only PUT body | `ValidationError` (service `.strip()` guard) / `RequestValidationError` (`min_length=1`) | 422 `{error:{code,message}}` |
| invalid / SSRF-rejected URL | `ValidationError(msg)` | 422 `{error:{code,message}}` |
| unauthenticated | `AuthRequiredError` | 401 |
| the `WEBHOOK_UPDATED` log write fails | swallowed in `log_agent_event` | the op already committed; response unaffected (rotation traceability lost — see Risks) |

# Risks

- **Silent secret rotation (highest-severity, no error surface).** If the same-URL no-op guard or the
  `.strip()` normalization is missed, a re-save (or a whitespace-only-different resubmit) rotates
  `whs_` and the agent's stored signing key silently goes stale — all future `X-Focal-Signature`
  checks fail on the agent side with zero visibility in Focal. Pinned by the byte-identical-stored
  -secret test **and** the trailing-whitespace no-op test.
- **Concurrent changed-URL writers (accepted waiver).** Two near-simultaneous PUTs with the same new
  URL each generate a distinct secret; the second commit wins, so the secret returned to the first
  caller is not the persisted one. Legacy had the identical gap (no row lock) — **not a parity
  regression**; last-writer-wins on a control-plane PUT is the accepted tradeoff. `SELECT … FOR
  UPDATE` is deliberately out of scope.
- **Secret leak on read.** Any future `webhook_secret` field on `AgentTokenRead` (or a stray
  `model_dump` of the ORM row) would expose the HMAC key on every list. Pinned by the extended
  `_SECRET_KEYS` absence assertion.
- **Secret/URL in logs.** The secret and the URL must never enter `log_agent_event` `details` (it
  persists to `ai_agent_logs` and drains to Loki) — only `{"removed": bool}`. Pinned by the strict
  `==` audit-row assertions, which forbid any extra key.
- **Rotation audit can be lost (accepted).** `log_agent_event` runs in a separate session after the
  commit and swallows `SQLAlchemyError`; a successful rotation whose audit write fails leaves no
  durable record of which agent's key changed. This is the accepted tradeoff — logging never blocks
  the control-plane op. Named, not silent.
- **Plaintext-at-rest, url+secret co-resident (accepted, documented).** `webhook_secret` is
  unencrypted at the app layer and shares the row with the plaintext `webhook_url`, so a DB-read
  compromise yields a forgeable, correctly signed delivery to the agent's URL. Confidentiality rests
  on Postgres at-rest encryption of whichever managed engine holds `focal.*` (per this repo, dev/
  migrations on local Docker / Railway PG; Supabase is auth, not necessarily the at-rest owner).
  Application-layer encryption is out of scope for this slice.
- **Validator is host-string-only (no DNS).** A public hostname resolving to a private IP
  (DNS-rebinding) is not blocked at storage time — that residual SSRF risk is owned by slice 3's
  connect-time IP check (documented in slice 1). This slice does not claim full SSRF protection.
- **No migration / no schema change** (`webhook_url`/`webhook_secret`/`webhook_fail_count` exist on
  head `acb242a1f541`); no behavior change to other endpoints.

# Scope check

- [x] Matches the task (URL-only CRUD + the `whs_` secret lifecycle + the `fail_count`-zero
      invariant on write; delivery/HMAC/fail-count read+increment deferred to slice 3).
- [x] Reviewable in one pass — one domain helper + two service methods + two routes + two schemas +
      one log level + tests.
- [x] Size smell: small; reuses `_require`, `validate_webhook_url`, `log_agent_event`, the ical
      route/service/test template, and the `_SECRET_KEYS` leak guard.

# Out of scope

Slice 3 — delivery (`notifyAgent`/`fireWebhook`), HMAC signing + the `X-Focal-Signature` header,
retries, the `webhook_fail_count` **read / increment / 4xx auto-disable** logic (this slice only
zeroes the counter on set/clear), the `sanitize_*` payload subsets, the event triggers, and the
connect-time IP / DNS-rebinding SSRF re-check; application-layer encryption of the secret;
concurrency hardening (`SELECT … FOR UPDATE`); the Redis rate-limit backend; any change to
`AgentTokenRead`/`AgentTokenCreated`, the scopes `PATCH`, or other endpoints; no new migration.

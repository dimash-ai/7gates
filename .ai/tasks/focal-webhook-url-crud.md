# Goal

Port the focal **webhook-URL CRUD** (Phase 8, webhook slice 2/3): `PUT`/`DELETE
/api/ai-agent/tokens/{name}/webhook` — set/replace or clear the delivery webhook URL on an existing
`foc_` token. Setting a (new, valid) URL generates the per-agent HMAC signing secret `whs_<48hex>`,
stored **recoverable** (the server is the signer at delivery) and returned **once**; the URL is
SSRF-validated by the shipped `validate_webhook_url` before any write. Builds on slice 1 (the
validator, `app/domain/webhook.py` + `tests/test_webhook_ssrf.py`) and is consumed by slice 3
(delivery / HMAC signing / fail-count increment / retries). Legacy: `focal/server/ai-agent.ts:495-550`
(the dedicated `PATCH /tokens/:name` webhook handler).

# Scope

- **`app/domain/agent_token.py`** (modify) — add `generate_webhook_secret() -> str`: `return
  "whs_" + secrets.token_hex(24)` (48 hex after the `whs_` prefix, matching legacy
  `whs_${randomBytes(24).hex}`). Returns the raw string only — **no** hash pair (unlike
  `generate_agent_token`/`generate_ical_alias`; the secret is stored recoverable, not hashed — see
  Decisions).
- **`app/services/agent_tokens.py`** (modify) — two methods mirroring `create_ical_alias`/
  `revoke_ical_alias`:
  - `set_webhook(user_id, name, payload: WebhookUrlSet) -> WebhookSet`:
    1. `token = await self._require(user_id, name)` — **first**; 404 (missing/cross-tenant) is
       raised before any URL handling, so a non-owner never receives validation feedback.
    2. `url = payload.webhook_url.strip()` — normalize exactly like legacy `.trim()`. If `url == ""`
       (empty or whitespace-only) `raise ValidationError("webhookUrl must not be empty; use DELETE
       to clear")` (422) — PUT never clears (see Decisions: empty-string).
    3. `if (msg := validate_webhook_url(url)) is not None: raise ValidationError(msg)` (422; the
       domain wording verbatim, e.g. `"webhookUrl must use HTTPS"`).
    4. **Idempotency no-op** — `if url == token.webhook_url:` return `WebhookSet(webhook_url=
       token.webhook_url, webhook_secret=None)` with **zero ORM mutation** (no secret assignment, no
       `commit`, no `refresh`) so the stored secret is provably byte-identical. The compare uses the
       **same normalized `url`** as storage, so a re-PUT differing only in surrounding whitespace is
       a true no-op (does **not** rotate the secret).
    5. Otherwise (URL changed) — `token.webhook_url = url`, `token.webhook_secret =
       generate_webhook_secret()`, `token.webhook_fail_count = 0` (a fresh signing key starts with a
       clean delivery-failure budget — see Decisions: fail-count), `commit`, `refresh`, return
       `WebhookSet(webhook_url=token.webhook_url, webhook_secret=<raw>)`.
    The non-null `webhook_secret` in the result is the router's "URL changed" signal so the audit is
    success-and-change-only (`result.webhook_secret is not None`).
  - `clear_webhook(user_id, name) -> bool`: `token = await self._require(user_id, name)`; capture
    `changed = token.webhook_url is not None`; set **all three** `token.webhook_url = None`,
    `token.webhook_secret = None`, `token.webhook_fail_count = 0` in the same update; `commit`;
    `return changed`. Idempotent on an owned token (already-null → still a successful 204). The
    `changed` flag is the router's signal to audit only an actual clear (legacy suppresses the audit
    on a null→null clear — see Decisions: DELETE no-op).
- **`app/schemas/agent_token.py`** (modify) — two `_Camel` schemas:
  - `WebhookUrlSet(_Camel)`: `webhook_url: str = Field(min_length=1, max_length=2048)` (input;
    wire `webhookUrl`). No field-validator — SSRF validation and trimming live in the service (see
    Decisions: single-layer / trimming).
  - `WebhookSet(_Camel)`: `webhook_url: str` + `webhook_secret: str | None` (output; wire
    `webhookUrl`/`webhookSecret`). `webhook_url` is **non-optional** — the clear path returns 204
    with no body, so this body always carries the submitted URL. `webhook_secret` is the once-only
    raw on a change, `None` on the no-op. The existing `AgentTokenRead` (already exposes
    `webhook_url`, never `webhook_secret`) is unchanged.
- **`app/api/agent_tokens.py`** (modify) — on the JWT-authed token router, placed alongside the
  ical routes (a literal `/webhook` suffix cannot be shadowed by the bare `/tokens/{name}`):
  - `PUT /tokens/{name}/webhook` (`response_model=WebhookSet`, status 200) → `result = await
    service.set_webhook(user_id, name, payload)`; emit `WEBHOOK_UPDATED` (info, `details={"removed":
    False}`) **only when the URL actually changed** (`result.webhook_secret is not None`); return
    `result`. No `Request` param — unlike ical, no URL is derived. (200 is FastAPI's default, the
    same implicit default the ical `POST` relies on — see Decisions: status.)
  - `DELETE /tokens/{name}/webhook` (204) → `changed = await service.clear_webhook(user_id, name)`;
    emit `WEBHOOK_UPDATED` (info, `details={"removed": True}`) **only when `changed`** (an
    already-null clear is a silent 204, matching legacy); return
    `Response(status_code=status.HTTP_204_NO_CONTENT)` (the same status-only `Response` the ical
    `DELETE` returns — a bare `Response(204)` would pass `204` as the *body* with a default 200).
- **`app/agent_logging.py`** (modify) — add `"WEBHOOK_UPDATED": "info"` to `AGENT_EVENT_LEVELS`
  (an unregistered type would default to `warn`, so the explicit `info` registration is required).
- **Tests** (extend `tests/test_agent_tokens_db.py`) — add a `_stored_webhook(name, user) ->
  tuple[str | None, str | None, int]` raw-SQL reader (`SELECT webhook_url, webhook_secret,
  webhook_fail_count FROM focal.ai_agent_tokens WHERE user_id = :u AND name = :n`) next to
  `_stored_hash`/`_ical_hash` — one reader covers all three webhook columns so every persistence
  assertion pins `webhook_fail_count` too; plus a `_set_fail_count(name, user, n)` raw-SQL `UPDATE`
  seed helper (same `_sessionmaker`/`text()` pattern) so the fail-count-reset tests start from a
  non-zero value rather than the `default 0`. Reuse `_create`, `_headers`, `_run`, `_logs`,
  `_only_log`, `_log_count`, `_SECRET_KEYS`.

# Decisions (design rulings to confirm at Gate 1)

- **Route shape = the ical sub-resource verb-pair, NOT a nullable `PATCH /tokens/{name}`.** Legacy
  overloaded one `PATCH /tokens/:name` (webhook + scopes + expiry); the FastAPI port already split
  scopes into its own `PATCH /tokens/{name}` (`agent_tokens.py:79`), so reusing that body would
  re-merge concerns the port deliberately separated. `PUT` (idempotent set/replace of the single
  webhook slot) + `DELETE` (clear) mirrors `POST`/`DELETE /tokens/{name}/ical-token` 1:1. **PUT
  over POST** for set because webhook-set is value-idempotent (one slot, repeating converges),
  whereas ical-create rotates a fresh random alias.
- **The `whs_` secret is stored RECOVERABLE (plaintext-at-rest), NOT hashed** — a deliberate,
  correct departure from the hash-only rule that governs the `foc_` token and the iCal alias.
  Rationale: the server itself is the HMAC signer at delivery (legacy `ai-agent-webhook.ts:149-152`,
  `createHmac("sha256", webhookSecret)`), so it must re-read the secret to recompute
  `X-Focal-Signature` on every send. It is a per-agent HMAC key (not a bearer credential), and it is
  never returned on reads. `generate_webhook_secret()` therefore returns the raw string only (no
  hash tuple). **The honest residual threat (see Risks):** `webhook_url` and `webhook_secret`
  co-reside in the same row, both plaintext, so a DB-read compromise yields a forgeable, correctly
  signed delivery to the agent's own URL. Confidentiality rests on Postgres at-rest encryption of
  whichever managed engine holds `focal.*` (per this repo, dev/migrations run on local Docker /
  Railway PG; Supabase is the auth/JWKS layer, **not** necessarily the at-rest owner of this
  column). Application-layer encryption of the secret is explicitly **out of scope** for this slice;
  named here so the tradeoff is conscious, not assumed.
- **Trimming = legacy `.trim()`, in the SERVICE.** `url = payload.webhook_url.strip()` runs before
  both `validate_webhook_url` and the no-op compare, and the **stored** value is the stripped `url`.
  This is load-bearing for idempotency: the slice-1 validator does **not** strip surrounding
  whitespace (`webhook.py` allows 0x20), so without trimming, `"https://x/ "` (trailing space) would
  pass `urlparse`, store verbatim, and a clean re-PUT of `"https://x/"` would mismatch `==` → rotate
  the secret → silently break the agent's stored `X-Focal-Signature` verification. Pinned by a test
  that re-PUTs the same URL with a trailing space and asserts the **stored** secret is byte-identical
  and no second audit row is written.
- **Empty/whitespace-only PUT body → 422, NOT a clear.** Legacy mapped `""`/`"   "` (post-`.trim()`)
  to `null` → clear via the overloaded PATCH. The port routes clearing through `DELETE`, so a
  whitespace-only `PUT` body raises `ValidationError("webhookUrl must not be empty; use DELETE to
  clear")` (422) rather than silently clearing. This is a **deliberate divergence from legacy**
  (PUT/DELETE separation over legacy's nullable-PATCH) — **flagged for the reviewer.** (A
  non-whitespace empty string `""` is also caught by `min_length=1` at the Pydantic layer → 422
  `validation_error`; the service `.strip()` guard catches the whitespace-only case that
  `min_length` lets through.)
- **Idempotency no-op is load-bearing (the agent-breaking footgun).** When the normalized submitted
  URL equals the stored URL, the service performs **zero ORM mutation** — do **not** regenerate the
  secret, do **not** commit, do **not** log — and returns success with `webhookSecret: null`.
  Re-rotating the secret without a URL change would silently break the agent's already-stored
  `X-Focal-Signature` verification with no error surfaced anywhere (legacy comment,
  `ai-agent.ts:521-525`). The no-op branch only fires when `token.webhook_url` is a non-null string
  (input is `min_length=1` and trimmed-non-empty, never null), so a null-vs-null no-op is
  impossible — `DELETE` is the only clear path. Pinned by a test asserting the **stored** secret is
  byte-identical across a same-URL resubmit.
- **Clearing the URL clears the secret AND zeroes the fail-count.** `DELETE` sets
  `webhook_url=None`, `webhook_secret=None`, **and** `webhook_fail_count=0` together — a dangling
  secret with no URL is dead key material (legacy `ai-agent.ts:528,532`), and a cleared slot carries
  no failure history.
- **Set zeroes `webhook_fail_count` on a URL change.** The rotate-on-change path also sets
  `token.webhook_fail_count = 0`, so a live `(url, secret)` pair always starts with a clean
  delivery-failure budget. This is a **deliberate, minor divergence from legacy's set-path** (legacy
  reset the counter only on its delivery-side auto-disable, `ai-agent-webhook.ts:194`, not on the
  PATCH set). Rationale: this slice owns the write that creates the secret, so it owns the column's
  invariant; leaving a stale non-zero count would let slice-3 delivery immediately re-trip the
  4xx-disable threshold and tear down a freshly-set webhook with no error surface. The reset is one
  line and belongs with the write. The slice-3 read/increment/auto-disable logic is still out of
  scope. **Flagged for the reviewer** as a divergence from strict legacy parity.
- **SSRF validation in the SERVICE, single layer, after `_require` and after `.strip()`.** Call
  `validate_webhook_url(url)` (the shipped slice-1 guard) before mutation; map a non-`None` message
  to the typed `ValidationError`. Not a Pydantic `field_validator` — keeping it in one place avoids
  double-validation and lets the service order ownership before validation (below). The validator
  receives the trimmed `url` (the validator itself handles control-byte / IDNA / non-canonical-IPv4
  attacks; trimming only strips the surrounding ASCII whitespace legacy also stripped).
- **Invalid/SSRF URL → 422 (`ValidationError`, code `validation_error`), NOT legacy 400.** The
  port's typed-error taxonomy uses `ValidationError` (422, `errors.py:50`) for "body parsed but a
  single field is semantically invalid"; legacy's 400 was bound to the forbidden agent `{ok:false}`
  envelope. **Acknowledged nuance:** `errors.py` is **not** uniformly "422 for invalid value" — it
  also carries 400-coded domain errors (`DuplicateSphereNameError`, `SimilarSphereNameError`,
  `ParentProjectNotFoundError`, `RelatedRecordNotFoundError`). Webhook-URL rejection follows the
  422 `ValidationError` path (not a bespoke 400 code) because it is a single-field body validation,
  not a cross-entity domain conflict. **Flagged for the reviewer:** this is the one genuine
  divergence from legacy parity — if strict 400-parity is mandated, `ValidationError(msg,
  status_code=400)` overrides without a new class. No bespoke `WebhookUrlError` class.
- **Ownership before validation (a deliberate divergence from legacy order).** `_require` (404)
  runs **before** `.strip()`/`validate_webhook_url`, so a cross-tenant/missing-token request returns
  404 regardless of URL validity and never leaks validation feedback (or timing) to a non-owner.
  Legacy validated first then 404'd (`ai-agent.ts:506→517`); the port reorders for the
  non-owner-leak reason. **Flagged for the reviewer.** Pinned by a cross-tenant test that sends an
  **invalid/SSRF** body and asserts 404 (not 422).
- **Audit asymmetry is intentional.** `PUT` is **change-only** (the no-op is silent) because
  re-rotation is the footgun. `DELETE` audits **only an actual clear** — an already-null `DELETE` is
  a silent 204, matching legacy's null→null short-circuit (`ai-agent.ts:521-525`). Both paths
  therefore honour "duplicate write → no second audit". `details` carries `{"removed": bool}` only,
  never the secret, never the URL — both would persist to `ai_agent_logs` (and the structlog
  drain → Loki).
- **Failure envelope = `{error:{code,message}}` via the typed `AppError` path.** These are
  JWT-management endpoints — `NotFoundError`/`ValidationError` only, never raw `HTTPException`,
  never `AgentApiError`/the `{ok:false}` agent envelope.
- **Concurrent same-URL write is last-writer-wins (accepted, documented).** No row lock / no
  `WHERE webhook_secret = :prev` guard — two near-simultaneous changed-URL PUTs each generate a
  distinct secret and the second commit wins, so the secret returned to the first caller may not be
  the persisted one. Legacy had the identical gap, so this is **not a parity regression**; a
  control-plane PUT serializing at the client is the accepted tradeoff. Named in Risks rather than
  silently relied upon. Adding `SELECT … FOR UPDATE` is out of scope for this slice.

# Out of scope

- **Slice 3 (delivery):** `notifyAgent`/`fireWebhook`, HMAC signing + the `X-Focal-Signature`
  header, retries, the `webhook_fail_count` **read / increment / 4xx-auto-disable** logic (this
  slice only *zeroes* the counter on set/clear, never reads or increments it), the `sanitize_*`
  payload subsets, the event triggers, and the **connect-time IP / DNS-rebinding** SSRF re-check
  (the slice-1 validator is host-string-only — no DNS — by design). Any clear-time reset slice 3
  also needs is owned there.
- **Application-layer encryption** of `webhook_secret` (KMS/Fernet decrypt-at-sign) — named in
  Decisions/Risks as a conscious deferral; this slice stores the secret recoverable in plaintext.
- **Concurrency hardening** (`SELECT … FOR UPDATE` / optimistic compare-and-set on the secret).
- No new migration (`webhook_url`/`webhook_secret`/`webhook_fail_count` already exist on head
  `acb242a1f541`); no change to `AgentTokenRead`/`AgentTokenCreated`, the scopes `PATCH`, or any
  other endpoint; no Redis rate-limit backend.

# Acceptance criteria

- [ ] `PUT /tokens/{name}/webhook` with a valid `https://…` URL on an owned token → 200 with
      `webhookUrl == <url>` and `webhookSecret` matching `^whs_[0-9a-f]{48}$` (shown once); the row's
      `webhook_url` and `webhook_secret` persist (the stored secret equals the returned value) and
      `webhook_fail_count == 0`; one `WEBHOOK_UPDATED` audit row with `level == "info"` and
      `details == {"removed": False}` (strict `==`, so no stray secret/url key can be present).
- [ ] **Idempotent same-URL re-PUT** → 200 with `webhookSecret` **null**, `'webhookSecret'` present
      in the JSON body (key-with-null, not omitted), the **stored** secret byte-identical to the
      first set (HMAC key stable), and **no** second `WEBHOOK_UPDATED` row.
- [ ] **Same-URL re-PUT differing only by surrounding whitespace** (e.g. `"<url> "`) → identical to
      the no-op above: 200, `webhookSecret` null, **stored** secret byte-identical, no second audit
      row (proves normalization, not byte-equality, drives the no-op).
- [ ] **Changed-URL PUT resets a *seeded non-zero* fail-count** → after the set, seed
      `webhook_fail_count` to a non-zero value (a raw-SQL `_set_fail_count` helper), then the
      changed-URL `PUT` → 200 with a new `whs_<48hex>` secret (`!=` the first), persisted, and
      `webhook_fail_count == 0` — the assertion must start from a non-zero count so it proves the
      rotate path *reset* it (a default-zero row would pass even if the reset were forgotten); one
      further `WEBHOOK_UPDATED` row. A single sequential test (set → same-URL → changed-URL) asserts
      the `WEBHOOK_UPDATED` count is `1 → 1 → 2`.
- [ ] **Set trims on first write** → `PUT` a URL with surrounding whitespace on a fresh token → 200
      with the response and the **stored** `webhook_url` both equal to the trimmed URL (proves
      `.strip()` runs before the write, so a later clean re-PUT is a true no-op).
- [ ] **Empty / whitespace-only PUT body** (`""` and `"   "`) → 422 `validation_error`, **nothing
      written** (`webhook_url`/`webhook_secret` stay null), **no** audit row.
- [ ] **Invalid/SSRF URL** (parametrized: `http://example.com`, `https://localhost/`,
      `https://127.0.0.1/`, and an **embedded** control-byte form `"https://127.0.0.1\t.example.com/"`
      — the tab is mid-string, so the service `.strip()` cannot remove it; it reaches the validator,
      which rejects any raw control byte → 422) → 422 with `error.code == "validation_error"`,
      **nothing written**, and **no** audit row. (Slice-1 `tests/test_webhook_ssrf.py` exhausts the
      validator; these only prove the 422 wiring and that the `.strip()` only trims surrounding
      whitespace — an embedded control byte still reaches the validator, no pre-strip bypass.)
- [ ] `DELETE /tokens/{name}/webhook` after a set (**with a seeded non-zero `webhook_fail_count`**)
      → 204; **all three** of `webhook_url`, `webhook_secret`, `webhook_fail_count` become null/0 —
      the count reset is proven from a non-zero seed, not a default-zero row; one `WEBHOOK_UPDATED`
      row with `details == {"removed": True}`.
- [ ] **Idempotent DELETE on an already-null webhook** → 204 and **zero** `WEBHOOK_UPDATED` rows
      (matching legacy's silent null→null short-circuit).
- [ ] `PUT`/`DELETE` on a missing or another user's token → 404 (`not_found`) with **no** audit row.
      The cross-tenant leg **seeds the owner's webhook first** (a populated `(url, secret, non-zero
      fail_count)` on `user-a`'s token), then `user-b` (owning no such token) `PUT`/`DELETE`s it →
      404 and the owner's full `(webhook_url, webhook_secret, webhook_fail_count)` tuple is
      byte-for-byte unchanged — proving an unscoped clear/write cannot wipe or mutate another tenant's
      webhook. A cross-tenant `PUT` with an **invalid/SSRF** body (e.g. `https://127.0.0.1/`) also →
      404 (not 422), proving ownership is checked strictly before validation. An **unauthenticated**
      `PUT` (with a valid body) / `DELETE` → 401 (`auth_required`) with no audit row.
- [ ] `GET /tokens` after a set exposes `webhookUrl` but **never** `webhookSecret`/`webhook_secret`
      (extend the `_SECRET_KEYS` absence assertion); the secret never appears on any read.
- [ ] `make verify` green; no migration.

# Verification commands

```sh
cd superapp/apps/focal/server && DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev make verify
```

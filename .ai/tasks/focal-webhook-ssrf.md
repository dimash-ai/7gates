# Goal

Port the focal **webhook URL SSRF validator** as a pure domain function (Phase 8, webhook slice 1 of 3):
`validate_webhook_url(raw) -> str | None` — `None` if the URL is a safe public HTTPS endpoint, else a
human error message. This is the security core both the webhook-URL CRUD (slice 2) and the delivery
(slice 3) rely on. Legacy: `ai-agent.ts` `validateWebhookUrl`.

# Scope

- **`app/domain/webhook.py`** (pure — no HTTP, no DB, no DNS):
  - `validate_webhook_url(raw: str) -> str | None`: parse with `urlparse`; reject —
    - a URL that doesn't parse or has no host → `"Invalid webhookUrl"`;
    - `scheme != "https"` → `"webhookUrl must use HTTPS"`;
    - host (lowercased) `== "localhost"` or ends with `.local` / `.internal` →
      `"webhookUrl must not target an internal host"`;
    - host that resolves to an **IP literal** (in any form) in a private/reserved range → `"webhookUrl
      must not target a private IP address"`. Detect the IP two ways: `ipaddress.ip_address(host)` for a
      canonical IPv4/IPv6, **and** `socket.inet_aton(host)` (pure, no DNS) to catch **non-canonical
      IPv4** — decimal (`2130706433`), hex (`0x7f000001`), octal/zero-padded (`127.000.000.001`), and
      short (`127.1`) forms that the legacy regex + `ipaddress` both miss (they resolve to `127.0.0.1` →
      an SSRF bypass). Whichever yields an IP, reject `is_loopback`/`is_private`/`is_link_local`/
      `is_reserved`/`is_unspecified`/`is_multicast`, the **CGNAT** `100.64.0.0/10`, and an **IPv4-mapped
      IPv6** whose embedded IPv4 is private (`ip.ipv4_mapped`).
  - else → `None` (allowed).
- **Tests** (`tests/test_webhook_ssrf.py`).

# Decisions (design rulings to confirm at Gate 1)

- **Pure domain, no consumers yet** — the validator ships unused this slice (the webhook-URL CRUD that
  calls it is slice 2; the delivery `redirect:"error"` second layer is slice 3). Reviewable + exhaustively
  unit-tested in isolation, like the iCal serializer cut.
- **`ipaddress` + `socket.inet_aton`, not the legacy regex** — a faithful-**intent** port that closes a
  real bypass: the legacy string/regex (and `ipaddress` alone) only catch *canonical* dotted IPv4, so
  `2130706433` / `0x7f000001` / `127.1` / `127.000.000.001` would slip through yet resolve to
  `127.0.0.1`. `inet_aton` (a pure string→bytes parse, no network) normalizes those non-canonical forms;
  `ipaddress` then classifies, covering the legacy's blocked set (127/8, 10/8, 172.16/12, 192.168/16,
  169.254/16, 0.0.0.0, `::1`, `fe80::/10`, `fc00::/7`) plus CGNAT `100.64/10` and the IPv4-mapped
  `::ffff:` bypass.
- **Host-string validation only (documented limitation, matches the legacy)** — it does **not** resolve
  DNS, so a *public domain that resolves to a private IP* is not caught here, and `redirect:"error"`
  alone does not mitigate that. **Slice 3 must add a named connect-time IP validation** (resolve + check
  the connected IP, or pin the socket) before delivery ships; this slice is the first filter. HTTPS is
  required, limiting plaintext-internal exfiltration.

# Out of scope

- The webhook-URL CRUD (`PUT`/`DELETE /tokens/{name}/webhook`, the `whs_` secret, `WEBHOOK_UPDATED`) —
  slice 2; the delivery (`notifyAgent`/`fireWebhook`, HMAC, retries, fail-count, the `sanitize_*`
  field subsets, the triggers) — slice 3; DNS resolution / connect-time pinning.

# Acceptance criteria

- [ ] A normal public `https://hooks.example.com/x` → `None` (allowed); an `http://…` → the HTTPS error;
      an unparseable string and a URL with no host → the invalid error.
- [ ] `https://localhost/…`, `https://x.local/…`, `https://y.internal/…` → the internal-host error.
- [ ] Each legacy-blocked **IPv4** literal is rejected — `127.0.0.1`, `10.0.0.1`, `172.16.0.1`,
      `192.168.1.1`, `169.254.169.254` (cloud metadata), `0.0.0.0`, `100.64.0.1` (CGNAT) → the private-IP
      error; a public IPv4 literal (`https://8.8.8.8/…`) is allowed.
- [ ] **Non-canonical IPv4** forms that resolve to loopback are rejected — `https://2130706433/`,
      `https://0x7f000001/`, `https://127.1/`, `https://127.000.000.001/` → the private-IP error.
- [ ] **Boundary** cases pin the ranges — `172.15.0.1` and `172.32.0.1` are **allowed** while
      `172.16.0.1` / `172.31.255.255` are blocked; `100.63.255.255` and `100.128.0.1` are **allowed**
      while `100.64.0.1` / `100.127.255.255` are blocked.
- [ ] Each legacy-blocked **IPv6** literal (in brackets) is rejected — `[::1]`, `[fe80::1]`, `[fc00::1]`,
      `[fd00::1]`, and an IPv4-mapped `[::ffff:127.0.0.1]` → the private-IP error.
- [ ] `make verify` green; no migration.

# Verification commands

```sh
cd superapp/apps/focal/server && DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev make verify
```

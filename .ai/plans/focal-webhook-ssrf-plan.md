# Summary

Implement `focal-webhook-ssrf` (Phase 8, webhook slice 1/3): a pure `app/domain/webhook.py`
`validate_webhook_url(raw) -> str | None` SSRF guard. No HTTP/DB/DNS. The webhook-URL CRUD (slice 2) and
delivery (slice 3) consume it. Task: [focal-webhook-ssrf.md](../tasks/focal-webhook-ssrf.md). Legacy:
`ai-agent.ts` `validateWebhookUrl`.

## Decisions (design + the Gate-1 rulings)

- **`app/domain/webhook.py`** (pure):
  - `validate_webhook_url(raw) -> str | None`: `urlparse(raw)` (on `ValueError` → `"Invalid webhookUrl"`);
    `scheme != "https"` → `"webhookUrl must use HTTPS"`; **force port validation** (`try: parsed.port`
    `except ValueError: return "Invalid webhookUrl"` — `urlparse` is lenient and only validates the port
    on access, unlike the legacy `new URL`); `host = (parsed.hostname or "").lower().rstrip(".")` —
    **strip the trailing root dot(s)** so `localhost.` / `x.local.` can't bypass the blocklist — empty →
    `"Invalid webhookUrl"`; `host == "localhost"` or `endswith(".local"/".internal")` → `"webhookUrl must
    not target an internal host"`; `ip = _as_ip(host)` and `_is_blocked_ip(ip)` → `"webhookUrl must not
    target a private IP address"`; else `None`.
  - `_as_ip(host) -> IPv4Address | IPv6Address | None`: try `ipaddress.ip_address(host)` (canonical
    IPv4/IPv6); on `ValueError`, try `socket.inet_aton(host)` (catches non-canonical IPv4 — decimal/hex/
    octal/short) and return `ipaddress.IPv4Address(packed)`; on `OSError` → `None` (a real hostname).
  - `_is_blocked_ip(ip) -> bool`: `is_loopback or is_private or is_link_local or is_reserved or
    is_unspecified or is_multicast` → True; an `IPv6Address` with `ipv4_mapped` → recurse on the mapped
    v4; an `IPv4Address` in `_CGNAT = ip_network("100.64.0.0/10")` → True; else False.
- **Pure, no consumers yet** — ships unused; reviewable in isolation with exhaustive unit tests (the
  serializer/SSRF-core cut). `inet_aton` is a string→bytes parse — **no network**.
- **Documented limitation** — host-string only (no DNS); connect-time IP validation is slice 3's named
  requirement.

# Files to change

| path | change | why |
|------|--------|-----|
| `app/domain/webhook.py` | add | the pure SSRF validator |
| `tests/test_webhook_ssrf.py` | add | exhaustive validator unit tests |

# Implementation slices

1. **The module.** *Verify:* unit tests + ruff/mypy.
2. **Tests.** *Verify:* full `make verify`.

# Tests (`tests/test_webhook_ssrf.py`, pure — no DB)

- **allowed:** `https://hooks.example.com/x` and `https://8.8.8.8/` → `None`.
- **scheme:** `http://hooks.example.com` → the message contains `HTTPS`.
- **invalid:** `"not a url"`, `"https://"` (no host), and `"https://example.com:bad/"` (a malformed port
  that `urlparse` accepts until `.port` is read) → the message contains `Invalid`.
- **internal hosts (parametrized):** `https://localhost/`, `https://x.local/`, `https://y.internal/`, and
  their **absolute (trailing-dot)** forms `https://localhost./`, `https://x.local./`,
  `https://y.internal./` → the message contains `internal host` (the trailing-dot bypass is closed).
- **IPv4 private (parametrized):** `127.0.0.1`, `10.0.0.1`, `172.16.0.1`, `192.168.1.1`,
  `169.254.169.254`, `0.0.0.0`, `100.64.0.1` → the message contains `private IP`.
- **non-canonical IPv4 (parametrized):** `2130706433`, `0x7f000001`, `127.1`, `127.000.000.001` → the
  message contains `private IP` (the bypass-closing cases).
- **boundary allowed (parametrized):** `172.15.0.1`, `172.32.0.1`, `100.63.255.255`, `100.128.0.1` →
  `None`.
- **boundary blocked (parametrized):** `172.16.0.1`, `172.31.255.255`, `100.64.0.1`, `100.127.255.255`
  → the message contains `private IP`.
- **IPv6 (parametrized, bracketed):** `[::1]`, `[fe80::1]`, `[fe90::1]`, `[febf::1]` (the wider
  `fe80::/10` link-local range), `[fc00::1]`, `[fd00::1]`, `[::ffff:127.0.0.1]` (IPv4-mapped loopback) →
  the message contains `private IP`.

# Risks

- **Pure + deterministic** — no network, no DB; `inet_aton` is offline string parsing.
- **Security completeness** — host-string validation closes the literal-IP (incl. non-canonical)
  vectors; DNS-rebinding / domain→private-IP remains for slice 3's connect-time check (documented, named).
- **No migration / no schema change**; no consumer yet.

# Scope check

- [x] Matches the task (pure SSRF validator; CRUD + delivery deferred).
- [x] Reviewable in one pass — one pure module + exhaustive unit tests.
- [x] Size smell: a single self-contained domain module.

# Out of scope

The webhook-URL CRUD (slice 2); the delivery / `notifyAgent` / `sanitize_*` / triggers (slice 3); DNS
resolution + connect-time IP pinning (slice 3).

# EXAMPLE — NOT A REAL TASK

> Worked example for an imaginary feature (`auth-refresh`) showing what a good task
> definition looks like. In real use this file lives at `.ai/tasks/<feature>.md`
> (here it would be `.ai/tasks/auth-refresh.md`); it is kept under `examples/` only to
> illustrate. Do not implement it.

# Goal

Keep users signed in without interruption by refreshing the short-lived access token in
the background before it expires, using the existing long-lived refresh token. No visible
re-login, no failed requests due to an expired token under normal conditions.

# Scope

- Add a token-refresh client that exchanges a valid refresh token for a new access token.
- Schedule a refresh shortly before the access token's `exp` (e.g. at 80% of its lifetime).
- Retry a refresh once on transient network failure, then surface a single auth error.
- Persist the new access token and expiry to the existing session store.
- Emit a structured log line on each successful and failed refresh.

# Out of scope

- Changing the login or logout flows.
- Refresh-token rotation or revocation server-side changes.
- UI/UX changes beyond not forcing re-login.
- Multi-tab refresh coordination (tracked as a follow-up).

# Acceptance criteria

- [ ] A valid session refreshes silently before expiry; in-flight requests never see a 401
      caused by an expired-but-refreshable token.
- [ ] An expired or invalid refresh token results in exactly one auth error and a clean
      redirect to login (no retry storm).
- [ ] The new access token and its expiry are written to the session store atomically.
- [ ] Each refresh attempt logs outcome (`success` / `failure`), reason on failure, and the
      next scheduled refresh time. No token values are logged.
- [ ] New unit tests cover: successful refresh, single-retry-then-fail, and invalid-token paths.

# Verification commands

```
make verify
```

(Equivalently: `make test`, `make lint`, `make typecheck`, `make build`.)

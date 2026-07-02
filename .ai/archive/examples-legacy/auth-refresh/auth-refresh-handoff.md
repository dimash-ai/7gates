# EXAMPLE — NOT A REAL HANDOFF

> This is a worked example of a final handoff for the imaginary `auth-refresh` feature,
> assembled at Stage 6 and used for the Stage 7 release after Codex approves the PR text.

# Final handoff: auth-refresh

## Status

- All plan slices implemented (Slices 1–3).
- `/gate-code` APPROVED for each slice (see `reviews/03-implementation-review-*.md`).
- `/gate-test` APPROVED.
- Awaiting `/gate-final` APPROVED before release.

## Verification output

```
$ make verify
== test ==      PASS (42 passed, 0 failed)
== lint ==      PASS (0 problems)
== typecheck == PASS (0 errors)
== build ==     PASS
verify: OK
```

## Regression check

- Login and logout flows unchanged and re-run green (out of scope, verified untouched).
- No new dependencies added.
- Session-store write path is now atomic; existing readers unaffected.

---

## PR description

### Title

auth-refresh: silently refresh access tokens before expiry

### Summary

Adds background refresh of the short-lived access token using the existing refresh token,
so users stay signed in without interruption and in-flight requests no longer race an
expired-but-refreshable token.

### What changed

- New `refreshAccessToken()` client that exchanges a refresh token for a new access token
  and returns `{ accessToken, expiresAt }` (typed `AuthRefreshError` on failure).
- New `TokenRefresher` that schedules a refresh at 80% of the access token's lifetime
  (clamped to a minimum lead time), persists the result atomically to the session store,
  and reschedules.
- Single-flight refresh with transparent retry of a request that 401s during the refresh
  window; one retry on transient failure, then a single terminal auth error and a clean
  redirect to login.
- Structured logging per attempt (outcome, failure reason, next refresh time). No token
  material is ever logged.

### Acceptance criteria

- [x] Valid sessions refresh silently before expiry; no 401s from refreshable tokens.
- [x] Invalid/expired refresh token → exactly one auth error, clean redirect, no retry storm.
- [x] New access token + expiry written atomically to the session store.
- [x] Each attempt logged with outcome and next refresh time; no token values logged.
- [x] Unit tests: successful refresh, single-retry-then-fail, invalid-token, and the
      straddling-request concurrency case.

### Testing

- `make verify` passes (test, lint, typecheck, build) — output above.
- Tests use a fake clock to assert scheduling and the refresh-window race deterministically.

### Out of scope / follow-ups

- Multi-tab refresh coordination (tracked separately).
- Refresh-token rotation / server-side revocation changes.

### Rollback

Feature is additive behind the existing auth client; revert the new modules to restore
prior behavior.

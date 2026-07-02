# EXAMPLE — NOT A REAL PLAN

> This is a worked example for the imaginary `auth-refresh` feature, showing what a good
> implementation plan looks like. Do not implement it.

# Plan: auth-refresh

## Approach

Introduce a small `TokenRefresher` that wraps the existing auth client. It computes the
next refresh time from the access token's `exp` claim, schedules a single timer, performs
the exchange, and writes the result back to the session store. Failures are funneled into
one retry, then a single terminal auth error that the existing router already handles.

## Slices

Each slice is independently reviewable (Stage 3 → Stage 4 loop) and leaves the tree green.

### Slice 1 — Refresh client (pure exchange)
- Add `refreshAccessToken(refreshToken)` that calls the token endpoint and returns
  `{ accessToken, expiresAt }` or throws a typed `AuthRefreshError`.
- No scheduling, no storage yet.
- Checks: `make test lint typecheck`.

### Slice 2 — Scheduling + storage
- Compute next refresh at 80% of token lifetime from `exp`.
- On fire: call Slice 1's client, persist to the session store atomically, reschedule.
- Checks: `make test lint typecheck`.

### Slice 3 — Retry + terminal error + logging
- One retry on transient/network failure; on second failure emit a single auth error and
  stop the schedule.
- Structured log line per attempt (outcome, failure reason, next refresh time; never the token).
- Checks: `make verify`.

## Files touched (anticipated)

- `auth/refresh_client.*` (new)
- `auth/token_refresher.*` (new)
- `auth/session_store.*` (small write API, if not already atomic)
- `auth/__tests__/*` (new tests)

## Test strategy

- Unit: successful refresh; single-retry-then-fail; invalid refresh token.
- Use a fake clock to assert the 80%-of-lifetime scheduling without real timers.
- Assert no token material appears in emitted logs.

## Risks / rollback

- Risk: clock skew triggers early/late refresh. Mitigation: derive timing from server `exp`
  and clamp to a minimum lead time.
- Rollback: feature is additive behind the existing auth client; revert the new modules to
  fall back to current behavior.

## Verification

```
make verify
```

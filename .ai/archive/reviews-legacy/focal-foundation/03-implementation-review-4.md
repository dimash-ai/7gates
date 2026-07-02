# Codex Review Verdict

Score: 8.7 / 10
Status: BLOCKED

## Reason
Scope matches slice 3 and the three round-1 fixes are mostly addressed. One edge case leaves the `app_metadata` malformed-token fix incomplete: falsey non-object values are still accepted.

## Must Fix
- `superapp/apps/focal/server/app/auth.py:83` uses `claims.get("app_metadata") or {}`, so a valid signed token with `app_metadata` of `[]`, `""`, `false`, or `0` is converted to `{}` and accepted as `tier="free"` instead of raising `AuthRequiredError(code="invalid_token")`. This contradicts the stated round-2 fix and the comment at `superapp/apps/focal/server/app/auth.py:84-87`. Extend `superapp/apps/focal/server/tests/test_auth.py:144` to cover falsey non-object values too.

## Should Consider
None

## Tests Reviewed
Inspected staged diff via `git -C superapp --no-pager diff --cached -- apps/focal/server` and `git -C superapp status`; read plan/task/rubric/CLAUDE and the staged auth/tests/config/model files. Did not rerun `make verify` in this read-only sandbox.

## Release Risk
Medium

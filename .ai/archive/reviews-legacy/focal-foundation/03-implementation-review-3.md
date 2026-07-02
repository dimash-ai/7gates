# Codex Review Verdict

Score: 7.8 / 10
Status: BLOCKED

## Reason
Scope matches Slice 3 and the core JWT checks are largely correct, but the heal path violates the task's no-PII logging and best-effort resilience requirements. There is also a fail-closed gap after JWT decode for malformed `app_metadata`.

## Must Fix
- `apps/focal/server/app/auth.py:105` logs `error=str(exc)` from a DB insert that includes `user.email` at `apps/focal/server/app/auth.py:97`; SQLAlchemy `StatementError.__str__` includes bound parameters, so heal failures can log email PII.
- `apps/focal/server/app/auth.py:104` awaits `db.rollback()` inside the DB-error handler without guarding rollback failure; if rollback raises after a broken DB connection, `heal_user_identity` can still 5xx a valid request.
- `apps/focal/server/app/auth.py:86` assumes `app_metadata` is a dict after leaving the verifier `try`; a signed token with non-object `app_metadata` raises `AttributeError` instead of `AuthRequiredError(code="invalid_token")`.

## Should Consider
None

## Tests Reviewed
Inspected `git -C superapp --no-pager diff --cached -- apps/focal/server`, `git -C superapp status`, task/plan/rubric/CLAUDE/AUTH_FLOWS, and `apps/focal/server/tests/test_auth.py`. Ran `git -C superapp --no-pager diff --cached --check -- apps/focal/server` and a local SQLAlchemy `StatementError` string check; did not rerun `make verify` in the read-only sandbox.

## Release Risk
Medium

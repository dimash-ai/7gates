# Codex Review Verdict

Score: 8.4 / 10
Status: BLOCKED

## Reason
The default production path is mostly correct: demo auth is off by default, `get_current_user_id` now delegates to real auth, and direct auth tests cover demo enabled/disabled behavior. The blocker is that the documented standalone demo fallback is not exercised through FastAPI and can fail before reaching the demo branch when `DATABASE_URL` is absent.

## Must Fix
- `get_current_user()` still requires `db: AsyncSession = Depends(get_db)` before its demo branch can run (`superapp/apps/focal/server/app/auth.py:123`), while `get_db()` unconditionally builds a session from `database_url` (`superapp/apps/focal/server/app/db.py:29`). That breaks the advertised no-DB/in-memory demo path. Add a route-level test for demo auth with empty `DATABASE_URL` and make that path skip DB heal or otherwise require/document DB for standalone dev.

## Should Consider
- Align the flag naming: the plan/comment names `FOCAL_DEMO_AUTH`, but `Settings` only defines `demo_auth_enabled` (no alias), so the effective env var is `DEMO_AUTH_ENABLED`.
- Add a default-route auth test for `/api/tags` because both tags suites override `get_current_user_id` and therefore do not prove the real route dependency rejects `X-Demo-User-Id` when demo auth is disabled.

## Tests Reviewed
Inspected the staged diff, status, plan/task/rubric/CLAUDE, auth/config/deps/tags/db code, and auth/tags tests. Did not run pytest (pydantic unavailable in the read-only sandbox).

## Release Risk
Medium

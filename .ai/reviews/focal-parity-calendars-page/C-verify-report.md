**Verification Report**

I ran the required diff/status first. The worktree started clean; after verification I changed only [test_google_integration_db.py](/Users/allosta/Desktop/allosta/superapp/.worktrees/focal-parity-calendars-page/apps/focal/server/tests/test_google_integration_db.py:1). `git diff --check` is clean. The prompted task file `.ai/tasks/focal-parity-calendars-page.md` is not present in `/Users/allosta/Desktop/allosta/.ai/tasks`; I verified against the prompt and [focal-parity-calendars-page-design.md](/Users/allosta/Desktop/allosta/.ai/design/focal-parity-calendars-page-design.md:1).

**What I Scrutinized**

I checked the disconnect IDOR closure: [google_integration.py](/Users/allosta/Desktop/allosta/superapp/.worktrees/focal-parity-calendars-page/apps/focal/server/app/services/google_integration.py:217) resolves the calendar before mutation, returns 404 for missing, checks `calendar.user_id != user_id` before `delete_token`, and only then clears the binding/settings.

I checked participant UI security: [CalendarsPage.tsx](/Users/allosta/Desktop/allosta/superapp/.worktrees/focal-parity-calendars-page/apps/focal/client/src/features/calendars/CalendarsPage.tsx:476) gates invite controls on `isOwner`, [line 507](/Users/allosta/Desktop/allosta/superapp/.worktrees/focal-parity-calendars-page/apps/focal/client/src/features/calendars/CalendarsPage.tsx:507) gates role edits, [line 618](/Users/allosta/Desktop/allosta/superapp/.worktrees/focal-parity-calendars-page/apps/focal/client/src/features/calendars/CalendarsPage.tsx:618) gates the Google section, and [line 1317](/Users/allosta/Desktop/allosta/superapp/.worktrees/focal-parity-calendars-page/apps/focal/client/src/features/calendars/CalendarsPage.tsx:1317) reuses `CalendarCard` for participating calendars with `isOwner={false}`.

I checked invite-code exposure: [shared_calendars.py](/Users/allosta/Desktop/allosta/superapp/.worktrees/focal-parity-calendars-page/apps/focal/server/app/services/shared_calendars.py:611) treats `invite_code` as a bearer token and [line 620](/Users/allosta/Desktop/allosta/superapp/.worktrees/focal-parity-calendars-page/apps/focal/server/app/services/shared_calendars.py:620) serializes it only when `include_invite_code` is true; owners get it on invite, joiners do not.

I checked identity sync and serializer flow: [identity_sync.py](/Users/allosta/Desktop/allosta/superapp/.worktrees/focal-parity-calendars-page/apps/focal/server/app/tasks/identity_sync.py:46) selects dirty users, [line 85](/Users/allosta/Desktop/allosta/superapp/.worktrees/focal-parity-calendars-page/apps/focal/server/app/tasks/identity_sync.py:85) uses `COALESCE` to avoid overwriting existing email/name data, and [shared_calendars.py](/Users/allosta/Desktop/allosta/superapp/.worktrees/focal-parity-calendars-page/apps/focal/server/app/services/shared_calendars.py:623) maps empty-string name sentinels back to `null`.

**Tests Added**

Added [test_shared_calendar_disconnect_participant_forbidden](/Users/allosta/Desktop/allosta/superapp/.worktrees/focal-parity-calendars-page/apps/focal/server/tests/test_google_integration_db.py:500): proves an accepted participant with viewer+ access still gets 403 and cannot clear the owner’s Google binding/token.

Added [test_shared_calendar_disconnect_missing_calendar_is_404](/Users/allosta/Desktop/allosta/superapp/.worktrees/focal-parity-calendars-page/apps/focal/server/tests/test_google_integration_db.py:545): proves a missing shared-calendar id maps to 404.

**Test Results**

`UV_CACHE_DIR=/private/tmp/uv-cache DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev uv run pytest ...` could not execute DB-backed assertions in this sandbox: asyncpg local socket connections to `localhost:5433` fail with `PermissionError: [Errno 1] Operation not permitted`. Focused attempted counts: disconnect run `7 errors`; identity/shared/ETL run `8 passed, 25 errors` where all errors were the same DB socket setup failure.

`UV_CACHE_DIR=/private/tmp/uv-cache uv run pytest tests/test_google_integration_db.py tests/test_identity_sync_db.py tests/test_shared_calendar_participants_db.py tests/test_etl_migrate_legacy.py -q`: `8 passed, 51 skipped, 1 warning`.

`pnpm exec vitest run`: failed in this sandbox with `[ERROR] fetch failed`.

`NODE_OPTIONS=--no-webstorage ./node_modules/.bin/vitest run src/features/calendars/CalendarsPage.test.tsx`: `29 passed`.

`NODE_OPTIONS=--no-webstorage ./node_modules/.bin/vitest run`: `1764 passed, 3 failed`, with the 3 failures all in the known pre-existing `TasksPage.test.tsx`.

**Conclusion**

No production-code defect requiring a gate-B stop surfaced in the code review pass. Verification is limited by sandbox restrictions for local Postgres and `pnpm exec`, but the changed calendar client tests pass, the full client suite only shows the known pre-existing TasksPage failures, and the added server authz tests collect cleanly when DB tests are skipped.

---

## Addendum (Opus, in-session): DB-backed tests re-run on real Postgres

GPT's sandbox could not reach local Postgres (asyncpg socket EPERM), so it left the DB-backed
assertions skipped. I re-ran the slice-affected server suites against the local Docker Postgres
(DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev), including GPT's two
newly-added authz tests:

- `uv run ruff check tests/test_google_integration_db.py` → All checks passed
- `uv run pytest tests/test_google_integration_db.py -k disconnect -q` → 7 passed (incl. the new
  `test_shared_calendar_disconnect_participant_forbidden` and `..._missing_calendar_is_404`)
- `uv run pytest test_google_integration_db + test_identity_sync_db + test_shared_calendar_participants_db + test_etl_migrate_legacy -q` → 59 passed

The two GPT-added tests prove: (1) a real accepted participant with viewer+ access still gets 403
on disconnect-google and the owner's binding/token is untouched (the IDOR is closed against a
genuine RBAC principal, not just a stranger); (2) a missing calendar id → 404.

## Gate-B fix after the release review (Opus, in-session)

The Opus release review BLOCKED (7.6) on one real, CI-breaking issue both the doer and GPT missed:
the new migration failed `ruff check .` (I001 un-sorted import block), which the `backend (focal)`
CI job runs. Fixed in-session: `ruff check --fix` grouped `from alembic import op` like every other
migration. Verified:
- `uv run ruff check .` (cwd apps/focal/server) → All checks passed (exit 0)
- `uv run ruff format --check .` → only `app/data_scope.py` flagged, which is NOT in this diff and
  is already format-broken on `feature/focal-migration` (proven: `git show base:…/data_scope.py`
  also "would reformat") → pre-existing, left untouched per Surgical Changes.
Re-running the release review to confirm the now-green state.

# Codex Review Verdict

Score: 8.7 / 10
Status: BLOCKED

## Reason
The changed surface is in scope and matches the planned files, with no migration, no raw `HTTPException`, and strong coverage for the main scoped update/delete behavior. However, single-occurrence override writes are read-then-insert rather than atomic upserts, so concurrent PATCH/DELETE requests can violate the unique override constraint and return an untyped 500.

## Must Fix
- `apps/focal/server/app/services/calendar.py:366` + `apps/focal/server/app/services/calendar.py:403`: `_update_single` selects for an existing override, then inserts when none was observed; with the unique `(recurring_event_id, occurrence_date)` constraint at `apps/focal/server/app/models/calendar.py:67`, two concurrent PATCHes for the same occurrence can both take the insert branch and one will fail at commit with `IntegrityError` instead of the required 200 enriched response.
- `apps/focal/server/app/services/calendar.py:535` + `apps/focal/server/app/services/calendar.py:545`: `_delete_single` has the same read-then-insert race for soft-delete overrides, so concurrent DELETE-single calls can produce an untyped 500 instead of a typed contract response.

## Should Consider
- Add a DELETE occurrence-id `occurrenceDate` precedence test; PATCH covers the shared resolver, but the task asked for PATCH/DELETE target precedence.
- The DB recurrence test module header still says override writes are a future slice; update it when touching that file next.

## Tests Reviewed
Inspected full diff for the listed files, task/approved plan, legacy contract excerpts, and grep sweeps for raw `HTTPException`, logging/secret terms, AI attribution, and ticket/spec IDs. `git diff --check -- apps/focal/server` passed; `make verify` and `alembic check` were not rerun in the read-only sandbox.

## Release Risk
Medium

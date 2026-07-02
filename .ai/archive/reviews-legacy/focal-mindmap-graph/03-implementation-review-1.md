# Codex Review Verdict

Score: 8.4 / 10
Status: BLOCKED

## Reason
Scope matches the mindmap backend slice and most contract paths are covered, but the core upsert implementation is not race-safe. Under concurrent creates for the same `(user_id, id)`, it can surface a raw DB integrity failure instead of the promised upsert behavior.

## Must Fix
- `apps/focal/server/app/services/mindmap.py:39` and `apps/focal/server/app/services/mindmap.py:87`: node and edge upserts do a select-then-insert. Two concurrent requests for the same `(user_id, id)` can both observe no row; one commits and the other raises an unhandled unique-constraint error. This violates the upsert contract, and for edges specifically misses the planned conflict path that updates style fields while preserving source/target. Use a DB-level `ON CONFLICT (user_id, id)` path or catch/retry the integrity conflict into the documented update behavior.

## Should Consider
- `apps/focal/server/tests/test_mindmap_db.py:102`: the test creates the same edge id for two users but only asserts node isolation. Add assertions that each user sees only their own edge, and that non-owned edge delete returns 404.

## Tests Reviewed
Ran `git -C superapp --no-pager diff --cached` and `git -C superapp status`. Inspected `.ai/tasks/focal-mindmap-graph.md`, `.ai/plans/focal-mindmap-graph-plan.md`, `.ai/checklists/scoring-rubric.md`, changed app files, migration, and DB/contract tests. Attempted `uv run pytest tests/test_migration.py -q -p no:cacheprovider`, but it could not run because the read-only sandbox blocked uv cache initialization at `/Users/allosta/.cache/uv`.

## Release Risk
Medium

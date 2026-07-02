# Codex Review Verdict

Score: 8.4 / 10
Status: BLOCKED

## Reason
The added tests cover most headline behavior, including composite-PK tenant isolation, node/edge upserts, batch ordering, dangling edges, and init shape. However, two acceptance-critical paths are not actually pinned: validation-error envelope shape and true transactional batch rollback.

## Must Fix
- `superapp/apps/focal/server/tests/test_mindmap_db.py:147`, `superapp/apps/focal/server/tests/test_mindmap_db.py:202`, and `superapp/apps/focal/server/tests/test_mindmap_db.py:235` only assert `422` status for mindmap validation failures. The task requires typed `{error:{code:"validation_error",message}}` envelopes; these tests would still pass if FastAPI returned its raw `{"detail": ...}` 422 body.
- `superapp/apps/focal/server/tests/test_mindmap_db.py:260` claims to prove batch atomic rollback, but the “bad” second entry is rejected by Pydantic before the endpoint/service runs because `BatchNode.id` is required at `superapp/apps/focal/server/app/schemas/mindmap.py:32`. This does not exercise the one-transaction rollback path in `MindmapService.batch_upsert_nodes`.

## Should Consider
- `superapp/apps/focal/server/tests/test_mindmap_db.py:172` verifies conflict updates for `strokeColor` only; the other style fields in the contract (`sourceHandle`, `targetHandle`, `edgeType`, `strokeWidth`, `strokeDasharray`, `hasArrow`) remain lightly covered.
- `superapp/apps/focal/server/tests/test_mindmap_db.py:308` covers ignored `userId`/unknown fields/body-id path-wins for node PUT only. Edge PUT, batch entries, and query `userId` are still unpinned.
- The captured verification output shows `make verify` green with 290 passed, but I did not see `uv run alembic check` output in `.ai/runs/focal-mindmap-graph-verify.txt`.

## Tests Reviewed
Read `.ai/runs/focal-mindmap-graph-verify.txt` showing `make verify` passed: ruff check, ruff format --check, mypy, and pytest with 290 passed. Ran `git -C superapp --no-pager diff --cached`. Inspected `superapp/apps/focal/server/tests/test_mindmap_db.py`, `tests/test_contracts.py`, `tests/test_migration.py`, and `tests/test_models_db.py`.

## Release Risk
Medium

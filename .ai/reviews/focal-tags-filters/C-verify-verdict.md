# Review Verdict

Reviewer: Opus
Step: verify
Score: 9.5 / 10
Status: APPROVED

## Reason
End-to-end review of the full 3-slice change against base `feature/focal-migration`, with both suites re-run from source against real Postgres (the runs GPT's sandbox could not do). Everything is green: client `pnpm lint` + `typecheck` + `test:run` (1697 tests, 133 files) + `build` all PASS; backend `ruff check` + `mypy` (171 files) PASS; `pytest tests/test_tags_db.py tests/test_tags.py tests/test_contracts.py` = 45 passed, including the 6 new usage-count DB tests (owner-isolation, id+name attribution, per-occurrence override, deleted-override exclusion, recurring-once, camelCase wire). `alembic check` reports "No new upgrade operations detected" — zero schema drift, confirming the no-migration design. The cumulative diff is exactly the design's surface with no stray edits. Risky paths are covered by tests rather than asserted: usage-aggregate owner-scoping (overrides scoped through the master's `user_id` — the only correct join), newest-same-name attribution, deleted-override exclusion, the `toIsoDate` created-date convention, the epoch `recent` sort, and full localStorage validation. Security pass clean: parameterized SQLAlchemy (no injection), backward-compatible camel wire (`{id,name,color,usageCount,createdAt}`, asserted; `usage_count` proven not to leak), no secrets/PII, no auth change (viewer-can-filter test proves writes stay gated). GPT's verification missed no real defect and raised no false one. Both flagged failures (`ruff format --check` on `app/data_scope.py`; 12 `test_ai_chat_routes_db.py`) are in files this branch does not touch (`git diff --stat` against base is empty for both) — genuinely pre-existing and external.

## Must Fix
None.

## Should Consider
- (Quality, non-blocking) `services/tags.py::_collect_refs` issues four separate `SELECT`s and tallies in Python rather than one SQL aggregate. Correct and within the design's accepted "one round-trip per table, no N+1" envelope at the current small-list scale; a single `unnest`+`count` would reduce data transfer at very large per-tenant volumes. Speculative for now — the design explicitly rejected denormalizing usage; right call to defer.

## Tests Reviewed
- `tests/test_tags_db.py` (22 passed): usage sums (count=3, recurring once, wire-name absent), per-occurrence overrides, deleted-override exclusion, legacy-name→newest-duplicate, and the strengthened cross-owner isolation (user-b refs across all four tables → user-a count 0).
- `tests/test_contracts.py` (18 passed): exact `TagRead` key set incl. camelCase `usageCount`/`createdAt`.
- `tagsFilters.test.ts`: each filter axis (search/color/usage/custom-range/preset), `sortTags` incl. mixed-ISO-precision `recent` + non-mutation, `colorOptions`, `activeTagFilterCount`, `reset`, `load/saveTagFilters` (round-trip, corrupt-JSON, per-field wrong-type incl. non-string date bounds).
- `TagsPage.test.tsx`: color filter narrows + count + fetched-once, default name-asc sort, reset-keeps-search, persist-across-remount, viewer-can-filter-while-writes-disabled, per-row usage badge, persisted used/unused/usage-desc/custom-range/recent re-applying on mount.
- Shared `Tag` factory updates across events/tasks tests are mechanical (additive `usageCount`/`createdAt`), required by the type change. Full client suite (1697) green confirms no regression.

## Release Risk
Low. No database migration (additive `TagRead` fields only; `created_at` already `nullable=False`, tag-bearing JSONB columns pre-exist, `usage_count` computed) — `alembic check` confirms no drift. Wire change backward-compatible (`to_camel` leaves `id`/`name`/`color` unchanged; `openapi.d.ts` regen committed; contract test pins the shape). Rollback is a clean per-slice commit revert plus `openapi.d.ts` regen. No secrets, no new external surface, no auth/RBAC/rate-limit change. The only caveat is the unrelated repo-wide `ruff format` drift on `app/data_scope.py`, which predates and is untouched by this change.

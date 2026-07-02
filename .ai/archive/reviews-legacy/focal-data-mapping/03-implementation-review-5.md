# Codex Review Verdict

Score: 8.1 / 10
Status: BLOCKED

(Slices 2-4 — generator + authored mapping + tables.json + doc reconcile, round 1.)

## Reason
The change is scoped to contract-freeze tooling/data, and the structural checker/generator path is mostly aligned with the task. It is blocked because the inventory still loses DB uniqueness/index facts and a few authored ownership/RLS paths omit task-required relationships.

## Must Fix
- `make_tables_inventory.py:65` emits `index_unique` only from manual overrides, and no overrides set it; generated `tables.json` marks `user_settings.user_id` as `index_unique: null` even though the snapshot has `user_settings_user_id_unique`. This violates the plan/task requirement to carry index/unique fidelity from the DB catalog.
- `_tables_mapping.py:82-85` only records `contacts` ownership through nullable `created_by`; the task requires noting nullable `created_by`/`updated_by` plus the orphan rule (`updated_by` is present in the snapshot).
- `_tables_mapping.py:69-72` scopes `event_contacts` only through `event_id -> calendar_events.user_id`; the task requires the join table be scoped via both `event_id` and `contact_id`.

## Should Consider
- README labels rowcount signals as prod-oriented while this slice uses a legacy dev snapshot; `capture_schema_snapshot.py` bands `-1` estimates as `empty`, which can mislead reviewers.
- Consider adding `ai-model` to the Phase-7 AI records where that ADR actually gates the disposition.

## Tests Reviewed
`check_tables.sh` (full/coverage/selftest); `git diff --check`; inspected task/plan/rubric/CLAUDE, MIGRATION_PLAN §3a/§6/§8, mapping/generator/checker/snapshot/tables/models. Did not rerun make verify (read-only sandbox).

## Release Risk
Medium

# Review Verdict

Reviewer: Opus
Step: verify
Score: 9.5 / 10
Status: APPROVED

## Reason
The verification is genuinely thorough and I independently confirmed every load-bearing claim: the migration is additive+reversible (3 nullable columns, reverse-order downgrade, mapping 1:1 to the model), the read-normalizer is idempotent across both single-GET and the LIST path, tenant scoping holds (`task.user_id == user_id` + project-scoped join), Pydantic rejects non-string/`null` inputs with 422, and there are no secrets/PII in the shipped diff. The "13 pre-existing failures" claim is diff-proven — none of `test_ai_chat_routes_db.py`/`test_schemas.py` or their subject modules appear in the 17-file diff — and the one real parity defect (null-projectType badge drop) is correctly fixed in `5101eba`, verified against the actual old-focal reference (`apps/old-focal/.../Tasks.tsx:1324-1333`, badge rendered unconditionally) and re-pinned by an inverted, now-passing test asserting the badge renders.

## Must Fix
None

## Should Consider
- The DB-backed backend counts (`1711 passed, 13 failed`, `alembic check` clean) were verified from the report + diff-based proof rather than re-run here (the local Docker PG truncates the user's dev data per run, per the charter's own instruction). The static evidence is strong, but the green claim ultimately rests on the verify-doer's logged run; the next live env to apply the migration should confirm `alembic upgrade head` then `check` once more before shipping to shared envs.
- Method transparency: the verification used a multi-agent Claude workflow rather than GPT-Codex (Codex sandbox blocked from writing `apps/focal/server` + `.ai/`). Fresh-context separation and adversarial scrutiny are intact, so this does not lower the score, but it is worth noting the cross-model independence guarantee was partially relaxed for this gate.

## Tests Reviewed
- Read `tests/test_tasks_db.py:712-722` (list-path normalizer: creates a legacy-`contact_id`-only row, fetches via `/api/tasks`, asserts `recurrence=='none'` + `contactIds==['legacy-9']`) and `:702-710,725-731` (legacy fallback, explicit-list-wins, otherParticipants clear-with-null).
- Read `TasksPage.test.tsx:650-661` (provision badge renders for null+unknown, `toHaveLength(2)`, mission absent — the re-pinned regression test), `:785-829` (schedule happy-path pins the `timezone='Asia/Almaty'` field and `endTime:'16:30'` +1h), and `:635-647` / `:895-916` (schedule create-failure → `deleteTask` not called; mutation-error draft retention).
- Independently inspected the migration `9288e60e47ce`, `models/tasks.py`, `schemas/tasks.py` (normalizer + validators), `services/tasks.py` (`_enrich` idempotency, tenant scoping), and ran a secret/PII grep over the full `origin/feature/focal-migration...HEAD` diff (clean) plus an i18n en/ru parity spot-check (recurrence + contactPicker keys present in both).

## Release Risk
Low

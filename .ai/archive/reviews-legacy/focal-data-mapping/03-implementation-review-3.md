# Codex Review Verdict

Score: 8.8 / 10
Status: BLOCKED

(Slice 1, round 3 — after ported=has-model, --coverage column enum, provenance match, snapshot scan + list-39.)

## Reason
Scope is tight and matches Slice 1: only contract-freeze table tooling, fixtures, and the DB snapshot were added; no app code changed. The selftest passes and the no-inventory run lists all 39 tables, but one discriminator edge case still lets malformed inventory pass despite the amendment.

## Must Fix
- `apps/focal/docs/contract-freeze/_check_tables.py:90`: `model = t.get("model")` uses truthiness, so an empty model object is treated as "no model." This violates the amended rule that a record carrying a model object is ported and must be kept/transformed. Evidence: `legacy_chat` with `"model": {}` still returns `[]` from `validate(...)`.

## Should Consider
- `apps/focal/docs/contract-freeze/_tables_discovery.py:67`: git provenance ignores non-zero git results and can produce `{branch: None, commit: None}`. Fail loud or require non-empty branch/commit.
- `apps/focal/docs/contract-freeze/capture_schema_snapshot.py:19`: `asyncpg` is third-party; document that capture runs in an environment with it installed (the checker stays stdlib-only).

## Tests Reviewed
`git -C superapp --no-pager diff -- apps/focal/docs/contract-freeze`; `git status`; `check_tables.sh --selftest`; `check_tables.sh`; `check_tables.sh --coverage`; targeted `validate(...)` checks for empty model and provenance behavior. Did not rerun Docker-backed `make verify`.

## Release Risk
Medium

# Codex Review Verdict

Score: 7.8 / 10
Status: BLOCKED

(Slice 1, round 2 — after chmod +x, snapshot secret-scan, duplicate-column check.)

## Reason
The chmod, snapshot secret-scan path, and duplicate-column check are improved, and the selftest passes. However, the checker still bakes in assumptions that conflict with the plan/task and can both reject a valid later inventory and allow a false-green `--coverage` run.

## Must Fix
- `apps/focal/docs/contract-freeze/_check_tables.py:32` and `:84`: `PORTED = {"kept", "transformed"}` treats every `kept` table as requiring extension fields, but `.ai/tasks/focal-data-mapping.md:49-52` and `:69-72` explicitly allow Phase-7 AI tables to be `kept` with standard fields only. Valid slice-4 AI records would fail full validation.
- `apps/focal/docs/contract-freeze/_check_tables.py:103`: `--coverage` returns before validating `columns[].disposition`, despite the plan requiring enum well-formedness for the slice-2 green bar. Confirmed: setting a column disposition to `"banana"` returned `[]` under `coverage_only=True`.
- `apps/focal/docs/contract-freeze/_check_tables.py:57`: provenance only checks that `repo/branch/commit` are present, not that they match the expected source. Confirmed: changing `source.commit` to `"deadbeef"` still returned `[]`.

## Should Consider
- `apps/focal/docs/contract-freeze/_check_tables.py:281` exits before scanning the real `schema-snapshot.json` when `tables.json` is absent, so slice-1's real checker command would not report a snapshot secret if one were present.
- `apps/focal/docs/contract-freeze/_check_tables.py:282` reports only the count of uncovered snapshot tables, while the slice plan says the no-`tables.json` run should list all 39 missing tables.

## Tests Reviewed
`git -C superapp --no-pager diff -- apps/focal/docs/contract-freeze`; `git -C superapp status`; `./check_tables.sh --selftest` passed with 33 checks caught; `./check_tables.sh` exited 1 with 39 uncovered; `git diff --check`; targeted in-memory validator probes for `--coverage` column disposition and provenance mismatch.

## Release Risk
Medium

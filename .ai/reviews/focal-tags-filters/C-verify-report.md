# Verification Report: focal-tags-filters

_Doer: GPT Codex (workspace-write, in the `superapp-tags-filters` worktree). Verifies the whole
3-slice change against `.ai/design/focal-tags-filters-design.md`._

Scrutinized the whole branch diff (`git diff feature/focal-migration...HEAD`, `git status`).
**No production defect found. Production code was not modified** — only test files changed.

## What was scrutinized
- **Usage aggregate owner-scoping + attribution** — `app/services/tags.py:95-148`: owner-scoped tag
  list; id-first attribution with the newest-same-name fallback (created-at ordered rows); the
  event/task/booking reference queries are owner-scoped; the override query joins through the owner's
  master event and excludes deleted overrides.
- **Created-date filter + sort** — `tagsFilters.ts:113-124` (created date via
  `toIsoDate(new Date(tag.createdAt))`), `:137-141` (recent sort uses epoch time, not raw ISO string
  comparison).
- **Persistence / localStorage validation** — `tagsFilters.ts:50-77`: corrupted JSON falls back;
  enums + array types validated; non-string date bounds covered by new tests.
- **Security** — SQLAlchemy queries are parameterized (no string-built SQL); no new secrets, no PII
  logging, no new authorization-bypass surface. Filtering remains client-side over the authorized
  `GET /api/tags` result.

## Tests added/strengthened
- `apps/focal/client/src/features/tags/tagsFilters.test.ts` — proves custom `dateFrom`/`dateTo` bounds
  persist+reload with the custom preset; proves invalid persisted types (incl. non-string date bounds)
  fall back to defaults.
- `apps/focal/server/tests/test_tags_db.py` — strengthens tenant isolation: another owner referencing
  user-a's tag id from calendar events, occurrence overrides, tasks, and bookings does not affect
  user-a's `usageCount`.

## Command results
- **Client** — biome check PASS (380 files); `tsc -b` PASS; Vitest PASS (133 files, 1697 tests);
  `vite build` PASS (pre-existing chunk-size warning only). _(Note: the exact `pnpm` invocation and the
  default Vitest run hit codex-sandbox limits — pnpm network fetch + a Node-25 built-in `localStorage`
  quirk — so equivalents were run directly with `--no-experimental-webstorage`.)_
- **Backend** — `ruff check .` PASS; `mypy app` PASS (171 files). The real-DB pytest was **blocked by
  the codex sandbox's localhost network restriction** (cannot reach `localhost:5433`), not by any
  assertion — with `DATABASE_URL` unset the DB tests skip (5 passed, 40 skipped).

## Reviewer note (Opus, in-session)
GPT's sandbox could not reach the local Postgres or the npm registry, so the suites were re-run
in-session with real DB + network access: **client `lint`/`typecheck`/`test:run` (1697) + `build` all
PASS; backend `ruff`/`mypy` PASS, `pytest tests/test_tags_db.py tests/test_tags.py tests/test_contracts.py`
= 45 passed** — including GPT's added/strengthened tests. The 12 `test_ai_chat_routes_db.py` failures and
the `app/data_scope.py` ruff-format drift remain (both proven pre-existing on `feature/focal-migration`).

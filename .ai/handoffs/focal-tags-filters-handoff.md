# Stage
3-gate flow · Gate C (verify) → ship. Feature: `focal-tags-filters`. Branch `feat/focal-tags-filters` → `feature/focal-migration`.

# What changed
The Tags page gains an Events-style filter toolbar over the axes a tag actually has, built in three slices:
- **Slice 1** — a collapsible filter panel: filter by **color**, **sort** (name A–Z / Z–A), an active-filter badge + reset, and persistence of the toolbar state in `localStorage` (`focal-tags-filters`). The existing name-search is reused.
- **Slice 2** — per-tag **usage count**: the backend exposes `usageCount` on `TagRead` via an owner-scoped aggregate over the tag's references in events (master + per-occurrence overrides), tasks, and bookings; the page adds a **Used / Unused / All** filter, **sort by most-used**, and a per-row count badge. Legacy references stored by tag *name* (not id) are attributed to the newest same-named tag; deleted occurrence-overrides are excluded; CRM contacts are excluded (PRIMA's concern).
- **Slice 3** — **created-date** filter: presets (this week / month / year) + a custom from/to range, and a **sort by most-recent**. The backend exposes `createdAt` on `TagRead`.

No database migration: `created_at` and the tag-bearing JSONB columns already exist; `usageCount` is computed at read time; `TagRead` only gains additive fields (which serialize camelCase via the shared alias base).

# Files touched
- `apps/focal/server/app/schemas/tags.py` — `TagRead` adopts the camelCase alias base; adds `usage_count`, `created_at`.
- `apps/focal/server/app/services/tags.py` — `StoredTag.usage_count`/`created_at`; owner-scoped usage aggregate (`_usage_counts`/`_collect_refs`) with id-or-name attribution + deleted-override exclusion.
- `apps/focal/server/tests/{test_tags_db.py, test_contracts.py}` — usage/created-date + tenant-isolation tests; tag-shape contract.
- `apps/focal/client/src/api/openapi.d.ts` — regenerated (`usageCount`, `createdAt` on `TagRead`).
- `apps/focal/client/src/features/tags/{tagsFilters.ts, tagsFilters.test.ts, TagsPage.tsx, TagsPage.test.tsx}` — the filter model + page UI + tests.
- `apps/focal/client/src/i18n/locales/{en,ru}.json` — `focal.tags.filters.*` keys (both locales).
- Required type-propagation only (the shared `Tag` type gained `usageCount`/`createdAt`): tag mocks updated in `features/events/{eventsFilters,EventsPage}.test.*` and `features/tasks/{TaskDialog,tasksFilters,TasksPage}.test.*`.

# Tests run
```sh
# client (apps/focal/client)
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
#   biome 380 files OK · tsc OK · Vitest 133 files / 1697 passed · vite build OK
# backend (apps/focal/server, DATABASE_URL → local Docker Postgres :5433)
uv run --frozen ruff check . && uv run --frozen mypy app   # PASS · PASS (171 files)
uv run --frozen pytest tests/test_tags_db.py tests/test_tags.py tests/test_contracts.py   # 45 passed
uv run --frozen pytest   # 1718 passed, 12 failed (pre-existing), 1 skipped
```

# Verification output
```sh
# Pre-existing failures, proven on base (feature/focal-migration, worktree superapp-parity):
#  - ruff format --check flags app/data_scope.py  (file untouched by this change)
#  - 12 tests in tests/test_ai_chat_routes_db.py fail (environmental AI pipeline)
# Both reproduce identically on the base branch; neither is caused by this change.
```

# Still needs review
- The usage-count aggregate's tenant isolation (no cross-owner counting) and the name→newest-tag attribution rule.
- The created-date `recent` sort uses parsed epoch time (not raw ISO-string compare) so mixed-precision timestamps order correctly.
- `dateFrom`/`dateTo` are validated as strings on load but not date-format-validated (matches the Events filter's handling) — non-blocking.

# PR / release notes (for users — stage 5)
**Tags page: filter, sort, and see how each tag is used.**

The Tags page now has a filter toolbar like the Events page:
- **Filter by colour**, and **filter by usage** — show only tags that are *used* or *unused* to find and clean up dead tags.
- **Filter by when a tag was created** — this week / month / year, or a custom date range.
- **Sort** the list by name (A–Z / Z–A), by **most-used**, or by **most-recent**.
- Each tag shows a **usage count** — how many of your events, tasks, and bookings reference it.
- Your filter and sort choices are remembered between visits. Viewers of a shared calendar can filter and sort too (only editing stays restricted).

No data migration; nothing to roll out. Rollback is a plain revert of the branch.

(No secrets, tokens, keys, or PII in this text.)

# Status
OPUS APPROVED (9.5) — gate C verify/release passed. Cleared to ship.

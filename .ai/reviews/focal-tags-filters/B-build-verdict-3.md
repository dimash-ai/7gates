# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.6 / 10
Status: BLOCKED

_(Slice 2 of 3 — tag usage count — round 1.)_

## Reason
The slice implements the main `usageCount` contract, owner-scoped counting over the intended tables, frontend used/unused filtering, sort-by-usage, row badges, and minimal type-propagation test ripples. It misses a recurring-events correctness edge that can overstate usage counts: deleted occurrence overrides are counted as live tag references.

## Must Fix
- `apps/focal/server/app/services/tags.py:125` selects all `CalendarEventOverride.tags` rows for the owner without excluding `CalendarEventOverride.is_deleted`. Deleted occurrence overrides are treated as non-events by the calendar read path (`apps/focal/server/app/services/calendar.py:620`), and `_delete_single` snapshots tags into those deleted override rows (`apps/focal/server/app/services/calendar.py:570`), so a recurring series with one deleted occurrence can count the master tag plus the deleted override and violate the slice requirement that recurring series count once.

## Should Consider
- `apps/focal/server/app/services/tags.py:139` and `apps/focal/server/app/services/tags.py:152` still return mutation `TagRead` objects with the default `usage_count=0`; the page refetches after mutations, but API consumers of POST/PATCH can see stale `usageCount`.

## Tests Reviewed
Inspected `.ai/runs/focal-tags-filters-build.txt`: client lint, i18n lint, typecheck, full Vitest, and build passed; backend changed-file ruff checks and mypy passed; full pytest had 12 failures documented as pre-existing. Reviewed added backend DB tests and frontend tags filter/page tests; did not rerun tests.

## Release Risk
Medium

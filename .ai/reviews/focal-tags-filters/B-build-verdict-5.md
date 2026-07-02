# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.6 / 10
Status: BLOCKED

_(Slice 3 of 3 — created-date filter — round 1.)_

## Reason
The slice is scoped to the design and the backend `createdAt` exposure/type ripple is minimal, but the new recent sort is not reliably chronological for valid ISO date-time strings. The logged client/backend checks are strong, but the sort bug needs fixing before approval.

## Must Fix
- `superapp-tags-filters/apps/focal/client/src/features/tags/tagsFilters.ts:137` compares raw `createdAt` strings for `recent` sorting. That breaks for valid ISO timestamps with mixed precision or offsets: a newer `.001Z` timestamp compares as older. Parse/normalize timestamps for the comparator and cover this edge case.

## Should Consider
- Add a direct preset-date filter test for `thisWeek`/`thisMonth`/`thisYear`; current new coverage proves custom range and active-count behavior, but not the preset narrowing path in `tagsFilters.ts:113`.

## Tests Reviewed
Inspected the slice-3 diff, the build log, and the design doc. Build log reports backend ruff/format/mypy pass, full pytest `1718 passed, 12 failed` documented pre-existing, and client lint/lint:i18n/typecheck/test:run/build pass; ran a Node comparator repro to confirm the sort bug.

## Release Risk
Medium

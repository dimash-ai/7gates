# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 7.8 / 10
Status: BLOCKED

## Reason
The new in-flight guard covers concurrent writes while a mutation is pending, but it still reopens entry writers before the invalidated entries refetch has refreshed the cache, leaving a note/status overwrite race in the same data-loss class as the prior Must Fix.

## Must Fix
- `HabitsPage` starts invalidation with `void invalidate()` while `HabitJournal` only blocks on `entries.isSuccess` + mutation `isPending`. After a note/status mutation resolves, writers re-enable while entries are still refetching with stale cache; the next write reads stale values and can send `note: null`, erasing a just-saved note before the refetch lands. Cover the resolved-mutation pending-refetch window (e.g. also gate on `entries.isFetching`, or await invalidate, or optimistic cache update) + a regression.

## Should Consider
- The delete confirmation closes immediately before `deleteHabit` settles, so a delete rejection does not keep the confirmation dialog open as the design's unhappy-path table describes.

## Tests Reviewed
Inspected `git diff`, `git status`, `HabitJournal.test.tsx`, `HabitCreateDialog.test.tsx`, `HabitsPage.test.tsx`. (Sandbox blocked re-running pnpm.)

## Release Risk
Medium

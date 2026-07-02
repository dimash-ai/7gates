# Review Verdict

Reviewer: GPT Codex
Step: review
Score: 7.2 / 10
Status: BLOCKED

## Reason
The re-skin is broadly scoped correctly and typechecks, but there are two concrete correctness/security gaps in the filter editor. A value-backed shared-calendar filter can be saved with `filterValue: null`, which changes the backend filter semantics and may expose the owner's unassigned/null events to participants; the per-card filter draft can also go stale across refetches and overwrite newer server state.

## Must Fix
- `apps/focal/client/src/features/calendars/calendarFilters.ts:67-70` maps an empty value for non-`all` filters to `null`, while `apps/focal/client/src/features/calendars/CalendarsPage.tsx:417-421` and `apps/focal/client/src/features/calendars/CalendarsPage.tsx:1070-1083` allow saving/creating `sphere`, `project`, or `product` filters without selecting a value. The backend then matches null fields for those filter types (`apps/focal/server/app/domain/shared_calendar_filter.py:62-67`), so a supposedly narrowed shared calendar can expose unassigned/null events instead of matching nothing or blocking save.
- `apps/focal/client/src/features/calendars/CalendarsPage.tsx:325` initializes `filterDraft` from `calendar` only once and never syncs it when the calendar prop changes after invalidation/refetch; saving from the editor at `apps/focal/client/src/features/calendars/CalendarsPage.tsx:417-421` can therefore silently write a stale filter over newer server data.

## Should Consider
- `apps/focal/client/src/features/calendars/GoogleSyncPanel.tsx:39-66` is unchanged from the base branch even though the plan/task called out restyling that panel to the old-focal Google-sync section.
- Add regression coverage for empty value-backed filters, stale draft after refetch, clipboard rejection, and missing self-participant leave handling.

## Tests Reviewed
`git -C .worktrees/focal-redesign-calendars --no-pager diff --cached`; `git -C .worktrees/focal-redesign-calendars status`; tsc passed. `pnpm/vitest` could not run because the read-only sandbox blocked pnpm/Vite temp-file writes.

## Release Risk
High

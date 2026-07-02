# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 8.2 / 10
Status: BLOCKED

## Reason
The design is well-scoped overall, and the events prefix invalidation, public toggle reuse, and delete confirmation approach are mostly sound. It blocks on the orphan badge contract: the design would undercount versus old-focal, uses the wrong response field names, and does not clearly gate the query away from limited shared-calendar users.

## Must Fix
- `.ai/design/focal-parity-cleanup-design.md:88-92` must use the actual `/api/stats/orphans` client contract and date window. The design says `{ orphan_tasks, orphan_events, total }` and omits `startDate`/`endDate`, but the generated schema is camelCase `orphanTasks`/`orphanEvents` (`superapp-slice13/apps/focal/client/src/api/openapi.d.ts:4022`) and old-focal sends `getRestRangeFromTodayYmd` as query params (`superapp/apps/old-focal/client/src/components/AppSidebar.tsx:312`). With no window, the new stats service defaults to current month (`superapp-slice13/apps/focal/server/app/services/stats.py:11`), so the badges would silently undercount.
- `.ai/design/focal-parity-cleanup-design.md:88-94` must specify query `enabled` gating for limited shared-calendar users, not only hide the rendered badge. `/api/stats/orphans` is `DataDomain.OTHER_PAGES` (`superapp-slice13/apps/focal/server/app/api/stats.py:14`) and only owner/full_access/developer can read it (`superapp-slice13/apps/focal/server/app/data_scope.py:55`); old-focal disables this query for limited menu (`superapp/apps/old-focal/client/src/components/AppSidebar.tsx:326`).

## Should Consider
- `.ai/design/focal-parity-cleanup-design.md:45-52` says to add events invalidation in shared `onActionSuccess`, but the current callback is also used by decline/tentative/delete (`superapp-slice13/apps/focal/client/src/features/meetings/MeetingRequestsPage.tsx:379`). Make the intended action set explicit to avoid extra refetches beyond the stated accept/reschedule-accept scope.

## Tests Reviewed
N/A

## Release Risk
Medium

# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 8.2 / 10
Status: BLOCKED

## Reason
The design makes the right reuse-first call on client-side move-preview counts and the existing PATCH/server cycle guard, and it keeps backend/modal/finance/edge scope bounded. It still has two correctness gaps in the reparent contract and undo architecture that would likely break required behavior if implemented as written.

## Must Fix
- The reparent payload must clear the opposite parent field: `update_project` uses `exclude_unset=True` and applies only sent fields (`services/projects.py:135-143`); since the schema accepts explicit nulls (`schemas/projects.py:50-51`), pillar reparent must send `{ parentType, parentProjectId: null }`, project-nest `{ parentType: null, parentProjectId }`, root both null — otherwise moving a child to a pillar leaves it under the old parent.
- Reparent undo is required, but the existing history is position-only (`features/goals/history.ts`). Define the structural undo/redo entry, inverse PATCH payload, failure behavior, and tests instead of only saying to reuse existing history.

## Should Consider
- Specify the schedule draft key/schema and exact mapping into `EventDraft` fields (`projectId`/`productId`/`activityId`, title, date/time defaults, calendarId/TTL for stale or foreign drafts) so the sessionStorage handoff is as concrete as the reparent contract.

## Tests Reviewed
N/A

## Release Risk
Medium

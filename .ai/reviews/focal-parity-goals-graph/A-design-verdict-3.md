# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 8.8 / 10
Status: BLOCKED

## Reason
The reparent contract still correctly sends both parent fields with the opposite nulled, structural undo/redo is defined, and the scope remains frontend-only. The schedule fix is still incomplete for product-owned activity nodes because the design said to derive activity drafts from `activity.projectId`/`activity.productId`, but those activities can have only `productId`, which would still create `noProject` orphaned events.

## Must Fix
- The schedule mapping must explicitly resolve an activity's parent project from the loaded `init.projects` graph when `activity.productId` is set, not just copy `activity.projectId`/`activity.productId`. Goals creates product activities with only `{ productId }` (`GoalsPage.tsx:676`, `api/mindmap.ts:113`), calendar persists exactly the submitted `project_id`/`product_id` (`services/calendar.py:204`), and a missing project link is orphaned (`services/calendar.py:800,823`).

## Should Consider
- Add an explicit schedule handoff test case for a product-owned activity, proving the draft contains both the parent `projectId` and `productId`.

## Tests Reviewed
N/A

## Release Risk
Medium

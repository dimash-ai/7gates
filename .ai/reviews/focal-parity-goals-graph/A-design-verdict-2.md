# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 8.6 / 10
Status: BLOCKED

## Reason
The prior reparent contract and structural undo blockers are addressed, and the design stays frontend-only. However, the schedule draft mapping is still incorrect for product/activity nodes and would create orphaned or out-of-filter calendar events.

## Must Fix
- The schedule draft mapped the event link by node kind only, so product nodes set only `productId` and activity nodes set only `activityId`. Calendar create only sends IDs present on the draft (`eventsFilters.ts:381`), enrichment/filtering derives project/product only from stored `project_id`/`product_id`, never `activity_id` (`services/calendar.py:688,800`), and a missing project link is orphaned (`services/calendar.py:823`). Specify hierarchy-aware mapping from the loaded graph: product drafts must include parent `projectId`; activity drafts must include the owning `projectId`/`productId`.

## Should Consider
None

## Tests Reviewed
N/A

## Release Risk
Medium

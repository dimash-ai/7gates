# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 8.4 / 10
Status: BLOCKED

## Reason
The two prior security Must Fix items are substantially addressed: the doc now separates AI read/write authorization and correctly states the app-layer owner filter is the active tenant boundary. However, the scoped endpoint matrix still misses concrete mutating routes in slice scope, so the build could leave assistant-mode writes unscoped or incorrectly self-scoped.

## Must Fix
- The scoped endpoint matrix lists Time Budgets writes only as “time-budget items,” but the Time Budgets API also mutates settings, categories, and subcategories (`time_budgets.py:40/50/61/71/81/92/102`). These must be explicitly covered by the write gate matrix and tests.
- The writes list misses non-CRUD mutating routes: `POST /api/activity-instances/sync` (`activity_instances.py:43`) and `POST /api/mindmap-nodes/batch` (`mindmap.py:38`). Add them explicitly or justify excluding them.

## Should Consider
- Add an explicit backend authz test that `editor` is denied owner-scoped reads (editor is in the write set but not the read set), since read-denial only named viewer/requester/non-participant.

## Tests Reviewed
N/A

## Release Risk
Medium

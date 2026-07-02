# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 8.3 / 10
Status: BLOCKED

## Reason
The core RBAC boundary, read/write role split, AI IDOR fix, unhappy paths, and no-`calendarId` backward compatibility are sound. The remaining blocker is that the scoped endpoint matrix still claims route-level completeness but omits several real scoped read routes, which is too risky for this security-critical design gate.

## Must Fix
- The matrix does not enumerate every scoped READ route it claims to cover, lists a non-existent `/api/products`, and omits single-item reads at `tasks.py:44`, `calendar.py:43`, `projects.py:29/46/55`, `activities.py:36`, `activity_instances.py:52`, `goals.py:35`, `spheres.py:36`, `bookings.py:41`. Add these exact routes, or explicit resource wildcards, to the matrix and authz test scope.

## Should Consider
- Time Budgets item routes (`time_budgets.py:112/121/131`) should be named to make the write matrix unambiguous.

## Tests Reviewed
N/A

## Release Risk
Medium

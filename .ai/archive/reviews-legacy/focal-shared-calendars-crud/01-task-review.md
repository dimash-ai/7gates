# Codex Review Verdict

Score: 8.4 / 10
Status: BLOCKED

## Reason
The RBAC direction is sound: enforcing the legacy commented checks as `viewer` for reads and `owner` for calendar config/delete matches the cited route intent, accepted-only role lookup is correct, the 404/403 split is faithful to `my-role`, and the 8-route slice is cohesive. The blocker is that the task under-specifies or drops legacy caller-view response contract details, which risks a silent API/UI regression.

## Must Fix
- `AccessibleSharedCalendarRead` is defined as calendar + `participantsCount` only, but legacy `getAccessibleSharedCalendars` returns caller `participantRole`/`inviteStatus` (`storage.ts:6567-6592`) and the route returns those augmented objects with counts (`routes.ts:7451-7464`). Add those fields or document the break.
- `my-participation` omits the per-item `isOwner` field that the legacy route includes (`routes.ts:7517-7534`).
- The task names snake_case fields; the migrated API contract is camelCase (`filterType`, `googleCalendarId`, `isActive`, `userId`, ...). Add schema acceptance for accepting/serializing camelCase via the `_Camel` pattern.

## Should Consider
- Specify whether `participantsCount` counts all participant rows or only accepted (legacy counts all).
- Add route-order/contract tests for `/accessible`, `/my-participation`, `/{id}/my-role` so static routes are not shadowed by `/{id}`.
- Require `POST` calendar + owner-participant creation to be atomic.

## Tests Reviewed
No tests run; Gate 1 task review. Inspected the task, rubric, `RBAC_CONTRACT.md`, legacy `routes.ts`/`storage.ts`/`schema.ts`, `app/rbac.py`, `app/models/shared_calendar.py`, and current schema/router patterns.

## Release Risk
Medium

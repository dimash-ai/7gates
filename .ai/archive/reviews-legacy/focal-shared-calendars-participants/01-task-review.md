# Codex Review Verdict

Score: 8.7 / 10
Status: BLOCKED

## Reason
The slice is cohesive and mostly faithful on list/invite/delete/join mapping, JWT tenanting, typed errors, minimal user shape, and verification criteria. It is not ready because role input semantics are underspecified in a way that can create durable owner-level participants and undermine the owner-immutable rule.

## Must Fix
- Constrain `ParticipantInvite.role` and `ParticipantRoleUpdate.role`. As written the API may accept `role="owner"` or an arbitrary string; `app/rbac.py` gives `owner` owner-level rank, so invite/update could create a second owner that cannot be removed/changed. Add required tests for invalid roles and for `role="owner"` being rejected, unless the task explicitly defines ownership-transfer/multi-owner behavior.

## Should Consider
- Clarify precedence for `DELETE` when a non-owner targets the owner participant ("non-owner removing someone else → 403" vs "removing the owner → 409").

## Tests Reviewed
No tests run; Gate 1 task review only. Inspected the task, rubric, `CLAUDE.md`, legacy `routes.ts:7738-7917`/`storage.ts:6443-6560`, `app/rbac.py`, `shared_calendars.py`, `models/shared_calendar.py`, `models/users.py`, `auth.py`, `errors.py`, and `RBAC_CONTRACT.md`.

## Release Risk
Medium

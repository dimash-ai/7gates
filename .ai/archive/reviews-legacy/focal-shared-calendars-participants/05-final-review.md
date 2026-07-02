# Codex Review Verdict

Score: 8.6 / 10
Status: BLOCKED

## Reason
Scope is clean and the planned participant/join surface is implemented with typed AppError paths, JWT tenant source, role validation, owner-only writes, owner immutability, and focused tests. The remaining blocker is a concrete race in one-time invite acceptance that can violate join idempotency under concurrent requests.

## Must Fix
- `app/services/shared_calendars.py` `join()` did a select/status-check/update sequence without a row lock or conditional update. Two concurrent joins could both read the same pending invite, both pass the accepted check, then both write — one overwrites `user_id` and both return success instead of exactly one success and one 409.

## Should Consider
- Add a regression test for concurrent joins once the service uses a lock or atomic conditional update.

## Tests Reviewed
Inspected `make verify`/`alembic check` claim, diff scope, task/plan, `RBAC_CONTRACT.md`, legacy `routes.ts:99`/`:7738-7917`, and the new/modified tests. Did not rerun full `make verify` in the read-only sandbox.

## Release Risk
Medium

---
Fix applied: `join()` now uses an atomic `UPDATE ... WHERE invite_status != 'accepted' RETURNING id`;
0 rows updated → re-query to distinguish 404 (no code) vs 409 (already accepted). Exactly one of two
concurrent joins wins. `test_join_already_accepted_is_409` exercises the same guard sequentially.

---

# Codex Review Verdict (round 3)

Score: 9.4 / 10
Status: APPROVED

## Reason
The final diff matches the participant/join task and stays within the planned files, with no model/migration/error-code churn. The round-2 escalation is closed: non-owner list/join paths receive `inviteCode: null`, owner-only routes are the only paths returning codes, and the atomic conditional join remains intact.

## Must Fix
None

## Should Consider
None

## Release Risk
Low

Fix applied: `_participant_read(include_invite_code=...)` — owner-only (`role == "owner"` on list;
True on the owner-only invite/role-change routes; False on join). New `test_invite_code_hidden_from_non_owner`
+ a join-echo null-code assertion.

# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 9.2 / 10
Status: APPROVED

## Reason
The slice matches the design: it adds a focused forward-parity checker, documents the 19 current divergences, wires the gate into `backend-focal`, and the checker correctly catches kept routes that are neither served nor allow-listed. I independently confirmed the real kept-but-missing set is exactly the 19 allow-listed entries, and dropping one allow entry produces a missing-route failure.

## Must Fix
None

## Should Consider
- Clarify the "pending product/ops confirmation" wording for the admin dropped routes, since CI now treats them as accepted divergences.
- Consider adding a small committed self-test for `check_parity.py` covering param canonicalization, `ALL`, and allowlist failure behavior.

## Tests Reviewed
Ran the parity checker against live `app.openapi()` successfully; ran an in-memory diff confirming 19 missing without allowlist and 0 missing with allowlist; ran an allowlist-drop check that reported the dropped route.

## Release Risk
Medium

> Note (doer): both Should-Consider items folded in before commit — added a `--selftest` mode to
> check_parity.py (refactored the matcher into a pure `missing_routes`; selftest covers canon, ALL,
> allow-listed-pass, and the missing-route failure) wired into the CI step; and reworded the admin
> drops in parity_allowlist.json + PARITY.md to make clear the gate accepts them while the drop awaits
> a product/ops ack. Verified: selftest OK, real check PARITY OK, ci.yml valid.

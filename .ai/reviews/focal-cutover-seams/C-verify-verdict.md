# Review Verdict

Reviewer: Opus
Step: verify
Score: 6.5 / 10
Status: BLOCKED

## Reason
The change was verified against a **stale base**: `feature/focal-migration...HEAD` resolves to merge-base `6f6659a`, which predates the already-landed PR #113 ("login with sign-up + forgot-password, and PKCE password reset"). Merging this branch into the current base tip (`18342d3`) fails with **6 conflicts** — including two `add/add` conflicts where slice 3 re-creates `apps/focal/client/src/features/auth/ResetPasswordScreen.tsx` (187 lines here vs #113's 311) and its test — so the verifier's "clean tree, green suite" does not reflect what happens at merge, and slice 3 is largely duplicate work that already shipped on base.

## Must Fix
- **Rebase onto the current `feature/focal-migration` (`18342d3`) and reconcile slice 3 before merge.** PR #113 already added focal forgot/reset/PKCE recovery. A real `git merge` into today's base conflicts on 6 files: `features/auth/ResetPasswordScreen.tsx` + `ResetPasswordScreen.test.tsx` (add/add), `AuthGate.tsx`, `LoginScreen.tsx`, `i18n/locales/en.json`, `i18n/locales/ru.json`. Decide which recovery implementation wins, drop the redundant one, then re-verify the other five (independent, clean) slices against the rebased tree.

## Should Consider
- If #113's focal recovery is the accepted one, slice 3 should be dropped entirely, leaving this feature as the 5 genuinely-new seams (`/api/me`, edge proxy, parity gate, openapi-drift, e2e smoke).
- Land the flagged i18n cleanup (`focal.tasks.countActive` plural keys; hardcoded `%` in dashboard/analytics) as a separate PR — confirmed not introduced here.
- The two scope deferrals (signup/email-verify; authed-CRUD E2E) are honestly justified and documented — removing GPT's un-runnable mocked `authenticated-crud.spec.ts` was correct, not a hidden omission.

## Tests Reviewed
- `check_parity.py --selftest` + full check (193/193); `pytest tests/test_me.py` (3 passed); inspected the proxy/guard/recovery/parity tests, CI, _routes.json, EDGE_PROXY.md, parity_allowlist.json (no secrets).
- Release-safety: `git merge-base` (= `6f6659a`, pre-#113); `git merge --no-commit` of `a7135ec` into `18342d3` → 6 conflicts (tree restored); i18n collision analysis (2004 shared keys, 0 differing auth values; branch only adds keys).

## Release Risk
High

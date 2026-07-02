# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 7.6 / 10
Status: BLOCKED

## Reason
The forgot/reset code is mostly scoped and follows PRIMA's recovery-event gating by inspection, with enumeration-neutral copy and no token logging. It cannot pass the build gate because the slice repeats a false signup-parity assumption and lacks regression tests for the reset/gating behavior that is the main risk of this slice.

## Must Fix
- The "forgot/reset only" scope is not justified by the claimed evidence: the design/build log say old-focal had no signup UI, but old-focal links to `/login#signup` (`apps/old-focal/client/src/pages/FocalLanding.tsx:219`), initializes `sign_up` mode (`apps/old-focal/client/src/pages/LoginPage.tsx:284`), renders it (`:342`), and calls `supabase.auth.signUp` (`apps/old-focal/client/src/components/AuthCredentialsForm.tsx:331`). Either include signup/email verification parity or document explicit product/ops sign-off that this old-focal surface is intentionally dropped.
- Add regression tests for the reset/recovery gate itself (`AuthGate.tsx:24`, `ResetPasswordScreen.tsx:34`, `:70`); no focal tests cover these paths, while PRIMA has `ResetPasswordScreen.test.tsx` and `useRecoveryMode.test.ts`.

## Should Consider
- Port PRIMA's sign-out cleanup for the recovery flag; focal's `signOut` clears session/cache but not `focal_recovery_pending`.

## Tests Reviewed
Inspected the build log (slice auth Vitest 32 passed, full Vitest 1249 passed, tsc/biome clean; check:i18n/lint:i18n documented as pre-existing) and the added auth tests; did not rerun the suite in the read-only sandbox.

## Release Risk
Medium

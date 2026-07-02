# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 7.8 / 10
Status: BLOCKED

## Reason
The landing/login/i18n/error-mapping work is broad and mostly well-covered, and ru/en key parity checks out. However the reset surface can be reached and used with a normal signed-in session, so the PKCE recovery flow is not strictly session-backed as required.

## Must Fix
- `AuthGate.tsx` renders ResetPasswordScreen for `/reset-password` before checking `session`, so a signed-in user on the public auth reset route does not redirect to `/tasks`; ResetPasswordScreen then renders the password form for any non-null session and calls `updatePassword`. This violates the signed-in public-auth routing contract and lets the reset UI operate outside an active recovery session.
- `AuthProvider.tsx` marks recovery from a bare `?code` or fresh localStorage flag, and blindly adopts whatever `getSession()` returns. If the PKCE exchange fails, the verifier is missing, or only the TTL flag remains while a normal session is stored, the reset form receives that normal session rather than a `PASSWORD_RECOVERY` session.

## Should Consider
- `LoginScreen.tsx` hardcodes "PRIMA — Personal CRM"; if product names are not intentionally fixed English copy, move it into `focal.auth.*`.
- Add explicit App/AuthProvider tests for signed-in `/reset-password` and for recovery callback/TTL flag with an existing normal stored session.

## Tests Reviewed
Inspected the full diff vs base, `App.test.tsx`, `AuthProvider.recovery.test.tsx`, `LoginScreen.test.tsx`, `ResetPasswordScreen.test.tsx`, `FocalLandingPage.test.tsx`, and i18n ru/en key parity.

## Release Risk
High

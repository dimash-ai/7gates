# Summary

Port the old-focal logged-out surface into the new Focal client as a frontend-only parity slice. Keep Supabase identity env-driven through the existing `getSupabase()` client and do not add backend/API work. The build should happen in three independently reviewable slices: login parity, PKCE recovery, then marketing landing and logged-out routing.

Pinned choices from the think gate:

- Landing inventory: port the old `FocalLanding.tsx` sections as-is: header with brand/tagline, language/theme controls, sign-in/sign-up CTAs; hero with feature pills and calendar mockup; feature cards; analytics preview with product analytics mockup; analytics layer cards; audience section; final CTA; footer with privacy/terms.
- PublicLayout usage: do not introduce `PublicLayout` for landing/login/reset. Old-focal used `PublicLayout` only around public legal pages; the new legal pages already render outside auth with `PublicToggles`, so leave that surface intact.
- Sign-in cooldown: port the old credentials cooldown behavior 1:1 for sign-in and sign-up: module-level deadline and unknown-429 counter, parsed retry interval when Supabase gives one, unknown 429 ladder `120s -> 300s -> 900s`, reset on successful credentials action, and disable both credentials submit and Google while the credentials cooldown is active. Forgot-password keeps its separate module-level cooldown, 60s success cooldown, and the same unknown-429 ladder.
- PKCE recovery: use `resetPasswordForEmail(..., { redirectTo: origin + '/reset-password' })`, let the existing Supabase PKCE client exchange the `?code=`, set a recovery-state signal from `PASSWORD_RECOVERY` and from the `/reset-password?code=` bootstrap path, then call `updateUser({ password })` from the reset screen. Do not port old hash `type=recovery` handling.

Official docs checked for the auth shape: Supabase `resetPasswordForEmail` documents PKCE support and the `PASSWORD_RECOVERY` -> `updateUser` flow; Supabase `signUp` documents PKCE support for email signups and `emailRedirectTo`.

# Files to change

| path | change | why |
|------|--------|-----|
| `superapp/apps/focal/client/src/features/auth/AuthProvider.tsx` | Extend auth context with `signUp`, `requestPasswordReset`, `updatePassword`, `isPasswordRecovery`, and `clearPasswordRecovery`; track PKCE recovery state with a short-lived localStorage flag; handle `PASSWORD_RECOVERY`; preserve existing token getter, 401 sign-out, query-cache clearing, and env guards. | Current provider only signs in/out and has no recovery signal or signup/reset methods. |
| `superapp/apps/focal/client/src/features/auth/AuthGate.tsx` | Route signed-out `/` and `/landing` to landing, `/login` to login, `/reset-password` or active recovery to reset; redirect signed-in public auth routes to `/tasks`; keep loading behavior. | Current gate returns `LoginScreen` for every logged-out path. |
| `superapp/apps/focal/client/src/features/auth/LoginScreen.tsx` | Convert from bare sign-in to the old-focal login container: FoCal branding, sign-in/sign-up toggle, forgot-password view, signup confirmation panel, privacy/terms links, PRIMA link, public controls, localized errors, and not-configured state. | Required login parity and old-focal branding. |
| `superapp/apps/focal/client/src/features/auth/AuthCredentialsForm.tsx` | Add credentials form component for sign-in and sign-up, including confirm password, show/hide toggles, Google button, validation, mapped Supabase errors, and credentials rate-limit cooldown. | Keeps the container small and ports the old reusable behavior. |
| `superapp/apps/focal/client/src/features/auth/SignupConfirmationPanel.tsx` | Add persistent "check your email" panel after `signUp` returns no session. | Required signup-email-confirmation parity. |
| `superapp/apps/focal/client/src/features/auth/ResetPasswordScreen.tsx` | Add reset page with session wait, expired-link state, password validation, show/hide toggles, `updatePassword`, success redirect, and back-to-login sign-out/clear handling. | Required PKCE recovery and password reset parity. |
| `superapp/apps/focal/client/src/lib/supabaseErrors.ts` | Port `parseRetryAfterSec`, `UNKNOWN_429_COOLDOWN_LADDER_SEC`, and `getUnknownRateLimitCooldownSec`. | Avoid duplicate 429 parsing/cooldown code across credentials and forgot-password. |
| `superapp/apps/focal/client/src/lib/commonPasswords.ts` | Port `isCommonPassword` block-list helper. | Required by sign-up and reset password validation. |
| `superapp/apps/focal/client/src/features/landing/FocalLandingPage.tsx` | Add landing page ported from old-focal, adjusted to new imports, `focal.landing.*` i18n keys, existing UI tokens where reasonable, and public controls. | Required logged-out marketing landing parity. |
| `superapp/apps/focal/client/src/features/landing/index.ts` | Export `FocalLandingPage`. | Keeps imports consistent with feature folders. |
| `superapp/apps/focal/client/src/App.tsx` | Keep `/privacy` and `/terms` public; leave authenticated app routes unchanged except relying on `AuthGate` for logged-out `/`, `/landing`, `/login`, and `/reset-password`; ensure authed `/` still redirects to `/tasks`. | Required routing parity without backend changes. |
| `superapp/apps/focal/client/src/App.test.tsx` | Update routing tests for logged-out landing/login/reset and signed-in redirects while preserving legal and `/settings` behavior. | Proves routing did not regress. |
| `superapp/apps/focal/client/src/features/auth/LoginScreen.test.tsx` | Add component tests for sign-in/sign-up toggle, signup confirmation, forgot-password success/error/cooldown, credentials rate-limit cooldown, Google error, and not-configured state. | Proves login parity and named failure modes. |
| `superapp/apps/focal/client/src/features/auth/ResetPasswordScreen.test.tsx` | Add component tests for session wait, expired link, validations, known/unknown Supabase update errors, success clear/redirect, and back-to-login. | Proves recovery screen behavior independent of the provider. |
| `superapp/apps/focal/client/src/features/auth/AuthProvider.recovery.test.tsx` | Add provider tests for `/reset-password?code=` bootstrap, `PASSWORD_RECOVERY`, recovery flag TTL/clear, and non-recovery auth events not bypassing the reset screen. | Proves the PKCE recovery handshake and avoids auth bypass/regression. |
| `superapp/apps/focal/client/src/lib/supabaseErrors.test.ts` | Add pure unit tests for retry parsing and unknown-429 ladder. | Proves cooldown math without UI timing fragility. |
| `superapp/apps/focal/client/src/lib/commonPasswords.test.ts` | Add pure unit tests for case-insensitive common-password detection and empty input. | Proves password validation helper behavior. |
| `superapp/apps/focal/client/src/features/landing/FocalLandingPage.test.tsx` | Add smoke tests for section inventory, CTAs, legal links, and language/theme controls. | Proves landing parity at the DOM level. |
| `superapp/apps/focal/client/src/i18n/locales/en.json` | Add `translation.focal.auth.*` and `translation.focal.landing.*` keys, porting old-focal copy into the new namespace. | Required ru/en localization. |
| `superapp/apps/focal/client/src/i18n/locales/ru.json` | Add matching Russian `translation.focal.auth.*` and `translation.focal.landing.*` keys, including old-focal branding text. | Required ru/en localization and branding. |

# Implementation slices

1. Login parity: add `supabaseErrors` and `commonPasswords`; split `LoginScreen` into a container plus `AuthCredentialsForm` and `SignupConfirmationPanel`; add sign-up, forgot-password, PRIMA/legal links, FoCal branding with "Голосовой Календарь", localized Supabase error mapping, public controls, and credentials/forgot cooldowns. Keep the current logged-out fallback rendering `LoginScreen` so this slice is independently usable before landing routing exists.
2. Reset/recovery on PKCE: extend `AuthProvider` with recovery state and auth methods; add `ResetPasswordScreen`; wire `AuthGate` to show reset on `/reset-password`, `/reset-password?code=...`, or active recovery; use `/reset-password` as the reset email redirect target; keep Supabase config in `supabase.ts` unchanged.
3. Marketing landing and logged-out routing: add `FocalLandingPage` with the pinned section inventory; update `AuthGate`/`App` routing so signed-out `/` and `/landing` render landing, `/login` renders login, `/reset-password` renders reset, and signed-in public auth routes redirect to `/tasks`; update i18n and routing/landing tests.

# Tests

- `superapp/apps/focal/client/src/lib/supabaseErrors.test.ts`: proves retry-after parsing supports seconds, minutes, combined minutes+seconds, empty/unparseable messages, and the unknown-429 cooldown ladder caps at 900s.
- `superapp/apps/focal/client/src/lib/commonPasswords.test.ts`: proves common password detection is case-insensitive, does not flag empty input, and catches the passwords used by sign-up/reset validation tests.
- `superapp/apps/focal/client/src/features/auth/LoginScreen.test.tsx`: proves sign-in still calls Supabase through context; sign-up validates confirm password/common password and calls `signUp` with `emailRedirectTo`; `data.session === null` renders `SignupConfirmationPanel`; forgot-password trims email, calls `resetPasswordForEmail` with `/reset-password`, starts 60s success cooldown, maps 429s, and escalates unknown 429 copy on the second consecutive error; credentials 429 blocks sign-in/sign-up/Google across form remount; unknown Supabase/SDK errors show localized generic copy without leaking raw English messages.
- `superapp/apps/focal/client/src/features/auth/ResetPasswordScreen.test.tsx`: proves reset renders a spinner while recovery session is pending, shows expired-link UI after the wait window without clearing recovery automatically, validates min/max/common/mismatch/confirm locally, calls `updatePassword` on valid submit, maps `same_password` and `weak_password`, logs unknown errors while showing generic copy, clears recovery and redirects on success, and uses sign-out/clear on back-to-login.
- `superapp/apps/focal/client/src/features/auth/AuthProvider.recovery.test.tsx`: proves `/reset-password?code=...` sets recovery before the app can flash authenticated content, `PASSWORD_RECOVERY` stores session and clears loading, stale recovery localStorage is ignored, `clearPasswordRecovery` removes the flag, and non-recovery auth events cannot overwrite an active recovery session.
- `superapp/apps/focal/client/src/features/landing/FocalLandingPage.test.tsx`: proves the old landing section inventory is present, CTAs point to `/login` and `/login#signup`, footer links point to `/privacy` and `/terms`, and public controls render.
- `superapp/apps/focal/client/src/App.test.tsx`: proves logged-out `/` and `/landing` render landing, logged-out `/login` renders login, logged-out `/reset-password` renders reset/expired state, signed-in `/` redirects to `/tasks`, signed-in `/landing` and `/login` redirect to `/tasks`, and `/privacy` plus `/terms` remain public.
- Verification command: `cd superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.

# Error & rescue map

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| `supabase-not-configured` | Missing `VITE_SUPABASE_URL` or `VITE_SUPABASE_PUBLISHABLE_KEY`; `isSupabaseConfigured()` false or `getSupabase()` would throw. | `LoginScreen`/auth actions guard before calling Supabase. | Localized "Authentication is not configured" public auth state; no crash. |
| `credentials-client-validation` | Empty/invalid email, empty password, sign-up password length >72 or <8, common password, empty confirm, mismatch. | `AuthCredentialsForm.validate`. | Inline localized validation error; no Supabase call. |
| `credentials-rate-limited` | Supabase credentials call returns status `429` or code `over_email_send_rate_limit`. | `AuthCredentialsForm.handleSubmit` via `handleRateLimit`. | Localized rate-limit copy; submit and Google disabled until cooldown expires; persistent copy on repeated unknown 429. |
| `credentials-supabase-denied` | Known Supabase codes such as `invalid_credentials`, `email_not_confirmed`, `user_banned`, `user_already_exists`, `weak_password`, `signup_disabled`. | `AuthCredentialsForm.handleMappedError`. | Specific localized inline message. |
| `credentials-unmapped-error` | Unknown Supabase code/message or thrown SDK/network error. | `AuthCredentialsForm.handleMappedError` / `catch`. | Generic localized inline message; raw code/message only in `console.warn`. |
| `oauth-start-failed` | `signInWithOAuth` returns error or throws. | `AuthCredentialsForm.handleGoogle`. | Generic localized Google sign-in error; form remains usable. |
| `signup-email-confirmation` | `signUp` succeeds with `data.session === null`. | `AuthCredentialsForm` signals `LoginScreen`. | Persistent check-email panel with submitted address and back-to-sign-in button. |
| `forgot-empty-email` | Forgot-password submit with blank email. | `ForgotPasswordForm.handleSubmit`. | Inline localized email-required error; no Supabase call. |
| `forgot-rate-limited` | `resetPasswordForEmail` returns status `429` or code `over_email_send_rate_limit`. | `ForgotPasswordForm.handleSubmit`. | Localized rate-limit copy; send button disabled until cooldown expires; persistent copy on repeated unknown 429. |
| `forgot-request-failed` | Unknown Supabase error or thrown SDK/network error during password-reset email request. | `ForgotPasswordForm.handleSubmit` / `catch`. | Generic localized inline error; raw code/message only in `console.warn`. |
| `pkce-recovery-code-exchange-pending` | User lands on `/reset-password?code=...`; Supabase has not emitted `PASSWORD_RECOVERY` or populated session yet. | `AuthProvider` sets `isPasswordRecovery`; `ResetPasswordScreen` waits for session. | Reset spinner, not landing/login/authed app. |
| `pkce-recovery-code-expired-or-missing` | No recovery session appears before the reset screen wait expires. | `ResetPasswordScreen` local timer. | Localized expired-link state and back-to-login action; recovery flag is not auto-cleared before the user sees the message. |
| `password-update-validation` | New password fails length/common/confirm checks. | `ResetPasswordScreen.handleSubmit`. | Inline localized validation error; no Supabase update call. |
| `password-update-rejected` | `updateUser({ password })` returns known `same_password` or `weak_password`, unknown error, or throws. | `ResetPasswordScreen.handleSubmit`. | Specific localized message for known errors; generic localized message for unknown/thrown errors; raw diagnostics only in `console.warn`. |
| `back-to-login-during-recovery` | User exits expired or active reset state. | `ResetPasswordScreen.handleBackToLogin` calls `signOut`/clear path through provider. | User lands on `/login` with recovery flag and local session cleared. |
| `authed-public-auth-route` | Signed-in user visits `/login`, `/landing`, or `/reset-password` outside active recovery. | `AuthGate`. | Redirect to `/tasks`; no public auth screen over an active session. |

# Review lenses (pre-answer before gate2-plan)

- **Scope / strategy** - This is the minimum in-client parity cut requested by the task: no `@allosta/auth`, no backend, no Supabase config change, no SSO package. Existing code already solves Supabase client creation, token wiring, sign-out, public legal pages, theme/language controls, UI primitives, and i18n bootstrapping. The decision is reversible because new auth/landing components stay inside the focal client and can later be extracted.
- **Architecture** - `AuthProvider` remains the only owner of session and API-token side effects. Forms map user-visible auth errors but do not mint or inspect tokens. Recovery is a provider state plus reset screen, not a client-side auth bypass: the reset screen can call `updatePassword` only after Supabase establishes a recovery session. Query cache clearing and server-side revoke behavior stay intact.
- **Design** - Public screens need loading, disabled, error, success, expired-link, email-confirmation, not-configured, light/dark, keyboard focus, and mobile layout states. Landing uses the old section order and mockups; auth screens use old-focal FoCal branding plus existing public theme/language controls.
- **DevEx** - Helper functions for rate-limit parsing and common passwords are pure and tested. Tests mock auth methods at the context boundary where possible, leaving Supabase env-driven. New files follow existing feature-folder and i18n namespace patterns (`translation.focal.*`).

# Risks & migrations

- No DB migration, backend change, or Supabase project config change.
- Existing env names stay `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY`; optional `VITE_PRIMA_URL` continues to control the PRIMA cross-link.
- Main risk is recovery routing: a bad PKCE handshake can flash the app or strand the user. Mitigation is `AuthProvider.recovery.test.tsx` plus `ResetPasswordScreen.test.tsx` for pending/expired/success paths.
- Main UX risk is copied landing density on mobile. Mitigation is DOM smoke coverage plus keeping old responsive classes and using existing tokens where the new app already differs.
- Rollback is frontend-only: revert the auth/landing components, routing changes, helper additions, tests, and i18n keys.

# Scope check

- [x] Matches the task's Scope and Out of scope
- [x] Small enough to review in one sitting when built as the three listed slices
- [x] Size smell: this touches many frontend files because the requested parity includes landing, sign-up, forgot-password, reset, routing, tests, and i18n; the three slices keep each review focused and independently green

# Out of scope

- Shared `@allosta/auth` package or cross-app SSO.
- Backend/FastAPI/schema changes.
- Supabase project configuration, secrets, or new env variables.
- Moving landing to `allosta.com`.
- Re-skinning authenticated Focal app screens beyond redirects needed for logged-out routing.
- Adding resend-confirmation email; old confirmation panel explicitly did not include resend.

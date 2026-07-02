# Stage

3-gate flow (gate C — verify/ship) for the `focal-parity-auth-landing` slice. Branch
`feat/focal-parity-auth-landing` → base `feature/focal-migration`, one commit. Frontend-only; no
server/API/schema change. Gates: A design 9.3 · B build 9.2 · C verify 9.4 (all APPROVED).

# What changed

Ports old-focal's **logged-out surface** onto the new Focal client (React 19 / Tailwind 4 / typed
client / Supabase PKCE), so a logged-out visitor gets the full experience instead of a bare sign-in:
- **Marketing landing** (`features/landing/FocalLandingPage`) at logged-out `/` and `/landing` —
  brand + tagline, feature mockups, sections, CTAs, `PublicToggles` (theme + language).
- **Login** (`features/auth/LoginScreen` + `AuthCredentialsForm`) — email/password **sign-in and
  sign-up** (confirm-password, length + common-password checks), Google, FoCal branding,
  privacy/terms links, optional PRIMA cross-link, localized Supabase error mapping, 429 cooldown.
- **Signup confirmation** (`SignupConfirmationPanel`) — "check your email" when sign-up returns no
  session.
- **Password reset / recovery** (`ResetPasswordScreen`) on the Supabase **PKCE** flow:
  `resetPasswordForEmail` → `/reset-password?code=` → `PASSWORD_RECOVERY` → `updateUser`.
- **`AuthProvider`** gains `signUp` / `requestPasswordReset` / `updatePassword` + a recovery signal;
  **recovery is session-backed, never a client auth bypass** — `isPasswordRecovery` is set only by
  the `PASSWORD_RECOVERY` event, the reset form is operable only under confirmed recovery + a
  session, a delayed `getSession` or stray event can't clobber it, and a recovery for a different
  user clears the prior user's cache.
- **`AuthGate`** routes logged-out `/`·`/landing` → landing, `/login` → login, recovery → reset;
  signed-in `/login`·`/landing`·`/reset-password` → `/tasks`.
- i18n `focal.auth.*` (96) + `focal.landing.*` (149) keys, ru + en parity.

# Files touched

20 files under `apps/focal/client/src/` — added: `features/auth/{AuthCredentialsForm,SignupConfirmationPanel,ResetPasswordScreen}.tsx`, `features/landing/{FocalLandingPage,index}.tsx`, `lib/{supabaseErrors,commonPasswords}.ts` + their tests, `features/auth/{LoginScreen,ResetPasswordScreen,AuthProvider.recovery}.test.tsx`, `features/landing/FocalLandingPage.test.tsx`; changed: `features/auth/{AuthProvider,LoginScreen,AuthGate,index}.tsx`, `App.tsx`/`App.test.tsx`, `i18n/locales/{en,ru}.json`.

# Tests run

```sh
cd superapp/apps/focal/client
pnpm typecheck && pnpm lint && pnpm test:run && pnpm build
```

# Verification output

```
tsc -b           → 0 errors
biome check .    → 322 files, 0 errors
vitest run       → 105 files, 1240 tests passed
vite build       → built
```

# Still needs review

- Frontend-only; identity stays Supabase env-driven (publishable key only); no secrets.
- The adversarial gates caught + fixed **two real recovery-security bugs** (initial `getSession`
  clobbering a confirmed recovery session; the recovery branch skipping the cross-user cache clear) —
  both now guarded and regression-tested.
- Deferred (not this slice): the shared `@allosta/auth` package + cross-app SSO (login can migrate to
  it later); pre-existing bundle-size advisory; HIBP password check.

# PR / release notes (for users)

Focal's logged-out experience is now complete. Visitors land on a **marketing home page**, can
**register** (with email confirmation), **sign in** (email/password or Google), and **reset a
forgotten password** via a secure email link — all with the FoCal branding, privacy/terms links, and
ru/en + light/dark. Password recovery only works from a genuine reset link (it can't be reached or
used from a normal session), and signing in mid-reset can't expose another account's data.

(No secrets, tokens, keys, or PII in this change — client components, an auth context, locale
strings, and tests.)

# Status

3-GATE APPROVED — A design 9.3 · B build 9.2 · C verify 9.4 (Opus release gate, all four checks
independently green: 1240 tests, lint, typecheck, build). Cleared for release.

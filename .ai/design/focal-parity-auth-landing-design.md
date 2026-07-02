# Design: focal-parity-auth-landing

## Problem & decision

The new Focal client's **logged-out experience** is a bare sign-in screen: `AuthGate` renders
`LoginScreen` (email/password + Google) and nothing else. The production reference `apps/old-focal`
ships, for logged-out users, a **marketing landing** (`FocalLanding.tsx`), a **login** with
**sign-up + forgot-password**, a **password-reset/recovery** page, and old-focal branding (FoCal mark
+ "Голосовой Календарь"), privacy/terms links, and a PRIMA cross-link. So a new user **cannot
register** and a locked-out user **cannot recover a password** in the new app. The user verified this
against the live reference and asked for full parity in the focal client.

**Decision:** port old-focal's logged-out surface (landing + full login + reset) onto the new stack
(React 19 / Tailwind 4 / typed client / Supabase **PKCE**), behind the existing `AuthGate`, with
`AuthProvider` extended to own the new actions + the recovery signal. **Rejected:** (a) *defer to a
shared `@allosta/auth` package* — it doesn't exist (no `packages/`, `shared/` is server-only), so the
gap is real now; ship in-client and migrate later if that package lands; (b) *login essentials only,
skip the landing* — user explicitly wants the landing; (c) *transliterate old-focal's hash
`type=recovery`* — the new client is PKCE (`detectSessionInUrl`), so recovery is re-expressed on
`?code=` + `PASSWORD_RECOVERY`, not the dead hash flow.

## Assumptions & scope

- Assumption (**confirmed**, user): full parity in the focal client — landing **and** login
  (sign-up + forgot) + reset served from `focal.allosta.com`, not deferred to `@allosta/auth`/allosta.com.
- Assumption (**confirmed**, fs): `@allosta/auth` does not exist; new `features/auth` has only
  `AuthGate`/`AuthProvider`/`LoginScreen`/`supabase`; the new Supabase client is PKCE.
- Assumption (**confirmed**, docs): Supabase `resetPasswordForEmail` supports PKCE + the
  `PASSWORD_RECOVERY` → `updateUser` flow; `signUp` supports `emailRedirectTo` (pinned `@supabase/auth-js` 2.107).
- Assumption (**confirmed**, design): landing header uses the new client's `PublicToggles`
  (language + theme), a deliberate minor divergence from old-focal's language-only header, for
  consistency with the already-shipped public legal pages.
- Out of scope: the `@allosta/auth` package + cross-app SSO; any backend/Supabase-config/schema
  change; moving the landing to allosta.com; re-skinning the authed app; resend-confirmation email
  (old-focal had none).
- Open questions: None blocking. (Sign-in rate-limit cooldown is ported 1:1 from old-focal; recovery
  handshake pinned below.)

## Success criteria

- [ ] Logged-out `/` and `/landing` render the marketing landing (old-focal section inventory + CTAs
      + branding); `/login` offers sign-in **and** sign-up toggle + forgot-password; signup with no
      session shows the "check your email" panel.
- [ ] A recovery link (`/reset-password?code=`) opens the reset screen (not landing/login/app), sets
      a new password via `updateUser`, and on success clears recovery + redirects to the app; an
      expired/missing recovery shows a localized "link expired" + back-to-login.
- [ ] Branding (FoCal + tagline), privacy/terms links, PRIMA cross-link present; all strings i18next
      **ru + en**; light + dark; recovery on PKCE with no dead hash-flow code.
- [ ] `cd superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green.
- [ ] No secrets; Supabase env-driven; recovery is not a client auth bypass.

## Build approach (slices)

| # | slice | files | main failure mode | what its test proves |
|---|-------|-------|-------------------|----------------------|
| 1 | Login parity | `lib/supabaseErrors.ts`, `lib/commonPasswords.ts`, `features/auth/{LoginScreen,AuthCredentialsForm,SignupConfirmationPanel}.tsx`, `AuthProvider.tsx` (add `signUp`,`requestPasswordReset`), i18n | unmapped Supabase error leaks raw English / 429 not throttled | sign-in/sign-up toggle, confirm+common-password validation, signup-confirmation on null session, forgot success+60s cooldown, credentials 429 disables submit+Google, generic copy without raw leak |
| 2 | Reset/recovery on PKCE | `AuthProvider.tsx` (add `updatePassword`,`isPasswordRecovery`,`clearPasswordRecovery` + handshake), `features/auth/ResetPasswordScreen.tsx`, `AuthGate.tsx` | recovery flashes the authed app / stale flag forces reset later | `/reset-password?code=` sets recovery before authed flash; `PASSWORD_RECOVERY` stores session; stale flag ignored (TTL); non-recovery event can't overwrite recovery; pending/expired/success states |
| 3 | Landing + logged-out routing | `features/landing/{FocalLandingPage,index}.tsx`, `AuthGate.tsx`, `App.tsx`, `App.test.tsx`, i18n | logged-out `/` shows login instead of landing / signed-in sees public auth screens | logged-out `/`+`/landing`→landing, `/login`→login, `/reset-password`→reset; signed-in public-auth routes→`/tasks`; `/privacy`+`/terms` stay public; landing section inventory + CTAs |

## Architecture & contracts

```
AuthProvider (owns session + token wiring + recovery signal)
 └─ AuthGate (logged-out router)
     ├─ isPasswordRecovery || /reset-password  → ResetPasswordScreen
     ├─ session==null: / or /landing → FocalLandingPage ; else /login → LoginScreen(container)
     └─ session!=null → children ; /login·/landing·/reset-password → Redirect /tasks
/privacy, /terms → public (unchanged)
```

| entity / interface | change | notes |
|--------------------|--------|-------|
| `AuthProvider` context | add `signUp(email,pw)→{ok,code?,needsConfirmation?}`, `requestPasswordReset(email)→{ok,code?}` (calls `resetPasswordForEmail(email,{ redirectTo: origin + '/reset-password' })`), `updatePassword(pw)→{ok,code?}`, `isPasswordRecovery`, `clearPasswordRecovery()` | existing `signIn`/`signInWithGoogle`/`signOut`/`session`/`user`/`loading` unchanged; preserve 401→signOut, server revoke, query-cache clear |
| recovery state | add | set synchronously on `/reset-password?code=` mount **and** on `PASSWORD_RECOVERY`, **before** the `userChanged → queryClient.clear()` path; TTL-guarded localStorage flag so a stale flag is ignored |
| `LoginScreen` | rewrite → container | branding + sign-in/sign-up toggle + forgot view + `SignupConfirmationPanel` + PRIMA/legal links + `PublicToggles` + not-configured state |
| `AuthCredentialsForm`, `SignupConfirmationPanel`, `ResetPasswordScreen` | add | reusable credentials form, check-email panel, reset screen |
| `lib/supabaseErrors.ts`, `lib/commonPasswords.ts` | add | pure: 429 retry parse + unknown-429 ladder (cap 900s); common-password block-list — shared by credentials/forgot/reset |
| `features/landing/FocalLandingPage` | add | ported sections on new imports + `focal.landing.*` i18n + `PublicToggles` |
| data model | **None** | no DB/server state; only the TTL recovery flag + reused env (`VITE_SUPABASE_*`, optional `VITE_PRIMA_URL`) |
| reuse-first | — | `getSupabase()`/`isSupabaseConfigured()`, `PublicToggles`, UI primitives, `translation.focal.*` namespace, existing 401/revoke — not rebuilt |

## Flow (happy + unhappy)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| happy — sign in | valid creds | `AuthCredentialsForm`→`signIn` | session → authed app |
| happy — sign up (confirm) | `signUp`→`session===null` | `LoginScreen`→`SignupConfirmationPanel` | "check your email" with the address |
| happy — forgot | submit email | `ForgotPasswordForm`→`requestPasswordReset` | success copy + 60s cooldown |
| happy — recovery | `/reset-password?code=`→`PASSWORD_RECOVERY` | provider sets recovery; `ResetPasswordScreen` | `updatePassword` → success → redirect to app |
| not configured | missing Supabase env | guards before any Supabase call | localized "auth not configured"; no crash |
| client validation | bad email / short / common / mismatch | `validate` (credentials/reset) | inline error; no network call |
| rate limited (429) | Supabase 429 / `over_email_send_rate_limit` | shared `handleRateLimit` | localized cooldown; submit+Google disabled until expiry; escalating copy on repeat |
| mapped auth error | `invalid_credentials`/`email_not_confirmed`/`user_banned`/`user_already_exists`/`weak_password`/`signup_disabled` | `handleMappedError` | specific localized inline message |
| unmapped error | unknown code / thrown SDK / network | `catch` | generic localized message; raw only in `console.warn` |
| recovery pending | on `/reset-password?code=`, no session yet | `ResetPasswordScreen` wait | spinner (not landing/login/app) |
| recovery expired | no recovery session before wait expires | reset screen timer | localized "link expired" + back-to-login; flag not auto-cleared |
| authed on public-auth route | signed-in visits `/login`·`/landing`·`/reset-password` (no active recovery) | `AuthGate` | redirect to `/tasks` |

## Test strategy, security & rollback

- **Test strategy:** *Unit (pure)* — `supabaseErrors` (retry-after incl. minutes+seconds, ladder cap
  900s), `commonPasswords` (case-insensitive, empty). *Component* — `LoginScreen` (toggle, validation,
  signup-confirmation, forgot success/error/cooldown, 429 disables submit+Google, generic-copy-no-leak);
  `ResetPasswordScreen` (pending/expired/validation/`same_password`+`weak_password`/success+redirect/back-to-login).
  *Provider* — `AuthProvider.recovery` (code-bootstrap before authed flash, `PASSWORD_RECOVERY`, stale-flag
  TTL ignore, `clearPasswordRecovery`, **non-recovery event cannot overwrite recovery**). *Routing* —
  `App.test` (logged-out landing/login/reset, signed-in→/tasks, privacy/terms public). *Landing* — DOM smoke
  (sections, CTAs→`/login`(+`#signup`), footer→legal, public controls). "Verified" = the 4 client checks green.
- **Security:** recovery is **not** a client auth bypass — `updatePassword` works only after Supabase
  establishes a recovery session; the no-overwrite guard + TTL prevent a stray event / stale flag from
  dropping the user into the app or forcing a spurious reset. No secrets — publishable Supabase key
  only, env-driven; raw Supabase error text goes to `console.warn`, never the UI. Preserve 401→signOut,
  best-effort server revoke, identity-change cache clear (recovery ordered ahead of it).
- **Rollback:** frontend-only — revert the listed client files, routing, helpers, tests, i18n. One PR
  (`feat/focal-parity-auth-landing` → `feature/focal-migration`); may land as the 3 slices above.

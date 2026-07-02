# Goal

Bring the new Focal client's **logged-out experience** to parity with `apps/old-focal`: a marketing
**landing page**, a full **login** (email/password **sign-in + sign-up**, **forgot-password**),
a **password-reset / recovery** page, and the old-focal **branding** (FoCal logo + tagline,
privacy/terms links, the PRIMA cross-link). Today the new app shows only a bare sign-in screen.

# Scope

- **Landing** — port `apps/old-focal/.../pages/FocalLanding.tsx` (hero, feature mockup, sections,
  CTAs, language toggle) onto the new stack; shown to logged-out visitors at `/` (and `/landing`).
- **Login** — extend `features/auth/LoginScreen.tsx`: sign-in **+ sign-up toggle** (confirm-password,
  password policy), **forgot-password** form (`resetPasswordForEmail` + cooldown), Google button,
  branding, privacy/terms links, PRIMA cross-link, localized error mapping.
- **Signup confirmation** — the "check your email" panel after sign-up returns no session.
- **Password reset/recovery** — a reset page handling Supabase recovery (new **PKCE `?code=`** flow,
  not old-focal's hash `type=recovery`): set new password via `updateUser`, expired-link state.
- **Auth routing** — `AuthGate`/`App` render landing for logged-out `/`, login at `/login`, the reset
  page on a recovery callback; `/privacy` + `/terms` already public.
- i18n ru+en for all new strings; light + dark.

# Out of scope

- The shared `@allosta/auth` package and cross-app SSO (does not exist yet; this slice ships in the
  focal client now and migrates later if that package lands).
- Backend auth changes — Supabase handles identity; no FastAPI/schema change.
- Moving the landing to the `allosta.com` umbrella site (user chose full parity in the focal client).

# Acceptance criteria

- [ ] Logged-out `/` shows the marketing landing (parity with old-focal sections/CTAs); `/login`
      shows login with a working sign-up toggle and forgot-password; a recovery link opens the reset
      page and sets a new password.
- [ ] Branding (FoCal mark + tagline), privacy/terms links, and the PRIMA cross-link are present;
      all strings via i18next in ru + en; light + dark.
- [ ] `cd superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run &&
      pnpm build` green, with tests for the sign-up/forgot/reset paths.
- [ ] No secrets; Supabase keys stay env-driven; no client-side auth bypass.

# Verification commands

```sh
cd superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```

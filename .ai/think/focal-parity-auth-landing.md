# Problem

The new Focal client's **logged-out experience** is a bare sign-in screen: `AuthGate` renders
`LoginScreen` (email/password + Google) and nothing else. The production reference `apps/old-focal`
ships, for logged-out users, a full **marketing landing** (`FocalLanding.tsx`, 685 lines), a
**login** with **sign-up** + **forgot-password** (`LoginPage.tsx` 406 + `AuthCredentialsForm` +
`SignupConfirmationPanel`), and a **password-reset/recovery** page (`ResetPasswordPage.tsx` 338),
plus old-focal branding (FoCal mark + "Голосовой Календарь" tagline), privacy/terms links, and a
PRIMA cross-link. The user verified this against the live reference and asked for full parity.

This area was marked **Out of scope** in the parity epic on the assumption that login/registration
move to a shared `@allosta/auth` package (per `superapp/CLAUDE.md`) and marketing to the
`allosta.com` umbrella site. But **that package does not exist** (no `packages/`, no `@allosta/auth`
anywhere; `shared/` is server-only), so the gap is **real and uncovered now** — a new user cannot
register and a locked-out user cannot recover a password in the new app. The user has explicitly
brought landing + auth **into scope** as a focal-client slice (overriding the epic's deferral); a
later migration to a shared package is an optional refactor, not a blocker.

One real technical wrinkle: old-focal's recovery used the URL **hash** (`type=recovery`), but the
new client's Supabase is configured for the **PKCE `?code=`** flow (`detectSessionInUrl`), and the
new `AuthProvider` has **no** `PASSWORD_RECOVERY` handling. So recovery must be re-expressed on PKCE,
not transliterated from old-focal.

# Assumptions

- **[confirmed — user]** Full parity in the focal client: landing **and** login (sign-up + forgot) +
  reset, served from `focal.allosta.com` itself — not deferred to `@allosta/auth` / `allosta.com`.
- **[confirmed — fs]** `@allosta/auth` does not exist yet; the new `features/auth` has only
  `AuthGate`, `AuthProvider`, `LoginScreen`, `supabase`; no landing, signup, forgot, or reset.
- **[confirmed — fs]** New Supabase client uses PKCE (`?code=` + `detectSessionInUrl`); recovery is
  re-expressed on PKCE: `resetPasswordForEmail({ redirectTo })` → callback exchanges the code →
  `updateUser({ password })`. The `AuthProvider` gains a recovery-state signal so the reset page
  shows before the app does.
- **[confirmed — audit]** old-focal is the look/behavior spec: `FocalLanding`, `LoginPage` (+
  `AuthCredentialsForm`, `SignupConfirmationPanel`, `ForgotPasswordForm`), `ResetPasswordPage`,
  `PublicLayout`/`PublicSidebar`. Reproduced on React 19 / Tailwind 4 / typed `api/*` — not lifted.
- **[unverified — settle at design/build]** exact landing section inventory + i18n keys to reuse
  verbatim; whether to keep old-focal's sign-in error rate-limit cooldown 1:1; whether the landing
  also needs the `PublicLayout` sidebar (old-focal used it only for logged-out privacy/terms).

# Options considered

| # | Option | What it is | Pros | Cons |
|---|--------|-----------|------|------|
| **A — Port landing + full login + reset into the focal client (chosen)** | Re-express old-focal's `FocalLanding` + `LoginPage` (signup/forgot) + `ResetPasswordPage` on the new stack; wire recovery on PKCE; branding/PRIMA/legal links; i18n ru+en. | Closes the real, uncovered gap now; exact-parity logged-out experience; uses the look old-focal already proves; self-contained slice. | Duplicates work that a future `@allosta/auth` may absorb (login portion); a sizeable slice (~1.4k reference lines). |
| **B — Login essentials only, defer landing** | Sign-up + forgot + reset + branding, no marketing landing. | Smaller; unblocks register/recover. | User explicitly wants the landing too. **Rejected.** |
| **C — Build the shared `@allosta/auth` package now** | Proper cross-app login UI + SSO. | Right long-term architecture. | Much larger, cross-app, and the landing still needs a home; blocks parity on infra not asked for. **Rejected for now.** |

# Recommendation

**Option A — port the landing + full login + reset into the focal client.** The shared package
doesn't exist, the gap is real (no registration / no password recovery), and old-focal is a ready,
proven spec. Build it as one parity slice on the new stack, wiring recovery on the PKCE flow the new
client already uses. If `@allosta/auth` later lands, the **login** portion migrates to it; the
landing stays focal's (or moves to `allosta.com`) — neither is blocked by shipping this now.

Likely build sub-slices (settle at the plan gate): **(1)** login parity — sign-up toggle + signup
confirmation + forgot-password + branding/PRIMA/legal on `LoginScreen`, with `AuthProvider`
sign-up/reset methods; **(2)** password reset/recovery page on PKCE + the `AuthGate` recovery route;
**(3)** marketing landing + logged-out routing (`/` → landing, `/login`, `/landing`).

# Out of scope

- The `@allosta/auth` shared package and cross-app SSO (deferred; this ships in-app, migrates later).
- Backend / Supabase config changes beyond what the client calls (identity stays Supabase-managed).
- Moving the landing to `allosta.com` (user chose in-app parity).
- Re-skinning the already-shipped authed app (separate epic) — this slice is the logged-out surface.

# Open questions

- **Recovery on PKCE** — confirm the exact Supabase recovery handshake for this project
  (`resetPasswordForEmail` redirect target + how the reset page detects the recovery session) at the
  design gate; old-focal's hash flow is not reusable verbatim.
- **Branding** — old-focal shows "FoCal · Голосовой Календарь" on auth but "Focal · Система
  осознанного планирования" on the landing; reproduce both as-is (i18n) unless told to unify.
- **Sign-in hardening** — port old-focal's rate-limit cooldown + escalating copy 1:1, or keep the
  new client's simpler mapping plus the new fields? Settle at design.

# Success criteria

- [ ] Logged-out `/` renders the marketing landing (sections/CTAs/branding parity with old-focal);
      `/login` offers sign-in **and** sign-up + forgot-password; a recovery link opens the reset page
      and sets a new password; signup-confirmation panel shown when email confirmation is pending.
- [ ] Branding, privacy/terms links, PRIMA cross-link present; all strings i18next ru + en; light +
      dark; recovery re-expressed on PKCE (no dead hash-flow code).
- [ ] `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green with tests for
      sign-up / forgot / reset paths; no secrets; no client-side auth bypass.

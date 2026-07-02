# Design: focal-cutover-seams

<!-- The complete pre-build design for the 3-gate flow (gate A). One cohesive document. Closes the
six integration "seams" surfaced by `/gate-explore migration` (see `.ai/notes/migration.md`). -->

## Problem & decision

The Focal Express→FastAPI migration is architecturally sound, but `/gate-explore migration`
(`.ai/notes/migration.md`, 2026-06-28) found the remaining cutover risk concentrated in six
**integration seams** — the joints between client, proxy, server, auth, and CI — not the core
design. This feature closes them as **independent, individually-shippable slices**, each its own PR
back into `feature/focal-migration` (per `apps/focal/CLAUDE.md` "one task = one slice = one PR").

**Decision:** treat the six seams as one design with six slices, ordered cheap-correctness-first then
the high-impact user-facing build then CI hardening. Two seams force a real choice:

1. **Prod API topology.** The migration plan already **decided same-origin** —
   `focal.allosta.com/api/*` proxied to Railway, so `GOOGLE_REDIRECT_URI`, `WEBHOOK_BASE_URL`,
   iCal/booking URLs and `VITE_API_URL` all derive from one origin (`MIGRATION_PLAN.md:36-39`). We
   **honor that decision**. The catch (verified against Cloudflare docs): Pages `_redirects`/
   `_routes.json` **cannot** proxy to an *external* origin like Railway — same-origin requires **edge
   compute** (a committed Cloudflare **Pages Function** or a Worker route bound to `focal.allosta.com/api/*`).
   So "codify the proxy" means **commit a Pages Function**, not a static rewrite file. The simpler
   *cross-origin* alternative (set `VITE_API_URL` to the Railway origin + lean on the already-present
   CORS middleware, `main.py:77-84`) is **rejected** because it contradicts the same-origin decision
   and breaks the same-origin-derived URLs — but it is recorded here so the user can overturn the
   topology call before slice 2 builds (see Open questions).
2. **Auth recovery scope.** The cutover-critical core is **forgot/reset password** for the ~163
   EXISTING users who are all signed out at flip (`CUTOVER_RUNBOOK.md:89`) and must be able to
   recover a forgotten password — built focal-local by porting PRIMA's already-shipped screens.
   old-focal **does** have self-serve signup (`sign_up` mode + `supabase.auth.signUp` —
   `apps/old-focal/client/src/pages/LoginPage.tsx:284`, `components/AuthCredentialsForm.tsx`), but
   self-registration is **not needed to migrate existing users** (they already have accounts), so
   signup + email-verify are **deferred to a post-cutover follow-up** — a real surface intentionally
   dropped from this slice, NOT claimed absent — flagged for product/ops sign-off that new-user
   signup can lag the flip. SSO magic-link consume stays deferred too (documented, no consumer yet).

Reuse-first throughout: auth recovery **ports PRIMA's built+tested screens** (`recovery.ts`,
`ForgotPasswordScreen`, `ResetPasswordScreen`, `useRecoveryMode`, `useResendCooldown`,
`passwordPolicy`); E2E **ports PRIMA's Playwright harness**; the route-diff **extends the existing
`contract-freeze/_check_routes.py`** rather than a new tool.

## Assumptions & scope

- Assumption (confirmed): **focal-local UI/auth, no `@allosta/*` package** for the migration window —
  `apps/focal/CLAUDE.md` / `MIGRATION_PLAN.md:133`. So recovery screens are copied into focal, not
  extracted to a shared package.
- Decision (needs product sign-off): old-focal **has** self-serve signup, but it is **deferred
  post-cutover** — migrating the ~163 existing users needs forgot/reset, not new-user
  self-registration. Signup + email-verify are a follow-up slice, explicitly out of scope here.
- Assumption (confirmed): **same-origin is the chosen prod topology** (`MIGRATION_PLAN.md:36-39`).
- Assumption (confirmed): the client already sources types from generated OpenAPI (`client.ts:1-12`),
  so a drift gate is additive, not a refactor.
- Assumption (unverified): the same-origin `/api/*`→Railway proxy is a **Pages Function / Worker**
  (Cloudflare docs rule out external-origin `_redirects`). Exact mechanism (Pages Function vs a
  zone-level Worker route) to confirm with whoever owns the Cloudflare account at slice 2.
- Assumption (unverified): **Supabase prod** has (or will get) a password-reset email template + the
  `focal.allosta.com/reset-password` redirect URL allow-listed. This is ops config, not in-repo; the
  runbook already requires "verify a password-reset email actually sends from superapp-prod"
  (`CUTOVER_RUNBOOK.md:91`). Slice 3 depends on it for an end-to-end pass.
- Assumption (unverified): `shared-calendars/:id/sync-settings` (old-focal `routes.ts:7648`, absent
  from the new router) is **UI-exposed**; if it is, it's a flip-blocker port in slice 4; if not, it's
  classified post-flip.
- Out of scope (owned elsewhere / deferred):
  - **Prod RLS bootstrap + the `data_scope`/`resolve_data_owner` authz audit** — the higher-priority
    *parallel* track owned by `focal-migration-assessment.md` ("Round 2 refresh"). Not a seam; not
    this feature. Called out so it isn't assumed covered here.
  - **CRM/contacts port** — stays the interim cross-app PRIMA-contacts path
    (`features/calendar/primaContacts.ts`) per the crm-boundary ADR; slice 4 only *classifies* it +
    ensures its prod wiring is on the env checklist.
  - **`/api/ai-agent/*` Phase-8 build** — already deferred; slice 2 only proxies it to parked Express.
  - **Self-serve signup, email-verify, SSO magic-link consume.**
- Open questions (must be answered before/within the relevant slice):
  1. **Confirm prod topology** = same-origin (slice 2 builds a Pages Function) vs cross-origin
     (slice 2 becomes "set `VITE_API_URL` + lock CORS"). Default: same-origin.
  2. **Flip-blocker classification sign-off** — slice 4 produces the proposed pre/post-flip list
     (the still-open ALL-204 mapping); the user ratifies which families block the flip.

## Success criteria

<!-- These become the gate-C tests. -->
- [ ] **No browser request path lives outside `/api/*`** — `getMe` calls `/api/me`, the `me` router
      is mounted under `/api`, `/health` stays bare (orchestration-only), and a guard test asserts no
      client `apiFetch` first-arg is a non-`/api` path. `openapi.d.ts` regenerated.
- [ ] **The prod `/api` proxy is a reviewable, committed artifact** (Pages Function/Worker) that
      routes `/api/*`→Railway and `/api/ai-agent/*`→parked-Express, with static assets + SPA fallback
      not shadowing `/api/*`; a documented smoke matrix (the runbook step-7 curls) passes on
      `focal-dev.allosta.com`.
- [ ] **A user can reset a forgotten password end-to-end on focal** — request reset → email →
      `/reset-password` screen detects the recovery event → set new password → signed in. ru+en i18n;
      resend cooldown; tests mirror PRIMA's.
- [ ] **CI fails on an unclassified unported non-AI route** — the freeze↔FastAPI route diff runs in
      CI; the accepted-transform allowlist (move→PATCH, `/api/status`→`/health`, push→Beat) is
      explicit; the pre/post-flip classification doc exists.
- [ ] **CI fails on OpenAPI drift** — a model/schema change that isn't reflected in the committed
      `openapi.d.ts` breaks the build.
- [ ] **A thin focal Playwright smoke runs green in CI** — login → dashboard loads → one core CRUD
      round-trip (e.g. create+delete a task).

## Build approach (slices)

| # | slice | files | main failure mode | what its test proves |
|---|-------|-------|-------------------|----------------------|
| 1 | **`/me`→`/api/me` path fix** | `server/app/api/me.py` (+/or `main.py` include), `client/src/api/me.ts`, `client/src/api/openapi.d.ts`, `client/src/api/me.test.ts` | a second non-`/api` browser path lurks; `/health` accidentally moved under `/api` and breaks orchestration | `/api/me` returns `MeResponse`; `/health` still bare; a guard test asserts every client `apiFetch` path starts `/api/` |
| 2 | **Prod topology + codified same-origin edge proxy** | NEW `client/functions/api/[[path]].ts` (+ `functions/api/ai-agent/[[path]].ts`) or committed Worker, `client/public/_routes.json`, a `docs/` proxy/smoke note; reconcile `server/app/main.py` CORS comment | SPA/static fallback swallows `/api/*`; ai-agent path mis-proxied; external-origin rewrite silently 404s | a Function unit test (mocked `fetch`) routes `/api/x`→Railway origin & `/api/ai-agent/x`→parked-Express; documented curl matrix green on dev |
| 3 | **Auth recovery: forgot + reset password** (focal-local port) | NEW `client/src/features/auth/{ForgotPasswordScreen,ResetPasswordScreen,recovery,useRecoveryMode,useResendCooldown,passwordPolicy,authErrors}.tsx/ts` (+ tests), `client/src/App.tsx` route `/reset-password`, `AuthProvider.tsx` (PASSWORD_RECOVERY event), `LoginScreen.tsx` (forgot link), `i18n/{ru,en}.json` | recovery event not detected → user stranded; redirect URL not allow-listed → dead link; reset form shown to a normal signed-in user | forgot calls `resetPasswordForEmail`; recovery event flips to the reset screen (TTL-guarded across reload); reset calls `updateUser`; cooldown enforced; ru+en keys present |
| 4 | **Route-parity reconciliation + route-diff CI gate** | NEW `apps/focal/docs/contract-freeze/PARITY.md` (classification), extend `contract-freeze/_check_routes.py` (or NEW `check_parity.py`) for freeze↔`/openapi.json` diff + transform allowlist, `.github/workflows/ci.yml`; port `shared-calendars/:id/sync-settings` **iff** UI-exposed | the diff false-positives on accepted path transforms; a genuine flip-blocker mis-classified as post-flip | CI fails on a synthetic unported non-AI route; passes on the classified set; the allowlist is explicit |
| 5 | **OpenAPI drift CI gate** | NEW small script to dump `app.openapi()`→`openapi.json`, `.github/workflows/ci.yml` (backend emits the spec as an artifact; a check runs `openapi-typescript` + `git diff --exit-code`) | the frontend job can't import the server → use a cross-job artifact, not a live server | a server schema change without a regenerated committed `openapi.d.ts` fails CI |
| 6 | **Focal E2E smoke (Playwright)** | NEW `client/playwright.config.ts`, `client/e2e/{auth.setup,tests/smoke.spec}.ts`, `client/package.json` (`test:e2e`, `@playwright/test`), `.github/workflows/ci.yml` E2E job | flaky/slow E2E becomes ignored | login→dashboard→one task create+delete round-trip passes headless in CI |

Each slice leaves the tree green and is independently revertable. Impact ranking (for sequencing
flexibility): **slice 3 (auth recovery) is highest user-impact**; slices 1–2 are the
guaranteed-prod-break fixes; 4–6 are regression-prevention.

## Architecture & contracts

No focal DB schema changes — auth recovery is entirely Supabase `auth.*` (Supabase-owned) + client;
the rest is client/CI/edge config. `sync-settings` (slice 4) reuses existing
`shared_calendar`/`integration` models if ported — **no new table**; if it needs persistence beyond
what exists, that's a flagged migration handoff (developer-owned per `apps/focal/CLAUDE.md`), not
autogenerated.

| entity / interface | change | notes |
|--------------------|--------|-------|
| `GET /me` → `GET /api/me` | move router under `/api` | every other domain router is `/api/*`; `/health` stays bare (Railway/orchestration hits it directly, not the browser) |
| Cloudflare Pages Function `/api/[[path]]` | **new** edge proxy | `fetch`-forwards to the Railway origin (env `API_ORIGIN`); preserves method/headers/body + bearer; `/api/ai-agent/*` → parked-Express origin |
| `_routes.json` | **new** | include `/api/*` for Functions, exclude static assets, keep SPA fallback off `/api/*` |
| `client` auth routes | **new** `/reset-password`; forgot entry from login | recovery detected by the SDK `PASSWORD_RECOVERY` event (PKCE `?code=`), not by path — port PRIMA's `recovery.ts` contract verbatim |
| Supabase Auth (prod) | redirect-URL allowlist + reset email template | ops config; `reset` link → `https://focal.allosta.com/reset-password` |
| `contract-freeze` checker | extend: freeze ↔ live `/openapi.json` diff + transform allowlist | currently validates legacy Express source only; CI-wire it |
| CI `ci.yml` | +3 gates: route-diff, openapi-drift, focal-E2E | additive jobs/steps; backend emits `openapi.json` artifact for the drift check |
| `main.py` CORS | keep, document scope | needed for dev + the cross-app prima-contacts caller; **not** the focal-API path (same-origin) — comment to say so |

## Flow (happy + unhappy)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| happy | user calls `/api/me` | Pages Function → Railway → `me` router | `MeResponse`; sidebar/dashboard gate resolves |
| happy | forgot password | `ForgotPasswordScreen` → `resetPasswordForEmail` | email sent; cooldown starts; neutral "if an account exists…" copy |
| happy | reset link clicked | SDK exchanges `?code=`, `PASSWORD_RECOVERY` fires → `/reset-password` | new password set via `updateUser`; signed in |
| unhappy | a non-`/api` browser path | slice-1 guard test (build-time) | regression blocked in CI before it ships |
| unhappy | reset email redirect not allow-listed | Supabase rejects redirect | dead link — **caught pre-flip** by the runbook send-test (`CUTOVER_RUNBOOK.md:91`); slice-3 acceptance requires it green |
| unhappy | recovery event missed on reload | `useRecoveryMode` TTL flag (ported) | reset screen persists across one reload, self-heals after 15 min |
| unhappy | unclassified unported route added | route-diff CI gate | PR fails until classified (flip-blocker/post-flip/dropped) |
| unhappy | server schema changed, types not regen'd | openapi-drift CI gate | PR fails until `pnpm gen:api` committed |
| unhappy | SPA fallback shadows `/api/*` | `_routes.json` + Function unit test | proxy precedence asserted; `/api/*` never returns `index.html` |

## Test strategy, security & rollback

- **Test strategy:**
  - *Unit (Vitest)* — recovery state machine, cooldown, password policy (port PRIMA's tests); the
    slice-1 "all client paths are `/api/*`" guard; the Pages Function routing (mocked `fetch`).
  - *Integration (pytest)* — `/api/me` 200 + auth; `sync-settings` router if ported.
  - *Contract (CI)* — freeze↔`/openapi.json` route diff; `openapi.d.ts` drift diff.
  - *E2E (Playwright)* — the login→dashboard→task-CRUD smoke.
  - "Verified" = all six success criteria green in CI + the documented dev curl/reset-email smoke
    matrix passing on `focal-dev.allosta.com`.
- **Security:**
  - Recovery copy is **enumeration-neutral** ("if an account exists, we sent a link"); reset only via
    a valid PKCE recovery exchange; the reset form never renders for an ordinary signed-in session
    (recovery-event-gated, per PRIMA's contract).
  - The Pages Function must **not** weaken auth: forward the `Authorization` bearer unchanged, set no
    permissive CORS of its own (same-origin needs none), and never log tokens.
  - Reset redirect URL strictly allow-listed in Supabase (open-redirect guard).
  - The route-diff gate is a defense-in-depth boundary check, not a security control; the real tenancy
    boundary (data_scope/RLS) is explicitly out of scope here and owned by the parallel audit.
- **Rollback:** every slice is its own PR, independently revertable, no DB migration (so no
  down-migration risk). Slice 2 (proxy) is the only infra-coupled one: rollback = re-point the
  Cloudflare route to the previous target + redeploy Pages; the Function is inert until the route is
  attached. No data is mutated by any slice.

# Findings: migration (the seams)

> Output of the **explore gate** (`/gate-explore migration`). Two independent takes — Opus (repo +
> live verification) and GPT Codex (offline, repo-only) — synthesized. Small and findings-first; raw
> per-model answers in `.ai/scratch/migration-{opus,gpt}.md` (gitignored). Not scored. Date: 2026-06-28.
>
> **Seam lens.** Sibling to `focal-migration-assessment.md` (qualitative verdict) and
> `focal-migration-progress.md` (% done), both 2026-06-27. This note pressure-tests the user's seed:
> *"architecture is right; the real risk is the joints — API contract parity, auth recovery, /api path
> consistency, CI/E2E."* Both models were asked to challenge that framing, not just confirm it.

## Questions
1. Is the framing right — architecture sound, real remaining risk in the integration seams?
2. API contract parity: (a) all legacy routes ported? (b) is the client↔server type contract drift-proof?
3. Auth recovery: is the recovery surface complete/robust enough to flip ~163 existing users?
4. /api path consistency: consistent client→proxy→server across dev+prod, and is the prod proxy codified?
5. CI/E2E: which gates exist vs. missing for a safe cutover?
6. Ranked: top concrete seam risks to close before flip.

## Consensus

> Both models reached these independently. High confidence unless noted.

- **The framing is right — and both models pushed back the same way to sharpen it.** The server
  architecture is sound: explicit router→service layering, JWT-derived identity, fail-closed RLS as a
  real second line (`app/rls.py`, bound per-txn at `app/db.py:66`). **But** two of the named "seams"
  are *not* small polish: `/api` consistency and **auth recovery can block cutover**, and the "typed
  API contract" is not yet a *reliable* seam because its generation isn't CI-enforced (below).
  Caveat carried from `focal-migration-assessment.md`: the single highest non-seam risk is the
  app-layer **data-scope** authz boundary + **RLS-not-applied-on-prod** — that's the security core,
  and it outranks every seam here. Confidence: High.

- **API route parity has a real gap: ~20 legacy routes are not served at the same path** (Opus
  counted 19, GPT 21 — same set, different tie-breaks). Verified against the frozen contract
  `apps/focal/docs/contract-freeze/routes.json` vs the router list in `main.py:90-121`. Families:
  - **CRM / contacts / interactions** — frozen (`routes.json:1441,1515`), **no router** in the new
    app; old-focal had it for real (`apps/old-focal/client/src/components/CrmInteractions.tsx`,
    `ContactPicker.tsx`). *Deferred by decision* (`MIGRATION_PLAN.md` D4 / crm-boundary ADR). The
    client currently reaches into **PRIMA's `GET /contacts` directly** as an interim stopgap
    (`apps/focal/client/src/features/calendar/primaContacts.ts:5-25`).
  - **`/api/admin/fix-event-times*`** (`routes.json:3126`) — not mounted, unclassified.
  - **`/api/status` (+ `/api/dev/status`)** (`routes.json:1549,909`) — not mounted; `/health`
    supersedes it but the swap isn't ticked off.
  - **`/api/shared-calendars/:id/sync-settings`** (`routes.json:1912`) — GPT's catch; frozen, absent
    from the shared-calendars router. Verify.
  - **Project move / move-preview** — *reshaped, not 1:1*: folded into `PATCH /api/projects/{id}` +
    client-side preview (`schemas/projects.py:36-39`, `features/goals/graph.ts:404-407`).
  - **`POST /api/push/check-reminders`** — unported **by design** (Celery Beat owns the sweep —
    `push.py:18-19`, `apps/focal/CLAUDE.md`). Clean.
  Confidence: High on the inventory; the open part is which are flip-blockers (see Open).

- **The typed client↔server contract is good by design but NOT drift-protected.** The client sources
  types from the generated schema (`client.ts:1-12` → `Schemas['EnrichedTaskRead']` etc.), so a
  renamed/removed route fails `tsc`. But `openapi.d.ts` is regenerated **manually** (`gen:api`,
  `package.json:17`) and committed; **no CI step regenerates + diffs it** (`ci.yml:227-242` runs only
  biome/i18n/tsc/vitest), so a backend schema change can land while committed client types silently
  lag. Confidence: High.

- **Auth recovery is the biggest user-facing seam gap.** Foundation is production-grade: login,
  Google OAuth PKCE, session auto-refresh + skew/timeout (`AuthProvider.tsx:117-141`,
  `supabase.ts:32-45`), 401→signOut (`client.ts`), fail-closed ES256 verify (`app/auth.py` — pins
  ES256, checks aud/iss/exp/sub). **But the focal auth dir is 5 files** (`AuthGate`, `AuthProvider`,
  `LoginScreen`, `supabase`, `index`) — **no signup, no forgot-password, no reset-password, no
  email-verify, no magic-link SSO consume UI.** PRIMA's auth dir is **44 files** with all of these
  built+tested (`ForgotPasswordScreen`, `ResetPasswordScreen`, `SignupScreen`, `authActions.ts:37,72,118`,
  `recovery.ts`). Cutover signs out **all ~163 users** (`CUTOVER_RUNBOOK.md:89`); with no self-serve
  reset UI, anyone who needs a reset post-flip is stuck unless the Supabase **hosted** reset path is
  configured. Confidence: High (UI absence); Medium on the hosted-page fallback (not visible in repo).

- **/api path: clean in dev for `/api/*`, but two real prod seams + one concrete mismatch.**
  - *Confirmed mismatch:* the client calls **`/me`** (`api/me.ts:5`) and the server serves `/me`
    **outside** `/api` (`main.py:91`, bare `me.router`), while the Vite proxy forwards **only** `/api`
    + `/prima-api` (`vite.config.ts:27-34`) — whose own comment claims *"the browser only ever calls
    same-origin /api/*"*, which `/me` violates. `/me` is the **only** non-`/api` client path, and it
    feeds the always-rendered sidebar + dashboard gate (`AppSidebar.tsx:133`, `DashboardPage.tsx:57`).
    It will not traverse the documented prod `/api/* → Railway` Cloudflare proxy either → breaks in
    prod unless an explicit rule is added. Cheapest fix: move `/me` under `/api` (client+server);
    leave `/health` bare (orchestration hits it, not the browser).
  - *Prod proxy not codified:* no `_redirects` / `_routes.json` / `wrangler.toml` anywhere under
    `apps/focal/client` (verified). The `/api/* → Railway` and `/api/ai-agent/* → parked-Express`
    rules live only as runbook prose (`CUTOVER_RUNBOOK.md:82-83,147-150`) — un-reviewed dashboard config.
  - *Same-origin vs cross-origin is a mixed message:* docs say same-origin / "no CORS exposure"
    (`MIGRATION_PLAN.md:36-39`), but the code ships CORS middleware for cross-origin bearer calls
    (`main.py:77-84`, `config.py` origins incl. `focal.allosta.com`). The prima-contacts stopgap also
    *needs* cross-origin in prod (`VITE_PRIMA_API_URL` + PRIMA CORS). Pick one contract and codify it.
  Confidence: High on the three findings; Medium on which prod topology is canonical (user decision).

- **CI/E2E: unit gates are strong; the cutover-relevant integration gates are absent.** Present:
  `backend-focal` (ruff, format, mypy, **alembic upgrade+check** drift, pytest — ~84 test files,
  `ci.yml:124-201`) and `frontend` matrix incl. `focal-client` (biome, lint:i18n, check:i18n, tsc,
  vitest — ~98 test files, `ci.yml:203-242`). **Missing:** (1) **no Playwright/E2E for focal at all**
  — no config, no `e2e/`, no `@playwright/test`, zero specs (PRIMA has a full suite); (2) the
  **contract-freeze route checker is not wired into CI** (`_check_routes.py` exists but validates the
  *legacy Express* inventory, not new-FastAPI parity); (3) **no OpenAPI regen-diff gate**. Confidence: High.

## Divergence

> Little genuine disagreement — both takes strongly aligned. The differences are ranking/emphasis,
> which still need a user call.

- **What's the #1 pre-flip seam — auth recovery or the `/me` proxy mismatch?**
  - **Opus:** auth recovery — biggest *blast radius* (every migrated user, password-reset table-stakes).
  - **GPT:** the `/me` outside-`/api` mismatch — most *concrete and certain* break, cheapest fix.
  - **Reconciled:** not a real conflict — different axes (impact vs certainty). Both are pre-flip. Suggested
    order: fix `/me` first (one-line-ish, removes a guaranteed prod break), then build the recovery UI
    (larger, higher impact). **Decision for the user:** confirm both are flip-blockers and sequence them.

- **How load-bearing is RLS as the tenant boundary?**
  - **Opus (+ `focal-migration-assessment.md`):** RLS is a *dormant backstop* on the hot path — the
    live boundary is the app-layer `data_scope`/`resolve_data_owner`, which deserves an independent audit.
  - **GPT:** credited RLS as a solid fail-closed second line, without the dormant-on-hot-path caveat.
  - **Decision for the user:** none new — the prior note already settled this at High confidence with
    code evidence; flagged so the synthesis doesn't read as "RLS fully covers tenancy."

## Open

> Neither model could close these from the repo alone.

- **Flip-blocking vs post-flip mapping (ALL-204).** Which unported/parity items (CRM, admin, status,
  sync-settings) and which missing auth screens actually gate the flip. *Still open from both prior
  notes.* To close: the user's / Linear's "done" definition.
- **Canonical prod API topology.** Same-origin `/api/*` proxy (docs' stated decision) vs cross-origin
  `VITE_API_URL` (what CORS + the prima-contacts path imply). They contradict. To close: the user
  picks one and it gets codified as a committed `_redirects`/`_routes.json` + env, then smoke-tested.
- **Prod password-reset fallback.** The runbook itself says *"verify a password-reset email actually
  sends from superapp-prod before the flip"* (`CUTOVER_RUNBOOK.md:91`) — is the Supabase **hosted**
  reset configured + redirect-allowlisted for `focal.allosta.com`? If yes, the missing reset UI is a
  smaller (UX) gap, not a lockout. To close: check the Supabase dashboard + send one test email.
- **prima-contacts prod wiring.** Is `VITE_PRIMA_API_URL` set and does PRIMA's CORS allow focal's
  origin in prod, or does CRM contact-linking silently 404 post-flip? To close: confirm the prod env +
  PRIMA CORS list (there's no `/prima-api` Cloudflare rule in the runbook).

## Next

- These six seam risks are a finite, listed punch-list — good seed for a **`/gate1-think`
  cutover-readiness burndown** (turn each into an explicit go/no-go), or direct slice work. Suggested
  pre-flip order: (1) `/me`→`/api` fix, (2) auth-recovery UI (or confirm hosted-reset fallback),
  (3) decide+codify the prod `/api` proxy & topology, (4) reconcile route parity into a pre/post list
  + wire `check_routes.sh`/route-diff into CI, (5) a thin focal E2E smoke (auth + core CRUD), (6)
  OpenAPI regen-diff CI gate.
- **Outranking all seams** (carried, not re-litigated here): the prod **RLS bootstrap** is still
  unapplied and the **data-scope authz audit** is the highest-value single review before flip — see
  `focal-migration-assessment.md` "Round 2 refresh".
- Most seams are *anticipated* by the runbook (proxy rules, password-reset check, env carry-over) —
  the gap is they're **prose, not codified/tested artifacts**, and the auth-recovery UI + `/me`
  mismatch are **not** covered by the runbook at all.

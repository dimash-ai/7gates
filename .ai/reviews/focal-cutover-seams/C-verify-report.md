# Verification Report — focal-cutover-seams (gate C)

Doer: GPT Codex (workspace-write), base branch `feature/focal-migration`. Raw transcript:
`.ai/runs/focal-cutover-seams-verify.txt`.

## Scrutiny (whole change, 6 seams) — no production-code defect found

GPT scrutinized the cumulative diff against the design and found **no gate-B-stopping production
defect**. Security / cross-cutting pass:
- `/me` → `/api/me`: guard + unit + backend (`test_me.py`) coverage present.
- Edge proxy preserves bearer/method/body/query, adds no CORS, leaks no token
  (`functions/api/_proxy.ts`); `_routes.json` scopes Functions to `/api/*`. Confirmed against
  Cloudflare Pages routing docs.
- Reset form gated on the recovery flag **and** a session (`ResetPasswordScreen.tsx`); a
  stale/non-recovery visit to `/reset-password` gets the expired state, not the form.
- Forgot/reset actions log no raw error/token; forgot copy is enumeration-neutral (`authActions.ts`).
- Parity allowlist inspected: `193/193` kept routes accounted for, `19` documented divergences.
- **No committed secrets** in `parity_allowlist.json`, `EDGE_PROXY.md`, the Playwright config, CI,
  or the proxy files.

## Verification results (GPT, with local equivalents where its sandbox blocked the pnpm/network path)

- `vitest run` (focal-client): **pass — 109 files, 1256 tests**.
- `tsc -b`: pass. `biome check .`: pass (334 files).
- `pytest tests/test_me.py`: pass (3 tests). *(The full backend DB suite is unaffected by this change —
  only `me.py`'s router prefix changed — and needs Postgres; not a regression.)*
- Route-parity `check_parity.py --selftest`: pass. Full parity check: pass (193/193).
- OpenAPI-drift equivalent: regenerated, `diff` clean.

## Pre-existing failures — PROVEN on base (GPT ran the CLI against an archived `feature/focal-migration`)

- `check:i18n`: fails on `focal.tasks.countActive` plural keys — **also fails on the base branch**.
- `lint:i18n`: fails on hardcoded `%` in dashboard/analytics — **also fails on the base branch**.
- Neither is touched or worsened by this change. (Recommend a separate cleanup PR.)

## E2E — the one verifier gap, resolved honestly

GPT could **not run Playwright** in its sandbox (`listen EPERM` on :5173 + the browser install was
blocked), so it added an `authenticated-crud.spec.ts` (a fully-mocked Supabase-auth + `/api/*`
login→create→delete flow) it **could not execute**. Opus (orchestrator) **ran the e2e suite on a
real machine**: the committed **smoke passes**; GPT's `authenticated-crud.spec.ts` **failed** (its
Supabase-auth mock breaks the initial login render → timeout on the email field). The authed-CRUD
E2E was *deliberately deferred* in slice 6 (approved 9.2) because it needs a live backend + Supabase
(or fragile full mocking) that CI lacks; a red, un-runnable, heavily-mocked test must not ship, so
the spec was **removed**. The signed-out boot smoke stands; authed-CRUD remains the documented
secrets-gated follow-up.

Final tree: clean; e2e suite green (1 passed).

---

## Rebase resolution (after the BLOCK on stale base) — re-verified

The gate-C Opus review BLOCKED (6.5): the change had been verified against the stale merge-base
`6f6659a`; PR #113 ("login with sign-up + forgot-password + PKCE reset") had since landed on
`feature/focal-migration`, making slice 3 (auth recovery) redundant + conflicting. Per the user's
decision (drop slice 3, ship the 5):

- Backed up the 6-slice branch (`backup/focal-cutover-seams-6slices`), reset `feat/focal-cutover-seams`
  onto current origin base (`cb5bb48`, now past #113 + #115), and cherry-picked the **5 genuinely-new
  slices** (1,2,4,5,6) — **dropped slice 3**. Cherry-pick was CONFLICT-FREE (origin's 16 commits touch
  neither the server nor any of the 5 slices' files).
- One required fix: the slice-6 e2e smoke was written for the pre-#113 login screen; #113 moved the
  login to `/login` (`/` is now a marketing landing) and reshaped the auth UI. Updated `smoke.spec.ts`
  to `/login` + #113's "FoCal" heading + `forgotPassword.{link,submit,back}` keys.

Re-verification on the rebased tree (current base):
- vitest run (FULL): 112 files, **1341 passed** (my 5 slices + #113 + #115 together).
- tsc -b clean; biome check . clean (339 files); apiPaths guard 27 passed (the new #113/#115 client
  code respects `/api`).
- pytest tests/test_me.py: 3 passed.
- parity --selftest + full check: PASS (193/193).
- openapi.d.ts vs live schema: NO DRIFT (origin did not change the server).
- e2e smoke: 1 passed against #113's UI.
- Branch is a clean fast-forward over the base — `git merge --no-conflicts`; HEAD ahead of base.

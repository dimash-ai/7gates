# Stage
Gate C (verify) — shipped. 3-gate flow: design (A, GPT 9.2) → build (B, 5 slices each GPT ≥9.0) →
verify (C, Opus release gate 9.3).

# What changed
Closed five Focal-migration integration "seams" found by `/gate-explore migration`. (A sixth seam —
self-serve password reset — was dropped before merge: PR #113 shipped focal's own auth recovery
concurrently, so that slice became redundant.)

- **`/me` → `/api/me`** so the same-origin proxy actually reaches it (the client called a bare `/me`
  the dev/prod `/api/*` proxies don't forward).
- **A committed Cloudflare Pages edge proxy** for the same-origin API: a Pages Function forwards
  `/api/*` to the Railway backend and `/api/ai-agent/*` to the parked Express, with `_routes.json`
  scoping Functions to `/api/*`.
- **A route-parity CI gate**: every "kept" legacy route (193) must be served by the new FastAPI app
  or be a documented divergence (19, classified in `PARITY.md`) — a newly-unported route now fails CI.
- **An OpenAPI-drift CI gate**: the committed client API types must match the server schema, or CI fails.
- **A Playwright E2E boot smoke + harness** (focal had none): builds + boots the app and checks the
  sign-in shell + password-reset navigation render.

# Files touched
- `apps/focal/server/app/api/me.py`, `apps/focal/server/tests/test_me.py`
- `apps/focal/client/src/api/me.ts`, `openapi.d.ts`, `apiPaths.guard.test.ts`
- `apps/focal/client/functions/api/{[[path]].ts,_proxy.ts,_proxy.test.ts}`, `public/_routes.json`,
  `tsconfig.json`, `apps/focal/server/app/main.py` (CORS comment), `apps/focal/docs/EDGE_PROXY.md`
- `apps/focal/docs/contract-freeze/{check_parity.py,parity_allowlist.json,PARITY.md,check_parity.sh,README.md}`
- `apps/focal/client/{playwright.config.ts,e2e/smoke.spec.ts,vite.config.ts,biome.json,.gitignore,package.json}`,
  `pnpm-lock.yaml`
- `.github/workflows/ci.yml` (route-parity gate, openapi-drift job, e2e job)

# Tests run
```sh
pnpm --filter focal-client run test:run     # 112 files, 1341 passed
pnpm --filter focal-client exec tsc -b       # clean
pnpm --filter focal-client exec biome check .# clean (339 files)
uv run pytest tests/test_me.py -q            # 3 passed
python3 check_parity.py --selftest && check_parity.py <live-openapi>   # selftest OK; PARITY OK 193/193
openapi-typescript <live-schema> -o openapi.d.ts && git diff --exit-code  # no drift
pnpm --filter focal-client run test:e2e      # 1 passed (boot smoke)
```

# Verification output
```sh
PARITY OK — all 193 kept legacy routes are served by the new app or are among the 19 documented divergences.
e2e: ✓ boots to sign-in and navigates the password-reset flow
git merge-base --is-ancestor origin/feature/focal-migration HEAD → fast-forward, 0 conflicts
```

# Still needs review
- **Pre-existing CI red (NOT from this change, proven on base):** `check:i18n` fails on
  `focal.tasks.countActive` plural keys; `lint:i18n` on hardcoded `%` in dashboard/analytics. Worth a
  separate cleanup PR.
- **Two decisions for product/ops sign-off** (documented, not blocking the seams): the parity allowlist
  marks `admin/fix-event-times` + `push/check-reminders` as *dropped* (ack the drop or port them); and
  the authenticated login→CRUD E2E is deferred (the boot smoke + harness ship; the authed flow needs
  Supabase/backend secrets CI lacks).
- **Edge-proxy ops:** set the Pages `API_ORIGIN`/`AGENT_API_ORIGIN` env + the SPA `not_found_handling`
  per `EDGE_PROXY.md`; run the curl smoke matrix on `focal-dev` before flip.

# PR / release notes (for users)
Hardens the Focal migration's integration seams ahead of cutover:

- The Focal web app now reliably reaches its API on its own domain — the `/me` call and the committed
  Cloudflare same-origin `/api/*` proxy fix a path that worked in dev but would have 404'd in production.
- Three new CI guards keep the migration honest going forward: a legacy route can't silently disappear
  from the new API, the frontend's API types can't drift out of sync with the backend, and a real
  browser confirms the app builds and the sign-in screen loads on every change.

No user-data, schema, or auth-behavior changes; no secrets in the diff.

# Status
OPUS APPROVED (9.3) — release gate cleared. PR opened:
https://github.com/Allosta-Group/superapp/pull/118 (base `feature/focal-migration`).

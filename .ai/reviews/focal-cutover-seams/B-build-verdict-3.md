# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 7.2 / 10
Status: BLOCKED

## Reason
The proxy routing logic is small and mostly matches the design: `/api/*` and `/api/ai-agent/*` split correctly, the bearer header is preserved, and no CORS is added. However the committed SPA catch-all can shadow static assets on Cloudflare Pages, and the smoke matrix includes an endpoint that contradicts the committed bare `/health` route.

## Must Fix
- `apps/focal/client/public/_redirects:4` rewrites `/*` to `/index.html`; with `_routes.json:3` invoking Functions only for `/api/*`, this also matches non-Function static paths such as the assets referenced by `apps/focal/client/index.html:8-14` (`/fonts/*`, `/manifest.webmanifest`, icons, and built `/assets/*.js`). That can make the deployed app serve `index.html` instead of required CSS/JS/PWA assets.
- `apps/focal/docs/EDGE_PROXY.md:37-39` documents `curl https://focal-dev.allosta.com/api/health` as a 200 backend-health smoke, but the server exposes health only at `apps/focal/server/app/api/health.py:72` (`/health`) and the slice/design intentionally kept health bare. Through this proxy, `/api/health` will hit Railway as `/api/health` and fail the documented smoke matrix.

## Should Consider
- Add a body-forwarding assertion to `apps/focal/client/functions/api/_proxy.test.ts`; the current tests cover URL/query, method, bearer header, and fetch target, but not POST/PATCH body preservation.

## Tests Reviewed
`git -C superapp --no-pager diff`; `git -C superapp status`; inspected `.ai/runs/focal-cutover-seams-build.txt` reporting green `vitest functions/api/_proxy.test.ts`, `tsc -b`, and `biome check functions/ public/_routes.json`; reviewed `functions/api/_proxy.test.ts`.

## Release Risk
High

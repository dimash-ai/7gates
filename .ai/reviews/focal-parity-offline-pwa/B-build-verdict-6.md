# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.4 / 10
Status: BLOCKED

_Slice B4 (PWA install + update prompts + app-shell service worker), round 1._

## Reason
B4 covers the install prompt, i18n, push preservation, `/api` bypass, and app-shell fetch boundaries with focused tests. The blocker is that the update-prompt path is not tied to ordinary app deploys, so polling can succeed while never producing a waiting worker for changed JS/CSS/index assets.

## Must Fix
- `src/lib/pwa.ts` polls `registration.update()`, but `public/sw.js` has only a static cache/version and `vite.config.ts` has no PWA/precache/build-stamp transform. A normal Vite deploy that changes app bundles but leaves `/sw.js` byte-identical will not fire `updatefound`, so `UpdatePrompt` will not appear for the normal app-update case.

## Should Consider
- `public/sw.js` caches navigation responses without checking `response.ok`, so a transient 500/maintenance HTML response can overwrite the offline shell.
- `public/sw.js` `clients.claim()` + the `pwa.ts` controllerchange reload can reload on first service-worker claim, not only after the user clicks the update prompt.

## Tests Reviewed
Inspected B4 build log (typecheck/lint/build green, test:run 1224); reviewed `InstallPrompt.test.tsx`, `UpdatePrompt.test.tsx`, `pwa.test.ts`, `sw.test.ts`.

## Release Risk
Medium

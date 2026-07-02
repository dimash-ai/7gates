# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.4 / 10
Status: BLOCKED

## Reason
The implementation is scoped correctly and typechecks, but it drops required old-focal loading/error behavior for several always-on dashboard cards and misses required cohort label localization. These are concrete parity and upstream-error handling regressions against the design/plan.

## Must Fix
- `apps/focal/client/src/features/dashboard/DashboardPage.tsx:286` through `:290`: retention curve, screen distribution, and devices cards render only when `.data` exists, so loading and rejected query states silently remove the card instead of showing old-focal card-level spinner/error states required by the design error map.
- `apps/focal/client/src/features/dashboard/sections.tsx:724`: cohort rows render raw API labels like `Week of 2026-05-01`; old-focal localized weekly labels, so RU users get English API text and the i18n parity requirement is not met.

## Should Consider
- Add coverage for PDF export generation and the curve/screens/devices loading/error branches after fixing the missing states.

## Tests Reviewed
`git diff`; `git status`; inspected `DashboardPage.test.tsx` and `dashboard.test.ts`; `tsc --noEmit` passed; focused `biome check` passed. `pnpm test:run`/`vitest run` were blocked by read-only sandbox EPERM writes to temp/Vite cache paths.

## Release Risk
Medium

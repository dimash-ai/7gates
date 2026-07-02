# Stage

Analytics epic — built, integrated, green, consolidated-review APPROVED (9.4). Worktree
`.worktrees/focal-redesign-analytics`, branch `feat/focal-redesign-analytics` (off shell `afaaeba`),
two commits: `6742301` (scaffold + Spheres) + `2df5594` (5 sections + integration + review fixes).
**Built via parallel subagents** (user-chosen pacing): one scaffold/Spheres build, then 5 sections
fanned out concurrently, then a serial integration, then a consolidated adversarial review.

# What changed

Replaced the single 219-line spheres-bars `AnalyticsPage` with old-focal's full **6-section** analytics
page, frontend-only over the existing APIs:
- **Shared scaffold:** `analyticsPeriods.ts` (month/quarter/year range math), `PeriodSelector.tsx`,
  `useSpheresAnalyticsData.ts` (period events + year events for trends + projects + spheres), recharts
  themed to the foundation tokens, and a `<XSection>` composition in `AnalyticsPage.tsx`.
- **Sections** (old-focal order): **Spheres** (radar log-scale + 12-mo trend + sortable table),
  **Mission** vs Provision (100% stacked bar + mission-% trend), **Projects** productivity (stacked
  bar + line + table), **Products** (stacked bar + line + table + parent filter), **Energy** balance
  (giving/taking stacked bar + trend + top-3), **Deep work** (metrics + recommendations).
- Each section ports old-focal's exact client-side computation: duration (null-`endTime` = 1h),
  plan = all events / fact = completed only; **budgets — Spheres `annual×days/365`, the other four
  `annual÷divisor` (year1/quarter4/month12)**, matching old-focal's deliberate inconsistency;
  `/api/analytics/spheres` is bypassed (its plan/fact semantics differ).
- i18next ru+en for every string (sourced from old-focal locales); strict TS, no `any`; light + dark.

# Files touched

`apps/focal/client/src/features/analytics/`: `AnalyticsPage.tsx`, `PeriodSelector.tsx`,
`analyticsPeriods.ts`, `useSpheresAnalyticsData.ts`, `spheresAnalytics.ts`, `{deepWork,products,
projects,mission,energy}Analytics.ts`, `sections/{Spheres,Mission,Projects,Products,Energy,DeepWork}
Section.tsx`, the matching `*.test.ts`, and `i18n/locales/{en,ru}.json`. (No server/API change.)

# Tests run

```sh
cd .worktrees/focal-redesign-analytics/apps/focal/client
pnpm lint        # biome: 238 files, 0 errors
pnpm typecheck   # tsc -b: 0 errors
pnpm test:run    # 55 files, 486 tests passed (~95 new analytics unit tests)
pnpm build       # ok
pnpm check:i18n  # en/ru parity, no drift
```

# Still needs review

- **Manual light/dark visual QA** vs old-focal — radar/stacked-bar/area/table across all 6 sections,
  the period selector, and a real authed dataset (the one thing unit tests can't assert).
- Consolidated review caught + fixed 2 real bugs (energy taking-delta suppression; showMore plural
  i18n). One non-blocking Should-Consider remains (products tooltip caps at top-5).
- **PDF export** is the one deferred old-focal feature (its own later sub-slice).
- Not pushed / no PR yet.

# Status

CODEX APPROVED (9.4, consolidated) — cleared pending visual QA + PR.

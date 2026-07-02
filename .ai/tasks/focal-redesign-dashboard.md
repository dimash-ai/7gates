# Goal

Re-skin the new Focal **admin product-dashboard** (`apps/focal/client/src/features/dashboard/`) to
**exact visual parity with old-focal's `/dashboard`** (`apps/old-focal/client/src/pages/Dashboard.tsx`
+ `components/dashboard/*`), composing the slice-0 shell tokens, over the **existing** dashboard APIs
+ backend. This is the **dashboard slice of the `focal-redesign-pages` epic** (traces to
`.ai/think/focal-redesign-pages.md`) — frontend-only, re-skin not rebuild, admin-gated.

> **Binding visual contract** = old-focal `pages/Dashboard.tsx` + the `components/dashboard/*` set
> (`DashboardControls`, `KpiRow`/`KpiCard`, `InsightsRow`/`InsightCard`, `RetentionCurveChart`,
> `ScreenDistributionCard`, `DevicesCard`, `UserEngagementSection`, `RetentionChurnSection`,
> `CohortAnalysisSection`, `FeatureOperationsSection`, `UsersTable`, `UserDetailsModal`, `UserAvatar`,
> `ExpandableSection`). **Behavioral/data base** = the new app's already-functional
> `features/dashboard/` (`DashboardPage.tsx`, `overview.tsx`, `sections.tsx`, `api/dashboard.ts`) on
> the ported backend (`server/app/services/dashboard.py`). Workspace = the worktree
> `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-dashboard` (branch
> `feat/focal-redesign-dashboard`, off slice-0 `afaaeba`).

# Scope

- **Header / controls** — title + subtitle + the shell `SidebarTrigger` (PageHeader pattern) + the
  segment / period / custom-date / CSV / PDF cluster, restyled to old-focal `DashboardControls`
  (filter options already match: segments `all/active/new/churned/retained/power`, periods
  `7d/30d/90d/6m/1y/custom`, export `csv|pdf`).
- **Overview (always-on)** — `KpiRow`/`KpiCard`, `InsightsRow`/`InsightCard`, `RetentionCurveChart`,
  `ScreenDistributionCard`, `DevicesCard` restyled to old-focal exact (card chrome, sparklines,
  Recharts styling, the cohort/heatmap colour ramps from the slice-0 tokens).
- **Collapsible sections** — users/engagement, retention-churn, cohort-analysis, feature-operations
  restyled to old-focal (the `ExpandableSection` look, table/list styling, cohort heatmap cells).
- **Parity-gap components** absent in the new app (`UserEngagementSection`, `UserDetailsModal`,
  `UserAvatar`): build to match old-focal **iff backed by an existing dashboard endpoint** (verified
  at the design gate); a genuinely backend-blocked piece (e.g. a per-user-detail fetch the new
  `api/dashboard.ts` lacks) is a **flagged handoff**, not faked.
- Light **and** dark; all user-facing strings via i18next `ru` + `en` (reuse old-focal copy);
  preserve existing behavior + the existing `dashboard.test.ts`.

# Out of scope

- Any **server / API / schema / migration** change — the dashboard service + endpoints are already
  ported; a missing endpoint a parity component needs is a separate flagged handoff.
- **New metrics / sections** not present in old-focal's dashboard.
- The admin-access model itself (`canAccessDashboard` gating stays as-is).
- Any other left-nav page.

# Acceptance criteria

- [ ] `cd /Users/allosta/Desktop/allosta/.worktrees/focal-redesign-dashboard/apps/focal/client &&
      pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` all green, with the slice's tests.
- [ ] `/dashboard` visually matches old-focal in **light and dark** — header/controls, KPI + insight
      cards, retention curve, screen-distribution, devices, and the four sections — by screenshot.
- [ ] Admin gate preserved (`canAccessDashboard`; denied + loading states render); CSV + PDF export
      still produce a file; existing dashboard behavior unchanged.
- [ ] Surgical diff confined to `features/dashboard/*` (+ i18n keys, + any new `components/ui` or
      `api/dashboard.ts` wrapper a parity component strictly needs); **no** server/API change.
- [ ] No hardcoded strings (i18next `ru` + `en`); nothing faked for a backend-blocked parity piece.

# Verification commands

```sh
cd /Users/allosta/Desktop/allosta/.worktrees/focal-redesign-dashboard/apps/focal/client
pnpm install --frozen-lockfile
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```

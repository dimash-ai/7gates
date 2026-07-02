# Stage

Stage 7: ship — the `focal-redesign-dashboard` slice of the `focal-redesign-pages` epic
(exact old-focal re-skin of the admin product-dashboard). Branch `feat/focal-redesign-dashboard`
(off slice-0 `afaaeba`), commit `88b54ec`.

# What changed

Re-skinned the new Focal admin product-dashboard (`apps/focal/client/src/features/dashboard/`) to
**exact visual parity with old-focal's `/dashboard`**, frontend-only, over the existing dashboard
APIs (no server/OpenAPI/schema change). Reproduced on the new stack (React 19 / Tailwind 4 /
shadcn) — old-focal's Tailwind-3 code was not lifted.

- **Header / controls** — old-focal layout with the shell `SidebarTrigger`, segment + period +
  custom-date filters, and a single **Export** button opening a PDF/CSV dialog (reusing the existing
  export paths). Export failure keeps the dialog open with an inline error (the app has no toast
  surface).
- **Overview** — `KpiRow`/`KpiCard` (now **clickable** → open a user-segment modal, with Info
  tooltips + arrow delta badges), `InsightsRow`, `RetentionCurveCard`, `ScreensCard`, `DevicesCard`,
  each rendering their own **loading / error / empty / collecting** states.
- **Sections** — `UserEngagementSection` (mini-KPIs + users table + section CSV), `UserDetailsModal`
  (KPI-segment list with in-memory search + truncation warning), `UserAvatar`, plus restyled
  retention-churn, cohort (localized weekly labels + heatmap ramp), and feature-operations sections.
- **Behavior preserved**: admin gating (`canAccessDashboard`), the data/query contracts, and CSV/PDF
  export. New helpers (`kpiSegmentFor`, `initialsFor`, `colorFor`, `formatDuration`,
  `cohortWeekDate`, `statusSearchTokens`, `csvSection`) are pure + unit-tested. CSV formula-injection
  guard hardened to old-focal's `= + - @ tab CR`. All copy via i18next (`ru` + `en`).

# Files touched

- `apps/focal/client/src/features/dashboard/DashboardPage.tsx` — header/controls/export dialog, KPI-modal state, card loading/error wiring (modified)
- `apps/focal/client/src/features/dashboard/overview.tsx` — KPI/insight cards + chart cards restyle + per-card states (modified)
- `apps/focal/client/src/features/dashboard/sections.tsx` — engagement/users/avatar/modal + retention-churn/cohort/features restyle (modified)
- `apps/focal/client/src/features/dashboard/dashboard.ts` — new pure helpers + hardened `csvCell` (modified)
- `apps/focal/client/src/api/dashboard.ts` — `getDashboardUsers` `sortBy`/`order` options (existing OpenAPI params; no regen) (modified)
- `apps/focal/client/src/features/dashboard/dashboard.test.ts` — helper unit tests (modified)
- `apps/focal/client/src/features/dashboard/DashboardPage.test.tsx` — component tests (added)
- `apps/focal/client/src/i18n/locales/en.json`, `ru.json` — new `focal.dashboard.*` keys (modified)

# Tests run

```sh
cd /Users/allosta/Desktop/allosta/.worktrees/focal-redesign-dashboard/apps/focal/client
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```

# Verification output

```sh
biome check . → Checked 218 files. No fixes applied.
tsc -b --pretty → 0 errors
vitest run → Test Files 50 passed (50) · Tests 391 passed (391) · 0 skipped
vite build → ✓ built (dashboard chunk code-split; only the pre-existing chunk-size warning)
i18next-cli check → ✅ No files were updated (ru/en parity intact)
```

# Still needs review

- **Visual parity QA** against old-focal `/dashboard` in **light + dark** (desktop 1440×900 + mobile
  390×844, all sections + the KPI modal opened) — not yet run by a human (the gates verified behavior
  + structure, not pixels).
- **Deferred (backend-blocked, not faked):** a true per-user detail/profile endpoint
  (`/api/dashboard/users/{id}` does not exist) — old-focal's modal is itself only a segment list,
  which is what shipped. A richer per-user view is a separate backend handoff.
- Non-blocking polish from the review gates: a couple of hardcoded a11y/tooltip labels
  (`overview.tsx` chart series name, trend aria-labels) and per-section error-branch tests.

# PR / release notes (for users)

**Focal dashboard — redesigned to match the production app.** The admin product-dashboard now looks
and behaves like the proven Focal dashboard:

- Filter by segment and time period (7d / 30d / 90d / 6m / 1y / custom), and export the current view
  to **CSV or PDF** from one Export button.
- **KPI cards are now clickable** — open any KPI to see the matching list of users, with instant
  in-memory search by name, email, or status.
- Read the **retention curve, screen distribution, device split, cohort retention matrix**, and
  **user-engagement** drill-down, each with proper loading and error states.
- Fully localized (Russian + English), light and dark themes.

The dashboard remains restricted to users with dashboard access; no data or permissions changed.
This text contains no secrets, tokens, keys, or PII.

# Status

CODEX BLOCKED (8.6) — code is APPROVED through gates 1–6 (think 9.4 · plan 9.4 · design 9.2 ·
build 9.1 · review 9.1/9.3 · test 9.5) and the final-review found the diff clean, scoped, and
secret-free. The **only** open Must Fix is the binding **visual-parity QA** (light/dark `/dashboard`
vs old-focal) — a human step. Resolve by running the local client, recording the screenshot
result, then re-running gate 7 → at ≥9.0, open the PR (`feat/focal-redesign-dashboard` →
`feature/focal-migration`) using the PR text above. Commit: `88b54ec`.

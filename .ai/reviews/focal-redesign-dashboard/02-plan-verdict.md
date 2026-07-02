# Review Verdict

Reviewer: Opus
Step: plan
Score: 9.4 / 10
Status: APPROVED

## Reason
The plan is a minimum-viable, surgically-scoped re-skin that correctly distinguishes backed parity work from unbacked (deferred) work. Its single load-bearing technical claim — that `sortBy`/`order` are already valid `/api/dashboard/users` query params needing no backend/OpenAPI change — is verified true at `openapi.d.ts:9043-9044`. Failure modes are enumerated per-query with where-caught/what-the-user-sees, each listed test states what it proves, and scope stays inside `features/dashboard/*` + i18n + one wrapper. Nothing is faked.

## Must Fix
None.

## Should Consider
- **Field-naming transcription hazard (camelCase vs snake_case).** old-focal's `UsersTable.tsx`/`UserEngagementSection.tsx`/`UserDetailsModal.tsx` read snake_case fields (`u.actions_24h`, `u.last_active_at`, `summary.avg_session_duration_sec`, `sort_by`/`page_size`), but the new app's generated OpenAPI is camelCase (`actions24h`, `lastActiveAt`, `avgSessionDurationSec`, `sortBy`; `openapi.d.ts:2912-2936`, `5072-5078`, `9043-9046`). The existing new-app `sections.tsx:155` already uses camelCase. Write the avatar/duration/sort helpers against the new camelCase shape — do not copy old-focal verbatim.
- **`kpiSegmentFor` key namespace.** old-focal's `KPI_SEGMENT_MAP` keys are snake_case KPI ids (`total_users`, `active_users_30d`, `dau_mau`, `retention_d7`, `churn_rate`; `UserDetailsModal.tsx:32-38`); the plan writes them camelCase. Confirm the KPI id strings the new `KpiRow`/`overview.tsx` actually emit before fixing the map keys so mapping and ids agree (the plan's own `kpiSegmentFor` test will catch a mismatch).
- **`UsersTable` relative-time has a 5th bucket.** old-focal's `formatRelative` includes a `weeksAgo` tier the new app's `relativeTimeParts` (`dashboard.ts:75-102`) lacks. Decide deliberately whether to preserve old-focal's `weeksAgo` rung (parity) or keep the 4-tier helper; pin it with the relative-label test.

## Tests Reviewed
N/A for plan scoring. Inspected the plan's stated test list (15 `DashboardPage.test.tsx` cases + `dashboard.test.ts` helper-contract cases): covers the admin gate, custom-date disabling, export CSV/PDF routing + failure, overview loading/error, KPI click+keyboard modal open, lazy section fetch-on-open, retention/churn independent pagination, cohort immature/absolute tooltips, feature top-user ordering, modal segment fetch + in-memory search + truncation, and avatar/segment-map determinism. Risky paths each have a named proving test. No suite run (read-only plan review).

## Release Risk
Low

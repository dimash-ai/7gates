# Summary

Re-skin the new Focal admin dashboard in place to match old-focal's `/dashboard`, using the
existing React 19 / Tailwind 4 / shadcn primitives and the already-ported dashboard endpoints. The
implementation stays frontend-only: restyle `DashboardPage.tsx`, `overview.tsx`, `sections.tsx`,
and local dashboard helpers; add only the missing i18n copy and the small `api/dashboard.ts` users
wrapper options needed by the legacy users views. Do not copy old-focal Tailwind 3 code, change the
backend, regenerate OpenAPI, or fake missing data.

# Design-gate data resolution

| parity component | backed by current client/OpenAPI/server? | in-scope plan | deferred handoff |
|------------------|-------------------------------------------|---------------|------------------|
| `UserEngagementSection` | **Backed.** `api/dashboard.ts` exposes `getDashboardUsers`; generated OpenAPI exposes `GET /api/dashboard/users` returning `UsersRead.summary.avgActionsPerUser`, `UsersRead.summary.avgSessionDurationSec`, and `DashboardUserRow[]`; `server/app/api/dashboard.py` routes `/users`; `DashboardService.users()` computes the summary and row engagement metrics. | Build old-focal's engagement section over `/api/dashboard/users`: mini KPI cards, users table, section CSV export, pagination, loading/error/empty states. | None for old-focal parity. Do not add new metrics beyond the existing summary/row fields. |
| `UserDetailsModal` | **Backed for old-focal's actual modal shape, not for a true per-user detail fetch.** old-focal's `UserDetailsModal` is a KPI segment-list modal that fetches `/api/dashboard/users?pageSize=1000` with a segment override and filters in memory. The current OpenAPI/server have no `/api/dashboard/users/{id}` or per-user detail schema. | Build the KPI segment modal exactly as old-focal: clickable KPI cards map to existing segment filters (`all`, `active`, `new`, `churned`), fetch up to 1000 users, client-side search by name/email/status token, status column, truncation warning. Extend only `api/dashboard.ts` options for `sortBy`/`order` if needed. | Any true per-user profile/details endpoint, row-click detail drawer, or richer user history is **unbacked** and must be a separate backend handoff, not faked here. |
| `UserAvatar` | **Backed without an endpoint.** old-focal's avatar is deterministic initials + color from the row `name`; `DashboardUserRow.name` is already present. There is no avatar URL/image field. | Build the client-only initials avatar helper/component inside the dashboard feature and use it in user lists. | Real uploaded/profile avatar images or a new avatar URL field are unbacked and out of scope. |

# Screenshot parity tolerance

Visual parity is checked against old-focal screenshots for light and dark at desktop `1440x900` and
mobile `390x844`, with every expandable section opened once and the KPI modal opened once. The
numeric pass bar is `pixelmatch`-style threshold `0.10`, full-page mismatch ratio `<= 1.0%`, and
named crop mismatch ratio `<= 0.75%` for header/controls, KPI row, insights row, chart/cards,
expanded sections, and modal. Any missing old-focal control/section, clipped text, incoherent
overlap, wrong breakpoint layout, or structural offset greater than `4px` fails even if the pixel
ratio passes. Only dynamic timestamps/tooltips may be masked; permanent cards, rows, labels, and
charts are not masked.

# Files to change

| path | change | why |
|------|--------|-----|
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-dashboard/apps/focal/client/src/api/dashboard.ts` | Extend `getDashboardUsers` options to include `sortBy?: 'actions_24h' \| 'sessions' \| 'last_active' \| 'name'` and `order?: 'asc' \| 'desc'`, passed as existing OpenAPI query names `sortBy` and `order`. No new endpoint. | The old-focal engagement section and KPI modal rely on sorted users calls; the backend and OpenAPI already support them, but the current wrapper does not expose them. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-dashboard/apps/focal/client/src/features/dashboard/DashboardPage.tsx` | Rework the page shell/header/controls/export modal, keep admin gating and the existing overview/section queries, own KPI-modal state, and pass query states into overview components. Use the shell `SidebarTrigger` in an old-focal-style local header; do not edit shared `PageHeader` or shell files. | This is the route surface and the current owner of filters, exports, queries, and section open state. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-dashboard/apps/focal/client/src/features/dashboard/overview.tsx` | Restyle KPI cards, insight cards, retention curve, screen distribution, and devices to old-focal parity, including tooltips, dark-mode classes, loading/error/empty branches, clickable/keyboard KPI cards, and old-focal chart/card rhythm. | This file owns the always-on dashboard overview blocks. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-dashboard/apps/focal/client/src/features/dashboard/sections.tsx` | Replace the current generic users section with old-focal `UserEngagementSection` behavior; add local `UserAvatar`, `UsersTable`, and `UserDetailsModal` pieces; restyle `ExpandableSection`, retention/churn, cohort, and feature operations to old-focal parity. | This file owns the collapsible detail sections and the absent but backed user-engagement/modal/avatar parity pieces. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-dashboard/apps/focal/client/src/features/dashboard/dashboard.ts` | Add or adjust dashboard-local pure helpers for KPI segment mapping, user initials/color, duration formatting, status-token search, and any class mapping updates such as old-focal heatmap tokens. Preserve existing CSV, relative-time, sparkline, and cohort helpers. | Keeps deterministic display/data helpers testable without adding global utilities. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-dashboard/apps/focal/client/src/features/dashboard/dashboard.test.ts` | Preserve existing helper coverage and add tests for new pure helpers and any updated class mappings. | Pure behavior should stay covered outside component rendering. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-dashboard/apps/focal/client/src/features/dashboard/DashboardPage.test.tsx` | Add page/component tests with mocked `getMe` and dashboard API calls for access gating, controls/export, user engagement, KPI modal, and expanded sections. | The current dashboard test file is pure `.ts`; the visual re-skin needs focused component coverage without broad snapshots. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-dashboard/apps/focal/client/src/i18n/locales/en.json` | Add missing `focal.dashboard` keys for old-focal tooltips, export dialog, mini KPI labels/tooltips, pagination, modal copy, empty states, status tooltip, feature/cohort metadata labels, and any renamed old-focal section labels. | No visible or accessible dashboard copy should be hardcoded. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-dashboard/apps/focal/client/src/i18n/locales/ru.json` | Add the same keys in Russian, reusing old-focal copy where it maps directly. | RU and EN remain first-class for the dashboard page. |

No generated OpenAPI, backend, package, Tailwind config, shared shell, or shared `components/ui/*`
change is planned.

# Implementation slices

1. Set up backed helpers, i18n, and the users API wrapper.
   - Extend only `api/dashboard.ts` for the already-backed users query options (`sortBy`, `order`).
   - Add dashboard-local helpers in `dashboard.ts`: `initialsFor`, deterministic `colorFor`,
     `formatDuration`, status search tokens, and `kpiSegmentFor` mapping:
     `totalUsers -> all`, `activeUsers30d -> active`, `dauMau -> active`,
     `retentionD7 -> new`, `churnRate -> churned`.
   - Add EN/RU keys for tooltip, modal, mini KPI, pagination, export dialog, and old-focal empty/error
     copy before UI consumes them.
   - Update `dashboard.test.ts` for the new helpers and keep all existing helper tests green.

2. Rebuild the dashboard header and export controls.
   - Keep `me.canAccessDashboard` loading/denied behavior unchanged.
   - Replace the two always-visible export buttons with old-focal's single Export button and dialog
     that selects `PDF` or `CSV`, while reusing the existing `exportCsv` and `exportPdf` functions.
   - Keep period/segment/custom-date filter state and query enabling unchanged; custom period with
     missing dates disables export and dashboard queries and shows the existing hint in old-focal
     spacing.
   - Compose a local old-focal-style header with the shell `SidebarTrigger`, title, subtitle, and
     `DashboardControls` cluster. Do not pull in old-focal's provider/query layer and do not edit
     shared `PageHeader`.
   - Add component tests proving admin loading/denied states, custom-date disabling, and export dialog
     routing to CSV/PDF.

3. Restyle always-on overview blocks.
   - Update `KpiRow`/`KpiCard` to old-focal grid (`grid-cols-2 md:grid-cols-3 xl:grid-cols-5`),
     card chrome, info tooltips, delta icons/classes, `new` color, keyboard activation, and KPI modal
     open callback.
   - Update `InsightsRow`/cards to old-focal one-column mobile, two-column tablet, four-column desktop,
     with dark-mode type backgrounds and localized `textKey` preference when present.
   - Update `RetentionCurveCard`, `ScreensCard`, and `DevicesCard` to old-focal title tooltips,
     loading/error/empty/collecting states, chart margins/ticks/gradient, devices stacked bar/list,
     and devices insight copy.
   - Keep Recharts, query keys, and data shapes unchanged.
   - Add component tests for loading/error branches, KPI click/keyboard open behavior, insight
     localization fallback, and devices collecting/insight states.

4. Build the backed user engagement section, users table, avatar, and KPI modal.
   - Replace `UsersSection` with old-focal `UserEngagementSection`: mini KPI cards from
     `UsersRead.summary`, section-level CSV export fetching `pageSize: 1000`, table page size 15,
     pagination summary, and no inline search field.
   - Add a local `UsersTable` that matches old-focal: avatar + name/email, optional status column
     only for the modal, mono numeric columns, trend icons, relative-time labels updated on a minute
     tick, loading and segment-specific empty states.
   - Add `UserAvatar` as deterministic initials/color from `DashboardUserRow.name`; no avatar endpoint
     or fake image.
   - Add `UserDetailsModal` as the old-focal KPI segment modal: segment override via the existing
     filters object, `pageSize: 1000`, client-side search by name/email/status token, truncation
     warning when `total > users.length`, and close hint.
   - Do not implement a true per-user detail/profile fetch; record that as the deferred handoff above.
   - Add component tests for summary mini KPIs, users section CSV, avatar determinism, KPI segment
     mapping, modal search/status filtering, and truncation warning.

5. Restyle retention/churn, cohort, and feature-operation sections.
   - Replace the generic `Section` chrome with old-focal `ExpandableSection` styling, icons
     (`Users`, `Activity`, `Calendar`, `Flame`), `hover-elevate`, and section-level query enabling
     only while open.
   - Retention/churn: two independent paginated columns, avatars, retained/churned tooltips, old-focal
     badges, empty states, loading spinners, and independent page reset when data changes.
   - Cohort: week granularity request, metric tooltip row, optional max-height scroll above 15 cohorts,
     localized week labels, immature cells, absolute-value tooltips, and old-focal
     `dashboard-heatmap-*` ramp.
   - Feature operations: metric tooltip, ranked bars, percentage/count display, top-users badge list
     ordered by the already-sorted features array, and empty top-user dash.
   - Add component tests proving closed sections do not fetch, expansion fetches the right endpoint,
     retention/churn independent pagination works, cohort immature/absolute tooltips render, and feature
     top-user badges follow feature order.

6. Final integration, visual parity, and cleanup.
   - Remove only code made unused by the dashboard re-skin; do not refactor unrelated files.
   - Confirm CSV/PDF export still includes the same data bundle and file download behavior.
   - Run focused tests first:
     ```sh
     cd /Users/allosta/Desktop/allosta/.worktrees/focal-redesign-dashboard/apps/focal/client
     pnpm test:run src/features/dashboard/dashboard.test.ts src/features/dashboard/DashboardPage.test.tsx
     ```
   - Run the required full client checks:
     ```sh
     cd /Users/allosta/Desktop/allosta/.worktrees/focal-redesign-dashboard/apps/focal/client
     pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
     ```
   - Capture old-focal and new screenshots in light/dark at `1440x900` and `390x844`, with all
     sections opened and the modal opened, and apply the tolerance defined above.

# Tests

- `dashboard.test.ts`: preserves existing `cohortCellClass` coverage; if the implementation switches
  to old-focal `dashboard-heatmap-*` classes, proves the exact threshold-to-class mapping.
- `dashboard.test.ts`: existing `isImmatureCell` cases stay green; proves cohort maturity still keys
  off the response period end rather than wall-clock time.
- `dashboard.test.ts`: existing `sparklinePath` and `deltaDirection` cases stay green; proves KPI
  chart/delta math did not change during the card re-skin.
- `dashboard.test.ts`: existing `relativeTimeParts`, `csvCell`, and `buildDashboardCsv` cases stay
  green; proves table relative labels and export escaping still behave.
- `dashboard.test.ts`: `initialsFor` and `colorFor` produce stable initials/colors for names, empty
  names, and anagrams; proves the client-only avatar has deterministic behavior.
- `dashboard.test.ts`: `formatDuration` formats `null`, whole minutes, and seconds; proves engagement
  mini KPI display is deterministic.
- `dashboard.test.ts`: `kpiSegmentFor` maps every clickable KPI to the old-focal modal segment and
  rejects/ignores unknown keys; proves the modal does not silently show the wrong users.
- `DashboardPage.test.tsx`: loading and access-denied branches render from mocked `getMe`; proves the
  admin gate remains intact.
- `DashboardPage.test.tsx`: segment/period/custom-date controls update query filters, and incomplete
  custom dates disable dashboard fetching/export; proves filters kept their existing contract.
- `DashboardPage.test.tsx`: old-focal export dialog can generate CSV and PDF, calls the existing
  export paths, handles export failure visibly, and re-enables controls; proves UI parity did not break
  export behavior.
- `DashboardPage.test.tsx`: overview loading/error/success branches render KPI cards, insight cards,
  retention chart, screen distribution, and devices states; proves overview visual states are covered.
- `DashboardPage.test.tsx`: KPI cards open the modal by click and keyboard; proves the old-focal modal
  affordance is accessible.
- `DashboardPage.test.tsx`: user engagement expansion fetches `/users`, shows mini KPIs, renders a
  no-status users table with avatars, paginates, and exports all users; proves the backed engagement
  section is functional.
- `DashboardPage.test.tsx`: KPI modal fetches the mapped segment with `pageSize: 1000`, searches in
  memory by name/email/status token, shows the status column, and renders truncation warning; proves
  the modal uses backed list data and does not invent per-user details.
- `DashboardPage.test.tsx`: closed retention/churn, cohort, and feature sections do not fetch; opening
  each section fetches once with current filters; proves old-focal lazy section behavior.
- `DashboardPage.test.tsx`: retention/churn columns render separate pagination, avatars, badges, and
  empty/error states; proves the old-focal section shape.
- `DashboardPage.test.tsx`: cohort rows render localized week labels, immature placeholders, heatmap
  classes, and absolute tooltips; proves the cohort matrix parity path.
- `DashboardPage.test.tsx`: feature bars and top-user badges render in feature order with empty dashes;
  proves feature operations did not lose top-user data.
- Final command set: `cd /Users/allosta/Desktop/allosta/.worktrees/focal-redesign-dashboard/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.
- Visual verification: light/dark desktop/mobile screenshots pass the concrete tolerance above.

# Error & rescue map

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| `dashboard.access.meLoading` | No exception; `getMe` pending | Existing `DashboardPage` loading branch | Centered spinner and screen-reader loading label. |
| `dashboard.access.denied` | No exception; `me.canAccessDashboard !== true` or `getMe` has no usable admin data | Existing `DashboardPage` denied branch | Old-focal access-denied title/subtitle; no dashboard queries are enabled. |
| `dashboard.filters.customIncomplete` | No exception; `period === 'custom'` and one date missing | `DashboardPage` derived `customIncomplete` guard | Old-focal hint text; dashboard queries and export generation stay disabled. |
| `dashboard.overview.failed` | `getOverview(filters)` rejects through React Query | `KpiRow` and `InsightsRow` error props/branches | Localized section error for KPI/insights while the rest of the page shell remains mounted. |
| `dashboard.retentionCurve.failed` | `getRetentionCurve(filters)` rejects | `RetentionCurveCard` error branch | Localized chart-section error inside the old-focal card. |
| `dashboard.screenDistribution.failed` | `getScreenDistribution(filters)` rejects | `ScreensCard` error branch | Localized screen-section error inside the old-focal card. |
| `dashboard.devices.failed` | `getDevices(filters)` rejects | `DevicesCard` error branch | Localized devices-section error inside the old-focal card. |
| `dashboard.devices.collecting` | No exception; `DevicesRead.collecting === true` | `DevicesCard` collecting branch | Old-focal collecting-data copy instead of a noisy distribution. |
| `dashboard.users.failed` | `getDashboardUsers(filters, ...)` rejects | `UserEngagementSection` or `UserDetailsModal` query branch | Engagement section shows localized section error; modal table shows loading/error-safe empty state and remains closeable. |
| `dashboard.users.emptySegment` | No exception; users response is empty | `UsersTable` empty branch | Segment-specific old-focal empty copy. |
| `dashboard.modal.truncated` | No exception; `UsersRead.total > users.length` after `pageSize: 1000` | `UserDetailsModal` truncation branch | Amber warning with shown/total counts; no fake pagination is invented. |
| `dashboard.retentionChurn.failed` | `getRetentionChurn(filters)` rejects | `RetentionChurnSection` error branch | Localized section error; existing page state and other sections remain usable. |
| `dashboard.cohort.failed` | `getCohortAnalysis(filters)` rejects | `CohortSection` error branch | Localized section error inside the opened accordion. |
| `dashboard.features.failed` | `getFeatureOperations(filters)` rejects | `FeaturesSection` error branch | Localized section error inside the opened accordion. |
| `dashboard.export.csvFailed` | Any export-time users/overview/cohort/features query or CSV download setup rejects | Export dialog `try/catch/finally` in `DashboardPage` | Localized destructive export error, dialog stays open, controls re-enable. |
| `dashboard.export.pdfFailed` | Dynamic `html2canvas`/`jspdf` import, canvas rendering, PDF generation, or download setup rejects | Export dialog `try/catch/finally` in `DashboardPage` | Localized destructive export error, dialog stays open, controls re-enable. |
| `dashboard.noPerUserDetailEndpoint` | No runtime exception; route/schema absent by design | Scope boundary in this plan | No per-user profile UI is rendered; backend handoff remains explicit. |

# Review lenses (pre-answer before gate2-plan)

- **Scope / strategy** - This is the minimum complete dashboard parity slice: one admin page, its
  local feature files, i18n copy, focused tests, and one wrapper expansion for an existing endpoint.
  Existing FastAPI routes, generated OpenAPI, query data shapes, admin gate, and CSV/PDF data
  generation remain the behavior base. The backed/deferred decisions for engagement, modal, and avatar
  are explicit so no fake server data enters the UI.
- **Architecture** - `DashboardPage` continues to own filters, custom-date completeness, export state,
  admin gate, overview queries, section open state, and KPI modal state. `overview.tsx` stays
  presentational over query results. `sections.tsx` owns lazy section queries and user-list UI. Pure
  formatting/mapping helpers live in `dashboard.ts` and are unit-tested. Unhappy paths are handled in
  component-local query branches rather than by changing API wrappers or global error behavior.
- **Design** - Light and dark old-focal parity is defined up front with a numeric screenshot
  tolerance. The plan covers loading, access-denied, custom-incomplete, query-error, empty, collecting,
  truncated, modal-open, all-sections-open, desktop, and mobile states. Keyboard behavior is covered
  for clickable KPI cards and modal close/search paths.
- **DevEx** - No new package, route, generated type, Tailwind config, server file, or shared UI
  primitive is introduced. Tests are split between pure helper contracts and focused rendered behavior
  instead of broad snapshots. The only non-feature implementation edit is the strictly-needed
  dashboard API wrapper option exposure for already-existing query params.

# Risks & migrations

- No database migration, backend/API/schema change, generated OpenAPI change, environment variable,
  package dependency, lockfile update, or data backfill.
- Main risk: the dashboard is a dense page and exact old-focal parity touches all local dashboard
  files. Mitigation: implement in the ordered slices above, keep each slice buildable, and use focused
  tests for each behavior class.
- Secondary risk: the local header must preserve old-focal spacing while using the new shell's
  `SidebarTrigger`. Mitigation: use the shell trigger directly in the dashboard header and do not edit
  shared `PageHeader` or shell components.
- Tertiary risk: the old-focal `UserDetailsModal` name can be misread as a true per-user detail
  endpoint. Mitigation: build only the backed segment-list modal old-focal actually ships, and keep any
  real per-user profile fetch as a named handoff.
- Screenshot risk: live chart/text antialiasing and dynamic relative timestamps can create harmless
  pixel drift. Mitigation: use the pinned tolerance and mask only dynamic timestamps/tooltips, never
  permanent layout or content.
- Rollback plan: revert the planned dashboard feature files, the `api/dashboard.ts` wrapper addition,
  the dashboard component test, and locale additions. No persistent data or server behavior changes
  are introduced.

# Scope check

- [x] Matches the task's Scope and Out of scope.
- [x] Small enough to review in one sitting if implemented in the ordered slices above.
- [x] Size smell checked: this is a full-page re-skin plus three backed parity pieces, but it remains
      confined to `features/dashboard/*`, i18n keys, and one strictly-needed API wrapper expansion.

# Out of scope

- Any server route, schema, migration, dashboard service logic, generated OpenAPI, package, lockfile,
  Tailwind config, or shared shell/UI primitive change.
- A true per-user detail/profile endpoint or row-click user history view; this is unbacked and must be
  a separate handoff.
- Real avatar image fetching or adding an avatar URL field.
- New dashboard metrics, new sections, changed filters, changed admin-access model, changed CSV/PDF
  data semantics, or backend-driven engagement fields beyond `UsersRead.summary` and
  `DashboardUserRow`.
- Lifting old-focal Tailwind 3 config/components/provider/query code verbatim.
- Any non-dashboard left-nav page or unrelated redesign cleanup.

# Design — focal-redesign-dashboard

Traces to `.ai/think/focal-redesign-dashboard.md` (gate-1, 9.4) and
`.ai/plans/focal-redesign-dashboard-plan.md` (gate-2, 9.4). Exact old-focal re-skin of the admin
product-dashboard, **frontend-only**, re-skin over the already-functional `features/dashboard/`,
reproduced on the new stack (React 19 / Tailwind 4 / shadcn) — never lifting old-focal Tailwind-3
code. Work lands in the worktree `.worktrees/focal-redesign-dashboard` (branch
`feat/focal-redesign-dashboard`, off slice-0 `afaaeba`).

## Architecture

**The one structural adaptation:** old-focal wires the dashboard through a React **`DashboardContext`**
(`openKpiModal`/`activeModalKpi`, `isSectionOpen`, segment/period/custom state, `useDashboardData`
hooks). The new app has **no such context** — `DashboardPage` already owns `segment`/`period`/custom +
`openSections` state and prop-drills into `overview.tsx`/`sections.tsx` over the typed `api/dashboard.ts`.
We **keep the new app's local-state + props architecture** and reproduce old-focal's *behavior* on top
of it — we do **not** port the context. Concretely, `DashboardPage` gains two pieces of local state and
the matching callbacks, passed down as props:

- `activeModalKpi: KpiKey | null` + `openKpiModal(key)` / `closeKpiModal()` → replaces
  old-focal `DashboardContext.openKpiModal` / `activeModalKpi`.
- (existing) `openSections` + `toggleSection` already replace old-focal `isSectionOpen`.

Component tree after the slice (file → components; old-focal source each reproduces):

| New file | Components (new) | old-focal contract reproduced |
|---|---|---|
| `features/dashboard/DashboardPage.tsx` | page shell, local header, controls cluster, **export dialog**, owns `activeModalKpi` | `pages/Dashboard.tsx` + `DashboardControls.tsx` (header + segment/period/custom + single Export→dialog) |
| `features/dashboard/overview.tsx` | `KpiRow`/`KpiCard` (**clickable + tooltip + arrow delta**), `InsightsRow`/`InsightCard`, `RetentionCurveCard`, `ScreensCard`, `DevicesCard` | `KpiRow`/`KpiCard`, `InsightsRow`/`InsightCard`, `RetentionCurveChart`, `ScreenDistributionCard`, `DevicesCard` |
| `features/dashboard/sections.tsx` | `ExpandableSection`, `UserEngagementSection` (+ `UsersTable`, `UserAvatar`), `UserDetailsModal`, `RetentionChurnSection`, `CohortSection`, `FeaturesSection` | `ExpandableSection`, `UserEngagementSection`, `UsersTable`, `UserAvatar`, `UserDetailsModal`, `RetentionChurnSection`, `CohortAnalysisSection`, `FeatureOperationsSection` |
| `features/dashboard/dashboard.ts` | + `kpiSegmentFor`, `initialsFor`, `colorFor`, `formatDuration`, `statusSearchTokens`, `csvSection` (keep existing helpers) | old-focal `KPI_SEGMENT_MAP`, `UserAvatar` initials/color, `formatDuration`, `STATUS_SEARCH_TOKENS`, `lib/csv.csvSection` |
| `api/dashboard.ts` | extend `getDashboardUsers` opts with `sortBy`/`order` | already-backed query params (`openapi.d.ts:9043`) |
| `i18n/locales/{en,ru}.json` | new `focal.dashboard.*` keys | old-focal `dashboard.*` copy |

`DashboardPage` stays the single owner of filters, custom-date completeness, export state, section
open-state, **and the new `activeModalKpi`**; `overview.tsx`/`sections.tsx` stay presentational over
query results + callbacks; pure formatting/mapping lives in `dashboard.ts`. No `DashboardProvider`,
no `useDashboardData`, no `lib/dashboardExport`/`lib/csv` import — the new app's own equivalents are used.

## Data model & contracts (all existing, camelCase — no backend/OpenAPI change)

- **KPI keys (camelCase, confirmed `overview.tsx:33-39`):** `totalUsers`, `activeUsers30d`, `dauMau`,
  `retentionD7`, `churnRate`. The clickable-KPI → modal-segment map (old-focal `KPI_SEGMENT_MAP`,
  snake_case → **rewritten camelCase**):
  `totalUsers→all`, `activeUsers30d→active`, `dauMau→active`, `retentionD7→new`, `churnRate→churned`.
  `kpiSegmentFor(key)` returns the segment or `undefined` for unknown keys (the modal never silently
  shows the wrong users).
- **Users (camelCase, confirmed `sections.tsx:141-161`, `openapi.d.ts:2912-2936`,`5072-5078`):**
  `DashboardUserRow` = `{ id, name, email, status('active'|'inactive'|'churned'), actions24h, sessions,
  lastActiveAt, trend('up'|'down'|'flat') }`; `UsersRead.summary` = `{ avgActionsPerUser,
  avgSessionDurationSec }`. **No per-user-detail field/endpoint** → the modal is old-focal's
  *segment-list* modal only; a true per-user profile is the **deferred backend handoff** (not built,
  not faked).
- **`api/dashboard.ts` extension:** `getDashboardUsers(filters, { page, pageSize, search?, sortBy?,
  order? })` where `sortBy ∈ {'actions_24h'|'sessions'|'last_active'|'name'}`, `order ∈ {'asc'|'desc'}`,
  passed as the existing OpenAPI query names `sortBy`/`order` (verified valid params, `openapi.d.ts:9043`
  — **wrapper-only, no new route, no regen**). The engagement table + section-CSV + KPI modal call it
  with `sortBy:'actions_24h', order:'desc'`.
- **New pure helpers in `dashboard.ts`:** `initialsFor(name)`, deterministic `colorFor(name)`,
  `formatDuration(sec|null)` (`Xm SSs`, `—` for null), `statusSearchTokens` (ru+en, **prefix** match —
  not substring — so "активен" ≠ "неактивен"), `kpiSegmentFor(key)`, and `csvSection(title, headers,
  rows)` for the engagement section CSV (reuses the existing `csvCell` injection guard).
- **Relative time (gate-2 SC#3 decision):** extend `relativeTimeParts` with a **`weeks`** tier to match
  old-focal's `formatRelative`, and refresh the users table's relative labels on a **minute tick** (old-focal
  behavior). Bounded change to the existing helper + a `useEffect` interval in `UsersTable`.

## Interfaces (new/changed component props)

- `KpiCard({ meta, kpi, onOpen })` — `onOpen(key)` fires on click + Enter/Space; `role="button"`,
  `tabIndex={0}`, `data-testid="kpi-${key}"`; Info tooltip when a KPI has one; delta badge with
  `ArrowUpRight`/`ArrowDownRight`. The tooltip trigger `stopPropagation`s so it doesn't open the modal.
- `KpiRow({ overview, onOpenKpi })` — maps `KPI_ORDER`, forwards `onOpenKpi`.
- `UserDetailsModal({ activeKpi, filters, onClose })` — `open = activeKpi !== null`; fetches
  `getDashboardUsers({ ...filters, segment: kpiSegmentFor(activeKpi) }, { page:1, pageSize:1000,
  sortBy:'actions_24h', order:'desc' })` (enabled only when open); in-memory search (name/email/status
  tokens); `truncated = total > users.length` → amber warning; `UsersTable showStatus`; resets search on
  `activeKpi` change.
- `UserEngagementSection({ filters, open, onToggle })` — `ExpandableSection` (Users icon, `text-chart-2`);
  two mini-KPI cards (`avgActionsPerUser`, `formatDuration(avgSessionDurationSec)`) with Info tooltips;
  section CSV button (fetches `pageSize:1000`); `UsersTable` (no status column) page size 15 + pagination;
  resets page on filter change; query enabled only when `open`.
- `UsersTable({ users, loading, segment, showStatus? })` — avatar + name/email, mono numeric columns
  (`actions24h`, `sessions`), `RelativeTime` (minute-tick), trend glyph; segment-specific empty copy;
  loading state.
- `UserAvatar({ name, size? })` — initials + deterministic color from `name`; presentational, no network.
- `ExpandableSection({ id, icon, title, open, onToggle, children })` — old-focal chrome
  (`hover-elevate`, chevron rotate, border-top body), body mounts only when `open`.

## Happy + unhappy flow

- **Admin gate (unchanged):** `getMe` loading → spinner; `!canAccessDashboard` → access-denied panel; no
  dashboard queries enabled until access is confirmed.
- **Filters:** segment/period/custom unchanged; `period==='custom'` with a missing date →
  `customIncomplete` disables all dashboard queries **and** export, shows the hint.
- **KPI → modal (happy):** click/Enter on a KPI card → `openKpiModal(key)` → modal opens → one fetch of
  the mapped segment (≤1000) → in-memory search → close via overlay/Esc/`onClose`.
- **Export (happy):** single Export button → dialog → choose PDF|CSV → Generate → reuse existing
  `exportCsv`/`exportPdf`.
- **Unhappy (each query branch, no global handler):** overview/curve/screens/devices/users/retention-churn/
  cohort/features rejection → localized section-level error while the page shell stays mounted; devices
  `collecting` → collecting copy; empty users → segment-specific empty; modal `total>shown` → truncation
  warning (no fake pagination); **export failure → dialog stays open, controls re-enable, inline
  destructive `Alert` in the dialog** (see alternative below); unbacked per-user detail → simply absent.
  (Full table: plan "Error & rescue map".)

## Alternatives rejected

- **Port old-focal `DashboardContext` + `useDashboardData`.** Rejected — the new app has neither; adding
  global context + a parallel data layer for one admin page is non-surgical and duplicates the typed
  `api/dashboard.ts`. Local state + props in `DashboardPage` reproduces the same behavior with less code.
- **Introduce a toast for export errors (old-focal uses `useToast`).** Rejected — the new
  `DashboardPage` has no toast infra; adding a toast system is out of scope. Use an **inline destructive
  `Alert` inside the export dialog** — same UX contract (modal stays open, user retries), zero new infra.
- **Build a true per-user detail/profile modal.** Rejected/deferred — no backing endpoint
  (`/api/dashboard/users/{id}` absent); old-focal's modal is itself only a segment list. Recorded as a
  named backend handoff; nothing faked.
- **Lift old-focal components verbatim.** Rejected — Tailwind-3 + snake_case fields + `@/lib/*` imports;
  reproduce structure/classes on the new camelCase types + new primitives.

## Test strategy

Per the plan's Tests section. `dashboard.test.ts` (pure): keep existing `cohortCellClass`/`isImmatureCell`/
`sparklinePath`/`deltaDirection`/`relativeTimeParts`/`csvCell`/`buildDashboardCsv` green; add
`initialsFor`/`colorFor` determinism (incl. empty name, anagrams), `formatDuration` (null/whole-min/secs),
`kpiSegmentFor` (every camelCase KPI → segment; unknown → undefined), `statusSearchTokens` prefix
behavior, and `relativeTimeParts` `weeks` tier. New `DashboardPage.test.tsx` (component, mocked `getMe`
+ api): admin loading/denied; custom-date disabling; export dialog routes CSV/PDF + failure keeps dialog
open; overview loading/error; **KPI click + keyboard opens modal**; modal fetches mapped segment at
`pageSize:1000`, in-memory search by name/email/status, truncation warning; lazy sections do not fetch
while closed and fetch once on open; retention/churn independent pagination; cohort immature/absolute
tooltips; feature top-user order. Gate: `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` in
the worktree client; visual parity at the pinned tolerance (plan "Screenshot parity tolerance":
light+dark, `1440x900`+`390x844`, sections+modal opened, pixelmatch threshold `0.10`, full-page mismatch
≤1.0%, crops ≤0.75%, structural offset >4px fails).

## Security notes

- **Admin-gated, unchanged:** the page + every query stays behind `me.canAccessDashboard`; the gate is
  not weakened. User emails (PII) render only inside this admin surface — same as old-focal/current.
- **CSV formula-injection guard preserved:** all CSV cells go through the existing `csvCell` (leading
  `= + - @` → quote-prefixed); the new `csvSection` reuses it. No raw user text reaches a CSV cell.
- **No new endpoints, no new auth surface, no secrets, no `dangerouslySetInnerHTML`.** Frontend-only;
  data shapes and the admin allow-list are untouched.

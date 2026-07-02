# Problem

Re-skin the new Focal **admin product-dashboard** (`apps/focal/client/src/features/dashboard/`) to
**exact visual parity with old-focal's `/dashboard`**, as the dashboard slice of the
`focal-redesign-pages` epic (parent: `.ai/think/focal-redesign-pages.md`; binding source = exact
old-focal; re-skin over working features, reproduce on the new stack — Tailwind 4 / React 19 /
shadcn, never lift old-focal's Tailwind-3 code).

This slice is unusually **low-risk on data and structure** because the new dashboard is a functional
port that already mirrors old-focal's information architecture, and **the filter/data contracts
already match exactly**:

- Both render: header + controls → KPI row → insights row → (retention-curve | screen-distribution +
  devices) → collapsible sections (users, retention-churn, cohort, features). New:
  `DashboardPage.tsx` + `overview.tsx` + `sections.tsx`; old: `Dashboard.tsx` + `components/dashboard/*`.
- Filter options are **identical**: periods `7d/30d/90d/6m/1y/custom`, segments
  `all/active/new/churned/retained/power`, export `csv|pdf` — confirmed in both
  `DashboardPage.tsx` and old-focal `DashboardControls.tsx`. So nothing about data/filters changes;
  this is appearance only.
- Admin-gated identically (`me.canAccessDashboard`), with loading + access-denied states already
  present in both.

So the work is restyling existing, wired components to old-focal's exact look (card chrome, KPI/insight
cards, Recharts styling, cohort-heatmap colour ramp, section/table styling) in light **and** dark,
using the slice-0 tokens.

**The one real scope question** (what gate-1 must resolve): old-focal has three components the new app
**lacks** — `UserEngagementSection`, `UserDetailsModal`, `UserAvatar` (the new app folds users into a
single `UsersSection` table with no click-through modal). "Exact parity" pulls toward building them;
the epic's "re-skin, not rebuild; a needed backend field is a separate handoff; nothing faked" pulls
toward only restyling what exists unless an existing endpoint backs the addition. Framing which is
which — against the new `api/dashboard.ts` + the ported `server/app/services/dashboard.py` — is the
job of this doc.

# Assumptions

- **[confirmed — parent epic]** Binding contract = exact old-focal; re-skin only (no behavior/data
  change); reproduce on the new stack; light+dark; i18next `ru`+`en`; surgical diff; no server/API
  change. Slice runs in the worktree `.worktrees/focal-redesign-dashboard` off slice-0 `afaaeba` (so
  the old-focal tokens are already present).
- **[confirmed — fs]** New `features/dashboard/`: `DashboardPage.tsx` (header/controls + overview +
  4 collapsible sections, CSV via `buildDashboardCsv`, PDF via lazy `html2canvas`+`jspdf`, admin-gated),
  `overview.tsx` (`KpiRow`, `InsightsRow`, `RetentionCurveCard`, `ScreensCard`, `DevicesCard`),
  `sections.tsx` (`Section`, `UsersSection`, `RetentionChurnSection`, `CohortSection`, `FeaturesSection`),
  `api/dashboard.ts` (the 7 query fns), `dashboard.test.ts` (114 lines — must stay green).
- **[confirmed — fs]** old-focal `/dashboard` = `pages/Dashboard.tsx` wrapping `DashboardProvider` +
  16 `components/dashboard/*` (`DashboardControls`, `KpiRow`/`KpiCard`, `InsightsRow`/`InsightCard`,
  `RetentionCurveChart`, `ScreenDistributionCard`, `DevicesCard`, `UserEngagementSection`,
  `RetentionChurnSection`, `CohortAnalysisSection`, `FeatureOperationsSection`, `UsersTable`,
  `UserDetailsModal`, `UserAvatar`, `ExpandableSection`). Filter/period/export sets match the new app.
- **[confirmed — grep]** Parity gap: the new app has **no** `UserDetailsModal` / `UserAvatar` /
  `UserEngagementSection` (grep for Modal/Avatar/engagement/UserDetails in `features/dashboard/` is
  empty). old-focal's users area is richer (an engagement section + a users table + a click-through
  details modal with an avatar).
- **[unverified — settle at design gate]** whether the new `api/dashboard.ts` / the ported
  `services/dashboard.py` expose a **per-user-detail** endpoint that `UserDetailsModal` needs. If yes
  → a `UserDetailsModal` (+ `UserAvatar`) is an **in-scope, frontend-only** parity add over an existing
  wrapper. If no → it is **backend-blocked → flagged handoff, not faked** (same discipline as the
  heatmap/analytics slices). The design gate verifies this against the OpenAPI types before deciding.
- **[unverified — design gate]** exact section default-expand behavior (old-focal `ExpandableSection`
  vs the new app's all-collapsed default) and whether old-focal's `UserEngagementSection` is a
  distinct always-on block or merges into the users section. Visual-parity detail, settled at design.
- **[confirmed — repo]** Recharts is already a dep (used by `overview.tsx` + the analytics slice); no
  new charting dep needed. PDF/CSV export already works and is out of the restyle's behavioral path.

# Options considered

The source-of-truth and re-skin approach are fixed by the epic. The two real forks: **(1)** one slice
vs decompose, and **(2)** how to treat the three parity-gap components.

| # | Fork | Option | Pros | Cons |
|---|------|--------|------|------|
| **1A (chosen)** | size | **One slice.** Restyle the whole dashboard (header + overview + 4 sections) in one feature, since it is a single cohesive page whose structure already matches old-focal and whose files overlap (`DashboardPage`/`overview`/`sections`). | Natural unit (one page = one PR); no awkward mid-page split touching the same files twice; matches "the dashboard slice" ask. | Larger single diff → the gate-5 holistic review must be thorough. |
| 1B | size | Decompose into 2–3 sub-slices (overview cards / sections / modal). | Smaller diffs. | Sub-slices collide on the same files; over-engineering a single page's restyle (the analytics split was justified by a 219-vs-3886-line *rebuild* — not the case here). |
| **2A (chosen)** | parity gaps | **Restyle what exists; add `UserDetailsModal`/`UserAvatar`/engagement only if an existing endpoint backs them — else flag.** Verify at design gate. | Honors exact-parity where cheap/backed; honors "nothing faked / re-skin not rebuild" where not; no server change. | "Exact parity" may be partial pending a flagged backend handoff. |
| 2B | parity gaps | Build all three unconditionally. | Maximal parity. | If unbacked, invents a UI with no data → fakes it / forces a backend change — violates the epic's out-of-scope. Rejected. |
| 2C | parity gaps | Drop them entirely, restyle only. | Smallest. | Leaves a known visible parity gap silently. Rejected (surface, don't hide). |

# Recommendation

**One slice (1A) + parity-gaps-if-backed (2A).** Restyle the existing dashboard — header/controls,
`KpiRow`/`KpiCard`, `InsightsRow`/`InsightCard`, `RetentionCurveChart`, `ScreenDistributionCard`,
`DevicesCard`, and the four collapsible sections — to old-focal's exact look in light+dark over the
existing APIs. For the three missing components: at the **design gate**, check the new
`api/dashboard.ts` + OpenAPI types for the endpoints they need; build `UserDetailsModal` + `UserAvatar`
+ a distinct `UserEngagementSection` **only** where an existing endpoint backs them, and **flag any
backend-blocked piece as a named handoff** (don't fake, don't add a server route in this slice). The
dashboard is admin-gated, so a partial-parity flagged item carries low user risk and stays honest.

Rationale: the page is one cohesive, already-structurally-aligned surface, so splitting its restyle
adds coordination cost without reducing risk; the parity gap is the only judgment call and the
epic already prescribes the "backed → build, unbacked → flag" rule. Carry the parent reviewer's
note forward — pin a concrete screenshot-comparison tolerance for this page at the design gate.

# Out of scope

- Any **server / API / schema / migration** change. A parity component that needs a new endpoint is a
  **separate flagged handoff**, not built here.
- **New metrics / sections** not in old-focal; changing the **admin-access** model; the CSV/PDF export
  *logic* (kept working — only its trigger/control chrome is restyled).
- Any other left-nav page (their own slices). Re-deriving the slice-0 tokens (inherited).

# Open questions

- **Per-user-detail endpoint?** Does `api/dashboard.ts` / `services/dashboard.py` expose what
  `UserDetailsModal` needs? → settles whether the modal+avatar are in-scope adds or a flagged handoff.
  (design gate, against OpenAPI types.)
- **Engagement section shape** — distinct always-on block vs merged into the users section; section
  default-expand behavior. (design gate, visual parity.)
- **Screenshot tolerance** — pin the objective fidelity bar for this page (carried from the epic
  gate-1 Should-Consider). (design gate.)

# Success criteria

- [ ] `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green in the worktree client, with
      the slice's own tests; the existing `dashboard.test.ts` still green.
- [ ] `/dashboard` matches old-focal by screenshot in **light + dark** across header/controls, KPI +
      insight cards, retention curve, screen-distribution, devices, and the four sections.
- [ ] Admin gate + loading/denied states preserved; CSV + PDF still export; no behavior/data change;
      no server/API change; diff confined to `features/dashboard/*` (+ i18n, + any strictly-needed
      `ui`/`api` wrapper for a backed parity component).
- [ ] Backed-vs-deferred is explicit: any parity component without an existing endpoint is a named,
      flagged handoff — nothing faked. i18next `ru` + `en`.

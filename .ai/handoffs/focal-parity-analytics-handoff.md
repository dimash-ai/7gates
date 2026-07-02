# Stage

3-gate · slice 9 of the `focal-parity` epic: **Analytics page parity**. Branch
`feat/focal-parity-analytics` → base `feature/focal-migration` (one commit `96f8515`).
Frontend-only; no server/API/schema/migration; no compute-module changes.

# What changed

Brings the Analytics page to old-focal feature parity — the charts/compute were already ported; this
adds the six presentation features that were dropped (every number consumed already existed in the
six `*Analytics.ts` modules, which are untouched):
- **PDF export** — header button exports the whole report to a multi-page PDF (title page + one A4
  page per section card). Lazy-loads `jspdf`/`html2canvas`, reuses `triggerDownload`, relaxes
  clip/overflow + force-expands collapsed sections for capture, restores everything in `finally`,
  guards re-entry with `isExporting`.
- **Per-section insight blocks** — Mission / Spheres / Projects / Products show the ⚠️/✅/💡 insight
  sentences, thresholds ported from old-focal exactly (the RU-hardcoded Projects/Products strings are
  now properly i18n'd in both locales).
- **Spheres summary cards + totals footer + 💼 marker** — Work + Life-spheres cards (4 columns,
  planVsBudget/factVsPlan sign-colored, completion percent ≥75 green), a `<tfoot>` totals row, and the
  work-row marker.
- **Help popovers** — `HelpCircle` hint popovers on the budget/plan/fact metrics (Mission, Spheres,
  Energy, Projects) and the DeepWork tiles.
- **Per-section collapse** — each section collapses from its header chevron (default expanded, not
  persisted; collapse state lifted to the page so export can force-expand).
- **Products "Show all" reset** — clears the parent-project filter from the empty state.

# Files touched

17 files, all under `apps/focal/client/src/features/analytics/` (AnalyticsPage + the 6 sections +
new `analyticsExport.ts`, `analyticsInsights.ts`, shared `MetricHint`/`SectionCard`/`InsightList`
helpers + tests) and the two locale files `i18n/locales/{en,ru}.json`.

# Tests run

```sh
cd apps/focal/client
pnpm typecheck   # 0 errors
pnpm lint        # biome: 0 errors (287 files)
pnpm test:run    # 83 files, 956 tests passed
pnpm build       # ✓ (jspdf/html2canvas in their own lazy chunks)
```

# Still needs review

- **Frontend-only** — no schema/migration; analytics is read-only over the user's own data (no new
  query/calendarId surface). Client scoping is not security; slice-2 backend RBAC/RLS is the boundary.
- Residual: PDF visual fidelity is covered with mocked html2canvas/jspdf (not a real browser render) —
  worth a one-time manual eyeball post-merge.
- Pre-existing (NOT from this slice): `pnpm lint:i18n` is red from 11 hardcoded strings on
  `feature/focal-migration` (incl. the `% (` recharts fragments in Mission/Energy); this diff adds
  none. Not one of the four required gates.

# PR / release notes (for users)

The Analytics page can now **export a PDF report** of the current period, and each section shows the
**insight summaries** (over/under budget, deficits, priority drift) that the old app had. The Spheres
section regains its **Work / Life-spheres summary cards** and **totals row**; **help tooltips** explain
the budget/plan/fact metrics; each section can be **collapsed**; and Products has a **"Show all"** link
to clear the filter.

(No secrets, tokens, keys, or PII — client components, locale strings, and tests.)

# Status

OPUS VERIFY/RELEASE-GATE APPROVED (9.4). Gate-A design APPROVED 9.3 (2 passes) · Gate-B build
APPROVED 9.0. Cleared for release; open the PR.

# Problem

Bring Focal's **Analytics** page to exact parity with `apps/old-focal/client/src/pages/Analytics.tsx`.
The gap is one of **size**, not backing: old-focal's analytics is a **3,886-line, 6-section** surface
(Mission-vs-Provision, Spheres radar, Project productivity, Energy balance, Deep work, Product
analytics — each with recharts charts, a period selector, and heavy client-side aggregation), while
the new app's `AnalyticsPage.tsx` is a **single 219-line spheres "plan/fact bar" view** on one
endpoint (`/api/analytics/spheres`). So this is **not a re-skin** — it is a multi-section feature
build, and an **epic** of section sub-slices, not one slice.

**Correction (gate-1 review):** an earlier draft wrongly called Mission/Projects/Energy
"backend-blocked." They are **not** — the discriminating fields already exist in the new backend +
generated client: `ProjectRead.project_type` / `is_work_time` / `gives_energy`
(`schemas/projects.py:82,84,95`), `SphereRead.gives_energy` (`schemas/spheres.py:60`), and
`EnrichedEventRead.project_type` / `sphere` / `project_id` (`schemas/calendar.py:256,257,237`). So
**all six sections are frontend-buildable over the existing APIs** — analytics is a **pure
frontend-only epic**, no backend handoff required. The job of this think doc is to decompose it into
section sub-slices and sequence them; the only real risk is its sheer size, which is why it is sliced
and each section is independently gated.

# Assumptions

- **[confirmed — user]** Binding visual contract = old-focal `Analytics.tsx`, exact, on the merged
  shell foundation (slice 0, `afaaeba`, which this worktree branches off).
- **[confirmed — fs]** New analytics frontend = `features/analytics/AnalyticsPage.tsx` (219 lines):
  one month period picker + a "work" plan/fact card + a grid of sphere plan/fact bar cards, on
  `api/analytics.ts` → `getSpheresAnalytics('/api/analytics/spheres')`. No charts/radar/recharts yet.
- **[confirmed — backend read]** **All six sections are backed.** Analytics endpoint:
  `/api/analytics/spheres` → `SpheresAnalyticsRead{period, work{plan,fact}, spheres[]{name,color,
  plan,fact}}`. Supporting data already exposed: `/api/events` (enriched, recurrence-expanded,
  period-filtered, carrying `project_id`/`project_type`/`sphere`), `/api/projects` (+ `/root`,
  `/{id}/products`; `ProjectRead` carries `project_type`/`is_work_time`/`gives_energy`/
  `allocated_work_hours`/`completed_tasks`/`total_tasks`), `/api/spheres` (`gives_energy`,
  `allocated_hours`), `/api/time-budgets/{year}` (working-days/hours settings). So:
  - Mission/Provision ← project `project_type` (mission/provision) + events + budgets. **backed.**
  - Spheres ← `/api/analytics/spheres` + events + spheres budgets. **backed.**
  - Projects ← project `is_work_time` + `allocated_work_hours` + events. **backed.**
  - Energy ← project/sphere `gives_energy` mapped onto events (old-focal derives event energy
    client-side from project/sphere maps — `old-focal/Analytics.tsx:1081,1099,1180,1187`, not from an
    event flag). **backed.**
  - Deep work ← `/api/events` (current month, >2h blocks). **backed.**
  - Products ← project products (`parent_id` set) + events. **backed.**
- **[confirmed — repo CLAUDE]** Recharts ≥3 is the stack's sanctioned chart lib, "add on first feature
  use" — analytics is that first use; install it in the first sub-slice.
- **[confirmed — fs/memory]** Runs in an isolated worktree (`.worktrees/focal-redesign-analytics`,
  branch off `afaaeba`, inside the pipeline root so codex write-gates can write to it); `.ai/` stays
  in the outer repo.
- **[unverified — confirm at each sub-slice's design gate]** the exact recharts chart types/props to
  reproduce old-focal's radar (log scale), stacked bars, and area trends; whether the 12-month trends
  stay client-side over `/api/events` (assumed) or warrant a backend aggregate if per-event volume is
  heavy; the exact `project_type` enum values the backend emits (confirm vs old-focal's mission/
  provision mapping at the mission sub-slice's design gate).

# Options considered

The source-of-truth is fixed (exact old-focal) and everything is backed; the real forks are **whether
to build the full multi-section page** and **how to sequence it**.

| # | Option | What it is | Pros | Cons |
|---|--------|-----------|------|------|
| **A — Full 6-section frontend epic, sequenced (chosen)** | Decompose into 6 section sub-slices; build each as a frontend-only 7-gate sub-slice over the existing APIs, in dependency order, the first one landing the shared period-selector + recharts. | Exact old-focal parity; stays frontend-only (all backed); surgical, independently-gated sub-slices; mirrors the calendar epic's shape. | Large (6 sub-slices); we own the recharts + aggregation logic per section. |
| **B — Minimal restyle of the current bar-view** | Re-skin the existing 219-line spheres-bars page to old-focal tokens; stop. | Tiny, cheap. | Not "exact old-focal" — old-focal's analytics is 6 sections with radar/trends/tables; bars-only misrepresents parity. **Rejected** as under-delivering the goal. |

(The earlier "frontend + in-epic backend handoffs" option is **moot** — the fields already exist, so
no backend change is needed.)

Sequencing fork: build **Spheres first** (it is the page's current subject, fully backed, and a clean
host for the shared period-selector + recharts), then the other backed sections by complexity.

# Recommendation

**Option A — an analytics epic of 6 frontend-only section sub-slices over the existing APIs.** All
data is backed, so no backend handoff is needed; the only management problem is size, solved by
slicing + per-section gates (exactly how the calendar epic handled its scale).

**Sub-slice order** (each a standalone 7-gate feature tracing to this think doc; the first lands the
shared period selector + recharts):

1. `focal-redesign-analytics-spheres` — **Spheres web**: radar (log scale) + 12-month area trend +
   sortable table, replacing today's bars, over `/api/analytics/spheres` + `/api/events`. **Brings in
   recharts + the month/quarter/year period selector.** (first — establishes the scaffold.)
2. `focal-redesign-analytics-deep-work` — Deep-work metrics + recommendations over `/api/events`.
3. `focal-redesign-analytics-products` — Product analytics (stacked bar + line + table) over
   `/api/projects` products + `/api/events`.
4. `focal-redesign-analytics-projects` — Project productivity over project `is_work_time` +
   `allocated_work_hours` + events.
5. `focal-redesign-analytics-mission` — Mission-vs-Provision over project `project_type` + events +
   budgets.
6. `focal-redesign-analytics-energy` — Energy balance, classifying events client-side via the
   project/sphere `gives_energy` maps (old-focal's approach).

**Deferred (surfaced, not faked):** old-focal's **PDF export** (html2canvas + jsPDF multi-page) — a
separate later sub-slice once the sections exist.

# Out of scope

- **Any server / API / schema change** — every section is backed; this epic is frontend-only. (If a
  section's design gate surfaces a genuinely missing field, that becomes a separate flagged handoff —
  but none is expected.)
- **PDF export** (a later sub-slice); other feature pages; re-deriving the shell foundation (slice 0).
- Building all 6 sections in one slice — explicitly an epic of independently-shippable sub-slices.

# Open questions

- **Start sub-slice:** recommend `…-spheres` (backed, the page's current subject, brings the shared
  scaffold). Confirm before its gate 1.
- **12-month trends:** client-side over `/api/events` first (assumed), or a backend aggregate if the
  per-event volume proves heavy — settled at the spheres sub-slice's design gate.
- **`project_type` enum:** confirm the backend's mission/provision values vs old-focal's mapping at
  the mission sub-slice's design gate.

# Success criteria

- [ ] Analytics framed as an ordered set of 6 section sub-slices, each a frontend-only 7-gate feature
      tracing here; the **all-backed** classification is explicit and contract-grounded (named fields +
      schema lines).
- [ ] Each sub-slice at ship: `pnpm lint && typecheck && test:run && build` green in the worktree;
      surgical diff; **no** server/API change; i18next ru+en; light+dark.
- [ ] On epic completion, all six sections match old-focal by screenshot (light+dark) over the real
      APIs; PDF export deferred to its own sub-slice; nothing faked.

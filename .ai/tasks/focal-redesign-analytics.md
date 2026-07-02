# Goal

Bring the Focal **Analytics** page (`apps/focal/client/src/features/analytics`) to **exact visual +
functional parity with old-focal** (`apps/old-focal/client/src/pages/Analytics.tsx`), composing the
merged shell foundation (slice 0) and the new app's real APIs. Because old-focal's analytics is a
**3,886-line, 6-section** surface and today's `AnalyticsPage.tsx` is a **single 219-line spheres
bar-view**, this is an **epic delivered as an ordered set of section sub-slices**, each run through
the full 7-gate pipeline — **not** one re-skin. **All six sections are backed by the existing APIs**,
so the epic is **frontend-only** end-to-end (no backend handoff).

> **EPIC kickoff** — frames the whole analytics-parity effort + the section breakdown. Each sub-slice
> (`focal-redesign-analytics-<section>`) gets its own task/think/plan/design/build/test/ship; the epic
> think doc is the parent roadmap. Worktree: `.worktrees/focal-redesign-analytics`, branch
> `feat/focal-redesign-analytics` (off the shell slice `afaaeba`, so it inherits the new foundation).

> **Binding visual contract** = `apps/old-focal/client/src/pages/Analytics.tsx` (6 sections, recharts).
> **Behavioral/data base** = the new app's existing typed `api/*` + the FastAPI backend.

# Scope — the 6 old-focal sections, mapped to sub-slices (all backed, frontend-only)

| # | Section (RU) | Charts | Backing data (exists today) | Sub-slice |
|---|---|---|---|---|
| 2 | Паутинка сфер жизни (Spheres web) | Radar + 12-mo area + table | `/api/analytics/spheres` + `/api/events` | `…-spheres` (first) |
| 6 | Глубокая работа (Deep work) | metrics + recs | `/api/events` (current month, >2h blocks) | `…-deep-work` |
| 7 | Аналитика по продуктам (Products) | stacked bar + line + table | `/api/projects` products + `/api/events` | `…-products` |
| 3 | Продуктивность по проектам (Projects) | stacked bar + line + table | project `is_work_time` + `allocated_work_hours` + events | `…-projects` |
| 1 | Миссия vs Остальное (Mission/Provision) | stacked bar + area | project `project_type` + events + budgets | `…-mission` |
| 5 | Энергетический баланс (Energy) | stacked bar + area + top-3 | project/sphere `gives_energy` mapped onto events (client-side, как в old-focal) | `…-energy` |

Confirmed-present fields (gate-1 correction): `ProjectRead.project_type`/`is_work_time`/`gives_energy`
(`schemas/projects.py:82,84,95`), `SphereRead.gives_energy` (`schemas/spheres.py:60`),
`EnrichedEventRead.project_type`/`sphere`/`project_id` (`schemas/calendar.py:256,257,237`).

Cross-cutting (built in the first sub-slice, shared by all sections): the period selector
(month/quarter/year + prev/next), the `PageHeader`, and recharts wiring (recharts is the stack's
sanctioned chart lib, added on first use).

# Out of scope

- **Any server / API / schema change** — every section is backed; this epic is frontend-only over the
  existing contract. (If a section's design gate surfaces a genuinely missing field, it becomes a
  separate flagged handoff — none expected.)
- **PDF export** (old-focal's html2canvas+jsPDF multi-page export) — a separate later sub-slice; not
  in the section MVPs.
- Other feature pages (their own slices); re-deriving the shell foundation (slice 0).
- Building all 6 sections in one slice — explicitly an epic of independently-shippable sub-slices.

# Acceptance criteria (epic)

- [ ] Each sub-slice ships green: `cd /Users/allosta/Desktop/allosta/.worktrees/focal-redesign-analytics
      && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`, with its own tests.
- [ ] On epic completion, the analytics page matches old-focal's six sections in light + dark, by
      screenshot, over the **existing** APIs; PDF export deferred to its own sub-slice; nothing faked.
- [ ] Behavior on real data; **no** server/API change inside a sub-slice; i18next ru + en; surgical
      per-sub-slice diffs.

# Verification commands

```sh
cd /Users/allosta/Desktop/allosta/.worktrees/focal-redesign-analytics
pnpm install --frozen-lockfile
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```

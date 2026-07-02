# Review Verdict

Reviewer: Opus
Step: plan
Score: 9.3 / 10
Status: APPROVED

## Reason
The plan's load-bearing decision is verified correct against source: the new `/api/analytics/spheres` service genuinely diverges from old-focal (plan from `TimeBudgetSettings` not events at `services/analytics.py:64,89`; fact loop ungated by `completed` at `:70-76`), so computing the section client-side from `/api/events`+`/api/projects`+`/api/spheres` is the only path to parity. Every field, formula, threshold, and dependency the plan relies on exists exactly as claimed, the slices are small and independently reviewable, failure modes are concretely named, and the frontend-only invariant holds. One minor parity deviation (null-`endTime` handling) is documented rather than silent.

## Must Fix
None.

## Should Consider
- **null-`endTime` parity deviation.** old-focal's `calculateDuration` returns **1 hour** for a null `endTime` (`old-focal/Analytics.tsx:153`), counted into plan/fact in both the Spheres compute (`:628`) and the trend (`:834`). The plan instead **skips** null durations. Real numeric divergence for start-only events. Defensible (the new backend skips null `end_time` at `analytics.py:72`), but the doer should choose deliberately — mirror old-focal's `?? 1` for exact parity, or keep the skip and note it.
- **Trend uses a full-year events pull; old-focal iterates the period-scoped array.** The plan's `listEvents(year)` makes all 12 months populate (a more useful trend, documented) — but screenshots differ from old-focal for a single-month period. Match or consciously diverge at design.
- Keep `PeriodSelector`/`analyticsPeriods` minimal (only month/quarter/year + the five listed functions); resist unused period types.

## Tests Reviewed
N/A (plan step). Reviewed the proposed test list against old-focal semantics: it correctly pins attribution, completed-gating, budget-from-annual-allocated, round/percent/deficit, log-scale radar with raw tooltips, the 12-month trend, the none→desc→asc sort cycle, and that `AnalyticsPage` has no `getSpheresAnalytics` dependency.

## Release Risk
Low — frontend-only, no server/API/schema/migration/dependency change (recharts already installed), reversible by reverting the analytics-feature files.

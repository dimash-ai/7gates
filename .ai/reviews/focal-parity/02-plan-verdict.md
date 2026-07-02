# Review Verdict

Reviewer: Opus
Step: plan
Score: 9.3 / 10
Status: APPROVED

## Reason
Every load-bearing claim verifies against source (no `CalendarFilterContext`/timezone provider in the new client but `sharedCalendars.ts` + backend timezone port exist; task recurrence/multi-participant and event custom-recurrence genuinely absent from new schemas; the goals product-less-activity regression and missing meeting-accept `['events']` invalidation are real). The plan is minimum-viable-by-design (foundations-first to avoid per-page duplication), reuses existing code, names per-slice failure modes with catch sites, and ties each test to a proven behavior.

## Must Fix
None

## Should Consider
- Slices 1/2 (shared-calendar context + read-only gating across 7 pages) and slice 6 (calendar interaction) remain large; the plan defers their boundaries to per-slice plan gates. Acceptable for an epic plan, but the per-slice gate2 must hold the line so a single build PR stays reviewable and surgical.
- The epic-wide "Files to change" matrix is a superset; enforce "only this slice's rows" at each build gate to prevent Surgical-Changes drift across the broad path list (e.g. the `features/{events,tasks,goals,...}.ts` glob row).
- Doc-consistency nit (think doc, not the plan): habit `note` lives on `HabitEntry` (per-day), not the `Habit` model. The plan's wording ("per-day notes") is already correct; worth aligning the think doc so a later slice doesn't look for a habit-level note column.

## Tests Reviewed
N/A (plan step — no tests run). Verified the plan's required commands exist: `focal/client/package.json` defines `lint`/`typecheck`/`test:run`/`build`; `focal/server/Makefile` defines `verify`; existing `focal/server/tests/test_timezone.py` covers the DST cases the plan's timezone tests reference.

## Release Risk
Medium

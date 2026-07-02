# Review Verdict

Reviewer: Opus
Step: plan
Score: 9.2 / 10
Status: APPROVED

## Reason
Minimum-viable, surgical plan that genuinely reuses the existing event machinery rather than rebuilding it — every reuse claim checks out against the real code (`api/events.ts`, `EventPopover`, `RecurringScopeDialog`, the option-list wrappers, the `['events']` query key/invalidation, and the `occurrenceDate ?? date` recurrence target that mirrors the tested `CalendarPage.tsx:302`). The two genuinely-missing primitives (`ui/multi-select`, `datePresetRange`) are confirmed absent; failure modes name the error, where it's caught, and what the user sees; each test states what it proves; the think doc's `CalendarFilterContext` deferral and the gate-1 `all`-preset Should-Consider are both addressed with an old-focal-exact bounded rest range (`2020-01-01` → year+2). Only minor, non-blocking polish remains.

## Must Fix
None

## Should Consider
- Preset enumeration is under-specified in the slices/tests: slice 2 (`.ai/plans/focal-redesign-events-plan.md:37-39`) and the test list (`:82`) name day/week/month/quarter/nextQuarter/year but omit `lastWeek`, `nextWeek`, `lastMonth`, `nextMonth`, which old-focal's `DatePresetForRange` includes (`superapp/apps/old-focal/shared/datePresetRange.ts`). The "port old-focal behavior" directive (`:37`) governs and keeps the implementation correct, but the explicit slice/test wording should cover all 14 presets so a literal reading doesn't ship a partial preset list.
- The plan adds a separate `events` nav item (`.ai/plans/focal-redesign-events-plan.md:20,22`) but doesn't note that the current `tasks` nav label reads "Tasks & events" (`apps/focal/client/src/i18n/locales/en.json:89`, reflecting the existing read-only events tab in `features/tasks/TasksPage.tsx:341,573`). Once a dedicated Events item exists, that combined label is misleading; decide whether to retune it to "Tasks" or consciously leave it (touching it is arguably outside the surgical surface).
- Slice 5 (`:59`) hedges products as "derive from `parentProjectId`… or `listProducts(projectId)` if implementation proves otherwise." `api/projects.ts` already documents the full list as "products included," and `api/products.ts` exists as the fallback — so this is safe, but the design step should pick one path to avoid a fetch-then-discover detour during build.

## Tests Reviewed
N/A (plan step). Verified the plan's factual claims against source: `api/events.ts`, `features/calendar/EventPopover.tsx`, `features/calendar/RecurringScopeDialog.tsx`, `features/calendar/CalendarPage.tsx:135-183,196,294-305`, `api/{projects,products,spheres,activities,tags}.ts`, `api/openapi.d.ts:3020-3109` (EnrichedEventRead incl. `isOrphan`/`orphanReason`/`occurrenceDate`), `App.tsx`, `components/AppSidebar.tsx:60-105`, `features/tasks/TasksPage.tsx`, `i18n/locales/en.json`, old-focal `pages/Events.tsx` + `shared/datePresetRange.ts` + `lib/calendarRanges.ts`.

## Release Risk
Low

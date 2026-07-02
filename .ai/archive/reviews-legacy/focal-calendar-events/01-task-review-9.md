# Codex Review Verdict

Score: 8.8 / 10
Status: BLOCKED

## Reason
The task is tightly scoped and the round-8 gaps are addressed, but one priority-resolution instruction is ambiguous against the target code. As written, Claude could either fail the activity-only event priority contract or change task behavior outside this slice.

## Must Fix
- `.ai/tasks/focal-calendar-events.md:113`-`.ai/tasks/focal-calendar-events.md:122` requires event priority to resolve project/product through `activityId`, but also says to reuse task priority resolution; `.ai/tasks/focal-calendar-events.md:227`-`.ai/tasks/focal-calendar-events.md:228` says not to change task behavior. Current task priority has activity fallback deferred (`superapp/apps/focal/server/app/services/tasks.py:193`-`229`), so clarify the intended path: add an event-specific/shared resolver with activity fallback, or explicitly allow shared extraction with tests proving existing task behavior is unchanged.

## Should Consider
- `.ai/tasks/focal-calendar-events.md:171`-`.ai/tasks/focal-calendar-events.md:177` says PATCH revalidates times, but only create clearly states zero-padding on store. Add an explicit PATCH single-digit-hour normalization assertion if patched times must preserve chronological list ordering.

## Tests Reviewed
Read `.ai/tasks/focal-calendar-events.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`; inspected legacy calendar event code and current FastAPI task priority context for contract context. No tests were run.

## Release Risk
Medium

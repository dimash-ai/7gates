# Codex Review Verdict

Score: 8.4 / 10
Status: BLOCKED

## Reason
The task file is strong overall and round-3 acceptance gaps are addressed, but it still bakes in one undocumented behavior change against its own “legacy source is binding” claim. That ambiguity would cause contract tests to enforce a non-legacy enriched shape.

## Must Fix
- `.ai/tasks/focal-calendar-events.md:105` says hierarchy resolution feeds both priority and enrichment, and `.ai/tasks/focal-calendar-events.md:210` / `.ai/tasks/focal-calendar-events.md:262` require an activity-only event to derive enriched `project`/`product` from the activity. But `.ai/tasks/focal-calendar-events.md:171` pins legacy `buildEnrichedEventsFromRows`, and `.ai/tasks/focal-calendar-events.md:186` says there are only two intentional enriched-shape deviations. The cited legacy enrichment resolves project/product from stored `projectId`/`productId`, not from `activityId`; activity fallback applies to priority context, not enriched read shape. Either align the spec to legacy, or explicitly document this as a third intentional deviation with rationale and acceptance coverage.

## Should Consider
- `.ai/tasks/focal-calendar-events.md:130` requires strict `HH:MM`; legacy route validation accepts single-digit hours such as `9:05`. If strict two-digit time is intended for the FastAPI port, call it out as an intentional hardening/deviation and test it.
- `.ai/tasks/focal-calendar-events.md:133` says `tags`/`contactIds` are “stored as-is, no validation,” but tests only pin null/default behavior. Clarify and test what happens for non-array or non-string values under Pydantic.

## Tests Reviewed
Read `.ai/tasks/focal-calendar-events.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, and legacy context in `focal/server/storage.ts`, `focal/server/routes.ts`, `focal/shared/schema.ts`, `focal/server/utils/userDateTime.ts`. No test suite was run.

## Release Risk
Medium

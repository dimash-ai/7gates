# Codex Review Verdict

Score: 8.1 / 10
Status: BLOCKED

## Reason
The task is broadly well-scoped, but the response contract is not pinned cleanly enough to be safe to implement. It mixes legacy-event fields with task-style names and misses a legacy completion edge case that acceptance tests would not catch.

## Must Fix
- `.ai/tasks/focal-calendar-events.md:24-27` and `.ai/tasks/focal-calendar-events.md:147-159` claim the enriched response preserves the legacy shape, but specify `projectName`, `displayColor`, and `completedAt`; legacy `EnrichedCalendarEvent` returns `project`/`product`/`projectColor` and `buildEnrichedEventsFromRows` does not emit `completedAt` (`focal/server/storage.ts:212-266`, `focal/server/storage.ts:3378-3413`). Pin the exact intended API shape or explicitly mark intentional contract changes.
- `.ai/tasks/focal-calendar-events.md:119-128` allows `completed` on create, but the task/tests never require create-time `completedAt` behavior. Legacy sets `completedAt` when an event is created already completed (`focal/server/storage.ts:748-756`, `focal/server/storage.ts:3834-3855`), so add that requirement and test or explicitly defer/change it.
- `.ai/tasks/focal-calendar-events.md:130-139` omits PATCH `timezone` sanitization, while legacy sanitizes `updates.timezone` before storage (`focal/server/routes.ts:2912-2914`). Add the update behavior and verification, or state that PATCH timezone is intentionally different.

## Should Consider
- `.ai/tasks/focal-calendar-events.md:208` lists `POST` under `/api/events/:id`; earlier scope correctly says `POST /api/events`, so fix the acceptance-criteria typo.
- Clarify whether event priority is recomputed only when links change or on every PATCH. The task says link changes only (`.ai/tasks/focal-calendar-events.md:99-101`), while legacy recomputes from merged state on update (`focal/server/storage.ts:3935-3953`).

## Tests Reviewed
Not run; task-definition review only. Inspected `.ai/tasks/focal-calendar-events.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, and legacy sources `focal/server/routes.ts`, `focal/server/storage.ts`, `focal/shared/schema.ts`.

## Release Risk
Medium

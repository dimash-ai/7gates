# Codex Review Verdict

Score: 8.6 / 10
Status: BLOCKED

## Reason
The task is mostly faithful to the existing model, baseline migration, legacy strict-containment behavior, and superapp tenant-hardening patterns. It needs one Gate 1 fix because the scoped CRUD includes PATCH, but the acceptance criteria do not define or test the update semantics.

## Must Fix
- `.ai/tasks/focal-bookings.md:18` scopes `PATCH /api/bookings/{id}` as a partial update, but the acceptance criteria only cover tenant behavior and read/init contract tests. Add acceptance/tests for PATCH applying allowed mutable fields, returning `BookingRead`, clearing nullable fields intentionally, and preventing client writes to tenant/server-managed fields. Legacy PATCH did not accept `source_type`/`source_id` (`routes.ts:3506`).

## Should Consider
- Explicitly call out router registration in `app/main.py` as part of "router wiring."
- Add an explicit test case for strict containment excluding overlapping-but-not-contained bookings.

## Tests Reviewed
No tests run; Gate 1 task review only. Inspected `.ai/tasks/focal-bookings.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, the existing Booking model/baseline migration, legacy booking routes/storage/schema, and calendar-init/events/tasks patterns.

## Release Risk
Medium

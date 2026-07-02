# Codex Review Verdict

Score: 7.8 / 10
Status: BLOCKED

## Reason
The plan is mostly aligned with the task and legacy behavior, but it misses a required model-registration file that the actual Alembic setup depends on. There is also a concrete test-planning gap for the explicit `userId` spoofing acceptance criterion.

## Must Fix
- `.ai/plans/focal-calendar-events-plan.md:94-107` omits `superapp/apps/focal/server/app/models/__init__.py`. Alembic imports metadata through `from app.models import Base` in `superapp/apps/focal/server/alembic/env.py:11`, and `app/models/__init__.py:1-18` imports the known model modules but no calendar module. Without adding `CalendarEvent` there, autogenerate can miss `focal.calendar_events`, making the migration/check path unreliable.
- `.ai/tasks/focal-calendar-events.md:339-340` requires testing that body/query `userId` is ignored and unknown body fields are ignored, but the plan’s test list at `.ai/plans/focal-calendar-events-plan.md:157-164` only covers tenant isolation by second-user access and does not name a spoofed `userId`/unknown-field test.

## Should Consider
- `.ai/plans/focal-calendar-events-plan.md:72` says “Plain columns, no DB FK (matches `tasks`)”, but `superapp/apps/focal/server/app/models/tasks.py:31-39` actually uses `ForeignKey(..., ondelete="SET NULL")` for project/product/activity links. The no-FK event choice is documented by the task, but the rationale should not claim it matches the current task model.
- `.ai/plans/focal-calendar-events-plan.md:87-88` says DELETE 204 is consistent with task deletes, but `superapp/apps/focal/server/app/api/tasks.py:64-71` returns `{"success": True}` with the default 200. Keep 204 if desired per task, but fix the inaccurate rationale.

## Tests Reviewed
Read `.ai/tasks/focal-calendar-events.md`, `.ai/plans/focal-calendar-events-plan.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, target FastAPI files under `superapp/apps/focal/server`, and legacy event sources in `focal/server/routes.ts`, `focal/server/storage.ts`, `focal/shared/schema.ts`, `focal/server/utils/userDateTime.ts`. No tests were run; this was a plan review.

## Release Risk
Medium

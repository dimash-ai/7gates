# Codex Review Verdict

Score: 7.8 / 10
Status: BLOCKED

## Reason
The slice is broadly on-plan and the provided verification capture is strong, but there is a concrete tenant-isolation/enrichment bug for stale or non-owned links, plus the committed table nullability does not match the task’s required model contract. The first issue can expose another tenant’s project/product id and render the event as non-orphaned.

## Must Fix
- `superapp/apps/focal/server/app/services/calendar.py:215` / `superapp/apps/focal/server/app/services/calendar.py:216` keep raw stored `project_id`/`product_id` even when those ids do not resolve to owned projects, and `superapp/apps/focal/server/app/services/calendar.py:236` only checks whether the raw id is truthy. A user-owned event with a stale/non-owned `project_id` or `product_id` can return that foreign id via `superapp/apps/focal/server/app/services/calendar.py:245` and report `isOrphan=false`, contrary to the tenant-isolated enrichment requirement.
- `superapp/apps/focal/server/app/models/calendar.py:31` through `superapp/apps/focal/server/app/models/calendar.py:40` and the generated migration at `superapp/apps/focal/server/alembic/versions/2026_06_04_1032-896e5577aa06_calendar_events.py:37` through `superapp/apps/focal/server/alembic/versions/2026_06_04_1032-896e5577aa06_calendar_events.py:44` make `priority`, `priority_score`, `priority_level`, `status`, `completed`, `tags`, and `contact_ids` nullable. The task specifies these as NOT NULL with ORM-side defaults, so the schema currently permits invalid event rows and `alembic check` will not catch it because the ORM matches the wrong nullability.

## Should Consider
- Strengthen `test_enrichment_does_not_leak_other_tenant_project` to assert `projectId is None`, `isOrphan is True`, and `orphanReason == "noProject"`; add the equivalent stale/non-owned `productId` case.
- Add explicit owned-link coverage for `productId` and `activityId` on create/patch, not just `projectId`.

## Tests Reviewed
Inspected `git -C superapp --no-pager diff --cached`, `git -C superapp status`, `.ai/plans/focal-calendar-events-plan.md`, `.ai/tasks/focal-calendar-events.md`, legacy `focal/server/routes.ts`, `focal/server/storage.ts`, `focal/shared/schema.ts`, and `.ai/runs/focal-calendar-events-verify.txt`. Verification capture shows `make verify` green: ruff, format, mypy, pytest 317 passed, plus `alembic upgrade head` and `alembic check` clean.

## Release Risk
Medium

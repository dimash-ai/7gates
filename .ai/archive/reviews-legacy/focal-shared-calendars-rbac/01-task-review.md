# Codex Review Verdict

Score: 8.6 / 10
Status: BLOCKED

## Reason
The task is well-scoped to rbac + models + migration, and it correctly preserves the 6 stored roles while using rank comparison for the legacy read/write/owner gates. The main blocker is a schema-faithfulness ambiguity: the task says UUID primary keys, but the legacy schema and shipped Focal SQLAlchemy tables use string/varchar IDs.

## Must Fix
- `.ai/tasks/focal-shared-calendars-rbac.md:31` and `:35` specify `id uuid PK` for both new tables, but the legacy tables use `varchar("id")` (`focal/shared/schema.ts:1451`/`:1511`), and existing Focal models/migrations use `String` IDs (`app/models/calendar.py:20`, `app/models/bookings.py:15`). Clarify to require string/varchar UUID-shaped IDs, or document an intentional type change.

## Should Consider
- Add an explicit acceptance criterion that corrupt/unknown stored roles deny with `PermissionDeniedError` rather than producing an untyped `KeyError`, since the legacy role column is plain varchar.
- Add boundary tests for `require_role("viewer")`, `require_role("editor")`, and `require_role("owner")` across all six roles to lock the grouped read-only rank behavior.

## Tests Reviewed
Not run; Gate 1 task review only. Inspected the task, rubric, `RBAC_CONTRACT.md`, `focal/shared/schema.ts`, `focal/server/storage.ts`, `focal/server/auth.ts`, `app/errors.py`, `app/models/__init__.py`, existing Focal models, and existing Alembic migrations.

## Release Risk
Medium

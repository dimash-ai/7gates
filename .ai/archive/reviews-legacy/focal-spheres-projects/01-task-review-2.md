# Codex Review Verdict

Score: 7.8 / 10
Status: BLOCKED

## Reason
The task is detailed and mostly scoped, but key update and error-contract behavior is still ambiguous enough to produce a wrong implementation while still passing the listed acceptance criteria. The main gaps are parent-project ownership on update, work-time update semantics, and exact duplicate/fuzzy error shape.

## Must Fix
- `.ai/tasks/focal-spheres-projects.md:54-55` and `.ai/tasks/focal-spheres-projects.md:101-102`: `parent_project_id` ownership is specified only for create, but project CRUD includes update at `.ai/tasks/focal-spheres-projects.md:45-47`. Define and test update behavior for changing/clearing `parent_project_id`, including same-tenant validation, no existence leak, and self/descendant parent cases if legacy handles them.
- `.ai/tasks/focal-spheres-projects.md:50-53` requires matching legacy create/update work-time handlers, but `.ai/tasks/focal-spheres-projects.md:98-100` only accepts/tests create behavior. Define and test update behavior for `is_work_time` transitions and submitted `sphere` values.
- `.ai/tasks/focal-spheres-projects.md:35-37` and `.ai/tasks/focal-spheres-projects.md:92-93`: sphere update duplicate/fuzzy validation does not state whether the current sphere is excluded, so unchanged-name updates or renames can be implemented incorrectly. Add explicit acceptance coverage for update self-exclusion and rename behavior.
- `.ai/tasks/focal-spheres-projects.md:35-37`, `.ai/tasks/focal-spheres-projects.md:92-93`, and `.ai/tasks/focal-spheres-projects.md:103-104`: the duplicate/fuzzy error contract is underspecified/conflicting between legacy `{error, similarNames}` and typed `AppError` `{error:{code,message}}`. Specify exact status code, error code, and where `similarNames` lives.

## Should Consider
- `.ai/tasks/focal-spheres-projects.md:94-95`: explicitly require the destructive sphere delete-cascade test to prove another tenant's same-named sphere/projects are untouched.
- `.ai/tasks/focal-spheres-projects.md:117-119`: the verification command creates an Alembic revision while the task says no migration file is committed. Add cleanup guidance so the verification step does not leave accidental generated files.

## Tests Reviewed
Inspected `.ai/tasks/focal-spheres-projects.md`, `.ai/checklists/scoring-rubric.md`, and `CLAUDE.md`. No implementation tests were run because this review was limited to the task definition.

## Release Risk
Medium

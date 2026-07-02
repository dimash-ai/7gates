# Codex Review Verdict

Score: 8.7 / 10
Status: BLOCKED

## Reason
The task is detailed and mostly measurable, with clear endpoint scope, tenant model, validation expectations, and tests. It is blocked by one direct contradiction in the expected opaque-id behavior, which could lead Claude to implement or test the wrong contract.

## Must Fix
- `.ai/tasks/focal-mindmap-graph.md:135` says an unknown/malformed `:id` on node/edge `GET`/`PUT`/`DELETE` yields typed `not_found` (404), but `.ai/tasks/focal-mindmap-graph.md:45-46`, `.ai/tasks/focal-mindmap-graph.md:116-118`, and `.ai/tasks/focal-mindmap-graph.md:176-177` say `PUT` to a new id upserts and never 404s. Resolve this contradiction in the Tests section.

## Should Consider
- `.ai/tasks/focal-mindmap-graph.md:73-77`, `.ai/tasks/focal-mindmap-graph.md:81`, and `.ai/tasks/focal-mindmap-graph.md:95` do not specify list/init ordering. If legacy order matters, pin it; if not, state that order is intentionally unspecified.
- `.ai/tasks/focal-mindmap-graph.md:60-65` hard-codes PK constraint names for the migration. Consider requiring verification of the existing foundation constraint names before using those exact `drop_constraint` calls.
- `.ai/tasks/focal-mindmap-graph.md:166-167` caps `fullDescription` and edge endpoint ids, but the task does not state whether overlong node/edge path ids are valid, `validation_error`, or impossible due to schema. Clarifying that would reduce raw-DB-error risk.

## Tests Reviewed
Inspected `.ai/tasks/focal-mindmap-graph.md`, `.ai/checklists/scoring-rubric.md`, and root `CLAUDE.md`. No implementation tests were run because this review was limited to the task definition.

## Release Risk
Medium

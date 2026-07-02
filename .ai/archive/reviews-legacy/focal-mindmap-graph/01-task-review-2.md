# Codex Review Verdict

Score: 8.1 / 10
Status: BLOCKED

## Reason
The task is well scoped overall, with strong test coverage expectations, but two acceptance criteria are internally contradictory. As written, Claude cannot implement and verify the PUT/upsert behavior without choosing between mutually exclusive requirements.

## Must Fix
- `.ai/tasks/focal-mindmap-graph.md:81`, `.ai/tasks/focal-mindmap-graph.md:94`, and `.ai/tasks/focal-mindmap-graph.md:156` define node/edge `PUT` as upsert/create behavior, but `.ai/tasks/focal-mindmap-graph.md:166` requires an unknown `:id` on any `GET`/`PUT`/`DELETE` to return `not_found`. A new `PUT /:id` cannot both create and return 404 for an unknown id.
- `.ai/tasks/focal-mindmap-graph.md:118`, `.ai/tasks/focal-mindmap-graph.md:147`, and `.ai/tasks/focal-mindmap-graph.md:162` conflict on cross-tenant upsert behavior. The task says two users can create the same id under composite PK, but also says a second user cannot upsert the first user's node/edge and should get `not_found`; because ids are shared strings, this needs to explicitly say whether user2's `PUT` same id creates/updates only user2's row.

## Should Consider
- Clarify batch duplicate return semantics at `.ai/tasks/focal-mindmap-graph.md:102` and `.ai/tasks/focal-mindmap-graph.md:160`: with duplicate ids, should the response contain one row per input item, collapsed unique rows, or repeated final-state rows in input order?
- Define handling for path/body id mismatches and over-length ids/string fields. The task requires opaque string ids and `varchar(100)` storage at `.ai/tasks/focal-mindmap-graph.md:55`, but does not specify whether invalid lengths are `validation_error`, `not_found`, or another typed error.

## Tests Reviewed
Inspected `.ai/tasks/focal-mindmap-graph.md`, `.ai/checklists/scoring-rubric.md`, and `CLAUDE.md` with `sed`/`nl`; no implementation tests run because this review was limited to the task definition.

## Release Risk
Medium

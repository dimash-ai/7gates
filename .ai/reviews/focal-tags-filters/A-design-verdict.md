# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 7.8 / 10
Status: BLOCKED

## Reason
The design is well-scoped overall and mostly reuses the existing Events/Tasks filter architecture, but it leaves key contracts ambiguous for usage counts, created-date filtering, and API field naming. Those gaps can produce incorrect counts or an implementation that does not typecheck cleanly against generated OpenAPI types.

## Must Fix
- `.ai/design/focal-tags-filters-design.md:42-52` requires legacy name references to count toward per-tag `usageCount`, but duplicate tag names are explicitly allowed (`superapp-tags-filters/apps/focal/server/tests/test_tags_db.py:265-272`). The design must define how ambiguous legacy name references are attributed before this can be considered correct.
- `.ai/design/focal-tags-filters-design.md:92-97` defines `filterTags(tags, filters)` with no `todayYmd` or timezone/display-date input, while slice 3 requires date presets and calls timezone handling a failure mode at `.ai/design/focal-tags-filters-design.md:80`. The date filter contract must specify the reference date/timezone source and pass it through testably.
- `.ai/design/focal-tags-filters-design.md:104` specifies backend `TagRead` fields as `usage_count` / `created_at`, while the client-facing success criteria and flow use `usageCount` / `createdAt` at `.ai/design/focal-tags-filters-design.md:66-70` and `.ai/design/focal-tags-filters-design.md:116`. The design must make the wire/OpenAPI naming contract explicit, either by adding the repo’s camelCase alias convention to `TagRead` or by having the frontend consume snake_case fields.

## Should Consider
- `.ai/design/focal-tags-filters-design.md:104` says `created_at: datetime`, but `.ai/design/focal-tags-filters-design.md:121` designs for absent/null dates. Align the schema optionality with the intended client fallback behavior.

## Tests Reviewed
N/A

## Release Risk
Medium

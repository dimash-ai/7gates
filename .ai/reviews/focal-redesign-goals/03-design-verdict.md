# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 8.1 / 10
Status: BLOCKED

## Reason
The design is broadly scoped correctly and most node metadata/API assumptions are verified, but two requested parity specs are not sound enough for build. The wash CSS would not resolve against the current token shape, and the edge section asserts parity where old-focal source shows different product/activity edge rules.

## Must Fix
- `.ai/design/focal-redesign-goals-design.md:46-51` specifies `color-mix(... var(--card))`, but `--card` is an HSL triplet in `index.css:162` and `:243`, so this is not a valid CSS color; it also claims old-focal mixes over card while old source uses `white`/hard-coded branch backgrounds at `PyramidNode.tsx:337-343`. Fix the wash spec to use valid color syntax and explicitly match or document the old-focal light/default behavior.
- `.ai/design/focal-redesign-goals-design.md:101-103` says edge styles can stay unchanged because they already match old-focal, but old-focal product edges use `strokeWidth: 1.5` and `strokeDasharray: '5,5'` at `MindMap.tsx:1423-1427`, and activity edges are dashed `2, 4` at `:1474-1478`; the current target graph only specifies product `strokeWidth: 2`/`'5 5'` and no activity dash at `graph.ts:123-131`. Update the edge parity spec/tests or mark any deviation as intentional.

## Should Consider
- Verify mobile header parity: old-focal mobile header omits the subtitle at `Goals.tsx:37-50`, while the design asks `PageHeader.subtitle` to render on desktop and mobile at design:107-110.
- Separate the graph test wording for project-only `isWorkTime`/`sphere` and activity-only dates; design:146-147 currently reads as if every project/activity node has all those fields.

## Tests Reviewed
N/A

## Release Risk
Medium

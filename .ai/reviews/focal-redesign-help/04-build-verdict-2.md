# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.4 / 10
Status: BLOCKED

## Reason
The two previously cited Must Fix items are resolved: the header now has desktop/mobile structures, and dimensions/levels/data tips use dedicated old-focal-shaped helpers. However, the build still misses required old-focal helper surfaces from the approved design/binding contract, so exact visual parity is not yet met.

## Must Fix
- `apps/focal/client/src/features/help/HelpPage.tsx:534` still renders the calendar filter types as generic `Panel` cards instead of the old-focal `FilterTypeItem` row shape required by the design and shown in old-focal `Help.tsx:686`.
- `apps/focal/client/src/features/help/HelpPage.tsx:52` / `:736` still render planning/habit steps through the simplified `Step` list item, not the old-focal `StepItem` hover row with icon and description shape (old-focal `Help.tsx:1515`).

## Should Consider
- `apps/focal/client/src/features/help/HelpPage.test.tsx:103` asserts the clicked panel content is in the document; `toBeVisible()` would make the test's "visible panel content" intent explicit.

## Tests Reviewed
`git diff`, `git status`, `git diff --check`, task/plan/design docs, previous build verdict, current `HelpPage.tsx`/`HelpPage.test.tsx`, old-focal `Help.tsx`. Did not rerun the local suite; prompt reports biome, tsc, vitest, vite build passing.

## Release Risk
Medium

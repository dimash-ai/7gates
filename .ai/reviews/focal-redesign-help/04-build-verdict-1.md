# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.2 / 10
Status: BLOCKED

## Reason
The tabbed shell, locale keys, AI-agents deferral, and `?tab=` seeding are largely in place. However, the build still misses key parts of the binding old-focal visual contract, especially the responsive header rhythm and per-section helper treatments.

## Must Fix
- `apps/focal/client/src/features/help/HelpPage.tsx:215` renders one header row at all breakpoints, while the design and old-focal contract require a desktop one-row header and a mobile two-row header with the subtitle separated below the title row. The current subtitle at `:223` is truncated inside the same row on mobile.
- `apps/focal/client/src/features/help/HelpPage.tsx:67` keeps the generic `Panel` helper and uses it for required old-focal helper surfaces such as dimensions (`:309`), levels (`:368`), and tips (`:1249`). These do not implement the planned old-focal `DimensionCard`/`LevelCard`/`TipItem` visual shapes from the binding contract.

## Should Consider
- `apps/focal/client/src/features/help/HelpPage.test.tsx:91` only asserts the clicked tab becomes selected; add a visible-content assertion so the test proves panel switching, not just trigger state.

## Tests Reviewed
`git diff`, `git status`, task/plan/design, old-focal `Help.tsx`; ran `git diff --check`, `tsc --noEmit`, and `biome check` on the two help files. `pnpm test:run` was blocked by the read-only sandbox (EPERM temp writes).

## Release Risk
Medium

# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.3 / 10
Status: BLOCKED

## Reason
The header, `?tab=` seeding, tab tests, AI-agents deferral, TOC removal, and `FilterTypeItem` fix are in place. However, the implementation still does not meet the approved old-focal helper fidelity contract for several named helpers, including the previously cited `StepItem`.

## Must Fix
- `HelpPage.tsx:52` defines the restyled `Step` without the icon slot required by the design (`:93`) and old-focal `Help.tsx:1515`; planning/habit usages (`:734`, `:1333`) render number + text only, not old-focal's number + icon/title + description shape.
- `HelpPage.tsx:129` keeps `RoleItem` on the generic `Panel` with no colored icon and a `<code>` badge, while the design requires old-focal's colored-icon row with an outline `Badge` (`:90`, old-focal `Help.tsx:698`).
- `HelpPage.tsx:164` keeps `DataSourceItem` on the generic `Panel` with no primary icon, while the design requires old-focal's primary-icon data-source row (`:94`, old-focal `Help.tsx:1537`).

## Should Consider
- `HelpPage.tsx:102` keeps `GlossaryItem` on `Panel`, lacking old-focal's `hover:shadow-sm` surface.

## Tests Reviewed
`git diff`, `git status`, task/plan/design docs, previous build verdicts, current `HelpPage.tsx`/`HelpPage.test.tsx`, old-focal `Help.tsx`. Did not rerun the local suite; prompt reports biome, tsc, full vitest, vite build passing.

## Release Risk
Medium

## Doer note (carried to the checkpoint)
Root cause of the remaining gap: the new app's ported help i18n content is **structurally simpler than old-focal's** for these helpers — e.g. each step is a single body string (`googleSync.step1`), whereas old-focal's `StepItem` renders an **icon + title + description**, and old-focal's `RoleItem`/`DataSourceItem` carry per-item **icons** the ported content does not include. Reaching pixel-exact parity on these requires expanding the ported content (icons + per-item title/description), which is content authoring beyond a visual re-skin. Raised with the user for a scope decision.

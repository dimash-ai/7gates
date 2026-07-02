# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 7.8 / 10
Status: BLOCKED

## Reason
The design is mostly faithful to the approved plan and the old-focal tabbed manual, but it specifies one typecheck-breaking tab validation shape and misses an existing in-app help-link contract that will route users to the wrong tab after the redesign.

## Must Fix
- `.ai/design/focal-redesign-help-design.md:51-55` specifies `VALID_HELP_TABS` as an `as const` tuple and then calls `.includes(h)` where `h` is a plain `string`; under the client's strict TypeScript config (`superapp/apps/focal/client/tsconfig.json:18-22`) this is TS2345. Specify a type-safe predicate, string set, or widened readonly string list for hash validation.
- `.ai/design/focal-redesign-help-design.md:53-56` only seeds from `window.location.hash`, but the existing help interface documents and uses query-tab links (`superapp/apps/focal/client/src/components/PageHeader.tsx:15`, `superapp/apps/focal/client/src/features/budgets/TimeBudgetsPage.tsx:1926`). Once content is hidden behind tabs, `/help?tab=formulas` will open System and hide Formulas; the design needs to preserve or explicitly migrate that contract.

## Should Consider
None

## Tests Reviewed
N/A

## Release Risk
Medium

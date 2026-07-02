# Review Verdict

Reviewer: GPT Codex
Step: review
Score: 7.7 / 10
Status: BLOCKED

## Reason
The reskin is mostly scoped and the modal/lazy-query paths are covered, but the new CSV export path does not preserve old-focal's full formula-injection guard and ships hardcoded English CSV headers. Because the CSV issue is a concrete security risk in an admin export containing user-controlled names/emails, this cannot ship as-is.

## Must Fix
- `apps/focal/client/src/features/dashboard/dashboard.ts:119` only guards formula cells beginning with `=`, `+`, `-`, or `@`; old-focal also guarded leading tab and carriage return, and the new section export sends user-controlled names/emails through `csvSection` at `apps/focal/client/src/features/dashboard/sections.tsx:351`, so a name like `\t=IMPORTXML(...)` can still land in an exported CSV as an executable formula in spreadsheet apps.
- `apps/focal/client/src/features/dashboard/sections.tsx:353` hardcodes the user-engagement CSV headers in English (`User`, `Email`, `Status`, etc.) instead of routing them through `focal.dashboard.*` i18n keys, so the RU export violates the task's "No hardcoded strings / ru+en" acceptance.

## Should Consider
- `apps/focal/client/src/features/dashboard/overview.tsx:300` still hardcodes the Recharts series label as `retention`, and `apps/focal/client/src/features/dashboard/sections.tsx:146`/`:148` hardcode trend aria labels; localizing those would finish the i18n pass.
- Visual parity screenshots and the full writable-environment gate still need to be rerun outside this read-only review context.

## Tests Reviewed
`git diff`; `git status`; `git diff --check`; task/plan/design; old-focal dashboard/csv/export components; generated `openapi.d.ts`; dashboard source and component/helper tests; EN/RU dashboard key diff. Did not run the full suite because this review context is read-only.

## Release Risk
High

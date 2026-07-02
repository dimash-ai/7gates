# Review Verdict

Reviewer: GPT Codex
Step: review
Score: 8.6 / 10
Status: BLOCKED

## Reason
The token port is largely correct, `--sh-*` indirection is present, and a repo-wide CSS-variable reference scan found no orphaned token references. The slice still misses the top-bar shell parity required by the task/design: the shared header trigger was not reconciled to old-focal sizing.

## Must Fix
- `apps/focal/client/src/components/PageHeader.tsx:50` still renders a bare `SidebarTrigger`, which resolves to `h-7 w-7` in `apps/focal/client/src/components/ui/sidebar.tsx:267`; old-focal's header toggle uses `h-8 w-8` in `apps/old-focal/client/src/components/PageToolbar.tsx:99` and direct page headers such as `apps/old-focal/client/src/pages/Calendar.tsx:2678`. This leaves the top bar short of the shell visual acceptance criterion.

## Should Consider
- `apps/focal/client/src/themeTokens.test.ts:12` and `:31` only pin representative token/shadow values; a real misport of tokens like `--border`, `--card`, `--chart-*`, `--dashboard-*`, or the bare `--shadow` mapping would still pass. Consider enumerating the full shared token and shadow contract.

## Tests Reviewed
Reviewed `git -C superapp --no-pager show --stat HEAD`, `git -C superapp --no-pager show HEAD`, task/plan/design docs, changed files, old-focal references, and a repo-wide CSS variable reference scan. Attempted `pnpm test:run -- src/themeTokens.test.ts`, but the read-only sandbox blocked pnpm temp-file creation with `EPERM`.

## Release Risk
Medium

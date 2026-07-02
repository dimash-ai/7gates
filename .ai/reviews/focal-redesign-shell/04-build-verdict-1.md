# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.4 / 10
Status: BLOCKED

## Reason
The old-focal token port, bridge-token preservation, shadow indirection, and brand-mark swap are largely consistent with the task/design. However, the diff includes unrelated Goals page behavior and i18n edits, violating the required surgical scope for this shell/theme slice.

## Must Fix
- Remove or split the unrelated Goals feature changes from this build slice: `superapp/apps/focal/client/src/features/goals/GoalsPage.tsx:315`, `:387`, `:465`, `superapp/apps/focal/client/src/features/goals/CreateActivityDialog.tsx:18`, `superapp/apps/focal/client/src/i18n/locales/en.json:483`, and `superapp/apps/focal/client/src/i18n/locales/ru.json:491`. The task acceptance criteria limit production edits to `index.css` and shell components, with only the focused token test added.

## Should Consider
- Strengthen `superapp/apps/focal/client/src/themeTokens.test.ts` to assert the pinned `--focal-*` hex values and representative exact shadow values, not only token presence.

## Resolution
The flagged Goals/i18n edits were PRE-EXISTING uncommitted working-tree changes (last committed 4 days ago, commit 9385f5a), not part of this slice. Isolated the slice onto branch `feat/focal-redesign-shell` as commit b408877 (only index.css + AppSidebar.tsx + themeTokens.test.ts); the pre-existing changes remain untouched/unstaged. Also addressed the Should-Consider (pinned hex + exact shadow assertions). Re-reviewed → 04-build-verdict-2.md.

## Release Risk
Medium

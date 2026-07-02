---
description: "Step 7 (ship): Opus does, GPT reviews"
argument-hint: <feature-name> <repo-path> [base-branch]
---

# Step 7 — ship  ·  Opus does · GPT reviews

**Arguments — parse them yourself.** Raw args: `$ARGUMENTS`

Whitespace-split the raw args: token 1 → `<feature>`; token 2 → `<repo>` (path relative to the
pipeline root); token 3 (optional) → `<base>` (empty → `main`; focal until 2026-07-10 passes
`feature/focal-migration`). If the raw-args line above looks unsubstituted or empty, recover the tokens from this invocation's command-args instead. This file deliberately uses **no positional dollar-number placeholders** (the runner's `$N` is **0-indexed** — `$1` is the *second* argument, per the Claude Code skills docs — an off-by-one foot-gun against shell conventions); instead, substitute the literal angle-bracket tokens below — in prose AND inside bash blocks — with the parsed values before running anything. An absent optional token substitutes as an **empty string**.


`<feature>` is the feature; `<repo>` is the repo path (relative to the pipeline root); `<base>` is the **base
branch** the change targets — optional, **default `main`; pass `feature/focal-migration` for focal
slices** (which branch off the integration branch, not `main`). Where `<base>` appears below and was
omitted, substitute `main`.

**Worktree.** The change lives in this feature's dedicated worktree, `<repo>/.worktrees/<feature>`, on branch
`feature/<feature>` (per `.ai/checklists/worktree.md`). Every `git` and `codex` command below targets it,
never `<repo>`. Confirm it exists first:

```bash
[ -d "<repo>/.worktrees/<feature>" ] || echo "ERROR: no worktree for '<feature>' at <repo>/.worktrees/<feature> — run the build gate first."
```

**Doer = Opus (you, in this conversation).** Draft the PR text for `<feature>` into
`.ai/handoffs/<feature>-handoff.md` (title, summary, what changed, tests, verification output,
risks/rollback) following `.ai/handoffs/TEMPLATE.md`. The PR body is **for users** — what they can
now do — not the branch's history. Confirm it contains no secrets, tokens, keys, or PII.

**Reviewer = GPT (Codex), read-only — final release gate.** Run exactly this one bash command from the pipeline root:

```bash
codex exec --sandbox read-only "$(cat .ai/prompts/final-release-review.md)
This is the final release review for <feature>. First run 'git -C <repo>/.worktrees/<feature> --no-pager diff <base>...HEAD' (the base branch is <base> — if it was omitted, use main) and 'git -C <repo>/.worktrees/<feature> status' to see the full change set. Then review: the full diff against the base branch, the tests added, the verification output, possible regressions, and the drafted PR description at .ai/handoffs/<feature>-handoff.md. You are read-only and must NEVER edit any file. Score 0-10 per .ai/checklists/scoring-rubric.md and output the verdict EXACTLY as that prompt specifies (Reviewer: GPT Codex, Step: ship). Status is APPROVED only if Score is 9.0 or higher."
```

Then:

1. Ensure `.ai/reviews/<feature>/` exists, then save **only the verdict block** to `.ai/reviews/<feature>/07-ship-verdict.md` (increment if it exists).
2. STOP. Make no code changes in this step.
3. Report **Score** and **Status**:
   - **BLOCKED** (< 9.0): list every Must Fix.
   - **APPROVED** (>= 9.0): say so — this is the final gate; the change is cleared for release. The PR is from branch `feature/<feature>` — push it from the worktree (`git -C <repo>/.worktrees/<feature> push -u origin feature/<feature>`), then open/merge it using the drafted text in `.ai/handoffs/<feature>-handoff.md`, and run **Cleanup** below.

**Cleanup (after the PR merges).** Remove the worktree (keep the branch), per `.ai/checklists/worktree.md`:

```bash
git -C "<repo>" worktree remove ".worktrees/<feature>"     # refuses if dirty; keeps the branch
echo "Worktree removed. After confirming the merge landed: git -C <repo> branch -d feature/<feature>"
```

> `--sandbox read-only` keeps the reviewer from touching the tree — confirm the flag with `codex --help`.

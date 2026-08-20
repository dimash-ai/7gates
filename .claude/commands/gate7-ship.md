---
description: "Step 7 (ship): Opus does, GPT reviews"
argument-hint: <feature-name> <repo-path> [base-branch]
---

# Step 7 — ship  ·  Opus does · GPT reviews

`$1` is the feature; `$2` is the repo path (relative to the pipeline root); `$3` is the **base
branch** the change targets — optional, **default `main`; pass `feature/focal-migration` for focal
slices** (which branch off the integration branch, not `main`). Where `$3` appears below and was
omitted, substitute `main`.

**Worktree.** The change lives in this feature's dedicated worktree, `$2/.worktrees/$1`, on branch
`feature/$1` (per `harness/checklists/worktree.md`). Every `git` and `codex` command below targets it,
never `$2`. Confirm it exists first:

```bash
[ -d "$2/.worktrees/$1" ] || echo "ERROR: no worktree for '$1' at $2/.worktrees/$1 — run the build gate first."
```

**Doer = Opus (you, in this conversation).** Draft the PR text for `$1` into
`harness/handoffs/$1-handoff.md` (title, summary, what changed, tests, verification output,
risks/rollback) following `harness/handoffs/TEMPLATE.md`. The PR body is **for users** — what they can
now do — not the branch's history. Confirm it contains no secrets, tokens, keys, or PII.

**Reviewer = GPT (Codex), read-only — final release gate.** Run exactly this one bash command from the pipeline root:

```bash
codex exec --sandbox read-only "$(cat harness/prompts/final-release-review.md)
This is the final release review for $1. First run 'git -C $2/.worktrees/$1 --no-pager diff $3...HEAD' (the base branch is $3 — if it was omitted, use main) and 'git -C $2/.worktrees/$1 status' to see the full change set. Then review: the full diff against the base branch, the tests added, the verification output, possible regressions, and the drafted PR description at harness/handoffs/$1-handoff.md. You are read-only and must NEVER edit any file. Score 0-10 per harness/checklists/scoring-rubric.md and output the verdict EXACTLY as that prompt specifies (Reviewer: GPT Codex, Step: ship). Status is APPROVED only if Score is 9.0 or higher."
```

Then:

1. Ensure `harness/reviews/$1/` exists, then save **only the verdict block** to `harness/reviews/$1/07-ship-verdict.md` (increment if it exists).
2. STOP. Make no code changes in this step.
3. Report **Score** and **Status**:
   - **BLOCKED** (< 9.0): list every Must Fix.
   - **APPROVED** (>= 9.0): say so — this is the final gate; the change is cleared for release. The PR is from branch `feature/$1` — push it from the worktree (`git -C $2/.worktrees/$1 push -u origin feature/$1`), then open/merge it using the drafted text in `harness/handoffs/$1-handoff.md`, and run **Cleanup** below.

**Cleanup (after the PR merges).** Remove the worktree (keep the branch), per `harness/checklists/worktree.md`:

```bash
git -C "$2" worktree remove ".worktrees/$1"     # refuses if dirty; keeps the branch
echo "Worktree removed. After confirming the merge landed: git -C $2 branch -d feature/$1"
```

> `--sandbox read-only` keeps the reviewer from touching the tree — confirm the flag with `codex --help`.

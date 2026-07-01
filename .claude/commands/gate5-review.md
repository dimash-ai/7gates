---
description: "Step 5 (review): GPT does, Opus reviews"
argument-hint: <feature-name> <repo-path>
---

# Step 5 — review  ·  GPT does · Opus reviews

A single **holistic, adversarial whole-change pass** — distinct from Step 4, which gates each
slice for correctness. Here GPT reviews the *entire* change; Opus then reviews GPT's review.

`$1` is the feature; `$2` is the repo path (relative to the pipeline root).

**Worktree.** The change lives in this feature's dedicated worktree, `$2/.worktrees/$1` (per
`.ai/checklists/worktree.md`). Every `git` and `codex` command below targets it, never `$2`. Confirm
it exists first:

```bash
[ -d "$2/.worktrees/$1" ] || echo "ERROR: no worktree for '$1' at $2/.worktrees/$1 — run the build gate first."
```

**Doer = GPT (Codex), read-only.** A reviewer must not touch the tree, so GPT runs read-only and
prints its review; you persist it. Run exactly this one bash command from the pipeline root:

```bash
codex exec --sandbox read-only "$(cat .ai/prompts/reviewer.md)
You are GPT Codex, the doer for the REVIEW step of $1 — perform one holistic, adversarial pass over the WHOLE change. First run 'git -C $2/.worktrees/$1 --no-pager diff' and 'git -C $2/.worktrees/$1 status'. Review the full change against task .ai/tasks/$1.md, plan .ai/plans/$1-plan.md, and design .ai/design/$1-design.md. Hunt the things a per-slice gate misses: cross-cutting races, resource leaks, security (authz, injection, SSRF, secrets, rate-limiting), silent data corruption, swallowed failures, and any acceptance criterion not actually met. Cite file:line. You are read-only and must NEVER edit any file. Output your findings as a verdict EXACTLY as the charter specifies (Reviewer: GPT Codex, Step: review)."
```

Save GPT's verdict block to `.ai/reviews/$1/05-review-pass.md` (this is the **artifact**, GPT's review — increment if it exists).

**Reviewer = Opus, fresh context.** Do **not** judge GPT's review inline. Spawn a clean-context Opus reviewer with the **Agent tool** (`subagent_type: "claude"`), passing this prompt:

> `<contents of .ai/prompts/reviewer.md>`
> You are Opus, the reviewer. Step: review. Read GPT's review pass at `.ai/reviews/$1/05-review-pass.md`, and inspect the change yourself with `git -C $2/.worktrees/$1 --no-pager diff` plus the task/plan/design. Score the **quality of GPT's review**: did it miss real defects, raise false Must-Fixes, or fail to cite evidence? Output the verdict EXACTLY as the charter specifies (Reviewer: Opus, Step: review). Status APPROVED only if Score >= 9.0.

Then:

1. Save the subagent's verdict block to `.ai/reviews/$1/05-review-verdict.md` (increment if it exists).
2. STOP.
3. Report **Score** and **Status**:
   - **BLOCKED** (< 9.0): if Opus found the review weak, re-run the GPT review pass with the gaps named; if the review surfaced real Must-Fix defects in the *code*, fix those (back to Step 4) before proceeding.
   - **APPROVED** (>= 9.0): say so; next stage is **Step 6 — test** (`/gate6-test $1 $2`).

> `--sandbox read-only` keeps the GPT doer from editing during a review. The Opus review runs in a **fresh subagent**, not inline.

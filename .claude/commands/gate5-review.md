---
description: "Step 5 (review): GPT does, Opus reviews"
argument-hint: <feature-name> <repo-path>
---

# Step 5 — review  ·  GPT does · Opus reviews

**Arguments — parse them yourself.** Raw args: `$ARGUMENTS`

Whitespace-split the raw args: token 1 → `<feature>`; token 2 → `<repo>` (path relative to the
pipeline root). If the raw-args line above looks unsubstituted or empty, recover the tokens from this invocation's command-args instead. This file deliberately uses **no positional dollar-number placeholders** (the runner's `$N` is **0-indexed** — `$1` is the *second* argument, per the Claude Code skills docs — an off-by-one foot-gun against shell conventions); instead, substitute the literal angle-bracket tokens below — in prose AND inside bash blocks — with the parsed values before running anything. An absent optional token substitutes as an **empty string**.


A single **holistic, adversarial whole-change pass** — distinct from Step 4, which gates each
slice for correctness. Here GPT reviews the *entire* change; Opus then reviews GPT's review.

`<feature>` is the feature; `<repo>` is the repo path (relative to the pipeline root).

**Worktree.** The change lives in this feature's dedicated worktree, `<repo>/.worktrees/<feature>` (per
`.ai/checklists/worktree.md`). Every `git` and `codex` command below targets it, never `<repo>`. Confirm
it exists first:

```bash
[ -d "<repo>/.worktrees/<feature>" ] || echo "ERROR: no worktree for '<feature>' at <repo>/.worktrees/<feature> — run the build gate first."
```

**Doer = GPT (Codex), read-only.** A reviewer must not touch the tree, so GPT runs read-only and
prints its review; you persist it. Run exactly this one bash command from the pipeline root:

```bash
codex exec --sandbox read-only "$(cat .ai/prompts/reviewer.md)
You are GPT Codex, the doer for the REVIEW step of <feature> — perform one holistic, adversarial pass over the WHOLE change. First run 'git -C <repo>/.worktrees/<feature> --no-pager diff' and 'git -C <repo>/.worktrees/<feature> status'. Review the full change against task .ai/tasks/<feature>.md, plan .ai/plans/<feature>-plan.md, and design .ai/design/<feature>-design.md. Hunt the things a per-slice gate misses: cross-cutting races, resource leaks, security (authz, injection, SSRF, secrets, rate-limiting), silent data corruption, swallowed failures, and any acceptance criterion not actually met. Cite file:line. You are read-only and must NEVER edit any file. Output your findings as a verdict EXACTLY as the charter specifies (Reviewer: GPT Codex, Step: review)."
```

Save GPT's verdict block to `.ai/reviews/<feature>/05-review-pass.md` (this is the **artifact**, GPT's review — increment if it exists).

**Reviewer = Opus, fresh context.** Do **not** judge GPT's review inline. Spawn a clean-context Opus reviewer with the **Agent tool** (`subagent_type: "claude"`), passing this prompt:

> `<contents of .ai/prompts/reviewer.md>`
> You are Opus, the reviewer. Step: review. Read GPT's review pass at `.ai/reviews/<feature>/05-review-pass.md`, and inspect the change yourself with `git -C <repo>/.worktrees/<feature> --no-pager diff` plus the task/plan/design. Score the **quality of GPT's review**: did it miss real defects, raise false Must-Fixes, or fail to cite evidence? Output the verdict EXACTLY as the charter specifies (Reviewer: Opus, Step: review). Status APPROVED only if Score >= 9.0.

Then:

1. Save the subagent's verdict block to `.ai/reviews/<feature>/05-review-verdict.md` (increment if it exists).
2. STOP.
3. Report **Score** and **Status**:
   - **BLOCKED** (< 9.0): if Opus found the review weak, re-run the GPT review pass with the gaps named; if the review surfaced real Must-Fix defects in the *code*, fix those (back to Step 4) before proceeding.
   - **APPROVED** (>= 9.0): say so; next stage is **Step 6 — test** (`/gate6-test <feature> <repo>`).

> `--sandbox read-only` keeps the GPT doer from editing during a review. The Opus review runs in a **fresh subagent**, not inline.

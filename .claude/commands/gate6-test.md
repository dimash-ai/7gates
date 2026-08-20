---
description: "Step 6 (test): GPT does, Opus reviews"
argument-hint: <feature-name> <repo-path>
---

# Step 6 — test  ·  GPT does · Opus reviews

The builder does **not** grade its own homework: GPT (not the Opus builder) authors the tests, so
coverage is adversarial. `$1` is the feature; `$2` is the repo path (relative to the pipeline root).

**Worktree.** The change lives in this feature's dedicated worktree, `$2/.worktrees/$1` (per
`harness/checklists/worktree.md`). Every `git` and `codex` command below targets it, never `$2`. Confirm
it exists first:

```bash
[ -d "$2/.worktrees/$1" ] || echo "ERROR: no worktree for '$1' at $2/.worktrees/$1 — run the build gate first."
```

**Doer = GPT (Codex), write-enabled.** Run exactly this one bash command from the pipeline root:

```bash
codex exec --sandbox workspace-write "$(cat harness/prompts/doer.md)
You are GPT Codex, the doer for the TEST step of $1 in worktree $2/.worktrees/$1. Add or strengthen tests that prove the RISKY paths of this change — read the plan harness/plans/$1-plan.md and design harness/design/$1-design.md for which paths matter, and 'git -C $2/.worktrees/$1 --no-pager diff' for what changed. Cover edge and error paths, not just the happy path. Then run the repo's verification (e.g. 'make -C $2/.worktrees/$1 verify', or the repo's test command) until it passes. Write a short log — exact commands and pass/fail counts — to harness/runs/$1-test.txt. Touch ONLY test files and fixtures under $2/.worktrees/$1; do NOT change production code (if a test reveals a real bug, report it in the log, do not patch the code)."
```

**Reviewer = Opus, fresh context.** Spawn a clean-context Opus reviewer with the **Agent tool** (`subagent_type: "claude"`), passing this prompt:

> `<contents of harness/prompts/reviewer.md>`
> You are Opus, the reviewer. Step: test. Inspect the tests GPT added with `git -C $2/.worktrees/$1 --no-pager diff` (test files) and the run log `harness/runs/$1-test.txt`. Apply the test lens: do the tests cover the risky paths from the plan/design or only the happy path? Did the suite actually run green? Any failing or skipped check claimed "pre-existing" must be proven on the base branch. Output the verdict EXACTLY as the charter specifies (Reviewer: Opus, Step: test). Status APPROVED only if Score >= 9.0.

Then:

1. Save the subagent's verdict block to `harness/reviews/$1/06-test-verdict.md` (increment if it exists).
2. STOP.
3. Report **Score** and **Status**:
   - **BLOCKED** (< 9.0): list every Must Fix; re-run the GPT doer command to strengthen tests (or, if a real bug surfaced, fix it back at Step 4), then re-review.
   - **APPROVED** (>= 9.0): say so; next stage is **Step 7 — ship** (`/gate7-ship $1 $2`).

> `--sandbox workspace-write` lets the GPT doer write tests and run the suite — confirm the flag with `codex --help`. The Opus review runs in a **fresh subagent**, not inline.

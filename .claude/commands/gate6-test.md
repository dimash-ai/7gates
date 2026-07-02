---
description: "Step 6 (test): GPT does, Opus reviews"
argument-hint: <feature-name> <repo-path>
---

# Step 6 — test  ·  GPT does · Opus reviews

**Arguments — parse them yourself.** Raw args: `$ARGUMENTS`

Whitespace-split the raw args: token 1 → `<feature>`; token 2 → `<repo>` (path relative to the
pipeline root). If the raw-args line above looks unsubstituted or empty, recover the tokens from this invocation's command-args instead. This file deliberately uses **no positional dollar-number placeholders** (the runner's `$N` is **0-indexed** — `$1` is the *second* argument, per the Claude Code skills docs — an off-by-one foot-gun against shell conventions); instead, substitute the literal angle-bracket tokens below — in prose AND inside bash blocks — with the parsed values before running anything. An absent optional token substitutes as an **empty string**.


The builder does **not** grade its own homework: GPT (not the Opus builder) authors the tests, so
coverage is adversarial. `<feature>` is the feature; `<repo>` is the repo path (relative to the pipeline root).

**Worktree.** The change lives in this feature's dedicated worktree, `<repo>/.worktrees/<feature>` (per
`.ai/checklists/worktree.md`). Every `git` and `codex` command below targets it, never `<repo>`. Confirm
it exists first:

```bash
[ -d "<repo>/.worktrees/<feature>" ] || echo "ERROR: no worktree for '<feature>' at <repo>/.worktrees/<feature> — run the build gate first."
```

**Doer = GPT (Codex), write-enabled.** Run exactly this one bash command from the pipeline root:

```bash
codex exec --sandbox workspace-write "$(cat .ai/prompts/doer.md)
You are GPT Codex, the doer for the TEST step of <feature> in worktree <repo>/.worktrees/<feature>. Add or strengthen tests that prove the RISKY paths of this change — read the plan .ai/plans/<feature>-plan.md and design .ai/design/<feature>-design.md for which paths matter, and 'git -C <repo>/.worktrees/<feature> --no-pager diff' for what changed. Cover edge and error paths, not just the happy path. Then run the repo's verification (e.g. 'make -C <repo>/.worktrees/<feature> verify', or the repo's test command) until it passes. Write a short log — exact commands and pass/fail counts — to .ai/runs/<feature>-test.txt. Touch ONLY test files and fixtures under <repo>/.worktrees/<feature>; do NOT change production code (if a test reveals a real bug, report it in the log, do not patch the code)."
```

**Reviewer = Opus, fresh context.** Spawn a clean-context Opus reviewer with the **Agent tool** (`subagent_type: "claude"`), passing this prompt:

> `<contents of .ai/prompts/reviewer.md>`
> You are Opus, the reviewer. Step: test. Inspect the tests GPT added with `git -C <repo>/.worktrees/<feature> --no-pager diff` (test files) and the run log `.ai/runs/<feature>-test.txt`. Apply the test lens: do the tests cover the risky paths from the plan/design or only the happy path? Did the suite actually run green? Any failing or skipped check claimed "pre-existing" must be proven on the base branch. Output the verdict EXACTLY as the charter specifies (Reviewer: Opus, Step: test). Status APPROVED only if Score >= 9.0.

Then:

1. Save the subagent's verdict block to `.ai/reviews/<feature>/06-test-verdict.md` (increment if it exists).
2. STOP.
3. Report **Score** and **Status**:
   - **BLOCKED** (< 9.0): list every Must Fix; re-run the GPT doer command to strengthen tests (or, if a real bug surfaced, fix it back at Step 4), then re-review.
   - **APPROVED** (>= 9.0): say so; next stage is **Step 7 — ship** (`/gate7-ship <feature> <repo>`).

> `--sandbox workspace-write` lets the GPT doer write tests and run the suite — confirm the flag with `codex --help`. The Opus review runs in a **fresh subagent**, not inline.

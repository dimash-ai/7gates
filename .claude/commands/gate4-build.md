---
description: "Step 4 (build): Opus does, GPT reviews"
argument-hint: <feature-name> <repo-path> [base-branch]
---

# Step 4 — build  ·  Opus does · GPT reviews

**Arguments — parse them yourself.** Raw args: `$ARGUMENTS`

Whitespace-split the raw args: token 1 → `<feature>`; token 2 → `<repo>` (path relative to the
pipeline root); token 3 (optional) → `<base>` (empty → `main`; focal until 2026-07-10 passes
`feature/focal-migration`). If the raw-args line above looks unsubstituted or empty, recover the tokens from this invocation's command-args instead. This file deliberately uses **no positional dollar-number placeholders** (the runner's `$N` is **0-indexed** — `$1` is the *second* argument, per the Claude Code skills docs — an off-by-one foot-gun against shell conventions); instead, substitute the literal angle-bracket tokens below — in prose AND inside bash blocks — with the parsed values before running anything. An absent optional token substitutes as an **empty string**.


Invoke as `/gate4-build <feature> <repo> [base-branch]` (e.g.
`/gate4-build focal-habits-crud superapp feature/focal-migration`). `<feature>` is the feature; `<repo>` is the
path — relative to this pipeline root — to the git repo holding the changes; `<base>` is the **base
branch** the feature forks from (optional, **default `main`; pass `feature/focal-migration` for
focal slices**).

**Worktree (first thing).** This gate builds in a **dedicated worktree of `<repo>`** —
`<repo>/.worktrees/<feature>` on branch `feature/<feature>` — so parallel sessions never collide. Create it (first
slice) or reuse it (later slices), per the worktree contract `.ai/checklists/worktree.md`. Run from
the pipeline root:

```bash
BR="feature/<feature>"; BASE="<base>"; [ -n "$BASE" ] || BASE="main"   # focal: pass feature/focal-migration as <base>
if [ ! -d "<repo>/.worktrees/<feature>" ]; then
  if git -C "<repo>" show-ref --verify --quiet "refs/heads/$BR"; then
    git -C "<repo>" worktree add ".worktrees/<feature>" "$BR"            # branch exists (prior run) -> attach
  else
    git -C "<repo>" worktree add ".worktrees/<feature>" -b "$BR" "$BASE" # new branch off base
  fi
fi
echo "worktree: <repo>/.worktrees/<feature>   branch: $BR"
```

Every `git`, build, and review command below targets `<repo>/.worktrees/<feature>`, never `<repo>`.

**Doer = Opus (you, in this conversation).** Implement **one slice** of the approved plan, keep
the tree green, and run local checks. Do not start the next slice until this gate clears.

**Reviewer = GPT (Codex), read-only.** Run exactly this one bash command from the pipeline root; Codex reads the diff with `git -C <repo>/.worktrees/<feature>`:

```bash
codex exec --sandbox read-only "$(cat .ai/prompts/reviewer.md)
You are GPT Codex, the reviewer. Step: build. First run 'git -C <repo>/.worktrees/<feature> --no-pager diff' and 'git -C <repo>/.worktrees/<feature> status' to see the uncommitted changes. Then review that diff against the design .ai/design/<feature>-design.md, plan .ai/plans/<feature>-plan.md, and task .ai/tasks/<feature>.md. Apply the build lens: correctness, regressions, missing tests, unhandled edge cases, security, and any deviation from the plan/design. You are read-only and must NEVER edit any file. Score 0-10 per .ai/checklists/scoring-rubric.md and output the verdict EXACTLY as the charter specifies (Reviewer: GPT Codex, Step: build). Status is APPROVED only if Score is 9.0 or higher."
```

Then:

1. Ensure `.ai/reviews/<feature>/` exists, then save **only the verdict block** to `.ai/reviews/<feature>/04-build-verdict-1.md`. **Increment per slice and per fix:** `04-build-verdict-2.md`, `-3`, …
2. STOP. Make no code changes in this step.
3. Report **Score** and **Status**:
   - **BLOCKED** (< 9.0): list every Must Fix; fix only those next, then re-run this gate.
   - **APPROVED** (>= 9.0) and slices remain: build the next slice and re-run. All slices done: next stage is **Step 5 — review** (`/gate5-review <feature> <repo>`).

> `--sandbox read-only` keeps the reviewer from touching the tree — confirm the flag with `codex --help`.

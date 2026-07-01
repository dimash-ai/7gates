---
description: "Step 4 (build): Opus does, GPT reviews"
argument-hint: <feature-name> <repo-path> [base-branch]
---

# Step 4 — build  ·  Opus does · GPT reviews

Invoke as `/gate4-build <feature> <repo> [base-branch]` (e.g.
`/gate4-build focal-habits-crud superapp feature/focal-migration`). `$1` is the feature; `$2` is the
path — relative to this pipeline root — to the git repo holding the changes; `$3` is the **base
branch** the feature forks from (optional, **default `main`; pass `feature/focal-migration` for
focal slices**).

**Worktree (first thing).** This gate builds in a **dedicated worktree of `$2`** —
`$2/.worktrees/$1` on branch `feature/$1` — so parallel sessions never collide. Create it (first
slice) or reuse it (later slices), per the worktree contract `.ai/checklists/worktree.md`. Run from
the pipeline root:

```bash
BR="feature/$1"; BASE="$3"; [ -n "$BASE" ] || BASE="main"   # focal: pass feature/focal-migration as $3
if [ ! -d "$2/.worktrees/$1" ]; then
  if git -C "$2" show-ref --verify --quiet "refs/heads/$BR"; then
    git -C "$2" worktree add ".worktrees/$1" "$BR"            # branch exists (prior run) -> attach
  else
    git -C "$2" worktree add ".worktrees/$1" -b "$BR" "$BASE" # new branch off base
  fi
fi
echo "worktree: $2/.worktrees/$1   branch: $BR"
```

Every `git`, build, and review command below targets `$2/.worktrees/$1`, never `$2`.

**Doer = Opus (you, in this conversation).** Implement **one slice** of the approved plan, keep
the tree green, and run local checks. Do not start the next slice until this gate clears.

**Reviewer = GPT (Codex), read-only.** Run exactly this one bash command from the pipeline root; Codex reads the diff with `git -C $2/.worktrees/$1`:

```bash
codex exec --sandbox read-only "$(cat .ai/prompts/reviewer.md)
You are GPT Codex, the reviewer. Step: build. First run 'git -C $2/.worktrees/$1 --no-pager diff' and 'git -C $2/.worktrees/$1 status' to see the uncommitted changes. Then review that diff against the design .ai/design/$1-design.md, plan .ai/plans/$1-plan.md, and task .ai/tasks/$1.md. Apply the build lens: correctness, regressions, missing tests, unhandled edge cases, security, and any deviation from the plan/design. You are read-only and must NEVER edit any file. Score 0-10 per .ai/checklists/scoring-rubric.md and output the verdict EXACTLY as the charter specifies (Reviewer: GPT Codex, Step: build). Status is APPROVED only if Score is 9.0 or higher."
```

Then:

1. Ensure `.ai/reviews/$1/` exists, then save **only the verdict block** to `.ai/reviews/$1/04-build-verdict-1.md`. **Increment per slice and per fix:** `04-build-verdict-2.md`, `-3`, …
2. STOP. Make no code changes in this step.
3. Report **Score** and **Status**:
   - **BLOCKED** (< 9.0): list every Must Fix; fix only those next, then re-run this gate.
   - **APPROVED** (>= 9.0) and slices remain: build the next slice and re-run. All slices done: next stage is **Step 5 — review** (`/gate5-review $1 $2`).

> `--sandbox read-only` keeps the reviewer from touching the tree — confirm the flag with `codex --help`.

---
description: "3-gate B (build): Opus does, GPT reviews"
argument-hint: <feature-name> <repo-path> [base-branch]
---

# 3-Gate · B — build  ·  Opus does · GPT reviews

The middle gate of the **3-gate flow** (`ai/README-3gate.md`). Invoke as
`/gate-build <feature> <repo> [base-branch]` (e.g.
`/gate-build focal-habits-crud superapp feature/focal-migration`). `$1` is the feature; `$2` is the
path — relative to this pipeline root — to the git repo holding the changes; `$3` is the **base
branch** the feature forks from (optional, **default `main`; pass `feature/focal-migration` for
focal slices**).

**Worktree (first thing).** This gate builds in a **dedicated worktree of `$2`** —
`$2/.worktrees/$1` on branch `feature/$1` — so parallel sessions never collide. Create it (first
slice) or reuse it (later slices), per the worktree contract `ai/checklists/worktree.md`. Run from
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

**Doer = Opus (you, in this conversation).** Implement **one slice** of the plan in the design doc,
keep the tree green, and run local checks. Do not start the next slice until this gate clears.

- Read the design `ai/design/$1-design.md` and task `ai/tasks/$1.md`, then run
  `git -C $2/.worktrees/$1 --no-pager diff` and `git -C $2/.worktrees/$1 status` to see what is already done.
- Implement the NEXT single unbuilt slice: the minimum code that satisfies it, matching existing
  style. Walk the reuse-first ladder (CLAUDE.md #2) before adding new surface. Touch ONLY files
  under `$2/.worktrees/$1` needed for THIS slice — do not start later slices or refactor unrelated code.
- Keep the tree green: run the repo's local checks (e.g. `make -C $2/.worktrees/$1 verify` or its
  lint/type/test command) before finishing, and write a short log of exact commands and pass/fail
  counts to `ai/runs/$1-build.txt`.

**Reviewer = GPT (Codex), read-only.** Do not review your own slice — GPT reviews it from a blind
`codex exec` context. Run exactly this one bash command from the pipeline root:

```bash
codex exec --sandbox read-only "$(cat ai/prompts/reviewer.md)
You are GPT Codex, the reviewer. Step: build. First run 'git -C $2/.worktrees/$1 --no-pager diff' and 'git -C $2/.worktrees/$1 status' to see the uncommitted changes, and read the build log ai/runs/$1-build.txt. Review that diff against the design doc ai/design/$1-design.md and task ai/tasks/$1.md. Apply the build lens: correctness, regressions, missing tests, unhandled edge cases, security, and any deviation from the plan/design or scope creep beyond the single slice. You are read-only and must NEVER edit any file. Score 0-10 per ai/checklists/scoring-rubric.md and output the verdict EXACTLY as the charter specifies (Reviewer: GPT Codex, Step: build). Status is APPROVED only if Score is 9.0 or higher."
```

Then:

1. Ensure `ai/reviews/$1/` exists, then save **only the verdict block** to `ai/reviews/$1/B-build-verdict-1.md`. Do NOT paste the raw CLI transcript (write that to `ai/runs/` if you want it). **Increment per slice and per fix:** `B-build-verdict-2.md`, `-3`, …
2. STOP.
3. Report **Score** and **Status**:
   - **BLOCKED** (< 9.0): list every Must Fix, fix only those in the slice, then re-run this gate.
   - **APPROVED** (>= 9.0): **commit this slice in the worktree** — `git -C $2/.worktrees/$1 add -A && git -C $2/.worktrees/$1 commit -m "…"` (it is already on `feature/$1`) — with a clear message (amend/squash as you like), so the slices accumulate as committed history that gate C diffs against the base branch. Then, if slices remain, build the next and re-review; once all are done, next stage is **3-gate C — verify** (`/gate-verify $1 $2 $3`).

> `--sandbox read-only` keeps the GPT reviewer from touching the tree — confirm the flag with `codex --help`. GPT reviews from a separate `codex exec` process, so it has the same blind context a fresh subagent gives the other direction.

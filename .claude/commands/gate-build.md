---
description: "3-gate B (build): Opus does, GPT reviews"
argument-hint: <feature-name> <repo-path> [base-branch]
---

# 3-Gate · B — build  ·  Opus does · GPT reviews

**Arguments — parse them yourself.** Raw args: `$ARGUMENTS`

Whitespace-split the raw args: token 1 → `<feature>`; token 2 → `<repo>` (path relative to the
pipeline root); token 3 (optional) → `<base>` (empty → `main`; focal until 2026-07-10 passes
`feature/focal-migration`). If the raw-args line above looks unsubstituted or empty, recover the tokens from this invocation's command-args instead. This file deliberately uses **no positional dollar-number placeholders** (the runner's `$N` is **0-indexed** — `$1` is the *second* argument, per the Claude Code skills docs — an off-by-one foot-gun against shell conventions); instead, substitute the literal angle-bracket tokens below — in prose AND inside bash blocks — with the parsed values before running anything. An absent optional token substitutes as an **empty string**.


The middle gate of the **3-gate flow** (`.ai/README-3gate.md`). Invoke as
`/gate-build <feature> <repo> [base-branch]` (e.g.
`/gate-build focal-habits-crud superapp feature/focal-migration`). `<feature>` is the feature; `<repo>` is the
path — relative to this pipeline root — to the git repo holding the changes; `<base>` is the **base
branch** the feature forks from (optional, **default `main`; focal until 2026-07-10: pass
`feature/focal-migration`**).

**Worktree (first thing).** This gate builds in a **dedicated worktree of `<repo>`** —
`<repo>/.worktrees/<feature>` on branch `feature/<feature>` — so parallel sessions never collide. Gate A normally
creates it; locate and reuse it here, or create it now if missing (7-step flow, or a design run
without a `<repo>`), per the worktree contract `.ai/checklists/worktree.md`. Run from
the pipeline root:

```bash
BR="feature/<feature>"; BASE="<base>"; [ -n "$BASE" ] || BASE="main"   # focal until 2026-07-10: pass feature/focal-migration as <base>
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

**Doer = Opus (you, in this conversation).** Implement **one slice** of the plan in the design doc,
keep the tree green, and run local checks. Do not start the next slice until this gate clears.

- Read the design `.ai/design/<feature>-design.md` and task `.ai/tasks/<feature>.md`, then run
  `git -C <repo>/.worktrees/<feature> --no-pager diff` and `git -C <repo>/.worktrees/<feature> status` to see what is already done.
- Implement the NEXT single unbuilt slice: the minimum code that satisfies it, matching existing
  style. Walk the reuse-first ladder (CLAUDE.md #2) before adding new surface. Touch ONLY files
  under `<repo>/.worktrees/<feature>` needed for THIS slice — do not start later slices or refactor unrelated code.
- Keep the tree green: run the repo's local checks (e.g. `make -C <repo>/.worktrees/<feature> verify` or its
  lint/type/test command) before finishing, and write a short log of exact commands and pass/fail
  counts to `.ai/runs/<feature>-build.txt`.

**Reviewer = GPT (Codex), read-only.** Do not review your own slice — GPT reviews it from a blind
`codex exec` context. Run exactly this one bash command from the pipeline root:

```bash
codex exec --sandbox read-only "$(cat .ai/prompts/reviewer.md)
You are GPT Codex, the reviewer. Step: build. First run 'git -C <repo>/.worktrees/<feature> --no-pager diff' and 'git -C <repo>/.worktrees/<feature> status' to see the uncommitted changes, and read the build log .ai/runs/<feature>-build.txt. Review that diff against the design doc .ai/design/<feature>-design.md and task .ai/tasks/<feature>.md. Apply the build lens: correctness, regressions, missing tests, unhandled edge cases, security, and any deviation from the plan/design or scope creep beyond the single slice. You are read-only and must NEVER edit any file. Score 0-10 per .ai/checklists/scoring-rubric.md and output the verdict EXACTLY as the charter specifies (Reviewer: GPT Codex, Step: build). Status is APPROVED only if Score is 9.0 or higher."
```

Then:

1. Ensure `.ai/reviews/<feature>/` exists, then save **only the verdict block** to `.ai/reviews/<feature>/B-build-verdict-1.md`. Do NOT paste the raw CLI transcript (write that to `.ai/runs/` if you want it). **Increment per slice and per fix:** `B-build-verdict-2.md`, `-3`, …
2. STOP.
3. Report **Score** and **Status**:
   - **BLOCKED** (< 9.0): list every Must Fix, fix only those in the slice, then re-run this gate.
   - **APPROVED** (>= 9.0): **commit this slice in the worktree** — `git -C <repo>/.worktrees/<feature> add -A && git -C <repo>/.worktrees/<feature> commit -m "…"` (it is already on `feature/<feature>`) — with a clear message (amend/squash as you like), so the slices accumulate as committed history that gate C diffs against the base branch. Then, if slices remain, build the next and re-review; once all are done, next stage is **3-gate C — verify** (`/gate-verify <feature> <repo> <base>`).

> `--sandbox read-only` keeps the GPT reviewer from touching the tree — confirm the flag with `codex --help`. GPT reviews from a separate `codex exec` process, so it has the same blind context a fresh subagent gives the other direction.

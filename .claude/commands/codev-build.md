---
description: "Co-dev 2 (build): Opus does, GPT reviews"
argument-hint: <feature-name> [repo-path] [base-branch]
---

# Co-dev · 2 — build  ·  Opus does · GPT reviews

The second and final gate of the **2-gate co-dev flow** (`harness/README-2gate.md`). Invoke as
`/codev-build <feature> [repo] [base-branch]` (e.g. `/codev-build focal-habits-crud dev`).
`$1` is the feature; `$2` is the path — relative to this pipeline root — to the git repo holding the
changes (**optional, defaults to `superapp`**); `$3` is the **base branch** the feature forks from
(**optional, defaults to `main`**; pass `dev` for superapp app work, per that repo's branch policy).

Run this command **once per slice**. Each run does **Phase 1**; on the run whose slice verdict
completes the last slice in the plan, continue straight into **Phase 2** in that same run.

**Worktree + arguments (first thing).** This gate builds in a **dedicated worktree of the repo** —
`<repo>/.worktrees/$1` on branch `feature/$1` — so parallel sessions never collide. Create it (first
slice) or reuse it (later slices), per the worktree contract `harness/checklists/worktree.md`. This block
also resolves the two optional arguments — both are positional, so it disambiguates them by testing
whether `$2` is an actual directory (`superapp` is; `dev` isn't). Run from the pipeline root:

```bash
REPO="$2"; BASE="$3"; BR="feature/$1"
[ -d "$REPO" ] || { BASE="${BASE:-$REPO}"; REPO="superapp"; }  # arg2 isn't a directory -> it was the base branch
[ -n "$BASE" ] || BASE="main"
if [ ! -d "$REPO/.worktrees/$1" ]; then
  if git -C "$REPO" show-ref --verify --quiet "refs/heads/$BR"; then
    git -C "$REPO" worktree add ".worktrees/$1" "$BR"            # branch exists (prior run) -> attach
  else
    git -C "$REPO" fetch origin "$BASE" --quiet || true          # fork from the remote tip, not a stale local ref
    git -C "$REPO" worktree add ".worktrees/$1" -b "$BR" "$BASE"
  fi
fi
echo "repo: $REPO   base: $BASE   worktree: $REPO/.worktrees/$1   branch: $BR"
```

**Use the printed `repo:` and `base:` values literally in every command below**, in the bash blocks
and inside the codex prompt strings alike — shell variables do not survive between these blocks, so
wherever `$2` or `$3` appears below, write the resolved value instead. Every `git`, build, and review
command targets `<repo>/.worktrees/$1`, never `<repo>` itself.

---

## Phase 1 — build one slice, GPT reviews it

**Doer = Opus (you, in this conversation).** Implement **one slice** of the plan, keep the tree
green, and run the local checks yourself.

- Read the plan `harness/design/$1-design.md` and the task `harness/tasks/$1.md` if present, then run
  `git -C $2/.worktrees/$1 --no-pager diff` and `git -C $2/.worktrees/$1 status` to see what is
  already done.
- Implement the NEXT single unbuilt slice: the minimum code that satisfies it, matching existing
  style. Walk the reuse-first ladder (CLAUDE.md #2) before adding new surface. Touch ONLY the files
  under `$2/.worktrees/$1` this slice needs — do not start later slices or refactor unrelated code.
- **Write this slice's tests.** In the 2-gate flow you author your own tests — GPT never writes an
  independent one, it only judges yours — so cover the failure mode the plan names for this slice,
  not just the happy path.
- Keep the tree green: run the repo's local checks (its lint / type / test commands, e.g.
  `make -C $2/.worktrees/$1 verify`) and append the **exact commands with their real pass/fail
  counts** to `harness/runs/$1-codev-build.txt`. Never write a count you didn't observe — the reviewer
  re-runs the suite in Phase 2.

**Reviewer = GPT (Codex), read-only.** Do not review your own slice. Run exactly this one bash
command from the pipeline root — **bump `-1` in the `-o` path to the next unused number** for each
slice and each re-review after a fix:

```bash
mkdir -p harness/reviews/$1 harness/runs
codex exec --sandbox read-only -o harness/reviews/$1/2-build-verdict-1.md "$(cat harness/prompts/reviewer.md)
You are GPT Codex, the reviewer. Step: build. First run 'git -C $2/.worktrees/$1 --no-pager diff' and 'git -C $2/.worktrees/$1 status' to see the uncommitted slice, and read the build log harness/runs/$1-codev-build.txt. Review that diff against the plan harness/design/$1-design.md and the task harness/tasks/$1.md. Apply the build lens: correctness, regressions, unhandled edge cases, security, and any deviation from the plan or scope creep beyond this single slice. Judge the TESTS as hard as the code — the builder wrote them itself, so ask whether they actually exercise the failure mode this slice's plan row names, or only the happy path; a new behavior with no test that could fail is a Must Fix. Any pass/fail claim in the build log that the log itself does not show is a Must Fix. You are read-only and must NEVER edit any file. Score 0-10 per harness/checklists/scoring-rubric.md. Your FINAL message must be the verdict block EXACTLY as the charter specifies (Reviewer: GPT Codex, Step: build) and nothing else. Status is APPROVED only if Score is 9.0 or higher." 2>&1 | tee harness/runs/$1-codev-review.txt
```

Then read the verdict file and report **Score** and **Status**:

- **BLOCKED** (< 9.0): list every Must Fix, fix only those in this slice, re-run the review (next `-o` number).
- **APPROVED** (>= 9.0): **commit the slice in the worktree** —
  `git -C $2/.worktrees/$1 add -A && git -C $2/.worktrees/$1 commit -m "…"` (it is already on
  `feature/$1`) — with a clear message and **no AI attribution** (root `CLAUDE.md`). Then: if slices
  remain, STOP and re-invoke this command for the next one; if this was the last slice, continue to
  Phase 2 now.

---

## Phase 2 — release review over the whole change, then ship

Runs **once**, after the final slice is committed. Here GPT gets a write-enabled sandbox for one
reason: to **run the checks itself**, so the release never rests on the builder's own claim that the
suite was green. It still may not change anything.

```bash
git -C $2/.worktrees/$1 status --porcelain   # must be EMPTY — every slice is committed before this pass
codex exec --sandbox workspace-write -o harness/reviews/$1/2-release-verdict.md "$(cat harness/prompts/final-release-review.md)
You are GPT Codex, the reviewer for the RELEASE gate of $1. Step: ship. Run 'git -C $2/.worktrees/$1 --no-pager diff $3...HEAD' (substitute the base branch resolved above) and review the WHOLE change against the plan harness/design/$1-design.md: every success criterion actually met, plus the defects a per-slice gate misses — cross-cutting races, resource leaks, security (authz, injection, SSRF, secrets, rate-limiting), silent data corruption, swallowed failures. Cite file:line. Then RUN the repo's own checks yourself inside $2/.worktrees/$1 (its lint, type, and test commands) and report the counts you actually observed; treat the build log harness/runs/$1-codev-build.txt as a claim to verify, not evidence. The builder wrote its own tests, so judge whether they prove the risky paths the plan names or merely the happy path. You have NO network and no secrets: if a check cannot run here because it needs the network, a database, or credentials, say so explicitly and fall back to reviewing the log for it — that is a limitation of the sandbox, NOT a failure of the change. You may run commands, but you must NOT create, edit, or delete ANY file — no source, no test, no fixture, no config: if something needs changing, report it as a Must Fix instead of patching it. Your FINAL message must be the verdict block EXACTLY as that charter specifies (Reviewer: GPT Codex, Step: ship) and nothing else. Status is APPROVED only if Score is 9.0 or higher." 2>&1 | tee harness/runs/$1-codev-release.txt
git -C $2/.worktrees/$1 status --porcelain   # must STILL be empty
```

If that second `status` is not empty, the reviewer touched the tree: inspect the diff, discard it
(`git -C $2/.worktrees/$1 checkout -- .`), and re-run the pass — a verdict produced while editing the
code isn't a review.

Then report **Score** and **Status**:

- **BLOCKED** (< 9.0): list every Must Fix. Fix them back in **Phase 1** as a new slice (build →
  GPT slice review → commit), then re-run Phase 2.
- **APPROVED** (>= 9.0): proceed to **Ship**.

**Ship (Opus, on APPROVED only).** Draft the PR text for `$1` into `harness/handoffs/$1-handoff.md`
following `harness/handoffs/TEMPLATE.md` (title, summary, what changed, tests, verification output,
risks/rollback). The PR body is **for users** — what they can now do — not the branch's history, and
carries **no AI attribution**. Confirm it contains no secrets, tokens, keys, or PII. Then push and
open the PR, **always naming the base explicitly** (`gh pr create` defaults to the repo's default
branch, which is how a feature branch ends up targeting `main` by accident):

```bash
git -C $2/.worktrees/$1 push -u origin "feature/$1"
gh pr create --repo <owner/repo> --base <the base resolved above> --head "feature/$1" --title "…" --body-file harness/handoffs/$1-handoff.md
```

**After the PR merges, remove the worktree** (keep the branch), per `harness/checklists/worktree.md`:

```bash
git -C "$2" worktree remove ".worktrees/$1"     # refuses if dirty; keeps the branch
echo "Worktree removed. After confirming the merge landed: git -C $2 branch -d feature/$1"
```

> `--sandbox read-only` keeps the per-slice reviewer off the tree; `--sandbox workspace-write` in Phase 2 exists only so it can run the suite — the two `git status --porcelain` calls around it are the guard. Confirm both flags with `codex --help`. `-o <file>` writes the reviewer's final message straight to the verdict file, so no verdict is ever transcribed by hand.

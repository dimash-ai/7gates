---
description: "3-gate C (verify): GPT does, Opus reviews"
argument-hint: <feature-name> <repo-path> [base-branch]
---

# 3-Gate · C — verify  ·  GPT does · Opus reviews

**Arguments — parse them yourself.** Raw args: `$ARGUMENTS`

Whitespace-split the raw args: token 1 → `<feature>`; token 2 → `<repo>` (path relative to the
pipeline root); token 3 (optional) → `<base>` (empty → `main`; focal until 2026-07-10 passes
`feature/focal-migration`). If the raw-args line above looks unsubstituted or empty, recover the tokens from this invocation's command-args instead. This file deliberately uses **no positional dollar-number placeholders** (the runner's `$N` is **0-indexed** — `$1` is the *second* argument, per the Claude Code skills docs — an off-by-one foot-gun against shell conventions); instead, substitute the literal angle-bracket tokens below — in prose AND inside bash blocks — with the parsed values before running anything. An absent optional token substitutes as an **empty string**.


The final gate of the **3-gate flow** (`.ai/README-3gate.md`): **prove the change is correct
and ready, then ship it.** `<feature>` is the feature; `<repo>` is the repo path (relative to the pipeline
root); `<base>` is the **base branch** the slice targets — optional, **default `main`; pass
`feature/focal-migration` for focal slices.** By this gate the build slices are committed on the
feature branch (gate B commits each approved slice), so the change is diffed against `<base>` below as
`<base>...HEAD`. (Where `<base>` appears in a command and was omitted, substitute `main`.)

**Worktree.** The build slices live in this feature's dedicated worktree, `<repo>/.worktrees/<feature>` (per
`.ai/checklists/worktree.md`). Every `git` and `codex` command below targets it, never `<repo>`.
Confirm it exists first:

```bash
[ -d "<repo>/.worktrees/<feature>" ] || echo "ERROR: no worktree for '<feature>' at <repo>/.worktrees/<feature> — run the build gate first."
```

The builder (Opus, gate B) does not verify its own work — GPT runs the verification here, so it
stays adversarial.

**Doer = GPT (Codex), write-enabled.** GPT verifies the whole change in one pass — scrutinize, then
back the risky paths with tests. Run exactly this one bash command from the pipeline root:

```bash
codex exec --sandbox workspace-write "$(cat .ai/prompts/doer.md)
You are GPT Codex, the doer for the VERIFY step of <feature> in worktree <repo>/.worktrees/<feature>. Run 'git -C <repo>/.worktrees/<feature> --no-pager diff <base>...HEAD' (the base branch is <base> — if it was omitted, use main) and 'git -C <repo>/.worktrees/<feature> status', then verify the whole change against task .ai/tasks/<feature>.md and design .ai/design/<feature>-design.md in ONE pass, not a checklist. (a) Scrutinize the entire change for the defects a per-slice gate misses: cross-cutting races, resource leaks, security (authz, injection, SSRF, secrets, rate-limiting), silent data corruption, swallowed failures, and any success criterion not actually met — cite file:line. (b) Back the risky paths with proof: add or strengthen tests under <repo>/.worktrees/<feature> covering the edge and error paths (not just the happy path), and run the repo's verification (e.g. 'make -C <repo>/.worktrees/<feature> verify' or its test command) until it is green. (c) PRINT your full verification report to stdout — what you scrutinized, what each test proves, and the pass/fail counts. Do NOT try to write it under .ai/: your workspace-write sandbox is scoped to <repo>/.worktrees/<feature>, a worktree of a DIFFERENT git repo than the pipeline's .ai/ tree, so a write there will fail. Touch ONLY test files and fixtures under <repo>/.worktrees/<feature>; if you find a real bug in production code, STOP and report it for a gate-B fix — do NOT patch production code here."
```

**After codex returns, save its output (Opus, in-session).** GPT printed its report rather than
writing it (its sandbox can't reach `.ai/`), so persist it now: write codex's verification report to
`.ai/reviews/<feature>/C-verify-report.md` and the raw transcript to `.ai/runs/<feature>-verify.txt` — the Opus
reviewer below reads both.

**Reviewer = Opus, fresh context — also the release gate.** Do **not** review inline — you did not
watch GPT verify, keep it that way. Spawn a clean-context Opus reviewer with the **Agent tool**
(`subagent_type: "claude"`), passing this prompt:

> `<contents of .ai/prompts/final-release-review.md>`
> You are Opus, the reviewer for the VERIFY step of <feature> (it also serves as the release gate). First run `git -C <repo>/.worktrees/<feature> --no-pager diff <base>...HEAD` (the base branch is <base> — if omitted, use main) and `git -C <repo>/.worktrees/<feature> status`. Read GPT's verification report at `.ai/reviews/<feature>/C-verify-report.md` and the test run log `.ai/runs/<feature>-verify.txt`. Judge the verification as a whole: did GPT miss real defects or raise false ones; do the added tests actually cover the risky paths from the design rather than just the happy path; did the suite truly run green (any failing/skipped check claimed 'pre-existing' must be proven on the base branch); and what is the release risk across the full diff? Output the verdict EXACTLY as that charter specifies (Reviewer: Opus, Step: verify). Status APPROVED only if Score >= 9.0.

Then:

1. Save **only the verdict block** to `.ai/reviews/<feature>/C-verify-verdict.md` (increment if it exists).
2. Report **Score** and **Status**:
   - **BLOCKED** (< 9.0): list every Must Fix. If the verification was thin (missed defects, weak tests), re-run the GPT verify doer to strengthen it; if a real defect in the *code* surfaced, fix it back at **gate B** (Opus, in-session) before re-running this gate.
   - **APPROVED** (>= 9.0): proceed to **Ship** below.

**Ship (Opus, on APPROVED only).** Draft the PR text for `<feature>` into `.ai/handoffs/<feature>-handoff.md`
following `.ai/handoffs/TEMPLATE.md` (title, summary, what changed, tests, verification output,
risks/rollback). The PR body is **for users** — what they can now do — not the branch's history.
Confirm it contains no secrets, tokens, keys, or PII. The PR is from branch `feature/<feature>` — push it
from the worktree (`git -C <repo>/.worktrees/<feature> push -u origin feature/<feature>`), then open/merge it using
that text.

**After the PR merges, remove the worktree** (keep the branch), per `.ai/checklists/worktree.md`:

```bash
git -C "<repo>" worktree remove ".worktrees/<feature>"     # refuses if dirty; keeps the branch
echo "Worktree removed. After confirming the merge landed: git -C <repo> branch -d feature/<feature>"
```

> `--sandbox workspace-write` lets the GPT verify doer write tests and run the suite — confirm the flag with `codex --help`. The Opus review runs in a **fresh subagent**, not inline, and uses the final-release-review charter, so it doubles as the release gate.

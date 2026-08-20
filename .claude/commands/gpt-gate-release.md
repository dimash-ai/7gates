---
description: "GPT gate γ (release): Codex runs the suite itself and scores the whole change before ship"
argument-hint: <ticket-slug> [work-root] [base-branch]
---

# GPT gate · γ — release  ·  Claude built · GPT Codex verifies

The **cross-model release gate** for the feature-dev flow. It runs after the Triage findings are
implemented (RUNBOOK **T6**) and before the ship steps (**T9/T10**).

Why it exists: every verification upstream of this point is Claude verifying Claude. `qa` is Sonnet
scoring Sonnet's code; T3–T5 are three Claude review skills. All of them read. **This gate runs.**
Codex gets a write-enabled sandbox for one reason — so the approval rests on a suite *it executed
itself and counted*, never on the builder's claim that it was green. That is the single property
the 2-gate co-dev flow's release pass existed to guarantee, and it is the one feature-dev has no
equivalent for. See [`harness/README-gpt-gates.md`](../../harness/README-gpt-gates.md).

`$1` is the ticket slug (`ALL-555`). `$2` is the work root relative to the pipeline root —
**optional, defaults to `superapp`**; pass the worktree
(`superapp/.claude/worktrees/all-555-focal-settings`) when the ticket runs in one. `$3` is the base
branch the change forks from and the PR targets — **optional, defaults to `dev`**. **If `$2`/`$3`
were omitted, substitute `superapp` / `dev` for every occurrence below — inside the codex prompt
string too — before running anything.**

> **Get the base right.** The default `dev` is correct for this gate, because gate γ runs before
> **T9**, which ships to `dev`. Do not be misled by the `-main` branches: `feature/all-555-…-main`
> is the **T10 promotion branch**, cherry-picked onto `main` *after* human QA moves the issue to
> `Done` — every ticket has both (`feature/all-551-focal-analytics` and `…-analytics-main`). Pass
> `main` only when you are gating a promotion branch itself. If unsure, confirm the real fork point:
> `git -C $2 merge-base --fork-point dev HEAD` vs `… main HEAD` — a wrong base fills the diff with
> unrelated commits and the verdict is noise.

## Reviewer = GPT Codex, write-enabled so it can execute

Write access is scoped to running checks, not to fixing anything. Run exactly this one bash command
from the pipeline root:

```bash
mkdir -p harness/reviews/$1 harness/runs
codex exec --sandbox workspace-write "$(cat harness/prompts/final-release-review.md)
$(cat harness/checklists/release-gate.md)
$(cat harness/checklists/scoring-rubric.md)
You are GPT Codex performing the FINAL release gate for $1, built by Claude Code in $2. Work in $2. You are a REVIEWER: you may run commands, but you may NOT fix, refactor, or edit any source file, test, or config — if something is broken, report it, do not repair it. The one exception is the review hygiene below.
REVIEW HYGIENE (do this first, and undo it last). Run 'git -C $2 add -N .' so new and untracked files enter every diff-based view — intent-to-add respects .gitignore and stages nothing for commit; skip it and a plain diff omits new files entirely, so the review silently covers only the modified ones and misses whole new modules. Use 'git -C $2 diff $3...HEAD' and 'git -C $2 diff HEAD' rather than a bare 'git diff', which shows NOTHING for an already-staged path. Enumerate the full review scope with 'git -C $2 status --porcelain -uall | cut -c4- | grep -vE \"^specs/\"' — cut -c4-, never awk, which drops the new path of a rename and breaks on paths with spaces; the file count you review MUST match that list, and say so if it does not. WHEN DONE run 'git -C $2 reset' to clear the intent-to-add entries: leaving them in the index arms a data-loss trap, because git add -N records each new path with an EMPTY blob and a later 'git restore .' then destroys those files' contents.
RUN THE CHECKS YOURSELF. Read $2/CLAUDE.md for the repo's verification commands and the DevelopmentPlan.md Runtime Commands table for this ticket's app-specific row, then execute them — the full suite, the linter, the type checker, whatever that row names. Report the ACTUAL counts you observed (passed / failed / skipped / errors) and the exact command lines you ran. An approval that cites a count you did not personally produce is itself a Must Fix. Any failing or skipped check counts as pre-existing ONLY if you prove it fails on $3 too; an unproven 'unrelated to my change' claim blocks the release.
CONSTITUTIONAL PASS. Read $2/CLAUDE.md's AI-track rule. For every NEW backend Python module in the diff, confirm the semantic exoskeleton is present (# region MODULE_CONTRACT with the Doxygen ## @-contract block, paired # region FUNC_/CLASS_ tags, # GREP_SUMMARY:, # STRUCTURE:) and that LDD is encoded as structlog fields (imp=/func=/block=), NOT bracket strings. For a PRE-EXISTING module the change edits, require LDD only on the new control flow this change introduced — a retrofit demand on untouched branches is itself a Must Fix, and so is module-level markup added to a pre-existing file. Records emitted by a shared wrapper, decorator or middleware do NOT satisfy a module's own instrumentation: a module must instrument the control flow it owns — every I/O boundary it crosses and every validation rejection it makes. A trace that reads as compliant because someone else's wrapper logged func=\"<this module>\" is the false negative to hunt. Alembic migrations are EXEMPT from both. Frontend code is EXEMPT from both. Missing constitutional instrumentation grades MED and is a Must Fix.
SPEC TRUTH. Read $2/specs/$1.md (or the single specs/*.md if that exact name is absent) and $2/specs/DevelopmentPlan.md. Every Acceptance Criterion must be met AND demonstrably tested — name the test that proves each one. An AC met but untested is a Must Fix; an AC silently dropped is a Must Fix that also means the spec and the build diverged, so say which is wrong. Check the coder's Deviations / SD blocks in DevelopmentPlan.md: an undeclared deviation is a Must Fix.
Also apply the Test-Capture Antipattern check: for any capture fixture whose channel is a declared deliverable or crosses a process/container boundary (caplog, capsys, mocked asyncpg/httpx/neo4j drivers, in-memory transports), a green assert proves only that the code CALLED the channel's API — demand a runtime probe against the real sink, or grade it a Must Fix.
Output ONLY the verdict block from the charter, with Step: ship." 2>&1 | tee harness/runs/$1-gpt-gate-release.txt
```

**You persist the verdict**: copy the block verbatim into `harness/reviews/$1/release-verdict.md`
(re-scores become `release-verdict-2.md`, …). Do not summarize or re-grade it.

Then confirm the sandbox left nothing behind — `git -C $2 status --porcelain` should show only the
change itself, with no staged entries:

```bash
git -C $2 status --porcelain | head -30
```

If intent-to-add entries survived (paths staged as `A `), run `git -C $2 reset` yourself before
touching anything else. **Never** run `git restore .` / `git checkout -- .` while they are present.

## The gate

- **Score >= 9.0 / APPROVED** → cleared for **T9** (ship to `$3`). Carry the verdict's Release Risk
  line into the PR body.
- **Score < 9.0 / BLOCKED** → paste the **Must Fix** list into the still-open build thread as a
  fix round, same as a T6 findings loop. Fix only the cited items, then re-run this gate. Hard caps
  from the rubric apply: any must-fix → ≤ 8.9; any security, data-loss or build/test-breaking issue
  → ≤ 7.9.
- A Must Fix that is **spec-level** (an AC that was never right) stops the ship: amend `specs/$1.md`
  and re-enter the flow at T2, not here.

## When to skip it

Trivial fix tickets that enter the flow at T6/T7 and touch no AI-track module, no auth path, no
migration and no public contract. Say in the PR that the gate was skipped and why — a silently
skipped gate reads as a passed one.

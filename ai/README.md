# Two-Agent Development Pipeline

> **Superseded for superapp work (2026-08-20).** New features enter through the feature-dev cycle
> with the two cross-model gates — see [`README-gpt-gates.md`](README-gpt-gates.md). This flow's
> charters and rubric are still live; its doer commands have no active consumer.

This `ai/` directory is the **coordination layer** between Opus (Claude Code) and GPT (Codex) —
a lightweight, operational paper trail, not a transcript archive. Every feature flows through a
scored, adversarial process; each step has a **doer** and a **reviewer**, and the work proceeds
only when the reviewer scores it **>= 9.0**.

> **This file documents the 7-step flow — the higher-granularity option.** By default a feature runs
> the shorter **3-Gate flow** ([`README-3gate.md`](README-3gate.md)) — design / build / verify, the
> same adversarial scored gates in three integrated passes instead of seven. Reach for the 7-step
> flow below when you want finer checkpoints (e.g. the test author blind to its own review findings).
> The two flows are peers; the 3-gate is just the default pick.
>
> **Just exploring?** Before any build flow, `/gate-explore <topic>` brainstorms a question with
> Opus and GPT answering **independently**, then synthesizes a small findings note to
> `notes/<topic>.md` (consensus / divergence / open). It is standalone and **not scored** — it
> builds context, it doesn't gate code.

## Operating Model

**Each step has one doer and one reviewer. They alternate between Opus and GPT.** The doer is one
model, the reviewer is always the *other* model — so no model ever grades its own work.

```
Doer produces the step's artifact.
Reviewer (the other model) scores it / 10.
Score >= 9.0  → proceed to the next step.
Score <  9.0  → doer fixes the cited Must Fix items and resubmits for re-score.
```

The reviewer runs **read-only** and returns a scored verdict only — it never edits the artifact.
The doer fixes **only** the cited Must Fix items on a BLOCK — no scope creep, no opportunistic
refactors — then resubmits.

**House quality bar.** Both roles work to four principles — Think Before Coding, Simplicity First,
Surgical Changes, Goal-Driven Execution (full text in root [`CLAUDE.md`](../CLAUDE.md)). The doer
follows them; the reviewer scores against them, with severities in
[`checklists/scoring-rubric.md`](checklists/scoring-rubric.md).

## The 7 Steps

| # | Step | Doer | Reviewer | Artifact | Command |
|---|------|------|----------|----------|---------|
| 1 | think  | **Opus** | GPT  | `think/<f>.md`        | `/gate1-think <f>` |
| 2 | plan   | **GPT**  | Opus | `plans/<f>-plan.md`   | `/gate2-plan <f>` |
| 3 | design | **Opus** | GPT  | `design/<f>-design.md`| `/gate3-design <f>` |
| 4 | build  | **Opus** | GPT  | code diff in repo     | `/gate4-build <f> <repo> [base]` |
| 5 | review | **GPT**  | Opus | `reviews/<f>/05-review-pass.md` | `/gate5-review <f> <repo>` |
| 6 | test   | **GPT**  | Opus | tests + `runs/<f>-test.txt` | `/gate6-test <f> <repo>` |
| 7 | ship   | **Opus** | GPT  | `handoffs/<f>-handoff.md` + PR | `/gate7-ship <f> <repo>` |

Two deliberate properties of this assignment:

- **Step 4 vs Step 5.** Step 4 gates each build *slice* for correctness against plan/design. Step 5
  is one *holistic, adversarial whole-change pass* — GPT reviews the entire change, Opus reviews
  GPT's review. They are not redundant: per-slice gate vs cross-cutting sweep.
- **GPT writes the tests (Step 6), not the Opus builder.** The builder does not grade its own
  homework — adversarial test authorship by the other model.

## How the two directions run

| Direction | Doer mechanism | Reviewer mechanism |
|-----------|----------------|--------------------|
| Opus does → GPT reviews (1, 3, 4, 7) | Opus works in the live Claude session | `codex exec --sandbox read-only` → verdict |
| GPT does → Opus reviews (2, 5, 6) | `codex exec` (write-enabled for plan/test; read-only for the review pass) | **fresh Opus subagent**, clean context → verdict |

The fresh Opus subagent is the point: it gives Opus-as-reviewer the same blind-context
independence that `codex exec` already gives GPT-as-reviewer. The reviewer must never be the same
context that watched the artifact being made.

## The Gate (scored)

Every reviewer ends with a **Score / 10** and a **Status**, governed by
[`checklists/scoring-rubric.md`](checklists/scoring-rubric.md):

| Score    | Status   | Meaning                                       |
| -------- | -------- | --------------------------------------------- |
| 9.0–10.0 | APPROVED | Proceed.                                      |
| 8.0–8.9  | BLOCKED  | Close; fix issues / strengthen tests.         |
| 6.0–7.9  | BLOCKED  | Meaningful correctness, design, or test gaps. |
| 0.0–5.9  | BLOCKED  | Failed review; likely needs rework.           |

**Hard caps:** any must-fix issue caps the score at **8.9**; any security, data-loss, or
build/test-breaking issue caps it at **7.9** or lower. A review reaches 9.0+ only when no such
issues remain.

## Folder Layout

| Path                            | Holds                                                                               | Committed?          |
| ------------------------------- | ----------------------------------------------------------------------------------- | ------------------- |
| `README.md`                     | This operating manual.                                                              | yes                 |
| `prompts/`                      | Role charters: `doer.md` (doer), `reviewer.md` (reviewer), `final-release-review.md` (step-7 release gate). | yes |
| `checklists/`                   | `scoring-rubric` (how a reviewer scores), `release-gate`, `implementation`, `review`. | yes               |
| `think/<feature>.md`            | Step 1 — problem framing, assumptions, options, recommendation.                     | yes                 |
| `tasks/<feature>.md`            | One-line-or-short kickoff that seeds step 1 (Goal, Scope, Acceptance, Verification). | yes                |
| `plans/<feature>-plan.md`       | Step 2 — implementation plan in small slices.                                       | yes                 |
| `design/<feature>-design.md`    | Step 3 — architecture, data model, interfaces, flow, test strategy.                 | yes                 |
| `notes/<topic>.md`              | Explore gate (`/gate-explore`) — synthesized Opus+GPT findings; standalone, unscored. | yes               |
| `reviews/<feature>/`            | Numbered scored verdicts + the step-5 review pass.                                  | optional            |
| `handoffs/<feature>-handoff.md` | Step 7 — per-feature handoff + PR text.                                             | yes                 |
| `scratch/`                      | Throwaway working files.                                                            | **no (gitignored)** |
| `runs/`                         | Raw run logs / dumps (incl. step-6 test logs).                                      | **no (gitignored)** |

Slash commands live in `.claude/commands/`. Per-feature reviews are numbered by step; each verdict
records **which model reviewed**:

```
reviews/<feature>/
  01-think-verdict.md         # GPT
  02-plan-verdict.md          # Opus
  03-design-verdict.md        # GPT
  04-build-verdict-1.md       # GPT  (repeats per slice/fix: -2, -3, …)
  05-review-pass.md           # GPT's holistic review (the step-5 artifact)
  05-review-verdict.md        # Opus reviews GPT's review
  06-test-verdict.md          # Opus
  07-ship-verdict.md          # GPT
```

**Step 5 is the only step with two files:** `05-review-pass.md` is GPT's review (the doer's
artifact) and `05-review-verdict.md` is Opus's score of that review. Every other step has a single
`NN-…-verdict.md`.

> `AGENTS.md` at the repo root tells Codex its dual role — reviewer on steps 1/3/4/7, doer on steps
> 2/5/6 — and the scored-verdict format. The automatic stop-time review gate is toggled with
> `/codex:setup --enable-review-gate`.

## How to Run a Feature

```
cp ai/tasks/TEMPLATE.md ai/tasks/<feature>.md       # seed the kickoff, then fill it in

# 1. think   — Opus writes ai/think/<feature>.md (from think/TEMPLATE.md)
/gate1-think  <feature>

# 2. plan    — GPT writes ai/plans/<feature>-plan.md; a fresh Opus subagent scores it
/gate2-plan   <feature>

# 3. design  — Opus writes ai/design/<feature>-design.md
/gate3-design <feature>

# 4. build   — Opus implements ONE slice + local checks in the feature's worktree; repeat until Score >= 9.0
/gate4-build  <feature> <repo> [base-branch]

# 5. review  — GPT does a holistic pass; a fresh Opus subagent scores the review
/gate5-review <feature> <repo>

# 6. test    — GPT authors/runs tests; a fresh Opus subagent scores coverage
/gate6-test   <feature> <repo>

# 7. ship    — Opus drafts PR text in ai/handoffs/<feature>-handoff.md; GPT final-reviews
/gate7-ship   <feature> <repo>   # → at Score >= 9.0, open/merge the PR
```

Each command runs the step's reviewer, saves the scored verdict under `reviews/<feature>/`, and
**stops** — the work advances only at Score >= 9.0.

**Parallel sessions (worktrees).** Steps 4–7 build in a per-feature **git worktree of `<repo>`** —
`<repo>/.worktrees/<feature>` on branch `feature/<feature>` — so several sessions can run different
features at once without colliding on files, the branch, or the index. **Step 4 creates** it (off
`[base-branch]`, default `main` / `feature/focal-migration` for focal), steps 5–7 reuse it, and
**step 7 removes** it after the PR merges (keeping the branch). Invoke the gates exactly as above —
the worktree is derived from `<feature>`. Full convention:
[`checklists/worktree.md`](checklists/worktree.md). Only the code repo is isolated; the `ai/` paper
trail stays in the shared checkout (commit it per feature so sessions don't race on `ai/` git state).

## Prerequisites

- **Codex CLI installed and authenticated** — GPT runs as `codex exec ...` (reviewer and doer).
- **Sandbox per role.** Reviewer steps and the step-5 review pass run `--sandbox read-only` so GPT
  cannot modify the tree. The step-2 plan and step-6 test doer steps run `--sandbox workspace-write`
  so GPT can write the plan / author and run tests. Confirm both flags with `codex --help` for your
  version.
- **Opus reviewer = fresh subagent.** Steps 2/5/6 spawn a clean-context Opus subagent (Agent tool,
  `subagent_type: "claude"`) loading `prompts/reviewer.md`. Never review those steps inline.
- **Git for diffs & worktrees** — steps 4–7 operate on `git diff`. Run the commands from the
  pipeline root (where `ai/` and `.claude/` live) and pass the product repo (e.g. `superapp`) as
  the second argument. Step 4 builds in a per-feature **worktree** of that repo
  (`<repo>/.worktrees/<feature>`, branch `feature/<feature>`); steps 4–7 read/write it with
  `git -C <repo>/.worktrees/<feature>`, and step 7 removes it after merge. See
  [`checklists/worktree.md`](checklists/worktree.md).
- **Model policy** — set your Codex default to the **strongest available model at xhigh reasoning**
  (in `~/.codex`), and run Opus at its highest reasoning. A sub-9.0 verdict blocks the step, so the
  gates deserve the best reviewer on both sides.

## Review Output Format

Every reviewer (Opus or GPT) uses the scored verdict (see `prompts/reviewer.md` and
`checklists/scoring-rubric.md`):

```
# Review Verdict

Reviewer: <Opus | GPT Codex>
Step: <think | plan | design | build | review | test | ship>
Score: X.X / 10
Status: APPROVED or BLOCKED

## Reason
## Must Fix
## Should Consider
## Tests Reviewed
## Release Risk
```

A full worked feature on the retired 5-gate flow is archived at `archive/examples-legacy/auth-refresh/`; a fresh 7-step worked example is a TODO.

## Retired: the legacy 5-gate pipeline

The original unidirectional flow — **Opus builds, GPT reviews** at every gate — has been retired.
Its commands (`gate-task … gate-final`), prompts (`claude-builder.md`, `codex-reviewer.md`),
per-feature verdicts, and the worked example now live under `archive/` for history only. Every
feature now runs on one of the two current flows — the default 3-gate or this 7-step flow.

## What to Commit

- **Commit:** `README.md`, `prompts/`, `checklists/`, `think/` + `tasks/` (meaningful features),
  `plans/` / `design/` (when useful), `reviews/` (if you want audit history), `archive/` (retired
  legacy history). Also `AGENTS.md` at root.
- **Ignore** (see root `.gitignore`): `scratch/`, `runs/`, `transcripts/`, `archive/runs-legacy/`, raw dumps.

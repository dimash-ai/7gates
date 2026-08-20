# Two-Agent Development Pipeline

A disciplined process for building software with two AI coding agents — Claude Code (Opus) and
Codex (GPT) — that check each other's work. This repository is the **orchestration layer**: the
process, prompts, checklists, and house rules the agents follow. It is project-agnostic — point it
at any code repository.

New here? Read in this order: this file → [`PIPELINE_OVERVIEW.md`](PIPELINE_OVERVIEW.md) (the three
flows at a glance) → [`CLAUDE.md`](CLAUDE.md) (the quality bar) → [`ai/README.md`](ai/README.md)
(the full process).

## What this is

Every feature flows through a **7-step pipeline**. Each step has a **doer** and a **reviewer**, and
they alternate between Opus and GPT — so no model ever grades its own work. A step advances only
when the reviewer scores the artifact **≥ 9.0 / 10**; below that, the doer fixes the cited
*Must Fix* items and resubmits.

| # | Step | Doer | Reviewer | Artifact |
|---|------|------|----------|----------|
| 1 | think  | **Opus** | GPT  | `ai/think/<feature>.md` |
| 2 | plan   | **GPT**  | Opus | `ai/plans/<feature>-plan.md` |
| 3 | design | **Opus** | GPT  | `ai/design/<feature>-design.md` |
| 4 | build  | **Opus** | GPT  | code diff in the target repo |
| 5 | review | **GPT**  | Opus | `ai/reviews/<feature>/05-review-pass.md` |
| 6 | test   | **GPT**  | Opus | tests + `ai/runs/<feature>-test.txt` |
| 7 | ship   | **Opus** | GPT  | `ai/handoffs/<feature>-handoff.md` + PR |

Full operating manual, folder layout, and scoring rules: [`ai/README.md`](ai/README.md).

## House rules

All work — by humans or agents — holds to four principles (full text in [`CLAUDE.md`](CLAUDE.md)):

1. **Think before coding** — state assumptions, surface tradeoffs, ask when unclear.
2. **Simplicity first** — minimum code that solves the problem; nothing speculative.
3. **Surgical changes** — touch only what the task needs; match existing style.
4. **Goal-driven execution** — define success criteria, loop until verified.

[`AGENTS.md`](AGENTS.md) tells Codex its dual doer/reviewer role and the scored-verdict format.

## Layout

| Path | Holds |
|------|-------|
| [`ai/`](ai/)         | The pipeline: prompts, checklists, and per-feature think / plan / design / reviews / handoffs |
| `.claude/`             | Slash commands (`/gate1-think` … `/gate7-ship`) and local settings |
| [`CLAUDE.md`](CLAUDE.md) | House rules — the always-on quality bar |
| [`AGENTS.md`](AGENTS.md) | Codex's doer/reviewer conventions |
| `Makefile`             | Verification gates — `make verify` runs test, lint, typecheck, build |

## Running a feature

From the repo root, run each step as a slash command in Claude Code. Where shown, the second
argument is the target repository that holds the diff:

```
/gate1-think  <feature>
/gate2-plan   <feature>
/gate3-design <feature>
/gate4-build  <feature> <repo>
/gate5-review <feature> <repo>
/gate6-test   <feature> <repo>
/gate7-ship   <feature> <repo>
```

Each command runs the step's reviewer, saves a scored verdict under `ai/reviews/<feature>/`, and
**stops** — work advances only at score ≥ 9.0. See
[`ai/README.md`](ai/README.md) for the kickoff template and per-step detail.

## Prerequisites

- **Claude Code** (Opus) — doer/reviewer on steps 1, 3, 4, 7; fresh-subagent reviewer on steps 2, 5, 6.
- **Codex CLI**, authenticated — GPT runs as `codex exec` (doer on 2/5/6, read-only reviewer on 1/3/4/7).
- **Make** — `make verify` is the umbrella verification gate. The targets currently ship as stubs;
  wire each one to your stack's real test / lint / typecheck / build command.
- **Git** — steps 4–7 operate on the `git diff` of the target repo.

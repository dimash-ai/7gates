# Two-Agent Development Pipeline

A disciplined process for building software with two AI coding agents — Claude Code (Opus) and
Codex (GPT) — that check each other's work. This repository is the **orchestration layer**: the
process, prompts, checklists, and house rules the agents follow. The work itself, and every result
the pipeline produces, lives in the code repository it points at.

New here? Read in this order: this file → [`PIPELINE_OVERVIEW.md`](PIPELINE_OVERVIEW.md) (all the
flows at a glance) → [`CLAUDE.md`](CLAUDE.md) (the quality bar) → [`harness/README-codev.md`](README-codev.md)
(the live flow in full).

## What this is

Every feature flows through the **co-dev flow**, which ships in **stages**: the smallest increments a
user can see, each its own PR into `dev`, merged, deployed and looked at on the dev environment
before the next one starts. The two models trade places, so no model ever grades its own work, and
a review blocks only on ship-blockers; everything else becomes a follow-up you decide on.

| # | Step | Does | Checks | Result |
|---|------|------|--------|--------|
| 1 | brief | **Opus** rephrases your input (your words or a Linear ticket) into a short brief: the problem, the user stories, **the MVP**; minutes, not hours | **you** | `specs/<slug>/brief.md` |
| 2 | plan  | **GPT** plans every stage, cold, from the brief and the code | Opus, inline; then **you** | `specs/<slug>/plan.md` |
| 3 | build, once per stage | **Opus** implements the next stage, no layers inside; its own PR into `dev`, verified on dev; registers the hypothesis in PostHog | your checks and CI; **GPT** for a data or auth stage, and once before main | a PR per stage, verified on dev |
| — | learn, weekly | **Opus** measures every shipped hypothesis in PostHog; **Opus and GPT** judge independently | **you** | verdicts in PostHog |

Results land in the code repo's gitignored `specs/<slug>/` (for superapp, `superapp/specs/`), never
in this repo. [ponytail](https://github.com/DietrichGebert/ponytail)'s reuse-first ladder and
over-engineering review run through all three steps from one pinned file,
[`harness/checklists/ponytail.md`](checklists/ponytail.md). Full manual:
[`harness/README-codev.md`](README-codev.md).

## House rules

All work — by humans or agents — holds to four principles (full text in [`CLAUDE.md`](CLAUDE.md)):

1. **Think before coding** — state assumptions, surface tradeoffs, ask when unclear.
2. **Simplicity first** — minimum code that solves the problem; nothing speculative.
3. **Surgical changes** — touch only what the task needs; match existing style.
4. **Goal-driven execution** — define success criteria, loop until verified.

[`AGENTS.md`](AGENTS.md) tells Codex its roles and the scored-verdict format.

## Layout

| Path | Holds |
|------|-------|
| [`harness/`](./)         | The pipeline: charters, checklists, templates, and the manuals for every flow |
| `.claude/`             | Slash commands (`/step1`, `/step2`, `/step3`, `/learn`, and the older flows') and local settings |
| [`CLAUDE.md`](CLAUDE.md) | House rules — the always-on quality bar |
| [`AGENTS.md`](AGENTS.md) | Codex's roles and verdict conventions |
| `Makefile`             | Verification gates — `make verify` runs test, lint, typecheck, build |

## Running a feature

In Claude Code, from superapp, one of its worktrees, or the harness itself (`superapp/harness`):

```
/step1 <slug>    # brief — your request rephrased, with the MVP; no stop unless it must ask
                 # plan  — GPT plans the stages (Opus alone in the quick lane); ONE stop: brief + stages
                 # build — then stage after stage: implemented, its PR into dev, verified on dev
/step3 <slug>    # resume a run, or release the stages to main when you say so
/learn           # learn — weekly: checks every shipped hypothesis against what users did
```

`<slug>` is the Linear id when there is an issue (`ALL-646`). The stage rules every step follows are
in [`harness/checklists/mvp.md`](checklists/mvp.md); each command prints the progress board and
**stops** where you are needed. See [`harness/README-codev.md`](README-codev.md)
for where it stops and why.

The other flows are documented in [`PIPELINE_OVERVIEW.md`](PIPELINE_OVERVIEW.md): `/gate-explore`
for epic-level research and the GPT gates for tickets that run through the CTO's feature-dev
cycle. The 3-gate and 7-step commands were removed on 2026-09-24.

## Prerequisites

- **Claude Code** (Opus) — author of the brief in step 1, checker of the plan in step 2, builder in
  step 3.
- **Codex CLI**, authenticated — GPT runs as `codex exec`: planner in step 2 (read-only), reviewer
  in step 3 of data and auth stages and of a release to main that carries one (write-enabled only so
  it can reproduce a finding; CI runs the checks).
- **Git ≥ 2.31** and **`gh`** — step 2 pins a worktree of the code repo, step 3 builds each stage in
  it and opens its PR.
- **Make** — `make verify` is the umbrella verification gate for code repos that use it. The
  targets ship as stubs; superapp's checks come from its CI workflows
  (`.github/workflows/ci-<app>.yml`) instead.

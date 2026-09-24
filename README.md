# Two-Agent Development Pipeline

A disciplined process for building software with two AI coding agents — Claude Code (Opus) and
Codex (GPT) — that check each other's work. This repository is the **orchestration layer**: the
process, prompts, checklists, and house rules the agents follow. The work itself, and every result
the pipeline produces, lives in the code repository it points at.

New here? Read in this order: this file → [`PIPELINE_OVERVIEW.md`](PIPELINE_OVERVIEW.md) (all the
flows at a glance) → [`CLAUDE.md`](CLAUDE.md) (the quality bar) → [`harness/README-codev.md`](harness/README-codev.md)
(the live flow in full).

## What this is

Every feature flows through the **3-step co-dev flow**. The two models trade places, so no model
ever grades its own work, and a scored step advances only at **≥ 9.0 / 10**; below that, the doer
fixes the cited *Must Fix* items and resubmits.

| # | Step | Does | Checks | Result |
|---|------|------|--------|--------|
| 1 | brief | **Opus and GPT**, independently: research the intent; Opus merges | **you** | `specs/<slug>/brief.md` |
| 2 | plan  | **GPT**, cold, from the brief | Opus, blind | `specs/<slug>/plan.md` |
| 3 | build | **Opus**, one slice at a time | GPT per slice, then GPT runs the checks itself | code + PR |

Results land in the code repo's gitignored `specs/<slug>/` (for superapp, `superapp/specs/`), never
in this repo. [ponytail](https://github.com/DietrichGebert/ponytail)'s reuse-first ladder and
over-engineering review run through all three steps from one pinned file,
[`harness/checklists/ponytail.md`](harness/checklists/ponytail.md). Full manual:
[`harness/README-codev.md`](harness/README-codev.md).

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
| [`harness/`](harness/)         | The pipeline: charters, checklists, templates, and the manuals for every flow |
| `.claude/`             | Slash commands (`/step1`, `/step2`, `/step3`, and the older flows') and local settings |
| [`CLAUDE.md`](CLAUDE.md) | House rules — the always-on quality bar |
| [`AGENTS.md`](AGENTS.md) | Codex's roles and verdict conventions |
| `Makefile`             | Verification gates — `make verify` runs test, lint, typecheck, build |

## Running a feature

In Claude Code, from anywhere at or under the pipeline root (the code repo, one of its worktrees, or
the root itself):

```
/step1 <slug>    # brief — you + Opus; Opus and GPT research; you approve the brief
/step2 <slug>    # plan  — GPT plans; a blind Opus scores it
/step3 <slug>    # build — once per slice; the last run does the release pass and opens the PR
```

`<slug>` is the Linear id when there is an issue (`ALL-646`). Each scored command saves its verdict
under `specs/<slug>/reviews/` and **stops**. See [`harness/README-codev.md`](harness/README-codev.md)
for where it stops and why.

The other flows still run and are documented in [`PIPELINE_OVERVIEW.md`](PIPELINE_OVERVIEW.md):
`/gate-explore` for epic-level research, the GPT gates for tickets that run through the CTO's
feature-dev cycle, and the superseded 3-gate and 7-step flows.

## Prerequisites

- **Claude Code** (Opus) — researcher and brief author in step 1, blind plan reviewer (a fresh
  subagent) in step 2, builder in step 3.
- **Codex CLI**, authenticated — GPT runs as `codex exec`: researcher in step 1 (read-only, with
  web search), planner in step 2 (read-only), reviewer in step 3 (read-only per slice;
  write-enabled for the release pass only so it can run the checks).
- **Git ≥ 2.31** and **`gh`** — step 1 pins a worktree of the code repo, step 3 builds in it and
  opens the PR.
- **Make** — `make verify` is the umbrella verification gate for code repos that use it. The
  targets ship as stubs; superapp's checks come from its CI workflows
  (`.github/workflows/ci-<app>.yml`) instead.

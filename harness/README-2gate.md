# The 2-Gate Co-Dev Flow

> **Superseded for superapp work (2026-08-20).** New features enter through the feature-dev cycle
> with the two cross-model gates — see [`README-gpt-gates.md`](README-gpt-gates.md). This flow's
> charters and rubric are still live; its doer commands have no active consumer.

**Two gates, the two models trading places.** GPT plans, Opus reviews the plan; Opus builds, GPT
reviews the build. It's the shortest flow that still keeps the load-bearing property intact — *no
model ever grades its own work* — and each model does the half it's strongest at.

## Why two gates

The 3-gate flow ([`README-3gate.md`](README-3gate.md)) splits verification into its own gate with its
own doer. That's the right shape when the change is risky enough that you want the *tests* written by
someone other than the builder. Most changes aren't. This flow collapses design and verification into
the two gates that always matter — **agree on what to build, then build it under review** — and pays
for the shortcut in exactly one place (see the tradeoff below).

## The two gates

| Gate | What it produces | Doer | Reviewer | Artifact |
|------|------------------|------|----------|----------|
| **1 — plan**  | The complete plan — the decision, the slices, the architecture, the test strategy — as one document the builder works from alone. | **GPT** | Opus | `design/<f>-design.md` |
| **2 — build** | The implementation slice by slice, its tests, and the PR. | **Opus** | GPT | code diff + `handoffs/<f>-handoff.md` + PR |

The doer alternates strictly: **GPT → Opus**. GPT plans cold against the repo, with no memory of the
conversation that produced the request; Opus builds in the live session where that context lives.

## How the two directions run

| Direction | Doer mechanism | Reviewer mechanism |
|-----------|----------------|--------------------|
| GPT does → Opus reviews (1) | `codex exec --sandbox workspace-write` writes the design doc | **fresh Opus subagent**, clean context → verdict |
| Opus does → GPT reviews (2) | Opus builds + tests each slice in the feature's worktree | `codex exec --sandbox read-only` per slice; `--sandbox workspace-write` for the final release pass, so GPT **runs the suite itself** → verdict |

The reviewer always runs blind — a separate `codex exec` process for GPT, a fresh clean-context
subagent for Opus — so it never grades an artifact it watched being made.

## The tradeoff — read this before choosing this flow

**The builder writes its own tests.** GPT reviews them and re-runs the suite at the release pass, but
it never *authors* an independent test. That's the one property the 3-gate's verify gate buys and
this flow doesn't.

Use the 2-gate when the change is ordinary — features, fixes, UI work, anything whose failure modes
the plan can name up front. Reach for the **3-gate** when a wrong test is as dangerous as wrong code:
migrations and data backfills, auth/authz and tenant isolation, money, or anything where "the tests
pass" is the only evidence anyone will ever look at.

## How to run a feature

```
cp harness/tasks/TEMPLATE.md harness/tasks/<feature>.md   # OPTIONAL kickoff — the plan is self-contained; seed one only if it helps

/codev-plan   <feature> [repo]                  # 1 — GPT writes the plan; a blind Opus subagent scores it
/codev-build  <feature> [repo] [base-branch]    # 2 — Opus builds one slice; GPT scores it; repeat, then release + ship
```

Both `[repo]` arguments default to **`superapp`**, the only code repo under the pipeline root — so in
practice the flow is `/codev-plan <feature>` then `/codev-build <feature> dev`. Pass a repo path
explicitly only when a second code repo lands beside it.

Gate 1 writes `design/<feature>-design.md` from [`design/TEMPLATE-3gate.md`](design/TEMPLATE-3gate.md)
— the **same** artifact the 3-gate's gate A produces, so a plan approved here can also be built by
`/gate-build` and verified by `/gate-verify` if you decide mid-flight that the change deserves the
third gate. Each command saves its scored verdict under `reviews/<feature>/` and **stops** — work
advances only at Score `>= 9.0`.

**Base branch, worktree & commits.** Gate 2 builds in the feature's own worktree
(`<repo>/.worktrees/<feature>` on `feature/<feature>`, per
[`checklists/worktree.md`](checklists/worktree.md)) and **commits each approved slice** there, so
several features can run in parallel. `[base-branch]` (default `main`) is what the branch forks from,
what the release pass diffs against (`<base>...HEAD`), and what the PR targets — pass it explicitly.

**GPT is offline.** The codex sandbox has no network, so gate 1's plan can't verify a library API or
a pinned version. That's the Opus reviewer's job at gate 1: every version-sensitive claim gets checked
against the repo's pins and the real docs before any code is written — the exact failure mode root
`CLAUDE.md` calls out under "AI agents — follow the documented stack, not training memory".

## Verdict files

```
reviews/<feature>/
  1-plan-verdict.md          # Opus scores GPT's plan          (re-score: -2, -3, …)
  2-build-verdict-1.md       # GPT scores each build slice     (per slice / per fix: -2, -3, …)
  2-release-verdict.md       # GPT scores the whole change + clears release
```

## What each gate guarantees

- **The plan is adversarially reviewed before any code** (gate 1), by the model that didn't write it.
- **Every slice is reviewed on its own** (gate 2), so defects surface per-slice, not in a pile.
- **The release pass is a real verification, not a re-read** (gate 2, final): GPT runs the repo's
  checks itself in a write-enabled sandbox and reports the actual counts, so an approval never rests
  on the builder's own claim that the suite was green.

This flow uses the repository's shared quality infrastructure unchanged: the doer & reviewer charters
in [`prompts/`](prompts/), the [`checklists/scoring-rubric.md`](checklists/scoring-rubric.md) scoring,
the worktree contract, and the folder layout.

---

> **See also:** [`README-3gate.md`](README-3gate.md) — the default flow, with verification as its own
> gate. [`README-7step.md`](README-7step.md) — the 7-step flow, for when you want the finest checkpoints.

# Pipeline Overview — the ways to run it

This repository is a **two-agent development pipeline**: every feature is built by one AI coding
agent and checked by the other — **Opus** (Claude Code) and **GPT** (Codex) — so no model ever
grades its own work. **One flow is live for our own work**, the co-dev flow, which ships in
stages. The others still run, for the cases named below. This page explains what each is and when
to reach for it.

## The shared foundation

All of the build flows rest on the same three rules:

- **Every scored step has a doer and a reviewer, and they are always different models.** The doer
  produces the artifact; the reviewer is the *other* model.
- **The reviewer scores the artifact out of 10 — work advances only at ≥ 9.0.** Below that, the
  reviewer returns cited *Must Fix* items, the doer fixes exactly those (no scope creep), and
  resubmits for a re-score. Scoring is governed by
  [`harness/checklists/scoring-rubric.md`](checklists/scoring-rubric.md). In the co-dev flow's
  **stage mode**, a Must Fix is only a ship-blocker
  ([`harness/checklists/mvp.md`](checklists/mvp.md) §5), everything else becomes a follow-up, and
  a BLOCK is fixed and goes on with CI as its proof, re-scored only for a security or data item.
- **The reviewer runs "blind"** (one exception: in the co-dev flow Opus checks GPT's plan inline,
  for speed, and the requester's yes is the last word). GPT reviews in a separate `codex exec`
  process; Opus reviews from a fresh, clean-context subagent. The reviewer never grades an artifact
  it watched being built.

Both roles work to the four house-rule principles in [`CLAUDE.md`](CLAUDE.md) — Think Before Coding,
Simplicity First, Surgical Changes, Goal-Driven Execution.

---

## 1 · The co-dev flow, in stages — **the default**

A request becomes a short brief with a hypothesis and its MVP, the brief becomes a plan of
stages, and every stage becomes its own PR into dev, verified on the dev environment before the next
one starts; a weekly `/learn` checks every shipped hypothesis against what users did.

| Step | Produces | Does | Checks |
|------|----------|------|--------|
| **1 — brief** | One short document: the request rephrased for the planner, with the problem, the user stories, the MVP and Not now | **Opus**, in minutes | **you**, at step 2's one stop |
| **2 — plan**  | The stage map (outcome on dev, demo, budget, risk, guard) and every stage's detail | **GPT** plans, cold, from the brief and the code (**Opus** alone in the quick lane) | Opus, inline; then **you**, brief and plan in one stop |
| **3 — build, once per stage** | The stage, implemented with no layers inside, its PR merged into dev and verified there; the release to main when you say; the hypothesis registered in PostHog | **Opus** | CI; **GPT** for data/auth stages and a release that carries one |
| **learn — weekly** | A verdict on every shipped hypothesis, and what is in demand | **Opus** measures in PostHog; **Opus and GPT** judge independently | **you** |

Step 1 is not scored: the only judge of an intent is the person who has it. GPT's independent
reading comes in step 2, where it plans cold from the brief, so a brief that does not stand on its
own comes back as questions. Every result lands in the code repo's gitignored
`specs/<slug>/`. [ponytail](https://github.com/DietrichGebert/ponytail)'s ladder and
over-engineering review run through all three steps from
[`harness/checklists/ponytail.md`](checklists/ponytail.md). Full detail:
[`harness/README-codev.md`](README-codev.md).

---

## 2 · `/gate-explore` — standalone reconnaissance, *unscored*

**Not a build flow, and deliberately not scored.** Two models sweep the codebase independently for
what a planner needs to know before designing anything (Territory, Prior art, Constraints, Scars,
Tests, Absences), and the union becomes one dossier, with contradictions and gaps flagged. Reach
for it for an epic or an open question, before step 1 of the co-dev flow; a single task needs no
sweep, because the co-dev planner reads the code it plans against. Command:
[`/gate-explore`](.claude/commands/gate-explore.md).

---

## 3 · The GPT gates — for tickets in the CTO's feature-dev cycle

When a ticket runs through the CTO's feature-dev harness (architect → coder → qa, all Claude), two
Codex gates bolt onto it: **α** scores the architect's plan before any code exists, **γ** runs the
suite itself before ship. Full detail: [`harness/README-gpt-gates.md`](README-gpt-gates.md).

---

## 4 · Superseded — no new work

- **2-gate** ([`harness/README-2gate.md`](README-2gate.md)): GPT plans, Opus builds. The
  co-dev flow grew out of it and rewrote its two commands, so it no longer runs as documented; the
  document stays as the record of the design.
- **3-gate** ([`harness/README-3gate.md`](README-3gate.md)): design / build / verify, with GPT
  authoring the verification. Its commands were removed on 2026-09-24; the document stays as the
  record.
- **7-step** ([`harness/README-7step.md`](README-7step.md)): think / plan / design / build /
  review / test / ship, strict alternation, GPT authoring the tests blind to its own review. Its
  commands were removed on 2026-09-24; the document stays as the record.

The 3-gate and 7-step flows were the ones where GPT, not the builder, wrote the tests.

---

## Which one, when

```
open question or epic, no code yet    →  /gate-explore   (unscored dossier)
a task of ours                        →  co-dev          DEFAULT: brief / plan / build, in stages
every week, after things ship         →  /learn          verdicts on the bets, demand board
a ticket in the feature-dev cycle     →  GPT gates       α before code, γ before ship
```

> **Heads-up on terminology:** an earlier **5-gate** flow ("Opus builds, GPT reviews at every gate")
> has been **retired**. If you see "5-gate" referenced anywhere, that's the deprecated design.

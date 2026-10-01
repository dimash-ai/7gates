# Pipeline Overview — the ways to run it

This repository is a **two-agent development pipeline**: every feature is built by one AI coding
agent and checked by the other — **Opus** (Claude Code) and **GPT** (Codex) — so no model ever
grades its own work. **One flow is live for our own work**, the 3-step co-dev flow. The others still
run, for the cases named below. This page explains what each is and when to reach for it.

## The shared foundation

All of the build flows rest on the same three rules:

- **Every scored step has a doer and a reviewer, and they are always different models.** The doer
  produces the artifact; the reviewer is the *other* model.
- **The reviewer scores the artifact out of 10 — work advances only at ≥ 9.0.** Below that, the
  reviewer returns cited *Must Fix* items, the doer fixes exactly those (no scope creep), and
  resubmits for a re-score. Scoring is governed by
  [`harness/checklists/scoring-rubric.md`](checklists/scoring-rubric.md).
- **The reviewer always runs "blind."** GPT reviews in a separate `codex exec` process; Opus reviews
  from a fresh, clean-context subagent. The reviewer never grades an artifact it watched being
  built.

Both roles work to the four house-rule principles in [`CLAUDE.md`](CLAUDE.md) — Think Before Coding,
Simplicity First, Surgical Changes, Goal-Driven Execution.

---

## 1 · The 3-step co-dev flow — **the default**

A request becomes a brief, the brief is researched and becomes a plan, the plan becomes code.

| Step | Produces | Does | Checks |
|------|----------|------|--------|
| **1 — brief** | One document stating the problem and the business task from the user's side: in short, user stories with numbered criteria, who benefits, the business side | **Opus and GPT** draft it independently; Opus merges | **you** |
| **2 — plan**  | The research merged into that brief, then the complete plan: slices, new surface by ladder rung, architecture, test strategy | **Opus and GPT** research independently, Opus merges; then **GPT** plans, cold | Opus |
| **3 — build** | The implementation, one slice at a time, then a release pass and the PR | **Opus** | GPT |

Step 1 and the research of step 2 are not scored: two independent drafts, then two independent
sweeps, buy **coverage**, so each pair merges as a union, and the only judge of an intent is the
person who has it. Every result lands in the code repo's gitignored
`specs/<slug>/`. [ponytail](https://github.com/DietrichGebert/ponytail)'s ladder and
over-engineering review run through all three steps from
[`harness/checklists/ponytail.md`](checklists/ponytail.md). Full detail:
[`harness/README-codev.md`](README-codev.md).

---

## 2 · `/gate-explore` — standalone reconnaissance, *unscored*

**Not a build flow, and deliberately not scored.** Two models sweep the codebase independently for
what a planner needs to know before designing anything (Territory, Prior art, Constraints, Scars,
Tests, Absences), and the union becomes one dossier, with contradictions and gaps flagged. Reach
for it on its own for an epic or an open question; for a single task, step 2 of the co-dev flow runs
the same kind of sweep and merges it into the brief. Command:
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
a task of ours                        →  3-step co-dev   DEFAULT: brief / plan / build
a ticket in the feature-dev cycle     →  GPT gates       α before code, γ before ship
```

> **Heads-up on terminology:** an earlier **5-gate** flow ("Opus builds, GPT reviews at every gate")
> has been **retired**. If you see "5-gate" referenced anywhere, that's the deprecated design.

# Pipeline Overview — the three ways to run it

This repository is a **two-agent development pipeline**: every feature is built by one AI coding
agent and checked by the other — **Opus** (Claude Code) and **GPT** (Codex) — so no model ever
grades its own work. There are **three setups** you actually invoke, at three different
granularities. This page explains what each is and when to reach for it.

## The shared foundation

All of the build flows rest on the same three rules:

- **Every step has a doer and a reviewer, and they are always different models.** The doer produces
  the artifact; the reviewer is the *other* model.
- **The reviewer scores the artifact out of 10 — work advances only at ≥ 9.0.** Below that, the
  reviewer returns cited *Must Fix* items, the doer fixes exactly those (no scope creep), and
  resubmits for a re-score. Scoring is governed by
  [`ai/checklists/scoring-rubric.md`](ai/checklists/scoring-rubric.md).
- **The reviewer always runs "blind."** GPT reviews in a separate read-only `codex exec` process;
  Opus reviews from a fresh, clean-context subagent. The reviewer never grades an artifact it
  watched being built.

Both roles work to the four house-rule principles in [`CLAUDE.md`](CLAUDE.md) — Think Before Coding,
Simplicity First, Surgical Changes, Goal-Driven Execution.

---

## 1 · `/gate-explore` — the standalone, *unscored* gate

The odd one out: **not a build flow, and deliberately not scored.** Its job is to turn open
questions into grounded answers by getting **two independent perspectives** before any code exists.

1. **Opus answers first, independently** — and owns all external research (library docs, web),
   because GPT runs offline in the next step.
2. **GPT answers the same questions, blind** to Opus's answer.
3. The two are **synthesized** into a small findings note — organized as
   **consensus / divergence / open questions**.

Why no doer/reviewer here: brainstorming is the opposite of adversarial review — the value is two
*independent* takes converging or disagreeing, so both models answer and nobody scores. The output
can later seed a build flow, or just stand on its own. Command:
[`/gate-explore`](.claude/commands/gate-explore.md).

---

## 2 · The 3-gate flow — **the default**

A feature has three real phases — **decide what to build → build it → prove it's right** — and this
flow gives each phase exactly one stop-and-score checkpoint.

| Gate | Produces | Doer | Reviewer |
|------|----------|------|----------|
| **A — design**  | The complete design (decision + build slices + architecture) in one doc | **Opus** | GPT |
| **B — build**   | The implementation, one independently reviewable slice at a time | **Opus** | GPT |
| **C — verify**  | Proof the change is correct and tested, then the PR | **GPT** | Opus |

Two invariants are load-bearing: **doer ≠ reviewer at every gate**, and **the builder never verifies
its own code** — Opus builds (B), GPT verifies (C). The doer sequence is deliberately
Opus → Opus → GPT (not strict alternation) so each model lands on its strongest work: Opus on design
and large-repo building, GPT on adversarial verification and test authorship. Gate C doubles as the
**release gate**. Full detail: [`ai/README-3gate.md`](ai/README-3gate.md).

---

## 3 · The 7-step flow — the **higher-granularity** peer

The same principles, with the three phases broken into **seven separately-scored steps** that
alternate doer/reviewer more finely.

| # | Step | Doer | Reviewer |
|---|------|------|----------|
| 1 | think  | **Opus** | GPT  |
| 2 | plan   | **GPT**  | Opus |
| 3 | design | **Opus** | GPT  |
| 4 | build  | **Opus** | GPT  |
| 5 | review | **GPT**  | Opus |
| 6 | test   | **GPT**  | Opus |
| 7 | ship   | **Opus** | GPT  |

Two things this granularity buys you that the 3-gate collapses:

- **Step 4 vs Step 5 are distinct.** Step 4 gates each build *slice* for correctness; step 5 is one
  *holistic, whole-change* adversarial sweep. Per-slice gate vs cross-cutting review.
- **The test author is isolated.** GPT writes the tests (step 6) — not the Opus builder, and blind to
  its own step-5 review findings. "The builder doesn't grade its own homework," taken one step
  further than the 3-gate does.

Full operating manual, folder layout, and worked commands: [`ai/README.md`](ai/README.md).

---

## Which one, when

```
/gate-explore   →  open question, no code yet     →  builds shared context (unscored)
     │
     ├─ 3-gate   →  DEFAULT. design / build / verify →  3 scored passes, short cycle
     └─ 7-step   →  when you want finer checkpoints   →  7 scored passes, max isolation
```

- **3-gate and 7-step are peers, not a hierarchy.** 3-gate is the default pick; escalate to 7-step
  only when the extra checkpoints earn their cost (e.g. you specifically want the test author
  isolated from the review step).
- **`/gate-explore` is orthogonal** to both — a context-building pre-step you can run before either,
  or skip entirely.

> **Heads-up on terminology:** an earlier **5-gate** flow ("Opus builds, GPT reviews at every gate")
> has been **retired**. If you see "5-gate" referenced anywhere, that's the deprecated design,
> superseded by the two current flows above.

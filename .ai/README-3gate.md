# The 3-Gate Flow

The **default** development pipeline: **three gates, each one integrated scored pass.** It lands a
feature quickly without giving up the two properties the work depends on — *the builder never grades
its own homework*, and *no model reviews its own work*. Each gate is scored `>= 9.0` by the opposite
model before the work advances.

## Why three gates

A feature has three real phases — **decide what to build, build it, prove it's right** — and this
flow gives each phase exactly one stop-and-score checkpoint instead of breaking it into a chain of
sub-steps. That keeps the cycle short: one design pass, per-slice builds, one verification pass. The
adversarial alternation still holds at every gate, so the shorter path costs nothing in rigor.

## The three gates

| Gate | What it produces | Doer | Reviewer | Artifact |
|------|------------------|------|----------|----------|
| **A — design**  | The complete design — the decision, the build approach in slices, and the architecture — in one document. | **Opus** | GPT  | `design/<f>-design.md` |
| **B — build**   | The implementation, one independently reviewable slice at a time. | **Opus** | GPT  | code diff in repo |
| **C — verify**  | Proof the change is correct and tested, then the PR. | **GPT**  | Opus | `reviews/<f>/C-verify-report.md` + tests + `handoffs/<f>-handoff.md` + PR |

Two invariants are load-bearing — **doer ≠ reviewer at every gate**, and **the builder never
verifies its own code**: **Opus builds (B)**, **GPT verifies (C)**. The doer sequence is
Opus → Opus → GPT, deliberately not a strict alternation, so each model lands on its strongest work:
Opus on design + large-repo build, GPT on adversarial verification + tests.

## How the two directions run

| Direction | Doer mechanism | Reviewer mechanism |
|-----------|----------------|--------------------|
| Opus does → GPT reviews (A, B) | Opus works in the live Claude session (in B: build one slice + local checks) | `codex exec --sandbox read-only` → verdict |
| GPT does → Opus reviews (C)    | `codex exec --sandbox workspace-write` (GPT verifies the whole change + writes/runs tests) | **fresh Opus subagent**, clean context, release-gate charter → verdict; then Opus drafts the PR & ships on APPROVED |

The reviewer always runs in blind context — a separate `codex exec` process for GPT, a fresh
clean-context subagent for Opus — so it never grades an artifact it watched being made.

## How to run a feature

```
cp .ai/tasks/TEMPLATE.md .ai/tasks/<feature>.md   # OPTIONAL kickoff — the design doc is self-contained; seed one only if it helps

/gate-design  <feature>                       # A — Opus writes the design doc; GPT scores it
/gate-build   <feature> <repo> [base-branch]  # B — Opus builds + commits one slice at a time in the feature's worktree; GPT scores each; repeat
/gate-verify  <feature> <repo> [base-branch]  # C — GPT verifies the whole change + writes tests; Opus scores it, then ships
```

Gate A uses `.ai/design/TEMPLATE-3gate.md` (one topic-structured design doc). The kickoff task is
**optional** — the design doc stands alone. Each command saves its scored verdict under
`reviews/<feature>/` and **stops** — work advances only at Score `>= 9.0`.

**Base branch & commits.** Gate B **commits each approved slice** on `feature/<feature>` (in the
feature's worktree); gate C diffs the committed change against `[base-branch]` (the 3rd arg —
**default `main`; `feature/focal-migration` for focal slices**, since those branch off the
integration branch, not `main`). GPT's verify runs in a `workspace-write` sandbox **scoped to the
feature's worktree `<repo>/.worktrees/<feature>`**, a different git repo than the pipeline's `.ai/`
tree — so GPT **prints** its verification report and Opus saves it to
`reviews/<feature>/C-verify-report.md`; GPT never writes `.ai/` directly.

**Parallel sessions (worktrees).** Each feature builds in its **own git worktree of `<repo>`** —
`<repo>/.worktrees/<feature>` on branch `feature/<feature>` — so several sessions can run different
features at once without colliding on files, the branch, or the index. **Gate B creates** it (off
`[base-branch]`), every later gate reuses it, and **gate C removes** it after the PR merges (keeping
the branch). Invoke the gates exactly as above — the worktree is derived from `<feature>`. Full
convention: [`checklists/worktree.md`](checklists/worktree.md). Only the code repo is isolated; the
`.ai/` paper trail stays in the shared checkout (commit it per feature so sessions don't race on
`.ai/` git state).

## Verdict files

Verdicts are letter-prefixed (A / B / C) so each gate's record stays unambiguous:

```
reviews/<feature>/
  A-design-verdict.md         # GPT  (re-score: -2, -3, …)
  B-build-verdict-1.md        # GPT  (per slice / per fix: -2, -3, …)
  C-verify-report.md          # GPT's verification report (the doer's artifact)
  C-verify-verdict.md         # Opus scores the verification + clears release
```

## What each gate guarantees

Each gate is a full checkpoint, not a shortcut — every safety property holds:

- **Design is adversarially reviewed before any code** (gate A), so build never starts on a shaky plan.
- **Every build slice is reviewed on its own** (gate B), so defects are caught per-slice, not in a pile.
- **Verification is done by the other model** (gate C) and doubles as the **release gate** — its Opus
  reviewer runs the `final-release-review` charter before the PR opens.

This flow uses the repository's shared quality infrastructure unchanged: the doer & reviewer charters
in `prompts/`, the `checklists/scoring-rubric.md` scoring, the folder layout, and the commit policy.

---

> **See also:** a higher-granularity variant with seven separate checkpoints lives in
> [`README.md`](README.md), for when you want the test author blind to its own review findings. It's
> the alternative to this default — the two flows are peers; reach for the 7-step only when you need
> the finer granularity.

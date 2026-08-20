# harness — the two-agent development methodology

Everything we know about making **Opus (Claude Code)** and **GPT (Codex)** build software
together, in one place. Four flows share one set of charters, one scoring rubric, and one verdict
home; they differ only in how many times the work stops to be graded, and by whom.

The invariant every flow is built to protect:

> **No model grades its own work.** Not "a different agent" — a different *vendor*. The reviewer
> always runs blind: a separate `codex exec` process for GPT, a fresh clean-context subagent for
> Opus, so it never scores an artifact it watched being made.

Work advances only at **Score >= 9.0** ([`checklists/scoring-rubric.md`](checklists/scoring-rubric.md)).

## The four flows

| Flow | Status | Gates | Who does / who reviews | Entry |
|---|---|---|---|---|
| **[GPT gates](README-gpt-gates.md)** | **live** | 2, spliced into the CTO's feature-dev cycle | Claude `architect → coder → qa` builds; **Codex** scores the plan and runs the release suite | `/gpt-gate-plan` · `/gpt-gate-release` |
| **[2-gate](README-2gate.md)** | superseded | plan · build | GPT plans → Opus reviews; Opus builds → GPT reviews | `/codev-plan` · `/codev-build` |
| **[3-gate](README-3gate.md)** | superseded | design · build · verify | Opus does A+B, GPT does C; each scored by the other | `/gate-design` · `/gate-build` · `/gate-verify` |
| **[7-step](README-7step.md)** | superseded | think · plan · design · build · review · test · ship | strict alternation, Opus ⇄ GPT at every step | `/gate1-think` … `/gate7-ship` |

**Superseded means retired-from-new-work, not broken.** All three still run, and their charters are
the ones the live flow calls. Nothing was deleted.

## Which one to reach for

- **Default — GPT gates.** superapp ships through the CTO's feature-dev cycle (Linear ticket →
  spec → architect → coder → qa → review session → ship). Our two Codex gates bolt onto it at the
  only two places where a second vendor changes the outcome: **before any code exists**, and
  **when the suite actually runs**.
- **A repo with no feature-dev harness installed** — the 3-gate flow is the self-contained one.
- **Ordinary change, want the shortest honest path** — 2-gate.
- **You want the test author blind to its own review findings** — 7-step, the only flow that
  separates them.

## Why the GPT gates exist at all

The CTO's harness ([`agent-skills`](../agent-skills), installed as live symlinks into `~/.claude`)
brought things this pipeline never had: the semantic exoskeleton, LDD logging, role decomposition,
spec normalization, a Linear-tracked ticket flow. It ships superapp daily.

But its `coder` and `qa` are **both Sonnet**, and its review session is three Claude skills reading
a Claude build. It guarantees no *agent* grades its own work — not no *model*. The two gates put
this pipeline's one irreplaceable property back into that cycle, and demote everything else here to
shared infrastructure.

`agent-skills` is upstream canon and nothing in this folder modifies it.

## Shared infrastructure

```
harness/
├── prompts/       doer · reviewer · final-release-review     ← role charters, model-agnostic
├── checklists/    scoring-rubric · release-gate · review · implementation · worktree
├── {design,plans,tasks,think,handoffs,reviews}/TEMPLATE.md
├── reviews/<feature>/   every scored verdict, from every flow
├── design/ · handoffs/ · notes/ · tasks/    the artifact paper trail
└── runs/ · scratch/ · archive/              raw transcripts (gitignored)
```

`prompts/reviewer.md` carries a per-step lens (think / plan / design / build / review / test /
ship). A flow picks its lens; the charter, the rubric and the verdict format never change. That is
what makes the four flows one system rather than four.

> **Note on the run logs.** Files under `runs/`, `scratch/` and `archive/runs-legacy/` still contain
> the original `.ai/` paths from before this folder was renamed twice (`.ai` → `ai` → `harness`).
> They are transcripts of commands as they were actually run; rewriting them would make them
> misreport history.

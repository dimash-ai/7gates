# harness — the two-agent development methodology

Everything we know about making **Opus (Claude Code)** and **GPT (Codex)** build software
together, in one place. Five flows share one set of charters and one scoring rubric; they differ
only in how many times the work stops to be graded, and by whom.

The invariant every flow is built to protect:

> **No model grades its own work.** Not "a different agent" — a different *vendor*. The reviewer
> always runs blind: a separate `codex exec` process for GPT, a fresh clean-context subagent for
> Opus, so it never scores an artifact it watched being made.

Work advances only at **Score >= 9.0** ([`checklists/scoring-rubric.md`](checklists/scoring-rubric.md)).

## The five flows

| Flow | Status | Gates | Who does / who reviews | Entry |
|---|---|---|---|---|
| **[3-step co-dev](README-codev.md)** | **live — default** | brief · plan · build | you and Opus write the product brief, Opus and GPT research it independently, you approve the brief; GPT plans → Opus reviews; Opus builds → GPT reviews | `/step1` · `/step2` · `/step3` |
| **[GPT gates](README-gpt-gates.md)** | live, for feature-dev tickets | 2, spliced into the CTO's feature-dev cycle | Claude `architect → coder → qa` builds; **Codex** scores the plan and runs the release suite | `/gpt-gate-plan` · `/gpt-gate-release` |
| **[2-gate](README-2gate.md)** | superseded by 3-step co-dev | plan · build | GPT plans → Opus reviews; Opus builds → GPT reviews | its commands were rewritten as 3-step co-dev's `/step2` and `/step3` |
| **[3-gate](README-3gate.md)** | removed 2026-09-24 | design · build · verify | Opus does A+B, GPT does C; each scored by the other | commands removed; README kept as the record |
| **[7-step](README-7step.md)** | removed 2026-09-24 | think · plan · design · build · review · test · ship | strict alternation, Opus ⇄ GPT at every step | commands removed; README kept as the record |

**The 3-gate and 7-step commands were removed on 2026-09-24**; git history has them. Their charters
and rubric are still the ones the live flows call, and their READMEs stay as the record.

## Which one to reach for

- **Default — 3-step co-dev.** Our own tasks: the request becomes a product brief with user
  stories, both models research it, and it is written down as a brief you approve; GPT plans from it
  cold, Opus builds, GPT reviews every slice and runs the checks itself before the PR. Results land
  in the code repo's `specs/<slug>/`.
- **A ticket that runs through the CTO's feature-dev cycle** (Linear ticket → spec → architect →
  coder → qa → review session → ship) — the GPT gates, which bolt Codex onto it at the only two
  places where a second vendor changes the outcome: **before any code exists**, and **when the
  suite actually runs**.
The removed 3-gate and 7-step flows were the ones where GPT, not the builder, wrote the tests; for a
change where a wrong test is as dangerous as wrong code, see the known gaps in README-codev.

## Why the GPT gates exist at all

The CTO's harness ([`agent-skills`](../../agent-skills), installed as live symlinks into `~/.claude`)
brought things this pipeline never had: the semantic exoskeleton, LDD logging, role decomposition,
spec normalization, a Linear-tracked ticket flow. It ships superapp daily.

But its `coder` and `qa` are **both Sonnet**, and its review session is three Claude skills reading
a Claude build. It guarantees no *agent* grades its own work — not no *model*. The two gates put
this pipeline's one irreplaceable property back into that cycle, and demote everything else here to
shared infrastructure.

`agent-skills` is upstream canon and nothing in this folder modifies it.

That is also why [`runbook-amendments.md`](runbook-amendments.md) exists: the per-ticket
procedure is the CTO's RUNBOOK, so our two additions to it — **T1** reads the `/gate-explore`
findings note before drafting the spec, **T2** holds the architect so gate α has a window —
live here as copy-paste deltas rather than as edits upstream.

## Shared infrastructure

```
harness/
├── README-codev.md         the live flow: brief / plan / build
├── FLOW.md                 the end-to-end procedure for feature-dev tickets, epic -> Published
├── runbook-amendments.md   our deltas to the CTO's per-ticket prompts (T1, T2)
├── prompts/       doer · reviewer · final-release-review     ← role charters, model-agnostic
├── checklists/    scoring-rubric · ponytail · release-gate · review · implementation · worktree
├── {briefs,design,plans,tasks,think,handoffs,reviews}/TEMPLATE.md
├── reviews/<feature>/   scored verdicts of the older flows and the GPT gates
├── design/ · handoffs/ · notes/ · tasks/    the older flows' artifact paper trail
└── runs/ · scratch/ · archive/              raw transcripts (gitignored)
```

The 3-step co-dev flow keeps nothing here but its charters and templates: every result it produces
(brief, research, plan, verdicts, build log, PR body) lands in the code repo's gitignored
`specs/<slug>/`.

`prompts/reviewer.md` carries a per-step lens (think / plan / design / build / review / test /
ship). A flow picks its lens; the charter, the rubric and the verdict format never change. That is
what makes the five flows one system rather than five.

> **Note on the run logs.** Files under `runs/`, `scratch/` and `archive/runs-legacy/` still contain
> the original `.ai/` paths from before this folder was renamed twice (`.ai` → `ai` → `harness`).
> They are transcripts of commands as they were actually run; rewriting them would make them
> misreport history.

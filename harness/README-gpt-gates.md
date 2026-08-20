# GPT Gates — the cross-model review layer for the feature-dev flow

**Status: this is the live flow.** The 2-gate, 3-gate and 7-step flows documented beside this file
are **superseded for superapp work**. Their artifacts stay readable, their charters and rubric are
still load-bearing — this flow reuses them — but no new feature enters through `/codev-plan`,
`/gate-design` or `/gate1-think`.

## What happened

Two complete methodologies ended up in this repo without either knowing about the other.

| | `harness/` gate pipeline | feature-dev harness |
|---|---|---|
| Origin | this repo | `agent-skills/plugins/dev-methodology`, installed `--symlink` into `~/.claude` |
| Shape | cross-model gates, doer ⇄ reviewer | intra-Claude roles: architect → searcher → coder → qa → debugger |
| Reviewer | **the other vendor** (Opus ⇄ GPT Codex) | Claude review skills + `qa` |
| Code discipline | none prescribed | semantic exoskeleton + LDD, mandated in `superapp/CLAUDE.md` |
| Ticket entry | free-form feature slug | Linear `ALL-<n>` + `docs/PA_M1_BACKLOG.md` |
| Last activity | 2026-08-02 | shipping daily |

The harness won on everything except one property, and it is the property this pipeline was built
around: **no model grades its own work.** feature-dev guarantees only that no *agent* does — its
`coder` and `qa` are both Sonnet, and T3–T5 are three Claude review skills reading a Claude build.

So the pipeline is not retired. It is **demoted to what it is uniquely good at**: the cross-vendor
gate. Its doer half is dormant; its reviewer half — [`prompts/reviewer.md`](prompts/reviewer.md),
[`prompts/final-release-review.md`](prompts/final-release-review.md),
[`checklists/scoring-rubric.md`](checklists/scoring-rubric.md),
[`checklists/release-gate.md`](checklists/release-gate.md) — is now the charter for two gates
spliced into the feature-dev cycle, and `reviews/` remains the verdict home.

## Where the gates sit

```
Session 1 — build                                Session 2 — review (fresh, same cwd)
─────────────────────────────────────            ────────────────────────────────────
T1   spec        brownfield-spec-template
T2   architect → specs/DevelopmentPlan.md
     ╞═ GATE α  /gpt-gate-plan  ← GPT, read-only, BEFORE any code
T2   architect → coder → qa ⇄ debugger → green
                                                 T3  /code-review       Claude
                                                 T4  /ponytail-review   Claude
                                                 T5  /security-review   Claude
                                                 Triage → Bug Report (A / B / C1 / C2)
T6   implement findings
     ╞═ GATE γ  /gpt-gate-release  ← GPT, write-enabled, RUNS the suite
T9   ship to base   ·   T10 promote   ·   T11 backlog ↔ Linear sync
```

Both gates take `<ticket-slug> [work-root] [base-branch]`, default `superapp`, and are run **from
the pipeline root** — the same contract every gate command in `.claude/commands/` already uses.
They are symlinked into `superapp/.claude/commands/` exactly like `codev-*` and `gate-*`.

### Gate α — plan · [`/gpt-gate-plan`](../.claude/commands/gpt-gate-plan.md)

Codex reads `DevelopmentPlan.md` cold and scores it before the coder touches a file. It enforces
the devplan-protocol schema, checks every AC traces to a slice, and verifies the plan commits new
AI-track backend modules to the exoskeleton + structlog LDD per `superapp/CLAUDE.md`.

**What it buys.** feature-dev surfaces design defects only at Triage, as class **C1**, after the
build, the QA loop and the fix round have already been paid for. This is the same finding, one
`codex exec` earlier. It also restores the 2-gate flow's load-bearing property — *the plan is
adversarially reviewed before any code* — which nothing in the harness provides.

**Cost.** The architect must be held: add to the T2 launch prompt —
*"After writing DevelopmentPlan.md, STOP and report its absolute path. Do NOT delegate
implementation until I return with a plan verdict."* Without that line the architect delegates
straight through and the gate arrives too late to be a gate.

### Gate γ — release · [`/gpt-gate-release`](../.claude/commands/gpt-gate-release.md)

Codex gets `--sandbox workspace-write` for one reason: **so it runs the checks itself and reports
the counts it observed.** Everything upstream reads. This executes.

It also carries the review hygiene the RUNBOOK's own reviewers learned the hard way — `git add -N .`
so new modules enter the diff, `git diff HEAD` never a bare `git diff`, `cut -c4-` never `awk`, and
`git reset` at the end because intent-to-add records empty blobs and a later `git restore .`
destroys the new files.

**What it buys.** An approval that never rests on the builder's own claim that the suite was green.
`qa` runs pytest, but `qa` is the same model as `coder`; a shared blind spot survives both.

**Watch the base.** superapp runs two: the RUNBOOK ladder (`dev` → `main`) and a direct-to-`main`
convention marked by the `-main` branch suffix. Diff against the wrong one and the verdict is noise.

## Gate β — deliberately not built

A GPT reviewer as a fourth lens at T3–T5, feeding Triage. Skipped for now: Triage already dedupes
three reviewers into one list, and a fourth read-only correctness pass is the *least* differentiated
thing Codex can do here — α and γ both give it a job no Claude agent in the flow performs at all.
Add it if Triage starts showing defects that all three Claude lenses missed.

## Scoring

Unchanged. [`checklists/scoring-rubric.md`](checklists/scoring-rubric.md) governs both gates:
`>= 9.0` APPROVED, any must-fix caps at 8.9, any security / data-loss / build-breaking issue caps at
7.9. Codex is read-only at α and reviewer-only at γ — **you persist the verdict** into
`reviews/<ticket>/`, verbatim, as scribe not re-grader.

## Canon discipline

`agent-skills/` is the CTO's canon and this integration does not touch a byte of it — no edited
RUNBOOK, no edited agent, no edited rule. Everything above lives on our side, so a `git pull` in
`agent-skills` can never conflict with it.

That pull is **not** a routine action. `~/.claude/{rules,agents,skills,workflows}` are live symlinks
into that working copy, so a pull silently rewrites the constitution, the five role agents and six
skills for **every Claude Code session on this machine, instantly, with no review step**. Read the
changelog first; treat it like merging into `main`.

## Not done

- **`prompting-methodology` plugin** (GRACE, `/brainstorm` `/design` `/contract` `/verify-fact`
  `/agent-prompt`) — not installed; the marketplace is not registered.
- **The other 7 universal skills** — `repo-triage`, `repo-pathology`, `repo-anatomy`, `roadmap`,
  `brainstorm`, `okf`, `intake-audit`. Only `git-linear-flow` was installed, into
  `superapp/.claude/skills/` with a `config.yaml` derived live from the Linear workspace.
- **Generalization.** This is superapp-scoped by decision. If it holds for a few tickets, the two
  commands and this doc are the extractable part — they would go to `agent-skills` as a plugin, at
  which point the RUNBOOK becomes the right place for the T2 hold instruction.
- **The dormant half.** `codev-*` and `gate*-*` commands still exist and still work. Nothing was
  deleted; they simply have no live consumer.

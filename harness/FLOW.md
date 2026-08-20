# FLOW — from a huge Linear task to shipped code

The end-to-end procedure. Three actors appear throughout, and keeping them straight is the
whole discipline:

| | who | what they are for |
|---|---|---|
| **Opus** | Claude Code — `architect`, `coder`, `qa`, `debugger`, `searcher` | designs and builds |
| **Codex** | GPT, via `codex exec` | grades what Opus produced, blind |
| **You** | the operator | decide, merge, and run what no agent may run |

The invariant: **no model grades its own work.** Not "a different agent" — a different vendor.

---

## Before you start — pick your altitude

| what arrived | where you enter |
|---|---|
| A huge task / epic — many tickets' worth | **Part 1** |
| One feature slice, already specified | **Part 3** |
| A bug or fix | **Part 5** |

Running Part 1 on a single ticket is waste. Skipping it on an epic is how a plan becomes a
guess.

---

## Part 1 — Break the task down (once per epic)

### 1.1 Sweep for what solving it will need

```
/gate-explore <topic> [repo]
```

Two **independent reconnaissance sweeps** — Opus first (it owns external sourcing, since Codex runs
offline), then Codex cold — over six things a planner needs before designing anything: **Territory**
(what this touches) · **Prior art** (what already exists and should be reused) · **Constraints**
(pinned versions, contracts, which constitution rules govern this surface) · **Scars** (what was
already tried here and failed) · **Tests** (what they actually assert) · **Absences** (unenforced
invariants, untested paths, dangerous defaults).

They merge by **union** into `harness/notes/<topic>.md`, each item tagged `[O]` / `[G]` / `[both]`.
That is the opposite of the build gates: there, independence makes agreement meaningful; here it
buys **coverage**, because two models search differently. Sweep wide, report narrow — an item earns
its place only if a planner could make a different decision because of it.

Two sections aren't evidence. **Contradictions block planning** — resolve them by reading the code,
never by picking the more confident sweep. **Gaps** become `UNVERIFIED` assumptions the plan gate
re-checks.

Not scored, and optional — reach for it when the work has real unknowns. The dossier reaches the
build flow at **T1**, which folds it in section by section. Skip that fold-in and the sweep
evaporates: the architect reads `TASK_FILE` and nothing else.

### 1.2 Point at an architecture doc

Tickets should reference architecture, never restate it. `PA_ARCHITECTURE.md` is the model:
one place that holds the shape, so 69 tickets can stay short.

### 1.3 Decompose into a ticket catalog

One file — the backlog. Open it with a **dated scope freeze** and any policy that governs
whole classes of ticket, naming the tickets it governs. Then one entry per ticket:

```
### 49. foc_ scope vocabulary normalization + read-only default mint
`foc-scope-vocab` · **0.75d** · `route:interactive` · _Registrar APIs_

<what and why, and the decision that produced it>

Blast radius (measured 2026-07-27, re-measured 2026-07-29): <every file, by path>

> ⚠️ / ✅ dated decision notes — what changed and what it now means

**Acceptance criteria**
- <observable and testable — never "works correctly">

**Depends on:** #17 — not a capability dependency, a **sequencing** one.
             (Blocks #18, #19, #47; retrofits the already-shipped #20.)
```

Four things that are easy to drop and expensive to lose:

- **Blast radius is measured against the code and dated** — not estimated from memory.
- **Dependencies say *which kind*.** Capability ("cannot start until") and sequencing
  ("cheaper after") schedule differently.
- **Decision notes carry dates and reversals**, including why an earlier framing no longer
  applies. This is what stops the swarm re-litigating a settled question.
- **ACs are the gate contract.** They become what the plan gate checks the plan against and
  what the release gate demands a named test for. A vague AC disarms both gates.

### 1.4 Label every ticket on two axes

| axis | values | decides |
|---|---|---|
| `line:` | `wow-v0` · `early` · `must` · `stretch` · `post-m1` | which delivery window |
| `route:` | `auto` · `interactive` | **whether it can run unattended** |

### 1.5 Size the lines — recompute, never increment

Sum the per-ticket estimates per line. **Do not** maintain the totals by adding deltas as
tickets change; that drifts the moment one increment is missed. This is not theoretical — on
`PA_M1_BACKLOG` it hid a doubling: `must` interactive was recorded at 2.5d against a real
**5d**, accumulated across four separate decisions, none of them wrong on its own.

**The interactive column is the binding one.** `route:auto` parallelizes across worktrees;
`route:interactive` needs you. Compare each line's auto total against its window to get the
parallelism factor the plan assumes — if that number is not achievable, the plan is fiction.

Sequencing lives in a **separate phasing file**. The backlog says *what and how big*; phasing
says *in what order and in which wave*.

### 1.6 Mirror into Linear

Each ticket becomes an issue. The **file is the source of truth for authoring**; Linear is
the PO/CEO board. `git-linear-flow` drives the status ladder from git events.

---

## Part 2 — Set up for parallel execution

One worktree per ticket. The branch name comes **verbatim from the ticket's Linear issue** —
never hand-rolled, because the `all-<id>` token is the GitHub↔Linear join key and T1
cross-checks it:

```bash
git worktree add -b <gitBranchName> <path> dev
```

Then, per worktree: its own `uv sync`, and its own copy of every gitignored `.env` — neither
propagates. Copy `.env` from the **main tree**, which is the canonical source.

**What must not run concurrently:**

- Two branches adding an Alembic revision off the same head, **per app** — the second to
  merge has to re-chain `down_revision` and regenerate. Different apps never collide, and
  `route:interactive` does not imply a migration.
- Overlapping blast radii — the cost is a multi-branch pileup on one hot module.
- Shared surfaces: `.github/workflows/ci-*.yml`, `AGENTS.md`, `shared/**`.

`route:interactive` tickets **do** parallelize; the real cap is how many clarification threads
you can hold. Two or three is realistic — stagger their starts rather than capping the count.

> **Removing a worktree runs `rm -rf` on its gitignored files.** `.env` never appears in
> `git status --porcelain`, so a "clean" worktree can hold the only copy of a filled-in one.
> Run `git status --ignored --porcelain <worktree>` first. `.venv` and `node_modules` are free
> to lose.

---

## Part 3 — The ticket loop

Two sessions per ticket. **Everything runs from wherever you are** — the code repo, one of its
worktrees, or the pipeline root. The gate commands resolve `harness/` by walking up, so you never
switch directories mid-ticket.

### Session 1 — spec and build

**T1 — draft the spec** → `specs/ALL-<id>.md`, via `brownfield-spec-template`. It normalizes
the ticket into BR ids, MAY EDIT / DO NOT TOUCH lists and measurable ACs; resolves the Linear
issue and moves it to **In Progress**; and **diffs the backlog against Linear before
drafting** — if Linear holds ACs the file lacks, it stops, because someone specified into
Linear and building without it passes every gate and still fails acceptance.

Two things T1 must carry, per [`runbook-amendments.md`](runbook-amendments.md): the
exploration note if one exists, and the statement that new or edited AI-track backend modules
carry the semantic exoskeleton and LDD as structlog fields. **A spec that is silent on LDD
gives the coder room to argue out of it.**

**T2 — launch the architect**, with `TARGET_PROJECT`, `TASK_FILE`, and the hold line. It loads
the constitution itself (B1) and your repo's `CLAUDE.md` (B1b) — LDD arrives automatically;
there is no flag to forget. Output: `specs/DevelopmentPlan.md`, then it stops.

### ▌GATE α — the plan, before any code exists

```
/gpt-gate-plan ALL-<id> [work-root]
```

Codex reads the plan cold and scores it: does every AC trace to a slice, is the decomposition
minimal, are failure modes specific, was the reuse-first ladder walked, does the plan commit
to the exoskeleton where the constitution requires it. **You persist the verdict** verbatim to
`harness/reviews/ALL-<id>/plan-verdict.md`.

`>= 9.0` → back to the T2 thread: *"Plan verdict APPROVED at X.X. Proceed with
DELEGATE_IMPLEMENTATION."* The architect then drives `coder → qa ⇄ debugger` to green.

*Why it exists:* without it the design defect surfaces at Triage as class **C1** — after the
build, the QA loop and the fix round are already paid for.

### Session 2 — review, fresh session, same cwd

`/code-review` · `/ponytail-review` · `/security-review`, then **Triage** merges all three into
one Bug Report, dedupes, re-grades severity, and splits: **A** implement now · **B** what you
paste back · **C1** plan-level · **C2** spec-level.

### Back in Session 1

**T6 — implement the findings.** Only the cited items.

### ▌GATE γ — the release, with the suite actually run

```
/gpt-gate-release ALL-<id> superapp dev
```

Codex gets a write-enabled sandbox for one reason: **so it runs your checks itself and reports
counts it observed.** Everything upstream reads; this executes. It also does the constitutional
pass and demands a named test per AC.

Base is `dev` — this gate runs before T9. The `-main` branches are **T10 promotion branches**,
not a bypass.

### Ship

**T9 — to dev.** Several commits split by scope, never one blob. PR titled
`<type>(<scope>): <subject> (ALL-<id>)`. **You merge it.** Then the issue moves to **Test**.

**Human QA in Test.** PM (or you, for infrastructure) runs the scenarios and moves it to
**Done**. Findings go back as T6/T7 while it stays in Test.

**T10 — promote to main.** Only after **Done**. Cherry-picks the feature commits — never the
merge commit — onto a branch named `<ticket-branch>-main`, PRs into `main`. **You merge.**
Issue → **Published**.

> **T11 tripwire.** If the backlog file appears in your diff, run the Linear sync **before**
> committing. A committed backlog change Linear doesn't mirror makes the PO dashboards lie.

---

## Part 4 — Where everything lands

```
specs/ALL-<id>.md              the contract       (gitignored)
specs/DevelopmentPlan.md       the plan           (gitignored)
harness/notes/<topic>.md       exploration findings
harness/reviews/ALL-<id>/      plan-verdict · release-verdict · re-scores -2, -3 …
harness/runs/                  raw transcripts    (gitignored)
```

---

## Part 5 — When it doesn't go straight

**A gate scores below 9.0.** Never override — route it:

| the Must Fix is | goes to |
|---|---|
| implementation | the open build thread; fix only cited items; re-run the gate |
| plan-level (C1) | the architect amends `DevelopmentPlan.md`; re-run gate α |
| spec-level (C2) | **stop** — amend `specs/ALL-<id>.md`, re-enter at T2 |

**A fix, not a feature.** Three entry points:

- *Inside a ticket still in flight* — **T6** in the live session, **T7** if it's gone. No new
  issue, no worktree, no spec. The most common path by far.
- *Standalone, root cause known* — Linear issue → worktree → **T7** → **T8** → **T3** (+ **T5**
  on a security boundary) → T9. Keeps the `BUG_FIX_CONTEXT` scar and a regression test, drops
  the planning ceremony.
- *A "fix" that is really a redesign* — full pipeline from **T1**. `BR-1` in the brownfield
  template already is the regression guard.

---

## Part 6 — What only you can do

- **Migrations** — review the autogenerated revision plus hand-placed RLS in-session, before
  it enters the change set. Repo cardinal rule.
- **Real-DB tests** — local sandbox only. The suites `TRUNCATE`, so a shared DSN erases live
  data. A plain flow run reports DB-backed ACs as **TEST_DEFERRED**; that is correct, and you
  clear them as an operator gate afterwards.
- **Frontend** — the prototype-parallel walk, then the side-by-side screenshot. Mandatory for
  AI-built UI.
- **Merging** — both PRs. Agents open them and stop.
- **Deciding divergences** from `/gate-explore`, and every Superposition/Collapse fork on a
  `route:interactive` ticket.

> **CI is path-filtered and one app has none.** Nothing covers `apps/sura/**`, `docs/**` or
> `specs/**`. When no workflow ran, say so out loud at T9/T10 rather than reading a green PR
> page as a passing build.

---

## Quick reference

```
epic     /gate-explore <topic>          → harness/notes/<topic>.md      [optional]
         decompose → backlog → size the lines → Linear issues
         git worktree add -b <gitBranchName> <path> dev

ticket   T1  spec              → specs/ALL-<id>.md          in worktree
         T2  architect + HOLD  → specs/DevelopmentPlan.md    in worktree
     ▌   /gpt-gate-plan ALL-<id>                             resolves harness/ itself
         T2  coder → qa ⇄ debugger → green
         T3 T4 T5 + Triage                                   fresh session
         T6  findings
     ▌   /gpt-gate-release ALL-<id>                          resolves harness/ itself
         T9  ship → dev PR → you merge → Test
             human QA → Done
         T10 promote → main PR → you merge → Published
         T11 if the backlog file is in the diff
```

Every `▌` is a point where a model from the other vendor grades the work. Remove them and the
cycle is Claude reviewing Claude.

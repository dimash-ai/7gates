---
description: "Explore gate: two independent reconnaissance sweeps → one evidence dossier for the planner"
argument-hint: <topic-or-ticket> [repo-path]
---

# Explore gate  ·  two independent sweeps · one dossier

A **reconnaissance stage**, not a build gate. Two models sweep the codebase independently for
everything a planner would need to know before designing a solution, and the union becomes a
dossier that later stages read instead of rediscovering.

It is **not scored** and **not adversarial**. That is the whole point of the design:

> In the build gates, independence exists so **neither model grades its own work** — you want
> *agreement to be meaningful*. Here independence exists for **coverage** — you want the
> **union**, because two models search differently and each finds things the other walks past.
> So the merge rule is not consensus. It is *everything both found, with contradictions flagged.*

`$1` is a topic or ticket slug (`focal-recurrence-model`, `ALL-555`). `$2` is the code repo —
optional, defaults to the current git repo.

**Sweep wide, report narrow.** The sweep should be exhaustive; the dossier should not. An item
earns a place only if a planner could plausibly **make a different decision because of it**. A
dossier that reprints the codebase is the same as no dossier.

## 0 — Resolve the harness root

Every `harness/…` path below is relative to the **pipeline root** — the directory containing
`harness/`, not the code repo:

```bash
d=$PWD; while [ "$d" != / ] && [ ! -d "$d/harness/prompts" ]; do d=$(dirname "$d"); done; echo "$d/harness"
```

**Never create a `harness/` directory inside the code repo.** If that path appears under the repo,
resolution was skipped and the dossier is in the wrong tree.

## 1 — State the issue in one paragraph

Write what is actually being solved — from the Linear issue, the backlog ticket, or this
conversation. Both sweeps get this same paragraph and nothing else. It goes at the top of the
dossier so the document stands alone six weeks later.

## 2 — Opus sweeps first, independently

**You (Opus), before invoking GPT,** sweep and write raw findings to `harness/scratch/$1-opus.md`.
Sweeping first is what keeps you from anchoring on GPT.

Cover the six categories in §4. Cite every item as `file:line`.

**You own all external sourcing** — GPT runs offline in the next step. For anything outside this
codebase (library behaviour, API surfaces, pinned-version semantics, framework features) verify it
now: the Context7 docs MCP for library docs, WebSearch/WebFetch for the rest. **Never answer a
library or "current best practice" question from memory** — that is the exact failure the host
`CLAUDE.md` calls out.

## 3 — GPT sweeps the same issue, independently

GPT must not see your findings. Run this, with the issue paragraph pasted in place of `<ISSUE>`.
**Escaping:** the text lands inside a double-quoted shell string — escape any `"` in it, or pipe it
via a heredoc, so the command doesn't break.

```bash
codex exec --sandbox read-only "You are GPT Codex on a reconnaissance sweep. You are NOT solving this issue and NOT proposing a design — you are finding everything a planner would need to know before designing one. Work INDEPENDENTLY and from scratch: do NOT look for, assume, or defer to any other model's findings. THE ISSUE: <ISSUE>
Sweep the repo for six things. (1) TERRITORY — every module, route, table, migration, config and test this issue plausibly touches. (2) PRIOR ART — code that already does part of this and should be reused instead of reinvented; walk the reuse-first ladder in CLAUDE.md (an existing helper, the standard library, a platform or framework feature, an already-installed dependency) before concluding something must be written. (3) CONSTRAINTS — pinned versions read from pyproject.toml / package.json / lockfiles, contracts and interfaces this must not break, rules in CLAUDE.md or AGENTS.md that govern this surface, and any tenant-isolation or RLS boundary in play. (4) SCARS — BUG_FIX_CONTEXT comments, recorded deviations, TODOs and past workarounds in the code this touches; they record what was already tried and why it failed, which is the cheapest thing to know and the easiest to miss. (5) TESTS — what already covers this surface, and what each actually asserts versus what its name claims. (6) ABSENCES — the defect class that is code which does NOT exist: an invariant stated only in a comment with nothing enforcing it, a configurable value whose worst legal setting is materially worse than its default, two concerns sharing one credential or limit, a code path with no test at all.
Cite EVERY item as file:line. An item you cannot cite is not evidence — drop it, or mark it explicitly as a hunch. You have NO network access: for anything needing an external source, say so plainly and never invent a URL, version or API detail. Sweep WIDE but report NARROW — include an item only if a planner could plausibly make a different decision because of it. Do not propose a solution, a design, or an implementation order. You are read-only and must NEVER edit any file."
```

Save the raw output to `harness/scratch/$1-gpt.md` (gitignored).

> **If `codex exec` errors or returns an auth failure, STOP — do not build the dossier from one
> sweep.** Two independent sweeps *is* this gate; one is just a search. Codex auth flaps and
> `codex login status` is unreliable — recover with `rm ~/.codex/auth.json && codex login`, then
> re-run this step.

## 4 — Merge into the dossier

Read **both** scratch files and write `harness/notes/$1.md` from
[`harness/notes/TEMPLATE.md`](../../harness/notes/TEMPLATE.md). Six evidence sections, then
contradictions, then gaps:

| Section | What goes in it |
|---|---|
| **Territory** | What this touches. The candidate blast radius, before anyone measures it properly at spec time. |
| **Prior art** | What already exists that a solution should reuse. The highest-value section — it is what stops reinvention. |
| **Constraints** | Pinned versions, contracts, host-constitution rules that apply to this surface, isolation boundaries. |
| **Scars** | What was already tried here and failed, with the citation that proves it. |
| **Tests** | What covers this today and what it really asserts. |
| **Absences** | What is missing rather than wrong — unenforced invariants, untested paths, dangerous defaults. |

**Merge by union, not intersection.** An item found by only one sweep is a *finding*, not a
weakness — that is the coverage you paid for. Mark each item's provenance: **`[O]`**, **`[G]`**,
or **`[both]`**.

> That marker makes the gate self-measuring. If nearly everything is `[both]`, the two sweeps were
> redundant and one would do next time. If they are largely disjoint, running two was the right
> call. Read the ratio before deciding whether to run this gate on the next ticket.

Two things do **not** merge quietly:

- **Contradictions** — the sweeps report the same fact differently (a version, a call count, who
  owns a table). Put both claims side by side with both citations. **These block planning**: a plan
  built on the wrong one of two contradictory facts is wrong from its first line. Resolve them by
  reading the code, not by picking the more confident-sounding sweep.
- **Gaps** — neither sweep could establish something the planner will need. Name exactly what is
  missing and what would close it. A gap named here becomes an `UNVERIFIED` assumption in the spec
  rather than a silent guess in the plan.

Keep it to findings, not transcripts. If a prior round's `harness/notes/$1.md` exists, **merge into
it** — never overwrite: add new items, fold resolved contradictions into the evidence sections with
a note on how they were settled, and preserve the earlier provenance markers.

## 5 — Hand it to the planner

The dossier is not the end state — it is an input. It reaches the build flow at **T1**, which reads
`harness/notes/$1.md` before drafting the spec and folds it in per
[`harness/runbook-amendments.md`](../../harness/runbook-amendments.md): evidence becomes confirmed
assumptions and ACs, gaps become explicit open questions, and anything the sweeps could not verify
stays marked unverified so the plan gate re-checks it.

**Nothing reads this file automatically.** If you skip the T1 fold-in, the sweep evaporates — the
architect takes `TASK_FILE` and nothing else.

Report the summary, decide the contradictions yourself, and re-run any step if a new question
surfaced. There is no score and nothing to approve.

> `--sandbox read-only` keeps GPT from touching the tree. Raw per-model sweeps live in
> `harness/scratch/` (gitignored); only the merged `harness/notes/$1.md` is committed.

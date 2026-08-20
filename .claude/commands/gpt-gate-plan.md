---
description: "GPT gate α (plan): Codex scores DevelopmentPlan.md before any code is written"
argument-hint: <ticket-slug> [work-root]
---

# GPT gate · α — plan  ·  architect does · GPT Codex reviews

The **cross-model plan gate** for the feature-dev flow. It runs between the architect writing
`specs/DevelopmentPlan.md` (RUNBOOK **T2**) and the coder touching a single file.

Why it exists: feature-dev's `coder` and `qa` are **both Sonnet**, and its design-level findings
only surface *after* the build, as Triage class **C1**. This gate restores the property the 2-gate
co-dev flow was built around — *the plan is adversarially reviewed before any code*, by a model
from a different vendor. See [`harness/README-gpt-gates.md`](../../harness/README-gpt-gates.md).

`$1` is the ticket slug (`ALL-555`) — it names the verdict file. `$2` is the work root relative to
the pipeline root — **optional, defaults to `superapp`**; pass the worktree
(`superapp/.claude/worktrees/all-555-focal-settings`) when the ticket runs in one. **If `$2` was
omitted, substitute `superapp` for every `$2` below — inside the codex prompt string too — before
running anything.**

## Precondition — hold the architect

The architect auto-delegates from `DESIGN_AND_VALIDATE` straight into `DELEGATE_IMPLEMENTATION`.
Amend the **T2** launch prompt with this line so it stops at the plan:

> After writing DevelopmentPlan.md, STOP and report its absolute path. Do NOT delegate implementation until I return with a plan verdict.

Then run this gate. Nothing here creates or edits a file in `$2` — the plan is already on disk.

## Where this runs

**Anywhere at or under the pipeline root** — the repo you are working in (`superapp`), one of its
worktrees, or the root itself. The block below resolves two things for you rather than assuming a
working directory: `$H` (the `harness/` charters) and `$R` (the work root being reviewed, defaulting
to the current git repo when `$2` is omitted). A bare `harness/…` path would silently resolve inside
the code repo, and `$(cat …)` on a missing charter returns **empty** — the gate would run with no
rubric and no verdict format, and look like it passed.

## Reviewer = GPT Codex, read-only, blind

Codex has none of the architect's conversation — it reads the plan cold, which is the point. Run
exactly this one bash command:

```bash
# Resolve the pipeline root from wherever you are (superapp, a worktree, or the root itself)
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
[ -n "$H" ] || { echo "ERROR: no harness/ at or above $PWD"; exit 1; }
R=$(cd "${2:-$(git rev-parse --show-toplevel)}" && pwd) || exit 1
[ -d "$R/harness/prompts" ] && R="$R/superapp"   # ran from the pipeline root -> default to the code repo
mkdir -p $H/reviews/$1 $H/runs
codex exec --sandbox read-only "$(cat $H/prompts/reviewer.md)
$(cat $H/checklists/scoring-rubric.md)
You are GPT Codex, the blind reviewer for the PLAN gate of $1. You did NOT write this plan — a Fable/Opus architect did. Apply the **plan** and **design** lenses from the charter above. Read $R/specs/DevelopmentPlan.md and the task spec it claims to satisfy ($R/specs/$1.md, or the single specs/*.md file if that exact name is absent), then study the code repo $R until you can judge the plan against what is actually there — cite every claim about existing code as file:line. Score whether: the decomposition into slices is minimal and each slice is independently shippable; every Acceptance Criterion in the spec traces to a slice and is measurably verifiable (not 'works correctly'); the named failure modes are specific (which error, caught where, what the user sees); the reuse-first ladder was walked before any new surface was proposed; the data flow covers the unhappy path, not just the happy one; and the plan's own test strategy states what each test PROVES. Enforce the devplan-protocol schema as a gate, not a suggestion: a missing §0 Rationale (Superposition/Collapse), DraftCodeGraph, step-by-step Data Flow, measurable Acceptance Criteria, Delivery Contract, Runtime Commands table, or §7 Verification Commitments is a Must Fix. Enforce the host constitution: read $R/CLAUDE.md and confirm the plan commits new/edited AI-track backend modules to the semantic exoskeleton and LDD as structlog fields (imp=/func=/block=) — a plan that is silent on that for AI-track Python, or that pre-endorses dropping it, is a Must Fix; a plan that demands it for frontend or for pre-existing untouched code has the scoping wrong and is also a Must Fix. You have NO network access: any claim the plan makes about a library, framework or tool API must name the pinned version it assumed and read it from $R's pyproject.toml / package.json / lockfiles — an unpinned or memory-sourced version claim that the plan has not marked UNVERIFIED is a Must Fix, because no code has been written yet and this is the last cheap moment to catch it. Do NOT review code quality — no code exists yet. Do NOT propose an alternative plan; score the one in front of you. Output ONLY the verdict block from the charter, with Step: plan." 2>&1 | tee $H/runs/$1-gpt-gate-plan.txt
```

Codex is read-only and cannot write its own verdict. **You persist it**: copy the verdict block
verbatim from the output into `harness/reviews/$1/plan-verdict.md` (re-scores after an amendment become
`plan-verdict-2.md`, `-3.md`, …). Do not summarize or re-grade it — you are the scribe here, not
the reviewer.

## The gate

- **Score >= 9.0 / APPROVED** → release the architect. Paste back into the still-open T2 build
  thread: *"Plan verdict APPROVED at X.X. Proceed with DELEGATE_IMPLEMENTATION."*
- **Score < 9.0 / BLOCKED** → the architect amends the plan. Paste the **Must Fix** list into the
  T2 thread as a plan amendment — this is the same routing the RUNBOOK gives Triage class **C1**,
  arriving before the build instead of after it. Fix only the cited items, then re-run this gate.
- A Must Fix that turns out to be **spec-level** (a missing or contradictory AC/BR — Triage class
  **C2**) is not the architect's to fix. Stop, amend `specs/$1.md`, and re-run T2 from the spec.

## Cost note

One read-only `codex exec` over a plan and its repo. This is the cheapest gate in the flow and the
most leveraged — a wrong decomposition caught here costs one re-plan; caught at Triage it costs the
build, the QA loop, and the fix round.

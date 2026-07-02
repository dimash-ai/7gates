---
description: "Step 2 (plan): GPT does, Opus reviews"
argument-hint: <feature-name>
---

# Step 2 — plan  ·  GPT does · Opus reviews

**Arguments — parse them yourself.** Raw args: `$ARGUMENTS`

The first whitespace token of the raw args → `<feature>` (the rest, if any, is context, not
positional data). If the raw-args line above looks unsubstituted or empty, recover the tokens from this invocation's command-args instead. This file deliberately uses **no positional dollar-number placeholders** (the runner's `$N` is **0-indexed** — `$1` is the *second* argument, per the Claude Code skills docs — an off-by-one foot-gun against shell conventions); instead, substitute the literal angle-bracket tokens below — in prose AND inside bash blocks — with the parsed values before running anything. An absent optional token substitutes as an **empty string**.


**Doer = GPT (Codex), write-enabled.** Have GPT write the plan. Run exactly this one bash command from the pipeline root:

```bash
codex exec --sandbox workspace-write "$(cat .ai/prompts/doer.md)
You are GPT Codex, the doer for the PLAN step of <feature>. Read the approved think doc .ai/think/<feature>.md and the task .ai/tasks/<feature>.md. Write the implementation plan to .ai/plans/<feature>-plan.md following the structure in .ai/plans/TEMPLATE.md — small, independently reviewable slices, named failure modes, and what each test proves. Write ONLY .ai/plans/<feature>-plan.md. Do NOT edit code, tests, or any other file."
```

**Reviewer = Opus, fresh context.** Do **not** review the plan inline — you watched it being made. Instead spawn a clean-context Opus reviewer with the **Agent tool** (`subagent_type: "claude"`), passing this prompt:

> `<contents of .ai/prompts/reviewer.md>`
> You are Opus, the reviewer. Step: plan. Read ONLY the plan at `.ai/plans/<feature>-plan.md`, the think doc `.ai/think/<feature>.md`, and the task `.ai/tasks/<feature>.md`. Apply the plan lens (minimum viable change, existing code that already solves it, named failure modes, what each test proves). Output the verdict EXACTLY as the charter specifies (Reviewer: Opus, Step: plan). Status is APPROVED only if Score >= 9.0.

Take the subagent's returned verdict and:

1. Ensure `.ai/reviews/<feature>/` exists, then save the verdict block to `.ai/reviews/<feature>/02-plan-verdict.md` (increment if it exists: `-2`, `-3`, …).
2. STOP.
3. Report **Score** and **Status**:
   - **BLOCKED** (< 9.0): list every Must Fix; re-run the GPT doer command to revise the plan (fixing only those items), then re-review.
   - **APPROVED** (>= 9.0): say so; next stage is **Step 3 — design** (`/gate3-design <feature>`).

> `--sandbox workspace-write` lets the GPT doer write the plan file — confirm the flag with `codex --help`. The Opus review must run in a **fresh subagent**, not inline, so the reviewer has the same blind context GPT gets from `codex exec`.

---
description: "Step 3 (design): Opus does, GPT reviews"
argument-hint: <feature-name>
---

# Step 3 — design  ·  Opus does · GPT reviews

**Doer = Opus (you, in this conversation).** Before running this gate, write the design doc for
`$1` to `.ai/design/$1-design.md` following `.ai/design/TEMPLATE.md`: architecture, data model,
interfaces & contracts, happy + unhappy flow, alternatives rejected, test strategy, security
notes. It must trace back to the approved think doc and plan. If that file does not exist yet,
write it now, then continue.

**Reviewer = GPT (Codex), read-only.** Run exactly this one bash command from the pipeline root:

```bash
codex exec --sandbox read-only "$(cat .ai/prompts/reviewer.md)
You are GPT Codex, the reviewer. Step: design. Review ONLY the design doc at .ai/design/$1-design.md against the plan .ai/plans/$1-plan.md and task .ai/tasks/$1.md. Apply the design lens: coupling, state transitions, data flow on the unhappy path (null/empty/upstream error), soundness of interfaces and the data model, and whether alternatives were rejected for stated reasons. You are read-only and must NEVER edit any file. Score 0-10 per .ai/checklists/scoring-rubric.md and output the verdict EXACTLY as the charter specifies (Reviewer: GPT Codex, Step: design). Status is APPROVED only if Score is 9.0 or higher."
```

Then:

1. Ensure `.ai/reviews/$1/` exists, then save **only the verdict block** to `.ai/reviews/$1/03-design-verdict.md` (increment if it exists).
2. STOP.
3. Report **Score** and **Status**:
   - **BLOCKED** (< 9.0): list every Must Fix, revise the design doc, re-run this gate.
   - **APPROVED** (>= 9.0): say so; next stage is **Step 4 — build** (`/gate4-build $1 <repo>`).

> `--sandbox read-only` keeps the reviewer from touching the tree — confirm the flag with `codex --help`.

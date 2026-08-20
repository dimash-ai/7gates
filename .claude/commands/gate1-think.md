---
description: "Step 1 (think): Opus does, GPT reviews"
argument-hint: <feature-name>
---

# Step 1 — think  ·  Opus does · GPT reviews

**Doer = Opus (you, in this conversation).** Before running this gate, write the think doc for
`$1` to `harness/think/$1.md` following `harness/think/TEMPLATE.md`: frame the problem, state every
assumption, weigh at least two options, recommend one, and list open questions + success
criteria. If that file does not exist yet, write it now, then continue.

**Reviewer = GPT (Codex), read-only.** Run exactly this one bash command from the pipeline root:

```bash
codex exec --sandbox read-only "$(cat harness/prompts/reviewer.md)
You are GPT Codex, the reviewer. Step: think. Review ONLY the think doc at harness/think/$1.md (and the kickoff task harness/tasks/$1.md if present). Apply the think lens: is the problem framed correctly, are assumptions explicit, is the recommended option justified against the alternatives, is anything unstated or unbounded? You are read-only and must NEVER edit any file. Score 0-10 per harness/checklists/scoring-rubric.md and output the verdict EXACTLY as the charter specifies (Reviewer: GPT Codex, Step: think). Status is APPROVED only if Score is 9.0 or higher."
```

Then:

1. Ensure `harness/reviews/$1/` exists, then save **only the verdict block** — from the `# Review Verdict` line to the end — to `harness/reviews/$1/01-think-verdict.md`. Do NOT paste the raw CLI transcript (write that to `harness/runs/` if you want it). **If the file exists, increment:** `01-think-verdict-2.md`, etc.
2. STOP. Make no further changes.
3. Report **Score** and **Status**:
   - **BLOCKED** (< 9.0): list every Must Fix, address them in the think doc, re-run this gate.
   - **APPROVED** (>= 9.0): say so; next stage is **Step 2 — plan** (`/gate2-plan $1`).

> `--sandbox read-only` keeps the reviewer from touching the tree — confirm the flag with `codex --help` for your version.

---
description: "3-gate A (design): Opus does, GPT reviews"
argument-hint: <feature-name>
---

# 3-Gate · A — design  ·  Opus does · GPT reviews

The first gate of the **3-gate flow** (`ai/README-3gate.md`): produce the **complete design**
for `$1` — the decision, the build approach in slices, and the architecture — as one cohesive
document the builder and verifier can work from alone.

**Doer = Opus (you, in this conversation).** Before running this gate, write the design for `$1` to
`ai/design/$1-design.md` following `ai/design/TEMPLATE-3gate.md`. It is one document, structured by
topic, not a sequence of sub-steps: the problem and the decision (with the alternatives you rejected
and why), the assumptions and what's out of scope, the success criteria, the build broken into
independently shippable slices, and the architecture — data model, interfaces, happy/unhappy flow,
test strategy, security, and rollback. If the file doesn't exist yet, write it now, then continue.

**Reviewer = GPT (Codex), read-only.** Run exactly this one bash command from the pipeline root:

```bash
codex exec --sandbox read-only "$(cat ai/prompts/reviewer.md)
You are GPT Codex, the reviewer. Step: design. Review ONLY the design doc at ai/design/$1-design.md (and the kickoff task ai/tasks/$1.md if present), judging it as one whole design: is the problem framed correctly and the chosen approach justified against the alternatives; are assumptions explicit and scope bounded; is the build sliced into sound, independently shippable steps each with a clear test; is the architecture coherent — coupling, data model, interfaces, and the unhappy-path flow (null/empty/upstream error); does it reach for what already exists before adding new surface (the reuse-first ladder, CLAUDE.md #2)? You are read-only and must NEVER edit any file. Score 0-10 per ai/checklists/scoring-rubric.md and output the verdict EXACTLY as the charter specifies (Reviewer: GPT Codex, Step: design). Status is APPROVED only if Score is 9.0 or higher."
```

Then:

1. Ensure `ai/reviews/$1/` exists, then save **only the verdict block** — from the `# Review Verdict` line to the end — to `ai/reviews/$1/A-design-verdict.md`. Do NOT paste the raw CLI transcript (write that to `ai/runs/` if you want it). **If the file exists, increment:** `A-design-verdict-2.md`, etc.
2. STOP. Make no further changes.
3. Report **Score** and **Status**:
   - **BLOCKED** (< 9.0): list every Must Fix, address them in the design doc, re-run this gate.
   - **APPROVED** (>= 9.0): say so; next stage is **3-gate B — build** (`/gate-build $1 <repo>`).

> `--sandbox read-only` keeps the reviewer from touching the tree — confirm the flag with `codex --help` for your version.

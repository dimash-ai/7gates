---
description: "Step 1 (think): Opus does, GPT reviews"
argument-hint: <feature-name>
---

# Step 1 — think  ·  Opus does · GPT reviews

**Arguments — parse them yourself.** Raw args: `$ARGUMENTS`

The first whitespace token of the raw args → `<feature>` (the rest, if any, is context, not
positional data). If the raw-args line above looks unsubstituted or empty, recover the tokens from this invocation's command-args instead. This file deliberately uses **no positional dollar-number placeholders** (the runner's `$N` is **0-indexed** — `$1` is the *second* argument, per the Claude Code skills docs — an off-by-one foot-gun against shell conventions); instead, substitute the literal angle-bracket tokens below — in prose AND inside bash blocks — with the parsed values before running anything. An absent optional token substitutes as an **empty string**.


**Doer = Opus (you, in this conversation).** Before running this gate, write the think doc for
`<feature>` to `.ai/think/<feature>.md` following `.ai/think/TEMPLATE.md`: frame the problem, state every
assumption, weigh at least two options, recommend one, and list open questions + success
criteria. If that file does not exist yet, write it now, then continue.

**Reviewer = GPT (Codex), read-only.** Run exactly this one bash command from the pipeline root:

```bash
codex exec --sandbox read-only "$(cat .ai/prompts/reviewer.md)
You are GPT Codex, the reviewer. Step: think. Review ONLY the think doc at .ai/think/<feature>.md (and the kickoff task .ai/tasks/<feature>.md if present). Apply the think lens: is the problem framed correctly, are assumptions explicit, is the recommended option justified against the alternatives, is anything unstated or unbounded? You are read-only and must NEVER edit any file. Score 0-10 per .ai/checklists/scoring-rubric.md and output the verdict EXACTLY as the charter specifies (Reviewer: GPT Codex, Step: think). Status is APPROVED only if Score is 9.0 or higher."
```

Then:

1. Ensure `.ai/reviews/<feature>/` exists, then save **only the verdict block** — from the `# Review Verdict` line to the end — to `.ai/reviews/<feature>/01-think-verdict.md`. Do NOT paste the raw CLI transcript (write that to `.ai/runs/` if you want it). **If the file exists, increment:** `01-think-verdict-2.md`, etc.
2. STOP. Make no further changes.
3. Report **Score** and **Status**:
   - **BLOCKED** (< 9.0): list every Must Fix, address them in the think doc, re-run this gate.
   - **APPROVED** (>= 9.0): say so; next stage is **Step 2 — plan** (`/gate2-plan <feature>`).

> `--sandbox read-only` keeps the reviewer from touching the tree — confirm the flag with `codex --help` for your version.

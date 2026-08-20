---
description: "Explore gate: brainstorm a question with Opus + GPT independently, synthesize findings"
argument-hint: <topic> [repo-path]
---

# Explore gate  ·  Opus + GPT answer independently · synthesize findings

A standalone **exploration gate** — not part of the 7-step or 3-gate build flow, and **not
scored**. Its job: turn your open questions into solid, grounded answers by getting **two
independent perspectives** (Opus and GPT), then synthesizing them into a small findings doc that
improves shared context. The output can later seed `/gate1-think` or `/gate-design`, or just stand
on its own.

`$1` is a short topic slug (e.g. `focal-recurrence-model`). `$2` is an **optional** repo path
(relative to the pipeline root) when the questions are about a codebase GPT should read.

Why no doer/reviewer here: the build gates keep the two models adversarial so neither grades its
own work. Brainstorming is the opposite — the value is two *independent* takes converging or
disagreeing. So both models answer; nobody scores.

## 1 — Capture the questions

Collect the questions for `$1` (from this conversation, or a `## Questions` section in
`ai/notes/$1.md` if you seeded one). Keep them explicit — each finding traces to a question.

## 2 — Opus answers first, independently

**You (Opus), before invoking GPT,** write your own answer to `ai/scratch/$1-opus.md` — for each
question: best answer, reasoning, confidence (High/Medium/Low), assumptions/open points.

**Own the external sourcing.** GPT runs offline in the next step, so you carry the research. For
anything beyond this codebase — library/API behavior, best practices, comparisons, recent changes
— actively verify it: the Context7 docs MCP for library/framework docs, WebSearch/WebFetch for
everything else. Do not answer library or "current best practice" questions from memory. Ground
every factual claim in evidence: `file:line` for repo facts, a page/doc URL for external ones.
Writing your answer *first* keeps you from anchoring on GPT.

## 3 — GPT answers the same questions, independently

GPT must not see Opus's answer. The codex sandbox has **no network**, so GPT's value here is an
independent line of reasoning plus codebase grounding — not external lookup. Run exactly this one
bash command from the pipeline root, with the question list pasted in place of `<QUESTIONS>`.
**Escaping:** the questions land inside a double-quoted shell string — escape any `"` in them (or
pipe them in via a heredoc / a temp file) so the command doesn't break. The same caution applies
anywhere a question, feature name, or topic flows into a `codex exec "…"` string in these gates.

```bash
codex exec --sandbox read-only "You are GPT Codex, brainstorming partner. Answer the following questions about $1 INDEPENDENTLY and from scratch — do NOT look for, assume, or defer to any other model's answer. Questions:
<QUESTIONS>
You have NO network access. Ground claims in repo files you can read read-only (this repo and $2 if a repo path was given) and cite them as file:line. For any claim that needs an external source you cannot verify here, SAY SO and lower your confidence accordingly — do not invent URLs, versions, or API specifics. For EACH question give: (a) your best answer, (b) the reasoning, (c) confidence as High/Medium/Low, (d) any assumptions or open points. Be concise — this feeds a small findings note, not a report. You are read-only and must NEVER edit any file."
```

Save GPT's raw answer to `ai/scratch/$1-gpt.md` (scratch is gitignored). When GPT flags a claim it
couldn't verify offline, that's a cue for you to confirm it with the web/doc sources from step 2.

> **If `codex exec` errors or returns an auth failure, STOP — do not synthesize from Opus's answer
> alone.** This gate *is* two independent takes; one model is not this gate. Codex auth flaps and
> `codex login status` is unreliable — recover with `rm ~/.codex/auth.json && codex login`, then
> re-run this step.

## 4 — Synthesize into the findings doc

Read **both** `ai/scratch/$1-opus.md` and `ai/scratch/$1-gpt.md` and write
`ai/notes/$1.md` following `ai/notes/TEMPLATE.md`. Keep it **small** — findings, not transcripts.
**If `ai/notes/$1.md` already exists from a prior round, read it first and *merge* the new findings
in** — add the new questions, fold now-resolved divergences into Consensus, and preserve earlier
findings; never overwrite a prior round's work.
For each question, classify the two answers:

- **Consensus** — both agree → state it once, mark confidence High, cite the evidence.
- **Divergence** — they disagree or emphasize different things → present *both* views briefly and
  **flag it for your decision**; do not silently pick a winner.
- **Open** — neither resolved it → name exactly what's missing to close it.

## 5 — Loop with the user

Report the Consensus / Divergence / Open summary. The user reacts, decides the divergences, and may
add follow-up questions — then re-run from step 1 for those; step 4 **accumulates** them into the
same `ai/notes/$1.md` rather than replacing it. The gate is "done" when the user is
satisfied; there is no score and nothing to approve.

> `--sandbox read-only` keeps GPT from touching the tree — confirm the flag with `codex --help`. The
> per-model raw answers live in `ai/scratch/` (gitignored); only the synthesized `ai/notes/$1.md`
> is committed.

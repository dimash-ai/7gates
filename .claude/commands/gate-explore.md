---
description: "Explore gate: brainstorm a question with Opus + GPT independently, synthesize findings"
argument-hint: <topic> [repo-path]
---

# Explore gate  ·  Opus + GPT answer independently · synthesize findings

**Arguments — parse them yourself.** Raw args: `$ARGUMENTS`

When the raw args are a short slug, that is `<topic>`; when they are free text (a question or
description, as usual), derive a short kebab-case `<topic>` slug from it yourself. An explicit
repo path mentioned in the args (relative to the pipeline root) is `<repo>`, otherwise there is
no repo. If the raw-args line above looks unsubstituted or empty, recover the tokens from this invocation's command-args instead. This file deliberately uses **no positional dollar-number placeholders** (the runner's `$N` is **0-indexed** — `$1` is the *second* argument, per the Claude Code skills docs — an off-by-one foot-gun against shell conventions); instead, substitute the literal angle-bracket tokens below — in prose AND inside bash blocks — with the parsed values before running anything. An absent optional token substitutes as an **empty string**.


A standalone **exploration gate** — not part of the 7-step or 3-gate build flow, and **not
scored**. Its job: turn your open questions into solid, grounded answers by getting **two
independent perspectives** (Opus and GPT), then synthesizing them into a small findings doc that
improves shared context. The doc frames the topic as a mini-spec — **user story, current
behaviour, expected behaviour, acceptance criteria** — backed by the per-question findings, so
the output can later seed `/gate1-think` or `/gate-design`, or just stand on its own.

`<topic>` is a short topic slug (e.g. `focal-recurrence-model`). `<repo>` is an **optional** repo path
(relative to the pipeline root) when the questions are about a codebase GPT should read.

Why no doer/reviewer here: the build gates keep the two models adversarial so neither grades its
own work. Brainstorming is the opposite — the value is two *independent* takes converging or
disagreeing. So both models answer; nobody scores.

## 1 — Capture the questions and draft the framing

Collect the questions for `<topic>` (from this conversation, or a `## Questions` section in
`.ai/notes/<topic>.md` if you seeded one). Keep them explicit — each finding traces to a question.

Then draft the four framing sections from what is already known: **user story** (as a …, I want …,
so that …), **current behaviour**, **expected behaviour**, **acceptance criteria**. Whatever you
cannot fill yet is not left blank — it becomes one of the questions above. For a pure research
topic with no behaviour change, mark the sections that don't apply N/A and move on.

## 2 — Opus answers first, independently

**You (Opus), before invoking GPT,** write your own answer to `.ai/scratch/<topic>-opus.md` — for each
question: best answer, reasoning, confidence (High/Medium/Low), assumptions/open points. End with
your take on the four framing items: user story, current behaviour as the code actually implements
it (`file:line`), expected behaviour, and the acceptance criteria you would set.

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
codex exec --sandbox read-only "You are GPT Codex, brainstorming partner. Answer the following questions about <topic> INDEPENDENTLY and from scratch — do NOT look for, assume, or defer to any other model's answer. Questions:
<QUESTIONS>
You have NO network access. Ground claims in repo files you can read read-only (this repo and <repo> if a repo path was given) and cite them as file:line. For any claim that needs an external source you cannot verify here, SAY SO and lower your confidence accordingly — do not invent URLs, versions, or API specifics. For EACH question give: (a) your best answer, (b) the reasoning, (c) confidence as High/Medium/Low, (d) any assumptions or open points. Then, for <topic> as a whole, give your independent take on four framing items: (1) user story (as a ..., I want ..., so that ...), (2) current behaviour as the repo actually implements it, cited as file:line, (3) expected behaviour, (4) the acceptance criteria you would set — verifiable checks, each tied to one of your answers. If <topic> is pure research with no behaviour change, say so and mark the items that don't apply N/A. Be concise — this feeds a small findings note, not a report. You are read-only and must NEVER edit any file."
```

Save GPT's raw answer to `.ai/scratch/<topic>-gpt.md` (scratch is gitignored). When GPT flags a claim it
couldn't verify offline, that's a cue for you to confirm it with the web/doc sources from step 2.

> **If `codex exec` errors or returns an auth failure, STOP — do not synthesize from Opus's answer
> alone.** This gate *is* two independent takes; one model is not this gate. Codex auth flaps and
> `codex login status` is unreliable — recover with `rm ~/.codex/auth.json && codex login`, then
> re-run this step.

## 4 — Synthesize into the findings doc

Read **both** `.ai/scratch/<topic>-opus.md` and `.ai/scratch/<topic>-gpt.md` and write
`.ai/notes/<topic>.md` following `.ai/notes/TEMPLATE.md`. Keep it **small** — findings, not transcripts.
**If `.ai/notes/<topic>.md` already exists from a prior round, read it first and *merge* the new findings
in** — add the new questions, fold now-resolved divergences into Consensus, update the framing
sections in place, and preserve earlier findings; never overwrite a prior round's work.
For each question, classify the two answers:

- **Consensus** — both agree → state it once, mark confidence High, cite the evidence.
- **Divergence** — they disagree or emphasize different things → present *both* views briefly and
  **flag it for your decision**; do not silently pick a winner.
- **Open** — neither resolved it → name exactly what's missing to close it.

Then fill the four framing sections from those classified answers: **user story**, **current
behaviour** (code-grounded claims only), **expected behaviour**, and **acceptance criteria** — each
criterion a verifiable check tracing to an answered question. Where the models diverge on expected
behaviour or a criterion, keep both views in Divergence and mark the section **pending decision**;
never pick silently.

## 5 — Loop with the user

Report the Consensus / Divergence / Open summary. The user reacts, decides the divergences, and may
add follow-up questions — then re-run from step 1 for those; step 4 **accumulates** them into the
same `.ai/notes/<topic>.md` rather than replacing it. The gate is "done" when the user is
satisfied — in practice, when the acceptance criteria are agreed; there is no score and nothing
to approve.

> `--sandbox read-only` keeps GPT from touching the tree — confirm the flag with `codex --help`. The
> per-model raw answers live in `.ai/scratch/` (gitignored); only the synthesized `.ai/notes/<topic>.md`
> is committed.

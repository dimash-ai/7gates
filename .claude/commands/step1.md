---
description: "Step 1 (brief): your request — your words or a Linear ticket — rephrased in minutes into a short brief for step 2: the problem, the user stories, the MVP"
argument-hint: <slug> [repo-path]
---

# Step 1 — brief  ·  Opus rephrases · you confirm

The first step of the **co-dev flow** (`harness/README-codev.md`). It takes what the requester gives
(their words, a problem, a Linear ticket, a screenshot, a design) and **rephrases it into a short
brief**: the prompt step 2 plans from. What we want to do, which problem it solves for whom, the user
stories, and the **MVP**: the least a user must see on dev to say "this is it". Step 2 turns the
brief into stages; step 3 ships them.

**Fast by design: about ten minutes to the stop.** Opus alone, from the input alone: no second model,
no research, no reading of the code, no subagents, no plan, no branch. The brief stays under about
80 lines. If ultracode or a high effort is on, do not spend it here. GPT reads the brief cold in
step 2, so an ambiguity this step misses comes back there as a question.

`$1` is the slug: the Linear id when there is an issue (`ALL-646`), otherwise a short kebab-case
name. `$2` is the code repo, optional. If the arguments carry anything else (a URL, a path, the
requester's words), it is part of the input, not `$1` or `$2`: run the block with the slug and an
empty repo argument.

**Paths.** The block sources `harness/bin/codev-env.sh`, which prints `codev: slug=… results=<S> …`;
`<S>` and `<H>` (the `harness/` directory) mean those literal paths. `<S>` is the code repo's
`specs/$1/`, gitignored: in the main checkout, or in this session's own worktree when it runs in one.
Link the brief to the requester as `[brief.md](specs/$1/brief.md)`, relative to the session's working
directory, never as a bare path.

## 1a — The input

Collect it **verbatim**, in the requester's language: what they said, and for a Linear issue its
title, description, comments, attachments (transcribe screenshots: their signed URLs expire) and its
milestone's target date (Linear MCP when connected, otherwise ask once). Note the sources it names
(a design handoff, a prototype) by path, and open them only as far as the rephrasing needs. If the
input is too thin to rephrase (no product, no user, no outcome), ask once, then go on.

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
mkdir -p "$S" && echo "brief: $S/brief.md   harness: $(git -C "$H" rev-parse --short HEAD)$([ -n "$(git -C "$H" status --porcelain -- .claude briefs checklists design prompts bin)" ] && echo ' (with uncommitted changes)')"
```

## 1b — Rephrase it into the brief

Write `<S>/brief.md` from `<H>/briefs/TEMPLATE.md`: the header (`Linear:`, `Deadline:`, `Date:`,
`Harness:` from the block, and `Branch:` and `Base:` as proposed defaults) and its sections, each one
short.

- **In short is the heart of it**: the request as the prompt the requester meant to write, for a
  reader who never saw the conversation.
- **The MVP comes from the request's literal words** (`<H>/checklists/mvp.md` §3). What a design or a
  prototype shows beyond them is `[later]` and goes to Not now: kept, not dropped, and not MVP.
- **Write only what the input says or plainly implies.** Mark every inference `(assumed)`. Read
  through speech-to-text slips, but never turn a word into a different requirement.
- **Product terms only**: screens, flows, the words users see; never modules, endpoints or tables.
- **Nobody better off**: if no user gains anything, say so. That is rung 1 of
  `<H>/checklists/ponytail.md`, and the requester decides whether to build it.

## 1c — The yes

**STOP.** Show in the chat: In short, the MVP, the user stories with their criteria, Not now, the
assumptions, and Branch and Base; link the brief. Ask **at most three questions**, and only those
whose answer changes the MVP and has no safe default (`mvp.md` §4: one decision each, the smallest
option first with what it costs, "Later" always offered). Everything with a safe default is already
in the brief as `(assumed)`, and the requester's yes accepts it.

Their corrections go into the brief, their answers under Assumptions and questions with the date.
Their yes ends step 1. Next: `/step2 $1`.

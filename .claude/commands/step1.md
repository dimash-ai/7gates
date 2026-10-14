---
description: "Step 1 (brief): your request — your words or a Linear ticket — rephrased in minutes into a short brief: the problem, the user stories, the MVP, and whether there is something to draw; goes straight on into the design (or into step 2 when nothing users see changes) unless it must ask"
argument-hint: <slug> [repo-path]
---

# Step 1 — brief  ·  Opus rephrases · straight on to the design

The first step of the **co-dev flow** (`harness/README-codev.md`). It takes what the requester gives
(their words, a problem, a Linear ticket, a screenshot, a design) and **rephrases it into a short
brief**: what we want to do, which problem it solves for whom, the user stories, and the **MVP**: the
least a user must see on dev to say "this is it". The design step draws it and the requester
confirms the drawing; step 2 turns the brief and the confirmed design into stages; step 3 ships them.

**Fast by design: about ten minutes, and no stop unless it must ask.** Opus alone, from the input
alone: no second model, no research, no reading of the code, no subagents, no plan, no branch. The
brief stays under about 80 lines. If ultracode or a high effort is on, do not spend it here. In the
stages lane GPT reads the brief cold when it reviews the plan in step 2, so an ambiguity this step
misses comes back there as a question. The requester sees the brief together with the design at the
design step's stop, the flow's one stop before any code (`<H>/checklists/mvp.md` §4); a brief with
nothing to draw is seen with the plan at step 2's stop instead.

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
`Harness:` from the block, `Branch:` and `Base:` as proposed defaults, `Lane:` and `Design:`) and
its sections, each one short.

- **In short is the heart of it**: the request as the prompt the requester meant to write, for a
  reader who never saw the conversation.
- **The MVP comes from the request's words** (`<H>/checklists/mvp.md` §3): the least of it a user
  must see. The rest of what the request or its PM design asks for is `[later]`: kept as later
  stories, not dropped. The design step draws both, the MVP marked, and the requester's ok on the
  drawing fixes the scope.
- **The design** (`<H>/checklists/mvp.md` §11), in the header as `Design:`: `none` when nothing users
  see changes (no new or changed screen, state or text: a backend fix, delivery, infra,
  monitoring); `handoff <path>` when the input names a PM design for it (a prototype, a handoff
  folder), with its path; otherwise `html`, a prototype the design step draws.
- **Write only what the input says or plainly implies.** Mark every inference `(assumed)`. Read
  through speech-to-text slips, but never turn a word into a different requirement.
- **Product terms only**: screens, flows, the words users see; never modules, endpoints or tables.
- **Nobody better off**: if no user gains anything, say so. That is rung 1 of
  `<H>/checklists/ponytail.md`, and the requester decides whether to build it.
- **The lane** (`<H>/checklists/mvp.md` §9), in the header as `Lane:`: `quick` when the request
  reads as one stage of at most about two hours with low risk (no schema change or backfill, no
  auth, tenant or RLS surface, no deletes or rewrites of existing records); otherwise, or when
  unsure, `stages`. It is a guess from the input; step 2 checks it against the code.

## 1c — Ask only what you must, then go straight on

Show in the chat, briefly: In short, the MVP, Not now, the assumptions, the lane, the design, Branch
and Base; link the brief.

**Stop only for a question** whose answer changes the MVP and has no safe default: at most three
(`mvp.md` §4: one decision each, the smallest option first with what it costs, "Later" always
offered). Everything with a safe default is already in the brief as `(assumed)`; the requester
sees it with the design (or, with nothing to draw, with the plan) and can correct it there. Answers
go under Assumptions and questions with the date.

With nothing to ask, or once it is answered, **go straight on**: invoke `/design $1` yourself with
the Skill tool when the brief says `Design: html` or `Design: handoff`, and `/step2 $1` when it says
`Design: none`; the slug is the only argument (never the requester's words or a URL). Do not wait
for the requester to type it.

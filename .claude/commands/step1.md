---
description: "Step 1 (brief): Opus and GPT each draft the product brief from your request (the problem, who it is for, user stories, the business side); the union, confirmed by you, goes to step 2"
argument-hint: <slug> [repo-path]
---

# Step 1 — brief  ·  you + Opus · Opus and GPT draft independently

The first step of the **3-step co-dev flow** (`harness/README-codev.md`). It states the problem and
the business task from the user's side: what we want to achieve, for whom, whether they are better
off, and the user stories that say so. **Opus and GPT each draft it from the request alone**, Opus
merges the two drafts into **one document, `brief.md`**, and the requester confirms it. That
document goes to step 2, which researches the code against it and plans. Nothing technical happens
here: no code is read and no branch is made. The brief says *what* and *why*; step 2 finds out
*how*.

`$1` is the slug: the Linear id when there is an issue (`ALL-646`), otherwise a short kebab-case
name. `$2` is the code repo, optional: the current git repo, or `superapp` when run inside
`superapp/harness`.

Not scored. Two independent drafts buy **coverage**, not agreement: two models read the same request
differently, so the merge is a union, and where the drafts disagree about what was asked, the request
was ambiguous and the requester decides. The gate is the requester: the step ends when they confirm
the brief.

**Paths.** Every bash block below starts by sourcing `harness/bin/codev-env.sh`, which prints one
line: `codev: slug=… results=<S> …`. In the prose, `<S>` and `<H>` (the `harness/` directory) mean
those literal paths. Results land in `<S>` = the code repo's `specs/$1/`, gitignored in superapp: in
the **main** checkout, or, when this session runs in a worktree of its own
(`.claude/worktrees/<name>`, the Claude desktop app's default), in that worktree. The app lets such
a session write nowhere else.

## 1a — The request, verbatim

Both drafters get the request and nothing else, so it holds the requester's words, not anyone's
reading of them.

1. Collect the request **verbatim**, in the requester's language: the command arguments and what
   they said. If the work has a Linear issue, take its title, description, comments, attachments and
   `gitBranchName` too (Linear MCP if connected, otherwise ask for them).
2. List the sources the request names or plainly needs: a design handoff or prototype, screenshots,
   the app's product docs (`apps/<app>/docs/`). Paths or URLs, no summary.
3. Write both to `<S>/product/request.md`, the words first, then the sources. This block prints `<S>`
   and creates its folders:

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
mkdir -p "$S/product" "$S/runs" && echo "request: $S/product/request.md"
```

Ask nothing yet, unless the request is too thin for anyone to draft from (no app, no user, no
outcome): then ask once and add the answer to the request, verbatim. Ambiguity is what the two
drafts are for.

## 1b — Two product drafts, independent and in parallel

Start GPT first, then draft yourself while it runs. **Do not open `<S>/product/codex.md` until
`<S>/product/opus.md` is written**: reading GPT first anchors you on it, and the union stops being
two views. GPT drafts in the code repo, so `<S>` sits inside its working directory: keep your draft
in the scratchpad until GPT's run has exited, and only then write `opus.md`. The block writes GPT's
output to files and prints only its exit status, so nothing of the draft reaches you early.

**GPT**: read-only, in the code repo, web search on, the prompt read from a file and the final
message written by `-o`. Run it **in the background** (Bash `run_in_background`).

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
[ -s "$S/product/request.md" ] || { echo "codev: $S/product/request.md is missing - finish 1a first"; exit 1; }
P="$S/runs/product-codex.prompt.md"
{ printf 'THE REQUEST, verbatim:\n\n'; cat "$S/product/request.md"
  printf '\n\nTHE PRODUCT BRIEF TEMPLATE:\n\n'; cat "$H/briefs/PRODUCT.md"
  cat <<'EOF'

You are GPT Codex, drafting the product brief for the request above, INDEPENDENTLY and from scratch: do not look for, assume, or defer to any other model's draft. Your working directory is the code repo. This is product work, not engineering: the problem, who the change is for, what changes for them, whether they are better off, and why the business wants it. Read the product, not the code: the sources the request names, the app's product docs (apps/<app>/docs/), the words its screens show users today (apps/<app>/client/src/i18n/locales/ru.json), and who gets what (docs/ENTITLEMENTS.md). Use web search only for facts outside the repo, such as how comparable products handle this, and cite the URL; if you have no web access, say so, and never invent a URL.
Write the brief in the structure of the template, filling its sections in order. In short comes first: the request as the prompt the requester meant to write, for a reader who never saw it. Then the user stories, one per distinct thing a user can do or get, each with a priority, every criterion observable from the user's side and numbered (US-1.1). Then who it is for and what changes for them, whether they benefit and who could be worse off, the unhappy paths, the business and marketing lines (the release note in Russian), what is out of scope, the questions only the requester can answer (each with the answer you would assume), the sources you read, and the requester's words verbatim. The requester often dictates: read through speech-to-text slips, but never turn a word into a different requirement; where a word can mean two things, make it a question. Mark everything you inferred rather than read in the request or a source (assumed). If no end user is better off (a refactor, infrastructure), say so and write the stories for whoever is; never invent a story for a user who does not care. Name no modules, endpoints, tables or designs: step 2 researches the code. Do not open or quote any .env file. You are read-only and must NEVER edit any file. Your FINAL message must be the complete product brief in Markdown and nothing else.
EOF
} > "$P"
cd "$R" && codex exec --sandbox read-only --config 'web_search="live"' -o "$S/product/codex.md" - < "$P" > "$S/runs/product-codex.log" 2>&1
echo "codex exit=$?  draft bytes=$(wc -c < "$S/product/codex.md" 2>/dev/null || echo 0)"
```

- An empty draft or a non-zero exit is a failed run: read `<S>/runs/product-codex.log` (not the
  draft). If this Codex version rejects `--config 'web_search="live"'`, drop the flag and re-run.
- If `codex exec` fails auth, **STOP**. One draft is not this step. Recover with
  `rm ~/.codex/auth.json && codex login`, then re-run.

**Opus (you)**: the same request, the same template and the same rules as GPT's prompt, written to
`<S>/product/opus.md`. Read the product, not the code: the sources in the request, the app's product
docs, what its screens say today (`apps/<app>/client/src/i18n/locales/ru.json`), who gets what
(`docs/ENTITLEMENTS.md`), and PostHog when how many people use something would change a story.

## 1c — Merge by union into the brief

When the background run has finished and `opus.md` is written, read both drafts. Start
`<S>/brief.md` from `<H>/briefs/TEMPLATE.md`: its header, with `Linear:` and `Date:` filled in, and
its product part, in the sections of `<H>/briefs/PRODUCT.md`. The research part stays out: step 2
appends it.

- **Union, not intersection.** A story, criterion, unhappy path or question only one draft has is
  the coverage you paid for. Tag every item `[O]`, `[G]` or `[both]`, and number the stories and
  their criteria afresh (`US-1`, `US-1.1`).
- **One In short.** Where the drafts read the request the same way, write one In short from both.
  Where they read it differently (another user, another outcome, another scope), do not pick: that is
  the request's ambiguity, and it is a question for the requester.
- **Contradictions** (who it is for, whether they benefit, what is in or out of scope, who gets it)
  are questions for the requester, never settled by the more confident draft.
- **`(assumed)` stays marked** until the requester confirms or strikes it.
- **Re-check GPT's sources.** A path that does not exist, or does not say what the draft claims, is
  fixed or dropped, and the brief says so.
- **Nobody better off.** If either draft finds that no one is, that is rung 1 of the ladder in
  `<H>/checklists/ponytail.md`: ask whether to build it at all.

## 1d — Get the yes

Ask the merge's questions in one round, each with the answer you would assume, so that a yes
settles it (AskUserQuestion for discrete choices). Propose in the same round the three settings
step 2 needs:

- **Depth** of step 2's research. *quick*: a fix or a small change in a known place; Territory,
  Prior art, Tests and Scars, around the screens and flows the brief names. *full*: a feature, or
  anything with real unknowns; all six sections, plus sources outside the repo.
- **Branch.** Linear's `gitBranchName` when there is an issue. Otherwise the app's convention:
  `feat/focal-<slug>` for Focal (`apps/focal/CLAUDE.md`), `feature/<slug>` or `fix/<slug>`
  elsewhere. Every slug needs a branch of its own.
- **Base.** `dev` for superapp.

**STOP** until the requester says yes. Show In short, the stories with their criteria, the questions
and the settings in the chat; the whole document is `<S>/brief.md`. Their answers go into the stories
and under Questions and answers, with the date; the settings go into the header as `Branch:`,
`Base:` and `Depth:`, one per line, plain values with no backticks or bold. Their yes ends step 1.
Next: `/step2 $1`.

If they only wanted the product brief, it stands on its own, and step 2 can follow at any time. If
they reject the In short itself (a different request), start step 1 over from their new words.

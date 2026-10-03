---
description: "Step 1 (brief): the request becomes a short product brief with the MVP cut — stage 1, the next stages, Not now; Opus and GPT draft independently, you confirm stage 1"
argument-hint: <slug> [repo-path]
---

# Step 1 — brief and MVP  ·  Opus and GPT draft independently · you confirm

The first step of the **co-dev flow** (`harness/README-codev.md`). It turns the request into a short
brief: what we want, for whom, the **hypothesis**, and the point of this step, **the MVP cut**:
**stage 1** is the least a user must see on dev to say "this is it", then the **next stages** in
value order, each one user-visible, then **Not now**. Step 2 plans those stages; step 3 ships them to
dev one at a time. **Opus and GPT each draft the brief independently**, Opus merges them, the
requester confirms.

**Read `<H>/checklists/mvp.md` first.** Its rules decide every cut and every question below. The
flow's measure of success is how soon a user sees something real on dev, not how complete the brief
is.

**Timebox: about 45 minutes** of your own work to the stop, plus GPT's run in the background. A
brief is under about 150 lines. Nothing is built here and no branch is made.

`$1` is the slug: the Linear id when there is an issue (`ALL-646`), otherwise a short kebab-case
name. `$2` is the code repo, optional: the current git repo, or `superapp` when run inside
`superapp/harness`. If the arguments carry anything else (a URL, a path, the requester's words), it
belongs in the request (1a), not in `$1`/`$2`: run every block below with the slug and an empty repo
argument.

**Paths.** Every bash block below starts by sourcing `harness/bin/codev-env.sh`, which prints one
line: `codev: slug=… results=<S> …`. In the prose, `<S>` and `<H>` (the `harness/` directory) mean
those literal paths. Results land in `<S>` = the code repo's `specs/$1/`, gitignored in superapp: in
the **main** checkout, or, when this session runs in a worktree of its own
(`.claude/worktrees/<name>`, the Claude desktop app's default), in that worktree. The app lets such
a session write nowhere else.

**Links.** When you point the requester at a file of the flow (the brief above all), write a
markdown link whose target is the file's path relative to the session's working directory, usually
`[brief.md](specs/$1/brief.md)`; never a bare path in backticks. In the Claude desktop app a click
on that link opens the file; `specs/` is gitignored, so it never shows in the diff pane.

**Speed rule.** This step drafts and asks; it does not research the code in depth, write a design or
plan the stages' internals. If ultracode or a high effort is on, do not spend it here on extra
drafts, extra reviewers or longer documents (`mvp.md` §6).

## 1a — The request, verbatim

Both drafters get the request and nothing else, so it holds the requester's words, not anyone's
reading of them.

1. Collect the request **verbatim**, in the requester's language: the command arguments and what
   they said. If the work has a Linear issue, take its title, description, comments, attachments, its
   project and milestone with the **target date**, and its `gitBranchName` (Linear MCP if
   connected, otherwise ask for them). A target date is the deadline the stage map is cut against.
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
outcome): then ask once and add the answer to the request, verbatim. Ambiguity is what the two drafts
are for.

## 1b — Two drafts, independent and in parallel

Start GPT first, then draft yourself while it runs. **Do not open `<S>/product/codex.md` until your
own draft is finished**: reading GPT first anchors you on it, and the two views collapse into one.
GPT drafts in the code repo, so `<S>` sits inside its working directory: keep your draft in the
scratchpad until GPT's run has exited, and only then write `<S>/product/opus.md`. The block writes
GPT's output to files and prints only its exit status.

**GPT**: read-only, in the code repo, web search on, the prompt read from a file and the final
message written by `-o`. Run it **in the background** (Bash `run_in_background`).

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
[ -s "$S/product/request.md" ] || { echo "codev: $S/product/request.md is missing - finish 1a first"; exit 1; }
P="$S/runs/product-codex.prompt.md"
{ printf 'THE REQUEST, verbatim:\n\n'; cat "$S/product/request.md"
  printf '\n\nTHE MVP LENS (binding):\n\n'; cat "$H/checklists/mvp.md"
  printf '\n\nTHE PRODUCT BRIEF TEMPLATE:\n\n'; cat "$H/briefs/PRODUCT.md"
  cat <<'EOF'

You are GPT Codex, drafting the product brief for the request above, INDEPENDENTLY and from scratch: do not look for, assume, or defer to any other model's draft. Your working directory is the code repo. This is product work: the problem, who the change is for, what changes for them, and above all the MVP CUT, following the MVP lens above. STAGE 1 is the least a user must see on the dev environment to say "this is it", buildable in about four hours. Then the NEXT STAGES in value order, each one user-visible on dev and at most about four hours of build (a bigger one is two stages). Then NOT NOW: everything the request or a design shows that no stage builds, each a candidate follow-up ticket. Start from the request's literal words: what the requester or the ticket names is in scope; what a design or prototype shows beyond it is a candidate for a later stage or Not now, never a requirement of stage 1.
Read the product: the sources the request names, the app's product docs (apps/<app>/docs/), the words its screens show users today (apps/<app>/client/src/i18n/locales/ru.json), who gets what (docs/ENTITLEMENTS.md). You may skim the code read-only, for at most about ten minutes, only to see what already exists (an editor, a screen, a list, an endpoint) and so size the stages and spot reuse; name what exists in product terms ("the full task card already opens from the calendar"), never modules, files, endpoints or tables. Use web search only for facts outside the repo, cite the URL, and never invent one.
Write the brief in the template's structure, short: the whole brief under about 150 lines. In short; Stage 1 with the criteria it meets and what it reuses; Next stages as the template's table; Not now; the Hypothesis (a fix or a chore says Hypothesis: none, and why); user stories whose every criterion carries an id and the stage that delivers it (US-1.1 [s1]), with no criteria written for Not now items; Who and why with the release note in Russian; stage 1's unhappy paths; questions; the sources you read; the requester's words verbatim. QUESTIONS: at most five, each ONE decision, never a bundle of several points under one yes; the first option is the smallest that still serves the request, with what each option costs in plain words (hours, a migration or a data backfill, which screens users have today it changes); a question that widens scope always offers "later, as a follow-up ticket". Ask only what only the requester can answer. The requester often dictates: read through speech-to-text slips, but never turn a word into a different requirement. Mark everything you inferred rather than read (assumed). Do not open or quote any .env file. You are read-only and must NEVER edit any file. Your FINAL message must be the complete brief in Markdown and nothing else.
EOF
} > "$P"
cd "$R" && codex exec --sandbox read-only --config 'web_search="live"' -o "$S/product/codex.md" - < "$P" > "$S/runs/product-codex.log" 2>&1
echo "codex exit=$?  draft bytes=$(wc -c < "$S/product/codex.md" 2>/dev/null || echo 0)"
```

- An empty draft or a non-zero exit is a failed run: read `<S>/runs/product-codex.log` (not the
  draft). If this Codex version rejects `--config 'web_search="live"'`, drop the flag and re-run.
  If the configured model is rejected, re-run with `-m <a model from ~/.codex/models_cache.json>`.
- If `codex exec` fails auth, **STOP**. One draft is not this step. Recover with
  `rm ~/.codex/auth.json && codex login`, then re-run.

**Opus (you)**: the same request, the same lens, the same template and the same rules as GPT's
prompt. Skim the code only to size stages and spot reuse (about ten minutes); read PostHog through
its MCP, read-only, when how many people use a screen would change the cut, and put the signal's
value today in the Hypothesis baseline. Never a database: superapp's rule against agents touching
dev or prod holds here too.

## 1c — Merge: union for coverage, intersection for commitment

When the background run has finished and your draft is written to `<S>/product/opus.md`, read both.
Write `<S>/brief.md` from `<H>/briefs/TEMPLATE.md` (its header, with `Linear:`, `Deadline:`,
`Date:` and `Harness:` filled, the last from `git -C <H> rev-parse --short HEAD`) followed by the
sections of `<H>/briefs/PRODUCT.md`:

- **Stage 1 is the intersection.** It holds what the request's literal words require, plus what both
  drafts put into stage 1. Where the drafts cut stage 1 differently, take the smaller one, and the
  difference becomes a question with the smaller option first.
- **Everything else is the union.** A story, a stage, an unhappy path or a Not-now item only one
  draft has is the coverage you paid for: it goes into Next stages or Not now, tagged `[O]` or `[G]`,
  never silently into stage 1. Number the stories and their criteria afresh, each criterion with its
  stage (`US-1.1 [s1]`).
- **Contradictions** about who it is for, whether they benefit, or what the request asks for are
  questions for the requester, never settled by the more confident draft.
- **One hypothesis.** Where the drafts bet on different outcomes or signals, keep both and ask.
- **Re-check what the drafts say exists.** A screen or flow claimed to exist that does not, or a path
  that is wrong, is fixed or dropped, and the brief says so.
- **Nobody better off** (either draft finds no user who is): that is rung 1 of
  `<H>/checklists/ponytail.md`; ask whether to build it at all.
- **Deadline.** With a target date, mark in Next stages which stages land before it at about one
  stage per half day. If stage 1 itself cannot land before it, say so first.
- **Keep it short.** Over about 150 lines means something belongs in a later stage's planning or in
  Not now.

## 1d — Get the yes

Ask the merge's questions in **one round**, following `mvp.md` §4: at most five, one decision each,
the smallest option first marked (Recommended), every option with its cost, "Later — a follow-up
ticket" on every question that widens scope (AskUserQuestion). A question whose smallest option is
safe is not asked: it goes into the brief as an `(assumed)` answer, listed at this stop so the
requester can overturn it. A larger option the requester picks
goes into the stage where it fits, not into stage 1, unless they say stage 1 needs it. Propose in the
same round:

- **Branch**: the base name of the stage branches, **without the Linear id**:
  `feat/focal-<short-name>` for Focal (`apps/focal/CLAUDE.md`), `feature/<short-name>` or
  `fix/<short-name>` elsewhere. Stage N is built on `<Branch>-s<N>`; the id stays out of branch
  names and PR titles so that merging stage 1 does not close the Linear issue (`briefs/TEMPLATE.md`
  explains). Every slug needs a branch name of its own.
- **Base**: `dev` for superapp.

Then create the progress board: `<S>/progress.md` from `<H>/briefs/PROGRESS.md`, one row per stage,
all `planned`.

**STOP** until the requester says yes. Show in the chat: In short, **Stage 1** (what users will see
on dev), the **Next stages** table, **Not now**, the Hypothesis in one line, the questions, the
settings, and the progress board; link the whole document, `<S>/brief.md` (see **Links**). Their
answers go into the brief: the stages and stories they change, and under Questions and answers with
the date; `Branch:` and `Base:` into the header, one per line, plain values. Their yes ends step 1.
Next: `/step2 $1`.

If they reject the In short itself (a different request), start step 1 over from their new words. If
they only wanted the brief, it stands on its own, and step 2 can follow at any time.

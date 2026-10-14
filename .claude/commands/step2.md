---
description: "Step 2 (plan): Opus plans the stages from the brief, the confirmed design and the code, every stage in detail so step 3 only implements; GPT reviews the plan blind (no GPT in the quick lane); after a confirmed design step 3 starts at once, and only a task with nothing to draw stops for you to confirm the brief and the stages"
argument-hint: <slug> [repo-path]
---

# Step 2 — the stage plan  ·  Opus plans · GPT reviews · then the build

The second step of the **co-dev flow** (`harness/README-codev.md`). It turns the brief from step 1,
and the design the requester confirmed, into **the stage plan**: the **stage map** (every stage, one
row: what users get on dev, its demo script, budget, risk, guard) and **every stage's detail**,
stage 1's the fullest. All the planning happens here, so that step 3 is implementation and nothing
else. **Opus plans**, from the brief, the confirmed design and the code: it builds every stage, so
the plan is its own commitment, and it plans with what this session knows (the requester's words,
the repo's rules, the traps on record). **GPT reviews the plan blind**: a separate `codex exec` that
sees the brief, the design, the plan and the code, and nothing of this conversation, so no model
grades its own work and the brief is read cold. In the **quick lane** (the brief's `Lane: quick`,
`mvp.md` §9) Opus plans the one stage (2q) and no GPT runs. **After a confirmed design**
(`Design: html` or `handoff`) the requester's ok on the design was the flow's one stop before code,
so step 2 does not stop: it reports the stages and starts step 3 at once (2e). **With nothing to
draw** (`Design: none`) step 2 ends at the one stop instead: the requester confirms the brief and
the stages together, and their yes starts step 3. When the map changes later (dev showed something,
the requester re-orders or adds), this step runs again and re-plans only the stages not yet started.

There is no separate research phase: the planner reads the code it plans against and cites it as
`file:line`, and GPT checks the citations the plan rests on. For an epic with large unknowns, run
`/gate-explore` before step 1, not here.

**Timebox: about half an hour** to 2e: Opus's plan (about fifteen minutes) and GPT's review (about
ten, in the background), with at most one fix round; about ten minutes in the quick lane. The plan
is under about 300 lines.

`$1` is the slug from step 1; `$2` is the code repo, optional. Every bash block sources
`harness/bin/codev-env.sh`, which prints `codev: slug=… results=<S> worktree=<WT> …`; in the prose,
`<S>`, `<WT>` and `<H>` (the `harness/` directory) mean those literal paths.

**Links.** When you point the requester at a file of the flow (the plan, the brief, a verdict), write
a markdown link whose target is the file's path relative to the session's working directory, usually
`[plan.md](specs/$1/plan.md)`; never a bare path in backticks.

**Speed rule.** If ultracode or a high effort is on, do not spend it here on extra planners, extra
reviewers, research sweeps or longer documents (`mvp.md` §6). One planner, one review.

## Before you start — where this slug stands

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header && codev_need_design || exit 1
if [ -d "$WT" ]; then echo "worktree: on $(git -C "$WT" branch --show-current)"; else echo "worktree: not yet - start at 2a"; fi
[ -s "$S/plan.md" ] && echo "plan: $(wc -l < "$S/plan.md") lines" || echo "plan: not yet"
[ -s "$S/progress.md" ] && grep -E '^\| [0-9]+ ' "$S/progress.md"
ls "$S/reviews" 2>/dev/null | grep '^plan-' || echo "no plan review yet"
```

No brief header means step 1 is not finished. **A re-plan** (a plan exists and some stages are
already on dev) keeps the worktree where it is: skip 2a, and the round numbering of the plan reviews
continues.

## 2a — The worktree, on stage 1's branch

It pins the tree Opus plans against and builds stage 1 in: the branch `<Branch>-s1`, cut from the
remote tip of the base. In a session with a worktree of its own, the block moves that worktree onto
the branch instead of adding one; it must be clean (the flow's files do not count: `specs/` is
gitignored), and the app's own `claude/…` branch stays behind, unused.

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header || exit 1
mkdir -p "$S/reviews" "$S/runs"
B1="$BR-s1"
git -C "$M" fetch origin "$BASE" --quiet || { echo "codev: cannot fetch origin/$BASE"; exit 1; }
git -C "$M" fetch origin "refs/heads/$B1:refs/remotes/origin/$B1" --quiet 2>/dev/null   # stage 1's branch, if it already exists on origin
has_b1() { git -C "$M" show-ref --verify --quiet "refs/heads/$B1" || git -C "$M" show-ref --verify --quiet "refs/remotes/origin/$B1"; }
if [ "$WT" = "$R" ]; then   # the session's own worktree (see codev-env.sh): move it onto the branch
  if [ "$(git -C "$WT" branch --show-current)" != "$B1" ]; then
    [ -z "$(git -C "$WT" status --porcelain)" ] || { echo "codev: $WT has uncommitted changes - commit or move them, then re-run"; exit 1; }
    if has_b1; then git -C "$WT" switch "$B1" || exit 1; else git -C "$WT" switch --no-track -c "$B1" "origin/$BASE" || exit 1; fi
  fi
elif [ -d "$WT" ]; then
  echo "worktree exists on $(git -C "$WT" branch --show-current)"
elif has_b1; then
  git -C "$M" worktree add ".worktrees/$SLUG" "$B1" || exit 1
else
  git -C "$M" worktree add --no-track -b "$B1" ".worktrees/$SLUG" "origin/$BASE" || exit 1
fi
echo "planning at: $(git -C "$WT" rev-parse --short HEAD) $(git -C "$WT" log -1 --format=%cs) on $(git -C "$WT" branch --show-current)"
```

## 2q — Quick lane: Opus plans the one stage

Only when the brief says `Lane: quick`; it takes the place of 2b, and 2c and 2d do not run. Read the
confirmed design (`<S>/design/`, when there is one) and the code the request touches in `<WT>` (file
reads, grep and git only), then write `<S>/plan.md` from `<H>/design/TEMPLATE-stages.md` with one
stage: its row on the map (what users get on dev, the demo, a budget of at most about two hours,
risk `low`, the guard) and its detail (the approach with the `file:line` it builds on, the files,
the tests), under about 60 lines.

If the code shows the stage is not quick (a migration or a backfill, an auth, tenant or RLS surface,
deletes or rewrites of existing records, more than one stage, or more than about two hours), it
leaves the lane: set `Lane: stages` in the brief, say why in one line, and plan it in 2b. No model
grades this plan, because the quick lane runs no GPT: the requester's ok on the design is its check,
or, with nothing to draw, their yes at 2e. Go to 2e.

## 2b — Opus plans the stages

**Doer = Opus (you)**, in this session, with `<H>/prompts/doer.md` as your charter. Read the brief,
the confirmed design (`<S>/design/`: its README and the prototype), `<H>/checklists/mvp.md`,
`<H>/checklists/ponytail.md`, and the code in `<WT>` with file reads, grep and git only (no `uv`,
`pnpm` or installs yet: they stall in a fresh worktree). Then write `<S>/plan.md` from
`<H>/design/TEMPLATE-stages.md`, under about 300 lines. Keep your working notes in the scratchpad:
GPT's working directory may contain `<S>`.

- **The stage map and every stage's detail.** Step 3 has no design step, so whatever building a stage
  needs is planned here. Stage 1 is the brief's MVP; if something smaller still meets its criteria
  and is what a user would recognise, plan that and say why in the Decision. Every stage is
  user-visible on dev, with a demo script a person can follow there, a budget of at most about four
  hours of build, a risk class (low, data, auth) and a guard (additive, a hidden route, a dev-only
  flag). A foundation without a visible result is folded into the first stage that uses it, or is a
  stage of about two hours that the very next stage uses. Order the stages by value to the user; a
  migration, a backfill or a new server contract goes into the stage that first needs it.
- **Stage 1's detail is the fullest**; a later stage's is short (what the user gets, the approach
  with the `file:line` it builds on, the files, the tests, the data), because the code will have
  moved by the time it is built.
- **The confirmed design is the scope of what users see**: stage 1 delivers the screens and states it
  marks MVP, as drawn (layout, copy), and later stages the ones marked Later. Stage 1's data model
  and API take the shape of the whole design (`mvp.md` §3), so that no later stage rewrites them.
- **Tests prove the stage** (`mvp.md` §6): its demo path, a regression guard for every behaviour
  users have today that it touches, and the repo's mandatory proofs. Edge cases of the new feature
  beyond the demo path go under the stage's Not in this stage.
- **Every claim about existing code cites `file:line`**, and every new file, module, dependency or
  abstraction names the ladder rung it stopped at. A version-sensitive claim names the version the
  lockfile pins.
- **The superapp rules**, wherever they apply: the rule headed AI-track code in the repo's
  `CLAUDE.md`, as written; a schema change ships its Alembic revision with RLS and grants written in
  and the sandbox proof (`scripts/migration-sandbox.sh` with the app's server dir and schema, plus an
  assertion that the policies exist), additive only, never applied to a shared database; DB-backed
  behaviour is tested by the app's real-DB suite against that sandbox; user-facing strings go
  through i18next with ru and en; the verification commands are the jobs of
  `.github/workflows/ci-<app>.yml` for each app a stage touches.
- **The Hypothesis signal**: when it does not exist yet, one stage adds it, through the app's own
  analytics helper.
- **Build on what the brief records as answered or decided**; do not reopen it. An ambiguity that
  would change stage 1 is a question for the requester before you finish (`mvp.md` §4: a safe
  default is taken as `(assumed)` instead of waited for); one that only touches a later stage is
  planned as an assumption marked UNVERIFIED.
- **A re-plan** keeps every stage that is building, in review, in a PR, on dev or verified exactly as
  it is, map row and detail, and re-plans only the stages not yet started, against the code as it is
  now and the brief as it is now. Copy the current plan to `<S>/plan.prev.md` first.

## 2c — GPT reviews the plan, blind

**Reviewer = GPT (Codex)**, read-only and in the background (Bash `run_in_background`): a separate
`codex exec` that sees the brief, the confirmed design, the plan and the code, and nothing of this
conversation. Opus wrote the plan, so the other model grades it; and since GPT reads the brief
cold, a brief that does not stand on its own comes back from it as QUESTIONS. **Before it reads the
plan, it cuts stage 1 itself** from the brief, the design and the code (the smallest stage 1 a user
would recognise, and its hours of build), so that it judges the plan's cut against its own instead
of taking the plan's framing; its verdict opens with that cut. It blocks only on ship-blockers
(`mvp.md` §5, the plan rules included), and the review has twenty minutes.

While it runs, create the progress board (2e) from your stage map and install what stage 1 needs in
`<WT>` (step 3's 3a, its fourth point), so that step 3 starts building the moment the verdict is
in. Set `PREV` to the number of the BLOCKED verdict this review follows after a fix round (2d), and
leave it empty for a first review:

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header && codev_need_worktree || exit 1
PREV=                                   # after a fix round (2d): the number of the BLOCKED verdict it fixed
[ -s "$S/plan.md" ] || { echo "codev: no plan at $S/plan.md - write it first (2b)"; exit 1; }
mkdir -p "$S/reviews" "$S/runs"
V="$S/reviews/plan-$(( $(ls "$S"/reviews/plan-*.md 2>/dev/null | wc -l) + 1 )).md"
P="$S/runs/plan-review.prompt.md"
{ printf 'THE PIPELINE HOUSE RULES (the charter below calls this root CLAUDE.md; its #2 is the reuse-first ladder):\n\n'; cat "$H/CLAUDE.md"
  printf '\n\n'; cat "$H/prompts/reviewer.md"
  printf '\n\n'; cat "$H/checklists/scoring-rubric.md"
  printf '\n\nTHE MVP LENS (binding; its section 5 decides what may be a Must Fix):\n\n'; cat "$H/checklists/mvp.md"
  printf '\n\n'; cat "$H/checklists/ponytail.md"
  printf '\n\nTHE BRIEF:\n\n'; cat "$S/brief.md"
  if [ -s "$S/design/README.md" ]; then
    printf '\n\nTHE CONFIRMED DESIGN (binding: the requester approved it; the prototype is in %s):\n\n' "$S/design/"; cat "$S/design/README.md"
  fi
  if grep -qE '^\| [0-9]+ \|[^|]*\| (building|look|test|review|PR|on dev|verified)' "$S/progress.md" 2>/dev/null; then
    printf '\n\nTHE PROGRESS BOARD (a RE-PLAN: these stages are under way or on dev):\n\n'; cat "$S/progress.md"
  fi
  if [ -n "$PREV" ]; then
    printf '\n\nYOUR PREVIOUS VERDICT ON THIS PLAN (a RE-REVIEW after a fix round):\n\n'; cat "$S/reviews/plan-$PREV.md"
  fi
  cat <<EOF

You are GPT Codex, the reviewer for the PLAN step of $SLUG, in STAGE MODE. Step: plan. Opus wrote the plan at the end of this prompt and will build it stage by stage; your verdict is the one check it gets before step 3 builds stage 1, and stage 1 reaches the shared dev environment within a day. Your working directory is the code repo, at the commit the plan was written against. The repo's own CLAUDE.md, AGENTS.md and the CLAUDE.md of each app the brief names are binding: read them. Verify with file reads, grep and git only: no installs and no package managers, which stall in this tree.
WORK IN THIS ORDER. First, before you read THE PLAN at the end of this prompt, decide from the brief, the confirmed design (when there is one) and the code the smallest stage 1 a user would recognise as the brief's MVP, and its hours of build. Then read the plan and judge its stage 1 against your cut. Open the Reason of your verdict with one line, "Own cut of stage 1: <what users get>, about <N> h of build", and say whether the plan's stage 1 matches it.
STAGE MODE: a Must Fix is ONLY a ship-blocker of a plan, as section 5 of the MVP lens lists them: stage 1 is not the smallest visible increment (your own cut is the evidence); a stage that is neither user-visible nor a foundation of about two hours that the very next stage uses; a stage over about four hours of build; a stage with no guard or no demo script; a literal ask of the brief that is in no stage and not in Not now; a migration, a backfill or a new server contract placed ahead of the stage that first needs it; an approach that builds far more than its outcome needs when a cheaper rung of the ladder delivers the same thing to the user (name the rung); and, against the code, an approach that would break what users have today, lose or corrupt data, or weaken authz, tenant isolation or RLS, or one that breaks a rule of the repo's CLAUDE.md (migrations with RLS, grants and the sandbox proof, additive only; i18next with ru and en; the rule headed AI-track code, as written; checks that match .github/workflows/ci-<app>.yml). A wrong file:line citation is a Must Fix only when the stage's approach rests on it. Every Must Fix opens with its class in brackets ([mvp], [regression], [data], [security], [broken] or [ci-rule]), names the plan's line or the code's file:line, and says what goes wrong. EVERYTHING ELSE goes under Should Consider as a follow-up, one line each, and never blocks: edge cases beyond a demo path, wording, nicer designs, more tests, and the over-engineering tags of the lens above.
When THE PROGRESS BOARD is above, this is a RE-PLAN: the stages it shows building, in review, in a PR, on dev or verified are out of scope, and you review the stages not yet started. When YOUR PREVIOUS VERDICT is above, this is a RE-REVIEW after a fix round: check that each of its Must Fix items is fixed in the plan, and raise a new Must Fix only for a ship-blocker that a fix introduced.
IF the brief and the design are ambiguous in a way that would change STAGE 1, make your final message a section titled QUESTIONS listing each ambiguity, with the answer you would assume, and nothing else; an ambiguity that only touches a later stage goes under Should Consider. Do not open or quote any .env file. You are read-only and must NEVER edit any file. Your FINAL message must be the verdict block exactly as the charter specifies (Reviewer: GPT Codex, Step: plan), or the QUESTIONS section, and nothing else. Status is APPROVED exactly when there is no Must Fix.
EOF
  printf '\n\nTHE PLAN (read it only after you have cut stage 1 yourself):\n\n'; cat "$S/plan.md"
} > "$P"
cd "$WT" && perl -e 'alarm shift; exec @ARGV or die "codex: $!\n"' 1200 codex exec --enable fast_mode -c service_tier="priority" --sandbox read-only -o "$V" - < "$P" > "$S/runs/plan-review.log" 2>&1
[ "$?" -eq 142 ] && echo "codev: the review hit its twenty-minute timebox"
if [ -s "$V" ]; then echo "verdict: $V"; grep -m1 '^Status:' "$V" || echo "codev: no Status line - a QUESTIONS section?"; else rm -f "$V"; echo "codev: no verdict - see $S/runs/plan-review.log"; fi
```

- A failed or killed run leaves no verdict. If the configured model is rejected, re-run with
  `-m <a model from ~/.codex/models_cache.json>`. If `codex exec` fails auth, **STOP** and recover
  with `rm ~/.codex/auth.json && codex login`. A log that ends on a usage-limit message means Codex
  is out of quota until its reset: tell the requester, and never put an Opus review in its place
  without their word.

Read the verdict, report its **Status** and GPT's own cut of stage 1, and put every Should Consider
item on the board's Follow-ups.

- **APPROVED**: go to 2e.
- **QUESTIONS** (no Status line): ask the requester in one round, following `mvp.md` §4, put the
  answers into the brief and, where they change it, the plan, then run 2c again. That is the brief
  failing, not the plan.
- **BLOCKED**: 2d.
- **No verdict in the twenty minutes**: run it once more. A second miss goes to the requester: a
  third run, or the plan goes on unreviewed; then write `<S>/reviews/plan-<N>.md` yourself with
  `Reviewer: the requester (GPT's review timed out twice)`, `Step: plan`, `Status: APPROVED` and
  their words under Reason, and mark the plan unreviewed on the board.

## 2d — Fix and go (only on BLOCKED)

Fix only the cited Must Fix items in `<S>/plan.md`, each checked against the code; change nothing
else, and put the Should Consider items on the board's Follow-ups, not into the plan. A Must Fix you
believe is wrong is not yours to overrule: leave the plan as it is on that point and take the item to
the requester with the evidence on both sides; 2e then stops for it, design or not.

- **No item is `[data]` or `[security]`**: fix and go (`mvp.md` §5). Write one line per Must Fix to
  `<S>/runs/plan-fixes-<N>.md` (the item, and how the plan now reads), then record the fix round with
  the block below. There is no second GPT run, and step 3 starts on that record.
- **An item is `[data]` or `[security]`**: its fix gets one re-review: run 2c again with `PREV=<N>`.
  APPROVED: go to 2e. BLOCKED again: **STOP** and take the open items to the requester, each with the
  options: fix the plan, accept it as a follow-up, or change the stage. A plan that does not converge
  in one fix round is cut wrong.

Replace `<N>` with the number of the BLOCKED verdict:

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header || exit 1
N=<N>; F="$S/runs/plan-fixes-$N.md"
grep -q '^Status: BLOCKED' "$S/reviews/plan-$N.md" 2>/dev/null || { echo "codev: $S/reviews/plan-$N.md is not a BLOCKED verdict"; exit 1; }
awk '/^## Must Fix/ { f = 1; next } /^## / { f = 0 } f' "$S/reviews/plan-$N.md" | grep -qE '\[(data|security)\]' && { echo "codev: plan-$N.md has a [data] or [security] item - its fix gets a re-review: run 2c with PREV=$N"; exit 1; }
[ -s "$F" ] || { echo "codev: list the fixes in $F first, one line per Must Fix"; exit 1; }
V="$S/reviews/plan-$(( $(ls "$S"/reviews/plan-*.md 2>/dev/null | wc -l) + 1 )).md"
{ printf '# Plan fix record\n\nReviewer: GPT Codex (plan-%s.md); its Must Fix items fixed by Opus, with no re-review (fix and go)\nStep: plan\nStatus: APPROVED\n\n## Reason\n%s: every Must Fix of plan-%s.md is fixed in plan.md as listed below; none is [data] or [security] (harness/checklists/mvp.md section 5).\n\n## Fixes\n' "$N" "$(date '+%Y-%m-%d %H:%M')" "$N"
  cat "$F"; } > "$V" && echo "recorded: $V"
```

## 2e — The stages: a report after a confirmed design, the one stop without one

Create `<S>/progress.md` from `<H>/briefs/PROGRESS.md` (on a re-plan, update it) from the stage map,
if 2c's wait did not already: one row per stage with its budget, stages already under way keeping
their status, and the review's follow-ups under Follow-ups. Then show in the chat:

- the **stage map** as a table, with stage 1 first and the hours to its arrival on dev;
- stage 1 in three lines: what users get, how to see it on dev, what it leaves to later stages;
- GPT's review, one line each: its Status, its own cut of stage 1 when it differs from the plan's,
  every Must Fix and how you fixed it, and its follow-ups;
- how the stages ship (`mvp.md` §10), in one line: every stage goes from its local CI pass to dev on
  green CI without a stop, and PM tests it there; the builder opens, Auto-fixes and merges every PR
  into dev itself and builds the next stage while CI runs; with nothing to draw, you first test
  stage 1 by hand on a local URL;
- a link to `<S>/plan.md` and to the verdict (see **Links**); the quick lane has none.

**After a confirmed design** (`Design: html` or `handoff`) this is a report, not a stop: the
requester's ok on the design was the flow's one stop before code (`mvp.md` §4), and the brief says
`Ship: none`. Record the approval of a quick-lane plan (the block below) and start step 3 at once.
The one exception is a Must Fix you left unfixed because you believe it is wrong (2d): it waits for
the requester's call. The requester can still stop the run, or re-order or cut stages, at any time.

**With nothing to draw** (`Design: none`, or a brief written before the design step) this is the
flow's **one stop before code** (`mvp.md` §4): **STOP**, and show the brief in short first, since
step 1 went on without stopping (In short, the MVP, Not now, the lane, and the assumptions taken as
defaults, with a link to `<S>/brief.md`). Ask in one round (AskUserQuestion), one question: **the
brief and the stages**: confirm, correct the brief, or re-order, cut or merge stages; the smallest
change is the default. Record `Ship: stage1` in the brief's header, or `Ship: every` when the
requester says they want to test every stage by hand locally before it ships. Shipping is not a
question of its own: the requester decided it for every ticket on 2026-10-06. Corrections go into the
brief and the plan; one that changes stage 1 is planned again (2b, or 2q in the quick lane) and
reviewed again (2c) before step 3 starts.

In the quick lane, record the approval that step 3 checks before it builds:

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header || exit 1
mkdir -p "$S/reviews"; V="$S/reviews/plan-$(( $(ls "$S"/reviews/plan-*.md 2>/dev/null | wc -l) + 1 )).md"
printf '# Plan approval\n\nReviewer: the requester (quick lane: Opus wrote this plan, so no model graded it)\nStep: plan\nStatus: APPROVED\n\n## Reason\n%s: covered by the requester'"'"'s ok on the design (Ship: none, nothing waits after it), or by their yes on the brief and the one-stage plan at the stop.\n' "$(date '+%Y-%m-%d %H:%M')" > "$V" && echo "recorded: $V"
```

Then **start step 3 at once** by invoking `/step3 $1` yourself with the Skill tool, the slug as its
only argument. Do not wait for the requester to type it.

**When the brief or the map changes later**, nothing that shipped is redone and nothing restarts:
put the change into the brief (the stages, Questions and answers), then run `/step2 $1` again. You
re-plan only the stages not yet started (2b), GPT reviews the re-plan (2c), and the report (or,
with nothing to draw, the stop) shows the new map. A one-line change to a single not-yet-started
stage (a budget, an order) can be edited into the map and the board directly, without a run.

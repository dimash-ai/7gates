---
description: "Step 3 (build): Opus implements the stages of the plan, and the confirmed design as drawn, one by one with no layers inside and no checks while building; the local CI pass runs once right before the push; every stage PR is opened, Auto-fixed and merged into dev on green CI without asking, the next stage built while CI runs, and PM tests on dev; you test stage 1 by hand locally only for a task with nothing to draw; GPT reviews only data/auth stages on their open PR while CI runs, and a release to main that carries one"
argument-hint: <slug> [repo-path]
---

# Step 3 — build and ship a stage  ·  Opus implements · checks before the push · dev on green CI

The third step of the **co-dev flow** (`harness/README-codev.md`). It starts by itself once step 2
has planned (after the requester's ok on the design, or their yes at step 2's stop when there was
nothing to draw), and it works **stage by stage**. Step 3 is **pure implementation of the plan**,
and of the confirmed design where a stage shows it: it takes the next stage, implements it as the
plan details it, ships it as its own PR into `dev`, and the stage is done when it is **on the dev
environment**: merged, deployed, the dev host serving the new build, the progress board updated
(`<H>/checklists/mvp.md` §1). **Check right before the push** (`mvp.md` §10): nothing is checked
while a stage is built; under `Ship: stage1` (a task with nothing to draw) the requester first tests
stage 1 end to end on a local URL; the local CI pass runs once, right before the push; every stage
goes from that pass straight to its PR, merges on green CI and is tested on dev by PM. **Nothing between the stages waits for the
requester** (`mvp.md` §10, their decision of 2026-10-09): you push, open each PR, turn on its
Auto-fix and merge it into dev on green CI without asking, and you build the next stage while CI
runs (3f). Run `/step3 $1` by hand only to resume, or to release to main (3g).

GPT reviews where a second model changes the outcome, and nowhere else: a stage whose risk is
**data** or **auth** gets one GPT review on its open PR, while CI runs, before it merges into dev
(3d), and a **release to main** that carries such a stage, or a cherry-pick that had to be resolved,
gets one GPT release pass the same way (3g). A low-risk stage, a release of low-risk stages and the
quick lane's one stage go on the local CI pass and CI (and, for stage 1, the requester's test by
hand). CI runs the checks, so a review does not repeat them. Every review blocks only on ship-blockers, and a BLOCK is
fixed and goes on: one re-review only for a security or data finding (`mvp.md` §5).

`$1` is the slug; `$2` is the code repo, optional. Every bash block sources
`harness/bin/codev-env.sh`, which prints `codev: slug=… results=<S> worktree=<WT> branch=… base=…`;
in the prose, `<S>`, `<WT>` and `<H>` (the `harness/` directory) mean those literal paths, `<BR>` the
brief's Branch and `<BASE>` its Base. Stage N is built on the branch `<BR>-s<N>`.

**Links.** When you point the requester at a file of the flow (the progress board, the plan, a
verdict, a drafted PR body), write a markdown link whose target is the file's path relative to the
session's working directory, usually `[progress.md](specs/$1/progress.md)`; never a bare path in
backticks.

**The rules of a run** (`mvp.md` §2 and §6):

- **No layers inside step 3.** Implement the stage yourself, in this session. Do not orchestrate it:
  no design phase, no parallel builder agents or waves, no separate verify agent, no internal
  pre-review or skeptics, no multi-agent fix rounds, even when ultracode or a high effort is on. Step
  2 produced the design; a stage the plan does not detail goes back to `/step2`, not into a design
  pass here.
- **Timebox.** The stage's budget is on the map. At one and a half times the budget, stop and tell
  the requester, then re-cut: ship what works behind the stage's guard and move the rest to the
  next stage.
- **One stage at a time, without waiting** (`mvp.md` §2). The next stage is built while the stage
  before it waits for CI, on that stage's branch (3a); its PR opens only after that stage merged,
  rebased onto the fresh `origin/<BASE>` (3c).
- **Never ask to move a stage on** (`mvp.md` §10). Pushing, opening the PR into dev, turning on its
  Auto-fix and merging it into dev on green CI are the requester's standing ask of 2026-10-09: «не
  жди меня, открывай PR и делай merge into dev if CI is green». Do them and report that you did;
  never ask about them, and never end a turn to wait for such an answer. The release to main (3g) is
  still theirs.
- **Checks once, right before the push** (`mvp.md` §10). No lint, format, type, i18n or test
  command while you build or while the requester tests; the local CI pass runs once, before the push
  (3b), and CI runs every suite on the PR.
- **Quick lane** (the brief's `Lane: quick`, `mvp.md` §9): one low-risk stage and no GPT review at
  any point. If it turns out to need a migration, an auth change, a second stage or more than three
  hours, it leaves the lane: stop, tell the requester, and re-plan with `/step2 $1`.
- **Show the board.** Print the progress board at the start and at the end of every run, and
  whenever the requester asks how things stand.
- **Every Codex run goes in the background** (Bash `run_in_background`).

## Before you start — where the stages stand

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header && codev_need_worktree && codev_need_approved_plan || exit 1
cat "$S/progress.md" 2>/dev/null || echo "codev: no progress board at $S/progress.md - create it from $H/briefs/PROGRESS.md and the plan's stage map"
echo "worktree on: $(git -C "$WT" branch --show-current)"; git -C "$WT" status --short
git -C "$WT" log --oneline "origin/$BASE..HEAD"
```

No approved plan, no build. **The stage of this run** is the first one on the board that is neither
`on dev` nor `verified`: finish a stage that is already under way (building, test, PR, review)
before starting a new one, except the next stage, built on a stage whose PR waits for CI (3a). If
`<S>` is gone (the session that held it ended), the last stage PR's
body carries the stage map and the board: rebuild `progress.md` from it, and take the plan's details
from `/step2 $1`'s re-plan.

---

## 3a — Start the stage

1. **The stage before it is in its PR.** For stage N ≥ 2, the stage before it has merged, or its PR
   is open and waiting for CI. Not yet in a PR: finish it first (3b, 3c). Waiting for CI: build this
   stage on its branch (the block below does it) and merge it the moment a read shows green (3d). A
   data or auth stage whose GPT review is still running keeps `<WT>` on its branch: prepare this
   stage without touching `<WT>` until the verdict is in and its fixes are pushed.
2. **The plan details it.** The plan has a `## Stage N` section. If it does not, or dev showed that
   the stage as planned is wrong, STOP: re-plan with `/step2 $1`, which re-plans only the stages not
   yet started.
3. **The branch.** Stage 1 is already on `<BR>-s1` from step 2. For stage N ≥ 2, cut `<BR>-s<N>` from
   the fresh `origin/<BASE>` when the stage before it has merged, or from that stage's branch while
   its PR waits for CI (replace `<N>`); 3c rebases it onto `origin/<BASE>` before its PR opens.
   Re-cut stage 1 the same way when the base moved since step 2 and the branch has no commits yet.

   ```bash
   H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
   . "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
   codev_need_header && codev_need_worktree || exit 1
   N=<N>; B="$BR-s$N"; P="$BR-s$((N-1))"
   [ -z "$(git -C "$WT" status --porcelain)" ] || { echo "codev: $WT has uncommitted changes - commit or move them first"; exit 1; }
   git -C "$M" fetch origin "$BASE" --quiet || { echo "codev: cannot fetch origin/$BASE"; exit 1; }
   FROM="origin/$BASE"
   if [ "$N" -gt 1 ] && git -C "$M" show-ref --verify --quiet "refs/heads/$P" && ! git -C "$M" merge-base --is-ancestor "$P" "origin/$BASE"; then
     FROM="$P"                                                           # the stage before waits for CI: build on it, stacked
   fi
   if [ "$(git -C "$WT" branch --show-current)" = "$B" ] && [ -z "$(git -C "$WT" log --oneline "$FROM..HEAD")" ]; then
     git -C "$WT" reset --hard "$FROM" --quiet                           # no commits of its own yet: re-cut on the fresh base
   elif git -C "$M" show-ref --verify --quiet "refs/heads/$B"; then
     git -C "$WT" switch "$B" || exit 1
   else
     git -C "$WT" switch --no-track -c "$B" "$FROM" || exit 1
   fi
   echo "stage $N on $B at $(git -C "$WT" rev-parse --short HEAD), cut from $FROM"
   ```

4. **First stage only:** install what the app needs in `<WT>` (`uv sync` in its server dir,
   `pnpm install` at the root): the requester's test of stage 1 and every local CI pass run from
   here. The checks do not need a `.env`: CI runs them without one.
5. **The board:** the stage is `building`, with the time it started, and `stacked on #<PR>` while
   the stage before it waits for CI.

## 3b — Implement the stage

**Doer = Opus (you).** The plan's stage detail governs; every departure from it is recorded.

- Read the stage's row and its `## Stage N` section in `<S>/plan.md`, and
  `<H>/checklists/ponytail.md`. Implement the minimum that delivers the stage's outcome, inside its
  guard. Climb the ladder before adding any surface; touch only the files the stage needs.
- **The confirmed design is the visual spec** (`mvp.md` §11). A stage that shows what the design
  draws builds those screens and states as drawn in `<S>/design/`: layout, sizes, colors and the
  words. A departure goes into the build log's Deviations with its reason.
- **Tests prove the stage** (`mvp.md` §6): its demo path; a regression guard for every behaviour
  users have today that it touches; the repo's mandatory proofs. Write them with the stage; the
  local CI pass runs the affected ones before the push, and CI runs them all. A schema change ships
  its Alembic revision with RLS and grants and is proven in the sandbox, as part of the local CI pass
  (superapp's `CLAUDE.md`, the migration row for the app: `scripts/migration-sandbox.sh <server-dir>
  <schema> --keep`, then assert the policies exist over the printed DSN and tear it down). Never a
  shared database. Edge cases beyond the demo path are follow-ups: list them, do not build them.
- A deliberate shortcut with a known ceiling gets a `ponytail:` marker naming the ceiling and the
  trigger to upgrade.
- **No checks while building** (`mvp.md` §10). Do not run lint, format, types, i18n checks or tests
  while you implement the stage or while the requester tests it. Generate what the change itself
  needs (API types after a server schema change, the ru and en locale keys of new strings): that is
  implementing the stage, not checking it.
- **Stage 1 under `Ship: stage1`: the requester tests it by hand, locally.** As soon as stage 1 is
  committed, bring the app up from `<WT>`, on the app's usual local port and without a sign-in where
  the app has a local demo mode, and give the requester the URL with the steps of the demo script.
  Do not walk it yourself first, and do not wait for screenshots. They test it end to end; their ok
  starts the local CI pass, and what they want changed goes into the stage without checks, then they
  test again. Timebox the bring-up to about ten minutes: if the local environment fights you, say so
  and let the requester choose between waiting and testing on dev. Stop the local servers once they
  are done. Under `Ship: every` every stage gets this test, and a later stage otherwise gets none.
  Under `Ship: none` (after a confirmed design) no stage waits for one: stage 1 goes from its build
  straight to the local CI pass, like every later stage.
- **The local CI pass, once, right before the push.** After the requester's ok on their hand test,
  or as soon as the stage is built when it has none: the static checks of the app's CI job for what
  the stage touched (lint, format, types; i18n and generated API types when they apply), the affected tests
  (`scripts/test-affected.sh` from the repo root runs the tests that import, are named after or name
  what changed, the real-DB ones in a throwaway sandbox; `--list` shows what it picks and why), and
  the migration sandbox proof when a schema change ships. Not the full suites: CI runs them on the
  PR into dev and again after the merge. A red check is fixed and the pass re-run; a fix that
  changes what the requester tested goes back to them.
- **The build log**, `<S>/runs/build-s<N>.txt`: the local CI pass's exact commands with their
  **real** pass/fail counts, the real-DB and sandbox output when they ran, a `Deviations` list with
  the reason for each departure from the plan, the follow-ups found, and the hours spent. Never write
  a count you did not observe.
- **Commit** the stage on its branch. Commit messages carry **no AI attribution** (superapp's
  `CLAUDE.md`) and no Linear id (`mvp.md` §8).

  ```bash
  H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
  . "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
  codev_need_header && codev_need_worktree || exit 1
  git -C "$WT" add -A && git -C "$WT" commit -m "<type>(<scope>): <subject>"
  ```

Then open the stage's PR (3c), right after the local CI pass. A **data** or **auth** stage gets its
GPT review on that PR while CI runs (3d); a **low**-risk stage merges on green CI.

## 3c — Open the stage's PR

Draft the PR body in `<S>/pr-s<N>.md`, for the people who read the PR:

- The **first line is exactly `Part of <Linear id>`** (`mvp.md` §8): it links the issue without
  closing it. Nowhere a closing word before the id (`fixes`, `closes`, `resolves`, `completes`,
  `implements` and their forms), and no id in the branch name or the title.
- `## What`: what users get on dev in this stage, in their words.
- `## How to see it on dev`: the demo script, for PM, who walks it on dev.
- `## Changes`: per area, one line each.
- `## Verification`: the local CI pass's commands and counts from the build log, and the
  requester's test by hand when there was one; CI on this PR runs every suite. For a data or auth stage, add the
  GPT verdict's Status and Release Risk and the Must Fix items fixed after it, once it is in (3d).
- `## Follow-ups`: the known follow-ups and the `ponytail:` markers the stage adds.
- `## Stages`: the plan's stage map and the progress board, so GitHub keeps the record.

No AI attribution, no secrets, tokens or personal data.

**When it opens** (`mvp.md` §10): right after the local CI pass, without asking whether to push or
to open it. For **stage 1 under `Ship: stage1`** (and every stage under `Ship: every` or an older
brief's `Ship: ask`) that pass comes after the requester's ok on their local test; for **every other
stage** (every stage under `Ship: none` or an older `Ship: auto`) it comes right after the build. **A stage built on the stage
before it** (3a) opens only once that stage has merged: read its PR and merge it if it is green
(3d). On the first push the block refuses while that stage has not merged, and rebases this one
onto the fresh `origin/<BASE>`, so the PR carries this stage's commits only (stages merge with a
merge commit, so the commits of the stage before it are in `origin/<BASE>` already).
The block checks the Linear wording, then pushes and opens the PR **with the base named
explicitly** (`gh pr create` otherwise targets the default branch). A data or auth stage opens as a
**draft**, so nobody merges it before its review is in; CI runs on a draft all the same:

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header && codev_need_worktree || exit 1
N=<N>; B="$BR-s$N"; TITLE="<type>(<scope>): <subject>"; F="$S/pr-s$N.md"
DRAFT=<yes for a data or auth stage, no for a low-risk one>
[ "$(git -C "$WT" branch --show-current)" = "$B" ] || { echo "codev: $WT is not on $B"; exit 1; }
ID=$(sed -n 's/^Linear:[[:space:]]*\([A-Z][A-Z]*-[0-9][0-9]*\).*/\1/p' "$S/brief.md" | head -1)
if [ -n "$ID" ]; then   # mvp.md section 8: link the issue without closing it
  [ "$(head -1 "$F")" = "Part of $ID" ] || { echo "codev: the first line of $F must be exactly 'Part of $ID'"; exit 1; }
  printf '%s\n%s\n' "$B" "$TITLE" | grep -qi "$ID" && { echo "codev: $ID in the branch or the title would close the issue on merge - take it out"; exit 1; }
  { printf '%s\n' "$TITLE"; cat "$F"; } | grep -qiE "(^|[^[:alnum:]])(close[sd]?|closing|fix(e[sd]|ing)?|resolve[sd]?|resolving|complete[sd]?|completing|implement(s|ed|ing)?|linear issue)[[:space:]]+(https://linear\.app/[^[:space:]]*/)?$ID" && { echo "codev: a closing word before $ID would close the issue - reword it"; exit 1; }
fi
if ! git -C "$WT" rev-parse --verify --quiet "refs/remotes/origin/$B" >/dev/null; then   # the first push: the PR carries this stage only
  git -C "$M" fetch origin "$BASE" --quiet || { echo "codev: cannot fetch origin/$BASE"; exit 1; }
  P="$BR-s$((N-1))"
  if [ "$N" -gt 1 ] && git -C "$M" show-ref --verify --quiet "refs/heads/$P" && git -C "$WT" merge-base --is-ancestor "$P" HEAD && ! git -C "$WT" merge-base --is-ancestor "$P" "origin/$BASE"; then
    echo "codev: $B is built on stage $((N-1)), which has not merged yet - merge it on green first (3d), then re-run this block"; exit 1
  fi
  git -C "$WT" rebase --quiet "origin/$BASE" || { echo "codev: the rebase onto origin/$BASE stopped on a conflict - resolve it, git rebase --continue, re-run the local CI pass for what it touched, then re-run this block"; exit 1; }
fi
git -C "$WT" push -u origin "$B" || exit 1
cd "$WT" && if [ "$DRAFT" = yes ]; then gh pr create --draft --base "$BASE" --head "$B" --title "$TITLE" --body-file "$F"; else gh pr create --base "$BASE" --head "$B" --title "$TITLE" --body-file "$F"; fi
```

After it opens, check that the Linear issue lists the PR among its links (Linear MCP `get_issue`);
if it does not, the body's first line was not read as a reference: fix the body, and Linear
re-evaluates it on save.

## 3d — Review and merge

CI runs every suite on the PR, so it is where a breakage outside the local selection shows up; a
red CI is fixed on the stage branch like a Must Fix. As soon as the PR is open, bind it with the
desktop app's PR tools (`get_status`, then `bind_pr` if it does not report this PR) and **turn its
Auto-fix on yourself** (`set_monitor` with `auto_fix: true` and the PR's url): the requester asked
for it on every stage PR (`mvp.md` §10), so it is not a question, and the app then wakes this
session when CI goes red, the PR conflicts or a review comment arrives. Never poll the checks. The
app does not wake the session when CI turns green, so **CI time is build time**: go straight on to
the next stage, built on this one's branch (3a), and read this PR with the app's PR status tool at
every natural point: the next stage built, its local CI pass done, a review back. The first read
that shows green (and, for a data or auth stage, its review in): merge it (below), do 3e, and go on.
**Never end a turn on a running CI while a next stage is left to build.** At the last stage, spend
the CI time on the wrap-up (the build log, the board, the bet in PostHog, 3f), then read; only if CI
still runs after that, end the turn with the board and one line, "stage N: CI running, I merge it on
green; any message resumes the run". When Auto-fix wakes you on a red stage you have already built
on, stash the next stage's work, switch `<WT>` back to the red stage's branch, fix and push, then
switch back and pop the stash.

**A data or auth stage** gets one GPT review while CI runs: start it as soon as the PR is open.
**Reviewer = GPT (Codex)**, on the committed branch, looking for what CI cannot see. It does not
re-run the CI jobs or the suites; it may run one targeted command to confirm or reproduce a finding,
which is the only reason its sandbox can write, and it must not change anything. The review has
twenty minutes. The same block runs the release pass in 3g. Set `<N>` to the stage number and run
it in the background:

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header && codev_need_worktree || exit 1
MODE=stage; N=<N>                      # 3g sets MODE=release and N to the promotion's label (main, main-2, ...)
[ -z "$(git -C "$WT" status --porcelain)" ] || { echo "codev: commit first - the review reads committed work"; exit 1; }
if [ "$MODE" = release ]; then
  TAG="release-$N"; STEP=ship
  TASK="Review the RELEASE TO MAIN: 'git --no-pager diff origin/main...HEAD' is every stage being promoted to production, cherry-picked onto origin/main. Beyond each stage on its own, look for what only the whole shows: stages that conflict, a migration chain that does not apply in order on main, a regression in something users have in production today, a guard switched off before its stage is complete, and a PR body (below, when present) that is not accurate. List every ponytail: marker the release adds (git --no-pager diff origin/main...HEAD | grep -E '^\+.*(#|//|\*|--) ?ponytail:') under Should Consider as file:line, ceiling, trigger."
else
  TAG="stage-$N-$(( $(ls "$S"/reviews/stage-$N-*.md 2>/dev/null | wc -l) + 1 ))"; STEP=build
  TASK="Review STAGE $N as committed: 'git --no-pager diff origin/$BASE...HEAD' (the stage's branch was cut from origin/$BASE after the stage before it merged, so this diff is the stage and nothing else), against the stage's row on the map and its section in the plan. It merges into the shared dev environment as soon as you approve it, and its risk class is data or auth."
fi
P="$S/runs/$TAG.prompt.md"
{ printf 'THE PIPELINE HOUSE RULES (the charter below calls this root CLAUDE.md):\n\n'; cat "$H/CLAUDE.md"
  printf '\n\n'; cat "$H/prompts/reviewer.md"
  printf '\n\n'; cat "$H/checklists/scoring-rubric.md"
  printf '\n\nTHE MVP LENS (binding; its section 5 decides what may be a Must Fix):\n\n'; cat "$H/checklists/mvp.md"
  printf '\n\n'; cat "$H/checklists/ponytail.md"
  printf '\n\nTHE BRIEF:\n\n'; cat "$S/brief.md"
  printf '\n\nTHE PLAN:\n\n'; cat "$S/plan.md"
  if [ "$MODE" = release ]; then
    printf '\n\nTHE PROGRESS BOARD:\n\n'; cat "$S/progress.md"
    printf '\n\nTHE DRAFTED PR BODY:\n\n'; cat "$S/pr-$N.md" 2>/dev/null || echo "(none yet)"
  else
    printf '\n\nTHE BUILD LOG OF THIS STAGE:\n\n'; cat "$S/runs/build-s$N.txt" 2>/dev/null || echo "(none)"
  fi
  cat <<EOF

You are GPT Codex, the reviewer for $SLUG, in STAGE MODE. Step: $STEP. Your working directory is the worktree. $TASK
STAGE MODE: a Must Fix is ONLY a ship-blocker, as section 5 of the MVP lens lists them: a regression in something users have today; data loss or corruption, including a migration that is irreversible or not proven in the sandbox; security (authz, tenant isolation and RLS, secrets, injection); a stage that does not do what its row says (its demo script fails on the happy path, or nothing, test or recorded browser check, shows it passing); CI or a repo rule (read CLAUDE.md and the CLAUDE.md of each app involved: i18next with ru and en, the rule headed AI-track code applied exactly as written, migration rules with RLS, grants and the sandbox proof, no AI attribution); unfinished user-facing work outside its stage's guard. Every Must Fix opens with its class in brackets ([regression], [data], [security], [broken], [ci-rule] or [unsafe-on-dev]) and names its file:line and the concrete failure: what input or sequence leads to what wrong result. EVERYTHING ELSE goes under Should Consider as a follow-up, one line each, and never blocks: edge cases of the new feature beyond a demo path, races that need two people on the new screen at once, polish, more tests, naming, and the over-engineering tags of the lens above. A departure from the plan that the build log does not record is a Must Fix only when it changes what users get or breaks a guard.
CI RUNS THE CHECKS, NOT YOU. Every job of .github/workflows/ci-<app>.yml runs on this change's pull request while you review: lint, format, types, i18n, migration drift, generated API types, and every test suite, the real-DB ones included. Do not re-run them and do not report pass or fail counts: the build log's counts are the builder's, and CI checks them. Spend your time on what CI cannot see. You may run a single targeted command (one test file, a short script, a git or grep query) to confirm or reproduce a finding; a Must Fix you reproduced says how. A check this change needs that you believe CI does not cover goes under Should Consider. You may run commands, but you must NOT create, edit or delete any file. Do not open, print or quote any .env file or environment variable: the worktree may hold real credentials. Your FINAL message must be the verdict block exactly as the charter specifies (Reviewer: GPT Codex, Step: $STEP) and nothing else. Status is APPROVED exactly when there is no Must Fix.
EOF
} > "$P"
cd "$WT" && perl -e 'alarm shift; exec @ARGV or die "codex: $!\n"' 1200 codex exec --enable fast_mode -c service_tier="priority" --sandbox workspace-write -o "$S/reviews/$TAG.md" - < "$P" > "$S/runs/$TAG.log" 2>&1
[ "$?" -eq 142 ] && echo "codev: the review hit its twenty-minute timebox"
if [ -s "$S/reviews/$TAG.md" ]; then echo "verdict: $S/reviews/$TAG.md"; else rm -f "$S/reviews/$TAG.md"; echo "codev: no verdict - see $S/runs/$TAG.log"; fi
git -C "$WT" status --porcelain   # must be empty
```

**If that last `status` is not empty**, look at what changed before anything else: a generated file a
check rewrote is drift GPT should have reported as a Must Fix; anything else is the reviewer
touching the tree, and a verdict made while editing the code is not a review. Clear it without
losing it (`git stash push --include-untracked -m "codev $SLUG $TAG: left by the review"`, then note
the stash's sha from `git stash list --format='%H %gs'`), and re-run the review.

Read the verdict, report its **Status**, and put every Should Consider item on the board's
Follow-ups; add its Status and Release Risk to the PR body's Verification
(`gh pr edit <PR number> --body-file <S>/pr-s<N>.md`).

- **APPROVED**: merge below.
- **BLOCKED — fix and go** (`mvp.md` §5): fix only the cited Must Fix items on the stage's branch,
  each shown by a test or a check where one can show it; record them in the build log and the PR
  body, and push. Green CI on the fix is the proof: there is no second GPT run, unless an item is
  `[security]` or `[data]`, whose fix gets one re-review (the same block). CI still red after the
  fix round, or a re-review that blocks again: **STOP** and take the open items to the requester,
  each with the options: fix it now, hide the part behind the guard, or cut it from the stage. A
  finding that keeps coming back says the stage is cut wrong: re-plan it with `/step2 $1`.
- **No verdict in the twenty minutes**: tell the requester and let them choose: run the review once
  more, or merge on CI alone with the stage marked unreviewed on the board.

**The merge.** With CI green, and for a data or auth stage its review APPROVED or its Must Fix items
fixed as above, mark a draft ready and merge it into `<BASE>` **on your own**, without asking:
merging into dev on green CI is the requester's standing ask (`mvp.md` §10), and their ok on the
design, or their test of stage 1, came before the PR.

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
cd "$R" && { [ "$(gh pr view <PR number> --json isDraft --jq .isDraft)" != true ] || gh pr ready <PR number>; } && gh pr merge <PR number> --merge
```

The board: `PR` (and `review` while GPT runs), then `on dev` once the deploy below is done.

## 3e — On dev

1. **The deploy.** Check that every service the stage touches deployed from the merge: the app's
   Railway services (all of an app's services that share its `railway.toml`, and its pre-deploy
   migration when the stage has one) and the client's Cloudflare Pages build. Then make sure the dev
   host serves the new build: something this stage added appears in the served page or bundle. A
   page that loads is not proof; an old bundle looks exactly like a working one. A deploy that fails,
   or a build that never arrives, is a ship-blocker: fix it on `<BR>-s<N>-fix` cut from
   `origin/<BASE>` (implement, PR, merge), or revert the merge if the people using dev are hurt
   meanwhile.
2. **The demo is PM's** (`mvp.md` §10). Do not walk the demo script on dev, and write nothing to the
   shared dev data: PM walks it from the PR's `How to see it on dev`, and so can the requester. What
   they find comes back as a fix on `<BR>-s<N>-fix`, a later stage or a follow-up.
3. **The board:** `on dev`, with the time, and a line in the Log; print it. A stage becomes
   `verified` when PM or the requester says its demo passed on dev: record who and when.
4. **Report** to the requester: stage N is on dev, the link, the three to five steps PM follows, the
   follow-ups waiting for their decision, and the next stage with its budget, already under way
   (3f). The report says what was done and asks nothing; the run does not wait for an answer.

## 3f — Next

- **The next stage starts by itself.** With a next stage on the board, report stage N (3e) and go
  straight on to stage N+1 (3a), usually already built on stage N's branch while N's CI ran; do not
  wait for the requester to type `/step3` or to answer the report. What dev showed
  may change the map: the requester may stop the run, re-order, cut, merge or add stages at any
  time, and follow-ups may become stages. A change to stages not yet started goes through
  `/step2 $1` (a re-plan); nothing that shipped is redone. When every stage is on dev, stop: PM's
  findings come back as fixes or follow-ups, and the release to main is the requester's call (3g).
- **The hypothesis.** When the stage that makes the brief's Hypothesis signal measurable is on dev
  (stage 1, when the signal already exists), register the bet (below). Skip it when the brief says
  Hypothesis: none.
- **The Linear issue** is the requester's to close. By the team's convention it closes with the
  release to main that finishes the feature (3g), not with a stage.

## 3g — Release to main

When the requester says (after PM signs off on dev; superapp's `CLAUDE.md`, "Promoting dev → main"):

1. **The branch.** Cut `<BR>-main` from `origin/main` (a later promotion of more stages uses
   `<BR>-main-2`, and so on) and cherry-pick each promoted stage's own commits, in stage order. A
   conflict means someone else's unpromoted work overlaps these files: stop and coordinate.

   ```bash
   H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
   . "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
   codev_need_header && codev_need_worktree || exit 1
   L=main; PRS="<the promoted stages' PR numbers, in stage order>"
   [ -z "$(git -C "$WT" status --porcelain)" ] || { echo "codev: $WT has uncommitted changes"; exit 1; }
   git -C "$M" fetch origin main --quiet || exit 1
   git -C "$WT" switch --no-track -c "$BR-$L" origin/main || exit 1
   cd "$R" && for pr in $(echo "$PRS"); do   # $(...) splits in zsh and bash alike
     for c in $(gh pr view "$pr" --json commits --jq '.commits[].oid'); do git -C "$WT" cherry-pick "$c" || { echo "codev: conflict at $c (PR $pr) - stop and coordinate"; exit 1; }; done
   done
   git -C "$WT" log --oneline origin/main..HEAD
   ```

2. **Does it need a release pass?** Only when the release carries a stage whose risk is data or
   auth, or a cherry-pick that had to be resolved. Otherwise CI on the PR into main and the
   requester's merge are the gate.
3. **The PR body**, `<S>/pr-main.md` (`pr-main-2.md` for a later promotion): what users get in
   production, the stages it carries with their dev PRs, the verification, whether a release pass
   runs and why, and the follow-ups, with the `ponytail:` markers the release adds
   (`git --no-pager diff origin/main...HEAD | grep -E '^\+.*(#|//|\*|--) ?ponytail:'`). Its first
   line is `Part of <id>`, or `Closes <id>` when the requester calls this the release that finishes
   the feature.
4. **The PR into main**, with the base named explicitly, and as a draft when a release pass runs:
   `git -C "$WT" push -u origin "$BR-main"`, then `gh pr create --base main --head "$BR-main"
   --title "<type>(<scope>): <subject>" --body-file "$S/pr-main.md"`, adding `--draft` when the
   pass runs.
5. **The release pass**, when it runs: the 3d review block with `MODE=release` and `N=main` (or
   `main-2`), in the background while the PR's CI runs; one GPT review of everything going to
   production, ship-blockers only. BLOCKED is handled as in 3d (fix and go), on this branch; then
   `gh pr ready`. The requester merges the PR. `/learn` takes this merge as the release date and
   starts the hypothesis window.

### Register the bet

Record the brief's Hypothesis in PostHog through its MCP, in the project that holds the app's events,
so that `/learn` can check it after release:

1. Save the signal as an insight named `<slug> · <signal>` and add it to the dashboard
   «Hypotheses — bets and demand» (`dashboards-get-all` with `search: "Hypotheses"`): the signal over
   time, prod only, filtered to the app the way that board's demand tables are.
2. Create the notebook `Hypothesis · <slug> · <title>` from `<H>/briefs/HYPOTHESIS.md`: Status
   `building`, the Branch, the stage PR that made the signal measurable and its date, the Hypothesis
   and In short verbatim from the brief, and the insight embedded.

Give the requester both links. Nothing else changes in PostHog until `/learn`.

## Cleanup

After the release, remove the worktree (the branches stay). Removing it deletes its gitignored files,
so the block refuses while a `.env` is still inside; copy out of `<S>` whatever must outlive the work
first. A session's own worktree is left alone: the app removes it with the session.

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
[ -d "$WT" ] || { echo "codev: no worktree at $WT"; exit 0; }
[ "$WT" != "$R" ] || { echo "codev: $WT is this session's own worktree - the app removes it with the session"; exit 0; }
E=$(git -C "$WT" status --ignored --porcelain | grep -E '^!! (.*/)?\.env')
[ -z "$E" ] || { echo "codev: $WT still holds these - keep what you need, delete them, re-run:"; echo "$E"; exit 1; }
git -C "$M" worktree remove ".worktrees/$SLUG" && echo "worktree removed; branches kept"
```

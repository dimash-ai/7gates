---
description: "Step 3 (build): Opus builds slice by slice, GPT reviews each slice, then runs the release pass"
argument-hint: <slug> [repo-path]
---

# Step 3 — build  ·  Opus does · GPT reviews

The third and last step of the **3-step co-dev flow** (`harness/README-codev.md`). Opus builds the
approved plan one slice at a time, GPT reviews every slice, and when the last slice is committed GPT
runs the release pass itself before anything ships.

`$1` is the slug; `$2` is the code repo, optional. Every bash block sources
`harness/bin/codev-env.sh`, which prints `codev: slug=… results=<S> worktree=<WT> branch=… base=…`;
in the prose, `<S>`, `<WT>` and `<H>` (the `harness/` directory) mean those literal paths. The
branch and base come from the brief's header, and the worktree is the one step 2 created: the plan
was written against this tree.

**Links.** When you point the requester at a file of the flow (the brief, the plan, a verdict, the
drafted PR body), write a markdown link whose target is the file's path relative to the session's
working directory, usually `[brief.md](specs/$1/brief.md)`; never a bare path in backticks. In the
Claude desktop app a click on that link opens the file. The card an edit leaves in the chat opens
the diff pane instead, and `specs/` is gitignored, so the file never shows there.

Run this command **once per slice**. Each run does **3a**; the run whose verdict completes the last
slice of the plan continues into **3b**. Every Codex run goes **in the background** (Bash
`run_in_background`): a review that runs the suites outlasts the Bash tool's timeout.

## Before you start — where the build stands

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header && codev_need_worktree && codev_need_approved_plan || exit 1
git -C "$WT" status --short
git -C "$WT" log --oneline "origin/$BASE..HEAD"
```

No approved plan, no build. The log shows the slices already committed; the status shows
uncommitted work.

**First slice only:** the worktree has no dependencies yet. Install what the app needs in `<WT>`
(`uv sync` in its server dir, `pnpm install` at the root). The checks do not need a `.env`: CI runs
them without one. Copy a `.env` in only to run the app itself, for a check in the browser, and
remember that GPT's release pass will run in a tree that holds it.

---

## 3a — build one slice, GPT reviews it

**Doer = Opus (you).** Best in the session that ran steps 1 and 2: it holds the requester's
context. The plan still governs. In a session with a worktree of its own it is the only choice:
`<WT>` and `<S>` live in that worktree, and no other session may write there. Never let the app
sync that branch with its base: the app's base for the session is `main`, and merging it would drag
main-only history into a PR for `<BASE>`.

- Read `<S>/brief.md`, `<S>/plan.md` and `<H>/checklists/ponytail.md` (the ladder, and what is *not*
  over-engineering in superapp).
- Implement the NEXT slice in the plan's order, or a **release fix** that 3b asked for: the
  minimum code that satisfies it. Climb the ladder before adding any surface; touch only the files
  in `<WT>` this slice needs.
- Write this slice's tests as the plan's test strategy says, in the repo's stack. Cover the failure
  mode the plan names for this slice, not just the happy path. If the slice changes DB-backed
  behaviour, run the app's real-DB suite against the migration sandbox: `scripts/migration-sandbox.sh`
  with `--keep` prints a DSN; set it in the suite's test-DB variable (the pytest step of
  `.github/workflows/ci-<app>.yml` names it, e.g. `FOCAL_TEST_DATABASE_URL`); tear the sandbox down
  after. Never a shared database: those suites truncate.
- A deliberate shortcut with a known ceiling gets a `ponytail:` marker naming the ceiling and the
  trigger to upgrade.
- Append to `<S>/runs/build.txt`, under a heading naming the slice (or `release fix` and the Must
  Fix items it closes): the **exact commands with their real pass/fail counts**, the real-DB output
  when it ran, and a `Deviations` list with the reason for each departure from the plan. Never write
  a count you did not observe.

**Reviewer = GPT (Codex), read-only.** Do not review your own slice. Replace `<slice>` with the
slice's number and name from the plan, or `release fix` and the Must Fix items it closes:

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header && codev_need_worktree || exit 1
N=$(( $(ls "$S"/reviews/build-*.md 2>/dev/null | wc -l) + 1 ))
P="$S/runs/build-$N.prompt.md"
{ printf 'THE PIPELINE HOUSE RULES (the charter below calls this root CLAUDE.md; its #2 is the reuse-first ladder):\n\n'; cat "$H/CLAUDE.md"
  printf '\n\n'; cat "$H/prompts/reviewer.md"
  printf '\n\n'; cat "$H/checklists/scoring-rubric.md"
  printf '\n\n'; cat "$H/checklists/ponytail.md"
  printf '\n\nTHE BRIEF:\n\n'; cat "$S/brief.md"
  printf '\n\nTHE PLAN:\n\n'; cat "$S/plan.md"
  printf '\n\nTHE BUILD LOG:\n\n'; cat "$S/runs/build.txt" 2>/dev/null
  cat <<EOF

THE SLICE UNDER REVIEW: <slice>
You are GPT Codex, the reviewer. Step: build. Your working directory is the worktree, which holds this slice uncommitted on top of the slices already committed. Run 'git status --porcelain -uall' and 'git --no-pager diff HEAD' to see it; git diff omits untracked files, so open every untracked path in the status list and read it in full. Review that slice against the plan and the brief with the build lens: correctness, regressions, unhandled edge cases, security, and any deviation from the plan or scope creep beyond the slice named above. A deviation the build log does not record is a Must Fix; a release fix is not a deviation. Judge the TESTS as hard as the code: the builder wrote them, so ask whether they exercise the failure mode the plan names for this slice or only the happy path; a new behaviour with no test that could fail is a Must Fix. Any pass or fail count in the build log that the log itself does not show is a Must Fix. Hold the touched files to the repo's rules: read CLAUDE.md, including its rule headed AI-track code, and the CLAUDE.md of the app involved. The exoskeleton and LDD belong exactly where that rule puts them: full markup in a new AI-track Python module, a FUNC_ region and full LDD for a new function in a pre-existing one, LDD on the added control flow of an edited function, nothing at module level of a pre-existing module, nothing in frontend code or Alembic revisions. User-facing strings go through i18next with ru and en. No AI attribution in code or comments. Then apply the over-engineering lens above to the lines this slice adds or modifies: put the tagged findings under Should Consider, ending with the net line, unless the rubric makes one a Must Fix; section 4 of the lens lists what is not over-engineering here. Do not open or quote any .env file. You are read-only and must NEVER edit any file. Score 0-10 per the rubric. Your FINAL message must be the verdict block exactly as the charter specifies (Reviewer: GPT Codex, Step: build) and nothing else. Status is APPROVED only if Score is 9.0 or higher.
EOF
} > "$P"
cd "$WT" && codex exec --sandbox read-only -o "$S/reviews/build-$N.md" - < "$P" > "$S/runs/build-$N.log" 2>&1
if [ -s "$S/reviews/build-$N.md" ]; then echo "verdict: $S/reviews/build-$N.md"; else rm -f "$S/reviews/build-$N.md"; echo "codev: no verdict - see $S/runs/build-$N.log"; exit 1; fi
```

Read the verdict and report **Score** and **Status**:

- **APPROVED** (>= 9.0): commit the slice. Commit messages carry **no AI attribution**: superapp's
  `CLAUDE.md` forbids it in commits and PRs.

  ```bash
  H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
  . "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
  codev_need_header && codev_need_worktree || exit 1
  git -C "$WT" add -A && git -C "$WT" commit -m "<type>(<scope>): <subject> (ALL-<id>)"
  ```

  If slices remain, STOP and re-invoke this command for the next one. If this was the last slice,
  continue to 3b now.
- **BLOCKED** (< 9.0): fix only the cited Must Fix items in this slice and review again. **The same
  slice BLOCKED twice after fixes: STOP** and take it to the requester. Findings that keep coming
  back mean the plan is wrong for this slice: put the finding into the brief, and re-plan with
  `/step2` from 2d, which restarts the round count. A plan changed mid-build is reviewed like a new
  one.

---

## 3b — the release pass, then ship

Runs after the last slice is committed. GPT gets a write-enabled sandbox for one reason: to **run
the checks itself**, so for every check the sandbox can run, the release rests on counts GPT
observed rather than on the builder's claim. It still may not change anything.

First, **draft the PR body** in `<S>/handoff.md`, for the people who read the PR rather than for the
branch's history, in superapp's usual shape:

- `## What`: what a user can now do, or what now behaves differently.
- `## Why`: the problem, with the Linear id.
- `## Changes`: per file or area, one line each.
- `## Verification`: the commands and counts from the build log, plus any check in the browser. After
  APPROVED these are replaced by the counts GPT observed.
- `## Known follow-ups (not in this PR)`: the `ponytail:` markers the change adds (ceiling and
  trigger each), and anything deliberately left out.

No AI attribution, no secrets, tokens or personal data. Then run the pass:

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header && codev_need_worktree || exit 1
[ -z "$(git -C "$WT" status --porcelain)" ] || { echo "codev: $WT is not clean - commit the slice, or stash what an earlier pass left (below)"; exit 1; }
[ -s "$S/handoff.md" ] || { echo "codev: draft $S/handoff.md first"; exit 1; }
N=$(( $(ls "$S"/reviews/release-*.md 2>/dev/null | wc -l) + 1 ))
P="$S/runs/release-$N.prompt.md"
{ printf 'THE PIPELINE HOUSE RULES (the charter below calls this root CLAUDE.md):\n\n'; cat "$H/CLAUDE.md"
  printf '\n\n'; cat "$H/prompts/final-release-review.md"
  printf '\n\n'; cat "$H/checklists/scoring-rubric.md"
  printf '\n\n'; cat "$H/checklists/ponytail.md"
  printf '\n\nTHE BRIEF:\n\n'; cat "$S/brief.md"
  printf '\n\nTHE PLAN:\n\n'; cat "$S/plan.md"
  printf '\n\nTHE BUILD LOG:\n\n'; cat "$S/runs/build.txt" 2>/dev/null
  printf '\n\nTHE DRAFTED PR BODY:\n\n'; cat "$S/handoff.md"
  cat <<EOF

You are GPT Codex, the reviewer for the RELEASE pass of $SLUG. Step: ship. Your working directory is the worktree, and every slice is committed. Review the WHOLE change with 'git --no-pager diff origin/$BASE...HEAD' against the brief and the plan: every acceptance criterion met AND proven by a test you name; plus the defects a per-slice review misses: cross-cutting races, resource leaks, security (authz, injection, SSRF, secrets, rate limiting, tenant isolation), silent data corruption, swallowed failures. Cite file:line.
RUN THE CHECKS YOURSELF in this worktree: the jobs of .github/workflows/ci-<app>.yml for each app the diff touches (lint, format, type, tests, i18n, migration drift, generated API types), as far as this sandbox allows. Report the exact command lines and the counts you observed; the build log is a claim to verify, not evidence. A check that cannot run here because it needs a network, a database or credentials (the real-DB suites skip without their test DSN) is neither a pass nor a failure of the change: list each under Should Consider as UNVERIFIED IN SANDBOX, with what the build log claims for it, and set Release Risk to at least Medium when such a check covers changed code. This overrides the charter's rule on skipped tests for environment-caused skips only; a skip for any other reason still needs proof that it also skips on the base. A check that rewrites a tracked file (a generated API types file, say) and leaves a diff has found drift: report it as a Must Fix, do not keep the change.
THE REPO'S RULES: read CLAUDE.md, including its rule headed AI-track code, and apply it as written to every Python file in the diff: full markup (the MODULE_CONTRACT region, FUNC_ and CLASS_ regions, GREP_SUMMARY, STRUCTURE) and LDD as structlog fields (imp=, func=, block=) in a new AI-track module or a new test module covering those paths; a FUNC_ region and full LDD for a new function in a pre-existing module; LDD on the added control flow of an edited function; nothing at module level of a pre-existing module; nothing in frontend code or Alembic revisions. Missing required instrumentation is a Must Fix, and so is markup where the rule puts none. A schema change carries its revision with RLS and grants, and the sandbox proof appears in the build log.
OVER-ENGINEERING: apply the lens above to the whole diff, with findings under Should Consider unless the rubric makes one a Must Fix.
DEBT: run git --no-pager diff origin/$BASE...HEAD | grep -E '^\+.*(#|//|\*|--) ?ponytail:' and list every marker the change adds under Should Consider as file:line, ceiling, trigger; tag a marker that names no upgrade trigger no-trigger.
PR BODY: check the drafted PR body above: accurate, written for users, no secrets or personal data, and no count in it that you did not observe.
Do not open, print or quote any .env file or environment variable: the worktree may hold real credentials. You may run commands, but you must NOT create, edit or delete any file: if something needs changing, report it as a Must Fix. Your FINAL message must be the verdict block exactly as the charter specifies (Reviewer: GPT Codex, Step: ship) and nothing else. Status is APPROVED only if Score is 9.0 or higher.
EOF
} > "$P"
cd "$WT" && codex exec --sandbox workspace-write -o "$S/reviews/release-$N.md" - < "$P" > "$S/runs/release-$N.log" 2>&1
if [ -s "$S/reviews/release-$N.md" ]; then echo "verdict: $S/reviews/release-$N.md"; else rm -f "$S/reviews/release-$N.md"; echo "codev: no verdict - see $S/runs/release-$N.log"; fi
git -C "$WT" status --porcelain   # must be empty
```

**If that last `status` is not empty**, look at what changed before anything else. A generated file
a check rewrote is the drift GPT should have reported as a Must Fix; anything else is the reviewer
touching the tree, and a verdict made while editing the code is not a review. Either way, clear it
without losing it, then re-run the pass:

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header && codev_need_worktree || exit 1
git -C "$WT" status --porcelain
git -C "$WT" stash push --include-untracked -m "codev $SLUG: left by the release pass"
```

Report **Score** and **Status**:

- **BLOCKED** (< 9.0): list every Must Fix and fix them in **3a** as a `release fix` slice (build,
  GPT slice review, commit), then re-run 3b.
- **APPROVED** (>= 9.0): ship.

**Ship (Opus, on APPROVED only).** Replace the handoff's `## Verification` counts with the ones in
the release verdict, and carry its UNVERIFIED IN SANDBOX list and its Release Risk line into the PR
body. Title: `<type>(<scope>): <subject> (ALL-<id>)`. Push and open the PR **with the base named
explicitly** (`gh pr create` otherwise targets the default branch):

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header && codev_need_worktree || exit 1
git -C "$WT" push -u origin "$BR" && cd "$WT" && gh pr create --base "$BASE" --head "$BR" --title "<type>(<scope>): <subject> (ALL-<id>)" --body-file "$S/handoff.md"
```

**Register the bet** (skip it when the brief says Hypothesis: none). Once the PR is open, record the
brief's Hypothesis in PostHog through its MCP, in the project that holds the app's events, so that
`/learn` can check it after release:

1. Save the signal as an insight named `<slug> · <signal>` and add it to the dashboard
   «Hypotheses — bets and demand» (`dashboards-get-all` with `search: "Hypotheses"`): the signal over
   time, prod only, filtered to the app the way that board's demand tables are.
2. Create the notebook `Hypothesis · <slug> · <title>` from `<H>/briefs/HYPOTHESIS.md`: Status
   `building`, the branch, the PR and its date, the Hypothesis and In short verbatim from the brief,
   and the insight embedded.

Give the requester both links. Nothing else changes in PostHog until `/learn`, which notices the
release to `main` and starts the window.

The requester merges. After PM QA on `dev`, promotion to `main` follows superapp's `CLAUDE.md`:
cherry-pick the feature commits onto `<branch>-main` and open a PR into `main`.

**After the merge, remove the worktree** (the branch stays). Removing it deletes its gitignored
files, so the block refuses while a `.env` is still inside; the results are safe in `<S>`. A
session's own worktree is left alone: the app removes it with the session, and `<S>` goes with it,
so copy out first whatever must outlive the session:

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
[ -d "$WT" ] || { echo "codev: no worktree at $WT"; exit 0; }
[ "$WT" != "$R" ] || { echo "codev: $WT is this session's own worktree - the app removes it with the session"; exit 0; }
E=$(git -C "$WT" status --ignored --porcelain | grep -E '^!! (.*/)?\.env')
[ -z "$E" ] || { echo "codev: $WT still holds these - keep what you need, delete them, re-run:"; echo "$E"; exit 1; }
git -C "$M" worktree remove ".worktrees/$SLUG" && echo "worktree removed; branch $BR kept"
```

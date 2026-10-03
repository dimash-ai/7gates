---
description: "Step 2 (plan): GPT plans the stages from the brief and the code, every stage in detail so step 3 only implements; a blind Opus reviews it against the MVP lens; you confirm the stages"
argument-hint: <slug> [repo-path]
---

# Step 2 — the stage plan  ·  GPT plans · a blind Opus reviews · you confirm

The second step of the **co-dev flow** (`harness/README-codev.md`). It turns the brief the requester
confirmed in step 1 into **the stage plan**: the **stage map** (every stage, one row: what users get
on dev, its demo script, budget, risk, guard) and **every stage's detail**, stage 1's the fullest.
All the planning happens here, so that step 3 is implementation and nothing else. **GPT plans, cold,
from the brief and the code**; a blind Opus scores the plan against `<H>/checklists/mvp.md`; the
requester confirms the stages. When the map changes later (dev showed something, the requester
re-orders or adds), this step runs again and re-plans only the stages not yet started.

There is no separate research phase: the planner reads the code it plans against, cites it as
`file:line`, and the reviewer checks the citations. For an epic with large unknowns, run
`/gate-explore` before step 1, not here.

**Timebox: about an hour** to the stop: GPT's run, one review, at most one revision. The plan is
under about 300 lines.

`$1` is the slug from step 1; `$2` is the code repo, optional. Every bash block sources
`harness/bin/codev-env.sh`, which prints `codev: slug=… results=<S> worktree=<WT> …`; in the prose,
`<S>`, `<WT>` and `<H>` (the `harness/` directory) mean those literal paths.

**Links.** When you point the requester at a file of the flow (the plan, the brief, a verdict), write
a markdown link whose target is the file's path relative to the session's working directory, usually
`[plan.md](specs/$1/plan.md)`; never a bare path in backticks.

**Speed rule.** If ultracode or a high effort is on, do not spend it here on extra planners, extra
reviewers, research sweeps or longer documents (`mvp.md` §6). One planner, one blind reviewer.

## Before you start — where this slug stands

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header || exit 1
if [ -d "$WT" ]; then echo "worktree: on $(git -C "$WT" branch --show-current)"; else echo "worktree: not yet - start at 2a"; fi
[ -s "$S/plan.md" ] && echo "plan: $(wc -l < "$S/plan.md") lines" || echo "plan: not yet"
[ -s "$S/progress.md" ] && grep -E '^\| [0-9]+ ' "$S/progress.md"
ls "$S/reviews" 2>/dev/null | grep '^plan-' || echo "no plan reviews yet: the next review is round 1"
```

No brief header means step 1 is not finished. **A re-plan** (a plan exists and some stages are
already on dev) keeps the worktree where it is: skip 2a, and the round numbering of the plan reviews
continues.

## 2a — The worktree, on stage 1's branch

It pins the tree GPT plans against and Opus builds stage 1 in: the branch `<Branch>-s1`, cut from
the remote tip of the base. In a session with a worktree of its own, the block moves that worktree
onto the branch instead of adding one; it must be clean (the flow's files do not count: `specs/` is
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

## 2b — GPT plans, cold and read-only

**Doer = GPT (Codex).** It sees the brief and the repo, nothing of this conversation; on a re-plan
also the current plan and the progress board. It runs **read-only** and **in the background** (Bash
`run_in_background`); its final message is the plan. While it runs, read the territory of stage 1
in `<WT>` yourself, so you are ready to build it and to judge the review; keep your notes in the
scratchpad (GPT's working directory may contain `<S>`).

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header && codev_need_worktree || exit 1
P="$S/runs/plan-codex.prompt.md"
{ printf 'THE PIPELINE HOUSE RULES (the charter below calls this root CLAUDE.md; its #2 is the reuse-first ladder):\n\n'; cat "$H/CLAUDE.md"
  printf '\n\n'; cat "$H/prompts/doer.md"
  printf '\n\nTHE MVP LENS (binding):\n\n'; cat "$H/checklists/mvp.md"
  printf '\n\n'; cat "$H/checklists/ponytail.md"
  printf '\n\nTHE BRIEF:\n\n'; cat "$S/brief.md"
  printf '\n\nTHE PLAN TEMPLATE:\n\n'; cat "$H/design/TEMPLATE-stages.md"
  if [ -s "$S/plan.md" ] && grep -qE '^\| [0-9]+ \|[^|]*\| (building|review|PR|on dev|verified)' "$S/progress.md" 2>/dev/null; then   # a stage is under way: re-plan
    printf '\n\nRE-PLAN. THE CURRENT PLAN:\n\n'; cat "$S/plan.md"
    printf '\n\nTHE PROGRESS BOARD (what is already on dev):\n\n'; cat "$S/progress.md"
    printf '\n\nThis is a RE-PLAN: keep every stage that is building, in review, in a PR, on dev or verified exactly as it is, map row and detail. Re-plan only the stages not yet started, against the code as it is now, and the brief as it is now.\n'
  fi
  cat <<EOF

You are GPT Codex, the doer for the PLAN step of $SLUG, in STAGE MODE. Your working directory is the code repo, at the commit the plan will be built on. The brief above is your whole task, and nobody will answer questions during this run. The repo's own CLAUDE.md, AGENTS.md and the CLAUDE.md of the app the brief names are binding: read them. Then study the code until you can plan against what is actually there, and write the plan in the template's structure, under about 200 lines.
The plan is a STAGE MAP plus EVERY STAGE'S DETAIL, following the MVP lens above, under about 300 lines in all. Step 3 only implements: it has no design step, so whatever a builder needs to know about a stage is planned here. Stage 1 is the brief's MVP; if something smaller still meets its criteria and is what a user would recognise, propose it in the Decision and say why. Every stage is user-visible on the dev environment, with a demo script a person can follow there, a budget of at most about four hours of build, a risk class (low, data, auth) and a guard that keeps the shared dev environment safe until users are switched over (additive, a hidden route, a dev-only flag). A foundation without a visible result is folded into the first stage that uses it, or is a stage of about two hours that the very next stage uses. Order the stages by value to the user; put what needs a migration, a backfill or a new server contract into the stage where it is first needed, never ahead of it. Stage 1's detail is the fullest; a later stage's detail is short (what the user gets, the approach with the file:line it builds on, the files, the tests, the data), because the code will have moved by the time it is built and its builder records any departure. Do NOT plan the feature to its last edge case: in every stage the tests are its demo path, a regression guard for every behaviour users have today that it touches, and the repo's mandatory proofs; edge cases of the new feature beyond the demo path are follow-ups, listed under the stage's Not in this stage, not built. Every new file, module, dependency or abstraction names the ladder rung it stopped at. Cite every claim about existing code as file:line. Build on what the brief records as answered or decided; do not reopen it. If the brief's Hypothesis signal does not exist yet, one stage adds it, through the app's own analytics helper.
The superapp rules the plan carries wherever they apply: the rule headed AI-track code in the repo's CLAUDE.md, applied as written (Python only, in services/assistant and the agent-API, agent-token and MCP modules of apps/focal/server and apps/prima/server; frontend code and Alembic revisions are exempt); a schema change ships its Alembic revision with RLS and grants written in and the sandbox proof (scripts/migration-sandbox.sh with the app's server dir and schema, plus an assertion that the policies exist), additive only, never applied to a shared database; DB-backed behaviour is tested by the app's real-DB suite against that sandbox; user-facing strings go through i18next with ru and en; the verification commands are the jobs of .github/workflows/ci-<app>.yml for each app a stage touches.
For anything version-sensitive the brief does not settle, name the pinned version you read from the lockfile and mark it UNVERIFIED. Do not open or quote any .env file. IF the brief is ambiguous in a way that would change STAGE 1, do not plan around it: make your final message a section titled QUESTIONS listing each ambiguity, with the answer you would assume, and nothing else; an ambiguity that only touches a later stage goes into that stage's detail as an assumption marked UNVERIFIED. You are read-only and must NEVER edit any file. Your FINAL message must be the complete plan in Markdown, or the QUESTIONS section, and nothing else.
EOF
} > "$P"
cd "$WT" && codex exec --sandbox read-only -o "$S/plan.new.md" - < "$P" > "$S/runs/plan-codex.log" 2>&1
if [ -s "$S/plan.new.md" ]; then
  [ -f "$S/plan.md" ] && mv "$S/plan.md" "$S/plan.prev.md"
  mv "$S/plan.new.md" "$S/plan.md" && echo "plan written: $(wc -l < "$S/plan.md") lines"
else
  rm -f "$S/plan.new.md"; echo "codev: codex returned no plan - see $S/runs/plan-codex.log"; exit 1
fi
```

- A failed or killed run leaves `plan.md` as it was. If the configured model is rejected, re-run
  with `-m <a model from ~/.codex/models_cache.json>`. If `codex exec` fails auth, **STOP** and
  recover with `rm ~/.codex/auth.json && codex login`.
- **If the plan is a QUESTIONS section**, ask the requester in one round, following `mvp.md` §4,
  put the answers into the brief, and re-run 2b. That is the brief failing, not the plan.

## 2c — A blind Opus reviews

**Reviewer = Opus, fresh context.** Do **not** review inline: you wrote the brief. Spawn a
clean-context reviewer with the **Agent tool** (`subagent_type: "claude"`, `model: "opus"`), passing
this prompt with the literal paths written in:

> You are Opus, the blind reviewer for the PLAN step of `$1`, in STAGE MODE. GPT Codex wrote this
> plan; you did not, and you did not take part in the conversation behind the brief. Read, in this
> order: `<H>/prompts/reviewer.md` (your charter and verdict format), `<H>/checklists/scoring-rubric.md`
> (its Stage mode section governs this review), `<H>/checklists/mvp.md` (the stage rules; its §5 lists
> the only grounds for a Must Fix), `<H>/checklists/ponytail.md`, the brief `<S>/brief.md`, the plan
> `<S>/plan.md`, then `<WT>/CLAUDE.md`, the CLAUDE.md of the app involved, and the code stage 1
> cites, in `<WT>`. **From round 2:** also read `<S>/plan.prev.md` and the previous verdict
> `<S>/reviews/plan-<N-1>.md`; check that each Must Fix was fixed and nothing else changed.
> Review stage 1 in depth and every later stage for ship-blockers only.
> **Must Fix only for a plan ship-blocker:** stage 1 is not the smallest increment a user would
> recognise (say what is smaller); a stage that is not user-visible on dev and is not a two-hour
> foundation the next stage uses; a stage over about four hours; a stage with no guard or no demo
> script; a literal ask of the request that no stage delivers and the requester did not defer;
> a stage's approach is wrong against the code (verify the `file:line` citations in `<WT>`, all of
> stage 1's and those later stages rest on), would break something users have today, or breaks a repo
> rule (the AI-track rule as written, a migration
> without RLS, grants and the sandbox proof, strings outside i18next, checks that do not match
> `.github/workflows/ci-<app>.yml`); a migration, backfill or new contract placed ahead of the stage
> that first needs it; a version-sensitive claim that is wrong (check the lockfiles, and the docs for
> that version through Context7 or WebSearch); on a re-plan, any change to a stage that already
> started. **Everything else** (edge cases beyond a stage's demo path, wording, nicer architectures,
> more tests) goes under Should Consider, one line each: it never blocks. Verify with file reads, grep and git only:
> no `uv`, `pnpm` or installs, which stall in a fresh worktree; find an Alembic head by grepping
> `^revision` / `^down_revision`. You are read-only. Output only the verdict block (Reviewer: Opus,
> Step: plan). Status is APPROVED exactly when there is no Must Fix.

Save **only the verdict block**, from the `# Review Verdict` line to the end, to
`<S>/reviews/plan-<N>.md`, where `<N>` is this round (on a re-plan, the numbering continues). Then:

- **APPROVED**: go to 2e.
- **BLOCKED the first time**: run the revision (2d), then review again with a fresh subagent.
- **BLOCKED the second time**: STOP. Take the open Must Fix items to the requester, each with the options:
  fix the plan, accept it as a follow-up, or change the stage. Two rounds that do not converge mean
  the stage is cut wrong, not that the plan needs a third pass.

## 2d — Revision (only on BLOCKED)

GPT revises its own plan against the latest verdict, fixing only the cited Must Fix items. Replace
`<N>` with the number of that verdict:

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header && codev_need_worktree || exit 1
V="$S/reviews/plan-<N>.md"; [ -s "$V" ] || { echo "codev: no verdict at $V"; exit 1; }
P="$S/runs/plan-revision.prompt.md"
{ printf 'THE PIPELINE HOUSE RULES:\n\n'; cat "$H/CLAUDE.md"
  printf '\n\nTHE MVP LENS (binding):\n\n'; cat "$H/checklists/mvp.md"
  printf '\n\nTHE BRIEF:\n\n'; cat "$S/brief.md"
  printf '\n\nYOUR CURRENT PLAN:\n\n'; cat "$S/plan.md"
  printf '\n\nTHE REVIEWER VERDICT:\n\n'; cat "$V"
  cat <<EOF

You are GPT Codex, the doer for the PLAN step of $SLUG, in STAGE MODE, revising your own plan after review. Your working directory is the code repo. Fix ONLY the Must Fix items in the verdict, checking each against the code; change nothing else, and do not act on Should Consider items. If a Must Fix is wrong, keep the plan as it is on that point and say why, with evidence, in one line under a heading REVIEWER DISAGREEMENTS at the end of the plan. Keep the plan under about 300 lines. Do not open or quote any .env file. You are read-only and must NEVER edit any file. Your FINAL message must be the complete revised plan in Markdown and nothing else.
EOF
} > "$P"
cd "$WT" && codex exec --sandbox read-only -o "$S/plan.new.md" - < "$P" > "$S/runs/plan-revision.log" 2>&1
if [ -s "$S/plan.new.md" ]; then
  mv "$S/plan.md" "$S/plan.prev.md" && mv "$S/plan.new.md" "$S/plan.md" && echo "revised plan written; the scored one is plan.prev.md"
else
  rm -f "$S/plan.new.md"; echo "codev: codex returned no revision - see $S/runs/plan-revision.log"; exit 1
fi
```

## 2e — The stop: the requester confirms the stages

Update `<S>/progress.md` from the stage map: one row per stage with its budget (stages already
under way keep their status), and the review's Should Consider items under Follow-ups. Then **STOP** and show in the chat:

- the **stage map** as a table, with stage 1 first and the hours to its arrival on dev;
- stage 1 in three lines: what users get, how to see it on dev, what it leaves to later stages;
- the follow-ups the review raised, one line each;
- a link to `<S>/plan.md` and to the verdict (see **Links**).

Ask in one round (AskUserQuestion):

1. **The stages**: confirm, re-order, cut or merge them. The smallest change is the default.
2. **Shipping**: when a stage's review and CI are green, (a) show me the stage, then I say "ship"
   and you open and merge its PR into dev (Recommended), or (b) open and merge it on your own, and
   show me on dev. Record the answer as `Ship: ask` or `Ship: auto` in the brief's header.

Their yes ends step 2. Next: `/step3 $1`, once per stage.

**When the brief or the map changes later**, nothing that shipped is redone and nothing restarts:
put the change into the brief (the stages, Questions and answers), then run `/step2 $1` again. It
re-plans only the stages not yet started (2b's re-plan), one blind review checks the result, and the
stop shows the new map. A one-line change to a single not-yet-started stage (a budget, an order) can
be edited into the map and the board directly, without a run.

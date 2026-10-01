---
description: "Step 2 (plan): Opus and GPT research the brief independently, GPT plans from it, a blind Opus reviews"
argument-hint: <slug> [repo-path]
---

# Step 2 — plan  ·  Opus and GPT research · GPT plans · Opus reviews

The second step of the **3-step co-dev flow** (`harness/README-codev.md`). It takes the brief the
requester confirmed in step 1 (the problem, the user stories, the business side) and finds out how
to deliver it: **Opus and GPT research the code independently** and Opus merges both sweeps into the
brief, then **GPT writes the complete plan from the brief**, and a blind Opus scores it. No code is
written until the score clears 9.0.

`$1` is the slug from step 1; `$2` is the code repo, optional. Every bash block sources
`harness/bin/codev-env.sh`, which prints `codev: slug=… results=<S> worktree=<WT> …`; in the prose,
`<S>`, `<WT>` and `<H>` (the `harness/` directory) mean those literal paths.

All of it happens in `<WT>`, the tree 2a pins: both sweeps read it and GPT plans against it, so the
research, the plan's citations and the code the build will change describe the same commit. Every
Codex run below goes **in the background** (Bash `run_in_background`): a sweep or a plan over a
large repo outlasts the Bash tool's timeout. Its output goes to files, and the block prints only
whether it produced something.

## Before you start — where this slug stands

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header || exit 1
if [ -d "$WT" ] && [ "$(git -C "$WT" branch --show-current)" = "$BR" ]; then echo "worktree: pinned on $BR"; else echo "worktree: not yet - start at 2a"; fi
if grep -q '^## Findings' "$S/brief.md"; then echo "research: in the brief - go to 2d"; else echo "research: not yet - run 2b and 2c"; fi
ls "$S/reviews" 2>/dev/null | grep '^plan-' || echo "no plan reviews yet: the next review is round 1"
```

No brief header means step 1 is not finished. A brief that already holds its research (its step 1
ran before the research moved into this step, or this step stopped after 2c) goes straight to 2d.
The listing tells you the round: `plan-1.md` and `plan-2.md` present means the next review is round
3, the last.

## 2a — The worktree

It pins the tree that both sweeps read, that GPT plans against, and that Opus builds in. In a
session with a worktree of its own, the block moves that worktree onto the branch instead of adding
one. It must be clean (the flow's files do not count: `specs/` is gitignored), and the app's own
`claude/…` branch stays behind, unused:

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header || exit 1
mkdir -p "$S/research" "$S/reviews" "$S/runs"
if [ "$WT" = "$R" ]; then   # the session's own worktree (see codev-env.sh): move it onto the branch
  if [ "$(git -C "$WT" branch --show-current)" != "$BR" ]; then
    [ -z "$(git -C "$WT" status --porcelain)" ] || { echo "codev: $WT has uncommitted changes - commit or move them, then re-run"; exit 1; }
    git -C "$M" fetch origin "$BASE" --quiet || { echo "codev: cannot fetch origin/$BASE"; exit 1; }
    git -C "$M" fetch origin "refs/heads/$BR:refs/remotes/origin/$BR" --quiet 2>/dev/null   # the branch, if it already exists on origin
    if git -C "$M" show-ref --verify --quiet "refs/heads/$BR" || git -C "$M" show-ref --verify --quiet "refs/remotes/origin/$BR"; then
      git -C "$WT" switch "$BR" || exit 1                                          # existing branch: attach to it
    else
      git -C "$WT" switch --no-track -c "$BR" "origin/$BASE" || exit 1             # new branch from the remote tip
    fi
  fi
elif [ -d "$WT" ]; then
  echo "worktree exists on $(git -C "$WT" branch --show-current)"
else
  git -C "$M" fetch origin "$BASE" --quiet || { echo "codev: cannot fetch origin/$BASE"; exit 1; }
  git -C "$M" fetch origin "refs/heads/$BR:refs/remotes/origin/$BR" --quiet 2>/dev/null   # the branch, if it already exists on origin
  if git -C "$M" show-ref --verify --quiet "refs/heads/$BR" || git -C "$M" show-ref --verify --quiet "refs/remotes/origin/$BR"; then
    git -C "$M" worktree add ".worktrees/$SLUG" "$BR" || exit 1                              # existing branch: attach to it
  else
    git -C "$M" worktree add --no-track -b "$BR" ".worktrees/$SLUG" "origin/$BASE" || exit 1   # new branch from the remote tip
  fi
fi
echo "pinned: $(git -C "$WT" rev-parse --short HEAD) $(git -C "$WT" log -1 --format=%cs)"
```

Add `Pinned: <sha>` from that last line to the brief's header.

## 2b — Two sweeps, independent and in parallel

Start GPT first, then sweep yourself while it runs. **Do not open `<S>/research/codex.md` until
`<S>/research/opus.md` is written**: reading GPT first anchors you on it, and the union stops being
two views. The block writes GPT's output to files and prints only its exit status, so nothing of
the sweep reaches you early. The wall runs the other way too: in a session with a worktree of its
own, `<S>` sits inside GPT's working directory, so keep your sweep in the scratchpad until GPT's run
has exited, and only then write `opus.md`.

**GPT**: read-only, in the worktree, web search on, the prompt read from a file and the final
message written by `-o`. Replace `<quick|full>` with the brief's `Depth:`. Run it **in the
background** (Bash `run_in_background`).

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header && codev_need_worktree || exit 1
grep -q '^## Findings' "$S/brief.md" && { echo "codev: the research is already in $S/brief.md - go to 2d"; exit 1; }
P="$S/runs/brief-codex.prompt.md"
{ cat "$H/checklists/ponytail.md"
  printf '\n\nTHE BRIEF, as the requester confirmed it in step 1. It says what users should get and why; it is the question, not a design:\n\n'; cat "$S/brief.md"
  cat <<EOF

DEPTH: <quick|full>. quick means sections 1, 2, 4 and 5 only, and only around the screens and flows the brief names. full means all six sections.

You are GPT Codex on a reconnaissance sweep of the code repo in your working directory. You are NOT solving this request and NOT proposing a design: you are finding everything a planner would need to know before designing one. Work INDEPENDENTLY and from scratch: do not look for, assume, or defer to any other model's findings.
Sweep for: (1) TERRITORY - every module, route, table, migration, config and test the user stories plausibly touch, naming the story (US-n) each item serves, and every other place a user meets the same data or flow (another screen, another app's mount), since the change reaches it too. (2) PRIOR ART - code that already does part of this and should be reused instead of reinvented. Walk the ladder in the lens above and record each item with its rung number: 2 existing code in this repo, 3 the standard library, 4 a native platform or framework feature, 5 an already-installed dependency. If something already covers the whole intent, say so first. (3) CONSTRAINTS - pinned versions read from pyproject.toml, package.json and the lockfiles (name the file), contracts and interfaces this must not break, and the rules that govern this surface: read CLAUDE.md, AGENTS.md and the CLAUDE.md of the app involved, and state whether the change is AI-track code (semantic exoskeleton and LDD), needs a migration (sandbox proof), adds user-facing strings (i18next, ru and en), or crosses a tenant-isolation or RLS boundary; name the CI workflow (.github/workflows/ci-<app>.yml) whose jobs verify it. (4) SCARS - BUG_FIX_CONTEXT comments, recorded deviations, TODOs, ponytail: markers and past workarounds in the code this touches: what was already tried and why it failed. (5) TESTS - what covers this surface today, and what each test actually asserts versus what its name claims. (6) ABSENCES - invariants stated only in a comment with nothing enforcing them, configurable values whose worst legal setting is materially worse than the default, two concerns sharing one credential or limit, code paths with no test.
Cite EVERY item as file:line. An item you cannot cite is not evidence: drop it, or mark it explicitly as a hunch. For facts outside this repo (library behaviour at the pinned version, platform features) use your web search tool and cite the URL; if you have no web access, say so, and never invent a URL, version or API detail. Do not open or quote any .env file. Sweep WIDE, report NARROW: include an item only if a planner could plausibly make a different decision because of it. Do not propose a solution, a design or an implementation order. You are read-only and must NEVER edit any file. Your FINAL message must be the complete sweep in Markdown, one section per category, and nothing else.
EOF
} > "$P"
cd "$WT" && codex exec --sandbox read-only --config 'web_search="live"' -o "$S/research/codex.md" - < "$P" > "$S/runs/brief-codex.log" 2>&1
echo "codex exit=$?  sweep bytes=$(wc -c < "$S/research/codex.md" 2>/dev/null || echo 0)"
```

- An empty sweep or a non-zero exit is a failed run: read `<S>/runs/brief-codex.log` (not the
  sweep). If this Codex version rejects `--config 'web_search="live"'`, drop the flag, re-run, and
  record in the brief that GPT's sweep has no external facts, so every external fact rests on Opus
  alone.
- If `codex exec` fails auth, **STOP**. One sweep is a search, not this step. Recover with
  `rm ~/.codex/auth.json && codex login`, then re-run.

**Opus (you)**: the same brief, the same depth, the same categories and rung numbers, reading the
code in `<WT>`, not the main checkout. Write `<S>/research/opus.md`. Cite every item as `file:line`,
every external fact by URL: Context7 for library docs at the pinned version, WebSearch or WebFetch
for the rest. Never answer a version or API question from memory. Read-only subagents for breadth
are fine.

## 2c — Merge into the brief

When the background run has finished and `opus.md` is written, read both sweeps. Append the research
part of `<H>/briefs/TEMPLATE.md` below the brief's product part, and fill it:

- **Union, not intersection.** An item only one sweep found is the coverage you paid for. Tag every
  item `[O]`, `[G]` or `[both]`.
- **Re-check GPT's citations** against `<WT>`. Fix or drop a wrong one and say so in the brief.
- **Contradictions** (the same fact reported two ways) are settled by reading the code, never by
  picking the more confident sweep. When the code cannot settle it because it is a product decision
  (what *should* happen, not what does), it is a question for the requester.
- **What users would meet that the brief does not mention** (another screen or app that shows the
  same thing, data made before the change, a group of users it reaches) is a question for the
  requester.
- **Gaps** (what neither sweep could establish) become open questions, each marked `UNVERIFIED` with
  what would close it.
- **Prior art that already covers the whole intent** (rungs 2 to 5: this repo, the standard library,
  the platform, an installed dependency) is a question for the requester: "X already does this.
  Still build?"
- **Sweep wide, report narrow.** A finding earns a place in the brief only if the planner could
  decide differently because of it. The raw sweeps stay in `research/` and are not pasted in.

Its Acceptance criteria are every story criterion by id, then any criterion the research added that
no story covers (`R-1` …), each naming the finding it came from. Its Verification section names the
jobs of `.github/workflows/ci-<app>.yml` for each app the change touches: that is where superapp's
real checks live.

**If the merge raised questions for the requester, STOP** and ask them in one round, each with the
answer you would assume. Their answers go under Questions and answers and into the stories they
change; no contradiction may stay open. If an answer changes the brief's In short or who it is for,
go back to `/step1`: the research answered a different question. Without questions, go on to 2d.

## 2d — GPT plans, cold and read-only

**Doer = GPT (Codex).** It sees the brief and the repo, nothing of this conversation. It runs
**read-only**, and its final message is the plan.

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header && codev_need_worktree || exit 1
P="$S/runs/plan-codex.prompt.md"
{ printf 'THE PIPELINE HOUSE RULES (the charter below calls this root CLAUDE.md; its #2 is the reuse-first ladder):\n\n'; cat "$H/CLAUDE.md"
  printf '\n\n'; cat "$H/prompts/doer.md"
  printf '\n\n'; cat "$H/checklists/ponytail.md"
  printf '\n\nTHE BRIEF:\n\n'; cat "$S/brief.md"
  printf '\n\nTHE PLAN TEMPLATE:\n\n'; cat "$H/design/TEMPLATE-3gate.md"
  cat <<EOF

You are GPT Codex, the doer for the PLAN step of $SLUG. Your working directory is the code repo, at the commit the brief was researched against. The brief above is your whole task, and nobody will answer questions during this run. The repo's own CLAUDE.md, AGENTS.md and the CLAUDE.md of the app the brief names are binding: read them. Then study the code until you can plan against what is actually there, and write the complete plan in the structure of the template: the problem and the decision, with the alternatives you rejected; assumptions marked confirmed or UNVERIFIED; scope; success criteria, where every acceptance criterion of the brief traces to a slice and to the test that proves it; the build as independently shippable slices, each with its files, its main failure mode and what its test proves; the new-surface table, where every new file, module, dependency or abstraction names the ladder rung it stopped at and why the earlier rungs did not hold; architecture and contracts; the happy AND unhappy flow; the test strategy, security and rollback. Close every open question in the brief, or carry it forward as an explicit UNVERIFIED assumption. Build on what the brief records as answered or decided; do not reopen it. Cite every claim about existing code as file:line.
The superapp rules the plan must carry wherever they apply. AI-track code: read the rule headed AI-track code in the repo's CLAUDE.md and apply it as written. It covers Python only, in services/assistant and in the agent-API, agent-token and MCP modules of apps/focal/server and apps/prima/server. A new module, and a new test module covering those paths, carries the full semantic exoskeleton and LDD as structlog fields. In a pre-existing module, a new function gets a FUNC_ region and full LDD, an edited function gets LDD on the control flow the change adds, a trivial edit gets nothing, and nothing is added at module level. Frontend code and Alembic revisions are exempt. A schema change ships its Alembic revision with RLS and grants written in, and the sandbox proof (scripts/migration-sandbox.sh with the app's server dir and schema, plus an assertion that the policies exist) is one of its acceptance checks; nothing is ever applied to a shared database. DB-backed behaviour is tested by the app's real-DB suite against that sandbox. User-facing strings go through i18next with ru and en. The verification commands are the jobs of .github/workflows/ci-<app>.yml for each app the change touches.
For anything version-sensitive the brief does not settle, name the pinned version you read from the lockfile and mark it UNVERIFIED. Do not open or quote any .env file. IF the brief is ambiguous in a way that would change the plan, do not plan around the ambiguity: make your final message a section titled QUESTIONS that lists each ambiguity and what you would need to know, and nothing else. You are read-only and must NEVER edit any file. Your FINAL message must be the complete plan in Markdown, or the QUESTIONS section, and nothing else.
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

A failed or killed run leaves `plan.md` as it was: the output goes to `plan.new.md` and replaces the
plan only when it is non-empty.

**If the plan is a QUESTIONS section**, stop: take the questions to the requester, put the answers
into the brief, and re-run 2d. That is the brief failing, not the plan, and it costs one run
instead of a wrong plan.

## 2e — A blind Opus reviews

**Reviewer = Opus, fresh context.** Do **not** review inline: you shaped the request and watched the
brief being written. Spawn a clean-context reviewer with the **Agent tool** (`subagent_type:
"claude"`, `model: "opus"`), passing this prompt with the literal paths written in:

> You are Opus, the blind reviewer for the PLAN step of `$1`. GPT Codex wrote this plan; you did not,
> and you did not take part in the conversation behind the brief. Read, in this order:
> `<H>/prompts/reviewer.md` (your charter: follow its review rules and output its verdict format
> exactly), `<H>/CLAUDE.md` (the pipeline house rules the charter calls root CLAUDE.md; its #2 is
> the reuse-first ladder), `<H>/checklists/scoring-rubric.md`, `<H>/checklists/ponytail.md`, the
> brief `<S>/brief.md`, the plan `<S>/plan.md`, then `<WT>/CLAUDE.md`, the CLAUDE.md of the app
> involved, and the code the plan cites, in `<WT>`. **From round 2:** also read the previous plan
> `<S>/plan.prev.md` and the previous verdict `<S>/reviews/plan-<N-1>.md`; check that each Must Fix
> was fixed and nothing else changed, and weigh any REVIEWER DISAGREEMENTS section on its evidence.
> Apply the plan and design lenses together: is the problem framed right and the approach justified
> against the alternatives; are assumptions explicit and scope bounded; is the build sliced into
> sound, independently shippable steps, each with a named failure mode and a test that proves
> something; is the architecture coherent (coupling, data model, interfaces, the unhappy path)?
> **Traceability:** every acceptance criterion of the brief maps to a slice and a test; one that does
> not is a Must Fix, and so is a slice that serves no criterion. **The ladder:** every new file,
> module, dependency or abstraction names its rung and why the earlier rungs did not hold; a new
> surface with no rung, or one an earlier rung obviously covers, is a Must Fix. **superapp's
> rules:** the AI-track rule in `<WT>/CLAUDE.md`, applied as written (full markup for new modules,
> FUNC_ region and LDD for new functions in pre-existing ones, nothing at module level there, and
> nothing for frontend or Alembic); a schema change carries RLS, grants and the sandbox proof, and
> DB-backed behaviour is tested against the sandbox; user-facing strings use i18next with ru and
> en; the verification commands match `.github/workflows/ci-<app>.yml`. **Citations:** verify the
> plan's `file:line` claims against `<WT>`; a plan built on code that is not there is a Must Fix.
> **Versions:** you own every version-sensitive claim; check it against the lockfiles and, where the
> API matters, the docs for that version (Context7 or WebSearch). A stale API or wrong version is a
> Must Fix. You are read-only. Output only the verdict block (Reviewer: Opus, Step: plan). Status is
> APPROVED only if Score >= 9.0.

Save **only the verdict block**, from the `# Review Verdict` line to the end, to
`<S>/reviews/plan-<N>.md`, where `<N>` is this round (1, 2 or 3). STOP; write no code. Report
**Score** and **Status**:

- **APPROVED** (>= 9.0): tell the requester to skim the slice table (two minutes, the last cheap
  moment to change course). Next: `/step3 $1`.
- **BLOCKED** (< 9.0) in round 1 or 2: list every Must Fix, run the revision (2f), and review again
  with a fresh subagent.
- **BLOCKED in round 3**: STOP. Three rounds that do not converge mean the brief is too broad or too
  vague, not that the plan needs a fourth pass. Go back to `/step1` with the requester: sharpen the
  brief, or split the work into several slugs, each with its own branch.

**When the brief changes** (answers to QUESTIONS, a return from round 3, or a plan defect found
during the build), the round count restarts: move `<S>/reviews/plan-*.md` into
`<S>/reviews/archive-<date>/`, then run 2d again from scratch. If the stories changed, the
research may no longer fit them: take the research part out of the brief and run 2b first.

## 2f — Revision (only on BLOCKED)

GPT revises its own plan against the latest verdict, fixing only the cited Must Fix items. Replace
`<N>` with the number of that verdict:

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header && codev_need_worktree || exit 1
V="$S/reviews/plan-<N>.md"; [ -s "$V" ] || { echo "codev: no verdict at $V"; exit 1; }
P="$S/runs/plan-revision.prompt.md"
{ printf 'THE PIPELINE HOUSE RULES (the charter below calls this root CLAUDE.md; its #2 is the reuse-first ladder):\n\n'; cat "$H/CLAUDE.md"
  printf '\n\n'; cat "$H/prompts/doer.md"
  printf '\n\n'; cat "$H/checklists/ponytail.md"
  printf '\n\nTHE BRIEF:\n\n'; cat "$S/brief.md"
  printf '\n\nYOUR CURRENT PLAN:\n\n'; cat "$S/plan.md"
  printf '\n\nTHE REVIEWER VERDICT:\n\n'; cat "$V"
  cat <<EOF

You are GPT Codex, the doer for the PLAN step of $SLUG, revising your own plan after review. Your working directory is the code repo, at the commit the brief was researched against. Fix ONLY the Must Fix items in the verdict, checking each against the code; change nothing else, and do not act on Should Consider items. If a Must Fix is wrong, keep the plan as it is on that point and say why, with evidence, in one line under a heading REVIEWER DISAGREEMENTS at the end of the plan. Do not open or quote any .env file. You are read-only and must NEVER edit any file. Your FINAL message must be the complete revised plan in Markdown and nothing else.
EOF
} > "$P"
cd "$WT" && codex exec --sandbox read-only -o "$S/plan.new.md" - < "$P" > "$S/runs/plan-revision.log" 2>&1
if [ -s "$S/plan.new.md" ]; then
  mv "$S/plan.md" "$S/plan.prev.md" && mv "$S/plan.new.md" "$S/plan.md" && echo "revised plan written; the scored one is plan.prev.md"
else
  rm -f "$S/plan.new.md"; echo "codev: codex returned no revision - see $S/runs/plan-revision.log"; exit 1
fi
```

`plan.prev.md` keeps the version the last review scored, so the next reviewer can see exactly what
changed.

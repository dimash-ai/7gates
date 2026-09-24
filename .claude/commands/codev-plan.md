---
description: "Co-dev 2 (plan): GPT plans from the brief, a blind Opus reviews"
argument-hint: <slug> [repo-path]
---

# Co-dev · 2 — plan  ·  GPT does · Opus reviews

The second step of the **3-step co-dev flow** (`harness/README-codev.md`): **GPT writes the complete
plan for `$1` from the brief**, and a blind Opus scores it. No code is written until the score
clears 9.0.

`$1` is the slug from step 1; `$2` is the code repo, optional. Every bash block sources
`harness/bin/codev-env.sh`, which prints `codev: slug=… results=<S> worktree=<WT> …`; in the prose,
`<S>`, `<WT>` and `<H>` (the `harness/` directory) mean those literal paths.

GPT plans in `<WT>`, the tree step 1 pinned and researched, so the plan's citations are to the same
code the build will change. Every Codex run below goes **in the background** (Bash
`run_in_background`): a plan over a large repo outlasts the Bash tool's timeout. Its output goes to
files, and the block prints only whether it produced something.

## 0 — Where this round stands

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header && codev_need_worktree || exit 1
ls "$S/reviews" 2>/dev/null | grep '^plan-' || echo "no plan reviews yet: this is round 1"
```

No brief header or no worktree means step 1 is not finished. The listing tells you the round:
`plan-1.md` and `plan-2.md` present means the next review is round 3, the last.

## 1 — GPT plans, cold and read-only

**Doer = GPT (Codex).** It sees the brief and the repo, nothing of this conversation. It runs
**read-only**, and its final message is the plan.

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header && codev_need_worktree || exit 1
P="$S/runs/plan-codex.prompt.md"
{ printf 'THE PIPELINE HOUSE RULES (the charter below calls this root CLAUDE.md; its #2 is the reuse-first ladder):\n\n'; cat "$H/../CLAUDE.md"
  printf '\n\n'; cat "$H/prompts/doer.md"
  printf '\n\n'; cat "$H/checklists/ponytail.md"
  printf '\n\nTHE BRIEF:\n\n'; cat "$S/brief.md"
  printf '\n\nTHE PLAN TEMPLATE:\n\n'; cat "$H/design/TEMPLATE-3gate.md"
  cat <<EOF

You are GPT Codex, the doer for the PLAN step of $SLUG. Your working directory is the code repo, at the commit the brief was researched against. The brief above is your whole task, and nobody will answer questions during this run. The repo's own CLAUDE.md, AGENTS.md and the CLAUDE.md of the app the brief names are binding: read them. Then study the code until you can plan against what is actually there, and write the complete plan in the structure of the template: the problem and the decision, with the alternatives you rejected; assumptions marked confirmed or UNVERIFIED; scope; success criteria, where every acceptance criterion of the brief traces to a slice and to the test that proves it; the build as independently shippable slices, each with its files, its main failure mode and what its test proves; the new-surface table, where every new file, module, dependency or abstraction names the ladder rung it stopped at and why the earlier rungs did not hold; architecture and contracts; the happy AND unhappy flow; the test strategy, security and rollback. Close every open question in the brief, or carry it forward as an explicit UNVERIFIED assumption. Build on the brief's Decided list; do not reopen it. Cite every claim about existing code as file:line.
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
into the brief, and re-run this step. That is the brief failing, not the plan, and it costs one run
instead of a wrong plan.

## 2 — A blind Opus reviews

**Reviewer = Opus, fresh context.** Do **not** review inline: you shaped the request and watched the
brief being written. Spawn a clean-context reviewer with the **Agent tool** (`subagent_type:
"claude"`, `model: "opus"`), passing this prompt with the literal paths written in:

> You are Opus, the blind reviewer for the PLAN step of `$1`. GPT Codex wrote this plan; you did not,
> and you did not take part in the conversation behind the brief. Read, in this order:
> `<H>/prompts/reviewer.md` (your charter: follow its review rules and output its verdict format
> exactly), `<H>/../CLAUDE.md` (the pipeline house rules the charter calls root CLAUDE.md; its #2 is
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
  moment to change course). Next: `/codev-build $1`.
- **BLOCKED** (< 9.0) in round 1 or 2: list every Must Fix, run the revision below, and review again
  with a fresh subagent.
- **BLOCKED in round 3**: STOP. Three rounds that do not converge mean the brief is too broad or too
  vague, not that the plan needs a fourth pass. Go back to `/codev-brief` with the requester:
  sharpen the brief, or split the work into several slugs, each with its own branch.

**When the brief changes** (answers to QUESTIONS, a return from round 3, or a plan defect found
during the build), the round count restarts: move `<S>/reviews/plan-*.md` into
`<S>/reviews/archive-<date>/`, then run step 1 again from scratch.

## 3 — Revision (only on BLOCKED)

GPT revises its own plan against the latest verdict, fixing only the cited Must Fix items. Replace
`<N>` with the number of that verdict:

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header && codev_need_worktree || exit 1
V="$S/reviews/plan-<N>.md"; [ -s "$V" ] || { echo "codev: no verdict at $V"; exit 1; }
P="$S/runs/plan-revision.prompt.md"
{ printf 'THE PIPELINE HOUSE RULES (the charter below calls this root CLAUDE.md; its #2 is the reuse-first ladder):\n\n'; cat "$H/../CLAUDE.md"
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

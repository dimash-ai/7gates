# The 3-step co-dev flow

**Status: live, the default for our own work (since 2026-09-24).** It grew out of the
[2-gate flow](README-2gate.md): the same two cross-model gates, now preceded by a product brief
both models draft and a research phase both models run, with every result written into the code
repo's `specs/`. Tickets that run through the CTO's
feature-dev cycle keep the [GPT gates](README-gpt-gates.md).

## The three steps

| step | command | does | checks | result in `superapp/specs/<slug>/` |
|------|---------|------|--------|------------------------------------|
| 1 · brief | `/step1 <slug>` | Opus and GPT each draft the product brief from your request (the problem, who it is for, user stories, the business side); Opus merges them into `brief.md` | **you**: the brief is done when you say yes | `brief.md`, `product/` |
| 2 · plan  | `/step2 <slug>` | pins a worktree; Opus and GPT research the brief in it independently and Opus merges the findings into it; then GPT plans, cold, from the brief alone | **you** answer what the research asks; a blind Opus subagent scores the plan, ≥ 9.0, three rounds at most | `research/`, `plan.md`, `reviews/plan-N.md` |
| 3 · build | `/step3 <slug>` | Opus, one slice per run, in the same worktree | GPT per slice, then GPT runs the checks itself (release pass), ≥ 9.0 | code and a PR into `dev`; `reviews/build-N.md`, `reviews/release-N.md`, `handoff.md` |

The invariant is the pipeline's own: **no model grades its own work.** Opus scores GPT's plan; GPT
scores Opus's build. The two drafters in step 1 and the two researchers in step 2 are not graded at
all: independence there buys coverage, so each pair merges as a union, and the only judge of an
intent is the person who has it.

Why this shape:

- **The user's side first.** Step 1 states the problem and the business task before anyone reads
  the code: what we want to achieve, for whom, whether they are better off, and the user stories
  that say so, each criterion numbered. Both models draft it from the request alone, so where they
  read the request differently, the ambiguity reaches you as a question instead of reaching the plan
  as a guess. Step 2 researches those stories, and their criteria are the acceptance criteria the
  plan and the release pass are held to, so a change nobody benefits from is caught before it costs
  a sweep.
- **One tree for research, plan and build.** Step 2 creates the worktree from the remote tip of
  the base (`origin/dev`), or moves the session's own worktree there (below). Both sweeps read it,
  GPT plans against it, Opus builds in it, so the research, the plan's citations and the code
  describe the same commit, recorded as `Pinned:` in the brief.
- **GPT plans cold.** A plan that has to stand on the brief alone exposes a brief that does not
  stand, and that is why the brief exists: whatever the planner needs has to be written down.
- **Opus builds where the context lives**, ideally in the session that ran steps 1 and 2. The plan
  still governs, and every departure from it is recorded in the build log.
- **The release pass executes.** Everything upstream reads; GPT runs the checks itself, so for every
  check its sandbox can run, the approval rests on counts GPT observed, not on the builder's claim.

## Where the results go

Everything for one slug lives in one folder of the code repo's **main** checkout, or of the
session's own worktree (the last bullet below):

```
superapp/specs/<slug>/          gitignored: stays on this machine
  brief.md                      1-2 · the one document: product part (step 1), research part (step 2)
  product/request.md            1 · the request both drafters got, verbatim
  product/opus.md, codex.md     1 · the two product drafts, never pasted into the brief
  research/opus.md, codex.md    2 · the raw sweeps, never pasted into the brief
  plan.md, plan.prev.md         2 · GPT's plan, and the version the last review scored
  reviews/plan-N.md             2 · Opus verdicts (older rounds move to reviews/archive-<date>/)
  reviews/build-N.md            3 · GPT verdicts, per slice and per re-review
  reviews/release-N.md          3 · the release pass, per run
  runs/                         the build log (build.txt), every Codex prompt as sent, every Codex log
  handoff.md                    3 · the PR body
```

- `<slug>` is the Linear id when there is an issue (`ALL-646`), otherwise a short name. Every slug
  has a branch of its own: a brief split in two means two slugs and two branches.
- One folder per slug, because the feature-dev flow writes into the same `specs/` (`ALL-<id>.md`
  and one shared `DevelopmentPlan.md`) and loose files would collide.
- Always the main checkout. [`bin/codev-env.sh`](bin/codev-env.sh), which every command block
  sources, resolves it through `git rev-parse --git-common-dir`, so a command run inside a worktree
  still writes here, and removing a worktree (which deletes its gitignored files) cannot take the
  results with it.
- Nothing here is committed. What should outlive the ticket, a research dossier say, is copied by
  hand into the repo's `docs/`, the way the native-mobile research reached `docs/research/`.
- The charters, rubric and templates stay in this repo's `harness/`; only results move.
- **A session that runs in a worktree of its own** (`.claude/worktrees/<name>`: the Claude desktop
  app's default, its composer's "worktree" box) is the exception. The app lets such a session write
  only inside that worktree, so `codev-env.sh` keeps the results in it (`<worktree>/specs/<slug>/`)
  and uses the worktree itself as the flow's tree: step 2 moves it onto the brief's branch instead
  of adding `.worktrees/<slug>`. The flow then belongs to that session: run all three steps in it
  (a step run from another session names the checkout that holds the brief). The results go when
  the app removes the worktree, so copy out what must outlive the session. Unticking the box runs
  the session in the main checkout, and the rules above apply unchanged.

## Ponytail

[ponytail](https://github.com/DietrichGebert/ponytail) runs through all three steps from one pinned
file, [`checklists/ponytail.md`](checklists/ponytail.md) (v4.10.0), which every step reads:

- **Brief.** A brief in which nobody is better off is rung 1: does this need to exist at all?
- **Research.** Both sweeps record prior art by rung number (2 this codebase, 3 the standard
  library, 4 the platform, 5 an installed dependency). Prior art that already covers the whole
  intent becomes a question for you: "X already does this. Still build?"
- **Plan.** Every new file, module, dependency or abstraction names the rung it stopped at, in the
  plan template's `New surface` table, and the Opus reviewer checks it.
- **Build.** Opus climbs the ladder before each slice. GPT's slice review and release pass carry the
  over-engineering tags (`delete` / `stdlib` / `native` / `yagni` / `shrink`, then a `net:` line)
  as Should Consider unless the rubric makes one a Must Fix. The release pass lists the `ponytail:`
  markers the change adds; they become the PR's known follow-ups.

The file also says what is **not** over-engineering in superapp: the exoskeleton and LDD where the
AI-track rule requires them, i18n, the repo's test stack, migrations, repo-mandated structure. It
widens the carve-out the CTO's RUNBOOK gives `/ponytail-review` at T4, which covers the exoskeleton
and LDD. The difference from T4 is also who applies the lens: there, a Claude review reads a Claude
build; here the reviewer is the other vendor, and the lens rides in the review call GPT makes
anyway, so it costs no extra pass.

**Keep the ponytail plugin off while the flow runs.** The gates never need it. Installed and on, its
hooks inject the *live* ruleset into your Claude session, into every Claude subagent (the blind plan
reviewer included) and, once its hooks are trusted, into Codex, which defeats the pin; and its test
rule ("one runnable check, no frameworks, no fixtures") contradicts superapp's. Outside the flow it
is a fine everyday companion: in Claude Code `/plugin marketplace add DietrichGebert/ponytail`, then
`/plugin install ponytail@ponytail`; in Codex `codex plugin marketplace add DietrichGebert/ponytail`,
then `codex plugin add ponytail@ponytail`, then trust its hooks under `/hooks`. Start the sessions
that run the flow with `PONYTAIL_DEFAULT_MODE=off`. Moving the pinned file to a newer release is a
deliberate act: read the changelog, carry the change over, bump the pin.

## Running a feature

From `superapp`, one of its worktrees, or the harness itself (`superapp/harness`). In a session that
runs in a worktree of its own, run all three in that same session.

```
/step1 ALL-646     # brief: Opus and GPT draft the product brief; Opus merges; you approve brief.md
/step2 ALL-646     # plan:  worktree pinned; Opus and GPT sweep; GPT plans; a blind Opus scores it
/step3 ALL-646     # build: once per slice; the last run does the release pass and opens the PR
```

Every Codex call runs in the background: a draft, a sweep, a plan or a release pass outlasts the
Bash tool's timeout. Each prompt is written to `runs/` first and fed to `codex exec` on stdin, so a
large brief and plan never hit the command-line length limit, and what Codex was asked stays on
record.

Set up once:

- **Codex CLI**, logged in. Check that your version accepts
  `codex exec --config 'web_search="live"'`: steps 1 and 2 use it so GPT can look outside the repo
  too. If it does not, both still run, and external facts rest on Opus alone.
- **git ≥ 2.31** (for `rev-parse --path-format`), and **`gh`**, authenticated, for the PR.
- **The commands** live in this repo's `.claude/commands/`, and `~/.claude/commands` is a symlink to
  that directory, so Claude Code lists them as user commands in every project and a pull here
  updates them. The link serves whatever branch this checkout (`superapp/harness`) has: the three steps
  appear once this flow is on that branch (normally `main`) and vanish while a branch without them
  is checked out. Nothing else to install; start a new Claude Code session. Never link or copy a
  single command file into `~/.claude/commands`: through the directory link, `ln -sf` replaces the
  repo's file with a link to itself, and `rm` followed by `cp` deletes it. On a new machine, move
  any existing `~/.claude/commands` aside, then create the link once from `superapp/harness`:

  ```
  ln -s "$PWD/.claude/commands" ~/.claude/commands
  ```

  Claude Code reads commands from `~/.claude/commands/` and from the `.claude/commands/` of the
  project it has open, nowhere else. A link in `superapp/.claude/commands/` works too, but only when
  Claude Code is opened in superapp.

Abandoning a slug: remove its worktree with the last block of `/step3`, then delete its branch. In
a session with a worktree of its own, delete the session instead, then the branch.

## Where it stops

| where | stop | why |
|-------|------|-----|
| 1d | you answer the drafts' questions and confirm the brief, the depth, the branch and the base | the research and the plan aim at it, and its stories become the acceptance criteria; the branch and base pin the tree in step 2 |
| 2c | the research raised questions: you answer them before the plan; one that changes the In short sends the work back to step 1 | the brief is the planner's whole world; no contradiction may reach it |
| 2 | GPT returns QUESTIONS instead of a plan: back to the brief | a plan built around an ambiguity is wrong from its first line |
| 2 | the third review is still BLOCKED: back to the brief, sharpen or split | rounds that do not converge point at the task, not the plan |
| 2 | APPROVED: you skim the slice table | the last cheap moment to change course |
| 3 | no APPROVED plan verdict: the build refuses to start | a plan nobody approved is not a plan |
| 3 | the same slice BLOCKED twice after fixes: re-plan with `/step2` from 2d | findings that keep coming back are a plan defect |
| 3 | the release pass must leave the tree untouched; whatever it left is stashed, not deleted | a verdict made while editing the code is not a review |
| ship | you merge; PM QA on `dev`; promotion to `main` per superapp's `CLAUDE.md` | agents open PRs and stop |

## What this flow does not give you

- **An independent test author.** Opus writes the tests; GPT judges them hard and re-runs them, but
  never writes one. Where a wrong test is as dangerous as wrong code (migrations, auth and tenant
  isolation, money), that is this flow's known gap: raise it with the requester before step 3.
- **A second run of the real-DB suites.** GPT's sandbox has no database and no network, so those
  suites skip there. Opus runs them against the migration sandbox in 3a and logs the output;
  the release pass lists them as UNVERIFIED IN SANDBOX, raises the Release Risk, and the PR says so.
  CI then runs them against its own Postgres.
- **A guard around `.env`.** If you copy a `.env` into the worktree to run the app, the release pass
  runs where it is. GPT is told never to open it; that is an instruction, not a sandbox rule. The
  checks do not need a `.env` (CI runs them without one), so keep it out when you can.
- **A wall between GPT and `<S>`.** In step 1 GPT drafts in the code repo itself, and in a session
  with a worktree of its own every step runs there, so `<S>` sits inside GPT's working directory: the
  drafter and the planner can read what is already in it, and the release pass's write sandbox
  reaches `specs/`, which `git status` does not show because it is gitignored. Steps 1 and 2 keep
  Opus's draft and sweep out of `<S>` until GPT's run exits; the rest is an instruction, not a
  sandbox rule.
- **The feature-dev machinery**: spec normalization, the qa scans, three Claude review lenses with
  Triage, automatic Linear moves. What carries over are the superapp checks in the plan review and
  the release pass. On tickets that touch auth, tokens or RLS, run `/security-review` on the
  worktree before the release pass.

## Beside the other flows

- [`/gate-explore`](.claude/commands/gate-explore.md): standalone reconnaissance for an epic;
  step 2 runs the same kind of sweep for one task.
- [GPT gates](README-gpt-gates.md): for tickets that run through the CTO's feature-dev cycle.
- [2-gate](README-2gate.md): the record of the design this flow grew from; its two commands were
  rewritten here.
- [3-gate](README-3gate.md) and [7-step](README-7step.md): superseded; their commands were removed
  on 2026-09-24, and the READMEs stay as the record.

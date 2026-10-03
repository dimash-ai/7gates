# The co-dev flow — ship in stages

**Status: live, the default for our own work.** Three steps: a short brief with the MVP, a plan of
**stages**, and a build that ships **one stage at a time to dev**, each as its own PR, merged,
deployed and looked at on the dev environment before the next one starts. A weekly `/learn` checks
every shipped bet against what users did. Tickets that run through the CTO's feature-dev cycle keep
the [GPT gates](README-gpt-gates.md).

**Since 2026-10-03.** The flow used to plan a whole feature, build it slice by slice behind a
per-slice review, and open one PR at the end. On a three-day kanban ticket that meant the first
commit after about 45 hours, the first deploy to dev after about 53 (plumbing only), and none of
the screens the ticket asked for on dev before it was handed off; 20 review Must Fix items, none of
which would have blocked a dev deploy of an MVP; and about 40 requests for a progress bar. The
rules that came out of it live in [`checklists/mvp.md`](checklists/mvp.md), which every step reads.

## The three steps

| step | command | does | checks | result in `superapp/specs/<slug>/` |
|------|---------|------|--------|------------------------------------|
| 1 · brief | `/step1 <slug>` | Opus rephrases your input (your words or a Linear ticket) into a short brief for step 2: the problem, the user stories, **the MVP**, Not now; about ten minutes, no second model, no code | **you** confirm the brief | `brief.md` |
| 2 · plan  | `/step2 <slug>` | pins a worktree on stage 1's branch; GPT plans cold from the brief and the code: the **stage map** (outcome on dev, demo, budget, risk, guard) and **every stage's detail** | a blind Opus, against the MVP lens, ship-blockers only, two rounds at most; then **you** confirm the stages and how stages ship | `plan.md`, `reviews/plan-N.md`, `progress.md` |
| 3 · build | `/step3 <slug>`, once per stage | **pure implementation** of the next stage, no layers inside; its own PR into `dev`, merged, deployed, its demo walked on dev; registers the bet when the signal is measurable | your checks and CI; **GPT** once for a data or auth stage, and once as the release pass before main | one PR per stage into `dev`; `runs/build-sN.txt`, `reviews/stage-N-K.md`, `reviews/release-*.md`; a PR into `main` per release |
| learn · weekly | `/learn` | measures every registered hypothesis and the demand board in PostHog; Opus and GPT judge independently | **you** confirm the verdicts before anything is written back | `specs/learn-<date>/`; verdicts in the PostHog notebooks |

The invariant is the pipeline's own: **no model grades its own work.** Opus scores GPT's plan; GPT
reviews what Opus built wherever a second model changes the outcome. Step 1 is not graded: the only
judge of an intent is the person who has it, and GPT's independent reading comes in step 2, where it
plans cold from the brief, so a brief that does not stand on its own comes back as questions.

## Why this shape

- **The stage is the unit of delivery.** A stage is the smallest increment a user can see on dev,
  at most about four hours of build. It is done when it is merged, deployed and its demo script
  passed on the dev environment, not when it is coded or approved. Stage 1, the MVP, aims to be on
  dev within a working day of the plan's yes, and value then arrives every few hours.
- **The MVP is named at the start, not discovered at the end.** Step 1 rephrases the request in
  minutes and takes the MVP from its literal words; what a design shows beyond them waits for a later
  stage. Questions are few, one decision each, smallest option first with its cost, and a safe
  default is assumed rather than waited for.
- **Planning happens in step 2, all of it.** The plan details every stage, so step 3 implements and
  nothing else: no design phase, no builder waves, no internal pre-reviews or fix workflows, even
  with ultracode on. When dev shows the map was wrong, `/step2` re-plans the stages not yet started.
- **Reviews where they change the outcome.** A blind Opus reviews the plan, the cheapest place to
  cut. A low-risk stage reaches dev on Opus's checks and CI. A stage that touches data or access gets
  one GPT review before it merges, and GPT runs the checks itself. Before anything reaches
  production, one GPT release pass reviews every stage being promoted. Every review blocks only on
  ship-blockers (a regression, data, security, a demo that fails, CI or a repo rule, unfinished work
  outside its guard); everything else is a follow-up you decide on.
- **Safe on a shared dev.** PM and QA use dev. Every stage names its guard (additive only, a hidden
  route, a dev-only flag) until the stage that switches users over, and migrations stay additive.
- **Progress means stages on dev.** `progress.md` counts stages verified on dev, not pipeline steps,
  and every step prints it. Each stage PR's body carries it, so GitHub keeps the record.
- **A bet, then a check.** Every change states its hypothesis in step 1; step 3 registers it in
  PostHog once its signal is measurable on dev; `/learn` judges it weekly after the release to main.

## Where the results go

Everything for one slug lives in one folder of the code repo's **main** checkout, or of the
session's own worktree (the last bullet below):

```
superapp/specs/<slug>/          gitignored: stays on this machine
  brief.md                      1 · the request rephrased: problem, user stories, MVP, Not now, its words verbatim
  progress.md                   2-3 · the progress board: one row per stage, printed by every step
  plan.md, plan.prev.md         2 · GPT's stage plan, and the version the last review scored
  reviews/plan-N.md             2 · Opus verdicts
  reviews/stage-N-K.md          3 · GPT's review of a data or auth stage N, round K
  reviews/release-main.md       3 · GPT's release pass before a promotion to main (release-main-2 …)
  runs/build-sN.txt             3 · stage N's build log: commands, real counts, deviations, hours
  runs/                         every Codex prompt as sent, every Codex log
  pr-sN.md, pr-main.md          3 · the PR bodies
superapp/specs/learn-<date>/    one /learn run: data.md (the numbers), verdict-opus.md, verdict-codex.md, runs/
```

- `<slug>` is the Linear id when there is an issue (`ALL-646`), otherwise a short name. The brief's
  `Branch:` is the base name of the stage branches, `<Branch>-s1`, `<Branch>-s2`, …, and of the
  promotion branch `<Branch>-main`. It carries **no Linear id**, and neither do the PR titles: Linear
  closes an issue when the last PR linked through its branch, title or a closing word merges. Stage
  PRs start their body with `Part of <id>`, which links without closing.
- One folder per slug, because the feature-dev flow writes into the same `specs/` (`ALL-<id>.md`
  and one shared `DevelopmentPlan.md`) and loose files would collide.
- Always the main checkout. [`bin/codev-env.sh`](bin/codev-env.sh), which every command block
  sources, resolves it through `git rev-parse --git-common-dir`, so a command run inside a worktree
  still writes here, and removing a worktree (which deletes its gitignored files) cannot take the
  results with it.
- Nothing here is committed. What should outlive the ticket is copied by hand into the repo's
  `docs/`; the stage map and the board also live on in every stage PR's body.
- The charters, rubric and templates stay in this repo's `harness/`; only results move. The brief's
  `Harness:` line records the harness commit the slug started on: a slug finishes on the harness it
  started with.
- **A session that runs in a worktree of its own** (`.claude/worktrees/<name>`: the Claude desktop
  app's default, its composer's "worktree" box) is the exception. The app lets such a session write
  only inside that worktree, so `codev-env.sh` keeps the results in it (`<worktree>/specs/<slug>/`)
  and uses the worktree itself as the flow's tree: step 2 moves it onto stage 1's branch and step 3
  from stage branch to stage branch, instead of adding `.worktrees/<slug>`. The flow then belongs to
  that session; the results go when the app removes the worktree, so copy out what must outlive it.
  Unticking the box runs the session in the main checkout, and the rules above apply unchanged.

## The MVP lens and ponytail

Two pinned files run through all three steps:

- [`checklists/mvp.md`](checklists/mvp.md): the stage rules, how to cut the MVP, how to ask
  questions, what a review may block on, how heavy the documents may be, the progress board, and how
  stage PRs reference Linear.
- [ponytail](https://github.com/DietrichGebert/ponytail)'s
  [`checklists/ponytail.md`](checklists/ponytail.md) (v4.10.0): the reuse-first ladder and the
  over-engineering tags. Step 1 names what already exists; the plan names the rung of every new
  surface, and a stage that builds far more than its outcome needs is a plan blocker; GPT's reviews
  carry the tags as follow-ups and list the `ponytail:` markers a release adds.

The ponytail file also says what is **not** over-engineering in superapp: the exoskeleton and LDD
where the AI-track rule requires them, i18n, the repo's test stack, migrations, repo-mandated
structure. **Keep the ponytail plugin off while the flow runs**: installed and on, its hooks inject
the live ruleset into your session, every Claude subagent and trusted Codex sessions, which defeats
the pin, and its test rule contradicts superapp's. Start the sessions that run the flow with
`PONYTAIL_DEFAULT_MODE=off`. Moving the pinned file to a newer release is a deliberate act: read the
changelog, carry the change over, bump the pin.

## Running a feature

From `superapp`, one of its worktrees, or the harness itself (`superapp/harness`). In a session that
runs in a worktree of its own, run all the steps in that same session.

```
/step1 ALL-646     # brief: your request rephrased for step 2, with the MVP; you confirm it
/step2 ALL-646     # plan:  GPT plans every stage; a blind Opus reviews; you confirm, and say how stages ship
/step3 ALL-646     # build: the next stage, its PR into dev, verified on dev; run it again for each stage
/step3 ALL-646     #        … and again; when you say so, it releases the stages to main (3g)
/learn             # weekly: checks every shipped bet in PostHog; a scheduled task runs it every Monday
```

Every Codex call runs in the background: a plan or a review outlasts the Bash tool's timeout. Each prompt is written to `runs/` first and fed to `codex exec` on stdin, so what Codex
was asked stays on record.

**The pace to expect.** Step 1 about ten minutes plus your yes; step 2 about an hour; each stage up to about four hours of build plus about half an hour of fixed cost (CI, deploy,
the look on dev). Your answers are the other clock: the flow asks few questions, assumes safe
defaults, and stops only where it needs you.

Set up once:

- **Codex CLI**, logged in: GPT plans in step 2 and reviews in step 3.
- **git ≥ 2.31** (for `rev-parse --path-format`), and **`gh`**, authenticated, for the PRs.
- **The commands** live in this repo's `.claude/commands/`, and `~/.claude/commands` is a symlink to
  that directory, so Claude Code lists them as user commands in every project and a pull here
  updates them. The link serves whatever branch this checkout (`superapp/harness`) has. Never link
  or copy a single command file into `~/.claude/commands`: through the directory link, `ln -sf`
  replaces the repo's file with a link to itself, and `rm` followed by `cp` deletes it. On a new
  machine, move any existing `~/.claude/commands` aside, then create the link once from
  `superapp/harness`:

  ```
  ln -s "$PWD/.claude/commands" ~/.claude/commands
  ```

Abandoning a slug: close its open stage PR, remove its worktree with the last block of `/step3`, and
delete its branches. In a session with a worktree of its own, delete the session instead.

## Where it stops

| where | stop | why |
|-------|------|-----|
| 1c | you confirm the brief: the MVP, the stories, Not now, the assumed answers, the branch and the base | the planner works from the brief alone |
| 2b | GPT returns QUESTIONS that change stage 1 | a stage 1 built around an ambiguity is wrong from its first line; a later stage's ambiguity is planned as an assumption instead |
| 2c | the plan is BLOCKED a second time: you decide each open Must Fix | two rounds that do not converge mean the stage is cut wrong |
| 2e | you confirm the stages, and whether stages ship on your word (`Ship: ask`) or on their own (`Ship: auto`) | the last cheap moment to change course |
| 3a | the plan does not detail the stage, or dev showed it is wrong: back to `/step2` | step 3 implements; it does not design |
| 3a/3b | a stage passes one and a half times its budget: you choose what ships and what moves on | the timebox is what keeps value arriving every few hours |
| 3c | a data or auth stage is BLOCKED a second time: you choose fix, hide behind the guard, or cut | a finding that keeps coming back is a cutting problem |
| 3d | `Ship: ask`: you look at the stage and say "ship" before its PR opens and merges | you see what goes to the shared dev environment |
| 3e | a step of the demo writes to shared dev data: you say yes first | dev is shared with PM and QA |
| 3g | you decide when stages go to main, and the release pass must approve | production is your call; the release is reviewed as a whole |

## What this flow does not give you

- **An independent test author.** Opus writes the tests. GPT re-runs them on data and auth stages
  and on the release to main, but never writes one. Where a wrong test is as dangerous as wrong code
  (migrations, auth and tenant isolation, money), those stages are exactly the ones GPT reviews;
  raise anything more with the requester before the stage.
- **A cross-model review of every stage.** A low-risk stage reaches dev on Opus's checks, CI and the
  look on dev; GPT sees it first in the release pass before main. That is deliberate: dev is the
  place where such a stage is checked by being used.
- **A second run of the real-DB suites.** GPT's sandbox has no database and no network, so those
  suites skip there. Opus runs them against the migration sandbox and logs the output; GPT's review
  lists them as UNVERIFIED IN SANDBOX and raises the Release Risk. CI then runs them against its own
  Postgres.
- **A guard around `.env`.** If you copy a `.env` into the worktree to run the app, GPT's reviews run
  where it is. GPT is told never to open it; that is an instruction, not a sandbox rule. The checks
  do not need a `.env`, so keep it out when you can.
- **A wall between GPT and `<S>`.** In a session with a worktree of its own every step runs there,
  so `<S>` sits inside GPT's working directory and the write sandbox of its reviews reaches `specs/`,
  which `git status` does not show because it is gitignored. That is an instruction, not a sandbox
  rule.
- **The feature-dev machinery**: spec normalization, the qa scans, three Claude review lenses with
  Triage, automatic Linear moves. On stages that touch auth, tokens or RLS, also run
  `/security-review` on the stage branch before its GPT review.

## Beside the other flows

- [`/gate-explore`](.claude/commands/gate-explore.md): standalone reconnaissance for an epic with
  large unknowns, before step 1.
- [GPT gates](README-gpt-gates.md): for tickets that run through the CTO's feature-dev cycle.
- [2-gate](README-2gate.md), [3-gate](README-3gate.md) and [7-step](README-7step.md): superseded;
  their READMEs stay as the record.

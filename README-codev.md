# The co-dev flow — ship in stages

**Status: live, the default for our own work.** A short brief with the MVP, **a design you confirm
locally before any code**, a plan of **stages**, and a build that ships **one stage at a time to
dev**, each as its own PR, merged and deployed on the dev environment. A weekly `/learn` checks
every shipped bet against what users did. Tickets that run through the CTO's feature-dev cycle keep
the [GPT gates](README-gpt-gates.md).

**Since 2026-10-03.** The flow used to plan a whole feature, build it slice by slice behind a
per-slice review, and open one PR at the end. On a three-day kanban ticket that meant the first
commit after about 45 hours, the first deploy to dev after about 53 (plumbing only), and none of
the screens the ticket asked for on dev before it was handed off; 20 review Must Fix items, none of
which would have blocked a dev deploy of an MVP; and about 40 requests for a progress bar. The
rules that came out of it live in [`checklists/mvp.md`](checklists/mvp.md), which every step reads.

**Since 2026-10-05.** A measurement of the last seven runs showed where the time went. In the flow
before stages, 56% of the wall-clock was waiting on the requester; in the stage flow, a 41-line
change took 87 minutes, 17 of them in hand-offs between the steps and 9 in a release pass that
found nothing. Of 141 BLOCKED verdicts scored 8.0–8.9, about 16 held a real ship-blocker, and since
2026-09-25 the re-reviews that cleared the rest cost about 275 minutes. The 9.0 threshold stays;
what changed is what follows a verdict, and where the waits were. The steps now chain on their own
around one stop before code; a small, low-risk change takes a quick lane without GPT; a BLOCK is
fixed and goes on with CI as its proof; and GPT reviews in parallel with CI, only where data or
auth is at stake.

**Since 2026-10-06.** The session logs of four runs, checked against GitHub, showed that about 78%
of their wall-clock was the flow waiting for the requester at a gate: a "ship", a merge after green
CI, a permission for a demo on dev. GPT took about 2.5%, CI and deploys under 2%, and local checks
and tests one or two minutes a stage. The requester's answer: **local is for looking, dev is for
checking** ([`checklists/mvp.md`](checklists/mvp.md) §10), refined the same evening to **test by hand
first, check right before the push**. Nothing is checked while a stage is built; the requester tests
stage 1 end to end on a local URL; the local CI pass (static checks, affected tests) runs once, right
before the push; every later stage goes from that pass to dev on green CI without a stop, merged by
the builder without asking; and PM, not the builder, walks the demo on dev.

**Since 2026-10-09.** The session logs since 2026-10-03, checked against GitHub, showed the flow
still waiting on the requester between stages: about a third of their messages (83 of 241) only
moved it on («merge», «да, открывай PR в dev», «да, включи auto-fix», «продолжай, мержи когда CI
green»), and a green stage PR waited a median of about 6 minutes more for that word, on a CI round
of about 8. Their answer: «не жди меня, открывай PR и делай merge into dev if CI is green». The
builder now pushes, opens the PR, turns on its Auto-fix and merges it into dev on green CI without
asking, and builds the next stage on the stage before it while that one's CI runs, so a turn no
longer ends on a running CI ([`checklists/mvp.md`](checklists/mvp.md) §2, §10). Only stage 1's test
by hand and the release to main still wait for the requester.

**Since 2026-10-09, design first.** The same day the requester put a design between the brief and
the code: a task comes in, we work out what to do, Opus draws it fast as a hi-fi HTML prototype,
the requester looks at it on their own machine, and **only their ok starts development**
([`checklists/mvp.md`](checklists/mvp.md) §11). That ok is the one stop before code; after it
nothing waits for them until the release to main, so the stage plan is a report and stage 1 has no
hand test. ALL-800 is why: twelve stages reached dev before the requester saw them, and their look
(«в дизайне у нас есть исполнители, а на деве я этого не вижу») turned into three follow-up tracks.
A task with nothing users see skips the design and keeps step 2's stop and stage 1's hand test.

**Since 2026-10-14, Opus plans and GPT reviews.** Twelve stage plans since 2026-10-03 showed the old
split, GPT planning cold and Opus checking inline, working against itself. The check passed eleven
of them on the first round, and it was the one review in the flow that was not blind: Opus had
written the brief and the design. GPT never sees the session's record of known traps, and twice
planned around the same one (a service that does not run under RLS, planned as if it did); and the
builder re-decided much of each plan at build time anyway. Now the builder plans, with everything
the session knows, and GPT reviews the plan blind. It cuts stage 1 itself before it reads the plan,
so its cold reading of the brief, which twice caught a stage 1 too big for one stage, still happens.
The same day, the merge into dev and the release branch started checking the Alembic chains (a
fork of two migrations had failed every Focal pre-deploy on 2026-10-09), step 3 traded `git stash`
for a WIP commit and a patch file (every worktree shares one stash stack), and `/learn` started
recording a release at once instead of after the requester's yes, which had not come for a week.

## The steps

| step | command | does | checks | result in `superapp/specs/<slug>/` |
|------|---------|------|--------|------------------------------------|
| 1 · brief | `/step1 <slug>` | Opus rephrases your input (your words or a Linear ticket) into a short brief: the problem, the user stories, **the MVP**, Not now, and `Design:` html, handoff or none; about ten minutes, no second model, no code | no stop unless it must ask; **you** see the brief with the design (or, with nothing to draw, with the plan) | `brief.md` |
| design | starts by itself after step 1; `/design <slug>` redraws | Opus draws a **hi-fi HTML prototype** of the MVP's screens and states (the later ones badged), on the product's tokens, and opens it in your browser; a PM handoff is shown instead of drawn; skipped when nothing users see changes | **you**: the one stop before code; ok, or what to change, until ok; your ok starts step 2 | `design/index.html`, `design/README.md`, `reviews/design-N.md` |
| 2 · plan  | starts by itself after your ok; `/step2 <slug>` re-plans | pins a worktree on stage 1's branch; Opus plans from the brief, **the confirmed design** and the code: the **stage map** (outcome on dev, demo, budget, risk, guard) and **every stage's detail** | **GPT** reviews it blind (~10 min, in the background): it cuts stage 1 itself first, then blocks only on ship-blockers; Opus fixes a BLOCK and goes on, and a data or security fix gets one re-review; no GPT in the quick lane; then a report and step 3 at once (with nothing to draw: **you** confirm the brief and the stages in one stop) | `plan.md`, `reviews/plan-N.md`, `progress.md` |
| 3 · build | starts by itself after step 2; `/step3 <slug>` resumes | **pure implementation** of the next stage, and of the design as drawn, no layers inside and no checks while building; the local CI pass runs once, right before the push; PR, Auto-fix and merge into dev on green CI without asking, the next stage built while CI runs; demo for PM on dev; registers the bet when the signal is measurable | the local CI pass and CI; with nothing to draw, your test of stage 1; **GPT** once for a data or auth stage, on its open PR while CI runs, and once as the release pass when a release carries one; a BLOCK is fixed and goes on | one PR per stage into `dev`; `runs/build-sN.txt`, `reviews/stage-N-K.md`, `reviews/release-*.md`; a PR into `main` per release |
| learn · weekly | `/learn` | measures every registered hypothesis and the demand board in PostHog; Opus and GPT judge independently | **you** confirm the verdicts before anything is written back | `specs/learn-<date>/`; verdicts in the PostHog notebooks |

The invariant is the pipeline's own: **no model grades its own work.** GPT reviews Opus's plan, and
what Opus built wherever a second model changes the outcome. Step 1 is not graded: the only judge of
an intent is the person who has it, and GPT's independent reading comes in step 2, where it reviews
the plan cold, without the conversation, so a brief that does not stand on its own comes back as
questions.

## Why this shape

- **The stage is the unit of delivery.** A stage is the smallest increment a user can see on dev,
  at most about four hours of build. It is done when it is merged, deployed and served by the dev
  host, with its demo script in the PR for PM, not when it is coded or approved. Stage 1, the MVP, aims to be on
  dev within a working day of the plan's yes, and value then arrives every few hours.
- **The MVP is named at the start, and seen before it is built.** Step 1 rephrases the request in
  minutes and names the MVP; the design draws it, with what comes later badged, and the requester's
  ok on the drawing fixes the scope before any code. Stage 1 builds the MVP states, but its data takes
  the shape of the whole design. Questions are few, one decision each, smallest option first with its
  cost, and a safe default is assumed rather than waited for.
- **Planning happens in step 2, all of it.** The plan details every stage, so step 3 implements and
  nothing else: no design phase, no builder waves, no internal pre-reviews or fix workflows, even
  with ultracode on. When dev shows the map was wrong, `/step2` re-plans the stages not yet started.
- **Reviews where they change the outcome.** GPT reviews Opus's plan blind, in minutes, before any
  code: the plan is the cheapest place to cut, and GPT cuts stage 1 itself before it reads the plan,
  so a plan that builds too much shows against that cut. A low-risk stage reaches dev on the local
  CI pass and CI (stage 1 after your test by hand). A stage that touches data or access gets one GPT
  review on its open PR, while CI runs; a release to main that carries such a stage gets one GPT
  release pass the same way, and a release of low-risk stages goes on CI and your merge. CI runs the
  checks, so GPT does not repeat them: it looks for what CI cannot see. Every review blocks only on
  ship-blockers (a regression, data, security, a demo that fails, CI or a repo rule, unfinished work
  outside its guard); everything else is a follow-up you decide on. A BLOCK is fixed and goes on
  with CI as its proof; only a security or data finding gets its fix reviewed again.
- **Two lanes.** A request that is one low-risk stage of about two hours takes the quick lane: Opus
  plans it, and no GPT review runs. Everything else takes the stages lane
  ([`checklists/mvp.md`](checklists/mvp.md) §9).
- **One stop before code.** Step 1 goes straight on into step 2 unless it must ask; you see the
  brief and the plan together at step 2's stop, your yes starts step 3, and each stage on dev
  starts the next. The one other wait is your test of stage 1 by hand, on a local URL. Nobody waits for a command to be typed.
- **Safe on a shared dev.** PM and QA use dev. Every stage names its guard (additive only, a hidden
  route, a dev-only flag) until the stage that switches users over, and migrations stay additive.
- **Progress means stages on dev.** `progress.md` counts stages on dev, not pipeline steps,
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
  plan.md, plan.prev.md         2 · Opus's stage plan, and the version before the last re-plan
  reviews/plan-N.md             2 · GPT's verdicts and fix records; quick lane: the requester's yes
  reviews/stage-N-K.md          3 · GPT's review of a data or auth stage N, round K
  reviews/release-main.md       3 · GPT's release pass, when the promotion carries a data or auth stage
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
/step1 ALL-646     # brief: your request rephrased, with the MVP; goes straight on unless it must ask
                   # design: a hi-fi HTML prototype opens in your browser; ONE stop: ok, or what to
                   #        change (a task with nothing users see skips it and stops at the plan)
                   # plan:  Opus plans every stage against the design, GPT reviews the plan blind
                   # build: stages go to dev on green CI, PR and merge without asking, PM tests there
/design ALL-646    # redraw the design (a change after the ok re-plans the stages not yet started)
/step3 ALL-646     # resume a run; when you say so, it releases the stages to main (3g)
/learn             # weekly: checks every shipped bet in PostHog; a scheduled task runs it every Monday
```

Every Codex call runs in the background: a plan or a review outlasts the Bash tool's timeout. Each prompt is written to `runs/` first and fed to `codex exec` on stdin, so what Codex
was asked stays on record. Every call passes `--enable fast_mode -c service_tier="priority"`, Codex's Fast mode (about twice
the speed, more usage), so the pace does not depend on `~/.codex/config.toml`, which the Codex desktop
app rewrites.

**The pace to expect.** Step 1 about ten minutes; the design about half an hour to your first look
and about ten minutes a correction round; step 2 about half an hour (about ten minutes in the quick
lane); each stage up to about four hours of build plus the local CI pass, with CI (about eight
minutes a round) and the deploy running while the next stage is built. Your answers are the other
clock: after your ok on the design, nothing waits for you until the release to main.

Set up once:

- **Codex CLI**, logged in: GPT reviews the plan in step 2, and data and auth stages in step 3.
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
| 1c | a question that changes the MVP and has no safe default; with none, no stop | everything else is assumed and shown with the design (or at 2e) |
| D3 | **the one stop before code**: the prototype is open in your browser; you say ok, or what to change, until ok | the cheapest moment to see what users will get, before any code exists |
| 2c | GPT's review returns QUESTIONS that change stage 1 | a stage 1 built around an ambiguity is wrong from its first line; a later stage's ambiguity is a follow-up instead |
| 2d | a data or security fix whose re-review blocks again, or a Must Fix Opus believes is wrong: you decide each open item | a plan that does not converge in one fix round is cut wrong, and neither model overrules the other |
| 2e | only with nothing to draw: the one stop before code, you confirm the brief and the stages (say so if you want to look at every stage locally: `Ship: every`); after a design, a report | the last cheap moment to change course |
| 3a | the plan does not detail the stage, or dev showed it is wrong: back to `/step2` | step 3 implements; it does not design |
| 3a/3b | a stage passes one and a half times its budget, or a quick stage needs more than its lane allows: you choose what ships and what moves on | the timebox is what keeps value arriving every few hours |
| 3b | only with nothing to draw (`Ship: stage1`): stage 1 is up on a local URL, you test it end to end and say ok, or what to change; then the checks run and its PR opens | the MVP is what you judge; after a design you judged it before the code |
| 3d | a fix that leaves CI red, or a security or data fix whose re-review blocks again: you choose fix, hide behind the guard, or cut; a review with no verdict in twenty minutes: re-run it or merge on CI | a finding that keeps coming back is a cutting problem |
| 3g | you decide when stages go to main; a release that carries a data or auth stage waits for its release pass | production is your call |

## What this flow does not give you

- **An independent test author.** Opus writes the tests. GPT reads them on data and auth stages
  and on a release that carries one, and runs one only to reproduce a finding; it never writes one.
  Where a wrong test is as dangerous as wrong code (migrations, auth and tenant isolation, money),
  those stages are exactly the ones GPT reviews; raise anything more with the requester before the
  stage.
- **A cross-model review of every stage.** A low-risk stage reaches dev on CI and is looked at there
  by PM; GPT sees it only in a release that carries a data or auth stage, and in the quick lane
  no second model sees the change at all. That is deliberate: dev is the
  place where such a stage is checked by being used.
- **A second run of the suites.** GPT does not re-run them. Opus runs the static checks and the
  affected tests once, right before the push (the real-DB ones against the migration sandbox), and
  CI runs every suite on the PR, the real-DB ones against its own Postgres.
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

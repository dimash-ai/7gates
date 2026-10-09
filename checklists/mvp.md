# MVP lens — stages that ship

The delivery rules of the co-dev flow. Every step reads this file, the way it reads
[`ponytail.md`](ponytail.md): step 1 names the MVP, the design step draws it for the requester's ok,
step 2 plans it as stages, step 3 implements and ships one stage at a time. Ponytail asks "does this code need to exist?"; this file asks "does it
need to exist **before users can see something**?"

**Why it exists.** In October 2026 a feature ran through the earlier version of this flow for three
days. One plan put every requirement into one release; the first commit came about 45 hours after
the start, the first deploy to dev about 53 hours after it and held only plumbing, and the screens
the ticket asked for never reached dev before the work was handed off, after some 21k lines of code
and 45k lines of tests. The requester asked for a progress bar about forty times. The flow had no
point at which value reached a user before the very end; every rule below closes one of the holes
that let that happen.

## 1 · The unit of delivery is a stage

A **stage** is the smallest increment a user can see on dev. It is **done** only when all four hold:

1. its PR into `dev` is merged;
2. the deploy succeeded, on every service the change touches, and the dev host serves the new
   build;
3. its **demo script** is in the PR for PM, who walks it on dev (§10); stage 1 was also tested by
   hand, locally, by the requester before its PR opened;
4. the progress board (§7) says so.

Code on a branch, an approved review or a green CI is not a delivered stage. A stage is
**verified** once PM or the requester has walked its demo on dev and said so; the next stage does
not wait for that.

## 2 · Stage rules

- **Stage 1 is the MVP**: the least a user must see to say "this is it", working on dev. Target: on
  dev within one working day of the plan's yes.
- **Every stage is user-visible.** A foundation-only stage (a migration, an endpoint nobody calls
  yet) is allowed only when it fits in about two hours and the very next stage uses it. Better: fold
  the foundation into the first visible stage that needs it, so nothing is built ahead of its use.
- **Budget: at most about four hours of build per stage.** A stage that cannot fit is two stages.
- **Over budget by half, stop.** Tell the requester, then re-cut: ship what works behind the stage's
  guard and move the rest to the next stage. Never keep polishing silently.
- **Safe on dev.** `dev` is shared with PM and QA and is the pre-prod surface. Every stage names its
  **guard**: additive only (nothing users have today changes), a hidden route, or a dev-only flag,
  until the stage that switches users over. Migrations are additive (expand → migrate → contract).
- **One stage at a time, without waiting between them.** Stage N+1 is built while stage N's PR waits
  for CI, on N's branch (stacked), so CI time is build time (§10). Its PR opens only after N merged,
  rebased onto the fresh `origin/<base>`, so every PR into dev carries one stage and nothing else;
  a stage N that CI or its review sends back is fixed first. Parallel stages only on disjoint files
  and on the requester's ask. Parallel work multiplies code, not delivered value.
- **The map is alive.** After every stage the requester may re-order, cut or add stages. A change
  re-plans only the stages not yet started (step 2 again); nothing that shipped is redone.
- **A deadline decides the cut.** When the ticket has a target date (a Linear milestone, a promise),
  the stage map shows which stages land before it.

## 3 · Naming the MVP

- **Start from the ticket's words, then draw them** (step 1, then the design step, §11). The brief
  names the MVP from what the ticket asks; the design draws the MVP and the [later] stories on the
  same screens, the MVP marked; and the drawing the requester confirms is the scope: its MVP states
  are stage 1, its Later states later stages. A PM handoff, when there is one, is the design.
- **The MVP is the least a user must see to say "this is it"**, and step 2's stage 1 delivers it. If
  something smaller still serves the request, the planner says so.
- **Stage 1's data takes the shape of the whole design.** Stage 1 builds only its own states, but
  its schema and API take the shape the confirmed design needs, so that a later stage adds to them
  instead of rewriting them. ALL-800 gave every item one assignee in four stages, then rebuilt it
  for several, which the design had shown from the start.
- **Reuse before build** (step 2). What already exists and covers part of the ask (an editor, a
  screen, an endpoint) is the cheapest stage there is.
- **Not now is a list of follow-up tickets**, one line each, never a silent drop.
- **Fast, then checked.** Step 1 is one model rephrasing in minutes; the second model reads the
  brief cold in step 2, so a brief that does not stand on its own comes back as questions there. In
  the quick lane (§9) no second model reads it: the requester's yes at the one stop is the check.

## 4 · Questions

- At most **five** per round, **one decision** each. Never a bundle such as "all six points as
  listed, ok?": one yes to a bundle is how a single exchange adds days of work nobody priced.
- The **first option is the smallest** that still serves the ticket, marked (Recommended).
- Every option says what it **costs** in plain words: hours, whether it needs a migration or a data
  backfill, which screens users have today it changes.
- A question that widens scope always offers **"Later — a follow-up ticket"**.
- A larger option the requester picks goes into the stage where it fits, **not into stage 1**, unless
  they say stage 1 needs it.
- Decide yourself what the code can decide; ask only what only the requester can answer.
- **Do not wait on a default.** When a question's smallest option is safe, take it as an
  `(assumed)` answer and keep working; the requester sees every assumption at the next stop and can
  overturn it. Stop only for what cannot be assumed: who the change is for, a contradiction in the
  request, a cost the requester must accept. In the run above, 17 of 25 answers were the recommended
  default, and waiting for them, overnight twice, took longer than all the agent work of steps 1
  and 2 together.
- **One stop before any code: the design.** Step 1 stops on its own only for a question that cannot
  be assumed; otherwise it goes straight on into the design step, and the requester sees the brief
  and the design together, on their own machine (§11). Their ok there starts step 2, which plans and
  starts step 3 without stopping, and a stage's open PR starts the next one: nobody waits for a
  command to be typed, and nothing waits for the requester until the release to main. A task with
  nothing to draw skips the design: its one stop is step 2's (the brief and the stages), and after it
  the run waits for the requester once more, while they test stage 1 by hand locally (§10). Moving a
  stage on is never a question: the builder pushes, opens the PR into dev, turns on its Auto-fix and
  merges it on green CI by itself (§10). The requester can stop the run, or re-order or cut stages,
  at any time.

## 5 · Reviews block only on ship-blockers

The flow has three reviews, each by the other model: the **plan** (step 2, Opus inline; in the
quick lane, §9, the requester's yes instead), a stage whose risk is **data** or **auth** (step 3,
GPT, on its open PR while CI runs, before the merge into dev), and the **release to main** when it
carries a data or auth stage or a cherry-pick that had to be resolved (step 3, GPT, once, while the
main PR's CI runs). A low-risk stage reaches dev, and a release of low-risk stages reaches main, on
the builder's checks, CI and the requester's merge. CI is the evidence for every mechanical check,
so a review does not re-run it: it looks for what CI cannot see. Every review returns a **Must Fix
only for a ship-blocker**, opened by its class in brackets:

1. **Regression** `[regression]`: something users have today breaks, or changes without the plan
   saying so.
2. **Data** `[data]`: loss or corruption, including a migration that is not reversible or not
   proven in the sandbox.
3. **Security** `[security]`: authz, tenant isolation and RLS, secrets, injection.
4. **It does not do what it says** `[broken]`: a stage's demo script fails on the happy path (a
   crash, a 500, the wrong thing on screen), or nothing, neither a test nor a recorded browser
   check, shows it passing.
5. **CI or a repo rule** `[ci-rule]`: a check of `ci-<app>.yml` would fail, or a rule of the repo's
   `CLAUDE.md` is broken (i18n ru and en, the AI-track markup, migration rules, no AI attribution).
6. **Unsafe on dev** `[unsafe-on-dev]`: unfinished user-facing work outside the stage's guard.

The plan review adds the MVP rules as blockers, because a plan is the cheapest place to cut: stage
1 is not the smallest visible increment; a stage that is neither user-visible nor covered by the
foundation exception; a stage over budget; no guard; no demo script; a literal ask of the ticket in
no stage and not deferred by the requester; a migration, backfill or new server contract placed
ahead of the stage that first needs it; and a stage whose approach builds far more than its outcome
needs when a cheaper rung of the ladder delivers the same thing to the user (name it). In the run
above, a server-side undo subsystem survived four plan reviews as a non-binding remark and became
the slice that blocked every board.

**Everything else is a follow-up**, never a block: edge cases of the new feature, races that need
two people on the new screen at once, polish, more tests, naming, simplifications. It goes under
Should Consider, onto the progress board, and the requester decides when, or whether, it is built.
With no ship-blocker, the verdict is APPROVED and its score is 9.0 or higher, whatever Should
Consider holds (`scoring-rubric.md`, Stage mode).

**Fix and go, one round.** A BLOCK does not buy a second review by default. The builder fixes the
cited Must Fix items on the stage's branch, shows each fix with a test or a check where one can show
it, and pushes; green CI on the fix is the proof, and the stage merges without another GPT run. Only
a `[security]` or `[data]` item gets one re-review of its fix, because those are the findings a
wrong fix turns into an incident. CI still red after the fix round, or a re-review that blocks
again, goes to the requester: fix now, hide behind the guard, or cut.

## 6 · Weight

- **Short documents.** The brief stays under about 80 lines; the plan, the stage map with every
  stage's detail, under about 300, stage 1's detail the fullest. Length is not rigour: the run above
  had an 88 KB brief and stage specs of up to 200 KB, and none of it reached a user sooner.
- **Step 3 is implementation, nothing else.** No design phase, no builder waves, no verify agents,
  no internal pre-reviews or skeptics, no multi-agent fix rounds. Step 2 is where planning happens;
  a stage that needs re-planning goes back to step 2.
- **Each model call gets what its job needs.** A review gets the plan, the stage's build log and the
  diff, not every document the flow ever wrote.
- **Tests prove the stage**: its demo path, a regression guard for every existing behaviour it
  touches, and the repo's mandatory proofs (the migration sandbox, RLS assertions). Not an
  exhaustive matrix of the new feature's edge cases; those are follow-ups. They are written with the
  stage; the affected ones run once, right before the push (§10), and CI runs them all.
- **Speed over exhaustiveness.** This flow optimises time to dev. Ultracode and max effort make a
  step more exhaustive, not faster: when either is on, do not spend it on extra review layers, spec
  documents, wider test matrices or future stages built ahead.
- **No flow changes mid-ticket.** A change to this harness lands between tickets; a running ticket
  finishes on the version it started with.

## 7 · The progress board

`<S>/progress.md` holds one row per stage: its outcome, its status (planned → building → test, for
stage 1 → PR → review → on dev → verified), its budget and the time spent, the PR, when it reached
dev, and its follow-ups. Every step updates it and prints it, and a "status?" is answered from it. Each stage
PR's body carries the board too, so GitHub keeps the record if the session's files are lost.

## 8 · Linear

A stage PR links the issue **without closing it**: no Linear id in its branch or title, and the
first line of its body is `Part of <id>`. Linear closes an issue when the last PR that links it
through its branch, its title or a closing word (`fixes`, `closes`, `resolves`, `completes`,
`implements` and their forms) merges, whatever the base; `part of`, `refs` and `towards` link without
closing ([Linear docs](https://linear.app/docs/github)). Only the PR the requester calls final
carries `Closes <id>`: by the team's convention, the promotion to main that finishes the feature.

## 9 · Two lanes

Step 1 picks the lane from the request, step 2 checks it against the code, and the requester sees
it at the one stop (§4) and can switch it.

- **Quick**: one stage of at most about two hours of build, with low risk: no schema change or
  backfill, no auth, tenant or RLS surface, no deletes or rewrites of existing records. Opus plans
  the stage itself in step 2, from the code; there is no GPT plan, no plan check and no GPT review,
  in step 3 or at the release. The requester's yes is the check of the plan; the requester's local
  test, the local CI pass, CI and PM on dev are the checks of the build. A quick stage that turns
  out to need more (a migration, an auth change, a second stage, over three hours of build) leaves
  the lane: stop, tell the requester, and re-plan it with `/step2` in the stages lane.
- **Stages**: everything else, as the rest of this file describes.

## 10 · Test by hand first, check right before the push

The requester's decisions of 2026-10-06, after a measurement of four runs: about 78% of their
wall-clock was the flow waiting for the requester at a gate (a "ship", a merge after green CI, a
permission for a demo on dev). Locally the requester wants the app up as fast as possible, to test
it end to end by hand; the checks run after that, once, right before the push into dev; on dev, CI
runs every suite and PM tests.

The requester's decision of 2026-10-09, after a second measurement (the session logs since
2026-10-03, checked against GitHub): about a third of their messages to the flow (83 of 241) only
moved it on: «merge», «да, открывай PR в dev», «да, включи auto-fix», «продолжай, мержи когда CI
green», «what is the status?». A stage's CI round took about 8 minutes (p50 7.6), and a green stage
PR then waited a median of about 6 more for their word, because the run asked first or ended its
turn on a running CI. Their words: «не жди меня, открывай PR и делай merge into dev if CI is green».
The same day they put the design first (§11): after their ok on the design nothing waits for them
until the release to main, and their test of stage 1 by hand stays only for a task with nothing to
draw.

- **No checks while building.** While a stage is being built, and while the requester is testing
  it, the builder runs no lint, format, type, i18n or test command. Files the change must regenerate
  (API types, locale keys) are part of implementing it, not a check.
- **Stage 1 is tested by hand, locally, first, when there was nothing to draw** (`Ship: stage1`, the
  default without a design). As soon as stage 1 is built, the builder brings the app up from the
  stage's worktree (the app's usual local port, without a sign-in where the app has a local demo
  mode) and gives the requester the URL. The requester tests it end to end and says ok, or what to
  change; a change goes in without checks, and they test again. After the plan's yes, this is the
  one wait per ticket. After a confirmed design the brief says `Ship: none`: the requester saw what
  users get before any code, and no stage waits for a hand test.
- **The local CI pass, once, right before the push.** After the requester's ok on their hand test,
  or as soon as a stage without one is built, the builder runs the local CI pass: the static checks
  of the app's `ci-<app>.yml` for what the stage touched (lint, format, types, i18n, generated API
  types), the affected tests (`scripts/test-affected.sh`), and, for a schema change, the migration
  sandbox proof. Not the full suites: CI runs them on the PR. A red check is fixed and the pass
  re-run; a fix that changes what the requester tested goes back to them. Then the push and the PR
  into dev.
- **Stages go straight to dev.** A stage without a hand test goes from its local CI pass straight
  to its PR, reaches dev on green CI behind its guard, and PM tests it there. The requester can ask
  to test every stage by hand first, at the stop or at any time: `Ship: every` in the brief's
  header. Older briefs: `Ship: ask` means every, `Ship: auto` means none, as `Ship: none` does.
- **Never ask to move a stage on.** Pushing a stage's branch, opening its PR into dev, turning on its
  Auto-fix and merging it into dev on green CI are the requester's standing ask, for every ticket:
  the builder does them without a question and says in its report that it did. No AskUserQuestion
  and no "shall I…?" for any of them, and no turn that ends to wait for such an answer. The release
  to main stays the requester's call (step 3g).
- **Merge on green; CI time is build time.** The builder merges a stage's PR itself as soon as CI is
  green (a data or auth stage once its review is in, too). The desktop app wakes a session when CI
  goes red (Auto-fix) but not when it turns green, and the builder never polls the checks, so while a
  stage's CI runs it builds the next stage on that stage's branch (§2) and reads the PR's status at
  every natural point: the next stage built, its local CI pass done, a review back. It merges as
  soon as a read shows green. A turn never ends on a running CI while a next stage is left to build;
  at the last stage the CI time goes to the wrap-up (the build log, the board, the bet in PostHog),
  and only if CI still runs after that does the turn end, with the board and one line.
- **GitHub auto-merge only with required checks.** Where the repo allows auto-merge and the base
  branch requires the CI checks, the builder turns auto-merge on (method merge) for each stage PR
  once it may merge, and then nothing waits at all. Allosta-Group/superapp has neither (2026-10-09):
  auto-merge is off and `dev` requires no check, so auto-merge there would merge before CI finished;
  never turn it on. Its CI workflows are path-filtered, so requiring them needs an always-running
  gate job first.
- **On dev, the builder checks the deploy, not the demo.** It confirms that the dev host serves the
  new build, and it writes nothing to the shared dev data; PM walks the demo script from the PR. The
  stage is `on dev` then; the next stage is usually built by then (§2).

## 11 · Design first

The requester's decision of 2026-10-09: a task comes in, we work out what to do, we draw it fast and
they look at it locally, and **only their ok on the drawing starts development**. The measured cost
of drawing late: ALL-800 reached dev in twelve stages, and the requester's look at it («в дизайне у
нас есть исполнители, а на деве я этого не вижу») turned into three follow-up tracks, one of them a
rebuild of the assignee field the PM design had drawn from the start.

- **What gets drawn.** The brief's `Design:` line (step 1) decides: `html`, a prototype the design
  step draws; `handoff <path>`, a PM design that already exists and is shown instead; `none`, when
  nothing users see changes (a backend fix, delivery, infra, monitoring), and the design step is
  skipped.
- **The prototype** is one self-contained HTML file in `<S>/design/`, hi-fi on the product's own
  tokens and fonts, with every state the MVP needs switchable on the page and the real words users
  will read. It shows the MVP and the [later] states of the same screens, those badged «Later». It
  is a picture, not code: nothing in the app imports it, and it is drawn in about half an hour.
- **Looked at locally.** It opens in the requester's browser from disk; the builder does not walk it
  first.
- **The one stop before code.** The requester sees the brief and the design together and says ok,
  or what to change; a change is drawn again, each round in about ten minutes, until they say ok.
  The ok is recorded (`<S>/reviews/design-<N>.md`) and step 2 refuses to plan without it.
- **After the ok nothing waits for the requester until the release to main.** The brief says
  `Ship: none`; step 2 plans against the design and reports the stages without stopping; step 3
  builds each stage as drawn and ships it to dev on green CI (§10).
- **The design is the visual spec.** Stage 1 builds the states the design marks MVP, later stages
  the ones marked Later, each as drawn: layout, sizes, colors and words. A departure goes into the
  build log with its reason, and a change of the design later runs the design step again for the new
  part, then re-plans only the stages not yet started.

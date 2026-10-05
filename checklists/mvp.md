# MVP lens — stages that ship

The delivery rules of the co-dev flow. Every step reads this file, the way it reads
[`ponytail.md`](ponytail.md): step 1 names the MVP, step 2 plans it as stages, step 3 implements and
ships one stage at a time. Ponytail asks "does this code need to exist?"; this file asks "does it
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
2. the deploy succeeded, on every service the change touches;
3. its **demo script** was walked on the dev environment and passed: someone looked at it;
4. the progress board (§7) says so.

Code on a branch, an approved review or a green CI is not a delivered stage.

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
- **Serial by default.** Stage N+1 starts from `origin/<base>` after stage N merged. Parallel stages
  only on disjoint files and on the requester's ask; never build on an unmerged stage's commit.
  Parallel work multiplies code, not delivered value.
- **The map is alive.** After every stage the requester may re-order, cut or add stages. A change
  re-plans only the stages not yet started (step 2 again); nothing that shipped is redone.
- **A deadline decides the cut.** When the ticket has a target date (a Linear milestone, a promise),
  the stage map shows which stages land before it.

## 3 · Naming the MVP

- **Start from the ticket's literal words** (step 1). What the ticket names is in scope. What a
  design or a prototype shows beyond it is a candidate for a later stage, not part of the MVP.
- **The MVP is the least a user must see to say "this is it"**, and step 2's stage 1 delivers it. If
  something smaller still serves the request, the planner says so.
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
- **One stop before any code.** Step 1 stops on its own only for a question that cannot be
  assumed; otherwise it goes straight on into step 2, and the requester sees the brief and the plan
  together at step 2's stop. Their yes there starts step 3 at once, and a verified stage starts the
  next one: nobody waits for a command to be typed. The requester can stop the run, or re-order or
  cut stages, at any time.

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
  exhaustive matrix of the new feature's edge cases; those are follow-ups.
- **Speed over exhaustiveness.** This flow optimises time to dev. Ultracode and max effort make a
  step more exhaustive, not faster: when either is on, do not spend it on extra review layers, spec
  documents, wider test matrices or future stages built ahead.
- **No flow changes mid-ticket.** A change to this harness lands between tickets; a running ticket
  finishes on the version it started with.

## 7 · The progress board

`<S>/progress.md` holds one row per stage: its outcome, its status (planned → building → PR → review
→ on dev → verified), its budget and the time spent, the PR, when it reached dev, and its
follow-ups. Every step updates it and prints it, and a "status?" is answered from it. Each stage
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
  in step 3 or at the release. The requester's yes is the check of the plan; the builder's checks,
  CI and the demo on dev are the checks of the build. A quick stage that turns out to need more (a
  migration, an auth change, a second stage, over three hours of build) leaves the lane: stop, tell
  the requester, and re-plan it with `/step2` in the stages lane.
- **Stages**: everything else, as the rest of this file describes.

# Progress: <slug>

Updated: <YYYY-MM-DD HH:MM>
Deadline: <date or none>
On dev: <bar> <N> of <M> stages verified on dev

<!-- The progress board of the co-dev flow (harness/checklists/mvp.md §7). /step2 creates it from
     the plan's stage map, and /step3 moves one stage through it per run. Every step prints it, and a
     "status?" is answered from it. Each stage PR's body carries a copy, so GitHub keeps the record if
     the session's files are lost.
     The bar is one block per stage: █ verified on dev, ▒ in progress, ░ not started; for example
     "██▒░░ 2 of 5 stages verified on dev". -->

| # | what users get on dev | status | budget | spent | PR | on dev | verified |
|---|-----------------------|--------|--------|-------|----|--------|----------|
| 1 |                       | planned | 4 h   | 0 h   | —  | —      | —        |

<!-- status: planned → building → PR → review (a data or auth stage) → on dev → verified, or cut /
     moved to <stage>.
     spent: build and fix time, not waiting time. on dev: when the deploy finished. verified: when
     the demo script passed on the dev environment, and who looked. -->

## Follow-ups
<!-- From the stage reviews and the build, one line each: what, the stage that found it, and the
     requester's decision (a later stage, a follow-up ticket, drop). Undecided ones are marked so. -->

## Log
<!-- One line per event, newest last: YYYY-MM-DD HH:MM — stage N: what happened. -->

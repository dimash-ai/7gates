# Brief: <slug>

Branch: <the base name of the stage branches, without the Linear id: feat/focal-<name> for Focal, feature/<name> or fix/<name> elsewhere>
Base: dev
Linear: <ALL-id — url, or none>
Deadline: <the milestone's target date or a promised date, or none>
Ship: <set in step 2: ask or auto>
Lane: <quick or stages: set in step 1, checked in step 2 (harness/checklists/mvp.md §9)>
Harness: <the harness commit step 1 ran on>
Date: YYYY-MM-DD

<!-- Step 1 of the co-dev flow (/step1): the requester's input, rephrased into the prompt step 2 plans
     from. The planner never saw the conversation, so the brief stands on its own: no "as
     discussed". It says WHAT and WHY in the user's terms, never HOW: no modules, endpoints, tables or
     designs. Under about 80 lines. Written in English; the requester's words and every UI string stay
     verbatim in their language.
     The header is machine-read: one key per line, a plain value with no backticks or bold. Branch is
     the base name of the stage branches (<Branch>-s1, <Branch>-s2, …, and <Branch>-main); it never
     carries the Linear id, because a branch or PR title with the id makes Linear close the issue when
     that PR merges (harness/checklists/mvp.md §8). Harness is the version of the flow this slug
     finishes on. -->

## In short
<!-- The request as the prompt the requester meant to write: three to five sentences that a reader
     who never saw the conversation understands. Where in the product, what becomes possible or stops
     going wrong, for whom, and why now. -->

## Problem
<!-- What is wrong or missing today, for whom, and what it costs them. One short paragraph. -->

## User stories
<!-- One story per distinct thing a user can do or get, only the ones the request asks for. Every
     criterion is observable from the user's side, numbered, and marked [MVP] or [later]. -->

### US-1 — <title>
As a <who>, I want <what>, so that <why>.
- US-1.1 [MVP] Given <the situation>, when <the user does this>, then <what they see or get>.

## MVP
<!-- The least a user must see on dev to say "this is it" (harness/checklists/mvp.md §3), in one to
     three lines, from the request's literal words. -->

## Not now
<!-- What the request or its design shows that the MVP leaves out, one line each: a later stage or a
     follow-up ticket. -->

## Hypothesis
<!-- One line: "We believe <the change> for <these users> will <this outcome>; signal: <an event or a
     screen's weekly users>." A fix or a chore says "none (fix)" or "none (chore)". Step 2 makes the
     signal measurable; /learn checks it after the release to main. -->

## Assumptions and questions
<!-- Everything inferred rather than read, each marked (assumed): the requester's yes accepts it.
     Then every question asked and its answer, with the date: the planner builds on it and does not
     reopen it. -->

## Sources
<!-- The Linear issue, the design handoff or prototype, screenshots: paths or URLs. -->

## In the requester's words
<!-- Verbatim: what they said, the Linear title, description and comments, screenshots transcribed. -->

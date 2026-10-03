# Product brief: <slug>

App: <focal, prima, sura, the assistant, or several>
Linear: <ALL-id — url, or none>
Deadline: <the milestone's target date or a promised date, or none>
Date: YYYY-MM-DD

<!-- Step 1 of the co-dev flow (/step1). The request from the user's side, with the MVP cut: what we
     want, for whom, why, and in which order users get it. Opus and GPT each draft one from the
     request (product/opus.md, product/codex.md), and Opus merges the two into brief.md: union for
     coverage, intersection for commitment (harness/checklists/mvp.md §3). Step 2 plans the stages
     from it; its criteria are what each stage is held to; its Hypothesis is the bet /step3
     registers in PostHog and /learn checks every week.
     Product, not engineering: screens, flows and the words a user sees, never modules, endpoints or
     tables. What already exists is named in product terms ("the full task card already opens from
     the calendar"). Whatever was inferred rather than read or heard is marked (assumed).
     Written in English; the requester's words and every UI string stay verbatim in their language.
     Under about 150 lines: a fix gets In short, Stage 1 and Not now; a feature gets every section,
     each one short. -->

## In short
<!-- The request as the prompt the requester meant to write: three to five sentences that a reader
     who never saw the conversation understands. Where in the product, what becomes possible or stops
     going wrong, for whom, and why now. Nothing the requester did not state or confirm. -->

## Stage 1 — the MVP
<!-- The least a user must see to say "this is it", working on dev within one working day
     (harness/checklists/mvp.md §2). Two to four lines on what the user sees and can do; the
     criteria it meets, by id; what already exists that it reuses; what it deliberately leaves to
     later stages. -->

## Next stages
<!-- In value order. Each one user-visible on dev, each at most about four hours of build; a bigger
     one is two stages. Size from a quick look at what exists, not from a design. -->

| # | what users get on dev | size | changes data? | why this order |
|---|-----------------------|------|---------------|----------------|
| 2 |                       | S (≤ 2 h) or M (≤ 4 h) | no, migration, or backfill | |

## Not now
<!-- What the request or the design shows that no stage builds, one line each: a candidate
     follow-up ticket. Includes whatever the requester deferred, with the date. -->

## Hypothesis
<!-- The bet, written so it can be checked after release. With about a hundred weekly users, count
     people rather than rates. A fix or a chore says "Hypothesis: none (fix)" or "(chore)" with one
     line on why, and is not tracked. -->
We believe that <this change> for <these users> will <this outcome>.
We will know we are right when <signal> reaches <target> within <weeks> of the prod release.
- Signal: <an event, a screen's weekly users, a funnel step; or "does not exist yet" and the stage
  that adds it>
- Baseline: <its value today and where it came from, or: unknown>
- Wrong if: <the result that means we were wrong> → <roll back, rework, or keep it and stop
  investing>
- Riskiest assumption: <the belief that, if false, makes this worthless>

## User stories
<!-- One story per distinct thing a user can do or get. Every criterion is observable from the
     user's side and carries an id and the stage that delivers it:
     "US-1.1 [s1] Given …, when …, then …". Criteria of Not now items are not written. -->

### US-1 — <title>
As a <who>, I want <what>, so that <why>.
- US-1.1 [s1] Given <the situation>, when <the user does this>, then <what they see or get>.

## Who and why
<!-- Five to ten lines: who it reaches, today → after (every Focal user, a shared calendar's
     editors, standalone and SURA's mount); who could be worse off (a habit broken, an option
     removed, data that now looks different, the users this must never regress for); why now; the
     release note in Russian, one or two sentences as a user reads them. -->

## Unhappy paths
<!-- Stage 1's only, from the user's side: the empty state, an error, a slow connection, phone and
     desktop, ru and en, shared access, data made before the change. Later stages list theirs when
     they are planned. -->

## Questions and answers
<!-- In a draft: at most five questions, each one decision, the smallest option first with its
     cost (harness/checklists/mvp.md §4). In the brief: every question asked, its answer, who gave
     it and when. -->

## Sources
<!-- The Linear issue, the design handoff or prototype, screenshots, the product docs read, a
     PostHog insight: paths or URLs. -->

## In the requester's words
<!-- Verbatim: the command arguments, what they said, the Linear title, description and comments. -->

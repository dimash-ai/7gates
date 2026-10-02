# Product brief: <slug>

App: <focal, prima, sura, the assistant, or several>
Linear: <ALL-id — url, or none>
Date: YYYY-MM-DD

<!-- Step 1 of the co-dev flow (/step1). The request rewritten from the user's side, before anyone
     reads the code: what we want to achieve, for whom, and why. Opus and GPT each draft one from the
     request alone (product/opus.md, product/codex.md), and Opus merges the two by union into the
     product part of brief.md, which step 2 researches and plans from. Its user stories' criteria
     are the acceptance criteria the plan, the build and the release pass are held to; its
     Hypothesis is the bet, which /step3 registers in PostHog and /learn checks every week.
     Product, not engineering: no modules, endpoints, tables or designs. Screens, flows and the words
     a user sees are product. Whatever was inferred rather than read or heard is marked (assumed),
     so the requester can strike it.
     Written in English; the requester's words and every UI string stay verbatim in their language.
     Scale it to the request: a fix gets In short, the story it repairs and Out of scope; a feature
     gets every section. -->

## In short
<!-- The request as the prompt the requester meant to write: three to five sentences that a reader
     who never saw the conversation understands. Where in the product, what becomes possible or stops
     going wrong, for whom, and why now. No requirement the requester did not state or confirm. -->

## Hypothesis
<!-- The bet this change makes, written so it can be checked after release. With about a hundred
     weekly users, count people rather than rates, and give the window time to reach them. A fix or
     a chore with no bet in it says "Hypothesis: none (fix)" or "(chore)", with one line on why, and
     is not tracked. -->
We believe that <this change> for <these users> will <this outcome>.
We will know we are right when <signal> reaches <target> within <weeks> of the prod release.
- Signal: <what measures it, in PostHog terms: an event, a screen's weekly users, a funnel step; or
  "does not exist yet", which step 2 must add>
- Baseline: <its value today and where it came from, or: unknown>
- Target: <a number and a window, e.g. 15 weekly users within 4 weeks of release>
- Wrong if: <the result that means we were wrong> → <then: roll back, rework, or keep it and stop
  investing>
- Riskiest assumption: <the belief that, if false, makes this worthless>

## User stories
<!-- One story per distinct thing a user can do or get. Every criterion is observable from the
     user's side (given / when / then) and has an id: the brief's acceptance criteria are these ids.
     Priority: must (no release without it), should, could (the first to cut). -->

### US-1 — <title>
As a <who>, I want <what>, so that <why>.
Priority: must
- US-1.1 Given <the situation>, when <the user does this>, then <what they see or get>.

## Who it is for, and what changes for them
<!-- Every group of users this reaches, directly or not, and for each: today → after. For example:
     every Focal user, or only the owner of a shared calendar and the people it is shared with; a
     PRIMA principal and their delegate; free or paid; the standalone app and SURA's mount of it. -->

## Does the user benefit?
<!-- Yes, indirectly or no, and why, in the user's terms. Then who could be worse off: a habit
     broken, an option removed, existing data that now looks different, a slower screen, a
     regression for the users this must never regress for. If no end user is better off (a
     refactor, infrastructure), name who is (engineers, the PM, support) and write the stories for
     them. If nobody is, the requester decides whether to build it at all. -->

## Unhappy paths
<!-- What a user can run into, from their side: the first visit and the empty state, an error, a
     slow or lost connection, phone and desktop, ru and en, time zones, shared or delegated access,
     a lot of data, data made before this change. Only the ones that apply. -->

## Business and marketing
- Release note (ru): <one or two sentences as a user would read them, or: not user-visible>
- Why now: <a launch, a promise to a client, retention, activation, conversion to paid, support
  load, a dependency>
- Fit: <the part of the product's vision or roadmap this serves, with its doc, or: none found>
- Who gets it: <everyone, internal only, a paid tier, behind a flag (docs/ENTITLEMENTS.md)>

## Out of scope
<!-- What is not being asked, including tempting neighbours and whatever a design shows but the
     requester excluded. -->

## Questions and answers
<!-- In a draft: the questions only the requester can answer, each with the answer you would
     assume. In the brief: every question asked in step 1 or step 2, its answer, who gave it and
     when. None stays open at a stop: an unanswered question becomes an (assumed) the requester
     accepted. -->

## Sources
<!-- What this rests on, as paths or URLs: the Linear issue, the design handoff or prototype,
     screenshots, the product docs read, a PostHog insight. -->

## In the requester's words
<!-- Verbatim: the command arguments, what they said, the Linear title, description and comments. -->

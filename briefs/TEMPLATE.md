# Brief: <slug>

Branch: <the base name of the stage branches, without the Linear id (see below)>
Base: dev
Linear: <ALL-id — url, or none>
Deadline: <the milestone's target date or a promised date, or none>
Ship: <ask, or auto: whether /step3 asks before it opens and merges a stage's PR into dev>
Harness: <the harness commit this slug started on: git -C harness rev-parse --short HEAD>
Date: YYYY-MM-DD

<!-- The ONE requirements document of the co-dev flow. Step 1 (/step1) writes it: the sections of
     harness/briefs/PRODUCT.md below its header, merged from two independent drafts (union for
     coverage, intersection for commitment: harness/checklists/mvp.md §3) and confirmed by the
     requester. Step 2 (/step2) plans the stages from it, cold: the planner never saw the
     conversation, so no "as discussed". Under about 150 lines.
     Tag every story, criterion, stage and question that came from one draft only: [O] Opus or [G]
     GPT; untagged means both, or the requester. Questions and answers records every answer the
     requester gives, in any step, with its date: the planner builds on it and does not reopen it.
     The header is machine-read: one key per line, a plain value with no backticks or bold. Step 1
     fills it; step 2 sets Ship from the requester's answer. Harness pins the flow's version: a slug
     finishes on the harness it started with (harness/checklists/mvp.md §6), so a later harness
     change waits for the next ticket unless the requester moves this one over.
     Branch is the BASE name of the stage branches: stage N is built on <Branch>-s<N>, cut from
     origin/<Base> once stage N-1 has merged, and the promotion to main is <Branch>-main. Use the
     app's convention WITHOUT the Linear id (feat/focal-<short-name> for Focal, feature/<short-name>
     or fix/<short-name> elsewhere): Linear links a PR whose branch or title carries the id and
     closes the issue when the last such PR merges, so the first stage's merge would close it. The
     stage PRs reference the issue in their body instead (/step3). -->

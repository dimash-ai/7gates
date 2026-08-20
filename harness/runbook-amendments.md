# RUNBOOK amendments — our local additions to the CTO's per-ticket prompts

The per-ticket procedure lives in the CTO's canon:
`agent-skills/plugins/dev-methodology/RUNBOOK.md`. We do not edit it — it is a live
symlink source, and a local edit would conflict on the next upstream pull.

So amendments live here. Each one names the RUNBOOK step it modifies and gives the exact
text to paste into that step's prompt block. Keep the house style: **prompt lines are
deliberately unwrapped** — one instruction per long line — so a copy-paste arrives as clean
prose instead of text broken mid-sentence.

> **Drift check.** These are deltas against the RUNBOOK as of 2026-08-20. If upstream
> rewrites T1 or T2, re-read the step before pasting — a delta assumes the surrounding
> block still says what it said.

---

## T1 — read the exploration note before drafting

**Why.** `/gate-explore` runs two independent reconnaissance sweeps and merges them into an
evidence dossier at `harness/notes/<topic>.md`, and **nothing downstream reads it.** The architect
takes `TASK_FILE` and nothing else; the RUNBOOK mentions `notes/` zero times, and so does the
`brownfield-spec-template` skill. A sweep that found the prior art, the scars and the contradictions
and never reached the spec is work the flow will never see. This closes that seam at the only place
it can be closed — the one step that authors the spec.

**Add this anchor** to the T1 block, beside `BACKLOG_FILE` and `LINEAR_PROJECT` (absolute
path per the RUNBOOK's anchor convention — do not use `~`, the agent quotes these):

```
NOTES_DIR=/Users/<you>/Desktop/allosta/harness/notes
```

**Add this line** to the T1 prompt, after the `Then compare the two records BEFORE drafting:`
instruction:

```
Then check NOTES_DIR for a dossier matching this ticket's topic — /gate-explore writes one when the issue was swept by Opus and GPT independently, and its sections are Territory / Prior art / Constraints / Scars / Tests / Absences, followed by Contradictions and Gaps. If one exists, read it BEFORE drafting and fold it in section by section, because each one lands somewhere different in the spec. Territory seeds the MAY EDIT and DO NOT TOUCH lists. Prior art constrains scope: if the dossier shows something already does part of this, the spec says to reuse it and does not silently re-specify building it. Constraints become confirmed assumptions with their citations carried across — including the AI-track determination, which is what decides whether the spec commits the change to the semantic exoskeleton and LDD. Scars become DO NOT lines: an approach already tried and recorded as failed must not be re-proposed without saying why this time differs. Absences are candidate acceptance criteria, and an unenforced invariant the dossier found is exactly what BR-1 exists to guard. Two sections are not evidence and must not be folded in as if they were: an unresolved CONTRADICTION blocks drafting outright — stop and tell me, because a spec built on the wrong one of two contradictory facts is wrong from its first acceptance criterion — and every GAP becomes an explicit open question in the spec, marked UNVERIFIED so the plan gate re-checks it rather than inheriting it as settled. Cite the dossier by filename so each decision has a traceable origin. If no dossier exists, say so in one line and carry on — do not go create one, and do not treat its absence as license to invent answers to questions the ticket leaves open.
```

**What it does not do.** It does not make exploration mandatory, and it does not let the note
override the backlog or Linear — the existing precedence rule still governs (the file is the
source of truth for authoring; if Linear holds ACs the file lacks, T1 still stops).

---

## T2 — hold the architect before it delegates

**Why.** The architect runs `DESIGN_AND_VALIDATE → DELEGATE_IMPLEMENTATION` without stopping,
so gate α has no window to open in. Without this line `/gpt-gate-plan` arrives after the code
is written, which is not a gate.

**Add this line** to the T2 launch prompt:

```
After writing DevelopmentPlan.md, STOP and report its absolute path. Do NOT delegate implementation until I return with a plan verdict.
```

Full context in [`README-gpt-gates.md`](README-gpt-gates.md) and
[`../.claude/commands/gpt-gate-plan.md`](../.claude/commands/gpt-gate-plan.md).

---

## Upstreaming

Both amendments are repo-agnostic — neither mentions superapp, a ticket prefix, or a path
that only exists here, apart from the `NOTES_DIR` anchor the operator fills in anyway. If
they hold for a few tickets they are the extractable part, and the right home for them is the
RUNBOOK itself. Send them to the CTO as a patch rather than growing this file indefinitely.

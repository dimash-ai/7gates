---
description: "3-gate A (design): Opus does, GPT reviews"
argument-hint: <feature-name> <repo-path> [base-branch]
---

# 3-Gate · A — design  ·  Opus does · GPT reviews

**Arguments — parse them yourself.** Raw args: `$ARGUMENTS`

Whitespace-split the raw args: token 1 → `<feature>`; token 2 → `<repo>` (path relative to the
pipeline root); token 3 (optional) → `<base>` (empty → `main`; focal until 2026-07-10 passes
`feature/focal-migration`). If the raw-args line above looks unsubstituted or empty, recover the tokens from this invocation's command-args instead. This file deliberately uses **no positional dollar-number placeholders** (the runner's `$N` is **0-indexed** — `$1` is the *second* argument, per the Claude Code skills docs — an off-by-one foot-gun against shell conventions); instead, substitute the literal angle-bracket tokens below — in prose AND inside bash blocks — with the parsed values before running anything. An absent optional token substitutes as an **empty string**.


The first gate of the **3-gate flow** (`.ai/README-3gate.md`): produce the **complete design**
for `<feature>` — the decision, the build approach in slices, and the architecture — as one cohesive
document the builder and verifier can work from alone.

Invoke as `/gate-design <feature> <repo> [base-branch]` (e.g.
`/gate-design focal-goals-mindmap-v2 superapp feature/focal-migration`). `<feature>` is the feature; `<repo>`
is the path — relative to this pipeline root — to the git repo the feature will change; `<base>` is
the **base branch** it forks from (optional — **default `main`; focal until 2026-07-10: pass
`feature/focal-migration`**, after the migration merges focal uses the default too).

**Worktree (first thing).** Create (or reuse) the feature's dedicated worktree of `<repo>` —
`<repo>/.worktrees/<feature>` on branch `feature/<feature>` — per the worktree contract
`.ai/checklists/worktree.md`, so the branch exists from the first gate and every later gate just
reuses it. Run from the pipeline root:

```bash
BR="feature/<feature>"; BASE="<base>"; [ -n "$BASE" ] || BASE="main"   # focal until 2026-07-10: pass feature/focal-migration as <base>
if [ ! -d "<repo>/.worktrees/<feature>" ]; then
  if git -C "<repo>" show-ref --verify --quiet "refs/heads/$BR"; then
    git -C "<repo>" worktree add ".worktrees/<feature>" "$BR"            # branch exists (prior run) -> attach
  else
    git -C "<repo>" worktree add ".worktrees/<feature>" -b "$BR" "$BASE" # new branch off base
  fi
fi
echo "worktree: <repo>/.worktrees/<feature>   branch: $BR"
```

The design work itself touches only `.ai/` in this pipeline repo — the worktree is where gate B
builds. When reading the codebase to ground the design, read `<repo>/.worktrees/<feature>`, not `<repo>`. If `<repo>`
was omitted, skip this step — gate B creates the worktree instead.

**Doer = Opus (you, in this conversation).** Before running this gate, write the design for `<feature>` to
`.ai/design/<feature>-design.md` following `.ai/design/TEMPLATE-3gate.md`. It is one document, structured by
topic, not a sequence of sub-steps: the problem and the decision (with the alternatives you rejected
and why), the assumptions and what's out of scope, the success criteria, the build broken into
independently shippable slices, and the architecture — data model, interfaces, happy/unhappy flow,
test strategy, security, and rollback. If the file doesn't exist yet, write it now, then continue.

**Reviewer = GPT (Codex), read-only.** Run exactly this one bash command from the pipeline root:

```bash
codex exec --sandbox read-only "$(cat .ai/prompts/reviewer.md)
You are GPT Codex, the reviewer. Step: design. Review ONLY the design doc at .ai/design/<feature>-design.md (and the kickoff task .ai/tasks/<feature>.md if present), judging it as one whole design: is the problem framed correctly and the chosen approach justified against the alternatives; are assumptions explicit and scope bounded; is the build sliced into sound, independently shippable steps each with a clear test; is the architecture coherent — coupling, data model, interfaces, and the unhappy-path flow (null/empty/upstream error); does it reach for what already exists before adding new surface (the reuse-first ladder, CLAUDE.md #2)? You are read-only and must NEVER edit any file. Score 0-10 per .ai/checklists/scoring-rubric.md and output the verdict EXACTLY as the charter specifies (Reviewer: GPT Codex, Step: design). Status is APPROVED only if Score is 9.0 or higher."
```

Then:

1. Ensure `.ai/reviews/<feature>/` exists, then save **only the verdict block** — from the `# Review Verdict` line to the end — to `.ai/reviews/<feature>/A-design-verdict.md`. Do NOT paste the raw CLI transcript (write that to `.ai/runs/` if you want it). **If the file exists, increment:** `A-design-verdict-2.md`, etc.
2. STOP. Make no further changes.
3. Report **Score** and **Status**:
   - **BLOCKED** (< 9.0): list every Must Fix, address them in the design doc, re-run this gate.
   - **APPROVED** (>= 9.0): say so; next stage is **3-gate B — build** (`/gate-build <feature> <repo> <base>` —
     it reuses the worktree created here).

> `--sandbox read-only` keeps the reviewer from touching the tree — confirm the flag with `codex --help` for your version.

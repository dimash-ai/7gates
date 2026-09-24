---
description: "Step 1 (brief): you state the intent, Opus and GPT research it independently, the union becomes the planner's brief"
argument-hint: <slug> [repo-path]
---

# Step 1 — brief  ·  you + Opus · Opus and GPT research independently

The first step of the **3-step co-dev flow** (`harness/README-codev.md`). It turns what the requester
wants into **one document the planner can work from alone**: the intent and its acceptance criteria
on top, the evidence both models found below. Nothing is designed here. The brief says *what* and
*why*; GPT designs the *how* in step 2, cold, from this document.

`$1` is the slug: the Linear id when there is an issue (`ALL-646`), otherwise a short kebab-case
name. `$2` is the code repo, optional: the current git repo, or `superapp` when run inside
`superapp/harness`.

Not scored. Two independent sweeps here buy **coverage**, not agreement: the merge is a union. The
gate is the requester, and the step ends when they confirm the brief.

**Paths.** Every bash block below starts by sourcing `harness/bin/codev-env.sh`, which prints one
line: `codev: slug=… results=<S> worktree=<WT> …`. In the prose, `<S>`, `<WT>` and `<H>` (the
`harness/` directory) mean those literal paths. Results land in `<S>` = the code repo's
`specs/$1/`, always in the **main** checkout, gitignored in superapp.

## 1a — The intent, confirmed before anyone researches

Both researchers get one paragraph and nothing else. A mistake in it sends both sweeps the wrong
way **together**: independence protects against one model's blind spots, not against a wrong
question. So the requester confirms it first.

1. Take the requester's words as given, in their language. If the work has a Linear issue, take its
   title, description and `gitBranchName` too (Linear MCP if connected, otherwise ask for them).
   Both verbatim.
2. Restate them as **one paragraph in English**: what should become possible, for whom, where in the
   product, and what is explicitly not being asked. Ask at most two questions, and only ones whose
   answer changes where to look. If the request itself looks speculative, say so now: rung 1 of the
   ladder in `<H>/checklists/ponytail.md`.
3. Agree three settings:
   - **Depth.** *quick*: a fix or a small change in a known place; Territory, Prior art, Tests and
     Scars, around the code the issue names. *full*: a feature, or anything with real unknowns; all
     six sections, plus sources outside the repo.
   - **Branch.** Linear's `gitBranchName` when there is an issue. Otherwise the app's convention:
     `feat/focal-<slug>` for Focal (`apps/focal/CLAUDE.md`), `feature/<slug>` or `fix/<slug>`
     elsewhere. Every slug needs a branch of its own.
   - **Base.** `dev` for superapp.
4. **STOP** until the requester says yes to the paragraph and the settings. Then write the paragraph,
   verbatim, to `<S>/research/issue.md`, and start `<S>/brief.md` from
   `<H>/briefs/TEMPLATE.md` with its header filled in: `Branch:`, `Base:`, `Linear:`, `Depth:` and
   `Date:`, one per line, plain values with no backticks or bold.

Then create the worktree. It pins the tree that both sweeps read, that GPT plans against, and that
Opus builds in, so research, plan and code all describe the same commit:

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header || exit 1
mkdir -p "$S/research" "$S/reviews" "$S/runs"
if [ -d "$WT" ]; then
  echo "worktree exists on $(git -C "$WT" branch --show-current)"
else
  git -C "$M" fetch origin "$BASE" --quiet || { echo "codev: cannot fetch origin/$BASE"; exit 1; }
  git -C "$M" fetch origin "refs/heads/$BR:refs/remotes/origin/$BR" --quiet 2>/dev/null   # the branch, if it already exists on origin
  if git -C "$M" show-ref --verify --quiet "refs/heads/$BR" || git -C "$M" show-ref --verify --quiet "refs/remotes/origin/$BR"; then
    git -C "$M" worktree add ".worktrees/$SLUG" "$BR" || exit 1                              # existing branch: attach to it
  else
    git -C "$M" worktree add --no-track -b "$BR" ".worktrees/$SLUG" "origin/$BASE" || exit 1   # new branch from the remote tip
  fi
fi
echo "pinned: $(git -C "$WT" rev-parse --short HEAD) $(git -C "$WT" log -1 --format=%cs)"
```

Add `Pinned: <sha>` from that last line to the brief's header.

## 1b — Two sweeps, independent and in parallel

Start GPT first, then sweep yourself while it runs. **Do not open `<S>/research/codex.md` until
`<S>/research/opus.md` is written**: reading GPT first anchors you on it, and the union stops being
two views. The block writes GPT's output to files and prints only its exit status, so nothing of
the sweep reaches you early.

**GPT**: read-only, in the worktree, web search on, the prompt read from a file and the final
message written by `-o`. Replace `<quick|full>` with the agreed depth. Run it **in the background**
(Bash `run_in_background`): a sweep outlasts the Bash tool's timeout.

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header && codev_need_worktree || exit 1
[ -s "$S/research/issue.md" ] || { echo "codev: $S/research/issue.md is missing - finish 1a first"; exit 1; }
P="$S/runs/brief-codex.prompt.md"
{ cat "$H/checklists/ponytail.md"
  printf '\n\nTHE ISSUE, verbatim as the requester confirmed it:\n'; cat "$S/research/issue.md"
  cat <<EOF

DEPTH: <quick|full>. quick means sections 1, 2, 4 and 5 only, and only around the code the issue names. full means all six sections.

You are GPT Codex on a reconnaissance sweep of the code repo in your working directory. You are NOT solving this issue and NOT proposing a design: you are finding everything a planner would need to know before designing one. Work INDEPENDENTLY and from scratch: do not look for, assume, or defer to any other model's findings.
Sweep for: (1) TERRITORY - every module, route, table, migration, config and test this issue plausibly touches. (2) PRIOR ART - code that already does part of this and should be reused instead of reinvented. Walk the ladder in the lens above and record each item with its rung number: 2 existing code in this repo, 3 the standard library, 4 a native platform or framework feature, 5 an already-installed dependency. If something already covers the whole intent, say so first. (3) CONSTRAINTS - pinned versions read from pyproject.toml, package.json and the lockfiles (name the file), contracts and interfaces this must not break, and the rules that govern this surface: read CLAUDE.md, AGENTS.md and the CLAUDE.md of the app involved, and state whether the change is AI-track code (semantic exoskeleton and LDD), needs a migration (sandbox proof), adds user-facing strings (i18next, ru and en), or crosses a tenant-isolation or RLS boundary; name the CI workflow (.github/workflows/ci-<app>.yml) whose jobs verify it. (4) SCARS - BUG_FIX_CONTEXT comments, recorded deviations, TODOs, ponytail: markers and past workarounds in the code this touches: what was already tried and why it failed. (5) TESTS - what covers this surface today, and what each test actually asserts versus what its name claims. (6) ABSENCES - invariants stated only in a comment with nothing enforcing them, configurable values whose worst legal setting is materially worse than the default, two concerns sharing one credential or limit, code paths with no test.
Cite EVERY item as file:line. An item you cannot cite is not evidence: drop it, or mark it explicitly as a hunch. For facts outside this repo (library behaviour at the pinned version, platform features) use your web search tool and cite the URL; if you have no web access, say so, and never invent a URL, version or API detail. Do not open or quote any .env file. Sweep WIDE, report NARROW: include an item only if a planner could plausibly make a different decision because of it. Do not propose a solution, a design or an implementation order. You are read-only and must NEVER edit any file. Your FINAL message must be the complete sweep in Markdown, one section per category, and nothing else.
EOF
} > "$P"
cd "$WT" && codex exec --sandbox read-only --config 'web_search="live"' -o "$S/research/codex.md" - < "$P" > "$S/runs/brief-codex.log" 2>&1
echo "codex exit=$?  sweep bytes=$(wc -c < "$S/research/codex.md" 2>/dev/null || echo 0)"
```

- An empty sweep or a non-zero exit is a failed run: read `<S>/runs/brief-codex.log` (not the
  sweep). If this Codex version rejects `--config 'web_search="live"'`, drop the flag, re-run, and
  record in the brief that GPT's sweep has no external facts, so every external fact rests on Opus
  alone.
- If `codex exec` fails auth, **STOP**. One sweep is a search, not this step. Recover with
  `rm ~/.codex/auth.json && codex login`, then re-run.

**Opus (you)**: the same paragraph, the same depth, the same categories and rung numbers, reading
the code in `<WT>`, not the main checkout. Write `<S>/research/opus.md`. Cite every item as
`file:line`, every external fact by URL: Context7 for library docs at the pinned version, WebSearch
or WebFetch for the rest. Never answer a version or API question from memory. Read-only subagents
for breadth are fine.

## 1c — Merge by union

When the background run has finished and `opus.md` is written, read both sweeps and merge:

- **Union, not intersection.** An item only one sweep found is the coverage you paid for. Tag every
  item `[O]`, `[G]` or `[both]`.
- **Re-check GPT's citations** against `<WT>`. Fix or drop a wrong one and say so in the brief.
- **Contradictions** (the same fact reported two ways) are settled by reading the code, never by
  picking the more confident sweep. When the code cannot settle it because it is a product decision
  (what *should* happen, not what does), it is a question for the requester.
- **Gaps** (what neither sweep could establish) become open questions, each marked `UNVERIFIED` with
  what would close it.
- **Prior art that already covers the whole intent** (rungs 2 to 5: this repo, the standard library,
  the platform, an installed dependency) is a question for the requester: "X already does this.
  Still build?"
- **Sweep wide, report narrow.** A finding earns a place in the brief only if the planner could
  decide differently because of it. The raw sweeps stay in `research/` and are not pasted in.

## 1d — Write the brief, get the yes

Complete `<S>/brief.md` from the template, in English, with the requester's words verbatim. Its
Verification section names the jobs of `.github/workflows/ci-<app>.yml` for each app the change
touches: that is where superapp's real checks live.

**STOP.** Show the requester the Goal, the Acceptance criteria, the Decided list, and every
question the merge produced. Their answers go into the brief; no contradiction may stay open. Their
yes ends step 1. Next: `/step2 $1`.

If their answers change the intent itself rather than filling it in, go back to 1a: the sweeps
answered a different question.

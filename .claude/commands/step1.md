---
description: "Step 1 (brief): you and Opus write the product brief (who it is for, user stories), Opus and GPT research it independently, the union becomes the planner's brief"
argument-hint: <slug> [repo-path]
---

# Step 1 — brief  ·  you + Opus · Opus and GPT research independently

The first step of the **3-step co-dev flow** (`harness/README-codev.md`). It starts on the user's
side: you and Opus rewrite the request as a **product brief**, what we want to achieve, for whom,
whether they are better off, and the user stories that say so. Only then do both models research
it. The result is **one document the planner can work from alone**: the product brief and its
acceptance criteria on top, the evidence both models found below. Nothing is designed here. The
brief says *what* and *why*; GPT designs the *how* in step 2, cold, from this document.

`$1` is the slug: the Linear id when there is an issue (`ALL-646`), otherwise a short kebab-case
name. `$2` is the code repo, optional: the current git repo, or `superapp` when run inside
`superapp/harness`.

Not scored. Two independent sweeps here buy **coverage**, not agreement: the merge is a union. The
gate is the requester: they confirm the product brief before any research starts, and the step ends
when they confirm the brief.

**Paths.** Every bash block below starts by sourcing `harness/bin/codev-env.sh`, which prints one
line: `codev: slug=… results=<S> worktree=<WT> …`. In the prose, `<S>`, `<WT>` and `<H>` (the
`harness/` directory) mean those literal paths. Results land in `<S>` = the code repo's
`specs/$1/`, gitignored in superapp: in the **main** checkout, or, when this session runs in a
worktree of its own (`.claude/worktrees/<name>`, the Claude desktop app's default), in that
worktree, which is then `<WT>` too. The app lets such a session write nowhere else.

## 1a — The product brief, confirmed before anyone researches

Both researchers get the product brief and nothing else, and its user stories become the acceptance
criteria the plan and the build are held to. A mistake in it sends both sweeps the wrong way
**together**: independence protects against one model's blind spots, not against a wrong question.
So the requester confirms it first.

This part is product work, not engineering: who the change is for, what changes for them, whether
they are better off, and why the business wants it. Modules, routes and tables are for the sweeps.

1. **Collect the request**, verbatim and in the requester's language. They often dictate: read
   through speech-to-text slips and filler, but never turn a word into a different requirement; when
   a word can mean two things, ask. If the work has a Linear issue, take its title, description,
   comments, attachments and `gitBranchName` too (Linear MCP if connected, otherwise ask for them).
2. **Read the product, not the code**: what tells you about the users and what they see. The design
   handoff or prototype the request names, the app's product docs (`apps/<app>/docs/`: vision, FAQ,
   backlog), what its screens say today (`apps/<app>/client/src/i18n/locales/ru.json`), who gets
   what (`docs/ENTITLEMENTS.md`), and PostHog when how many people use something would change a
   story.
3. **Write the product brief** to `<S>/product.md` (the first two lines of any block below print
   `<S>`) from `<H>/briefs/PRODUCT.md`, in English. It is the request rewritten as the prompt the
   requester meant to write. **In short** comes first: what we want to achieve, for whom, and why
   now. Then the **user stories**, every criterion observable from the user's side and numbered
   (`US-1.1`). Then who it is for and what changes for them, whether they benefit and who could be
   worse off, the unhappy paths, the business side, and what is out of scope. Mark whatever you
   inferred rather than read or heard `(assumed)`. If no end user is better off (a refactor,
   infrastructure), say so and write the stories for whoever is: a story invented for a user who
   does not care misleads every later step. If nobody is better off, that is rung 1 of the ladder
   in `<H>/checklists/ponytail.md`: ask whether to build it at all.
4. **Ask** only what changes a story: what users should get, never where the code is. Ask in one
   round, each question with the answer you would assume, so that a yes settles it (AskUserQuestion
   for discrete choices). The answers go into the stories and under Questions and answers.
5. Agree three settings:
   - **Depth.** *quick*: a fix or a small change in a known place; Territory, Prior art, Tests and
     Scars, around the screens and flows the product brief names. *full*: a feature, or anything
     with real unknowns; all six sections, plus sources outside the repo.
   - **Branch.** Linear's `gitBranchName` when there is an issue. Otherwise the app's convention:
     `feat/focal-<slug>` for Focal (`apps/focal/CLAUDE.md`), `feature/<slug>` or `fix/<slug>`
     elsewhere. Every slug needs a branch of its own.
   - **Base.** `dev` for superapp.
6. **STOP** until the requester says yes to the product brief and the settings. Show In short, the
   stories with their criteria, and the settings in the chat; the whole document is
   `<S>/product.md`. If they only wanted the product brief, step 1 ends here. Otherwise start
   `<S>/brief.md` from `<H>/briefs/TEMPLATE.md` with its header filled in: `Branch:`, `Base:`,
   `Linear:`, `Depth:` and `Date:`, one per line, plain values with no backticks or bold.

Then create the worktree. It pins the tree that both sweeps read, that GPT plans against, and that
Opus builds in, so research, plan and code all describe the same commit. In a session with a
worktree of its own, the block moves that worktree onto the branch instead of adding one. It must be
clean (step 1's files do not count: `specs/` is gitignored), and the app's own `claude/…` branch
stays behind, unused:

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header || exit 1
mkdir -p "$S/research" "$S/reviews" "$S/runs"
if [ "$WT" = "$R" ]; then   # the session's own worktree (see codev-env.sh): move it onto the branch
  if [ "$(git -C "$WT" branch --show-current)" != "$BR" ]; then
    [ -z "$(git -C "$WT" status --porcelain)" ] || { echo "codev: $WT has uncommitted changes - commit or move them, then re-run"; exit 1; }
    git -C "$M" fetch origin "$BASE" --quiet || { echo "codev: cannot fetch origin/$BASE"; exit 1; }
    git -C "$M" fetch origin "refs/heads/$BR:refs/remotes/origin/$BR" --quiet 2>/dev/null   # the branch, if it already exists on origin
    if git -C "$M" show-ref --verify --quiet "refs/heads/$BR" || git -C "$M" show-ref --verify --quiet "refs/remotes/origin/$BR"; then
      git -C "$WT" switch "$BR" || exit 1                                          # existing branch: attach to it
    else
      git -C "$WT" switch --no-track -c "$BR" "origin/$BASE" || exit 1             # new branch from the remote tip
    fi
  fi
elif [ -d "$WT" ]; then
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
the sweep reaches you early. The wall runs the other way too: in a session with a worktree of its
own, `<S>` sits inside GPT's working directory, so keep your sweep in the scratchpad until GPT's run
has exited, and only then write `opus.md`.

**GPT**: read-only, in the worktree, web search on, the prompt read from a file and the final
message written by `-o`. Replace `<quick|full>` with the agreed depth. Run it **in the background**
(Bash `run_in_background`): a sweep outlasts the Bash tool's timeout.

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header && codev_need_worktree || exit 1
[ -s "$S/product.md" ] || { echo "codev: $S/product.md is missing - finish 1a first"; exit 1; }
P="$S/runs/brief-codex.prompt.md"
{ cat "$H/checklists/ponytail.md"
  printf '\n\nTHE PRODUCT BRIEF, as the requester confirmed it. It says what users should get and why; it is the question, not a design:\n\n'; cat "$S/product.md"
  cat <<EOF

DEPTH: <quick|full>. quick means sections 1, 2, 4 and 5 only, and only around the screens and flows the product brief names. full means all six sections.

You are GPT Codex on a reconnaissance sweep of the code repo in your working directory. You are NOT solving this request and NOT proposing a design: you are finding everything a planner would need to know before designing one. Work INDEPENDENTLY and from scratch: do not look for, assume, or defer to any other model's findings.
Sweep for: (1) TERRITORY - every module, route, table, migration, config and test the user stories plausibly touch, naming the story (US-n) each item serves, and every other place a user meets the same data or flow (another screen, another app's mount), since the change reaches it too. (2) PRIOR ART - code that already does part of this and should be reused instead of reinvented. Walk the ladder in the lens above and record each item with its rung number: 2 existing code in this repo, 3 the standard library, 4 a native platform or framework feature, 5 an already-installed dependency. If something already covers the whole intent, say so first. (3) CONSTRAINTS - pinned versions read from pyproject.toml, package.json and the lockfiles (name the file), contracts and interfaces this must not break, and the rules that govern this surface: read CLAUDE.md, AGENTS.md and the CLAUDE.md of the app involved, and state whether the change is AI-track code (semantic exoskeleton and LDD), needs a migration (sandbox proof), adds user-facing strings (i18next, ru and en), or crosses a tenant-isolation or RLS boundary; name the CI workflow (.github/workflows/ci-<app>.yml) whose jobs verify it. (4) SCARS - BUG_FIX_CONTEXT comments, recorded deviations, TODOs, ponytail: markers and past workarounds in the code this touches: what was already tried and why it failed. (5) TESTS - what covers this surface today, and what each test actually asserts versus what its name claims. (6) ABSENCES - invariants stated only in a comment with nothing enforcing them, configurable values whose worst legal setting is materially worse than the default, two concerns sharing one credential or limit, code paths with no test.
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

**Opus (you)**: the same product brief, the same depth, the same categories and rung numbers, reading
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
- **What users would meet that the product brief does not mention** (another screen or app that
  shows the same thing, data made before the change, a group of users it reaches) is a question for
  the requester; the answer amends `product.md`.
- **Gaps** (what neither sweep could establish) become open questions, each marked `UNVERIFIED` with
  what would close it.
- **Prior art that already covers the whole intent** (rungs 2 to 5: this repo, the standard library,
  the platform, an installed dependency) is a question for the requester: "X already does this.
  Still build?"
- **Sweep wide, report narrow.** A finding earns a place in the brief only if the planner could
  decide differently because of it. The raw sweeps stay in `research/` and are not pasted in.

## 1d — Write the brief, get the yes

Complete `<S>/brief.md` from the template, in English. Its Product brief section is
`<S>/product.md` below its header, pasted verbatim: the planner reads the brief alone. Its
Acceptance criteria are every story criterion by id, then any criterion the research added that no
story covers. Its Verification section names the jobs of `.github/workflows/ci-<app>.yml` for each
app the change touches: that is where superapp's real checks live.

**STOP.** Show the requester the Acceptance criteria, the Decided list, and every question the merge
produced. Their answers go into the brief, and those about what users get into `product.md` and the
brief's copy of it as well; no contradiction may stay open. Their yes ends step 1. Next:
`/step2 $1`.

If their answers change the product brief's In short or who it is for, rather than filling in a
story, go back to 1a: the sweeps answered a different question.

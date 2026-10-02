---
description: "Learn (weekly): checks every shipped hypothesis against what users did in PostHog, reads what is in demand; Opus and GPT judge independently, you confirm the verdicts"
argument-hint: [repo-path]
---

# Learn — the weekly hypothesis review  ·  Opus measures · Opus and GPT judge · you decide

The last step of the loop. `/step1` states a hypothesis, `/step2` makes it measurable, `/step3`
ships it and registers it in PostHog; `/learn` checks every registered hypothesis against what
users did, and reads the demand board for what is used and what is not. It runs weekly, from a
scheduled task or by hand. It reads, judges and proposes; it writes nothing to PostHog until the
requester says yes.

`$1` is the code repo, optional, as in the steps. Every bash block sources
`harness/bin/codev-env.sh` with the slug `learn-<today>`, so this run's files land in `<S>` = the
code repo's `specs/learn-<date>/`, gitignored; `<R>` is the code repo and `<H>` the `harness/`
directory.

Three rules hold throughout:

- **PostHog only, and read-only until the stop.** The numbers come from PostHog through its MCP.
  Never a database: superapp's rule against agents touching dev or prod databases holds here too,
  and PostHog holds what the review needs.
- **No verdict stands on one model.** Opus and GPT judge independently from the same data file;
  where they differ, the requester decides.
- **Small numbers stay small.** With about a hundred weekly users, most changes cannot reach
  statistical significance. Every number says how many people it rests on; *inconclusive* and
  *too early* are honest verdicts, not failures.

## L1 — What is registered

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "learn-$(date +%F)" "$1" || exit 1
mkdir -p "$S/runs" && echo "learn: $S"
```

Then find, through the PostHog MCP:

- the dashboard «Hypotheses — bets and demand» (`dashboards-get-all` with `search: "Hypotheses"`);
- every notebook titled `Hypothesis · …` (search `system.notebooks` with `execute-sql`, after the
  schema check the MCP asks for), and each one's header lines: Status, Branch, Released, Review
  after.

No dashboard means PostHog was never set up for the loop: stop and say so. No notebooks means no
bet has shipped yet: the review is the demand board alone.

## L2 — What reached users

For every `building` hypothesis, find whether its change reached prod: the merged PR into `main`
from `<branch>-main`, the promotion branch superapp's `CLAUDE.md` prescribes, or else one whose title
carries the slug.

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "learn-$(date +%F)" "$1" || exit 1
cd "$R" && gh pr list --base main --state merged --head "<branch>-main" --json number,title,mergedAt,url
```

Its `mergedAt` is the release date, and the window starts there. Note it for L6; write nothing yet.

## L3 — Measure

Write `<S>/data.md`, the one file both judges read:

- **Every live or newly released hypothesis:** its Hypothesis section verbatim; the signal since the
  release, and over the same span before it when the notebook has no baseline; the target; the days
  left in the window; and the query behind each number. Count people, and say how many.
- **Demand:** the board's tables this week against the last (`dashboard-insights-run`), the biggest
  movers, and the screens and actions nobody used.
- **Gaps:** an app that sends nothing (SURA, as of 2026-10-01), a signal whose event never arrived.

Query with the MCP's own tools (`insight-query`, `execute-sql`), each after the schema checks it
asks for.

## L4 — Two verdicts, independent

Start GPT first, then judge yourself. **Do not open `<S>/verdict-codex.md` until
`<S>/verdict-opus.md` is written**, and keep your verdict in the scratchpad until GPT's run has
exited: `<S>` may sit inside GPT's working directory. Run it **in the background** (Bash
`run_in_background`).

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "learn-$(date +%F)" "$1" || exit 1
[ -s "$S/data.md" ] || { echo "codev: $S/data.md is missing - finish L3 first"; exit 1; }
P="$S/runs/learn-codex.prompt.md"
{ printf 'THE DATA, as measured in PostHog:\n\n'; cat "$S/data.md"
  cat <<'EOF'

You are GPT Codex, judging product hypotheses against the data above, INDEPENDENTLY: do not look for, assume, or defer to any other model's verdict. The data above is all you have: do not run queries and do not read the repo.
For every hypothesis whose window has ended, give one verdict: VALIDATED (the signal reached its target), INVALIDATED (it clearly did not, or its "wrong if" result happened), or INCONCLUSIVE (too few people, a confound, or a signal that cannot carry the claim), with the number it rests on and how many people that number counts. For every hypothesis still inside its window: ON TRACK, OFF TRACK or TOO EARLY, with the same evidence. Then name the decision the hypothesis itself sets for that verdict (roll back, rework, keep, stop investing), and what would change your verdict.
Then read the demand data: what people use most, what they use less than before, what nobody uses, and up to three new bets the data suggests, each one sentence of the form "We believe that ... for ... will ...".
Never claim a significance the numbers cannot carry; with about a hundred weekly users, say so. Your FINAL message must be the review in Markdown, one section per hypothesis and one for demand, and nothing else.
EOF
} > "$P"
cd "$R" && codex exec --sandbox read-only -o "$S/verdict-codex.md" - < "$P" > "$S/runs/learn-codex.log" 2>&1
echo "codex exit=$?  verdict bytes=$(wc -c < "$S/verdict-codex.md" 2>/dev/null || echo 0)"
```

- An empty verdict or a non-zero exit is a failed run: read `<S>/runs/learn-codex.log`. If
  `codex exec` fails auth, say so in L5 and present Opus's verdict alone, marked as one model's.

**Opus (you)**: the same data, the same verdicts and the same rules, written to
`<S>/verdict-opus.md`.

## L5 — The requester decides

Merge the two: where the verdicts agree, propose that verdict; where they differ, show both with
their reasons. **STOP** and show the requester, per hypothesis, the signal, its target, the value,
how many people it rests on, both verdicts and the decision each proposes; then the demand summary
and the new bets. A scheduled run ends its turn here, and the requester answers in that session.
Their answers are final.

## L6 — Record

On the yes, and only then, write to PostHog:

- every newly released hypothesis: an annotation `<slug> released` at its release date, and in its
  notebook Status `live`, Released and Review after;
- every judged hypothesis: a row in its notebook's Verdict log (date, value and people, target,
  verdict, decision) and its new Status;
- one review notebook, `Hypothesis review · <date>`: the verdict table, the demand summary, and the
  bets the requester chose to take.

Then offer `/step1` for each new bet the requester wants to pursue.

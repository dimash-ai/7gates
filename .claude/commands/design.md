---
description: "Design (between step 1 and step 2): a fast hi-fi HTML prototype of what users will see, opened on your machine; the one stop before code: you confirm the brief and the design, then step 2 plans against it and nothing else waits for you until the release to main"
argument-hint: <slug> [repo-path]
---

# Design — draw it first  ·  Opus draws · you look locally · then development

Between step 1 and step 2 of the **co-dev flow** (`harness/README-codev.md`). Step 1 named what to
do and its MVP; this step **draws it**: a hi-fi HTML prototype of the screens and states users will
see, opened on the requester's machine. The requester looks at it and says ok, or what to change,
and **only their ok starts development** (`<H>/checklists/mvp.md` §11, their decision of
2026-10-09). This is the flow's **one stop before code**: after it, step 2 plans against the
confirmed design and step 3 builds and ships to dev, and nothing waits for the requester until the
release to main.

It runs when the brief's header says `Design: html` (draw a prototype) or `Design: handoff <path>`
(a PM design exists: show it). With `Design: none` (nothing users see changes) step 1 goes straight
to `/step2`, and this step does not run.

**Fast by design: about half an hour to the first look**, Opus alone: no second model, no
subagents, no plan, no branch, no app code. If ultracode or a high effort is on, do not spend it
here.

`$1` is the slug; `$2` is the code repo, optional. Every bash block sources
`harness/bin/codev-env.sh`, which prints `codev: slug=… results=<S> …`; `<S>` and `<H>` (the
`harness/` directory) mean those literal paths. Link a file to the requester as a markdown link
relative to the session's working directory, usually `[index.html](specs/$1/design/index.html)`,
never as a bare path.

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header || exit 1
mkdir -p "$S/design" "$S/reviews"
echo "design: ${DESIGN:-none}"; ls "$S/design"; ls "$S"/reviews/design-*.md 2>/dev/null || echo "no design approval yet"
```

## D1 — Draw it (`Design: html`)

Write `<S>/design/index.html`: **one self-contained file** (inline CSS and JS; fonts and images by a
relative path inside `<S>/design/`) that opens from disk in any browser, with no build, no network
and no backend. It is a picture of the product, not production code: it imports nothing from the
app and never ships.

- **Hi-fi, on the product's own look.** Read the screens the change touches (their components) and
  the app's stylesheet (`apps/<app>/client/src/index.css`), and use the CSS variables and fonts those
  screens use, so the prototype shows them as they look today, with the change in place. For SURA,
  the prototype kit in `apps/sura/prototype/` has the tokens (`colors_and_type.css`), the fonts and a
  phone frame (`ios-frame.js`).
- **Every state the MVP needs** (filled, empty, error, loading, a sheet open and closed, as the
  brief's stories have them), switched from a small fixed panel on the page. Desktop and phone width
  when the app has both.
- **The real words.** Every string users will see, in Russian as the app shows it, ready to go into
  `ru.json`.
- **The whole idea, the first part marked.** Draw the MVP's screens and states. Where the brief has
  [later] stories on the same screens, draw them too, with a «Later» badge, so the requester sees
  where the design goes and which part is stage 1. Draw nothing nobody asked for.

Then write `<S>/design/README.md`, under about 40 lines: the screens and states, each marked MVP or
Later; what the design decided that the brief left open; what stays open.

## D1h — Show the handoff (`Design: handoff <path>`)

The PM's design is the design: do not draw another. Read its README and spec, and write
`<S>/design/README.md`: which of its screens and states stage 1 (the brief's MVP) covers and which
come later, with the switches of its own panel that show each, and every gap between the brief and
the handoff, one line each.

## D2 — Open it on the requester's machine

`open "<S>/design/index.html"` (for a handoff, its HTML file) opens it in the requester's default
browser; link it too. Do not walk it yourself first, and do not wait for screenshots.

## D3 — The one stop: the requester confirms the brief and the design

Show in the chat, briefly: the brief in short (In short, the MVP, Not now, the assumptions, the
lane), since step 1 went on without stopping; the screens and states, MVP and Later; the link. Then
ask in one round (AskUserQuestion), one question: **the design and the brief**: ok, or what to
change.

- **A change**: make it in the prototype, and in the brief when it moves the MVP or Not now; open it
  again (D2) and ask again. A round takes about ten minutes. Nothing is planned or built while the
  design is open.
- **Ok**: record the approval and set `Ship: none` in the brief's header (the block below): after the
  requester's ok on the design nothing waits for them until the release to main (`mvp.md` §10). Then
  start step 2 at once: invoke `/step2 $1` yourself with the Skill tool, the slug as its only
  argument. Do not wait for the requester to type it.

```bash
H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
. "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
codev_need_header || exit 1
V="$S/reviews/design-$(( $(ls "$S"/reviews/design-*.md 2>/dev/null | wc -l) + 1 )).md"
printf '# Design approval\n\nReviewer: the requester\nStep: design\nStatus: APPROVED\n\n## Reason\n%s: the requester confirmed the brief and the design (%s) at the stop.\n' "$(date '+%Y-%m-%d %H:%M')" "$(ls "$S/design" | tr '\n' ' ')" > "$V" && echo "recorded: $V"
perl -pi -e 's/^Ship:.*$/Ship: none/' "$S/brief.md" && grep '^Ship:' "$S/brief.md"
```

**When the design changes later** (dev showed something, the requester wants more), change the
prototype and run this step again for the new part; its approval re-plans only the stages not yet
started (`/step2 $1`).

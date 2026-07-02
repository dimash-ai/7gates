# Findings: focal-calendar-dnd (drag-to-move broken on the new calendar)

> Output of the **explore gate** (`/gate-explore focal-calendar-dnd`). Two independent takes — Opus
> and GPT — synthesized. Raw per-model answers in `.ai/scratch/focal-calendar-dnd-{opus,gpt}.md`
> (gitignored). Not scored. Date: 2026-06-29.

**Symptom:** on the week view the user hovers a timed event; the cursor stays a plain arrow (not
`grab`) and the event cannot be dragged to move. Should behave like Google Calendar / old-focal.

> **RESOLUTION (2026-06-29, after synthesis): already fixed upstream — no build needed.** The
> diagnosis below is correct, but the analysis ran against a **stale checkout** (`superapp` detached
> at `e7871ae`, 7 commits behind `feature/focal-migration`). The integration branch (`bb5e885`,
> pushed to origin) already carries the exact fix: **#127 "Pin calendar event blocks to
> position:absolute inline so hover-elevate's relative rule can't drop them below the hour grid"**
> adds `position: 'absolute'` to `EventBlock`'s style (`apps/focal/client/src/features/calendar/EventBlock.tsx`),
> matching this note's recommended fix 1:1. The live focal-dev bundle (`index-B9lcRwjA.js`) already
> includes it (it carries #128's `focal.calendar.undo.button`, which lands right after #127). The
> screenshot was a pre-#127 build (#127/#128 committed 02:14; screenshot 02:32). **Action: hard-refresh
> / update the PWA on focal-dev and re-test — no 3-gate pipeline required.** (Also landed on the same
> branch and noted in FRONTEND_PARITY.md: #122 variable-height grid, #125 drag-to-create, #126
> task-panel drag, #128 undo.)

## Questions

1. Root cause: why is the event block not draggable and showing an arrow cursor, given `canEdit` is true and the drag code is present?
2. Is the `hover-elevate` CSS footgun (forces `position:relative; z-index:0`, overriding the block's `absolute`/`z-[3]`) the cause — vs permissions, vs an overlay, vs a stale deploy?
3. Minimal fix to restore drag-to-move (and edge-resize)?
4. Fastest decisive confirmation?

## Consensus

> Both models agree.

- **Not permissions, not a stale deploy.** `canEdit` is **true** on the main calendar — the "Новое
  событие" button is `disabled={!canEdit}` yet renders enabled, and the read-only banner is absent
  (`features/calendar/CalendarPage.tsx:885`, `:961`; rights at `features/calendars/CalendarFilterContext.tsx:175`).
  The drag code (`setPointerCapture`, `grabbing`, `resize-top/bottom`, `data-day-column`) is present in
  the live `focal-dev` bundle. Confidence: **High**.
- **Root cause: the `hover-elevate` footgun on the event `<button>`.** `EventBlock` puts the drag
  handlers, inline `cursor:grab`, AND `className="hover-elevate absolute z-[3]"` on the **same** node,
  with **no inline `position`/`zIndex`** (`features/calendar/EventBlock.tsx:293-298,341-364`). The
  rule `.hover-elevate:not(.no-default-hover-elevate){position:relative;z-index:0}`
  (`src/index.css:390-396`) is in the **same `@layer utilities`** as `.absolute`/`.z-[3]` but has
  higher specificity ((0,2,0) > (0,1,0)), so it overrides them. That corrupts the block's
  positioning/stacking so it is **not the topmost hit-test target** — hence the arrow cursor (the
  inline `grab` never wins) and no drag. The `::after` overlay is `pointer-events:none`
  (`index.css:398-408`), so it is not itself the blocker. Confidence: **High** (GPT) / **Medium** (Opus — see Open).
- **Why old-focal worked (regression mechanism).** Old-focal kept the **absolute positioned wrapper
  on a separate node** from the `hover-elevate cursor-grab` visual node, with resize handles as
  separate siblings (`apps/old-focal/.../CalendarViews.tsx:1240,1271,1331`). New Focal collapsed both
  responsibilities onto one `<button>` — that is the regression. Confidence: **High**.
- **Fix shape.** Stop `hover-elevate` from owning the positioned node. Restores edge-resize too (same
  node/stacking). Confidence: **High**.
- **Decisive check.** `document.elementFromPoint(cx, cy)` at an event's center + `getComputedStyle`
  of the block — expect the hit target to be NOT the event button and/or `position:relative; z-index:0`.
  Confidence: **High**.

## Divergence

- **How to fix (minimal vs structural)**
  - Opus: minimal — add inline `position:'absolute'` + `zIndex:3` to `EventBlock`'s `style` object
    (inline beats the class; ghost/resize already bump `zIndex` to 30). Smallest diff.
  - GPT: prefer matching old-focal — an **outer absolute wrapper/button** for positioning + gesture,
    an **inner `hover-elevate`** visual layer (handles as separate siblings). More robust; avoids the
    footgun by construction rather than patching around it.
  - **Decision needed:** ship the 2-line inline-position patch now, or do the small structural split.
    Recommendation: inline patch first (unblocks users immediately + is the documented prior fix),
    then optionally adopt the separate-node structure as cleanup. They are not mutually exclusive.
- **Confidence the footgun is the *whole* story:** GPT High; Opus Medium — because of the Open item.

## Open

- **Positioning tension.** If `position:relative` were *fully* applied, the event blocks (the last
  flow children after 24 in-flow hour buttons ≈ 1152px) would render ~1150px too low — but the
  screenshot shows them at correct times. So either the override is only *partially* active
  (e.g. `z-index:0`/stacking lands but `position` resolves to `absolute` via a Tailwind v4 cascade
  nuance) or a different overlay is the live hit target. **To close:** run on the open page —
  ```js
  const el=document.querySelector('[data-day-column] button.hover-elevate');
  const c=getComputedStyle(el), r=el.getBoundingClientRect();
  const hit=document.elementFromPoint(r.left+r.width/2, r.top+Math.min(20,r.height/2));
  ({position:c.position, zIndex:c.zIndex, cursor:c.cursor,
    hitIsEvent: hit===el||el.contains(hit), hitTag:hit?.tagName,
    hitClass:(hit?.className||'').toString().slice(0,90)})
  ```
  `position:relative`/`zIndex:0` ⇒ footgun confirmed. `hitIsEvent:false` ⇒ read `hitTag`/`hitClass`
  for the real interceptor.

## Next

- Confirm with the snippet, then ship a fix slice (e.g. `feat/focal-calendar-event-hit-target`):
  inline `position:'absolute'`/`zIndex` on `EventBlock` (and/or the separate-node structure), add a
  Vitest/Playwright guard that a calendar event is the `elementFromPoint` hit target and drag-to-move
  fires `onMove`. Related: this same `hover-elevate`-on-absolute footgun is worth grepping for on
  other absolutely-positioned elements (booking chips, popovers).

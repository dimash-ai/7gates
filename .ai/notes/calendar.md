# Findings: calendar (migration fidelity — old-focal → new focal)

> Output of the **explore gate** (`/gate-explore calendar`). Two independent takes — Opus and GPT —
> synthesized. Small and findings-first; raw per-model answers in `.ai/scratch/` (gitignored).
> Not scored. Date: 2026-06-27.

Trigger: user compared screenshots — old-focal calendar (`focal.allosta.com`, **3-day view**) vs
new-focal (`localhost:5173/calendar`, **month view**) vs Google Calendar (the reference they like) —
and asked "are we sure we migrated the calendar page correctly?"

## Questions

1. Is the new-focal calendar a correct/complete migration of old-focal, or incomplete / regressed?
2. For each visible delta — intentional redesign, a tracked-deferred parity gap, or an untracked gap?
3. Is the missing CRM-interactions panel tracked anywhere, or untracked?
4. What is genuinely at risk of being silently lost?

## Consensus

> Both models reached these independently. High confidence unless noted.

- **"Looks different" ≠ "migrated wrong." It's a deliberate re-skin + a *sliced* parity backlog that's
  mid-flight — not a broken port.** Old-focal's calendar was a dense planning-hub (events + tasks + CRM
  + voice + year/bookings + undo on one page); new-focal is a narrower, Google-Calendar-style event
  surface with a scaffolded left rail. The two screenshots also compare **different views** (old 3-day
  time-grid vs new month grid), which exaggerates the gap — switch new-focal to 3-day and it's far
  closer. The polish that *did* ship (slice 6: scroll-to-now, mini-month dots, color-by-project,
  location+priority, loading/empty, all-day row) is verified at parity. Evidence:
  `focal-parity-calendar-handoff.md:7-20` (APPROVED 9.4 = commit `d9f9549`/PR #101); the ~15-gap audit
  `focal-parity-calendar-design.md:9`; `.ai/think/focal-parity.md:132-135`. Confidence: High.

- **Per-delta classification (both models agree):**

  | Old→new delta | Verdict | Evidence |
  |---|---|---|
  | **Year view (Г) gone** | tracked-deferred (year+bookings slice) | `focal-parity-calendar-design.md:107-108`; `.ai/think/focal-redesign-calendar-views.md:22-24`; old `Calendar.tsx:103,2727-2734` |
  | View toggles 5 letters → 4 words | intentional redesign | new `CalendarPage.tsx:44-51` |
  | **"Новое событие" button gone** | intentional; creation at parity via slot-click → popover (editor shipped slice 5) | new `CalendarPage.tsx:270-277`; `focal-redesign-calendar-popover-design.md:17-20`; old `Calendar.tsx:3212-3224` |
  | **Tasks side panel gone** | tracked-deferred | reserved region `CalendarPage.tsx:461-465`; `.ai/tasks/focal-redesign-calendar.md:61-64`; `.ai/think/focal-parity.md:132-134` |
  | **Voice control gone** | tracked-deferred — deliberately replaced by a button → `/aichat`; full voice = `focal-parity-ai-assistant` slice | `.ai/think/focal-parity.md:31-33,156-158`; old `Calendar.tsx:3270-3278,3375-3398` |
  | Sparse rail / "floating" mini-month | as-designed symptom (rail holds only mini-month + the empty reserved side-panel region) | `CalendarPage.tsx:461-465`; `focal-redesign-calendar-views-design.md:21-24` |
  | Personal CRM nav gone | present in code, **config+permission gated** (`VITE_PRIMA_URL` + `canViewOtherPages`); likely unset in local dev | new `AppSidebar.tsx:166-168,264-278` |
  | "Календари" → "Общие календари" | intentional rename | `ru.json:275-276` vs old `ru.json:65` |
  | Timezone "Almaty" label gone | intentional: new selector is **icon-only** (vs old `shortLabel`); tz-into-grid behavior separately deferred | new `TimezoneSelector.tsx:189-195`, `PageToolbar.tsx:53`; `focal-parity-calendar-design.md:103-106` |
  | Drag move/resize/create | tracked-deferred (needs dnd-kit) | `focal-parity-calendar-design.md:99-102` |

- **The CRM-interactions panel is the one UNTRACKED delta.** Old-focal renders a `CrmInteractions`
  left-rail feed of recent calls/meetings/messages (`old Calendar.tsx:3247-3252`,
  `CrmInteractions.tsx:98-103`). The CRM *boundary* is tracked — `/api/interactions` is relocated to
  PRIMA under the `crm-boundary` ADR (`apps/focal/docs/contract-freeze/make_routes_inventory.py:24-26`,
  `_tables_mapping.py:81-90`), and new-focal ships per-event PRIMA contact picking
  (`CalendarPage.tsx:212-215`, `primaContacts.ts`). But the **left-rail interactions panel itself is in
  no calendar design/think/handoff/tasks doc** (grep empty). Confidence: High it's untracked; the *why*
  (intentional retirement vs oversight) is unknown.

- **Main silent-loss risk = the CRM-interactions rail.** Everything else is tracked-deferred, gated, or
  shipped; only this panel is "neither implemented nor clearly deferred as a calendar UI surface." High.

## Divergence

- **Framing: "incomplete" vs "deliberate/tracked" — same facts, opposite emphasis.**
  - GPT led: *"incomplete migration / partially correct slice implementation."*
  - Opus led: *"correct-and-deliberate, not broken — just mid-backlog."*
  - **Decision needed (the real one underneath):** are all the *tracked* deferrals acceptable
    **pre-cutover**, or do some (year view? tasks panel? voice?) block the flip? This is exactly the
    `focal-migration-assessment.md` open item "ALL-204 → which parity slices are pre-flip vs post-flip."
    Only the user/Linear can draw that line.

## Open

> Neither model could close these from the repo alone.

- **CRM-interactions panel disposition** — intentionally retired (CRM now lives in PRIMA / per-event
  ContactPicker) or an oversight? To close: a one-line product call — if retired, write it into the
  parity epic / crm-boundary ADR so it's not "lost silently"; if wanted, add a backlog slice.
- **New month shows 0 events while GCal shows events** — almost certainly local-dev seeding / Google-sync
  state for this user+window (the Personal-CRM env is also unset locally), **not** a calendar-page
  migration defect. To close: confirm the dev instance is seeded / Google-synced for the demo user in
  that window. (Aside — separate from the UI migration question.)
- **Explicit "New event" button** — decide if the convenience button is wanted (creation already works
  via grid-click → popover).

## Round 2 — user priorities (2026-06-27, tool-verified by code read)

> The user named three must-haves: **event creation, task creation, a year view**. Verified directly
> against the new client (factual "does it exist" checks, not a new two-model round).

- **✅ Event creation EXISTS — and every old-dialog field exists — but it's SPLIT.** Calendar grid-click
  opens a lean Google-Calendar-style `EventPopover` (title, date, start/end, project→product→activity,
  recurrence, color, CRM contacts — `EventPopover.tsx:145-378`). The FULL old-focal field set
  (description, **location**, **event timezone**, **tags**+inline-create, **other participants**, status)
  lives in the Events-page `EventDialog` (`EventDialog.tsx:62-65,276-296,386-419,529-535`). Nothing lost;
  reorganized. **Decision:** is the split OK, or should the calendar quick-create carry the full field
  set (one dialog, like old focal)?
- **✅ Task creation EXISTS at full parity (superset).** `TaskDialog` has title, due date, due time,
  project→product→activity, tags+inline-create+color, notes, recurrence, participants (Из CRM / Другие),
  plus a **task→event "schedule as event"** convert (`TaskDialog.tsx:348-644`); reached from the Tasks
  page "new task" action (`TasksPage.tsx:375-376`). Caveat: CRM-contact *linking* is UI-only pending the
  crm-boundary `external_contacts` field — free-text "Другие" persists (`TaskDialog.tsx:151-154`). Only
  the embedded task panel ON the calendar is deferred — not task creation itself.
- **❌ Year view NOT built — the one genuine gap of the three.** Tracked-deferred, bundled with bookings
  ("year view is meaningless without bookings; the API returns `bookings` but the calendar never fetches
  them") — `focal-parity-calendar-design.md:107-108`. Needs its own slice.

**Net:** two of three priorities already ship (events + tasks); only the **year view** is actually
missing. Open product calls: (a) the event-create field-set split; (b) whether to add explicit
"Новое событие"/"Новая задача" buttons (old focal had prominent ones; new relies on grid-click / page
actions); (c) prioritize building the year view (+ bookings).

**Decision (user, 2026-06-27):** keep the existing split; **add explicit create buttons** on the
calendar like old focal ("Новое событие" + "Новая задача"); **build a year view**. CRM = **PRIMA**
(`apps/prima`) — the create dialogs' "Из CRM" `ContactPicker` already pulls PRIMA contacts
(`primaContacts.ts`); only persisting the link awaits the crm-boundary `external_contacts` field.
→ Two follow-up `focal-parity-calendar` slices: (A) calendar create buttons, (B) year view.

**Slice A status (2026-06-27): SHIPPED to PR.** 3-gate flow — Gate A design APPROVED 9.1, Gate B build
APPROVED 9.4 (task button) + 9.4 (event button), Gate C verify APPROVED 9.4 (fresh-context Opus release
gate; suite green 1072 tests). PR [#103](https://github.com/Allosta-Group/superapp/pull/103)
(`feat/focal-parity-calendar-buttons` → `feature/focal-migration`).

**Slice B status (2026-06-27): SHIPPED to PR.** 3-gate flow — Gate A design APPROVED 9.2, Gate B build
APPROVED 9.2, Gate C verify APPROVED 9.4 (fresh-context Opus release gate; suite green 1076 tests). The
lightweight 12-month event-density **year navigator** (windowFor('year') + new YearView + monthCells
adopted by MiniMonth); the **bookings** layer of old-focal's booking-centric year view is a deferred
follow-up. PR [#104](https://github.com/Allosta-Group/superapp/pull/104)
(`feat/focal-parity-calendar-year` → `feature/focal-migration`).

## Next

- Settle the **CRM-interactions panel** disposition (the only untracked item) and record it.
- **Year view + bookings** is the one real gap behind the user's must-haves — candidate for its own
  `/gate-design` slice (year view + the bookings fetch it depends on).
- Fold the calendar deferrals into the cutover **pre-flip vs post-flip** mapping — links straight to the
  open item in `.ai/notes/focal-migration-assessment.md`.

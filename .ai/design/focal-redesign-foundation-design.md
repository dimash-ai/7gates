# Design summary

Bring the Focal client onto the prototype's design language by (1) completing the **token bridge** in
`index.css` — re-anchoring shadcn semantic tokens to the Focal palette and **adding** the few semantic
tokens the prototype needs that shadcn never named — then (2) restyling the **shell** and **shared
primitives** against those tokens. The one decision everything hinges on: **keep the shadcn token
names and the primitives' public APIs; change only token *values* and component *class strings* (+
non-breaking variant aliases).** Inspection shows the bridge is already ~80% correct (the brand blue,
coral, green, and amber anchors are present; radius/shadow/fonts/`.dark` already match), so the slice
is small: the net-new is the state tokens + the surface split + the visual restyle. Traces to the
approved think doc (bridge strategy, 1:1 language, foundation-first) and plan (6 slices).

# Architecture

Pure **frontend, visual-only**. No server, API, data, routing, or state-ownership change. Component
graph and behavior are untouched:

```
index.css  (token source of truth — the bridge lives here, documented once)
   │  CSS custom properties (shadcn names ← Focal values) + @theme inline
   ▼
ui/* primitives (button, badge, card, input, textarea, select, dropdown-menu,
   │              popover, dialog, sheet, tooltip, sidebar)  ← class-only restyle
   ▼
shell (AppShell, AppSidebar, CalendarSwitcher, PageHeader, PageToolbar)  ← class-only restyle
   ▼
feature screens (OUT OF SCOPE — inherit the new tokens/primitives unchanged)
```

Ownership stays put: `SidebarProvider` owns collapse/mobile state + its localStorage; `AppSidebar`
owns nav rendering + the `me`/meeting-count queries + dashboard gating; `PageToolbar` owns
theme/language/AI handlers via existing hooks; Radix primitives keep their state machines and a11y —
this slice changes their **class names** only.

**Brand mark:** the prototype's `focal-app-icon.svg` (rounded brand-blue square + white "F" + brand-
green dot) is reproduced as an **inline SVG** inside `AppSidebar`, using the canonical logo hexes
`#407be9` / `#1baf73`. This refines the plan's slice-4 wording ("use the existing public app
icon/favicon"): the app's only brand assets in `public/` are **raster PNGs** (`favicon.png`,
`icons/icon-*.png`, `apple-touch-icon.png`) sized for browser tabs / PWA install — there is **no
scalable lockup**, and embedding a raster favicon in the 34px sidebar mark would look soft and off-
brand. An inline SVG matches the prototype 1:1 at any size, themes cleanly, and adds **no** `public/`
asset (which the plan lists out of scope) — so it satisfies both the fidelity bar and the no-new-asset
constraint. Replaced as an alternative below.

# Data model

| entity | change | notes |
|--------|--------|-------|
| — | None | Frontend visual slice; no persistent state, tables, or migrations. |

# Interfaces & contracts

## A. Token bridge (`src/index.css`) — shadcn name ← Focal value

**Already correct — keep, do not churn** (verified against `colors_and_type.css` LAYER 1):

| shadcn token | current triplet | Focal source | anchor |
|---|---|---|---|
| `--primary` / `--ring` / `--sidebar-primary` | `219 79% 58%` | `focal-blue-500` | `#407be9` ✓ |
| `--destructive` (light) | `0 84% 60%` | `focal-coral-500` | `#ef4444` ✓ |
| `--radius-sm/md/lg/xl` | `0.5/0.75/1/1.25rem` | prototype radii | 8/12/16/20px ✓ |
| `--shadow-xs…lg`, fonts, `.dark` class, `hover/active-elevate` | present | prototype | ✓ keep |

**Re-anchor (align neutrals + surfaces to the prototype's canvas/surface/sunken stack):**

| shadcn token | → Focal source (light / dark) | intent |
|---|---|---|
| `--background` | canvas `#ffffff` / sand-950 `#0e0e12` | page canvas = pure white (prototype `--color-bg-canvas`) |
| `--card`, `--popover` | raised `#ffffff` / sand-800 `#27272f` | raised surface |
| `--sidebar` | surface sand-50 `#fafaf9` / sand-900 `#18181d` | warm off-white rail |
| `--secondary`, `--muted` | subtle sand-100 `#f4f4f2` (`60 9% 96%`) / sand-900 `#18181d` (`240 9% 10%`) | subtle fills (secondary btn, muted bg) — the *surface* level, not the sunken well |
| `--accent` (menu/ghost focus+hover) | sand-200 `#e7e6e2` (`48 9% 90%`) / sand-700 `#3f3f46` (`240 6% 26%`) | focus/hover highlight — **one step off the surface** so focused dropdown/select items stay visible (dark menu surface is sand-800; this is lighter) |
| `--sidebar-accent` (active nav row) | sand-100 `#f4f4f2` (`60 9% 96%`) / `#0a0a0d` (`240 13% 4%`) | active nav row = `--surface-sunken`, matching the prototype (`Shell.jsx:7-8`); hover layers the `hover-elevate` overlay on top so hover ≠ active |
| `--border` | sand-200 `#e7e6e2` (`48 9% 90%`) / `240 9% 17%` | subtle hairlines (cards, dividers) = prototype `--color-border-subtle` |
| `--input` | sand-300 `#d1d0ca` (`48 7% 81%`) / `240 5% 26%` | field borders = prototype `--color-border-default` (`colors_and_type.css:208`), stronger than `--border` (already `51 7% 81%` today) |
| `--muted-foreground` | sand-700 `#3f3f46` (`240 5% 27%`) / sand-300 `#d1d0ca` (`48 6% 81%`) | muted text |
| `--destructive` (dark) | coral-400 `#f87171` = `0 91% 71%` | dark danger |

> **Every row in this table is an opaque HSL triplet** (e.g. `60 9% 96%`), consumed as
> `hsl(var(--token))`, so Tailwind alpha utilities (`bg-primary/10`, `border-yellow-950/30`) keep
> resolving. The Allosta *translucent-on-dark* borders/surfaces (`rgba(255,255,255,.06–.12)` in the
> prototype) are **approximated by opaque dark-gray triplets** — exactly what the current `.dark` theme
> already ships (`--border: 240 9% 17%`, `--input: 240 5% 26%`) — **never** an `rgba()` value in a
> triplet slot (which would compile to an invalid `hsl(rgba(...))`). Each anchor gets a one-line comment
> tying it to the prototype hex; the raw Focal scales (blue/green/sand/amber/coral 50–950) are added as
> commented **hex** CSS variables (e.g. `--focal-green-700: #11724b`) — the *source* the semantic HSL
> triplets derive from, and directly referenceable for exact-shade needs (e.g. subtle badge foregrounds)
> via `text-[var(--focal-green-700)]`, so no component hardcodes a hex.

**Add — the net-new semantic tokens** (state, surface split, accent-subtle, overlay, motion), each
mapped through `@theme inline` to a `--color-*` Tailwind utility + `:root`/`.dark` triplets:

| new token | light | dark | source / use |
|---|---|---|---|
| `--success` / `--success-foreground` | `156 73% 40%` (green-500 `#1baf73`) / white | `156 57% 48%` (green-400 `#34c089`) | success states, completed |
| `--warning` / `--warning-foreground` | `38 92% 50%` (amber-500 `#f59e0b`) / sand-900 | `43 96% 56%` (amber-400 `#fbbf24`) | warnings |
| `--info` / `--info-foreground` | `219 79% 58%` (= primary) / white | blue-400 `#5e8aff` | informational |
| `--surface-raised` | raised `#ffffff` (`0 0% 100%`) | sand-800 `#27272f` (`240 9% 17%`) | raised panels/cards/menus — prototype `--color-bg-surface-raised`; shares the `--card` value, named for shell use (`bg-surface-raised`) |
| `--surface-sunken` | sand-100 `#f4f4f2` (`60 9% 96%`) | **`#0a0a0d` (`240 13% 4%`) — deepest well, below canvas** | inset wells / active rows — prototype `--color-bg-surface-sunken` (`colors_and_type.css:254`); light shares the `--muted` value, dark diverges to the deepest level, so it is its own token (`bg-surface-sunken`) |
| `--accent-subtle` (complete color, both modes) | blue-50 `#eef4ff` | `rgba(64,123,233,0.16)` | icon badge, active-nav tint — consumed directly (`bg-accent-subtle`), never with an alpha suffix |
| `--overlay` (complete color, both modes) | `rgba(15,17,22,0.55)` | `rgba(0,0,0,0.6)` | dialog/sheet scrim |
| `--shadow-xl` | `0 16px 40px -12px rgb(0 0 0/.14)` | darker | dialog elevation |
| `--ease-out` / `--ease-in-out` | `cubic-bezier(.16,1,.3,1)` / `(.4,0,.2,1)` | same | motion |
| `--duration-fast/default/slow` | `160/240/360ms` | same | motion |

> **Dark surface hierarchy (authoritative, `colors_and_type.css:251-254`)** — darkest → lightest:
> `--surface-sunken` `#0a0a0d` (`240 13% 4%`) < `--background` canvas sand-950 `#0e0e12` (`240 12% 6%`)
> < `--sidebar` + `--secondary`/`--muted` surface sand-900 `#18181d` (`240 9% 10%`) < `--card`/`--popover`
> + `--surface-raised` raised sand-800 `#27272f` (`240 9% 17%`). The sunken well is **below** the canvas;
> raised cards/menus are the lightest surface. **Interactive-state tints sit off this surface stack:**
> `--accent` (menu/ghost focus+hover) is sand-700 `#3f3f46` — a step **lighter** than the sand-800 menu
> surface so focus is visible; `--sidebar-accent` (active nav) = `--surface-sunken` `#0a0a0d`. (Light mode
> mirrors: canvas/raised `#fff` lightest, sunken sand-100 the darkest fill, `--accent` sand-200.)
>
> **Color representation — two buckets, no mixing** (the build follows this split exactly):
> 1. **Core color tokens** — every shadcn-consumed token in both tables above (background, foreground,
>    primary, secondary, muted, accent, border, input, ring, card, popover, destructive, sidebar\*) and
>    the new **success / warning / info + their foregrounds** and **`--surface-raised` /
>    `--surface-sunken`**: **opaque, bare HSL triplets**
>    (`219 79% 58%`), each mapped `--color-x: hsl(var(--x))` in `@theme inline`. This is what lets
>    Tailwind alpha utilities (`bg-primary/10`, `bg-success/15`) resolve. (success/warning/info values
>    already exist as `--chart-2/3/1`; the new tokens just give them semantic names — no color is
>    invented.)
> 2. **Standalone translucent tokens** — `--accent-subtle` and `--overlay`: **complete color values**
>    in *both* light and dark (`#eef4ff`, `rgba(...)`), each mapped **directly** `--color-x: var(--x)`
>    (never wrapped in `hsl(var())`, since an alpha value cannot pass through it), and consumed as plain
>    utilities (`bg-accent-subtle`, the dialog scrim) — **never** with an alpha suffix.
>
> No core token ever holds an `rgba()`; no standalone token is ever wrapped in `hsl(var())`.

## B. Primitive variant contracts (non-breaking — add, never rename)

- **Shared focus ring (all interactive primitives)** — reproduce the prototype `.ds-focus-ring` (2px
  accent outline + 2px offset). Standard class set:
  `focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2
  focus-visible:ring-offset-background` (`--ring` = brand blue). Applies to `button` (replaces its
  current `ring-1`), `input` / `textarea` (replaces the `border-ring`-only treatment), the `select`
  trigger, the dialog/sheet close buttons, and the tooltip/dropdown **triggers**. Radix menu/select
  **items** keep their `bg-accent` focus highlight (their idiomatic focus state); only focusable
  triggers take the ring. Visible focus must never be removed — only restyled.
- **Button** (`ui/button.tsx`): keep `default | destructive | outline | secondary | ghost` and the
  `default | sm | lg | icon` sizes (heights 36/32/40/36 already match the prototype). **Add** alias
  `primary` (= `default`) and a new **`ai`** variant — raised surface bg, violet text/border
  (`text-violet-600 border-violet-300` light, `dark:text-violet-400 dark:border-violet-800`),
  reproducing the prototype `ai` button. Keep `hover-elevate active-elevate-2` + `rounded-md` (12px).
- **Badge** (`ui/badge.tsx`): keep the existing **filled** `default | secondary | destructive | outline`
  (solid bg + on-color fg) for current consumers. **Add** the prototype's **subtle** tone set
  (`Primitives.jsx:79-84`) as non-breaking variants — each a tinted subtle bg + a darker fg, all
  referencing **tokens** (semantic tokens or the raw Focal scale CSS vars added in §A — **no hardcoded
  hex in component classes**):
  - `neutral` → `bg-surface-sunken text-muted-foreground` (prototype neutral = `--color-bg-surface-sunken`, `Primitives.jsx:79`)
  - `accent` → `bg-accent-subtle text-primary`
  - `success` → `bg-success/15 text-[var(--focal-green-700)]`
  - `warning` → `bg-[var(--focal-amber-100)] text-[var(--focal-amber-800)]`
  - `danger` → `bg-destructive/12 text-[var(--focal-coral-700)]` — the **subtle** coral tone (distinct
    from the filled `destructive`)
  - `violet` → `bg-violet-100 text-violet-700 dark:bg-violet-950/40 dark:text-violet-300` — this is the
    plan's **single sanctioned violet exception** (the AI-accent family, "where no shared Focal token
    exists", `plan:61`); it is the only tone using palette utilities, mirroring the `ai` button.
- **Card** (`ui/card.tsx`): raised surface + subtle border + **`shadow-xs`** (was `shadow-sm`) +
  `rounded-lg` (16px). Exports unchanged.
- **Input/Textarea**: height 36px (`h-9` ✓), raised-surface bg, `border-input`, `rounded-md`, `text-sm`,
  focus = the **shared focus ring** above (replaces the current `border-ring`-only treatment). Add the
  bare-select look to `select` triggers.
- **Select / dropdown-menu / popover / dialog / sheet / tooltip**: raised surface, `--overlay` scrim
  (dialog/sheet), `rounded-xl` + `shadow-xl` for modal surfaces, `rounded-md` + `shadow-lg` for
  menus/popovers/tooltips, `--ease-out` animation timing. **No Radix prop/behavior change.**
- **Sidebar** (`ui/sidebar.tsx`): keep the state/storage API and `--sidebar-width: 16rem` (256px ✓);
  tune nav-row padding (`8px 12px`), gap, active-row = `--sidebar-accent`, group-label caps, collapsed
  icon rail, and mobile sheet to the prototype.

## C. Shell composition (class-only)

`AppSidebar` (brand inline-SVG + tagline, calendar switcher, 5 nav groups, footer cluster),
`PageHeader`/`PageToolbar` (accent icon badge + title + right cluster: `ai`-variant AI button, theme
toggle, language dropdown), `AppShell` (inset + mobile top bar), `CalendarSwitcher` (restyle only).
**All existing handlers, queries, hrefs, i18n keys, and props preserved verbatim.**

# Flow (happy + unhappy paths)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| happy | app loads, tokens resolve | `index.css` → primitives → shell | Focal design language renders, light + dark |
| theme persistence off | `localStorage` unavailable | `lib/theme.ts` `read()` catch (existing) | defaults to light; no crash (unchanged) |
| meeting count null/error | `/api/meeting-requests/count` fails | `?? 0` in `AppSidebar` (existing) | badge hidden when 0 (unchanged) |
| `getMe` null/error | `/api/me` fails | `?? false` for `canAccessDashboard` in `AppSidebar` (existing) | dashboard nav hidden; no crash (unchanged) |
| CSS var missing/typo | build or runtime | `pnpm build` (syntax) + visual QA (devtools) | caught pre-merge; wrong color visible in QA |
| HSL-triplet format broken | alpha utility computes wrong | visual QA light/dark + `index.css` review | caught pre-merge |
| variant union regression | a renamed/removed variant value | `pnpm typecheck` | build blocked before users see it |
| handler accidentally moved | markup edit drops an onClick | `AppShell.test.tsx` + manual spot-check | caught pre-merge |

# Alternatives rejected

- **Replace token strategy** (import `colors_and_type.css`, rewire to `--color-*`): touches every
  primitive + pulls in Prima/`[data-product]` machinery — rejected for Surgical Changes (think doc).
- **Hybrid** (two live vocabularies): speculative; no consumer needs `--color-*` yet — rejected
  (Simplicity First).
- **Add `public/focal-app-icon.svg`**: rejected in favor of an **inline-SVG** brand mark — same visual,
  honors the plan's "public assets out of scope" and the gate-2 Should-Consider.
- **Renaming `default`→`primary` / `destructive`→`danger`**: rejected — would break every consumer;
  add aliases instead.
- **Pixel-perfect reproduction**: rejected — fidelity bar is 1:1 language + faithful layout (user).

# Plan deviations (intentional — flag for the build reviewer)

- **Brand mark = inline SVG**, not the plan's "existing public app icon/favicon" (`plan §slice 4`).
  Reason: the app ships only raster PNG favicons/PWA icons (no scalable lockup), and a raster favicon in
  the 34px sidebar mark looks soft/off-brand; an inline SVG matches the prototype 1:1, themes cleanly,
  and adds **no** `public/` asset (which the plan lists out of scope). The build reviewer should verify
  it stays visual-only and within the allowed file scope (no new `public/` asset, no behavior change).
- **`--card`/`--popover` dark re-anchored to sand-800** (raised), where the current `.dark` theme ships
  sand-900. Intentional, for prototype raised-surface parity (see the dark-hierarchy note).

# Test strategy

- **Static/build gates (authoritative):** `pnpm lint` + `pnpm typecheck` (proves no variant-union /
  source-compat regression) + `pnpm test:run` (proves consumers' behavior tests still pass) +
  `pnpm build` (proves Tailwind/Vite compile the bridged tokens) — all green.
- **`AppShell.test.tsx`** stays green: app-label/children render, sign-out callback, dashboard-link
  show/hide gating (`AppShell.test.tsx:34-67`). Update queries only if structural markup makes them
  brittle; behavior assertions unchanged.
- **Manual behavior spot-checks** (no focused unit test exists): sidebar collapse/expand, mobile
  sidebar close-on-nav, calendar refresh invalidation, meeting badge when count>0, sign-out, AI nav,
  theme toggle, language switch, dialog/sheet escape+overlay close, select/dropdown keyboard nav,
  tooltip hover/focus.
- **Visual parity (the design bar):** before/after screenshots of the **sidebar**, **page
  header/toolbar**, and a **primitive sampler** (buttons incl. `ai`, badge tones, card, input, select,
  dialog), in **light + dark**, compared against `Shell.jsx` / `Primitives.jsx` / `app.css`. Not a
  pixel-diff gate.
- Gate-6 (GPT-authored tests) may add a lightweight render assertion that the new semantic state
  tokens are defined and a button renders the `ai` variant class — kept optional since CSS-variable
  resolution from stylesheets is unreliable under happy-dom; the build + visual checks are the real gate.

# Security & release notes

- **No security surface:** pure frontend CSS/markup — no authz, injection, secrets, SSRF, or
  rate-limiting introduced. No new dependency, no lockfile change.
- **Release blast radius:** re-anchoring shadcn token *values* affects **every** screen's color/surface
  rendering. Mitigated by: the bridge (no name churn), HSL-triplet preservation, variant aliases, and
  the full green gate sequence after each slice. Rollback = revert the single visual diff; no data or
  contract rollback needed.
- **Prerequisite for gate 4 (carried from think/plan):** the Focal client is an uncommitted tree
  (`HEAD` stub; shell + `ui/*` untracked). A **user-approved baseline commit** (or `git add -N`) must
  establish the current state as `HEAD` before gate 4, or the diff-based gates (4/5/7) cannot see the
  edits to untracked files. Treat an unresolved baseline as a hard stop before gate 4.

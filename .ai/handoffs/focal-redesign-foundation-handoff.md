# Stage

Stage 7: ship — the `focal-redesign-foundation` slice (design tokens + app shell + shared UI
primitives) brought onto the Allosta/Focal design system. Change set = commits `ff58a4a` (redesign)
and `084eccb` (tests), on top of the baseline checkpoint `1805005`.

# What changed

A **visual-only** foundation re-skin of the Focal client, via the **bridge** token strategy (shadcn
token *names* kept; their *values* re-anchored to the Focal palette; new semantic tokens added):

- **Tokens (`index.css`):** added the raw Focal palette (blue/green/sand/amber/coral 50–950) as the
  source of truth; re-anchored `--background`/`--card`/`--sidebar`/`--secondary`/`--muted`/`--accent`/
  `--sidebar-accent`/`--input`/`--muted-foreground`/dark `--destructive` to the Focal canvas/surface/
  sunken stack (light + dark); added **semantic state** (`--success`/`--warning`/`--info` + foregrounds),
  the **raised/sunken surface split**, **accent-subtle**, **overlay**, **`--shadow-xl`**, and **motion**
  (`--ease-out`/`--ease-in-out`/`--duration-*`) tokens, each wired through `@theme inline`.
- **Shell:** sidebar brand mark (inline-SVG Focal logo via palette vars, replacing the lucide icon),
  meeting badge → `warning` tone, calendar switcher raised surface, page-header accent icon badge →
  `accent-subtle`, toolbar AI button → the new `ai` variant.
- **Primitives:** `button` (added `primary` alias + violet `ai` variant + the shared 2px focus ring +
  `shadow-xs` on primary), `badge` (pill + medium weight + the six subtle tones via tokens/raw-scale
  vars), `card` (`shadow-xs`), `input`/`textarea`/`select` (raised surface + shared focus ring),
  `select`/`dropdown-menu`/`popover` (`shadow-lg`), `dialog`/`sheet` (`bg-overlay` scrim, `shadow-xl`,
  `rounded-xl`, shared close-button focus ring, motion tokens), `tooltip` (`shadow-lg`), `sidebar`
  (nav-row sizing to the prototype). Wrapped bare Radix custom-property arbitrary values in `var()` so
  they emit valid CSS under Tailwind 4.

No behavior, routing, API, server, dependency, or i18n changes. Existing primitive variant APIs are
preserved (aliases, never renames), so every consuming screen compiles unchanged.

# Files touched

Redesign (`ff58a4a`): `apps/focal/client/src/index.css`; `components/{AppSidebar,CalendarSwitcher,
PageHeader,PageToolbar}.tsx`; `components/ui/{button,badge,card,input,textarea,select,dropdown-menu,
popover,dialog,sheet,tooltip,sidebar}.tsx`. — Tests (`084eccb`): `components/AppShell.test.tsx` (+),
`components/PageToolbar.test.tsx`, `components/ui/button.test.tsx`, `components/ui/badge.test.tsx`.

# Tests run

```sh
cd superapp/apps/focal/client
pnpm lint        # biome — 205 files, 0 errors
pnpm typecheck   # tsc -b — 0 errors
pnpm test:run    # vitest — 45 files, 302 tests passed (+19 new)
pnpm build       # tsc -b && vite build — ✓
```

# Verification output

```sh
$ pnpm test:run
 Test Files  45 passed (45)
      Tests  302 passed (302)
$ pnpm build
✓ built in ~210ms
# built CSS emits valid var() for Radix props:
max-height:var(--radix-select-content-available-height)
transform-origin:var(--radix-select-content-transform-origin)
```

Visual QA (vite dev server, auth temporarily bypassed locally then reverted): the authenticated shell
renders faithfully in **light** and **dark** — sidebar (brand mark, calendar switcher, five nav groups,
sunken active row), top bar (accent icon badge, violet `ai` button, theme/language controls), correct
dark surface hierarchy. No console errors in the rendered shell beyond the expected data-fetch failures
(no backend in the QA environment).

# Still needs review

- **Authenticated-shell visual QA (light + dark) — done.** Captured the running shell on the vite dev
  server in both themes (auth was temporarily bypassed *locally* for the capture and immediately
  reverted via `git checkout` — no production code changed; the working tree is clean). The result
  matches the prototype: the inline-SVG brand mark, the calendar-switcher pill, the five nav groups
  with uppercase labels and the **sunken active row**, the **accent-subtle** top-bar icon badge, the
  violet **`ai`** AI-assistant button, and — in dark — the correct **surface hierarchy** (sand-900
  sidebar, raised sand-800 cards, `#0a0a0d` sunken active row). Brand blue, warm sand neutrals, soft
  shadows, and Inter/JetBrains type all render. `pnpm lint/typecheck/test:run/build` all green.
- **Intentional plan deviation (flagged at design):** the brand mark is an inline SVG (using the DS
  brand `#407be9`/`#1baf73` via palette vars) rather than the plan's "existing public icon/favicon" —
  the app ships only raster PNG favicons, so the SVG matches the prototype 1:1 without adding a
  `public/` asset.

# PR / release notes (for users — stage 5)

**Focal now wears the Allosta design system.** The app is re-skinned onto Focal's brand language: a
warm, paper-and-ink palette anchored to the brand blue and green, soft rounded surfaces and diffused
shadows, and Inter + JetBrains Mono type. The sidebar leads with the Focal mark; buttons, badges,
inputs, menus, and dialogs share one consistent, accessible look — including a clear 2px focus ring on
every control and a dedicated violet "AI assistant" button. Everything works in both **light and dark**.
This is a visual refresh only — every screen behaves exactly as before. (Contains no secrets, tokens,
keys, or PII.)

# Status

CODEX APPROVED (9.3) — all 7 gates cleared (think 9.4 · plan 9.4 · design 9.1 · build 9.1 · review 9.2
· test 9.4 · ship 9.3). The change is committed on `feature/focal-migration` (`ff58a4a` redesign +
`084eccb` tests, on baseline `1805005`). Opening/merging a PR is the engineer's call — the redesign is
one slice of the in-progress `feature/focal-migration` branch, not a standalone PR base.

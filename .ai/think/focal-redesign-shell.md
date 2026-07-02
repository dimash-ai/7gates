# Problem

Slice 0 of the `focal-redesign-pages` epic is the **foundation**: make `apps/focal/client` inherit
`apps/old-focal`'s **exact theme** (light + dark) and **shell** look, so every left-nav page picks up
old-focal's palette/radius/shadows/typography in one cascade. It **supersedes the merged Allosta
foundation (PR #50)** per the epic's confirmed "exact old-focal" decision.

The decisive, de-risking finding from reading both `index.css` files: **the new app already uses the
same shadcn HSL token *names*, the same `@theme inline` mapping, and the same "elevate" hover system
as old-focal** (shared shadcn/New-York origin). The only divergence is **values** — the new app
carries the Allosta DS palette (`--primary 219 79% 58%`, warm sand neutrals, `--radius .75rem`, soft
diffused shadows, extra `--success/--surface-*/--accent-subtle` tokens), while old-focal uses
`--primary 217 91% 48%`, cooler grays (`--foreground 220 13% 13%`, `--sidebar 220 9% 96%`,
`--border 220 13% 91%`), `--radius .5rem`, and its own shadow scale. So slice 0 is a **value-swap
within the existing structure**, not a restructure: keep the token *names* (so the build stays green
and every built page re-skins at once), change the *values* to old-focal's.

The one real tension to manage: the new app added **Allosta-only token names** that the already-ported
shadcn components/features consume (`--surface-raised/--surface-sunken`, `--accent-subtle`,
`--overlay`, `--success/--warning/--info`, `--radius-sm/md/lg/xl`, soft `--shadow-*`, the `--focal-*`
raw palette, motion vars). old-focal's `index.css` does **not** define those. If we just delete them,
components break (missing-token regressions). So each must be **re-anchored to old-focal's nearest
equivalent value** (e.g. `--surface-raised` ← old-focal `--card`; `--accent-subtle` ← a light tint of
old-focal `--primary`), preserving the name while making it read as old-focal. That keeps the
build-green invariant **and** the exact-old-focal look.

# Assumptions

- **[confirmed — fs]** new `apps/focal/client/src/index.css` is the Allosta foundation (PR #50): a
  Tailwind-4 `@theme inline` block mapping `hsl(var(--token))` → utilities (lines 10–80), then `:root`
  (light) + `.dark` value blocks, `@custom-variant dark (&:where(.dark, .dark *))` (class-based dark),
  and the `@layer utilities` elevate system. Token names: `--background/foreground/border/input/ring`,
  `--card*`, `--popover*`, `--primary*`, `--secondary*`, `--muted*`, `--accent*`, `--destructive*`,
  `--sidebar*`, `--chart-1..5`, `--dashboard-indigo` + `--dashboard-heatmap-1..5`, plus Allosta-only
  `--success/--warning/--info`, `--surface-raised/sunken`, `--accent-subtle`, `--overlay`,
  `--radius(-sm/md/lg/xl)`, `--shadow-xs..xl`, `--focal-{blue,green,sand,amber,coral}-*`, motion vars.
- **[confirmed — fs]** old-focal `client/src/index.css` defines the **same** shadcn token names with
  **old-focal values** (`--primary 217 91% 48%`, `--foreground 220 13% 13%`, `--sidebar 220 9% 96%`,
  `--card 0 0% 98%`, `--border 220 13% 91%`, `--radius .5rem`, a distinct `--shadow-*` scale, the same
  `--chart-1..5` + `--dashboard-*` ramps, `--font-sans InterVariable`) and a full `.dark` block
  (`index.css:97`). It is **Tailwind 3** (`@tailwind base/components/utilities` + `tailwind.config.ts`
  + PostCSS) → values are ported; the directives/config are **not**.
- **[confirmed — fs]** Both apps already share the **elevate** system (`--elevate-1/2`,
  `--button-outline`, `--opaque-button-border-intensity`, `*-border` derived tokens) → the component
  layer is common heritage; only theme values diverge.
- **[confirmed — fs]** old-focal defines **no** `--surface-*`/`--accent-subtle`/`--overlay`/`--success`
  /`--warning`/`--info`/`--radius-{sm..xl}` → these new-app-only names must be re-anchored, not dropped.
- **[confirmed — inspection]** The new app's shell already mirrors old-focal's structure: an
  `AppSidebar` (shadcn `Sidebar`) with sections planning/execution/analytics/assistant/settings, a
  calendar switcher, an inline `FocalMark`, and a `PageHeader` top bar → after the value-swap the shell
  is **mostly** old-focal-correct; remaining deltas are small (brand mark, spacing, the item set).
- **[unverified — settle at design gate]** the exact per-token old-focal values for the few
  re-anchored names, the radius decision (old-focal `.5rem` vs the new `--radius-md .75rem` that ported
  components use for `rounded-md`), and which shell deltas are visual (in-scope) vs structural (nav
  item-set/routes — deferred). Resolved by reading old-focal's full `index.css` + `tailwind.config.ts`
  + `AppSidebar.tsx` at the design gate.

# Options considered

Two real forks: **(1)** how to apply the token port, and **(2)** how much shell to take in slice 0.

| # | Option | What it is | Pros | Cons |
|---|--------|-----------|------|------|
| **A — Value-swap in place (chosen)** | Edit the `:root` + `.dark` value blocks to old-focal's values; keep the `@theme inline` map + token names; re-anchor the new-app-only names to old-focal equivalents; set `--radius .5rem` + old-focal shadows. | Surgical (one file's value blocks + minor shell); every built page re-skins at once; build stays green (names persist); trivially revertable. | Must hand-map the handful of Allosta-only tokens to avoid missing-token regressions (named in scope). |
| **B — Replace `index.css` wholesale** | Drop in a fresh old-focal-derived `index.css`. | Looks "clean". | Re-derives the working `@theme inline` map + elevate utilities (churn, surgical-changes violation); high risk of dropping a token a component needs → build break. Rejected. |
| **C — Split tokens (0a) and shell (0b)** | Theme swap as 0a, shell reconcile as a separate slice. | Even smaller diffs. | The user asked to run "slice 0" as one unit, and the shell is mostly re-skinned by the token swap already — a separate slice is overhead for a small remaining delta. Hold C in reserve only if the shell delta turns out large at the design gate. |

Scope fork (2): take the **theme swap + the shell's *visual* reconcile** (brand, sections, rows,
switcher, header) in slice 0; **defer the nav *item-set* / route changes** (Events/Integrations/CRM
entries, `/aichat`↔`/ai-chat` renames, role-gating, orphan badges) because they depend on
not-yet-restyled or not-yet-existing pages and would create dead/404 nav — they belong to each
page's slice or a later shell-nav pass.

# Recommendation

**Option A — value-swap in place**, scoped to **theme + shell visual** with the **nav item-set/route
changes deferred**. Rationale: the new app and old-focal already share the token *names*, the `@theme`
map, and the elevate system, so the entire "exact old-focal" cascade is achieved by changing values in
one file's `:root`/`.dark` blocks plus re-anchoring a named handful of Allosta-only tokens — the
smallest possible change that satisfies "exact old-focal everywhere" while honoring Surgical Changes
and the build-green invariant. B churns working infrastructure for no gain; C over-splits a slice the
user scoped as one (kept in reserve if the design gate finds the shell delta is large). Defer nav
item-set/route work so slice 0 ships no dead navigation.

Plan shape (settled at gate 2):
1. Read old-focal's full `index.css` (light + `.dark`) + `tailwind.config.ts` → the exact value set.
2. Swap the new `:root` + `.dark` values; set `--radius .5rem` + old-focal shadows; re-anchor the
   Allosta-only names to old-focal equivalents (no name deleted).
3. Reconcile the shell's visual deltas (brand mark, spacing) to old-focal.
4. `pnpm lint && typecheck && test:run && build` green; screenshot light + dark vs old-focal.

# Out of scope

- Per-page **content** restyle (each its own slice).
- Nav **item-set / route** changes + role-gating/badges (deferred — depend on later pages; avoid
  dead/404 nav).
- Any **server / API / schema / behavior** change.
- **Lifting** old-focal's Tailwind-3 directives / `tailwind.config.ts` / PostCSS / React-18 wiring.

# Open questions

- **Radius**: old-focal is `--radius .5rem`; the new app's ported components use `--radius-md .75rem`
  for `rounded-md`. Adopt old-focal's `.5rem` and rescale `--radius-sm/md/lg/xl` proportionally to
  old-focal — confirm the exact scale at the design gate (old-focal `tailwind.config.ts`).
- **Re-anchor map**: the exact old-focal value for each new-app-only token
  (`--surface-raised/sunken`, `--accent-subtle`, `--overlay`, `--success/warning/info`, soft
  `--shadow-*`). Proposal: `surface-raised←card`, `surface-sunken←muted/secondary`,
  `accent-subtle←primary@10%`, `overlay←rgba(0,0,0,.55/.6)`, `success←chart-2`, `warning←chart-4/amber`,
  `info←primary`, shadows←old-focal's scale. Confirmed at design.
- **Shell delta size** — if reconciling the sidebar/top bar turns out larger than a re-skin, split per
  option C (shell becomes its own slice). Decided at the design gate after reading old-focal's shell.
- **Dark mode** stays class-based (`@custom-variant dark`) — confirmed; both blocks ported.

# Success criteria

- [ ] `cd superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`
      green.
- [ ] Every existing left-nav page renders in **old-focal's exact palette / radius / shadows** in
      **light and dark**, no missing-token/unstyled regressions.
- [ ] Shell (brand, sections, rows, switcher, top bar) matches `apps/old-focal` after the swap.
- [ ] Diff is surgical — `index.css` value blocks + shell components only; no per-page/API change; no
      Allosta-only token name deleted while still referenced; revert = restore the value blocks.

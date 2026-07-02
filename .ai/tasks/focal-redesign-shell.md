# Goal

**Slice 0 of the `focal-redesign-pages` epic — the foundation.** Port `apps/old-focal`'s **exact
theme** (light + dark) and reconcile the **shell** (sidebar / top bar) to old-focal's look, so every
left-nav page inherits old-focal's palette, radius, shadows, and typography in one cascade. This
**supersedes the merged Allosta foundation (PR #50)** per the epic's "exact old-focal" decision.

> **Binding visual contract** = `apps/old-focal/client/src/index.css` (light `:root` + `.dark` HSL
> token sets, `--radius`, shadow scale, fonts), `apps/old-focal/client/tailwind.config.ts`, and
> `apps/old-focal/client/src/components/AppSidebar.tsx` (+ the brand mark / calendar switcher / top
> bar). **Thing changed** = `apps/focal/client/src/index.css` + the shell components
> (`components/AppShell.tsx`, `AppSidebar.tsx`, `PageHeader.tsx`).

> **Key enabler (surgical):** the new app's `index.css` already uses the **same shadcn HSL token
> names** (`--background`, `--foreground`, `--sidebar*`, `--primary`, `--card*`, `--popover*`,
> `--chart*`, `--dashboard*`) + the **same `@theme inline` mapping** + the **same "elevate" system**
> as old-focal (shared shadcn/New-York origin). So this slice swaps **token VALUES** (Allosta DS →
> old-focal exact) within the existing structure — it does **not** restructure the theme. The token
> names persist, so the build stays green and every already-built page shifts to old-focal's palette
> at once.

# Scope

- **`index.css` token port** — replace the `:root` (light) and `.dark` value blocks with
  old-focal's exact values: `--primary 217 91% 48%`, old-focal's neutrals (`--foreground 220 13%
  13%`, `--sidebar 220 9% 96%`, `--border 220 13% 91%`, ...), `--radius .5rem`, old-focal's shadow
  scale + chart/dashboard ramps, fonts (InterVariable — unchanged). Keep the `@theme inline` mapping
  (token names already match).
- **Allosta-only tokens the ported components still consume** (`--success/--warning/--info`,
  `--surface-raised/--surface-sunken`, `--accent-subtle`, `--overlay`, `--radius-sm/md/lg/xl`,
  `--shadow-*`, the `--focal-*` raw palette, motion vars) — **re-anchor each to old-focal's nearest
  equivalent value** (e.g. `--surface-raised` → old-focal `--card`) so nothing visually breaks and
  everything reads as old-focal. Do not delete names that existing components reference (build-green
  invariant).
- **Shell visual reconcile** — restyle `AppSidebar` / top bar (`PageHeader`) so the sidebar brand
  mark, sections, item rows, calendar switcher, and header match old-focal post-swap.

# Out of scope

- **Per-page content restyle** — every feature page's body is its own later slice; this slice only
  changes the theme + shell.
- **Nav item-set / route changes that depend on not-yet-restyled pages** — adding `События`/Events,
  `Интеграции`, `Personal CRM` entries, route renames (`/aichat`↔`/ai-chat`, `/calendar`↔`/`), and
  role-gating/orphan badges. Routes are behavior, not "design"; adding nav items whose pages aren't
  ready creates dead/404 nav. Deferred to each page's slice / a later shell-nav pass (flagged in the
  think doc).
- Any **server / API / schema / behavior** change.
- **Lifting old-focal's stack** — no Tailwind-3 `@tailwind`/config, no PostCSS, no React-18 wiring.

# Acceptance criteria

- [ ] `cd superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`
      all green.
- [ ] Every existing left-nav page renders in **old-focal's palette / radius / shadows** in **both
      light and dark** (class-based `.dark`), with no broken/unstyled components (no missing-token
      regressions).
- [ ] The shell (sidebar brand, sections, item rows, calendar switcher, top bar) visually matches
      `apps/old-focal` after the swap.
- [ ] Diff is surgical: `index.css` + the shell components only; no per-page or API changes; no
      Allosta-only token name deleted while a component still references it.

# Verification commands

```sh
cd superapp/apps/focal/client
pnpm install --frozen-lockfile
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```

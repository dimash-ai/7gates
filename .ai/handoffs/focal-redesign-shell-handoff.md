# Stage

Step 7 (ship) — slice 0 of the `focal-redesign-pages` epic: the theme + shell foundation.
Branch `feat/focal-redesign-shell`, single commit `afaaeba` (base: the current Focal client tip).

# What changed

Ported `apps/old-focal`'s **exact visual foundation** into the new Focal client by swapping token
**values** inside the existing Tailwind-4 structure — not restructuring the theme. Every left-nav
page now inherits old-focal's palette, radius, shadows, and typography in one cascade. This
supersedes the prior Allosta-mockup foundation (the epic's "exact old-focal" decision).

- **`index.css` token port** — `:root` (light) + `.dark` value blocks replaced with old-focal's exact
  HSL values (`--primary 217 91% 48%` light / `217 91% 60%` dark, the cooler `220`-hue neutrals,
  `--radius .5rem`); the `@theme inline` color map, token names, `@custom-variant dark`, and the
  elevate utilities are kept intact, so nothing downstream had to change.
- **Radius** rescaled to old-focal (`--radius-sm/md/lg .1875/.375/.5625rem`).
- **Shadows** — the full old-focal scale (`2xs`…`2xl` + bare) ported via `--sh-*` raw vars referenced
  from `@theme inline`, so shadows switch between light and dark like the colours do.
- **Allosta-only bridge tokens** the shipped components still consume (`--surface-*`, `--accent-subtle`,
  `--overlay`, `--success/--warning/--info`, the `--focal-*` ramp) re-anchored to old-focal equivalents
  — names preserved so the build stays green; no Allosta anchor (`#407be9`/`#1baf73`) remains.
- **Shell** — the sidebar brand mark is now old-focal's `Calendar` mark (the inline Allosta "F" SVG
  removed), and the shared page-header collapse trigger matches old-focal's `h-8 w-8`.

# Files touched

- `apps/focal/client/src/index.css` (modified — token values, radius, shadow indirection, focal ramp)
- `apps/focal/client/src/components/AppSidebar.tsx` (modified — brand mark → old-focal Calendar)
- `apps/focal/client/src/components/PageHeader.tsx` (modified — `h-8 w-8` sidebar trigger)
- `apps/focal/client/src/themeTokens.test.ts` (added — exact light/dark token + shadow contract test)
- `apps/focal/client/src/components/AppShell.test.tsx` (modified — assert the Calendar brand mark)
- `apps/focal/client/src/components/PageHeader.test.tsx` (added — trigger sizing + badge tone)

# Tests run

```sh
cd superapp/apps/focal/client
pnpm lint        # biome: 217 files, 0 errors
pnpm typecheck   # tsc -b: 0 errors
pnpm test:run    # 49 files, 361 tests passed
pnpm build       # production bundle built
```

# Verification output

```sh
$ pnpm test:run
 Test Files  49 passed (49)
      Tests  361 passed (361)

$ pnpm build
✓ built in ~270ms
(chunk-size warning only — pre-existing, unrelated)
```

# Still needs review

- **Manual visual QA is the one step unit tests can't assert** — compare against old-focal in light
  AND dark, desktop + mobile: sidebar (expanded/collapsed/mobile sheet), calendar-switcher slot,
  footer, a page header, and a sample of re-skinned primitives (badge, dialog/sheet, select).
- Frontend-only: no server / API / schema / behaviour change. The token-test mutation checks
  (border misport, dark-shadow regression) confirm the contract test actually bites.
- The slice excludes pre-existing uncommitted Goals/i18n working-tree edits (not part of this work).

# PR / release notes (for users)

**Focal now wears its proven production look across every screen.** The app's colours, corner
rounding, elevation/shadows, and the sidebar + page-header chrome now exactly match the established
Focal design — in both light and dark mode. This is a visual foundation change only: nothing about
how the app behaves or what it does has changed. Every page picks up the look automatically; the
per-page detailing follows in subsequent slices.

(No secrets, tokens, keys, or PII in this change — it is CSS variables, two small component tweaks,
and tests.)

# Status

CODEX APPROVED (9.2) — all 7 gates passed (think 9.3 · plan 9.2 · design 9.4 · build 9.4 ·
review 9.4 · test 9.4 · ship 9.2). Manual light/dark visual QA DONE 2026-06-22 — verified on a
real authed local run (Time Budgets page, both modes): sidebar/brand/top-bar/cards/primary all
match old-focal; the dark primary correctly renders lighter (60%) than light (48%). Remaining
before merge: push the branch + open the PR (base decision pending).

---
Cleared for release.

# Design — focal-redesign-shell (slice 0)

Reproduce `apps/old-focal`'s exact theme in `apps/focal/client/src/index.css` by swapping **token
values** inside the existing Tailwind-4 structure (keep `@import`, `@custom-variant dark`,
`@theme inline`, the elevate `@layer utilities`, and every token *name*), then reconcile the shell
visuals. Sources of truth: `apps/old-focal/client/src/index.css` (light `:root` + `.dark`) and
`apps/old-focal/tailwind.config.ts` (radius). **Note:** the config lives at
`apps/old-focal/tailwind.config.ts` (not `client/…` — task path corrected per the plan review).

## 1. Shared shadcn tokens — exact old-focal values to write into `:root` / `.dark`

Overwrite the new app's Allosta values with these (HSL triplets, consumed via `hsl(var(--x))`).
**Dark `--primary`/`--sidebar-primary`/`--ring` are `60%`, light are `48%` — they differ; do not copy
one into both blocks.**

| token | light (`:root`) | dark (`.dark`) |
|---|---|---|
| `--background` | `0 0% 100%` | `220 13% 9%` |
| `--foreground` | `220 13% 13%` | `210 40% 98%` |
| `--border` | `220 13% 91%` | `220 13% 20%` |
| `--input` | `220 13% 80%` | `220 13% 30%` |
| `--ring` | `217 91% 48%` | `217 91% 60%` |
| `--card` / `-foreground` / `-border` | `0 0% 98%` / `220 13% 13%` / `0 0% 95%` | `220 13% 11%` / `210 40% 98%` / `220 13% 14%` |
| `--popover` / `-foreground` / `-border` | `220 9% 94%` / `220 13% 13%` / `220 9% 90%` | `220 13% 15%` / `210 40% 98%` / `220 13% 18%` |
| `--primary` / `-foreground` | `217 91% 48%` / `210 40% 98%` | `217 91% 60%` / `210 40% 98%` |
| `--secondary` / `-foreground` | `220 14% 91%` / `220 13% 13%` | `220 14% 19%` / `210 40% 98%` |
| `--muted` / `-foreground` | `220 14% 92%` / `220 9% 46%` | `220 14% 18%` / `220 9% 65%` |
| `--accent` / `-foreground` | `220 14% 94%` / `220 13% 13%` | `220 14% 17%` / `210 40% 98%` |
| `--destructive` / `-foreground` | `0 84% 45%` / `0 0% 98%` | `0 84% 45%` / `0 0% 98%` |
| `--sidebar` / `-foreground` / `-border` | `220 9% 96%` / `220 13% 13%` / `220 9% 92%` | `220 13% 13%` / `210 40% 98%` / `220 13% 16%` |
| `--sidebar-primary` / `-foreground` | `217 91% 48%` / `210 40% 98%` | `217 91% 60%` / `210 40% 98%` |
| `--sidebar-accent` / `-foreground` | `220 14% 91%` / `220 13% 13%` | `220 14% 17%` / `210 40% 98%` |
| `--sidebar-ring` | `217 91% 48%` | `217 91% 60%` |
| `--chart-1..5` | `217 91% 48%` · `142 76% 36%` · `280 65% 47%` · `24 95% 53%` · `340 82% 52%` | `217 91% 65%` · `142 76% 65%` · `280 65% 70%` · `24 95% 65%` · `340 82% 65%` |
| `--dashboard-indigo` | `239 84% 67%` | `239 84% 75%` |
| `--dashboard-heatmap-1..5` | `239 84% 95%` · `239 84% 86%` · `239 84% 75%` · `239 84% 67%` · `244 76% 59%` | `239 50% 30%` · `239 60% 40%` · `239 70% 50%` · `239 80% 60%` · `244 80% 65%` |
| elevate: `--button-outline` / `--badge-outline` / `--opaque-button-border-intensity` / `--elevate-1` / `--elevate-2` | `rgba(0,0,0,.10)` / `rgba(0,0,0,.05)` / `-8` / `rgba(0,0,0,.03)` / `rgba(0,0,0,.08)` | `rgba(255,255,255,.10)` / `rgba(255,255,255,.05)` / `9` / `rgba(255,255,255,.04)` / `rgba(255,255,255,.09)` |

Fonts unchanged (`--font-sans: InterVariable`). The `*-border` derived tokens (`--primary-border`
etc.) already exist with the same `hsl(from … calc(l + var(--opaque-button-border-intensity)))`
formula — keep as-is; they re-resolve from the new values automatically.

## 2. Re-anchor map — Allosta-only token names old-focal lacks (keep the NAME, change the value)

These names are consumed by shipped primitives (`badge/sheet/dialog/input/select/textarea`,
`CalendarSwitcher`, `PageHeader`); deleting any breaks the build. Re-anchor each to its old-focal
equivalent so it renders as old-focal:

| token | light value | dark value | rationale |
|---|---|---|---|
| `--surface-raised` | `0 0% 98%` (= old `--card`) | `220 13% 11%` | raised surface = card |
| `--surface-sunken` | `220 14% 92%` (= old `--muted`) | `220 14% 18%` | sunken well = muted |
| `--accent-subtle` | `hsl(217 91% 48% / 0.10)` | `hsl(217 91% 60% / 0.16)` | active/icon tint = primary @ low alpha |
| `--overlay` | `hsl(220 13% 13% / 0.55)` | `rgba(0,0,0,0.6)` | dialog/sheet scrim |
| `--success` / `-foreground` | `142 76% 36%` / `210 40% 98%` | `142 76% 65%` / `210 40% 98%` | = old `--chart-2` per theme (`index.css:42`/`:133`); near-white fg for contrast |
| `--warning` / `-foreground` | `24 95% 53%` / `220 13% 13%` | `24 95% 65%` / `220 13% 13%` | = old `--chart-4` per theme (`index.css:44`/`:135`); dark fg on amber |
| `--info` / `-foreground` | `217 91% 48%` / `210 40% 98%` | `217 91% 60%` / `210 40% 98%` | = `--primary` per theme |

**`--focal-*` raw ramp (Should-Consider #1 from plan review).** `badge.tsx:19-25` references
`--focal-green-700/300`, `--focal-amber-100/800/400/300`, `--focal-coral-700/300`; `AppSidebar`
`FocalMark` uses `--focal-blue-500` / `--focal-green-500`. Re-anchor the **full referenced ramp** off
the Allosta hex (`#407be9`/`#1baf73`) to the standard Tailwind shades old-focal's badges/brand use —
**pinned** so the build is deterministic:

| token | hex | token | hex |
|---|---|---|---|
| `--focal-blue-500` | `#2f6fe0` (≈ old `--primary 217 91% 48%`) | `--focal-amber-100` | `#fef3c7` |
| `--focal-green-300` | `#86efac` | `--focal-amber-300` | `#fcd34d` |
| `--focal-green-500` | `#22c55e` | `--focal-amber-400` | `#fbbf24` |
| `--focal-green-700` | `#15803d` | `--focal-amber-800` | `#92400e` |
| `--focal-coral-300` | `#fca5a5` | `--focal-coral-700` | `#b91c1c` |

At minimum these enumerated shades are re-anchored (not just the `-500` anchors); the rest of each
ramp follows the same standard-Tailwind family. Keep **every** `--focal-*` name that any component
references defined (no deletion). `themeTokens.test.ts` asserts these shades are present and that no
`#407be9` / `#1baf73` / `219 79% 58%` Allosta anchor remains.

## 3. Radius (from `old-focal/tailwind.config.ts:8-12`)

Base `:root --radius: 0.5rem` (was `0.75`). Tailwind-4 scale in `@theme inline`:
`--radius-sm: 0.1875rem` (3px), `--radius-md: 0.375rem` (6px), `--radius-lg: 0.5625rem` (9px),
`--radius-xl: 0.75rem` (old-focal defines no xl → proportional). These re-resolve `rounded-sm/md/lg/xl`
across all shipped components to old-focal roundness.

## 4. Shadows — port old-focal's exact scale (both themes), switching via var-indirection

old-focal defines a full `--shadow-*` scale per theme (light `old-focal/index.css:57-64`, dark
`:143-150`). Port those exact values; do **not** drop to Tailwind defaults. Because the new app uses
`@theme inline` (values are inlined into utilities), a `.dark`-redefined `--shadow-*` would **not**
switch unless the inlined value itself contains a `var()` — the same pattern the colors already use
(`--color-card: hsl(var(--card))`). So:

Port the **full** old-focal scale — `2xs, xs, sm, base (bare `--shadow`), md, lg, xl, 2xl` — because
the new app consumes `shadow-2xl` (`features/onboarding/OnboardingTour.tsx:61`) and may consume the
bare `shadow`, so a partial xs–xl port would leave those outside the old-focal contract.

- In `@theme inline`, replace the five Allosta shadow lines (`index.css:61-66`) with eight that
  reference raw vars (distinct `--sh-*` prefix avoids a self-referential collision with the
  `--shadow-*` theme namespace):
  `--shadow-2xs: var(--sh-2xs)` · `--shadow-xs: var(--sh-xs)` · `--shadow-sm: var(--sh-sm)` ·
  `--shadow: var(--sh-base)` · `--shadow-md: var(--sh-md)` · `--shadow-lg: var(--sh-lg)` ·
  `--shadow-xl: var(--sh-xl)` · `--shadow-2xl: var(--sh-2xl)`.
- In `:root`, define old-focal's **light** values verbatim (`old-focal/index.css:57-64`):
  `--sh-2xs: 0px 2px 0px 0px hsl(220 13% 13% / 0.02)`;
  `--sh-xs: 0px 2px 0px 0px hsl(220 13% 13% / 0.03)`;
  `--sh-sm` = `--sh-base`: `0px 2px 0px 0px hsl(220 13% 13% / 0.02), 0px 1px 2px -1px hsl(220 13% 13% / 0.06)`;
  `--sh-md: 0px 2px 0px 0px hsl(220 13% 13% / 0.03), 0px 2px 4px -1px hsl(220 13% 13% / 0.07)`;
  `--sh-lg: 0px 2px 0px 0px hsl(220 13% 13% / 0.04), 0px 4px 6px -1px hsl(220 13% 13% / 0.10)`;
  `--sh-xl: 0px 2px 0px 0px hsl(220 13% 13% / 0.05), 0px 8px 10px -1px hsl(220 13% 13% / 0.12)`;
  `--sh-2xl: 0px 2px 0px 0px hsl(220 13% 13% / 0.08)`.
- In `.dark`, define old-focal's **dark** values verbatim (`old-focal/index.css:143-150`):
  `--sh-2xs: 0px 2px 0px 0px hsl(220 13% 9% / 0.30)`;
  `--sh-xs: 0px 2px 0px 0px hsl(220 13% 9% / 0.35)`;
  `--sh-sm` = `--sh-base`: `0px 2px 0px 0px hsl(220 13% 9% / 0.30), 0px 1px 2px -1px hsl(220 13% 9% / 0.40)`;
  `--sh-md: 0px 2px 0px 0px hsl(220 13% 9% / 0.35), 0px 2px 4px -1px hsl(220 13% 9% / 0.45)`;
  `--sh-lg: 0px 2px 0px 0px hsl(220 13% 9% / 0.40), 0px 4px 6px -1px hsl(220 13% 9% / 0.50)`;
  `--sh-xl: 0px 2px 0px 0px hsl(220 13% 9% / 0.45), 0px 8px 10px -1px hsl(220 13% 9% / 0.55)`;
  `--sh-2xl: 0px 2px 0px 0px hsl(220 13% 9% / 0.50)`.

`shadow-2xs/xs/sm/md/lg/xl/2xl` and the bare `shadow` then render old-focal's exact scale and switch
with `.dark`. `themeTokens.test.ts` asserts the `--sh-2xs` and `--sh-2xl` light + dark values are
present (scale ends covered).

## 5. Shell components (visual reconcile only — behavior preserved)

Binding contract = `apps/old-focal/client/src/components/AppSidebar.tsx` (+ its brand mark / calendar
switcher / footer) and old-focal's page header. After §1–4 the token cascade does most of the work;
the remaining concrete deltas:

- **`AppSidebar.tsx`** — replace the inline Allosta `FocalMark` SVG (brand-blue `#407be9` square + "F"
  + green dot) with old-focal's brand treatment (its `Calendar` lucide mark + "Focal" wordmark +
  localized tagline). Tune only visual classes: header padding, section-label spacing, item-row
  padding/active fill, meeting badge tone, switcher slot, footer. **Preserve** `SECTIONS`, hrefs,
  `dashboardOnly` filter, `getMe`, the meeting-count query, mobile-close, `OfflineIndicator`,
  `signOut`. **No** new nav items / route renames / role-gating (deferred — out of scope).
- **`AppShell.tsx`** — align inset + mobile header spacing/border/background to old-focal only if the
  token swap leaves a visible mismatch; keep `SidebarProvider`/state/`children` untouched.
- **`PageHeader.tsx`** — `border-b bg-background`, trigger sizing, title scale/weight, icon-badge tone
  (now `--accent-subtle` re-anchored), action wrapping. Don't touch `PageToolbar` behavior.
- **`CalendarSwitcher.tsx`** — only if it still visibly diverges after the cascade; classes only, no
  behavior.

Re-validates the gate-1 Should-Consider ("shell mostly old-focal-correct") via the §7 visual pass.

## 6. Test — `src/themeTokens.test.ts` (only new file)

Text-level assertions over `src/index.css` (cheap, deterministic, no snapshot infra):
- light block contains old-focal anchors (`--foreground: 220 13% 13%`, `--sidebar: 220 9% 96%`,
  `--primary: 217 91% 48%`, `--radius: 0.5rem`); dark block contains `--background: 220 13% 9%` **and
  `--primary: 217 91% 60%`** (proves the light/dark primary split).
- radius scale present (`--radius-sm: 0.1875rem`, `--radius-md: 0.375rem`, `--radius-lg: 0.5625rem`).
- shadow scale ported end-to-end: `--sh-2xs` and `--sh-2xl` defined in **both** `:root` and `.dark`,
  and `@theme inline` maps `--shadow-md: var(--sh-md)` + `--shadow-2xl: var(--sh-2xl)` (proves the
  full-scale port + the dark switch).
- every re-anchored Allosta-only name still defined in **both** themes (`--surface-raised`,
  `--surface-sunken`, `--accent-subtle`, `--overlay`, `--success`, `--warning`, `--info`), with the
  prior-blocked values asserted **concretely**: light `--success: 142 76% 36%` / `--warning: 24 95%
  53%`, dark `--success: 142 76% 65%` / `--warning: 24 95% 65%`.
- the **full referenced `--focal-*` ramp** (the shades enumerated in §2) is still defined and carries
  **no** Allosta anchor (`#407be9`, `#1baf73`, `219 79% 58%` absent).
- `@theme inline` still maps the existing color names (structure intact).

## 7. Verification + visual QA

`cd superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` (green).
Manual light+dark, desktop+mobile screenshot compare vs old-focal: sidebar expanded/collapsed, mobile
sheet, calendar-switcher slot, footer, a page header — **and** (gate-2 Should-Consider #3) a sample of
re-skinned primitives the token swap touches but the slice doesn't edit: **a badge (each variant), a
dialog/sheet (overlay + surface), and a select** — to confirm the cascade is visually correct, not
only the shell chrome.

## 8. Failure modes / rollback

Carries the plan's Error & rescue map (`old-token-misport`, `bridge-token-drop`,
`allosta-anchor-leftover`, `radius/shadow drift`, `dark-class-regression`, `sidebar-behavior-drift`,
`dead-nav-expansion`, `visual-scope-creep`) — caught by `themeTokens.test.ts`, `pnpm build`,
`AppShell.test.tsx`/`PageToolbar.test.tsx`, and the §7 visual pass. **Rollback** = restore the
`:root`/`.dark` value blocks + the `@theme` radius/shadow lines + revert the shell TSX; no data/API/
contract state to unwind. Diff stays surgical: `index.css` + the four shell files + the one token test.

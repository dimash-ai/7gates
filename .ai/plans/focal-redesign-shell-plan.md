# Summary

Port the old-focal visual foundation into the current Tailwind 4 client by changing token values, not
the theme structure. Keep `superapp/apps/focal/client/src/index.css`'s existing imports, `.dark`
class strategy, `@theme inline` map, token names, and elevate utilities; replace the light and dark
value blocks with old-focal's exact HSL/radius/shadow values, then re-anchor the Allosta-only bridge
tokens to old-focal equivalents so existing components keep resolving every variable they use.

After the cascade is correct, reconcile only the shell visuals in `AppSidebar`, `AppShell`, and
`PageHeader` against the old-focal shell. The current app's nav sections, queries, routing, sign-out,
meeting badge, theme toggle, and language behavior stay intact. The task names
`superapp/apps/old-focal/client/tailwind.config.ts`, but the file in this checkout is
`superapp/apps/old-focal/tailwind.config.ts`; use that path as the radius/config contract.

# Files to change

| path | change | why |
|------|--------|-----|
| `superapp/apps/focal/client/src/index.css` | modify | Replace Allosta DS token values with old-focal light and dark values while preserving Tailwind 4 structure, token names, and elevate utilities. Re-anchor bridge-only tokens so no referenced CSS variable disappears. |
| `superapp/apps/focal/client/src/components/AppSidebar.tsx` | modify | Match the old-focal sidebar brand, section spacing, item-row visual treatment, calendar-switcher slot, and footer spacing while preserving current nav behavior and deferred route/item-set scope. |
| `superapp/apps/focal/client/src/components/AppShell.tsx` | modify | Align the app inset and mobile-only shell header with old-focal's shell look if the token swap leaves a visible mismatch; keep `SidebarProvider`, sidebar state, and routed `children` unchanged. |
| `superapp/apps/focal/client/src/components/PageHeader.tsx` | modify | Align the shared top bar with old-focal page headers: sidebar trigger sizing, border/background, title scale, icon badge tone, and action wrapping. |
| `superapp/apps/focal/client/src/themeTokens.test.ts` | add | Lock the old-focal token port and bridge-token invariant with a cheap text-level test over `index.css`. This is the only expected test-only addition. |
| `superapp/apps/focal/client/src/components/AppShell.test.tsx` | modify only if needed | Keep existing shell behavior tests green; update only if visual markup changes make current queries brittle. No new behavior contract is planned here. |
| `superapp/apps/focal/client/src/components/CalendarSwitcher.tsx` | modify only if visual comparison proves necessary | Prefer letting the token swap restyle the existing switcher. If exact old-focal shell fit cannot be reached from `AppSidebar` wrapper classes alone, adjust only visual classes here; do not add old-focal's dropdown/shared-calendar behavior in this slice. |

# Implementation slices

1. **Reference lock and token inventory.**
   - Re-open `superapp/apps/old-focal/client/src/index.css`,
     `superapp/apps/old-focal/tailwind.config.ts`, and
     `superapp/apps/old-focal/client/src/components/AppSidebar.tsx`.
   - Inventory all current references to bridge-only variables in
     `superapp/apps/focal/client/src` (`--surface-*`, `--accent-subtle`, `--overlay`,
     `--success`, `--warning`, `--info`, `--focal-*`, shadow and radius tokens).
   - No code edits in this slice. It validates the exact value source and the no-missing-token
     constraint before changing the cascade.

2. **Core old-focal token value swap.**
   - In `index.css`, replace shared shadcn token values in `:root` and `.dark` with old-focal's
     exact values: background/foreground, border/input/ring, card/popover, primary/secondary/muted,
     accent/destructive, sidebar, chart, dashboard, `--button-outline`, `--badge-outline`,
     `--opaque-button-border-intensity`, and `--elevate-*`.
   - Set `--radius: .5rem`; set Tailwind 4 radius tokens from old-focal config intent:
     `--radius-sm: .1875rem`, `--radius-md: .375rem`, `--radius-lg: .5625rem`, and
     `--radius-xl: .75rem` unless visual comparison shows old-focal never uses an xl equivalent.
   - Copy old-focal's light and dark shadow scale values, retaining current Tailwind 4 shadow names
     and adding old-focal names such as `--shadow-2xs`, `--shadow`, and `--shadow-2xl` where useful.
   - Keep `@import`, `@custom-variant`, `@theme inline`, and `@layer utilities` intact.
   - Verify this slice with `cd superapp/apps/focal/client && pnpm build` to catch CSS syntax or
     Tailwind token mistakes before shell edits.

3. **Bridge-only token re-anchor and contract test.**
   - Re-anchor every Allosta-only token name that current components consume:
     `--surface-raised` to old-focal `--card`, `--surface-sunken` to old-focal `--muted` or
     `--secondary`, `--accent-subtle` to a complete old-focal primary tint,
     `--overlay` to the old modal scrim strength, `--success` to old chart/status green,
     `--warning` to old chart/status orange, and `--info` to old-focal primary.
   - Re-anchor referenced `--focal-*` raw tokens to old-focal-compatible blue/green/orange/red
     values so badge classes and any remaining raw-token consumers no longer carry Allosta
     `#407be9` or `219 79% 58%` anchors.
   - Add `src/themeTokens.test.ts` that reads `src/index.css` and proves:
     old-focal light values are present, old-focal dark values are present, old radius/shadow values
     are present, Allosta-only bridge tokens are still defined in both themes, `@theme inline`
     still maps the existing token names, and known Allosta primary anchors are gone.
   - Run `pnpm test:run -- src/themeTokens.test.ts`, `pnpm lint`, and `pnpm typecheck`.

4. **Sidebar visual reconcile.**
   - In `AppSidebar.tsx`, replace the inline Allosta `FocalMark` with old-focal's brand treatment
     (`Calendar` icon, `h-6 w-6 text-primary`, "Focal" label, existing localized tagline).
   - Tune only visual classes for sidebar header spacing, collapsed brand, group label spacing,
     item rows, active rows, meeting-request badge tone, switcher slot padding, and footer spacing.
   - Preserve `SECTIONS`, hrefs, dashboard filtering, `getMe`, meeting-count query, mobile close on
     nav, `OfflineIndicator`, and `signOut`. Do not add old-focal-only nav entries, role gating,
     CRM link, `/events`, `/integrations`, or `/ai-chat` route changes in this slice.
   - If the switcher itself still visibly fails old-focal comparison after token and wrapper changes,
     touch `CalendarSwitcher.tsx` only for classes; keep its single-calendar refresh behavior.
   - Run `pnpm test:run -- src/components/AppShell.test.tsx` after this slice.

5. **App shell and top bar reconcile.**
   - In `AppShell.tsx`, align the shell inset and mobile header with old-focal spacing, border, and
     background while keeping `SIDEBAR_STYLE`, `SidebarProvider`, `AppSidebar`, `SidebarInset`, and
     `children` data flow unchanged.
   - In `PageHeader.tsx`, align old-focal header visuals: `border-b bg-background`, trigger size,
     title scale/weight, optional icon badge color after token re-anchor, help tooltip trigger, and
     responsive action wrapping.
   - Do not edit `PageToolbar.tsx` unless a build error is caused by the header changes; AI
     navigation, dark-mode toggle, and language switching are behavior and stay as-is.
   - Run `pnpm test:run -- src/components/PageToolbar.test.tsx src/components/AppShell.test.tsx`
     if either shell or header markup affects toolbar/header rendering.

6. **Final verification and visual comparison.**
   - Run the full task command sequence:
     `cd superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.
   - Visually compare old-focal and the new client in light and dark at desktop and mobile widths:
     sidebar expanded, sidebar collapsed, mobile sidebar, calendar-switcher slot, footer, and a
     representative page header.
   - Confirm the production diff remains limited to `index.css` and shell files, plus the focused
     token test. If a mismatch requires primitive, page, route, API, or broad component edits, stop
     and split/escalate instead of expanding this slice.

# Tests

- `src/themeTokens.test.ts`: proves the old-focal light values, dark values, radius scale, shadow
  scale, and bridge-only token definitions are all present in `index.css`; also proves known Allosta
  primary anchors are not left in the token foundation.
- `pnpm test:run -- src/components/AppShell.test.tsx`: proves sidebar rendering, children rendering,
  sign-out, dashboard-link gating, meeting-request badge behavior, failed-count behavior, and
  calendar refresh invalidation still work after shell visual edits.
- `pnpm test:run -- src/components/PageToolbar.test.tsx`: proves the top-bar-adjacent toolbar still
  navigates to AI chat, toggles `.dark`, persists theme preference, and switches language if header
  layout changes affect it.
- `pnpm lint`: proves Biome accepts the edited TSX and the new token test.
- `pnpm typecheck`: proves shell component props/imports and test code remain type-safe after visual
  cleanup.
- `pnpm test:run`: proves the token and shell changes do not break existing component, feature,
  offline, API, i18n, and page tests.
- `pnpm build`: proves Tailwind 4 can compile the old-focal token values, bridge variables, class
  strings, and dark-mode strategy into a production bundle.
- Manual light/dark screenshot comparison against old-focal: proves the visual contract that unit
  tests cannot assert, especially palette, radius, shadows, sidebar rows, collapsed rail, mobile
  sheet, and top-bar spacing.

# Error & rescue map

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| `old-token-misport` | No thrown exception; wrong HSL value is assigned | `themeTokens.test.ts`, code review against old-focal `index.css`, visual QA | App uses a near-old but incorrect palette in light or dark mode |
| `bridge-token-drop` | CSS variable resolves invalid because a referenced bridge token was deleted or omitted | `themeTokens.test.ts`, `pnpm build` for syntax, visual QA for computed styles | Surfaces, badges, overlays, or inputs lose expected color/background styling |
| `allosta-anchor-leftover` | No thrown exception; old Allosta value remains in the cascade | `themeTokens.test.ts` grep assertions and visual QA | Parts of the app still show the superseded blue/warm-sand foundation |
| `radius-scale-drift` | No thrown exception; Tailwind radius tokens do not match old-focal config | `themeTokens.test.ts` and visual QA | Buttons, cards, nav rows, dialogs, or headers look too rounded |
| `shadow-scale-drift` | No thrown exception; Tailwind shadow tokens keep Allosta soft shadows | `themeTokens.test.ts` and visual QA | Cards/menus/dialogs have the wrong elevation compared with old-focal |
| `dark-class-regression` | No exception from React; `.dark` no longer re-resolves the intended values | `PageToolbar.test.tsx`, manual dark-mode visual QA | Theme toggle works mechanically but dark mode renders wrong colors |
| `sidebar-behavior-drift` | No thrown exception; markup move drops a callback, query, href, or filter | `AppShell.test.tsx` and manual nav checks | Sign-out fails, dashboard link appears for the wrong user, mobile menu stays open, or meeting badge is wrong |
| `dead-nav-expansion` | No thrown exception; old-focal-only route/item is added in this slice | Code review and manual nav checks | User sees nav entries for pages/routes not delivered by this slice |
| `responsive-overlap` | No thrown exception | Desktop/mobile visual QA | Header actions, title, sidebar footer, or switcher text overlap or truncate badly |
| `visual-scope-creep` | No thrown exception; implementation edits primitives/pages/routes to chase parity | Diff review against this plan | Reviewer sees a broad foundation rewrite instead of a surgical shell slice |

# Review lenses (pre-answer before gate2-plan)

- **Scope / strategy** - This is the minimum viable old-focal foundation: token values first, then
  shell visuals. Existing Tailwind 4 structure, shadcn token names, elevate utilities, app routes,
  data queries, auth, and feature pages already solve the behavior surface and are preserved. The
  decision is reversible because the cascade lives in `index.css` and shell edits are class/markup
  level.
- **Architecture** - No server, API, schema, route, dependency, state-machine, or data-flow changes.
  `SidebarProvider` still owns sidebar state, `AppSidebar` still owns nav rendering and queries, and
  `PageHeader` still composes the existing `PageToolbar`. CSS variables remain the only cross-page
  coupling introduced by this slice.
- **Design** - Light and dark themes must match old-focal's palette/radius/shadows, not the prior
  Allosta foundation. Shell checks cover expanded/collapsed sidebar, mobile sidebar, calendar switcher
  slot, footer, page header, action wrapping, and visible focus/hover states inherited from existing
  primitives. The think-review caution is handled by explicit screenshot comparison before completion.
- **DevEx** - Future page slices keep using existing semantic tokens and component APIs. The token
  contract test documents the high-risk value swap without introducing visual snapshots or a new test
  framework. Comments in `index.css` should describe old-focal anchors, not preserve stale Allosta DS
  language.

# Risks & migrations

- No database migrations, data backfills, server changes, config changes, lockfile edits, or dependency
  bumps are planned.
- Token blast radius is the main risk because every page inherits `index.css`. Mitigation: preserve
  names and Tailwind mappings, add the token contract test, run full lint/typecheck/test/build, and
  visually check representative shell/pages in both themes.
- Visual exactness is partly manual. Mitigation: compare directly with old-focal in light/dark and
  stop rather than broadening into primitives or feature pages if shell-only edits cannot satisfy the
  contract.
- The old Tailwind config path in the task is stale for this checkout. Mitigation: use
  `superapp/apps/old-focal/tailwind.config.ts` and mention this in the implementation notes.
- Rollback plan: revert the `index.css` value swap, shell TSX edits, and token test. No persisted data
  or API contract requires rollback.

# Scope check

- [x] Matches the task's Scope and Out of scope.
- [x] Small enough to review in one sitting when reviewed by slice: tokens, bridge test, sidebar,
      top bar, final QA.
- [x] Size smell checked: production edits are limited to `index.css` and shell components; any need
      to edit primitives, routes, feature pages, API code, or broad calendar-switcher behavior should
      split out instead of being folded into this slice.

# Out of scope

- Per-page content restyle for calendar, tags, tasks, goals, budgets, habits, heatmap, analytics,
  dashboard, settings, meetings, help, or legal pages.
- Nav item-set and route changes: Events, Integrations, Personal CRM, `/aichat` to `/ai-chat`,
  `/calendar` to `/`, role-gating, orphan badges, and old-focal-only external links.
- Server, API, schema, auth, offline, query behavior, generated OpenAPI files, or data migrations.
- Lifting old-focal's Tailwind 3 directives/config, PostCSS setup, React 18 wiring, old query client,
  or old app shell wholesale.
- Shared primitive restyles, `PageToolbar` behavior changes, new dependencies, screenshots checked
  into the repo, or visual snapshot infrastructure.

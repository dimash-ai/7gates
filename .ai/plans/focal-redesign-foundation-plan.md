# Summary

Implement the foundation redesign as a visual-only bridge from the prototype design system into the
current React 19 + Tailwind 4 + shadcn client. The key decision is to keep the shadcn semantic token
names already consumed by the app, re-anchor their values to the Focal palette from
`superapp/design/focal`, and then restyle the existing shell and primitives against those tokens. No
feature-screen internals, behavior, routing, API calls, dependencies, or primitive public APIs change.

Before gate 4 build work starts, resolve the process issue from the think doc: the current
`superapp/apps/focal/client` tree is untracked relative to the repository baseline, so the reviewer
must be able to see a real diff. Preferred resolution is a user-approved baseline commit; fallback is
`git add -N` for the untracked client files before code review. This plan does not perform that step.

# Files to change

| path | change | why |
|------|--------|-----|
| `superapp/apps/focal/client/src/index.css` | modify | Add the Focal raw scales as documented CSS variables, map them onto existing shadcn HSL tokens, add success/warning/info, raised/sunken surface, accent-subtle, overlay, motion, and shadow tokens, and keep `.dark` parity. |
| `superapp/apps/focal/client/src/components/AppShell.tsx` | modify | Restyle the app inset and mobile header to the prototype shell while preserving the existing `SidebarProvider`, mobile trigger, and routed `children`. |
| `superapp/apps/focal/client/src/components/AppSidebar.tsx` | modify | Restyle the brand block, grouped nav, active rows, meeting badge, collapsed behavior, and footer cluster while preserving dashboard gating, routing, meeting count, sign-out, and offline placement. |
| `superapp/apps/focal/client/src/components/CalendarSwitcher.tsx` | modify | Restyle the existing single-calendar switcher and refresh control to match the prototype switcher without adding the deferred multi-calendar dropdown. |
| `superapp/apps/focal/client/src/components/PageHeader.tsx` | modify | Align the shared page header with the prototype `TopBar`: sidebar trigger, accent icon badge, title/help, center/right slots, and responsive wrapping. |
| `superapp/apps/focal/client/src/components/PageToolbar.tsx` | modify | Restyle the right cluster; switch the AI button to the shared `ai` button variant; preserve AI navigation, theme toggle, and language switching; do not add a timezone chip. |
| `superapp/apps/focal/client/src/components/ui/sidebar.tsx` | modify | Tune the shadcn sidebar primitive classes for prototype sizing, spacing, active rows, collapsed tooltips, mobile sheet styling, and shell backgrounds without changing state/storage APIs. |
| `superapp/apps/focal/client/src/components/ui/button.tsx` | modify | Align button sizes, radius, border, shadow, focus, and variants; add non-breaking `primary` and `ai` variants while keeping `default` as the primary alias. |
| `superapp/apps/focal/client/src/components/ui/badge.tsx` | modify | Align badge radius, spacing, font weight, and tones; add non-breaking semantic variants (`neutral`, `accent`, `success`, `warning`, `danger`, `violet`) while keeping existing variant aliases. |
| `superapp/apps/focal/client/src/components/ui/card.tsx` | modify | Use raised surface, subtle border, prototype radius, and `--shadow-xs`; keep component exports unchanged. |
| `superapp/apps/focal/client/src/components/ui/input.tsx` | modify | Align field height, background, border, focus ring, text size, and disabled/placeholder states. |
| `superapp/apps/focal/client/src/components/ui/textarea.tsx` | modify | Keep textarea visually consistent with input tokens and focus behavior. |
| `superapp/apps/focal/client/src/components/ui/select.tsx` | modify | Align trigger, menu surface, item focus/selected state, radius, shadow, and sizing while preserving Radix Select APIs. |
| `superapp/apps/focal/client/src/components/ui/dropdown-menu.tsx` | modify | Align the language menu and other dropdown surfaces/items to the same popover/menu treatment as the prototype. |
| `superapp/apps/focal/client/src/components/ui/popover.tsx` | modify | Align shared popover surface, radius, border, shadow, and animation tokens used by existing screens. |
| `superapp/apps/focal/client/src/components/ui/dialog.tsx` | modify | Align overlay token, raised modal surface, radius `xl`, border, shadow, close button, and animation timing without changing Radix Dialog behavior. |
| `superapp/apps/focal/client/src/components/ui/sheet.tsx` | modify | Align sheet overlay/surface/radius/shadow and mobile sidebar sheet treatment without changing the side variants. |
| `superapp/apps/focal/client/src/components/ui/tooltip.tsx` | modify | Align tooltip surface, border, shadow, radius, text size, and animation token use. |
| `superapp/apps/focal/client/src/i18n/locales/ru.json` | modify only if needed | Add a new shell label only if the restyle introduces one; current inspection suggests existing `focal.app.*` keys cover the slice, so no locale change is expected. |
| `superapp/apps/focal/client/src/i18n/locales/en.json` | modify only if needed | Same as `ru.json`; any new key must be present in both locales. |
| `superapp/apps/focal/client/src/components/AppShell.test.tsx` | modify only if needed | Keep the same behavior assertions; update queries only if structural markup changes make the current queries brittle. No visual snapshot tests. |

# Implementation slices

1. **Preflight and references, no code edits.** Confirm the reviewer-visible baseline issue is resolved
   before gate 4. Open the prototype files (`colors_and_type.css`, `app.css`, `Shell.jsx`,
   `Primitives.jsx`) and the running client shell/primitives. Capture reference screenshots for shell
   and primitives in light and dark, plus current app screenshots for before/after comparison. This
   slice leaves the build unchanged.

2. **Token bridge only.** Update `index.css` first. Add the Focal raw palette as CSS variables with
   comments tying the important anchors to the prototype (`#407be9`, `#1baf73`, amber, coral, warm
   sand). Map those values onto existing shadcn names in `:root` and `.dark`, preserving HSL triplets
   for every shadcn color token used by Tailwind alpha utilities. Add `@theme inline` entries and CSS
   variables for success/warning/info, raised/sunken surface, accent-subtle, overlay, `--shadow-xl`,
   `--ease-out`, `--ease-in-out`, and duration tokens. Keep `hover-elevate`, `active-elevate`, and
   `.dark` class strategy intact. Verify after this slice with `pnpm lint`, `pnpm typecheck`, and
   `pnpm build`; visual changes are broad but behavior is untouched.

3. **Shared primitive restyle.** Update only `components/ui/*` primitives listed above. Keep all current
   exports and existing variant names working; add aliases rather than renaming (`Button default` remains
   the primary style, `Badge destructive` remains the danger style, etc.). Align button, badge, card,
   input/textarea, select, dropdown/popover, dialog/sheet, and tooltip classes to the token bridge.
   Avoid hardcoded color utilities except the prototype violet `ai` accent where no shared Focal token
   exists. Verify with `pnpm typecheck` to catch variant-union regressions and `pnpm test:run` to catch
   behavior regressions in consumers.

4. **Sidebar shell restyle.** Update `ui/sidebar.tsx`, `AppShell.tsx`, `AppSidebar.tsx`, and
   `CalendarSwitcher.tsx`. Use the existing public app icon/favicon for the brand mark instead of adding
   a new asset. Match the prototype sidebar width, header spacing, group labels, nav row heights, active
   row background, meeting badge tone, calendar switcher shell, footer spacing, collapsed icon rail, and
   mobile off-canvas sheet. Do not change the nav arrays, route hrefs, dashboard-only filtering, meeting
   query, sign-out callback, offline indicator behavior, or calendar refresh invalidation. Verify with
   `pnpm test:run -- src/components/AppShell.test.tsx` and then the full `pnpm test:run`.

5. **Top bar and toolbar restyle.** Update `PageHeader.tsx` and `PageToolbar.tsx`. Match the prototype
   header height, border, icon badge, title scale, help icon/tooltip treatment, slot layout, and compact
   right cluster. Change the AI button to `variant="ai"` from the shared button primitive. Preserve the
   existing `navigate('/aichat')`, `useTheme().toggle`, and `i18n.changeLanguage` calls exactly; keep the
   timezone chip out of scope. Check desktop and mobile widths so title/actions wrap without overlap.

6. **Final verification and visual QA.** Run the full acceptance command sequence from the task, then
   inspect the app in light and dark. Capture after screenshots for shell and representative primitive
   states, compare against the prototype references, and confirm there are no feature-screen layout
   edits. If any verification fails, fix only the file/slice that introduced the failure and rerun the
   failing command plus the full gate sequence.

# Tests

- `cd superapp/apps/focal/client && pnpm lint`: proves the edited TypeScript/CSS-adjacent class code still
  satisfies Biome formatting and static rules.
- `pnpm typecheck`: proves the shadcn primitive APIs stayed source-compatible, especially the `Button` and
  `Badge` variant unions after adding aliases and the `ai`/semantic variants.
- `pnpm test:run -- src/components/AppShell.test.tsx`: proves the shell still renders the app label and
  children, sign-out still calls the auth callback, and dashboard nav visibility still follows
  `canAccessDashboard`.
- `pnpm test:run`: proves the class-only primitive and shell changes did not break existing feature,
  offline, i18n, API, or component behavior tests.
- `pnpm build`: proves Tailwind 4 and Vite can compile the bridged token variables, new theme entries, and
  changed class strings into a production bundle.
- `pnpm check:i18n` if locale files are touched: proves any new shell key exists in both locales and no
  extraction drift was introduced.
- Light and dark visual screenshots of the sidebar, page header/toolbar, and a primitive sampler: prove
  design-language parity with `Shell.jsx`, `Primitives.jsx`, and `app.css`. These are manual visual checks,
  not pixel-diff gates.
- Manual behavior spot checks after visual QA: sidebar collapse/expand, mobile sidebar close on nav,
  calendar refresh, meeting badge presence when count is nonzero, sign-out button, AI navigation, theme
  toggle, language switcher, dialog/sheet escape/overlay close, select/dropdown keyboard navigation, and
  tooltip hover/focus. These prove behavior was preserved where no focused unit test exists.

# Error & rescue map

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| `token-bridge-missing-var` | No thrown exception; a CSS variable resolves invalid or falls back | Visual QA, browser devtools computed styles, `pnpm build` if syntax is invalid | Wrong color, transparent surface, or missing focus/overlay styling |
| `token-format-break` | No thrown exception; HSL triplet format is broken so `bg-primary/10` style utilities compute incorrectly | Visual QA in light/dark and review of `index.css` token format | Alpha-based accents, borders, or badges render too strong, too weak, or not at all |
| `primitive-variant-api-break` | TypeScript compile error for removed/renamed variant values | `pnpm typecheck` | Build is blocked before users see it |
| `primitive-visual-regression` | No thrown exception; class changes alter dimensions, radius, focus, or disabled state unexpectedly | Primitive screenshots and focused manual keyboard checks | Buttons, badges, fields, menus, dialogs, or tooltips look unlike the prototype or lose visible focus |
| `sidebar-behavior-drift` | No thrown exception; callback/query/render condition changes accidentally | `AppShell.test.tsx` and manual sidebar checks | Sign-out fails, dashboard link appears for the wrong user, mobile sidebar stays open after nav, or meeting badge disappears |
| `toolbar-behavior-drift` | No thrown exception; click handlers are changed or dropped | Manual AI/theme/language spot checks | AI button does not navigate, theme does not toggle, or language menu does not switch locale |
| `responsive-overlap-regression` | No thrown exception | Desktop and mobile screenshots at narrow and wide widths | Header title/actions, toolbar buttons, or sidebar footer overlap or truncate unprofessionally |
| `i18n-hardcoded-label` | No thrown exception | Code review and `pnpm check:i18n` if locale files are touched | Mixed-language or untranslated shell text |
| `overlay-accessibility-drift` | No thrown exception from Radix; behavior can degrade if classes hide focus or block pointer events | Manual select/dropdown/dialog/sheet/tooltip keyboard and pointer checks | Menus or modals are hard to open, close, read, or navigate |

# Review lenses (pre-answer before gate2-plan)

- **Scope / strategy** - This is the minimum viable foundation slice: bridge token values, restyle the
  existing shell, and align shared primitives. It deliberately avoids the rejected replace/hybrid token
  strategies, feature-screen layout work, new behavior, new dependencies, and primitive prop redesign.
  The decision is reversible because token mapping is isolated in `index.css` and component changes are
  class-level.
- **Architecture** - No server/API/data flow changes. Client state remains where it is today:
  `SidebarProvider` owns collapse/mobile state and localStorage, `AppSidebar` owns nav rendering and
  existing queries, `PageToolbar` owns theme/language/AI handlers through existing hooks. Radix primitives
  keep their accessibility and state machines; this slice changes their class names only.
- **Design** - The foundation must pass light and dark parity for tokens, shell, and primitives. Empty,
  loading, and error states are not redesigned here because feature-screen internals are out of scope, but
  shared disabled/focus/overlay states are part of the primitive pass. Responsive checks cover collapsed
  sidebar, mobile off-canvas sidebar, narrow page headers, and wrapped toolbar controls.
- **DevEx** - Future screen slices continue using familiar shadcn tokens and primitive APIs. Inline comments
  in `index.css` should document the bridge mapping once, not scatter palette knowledge through components.
  Variant aliases avoid forcing every current consumer to learn a new API during this foundation slice.

# Risks & migrations

- No database migrations, data backfills, config changes, server changes, lockfile changes, or dependency
  bumps are planned.
- **Reviewer-visible diff risk:** the app tree is currently untracked relative to the repository baseline.
  Resolve before gate 4 with a user-approved baseline commit or `git add -N`; otherwise review/ship gates
  may not see the actual shell and primitive diff.
- **Visual subjectivity risk:** "matches the design language" is not unit-testable. Mitigation is explicit
  reference screenshots and after screenshots for shell and primitives in both themes, plus reviewer checks
  against the prototype files.
- **Token blast-radius risk:** changing shadcn token values affects every screen. Mitigation is bridge
  strategy, HSL-triplet preservation, aliases for existing variants, and full lint/typecheck/test/build
  after each code slice.
- **Behavior regression risk:** visual edits can accidentally touch handlers while moving markup. Mitigation
  is to preserve existing logic blocks and imports, rely on `AppShell.test.tsx` for covered shell behavior,
  and manually spot-check toolbar/sidebar behavior that is not currently unit-tested.
- Rollback plan: revert the foundation slice as a single visual diff after the baseline is established. No
  persisted data or API contract changes need rollback.

# Scope check

- [x] Matches the task's Scope and Out of scope.
- [x] Small enough to review in one sitting per implementation slice; the whole foundation is intentionally
      split into token, primitive, sidebar, topbar, and final-QA slices.
- [x] Size smell: this touches many files because the requested foundation is exactly tokens + shell +
      primitives. The plan avoids screens, server code, dependencies, asset churn, and new abstractions to
      keep the diff surgical.

# Out of scope

- Feature-screen internals: calendar grid, goal map canvas, tasks board, habits, analytics, budgets,
  heatmap, dashboard, settings, projects, tags, and screen-specific empty/loading/error layouts.
- Importing `colors_and_type.css` wholesale, rewiring components to `--color-*`, or keeping two live token
  vocabularies for future consumers.
- Prima tokens and `[data-product="prima"]`.
- New behavior: timezone switching/chip, additional languages, additional nav destinations, new calendar
  dropdown behavior, new auth/offline behavior, or any server/API/contract change.
- Public primitive API redesign, breaking variant renames, new shadcn components, dependency bumps, or
  lockfile changes.
- Editing `src/offline/*`, feature tests, generated `dist/*`, public assets, or screenshots as part of the
  implementation diff.

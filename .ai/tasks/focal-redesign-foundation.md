# Goal

Bring the **new Focal client** (`superapp/apps/focal/client`) onto the **Allosta / Focal design system**
defined by the design prototype at `superapp/design/focal`, starting with the **foundation slice**: the
**design tokens**, the **app shell** (sidebar, top bar, page header), and the **shared UI primitives**
(button, badge, card, input, select, dialog/sheet, tooltip). After this slice, every later per-screen
slice inherits a correct token layer and a shell/primitive set that already matches the prototype, so
screen work becomes layout-only.

First of an ordered set of design slices (this `foundation` slice, then one slice per feature screen:
calendar, goal-map, tasks, habits, analytics, budgets, heatmap, …). Fidelity bar set with the user:
**adopt the design language 1:1** (tokens, shell, primitives reproduced exactly), **screens faithful to
the macro layout** but built idiomatically in the production stack — **not** pixel-measured.

> **Binding visual contract = the design prototype** at `superapp/design/focal`
> (`colors_and_type.css`, `app.css`, `Shell.jsx`, `Primitives.jsx`, `App.jsx`, and the reference
> images under `screenshots/`). Cited token names / values there are the authority for this slice.
> The **old working app** at `superapp/apps/old-focal` is the **behavioral/content oracle** only
> (what the shell must still *do* — routing, calendar switching, sign-out, offline, i18n) — **not** a
> visual source. The thing being changed is `superapp/apps/focal/client`.

> **Token strategy = bridge (decided with the user).** Keep the **shadcn token names** the 28
> primitives already consume (`--primary`, `--background`, `--secondary`, `--muted`, `--border`,
> `--ring`, `--sidebar-*`, `--card`, `--popover`, `--destructive`, …) and re-anchor their **values**
> to the Focal palette from `colors_and_type.css` (e.g. `--primary` ← `--focal-blue-500 #407be9`),
> **adding** the semantic tokens the design needs that shadcn lacks (success / warning / info, the
> raised/sunken surface split, accent-subtle). Do **not** import `colors_and_type.css` wholesale and
> do **not** rewire primitives onto `--color-*` — that is the rejected "replace" strategy (it touches
> every UI component and pulls in Prima). Format stays **HSL triplets** so shadcn alpha utilities
> (`bg-primary/10`, `border-yellow-950/30`) keep working.

> **Frontend-only, no behavior change.** No FastAPI/server edits, no API/contract changes, no new
> product features. Routing, auth gating, the dashboard-only nav item, the meeting-requests badge
> count, the offline indicator, calendar switching, and theme persistence all behave exactly as they
> do today — only their **appearance** is brought to the prototype. All user-facing strings stay in
> i18next (`ru` + `en`); no hardcoded text is introduced.

# Scope

**Design tokens — `apps/focal/client/src/index.css`**

- Re-anchor the existing `@theme inline` + `:root` / `.dark` shadcn HSL tokens to the Focal foundation
  scales from `superapp/design/focal/colors_and_type.css` LAYER 1: **blue** (brand, anchor
  `#407be9`), **green** (success/`#1baf73`), **sand** (warm neutrals), **amber** (warning), **coral**
  (danger). Introduce these raw scales as CSS variables and map them onto the shadcn semantic names
  (no name churn in components).
- **Add the missing semantic tokens** the prototype uses but shadcn omits: state **success** /
  **warning** / **info** (today only `--destructive` exists), the **surface raised vs sunken** split
  (`--color-bg-surface-raised` / `-sunken` equivalents the shell needs), and an **accent-subtle**
  background (used by the top-bar icon badge and active nav rows).
- Confirm/align the non-color tokens already present against the prototype: **radius**
  (8/12/16/20px = `0.5/0.75/1/1.25rem` — already matches), **soft shadows** (already the Allosta
  diffused set), **motion** easings/durations (`--ease-out`, `--duration-*` from the prototype),
  **focus ring** (2px accent outline + 2px offset). Keep the `.dark`-class strategy and the
  `hover-elevate` / `active-elevate` system intact; re-anchor their values to the prototype.
- **Dark-mode parity**: every re-anchored token gets a `.dark` value derived from the prototype's
  FOCAL — DARK block.

**App shell — `apps/focal/client/src/components/{AppShell,AppSidebar,CalendarSwitcher,PageHeader,PageToolbar}.tsx`**

- Bring the **sidebar** to the prototype `Shell.jsx`: brand header (icon + "Focal" + tagline), the
  **calendar switcher**, the **nav groups** (Целеполагание / Исполнение / Аналитика / Помощник /
  Настройки) with prototype paddings, sizes, active-row treatment, group-label caps, and the footer
  cluster (user email + offline + sign-out). Preserve the icon-collapse behavior, the dashboard-only
  filtering, and the meeting-requests badge — restyled to the prototype badge.
- Bring the **top bar / page header** to the prototype `TopBar`: the accent **icon badge** + title,
  optional help tooltip, left/center/right action slots, and the **right cluster** (AI-assistant
  button, theme toggle, language switcher). **Preserve** the behavior already wired in
  `PageToolbar.tsx` — theme toggle, **language switching** (`i18n.changeLanguage`, ru/en), and the AI
  nav (→ `/aichat`) — restyling only their appearance. The prototype's timezone chip has **no**
  counterpart in the app and is **not** added (real tz switching is out of scope).
- Keep `AppShell`'s mobile off-canvas sidebar + slim mobile top bar; restyle to match.

**Shared primitives — `apps/focal/client/src/components/ui/*.tsx`**

- Align the **button** variants to the prototype `Primitives.jsx` (`primary` / `secondary` / `ghost`
  / `outline` / `destructive`, plus the **`ai`** violet variant), with the prototype heights, padding,
  radius, weight, soft shadow, and hover-elevate.
- Align **badge** tones to the prototype (`neutral` / `accent` / `success` / `warning` / `danger` /
  `violet`), **card** (raised surface + subtle border + `--shadow-xs` + `--radius-lg`), **input** /
  bare-select look, **dialog/sheet** (radius `xl`, `--shadow-xl`, overlay token), and **tooltip**.
- Only token-level/value and variant alignment — **no API changes** to the primitives' props, so
  consuming screens keep compiling unchanged.

**Cross-cutting**

- Surgical: touch only the token file (`index.css`), the five shell files, the consumed `ui/*`
  primitives, and — only if needed — `i18n/locales/{ru,en}.json` (a new shell label, both locales)
  and `AppShell.test.tsx` (structural class updates). Do **not** restyle feature-screen internals
  (deferred to per-screen slices). Do **not** change any component's public props, routing, data
  fetching, or existing i18n keys.

# Out of scope

- **Feature-screen layouts** — calendar grid, goal-map canvas, tasks board, habits, analytics,
  budgets, heatmap, dashboard, settings, etc. Each is its own later slice; this slice only restyles
  the shell + primitives those screens compose.
- **The "replace" token strategy** — importing `colors_and_type.css` as the source of truth and
  rewiring primitives onto `--color-*`. Rejected with the user in favor of the bridge.
- **Prima tokens / the `[data-product="prima"]` block** — Focal-only here.
- **New behavior** — real language switching, real timezone switching, any new nav destination, any
  server/API/contract change. Visual-only.
- **Wholesale primitive API redesign**, new shadcn components not already in `ui/`, and any dependency
  bump beyond what the restyle strictly needs.

# Acceptance criteria

- [ ] `cd superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`
      all green; any `pnpm-lock.yaml` change committed.
- [ ] **Token bridge:** the shadcn semantic tokens resolve to the Focal palette — `--primary` is the
      brand blue (`#407be9` family), `--destructive` the coral, and **success / warning / info**
      tokens now exist; primitives consume the **same token names** as before (no name churn). Format
      stays HSL triplets (shadcn alpha utilities still resolve).
- [ ] **Shell parity:** sidebar (brand, calendar switcher, the five nav groups, active row, footer)
      and top bar / page header (icon badge, title, right cluster) visually match
      `superapp/design/focal/Shell.jsx`, in **both** light and dark.
- [ ] **Primitive parity:** button (incl. the `ai` variant), badge tones, card, input, select,
      dialog/sheet, tooltip match `superapp/design/focal/Primitives.jsx` + `app.css`, in light + dark.
- [ ] **Behavior preserved:** the existing `AppShell.test.tsx` stays green — it asserts
      app-label/children render, sign-out, and dashboard-link show/hide gating
      (`AppShell.test.tsx:34-67`), updated only for structural class changes. The other behaviors
      change only cosmetically — routing, auth gate, meeting-requests badge count, offline indicator,
      calendar switching, **theme + language switching** — preserved **by construction** (logic
      untouched) and spot-checked in the preview.
- [ ] **i18n:** no hardcoded user-facing strings; any new shell label exists in both `ru` + `en`.
- [ ] **Surgical:** the diff touches only `index.css`, the five shell files, the consumed `ui/*`
      primitives, and — only if needed — `i18n/locales/{ru,en}.json` and `AppShell.test.tsx` — no
      feature-screen layout changes, no primitive prop/API changes, no server changes.
- [ ] Visual parity is demonstrated with before/after screenshots of the shell + a primitives sampler,
      light and dark, against the prototype reference.

# Verification commands

```sh
# from the pipeline root
cd superapp/apps/focal/client
pnpm install --frozen-lockfile
pnpm lint            # biome
pnpm typecheck       # tsc -b
pnpm test:run        # vitest (non-watch)
pnpm build           # tsc -b && vite build
```

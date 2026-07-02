# Problem

The new Focal client (`superapp/apps/focal/client`) is a working React 19 + Tailwind 4 + shadcn/ui
migration of the legacy app, but its visual language is generic shadcn defaults — not the **Allosta /
Focal design system** the team has specified. That design system exists as a high-fidelity prototype
at `superapp/design/focal` (a vanilla-React reference with a two-layer token file, a styled shell, and
styled primitives + reference screenshots). The user wants the running app brought onto that design.

A whole-app reskin is too large to land or review in one pass, so this work is **sliced**. This think
doc frames the **foundation slice**: the **design tokens**, the **app shell** (sidebar, top bar, page
header), and the **shared UI primitives**. Everything downstream (the ~15 feature screens) composes
these, so getting the foundation right first means each later screen slice is layout-only against a
correct token + primitive base. It matters now because every screen slice built before the foundation
would have to be re-touched after it.

# Assumptions

- **[confirmed — user]** Token strategy is **bridge**: keep the shadcn token *names* the 28 primitives
  already consume and re-anchor their *values* to the Focal palette; do not import
  `colors_and_type.css` wholesale or rewire primitives onto `--color-*`.
- **[confirmed — user]** Slicing is **foundation-first**, then one slice per screen; each slice runs
  the full 7-gate pipeline.
- **[confirmed — user]** Fidelity is **design language 1:1** (tokens / shell / primitives reproduced
  exactly), **screens faithful** to the macro layout but built idiomatically in shadcn/Tailwind — not
  pixel-measured.
- **[confirmed — inspection]** Fonts already match the prototype — `InterVariable` + `JetBrains Mono`
  are wired in `index.html` + `@theme` (`apps/focal/client/src/index.css:58-60`); no font work needed.
- **[confirmed — inspection]** The shell is structurally already close: `AppSidebar.tsx` has the five
  nav groups, a `CalendarSwitcher`, dashboard-only filtering, and the meeting badge; `PageHeader.tsx`
  self-describes as matching "the design TopBar". So this slice is **re-styling existing structure**,
  not building it from scratch.
- **[confirmed — inspection]** The brand blue is already the primary anchor (`--primary: 219 79% 58%`
  ≈ `#407be9`) and radius/shadows already use the soft Allosta scale — the bridge is **partially in
  place**; this slice completes and corrects it, not invents it.
- **[unverified]** The prototype is the **authoritative** visual target (vs the old app's look). Taken
  as given by the request ("новый дизайн").
- **[confirmed — inspection]** The violet **`ai`** accent is already in use: `PageToolbar.tsx:32-40`
  styles the AI-assistant button `border-violet-300 text-violet-600`, matching the prototype's `ai`
  button (`Primitives.jsx` `ai` variant, `#7c3aed`). This slice keeps it.
- **[confirmed — inspection]** The shared top-right cluster already wires **real behavior** —
  theme toggle (`useTheme`), **language switching** (`i18n.changeLanguage`, ru/en), and the
  AI-assistant nav (→ `/aichat`) in `PageToolbar.tsx:24-76`. There is **no** timezone control in the
  app (the prototype's "Bangkok" chip has no counterpart). This slice **preserves** the theme +
  language + AI behavior and restyles only their appearance; it does **not** add a timezone control
  (real tz switching would be new behavior, out of scope; a non-functional chip will not be added).
- **[unverified — needs a process decision]** The current Focal client is an **uncommitted working
  tree**: `HEAD` is a stub (`index.css` = 5 lines; `components/` = only `AppShell`), while the live
  app is 44 modified + 19 untracked files — the **entire shell + `ui/` primitives are untracked**.
  Since `git diff` does not show untracked files, the diff-based gates (4 build / 5 review / 7 ship)
  cannot see edits to `AppSidebar.tsx` or `ui/*.tsx` until a **baseline commit** establishes the
  current state as `HEAD`. This must be resolved before gate 4 (see Open questions).

# Options considered

The central technical fork is **how the design tokens reach the production stack**. (Slicing and
fidelity were decided directly with the user and are recorded under Assumptions / Recommendation.)

| option | what it is | pros | cons |
|--------|-----------|------|------|
| **A — Bridge (chosen)** | Keep shadcn token names; re-anchor their HSL values to the Focal palette; add the few missing semantic tokens (success/warning/info, surface raised/sunken, accent-subtle). | Zero name churn across 28 primitives + every screen; lowest-risk, smallest diff; shadcn alpha utilities keep working; design fidelity lives in *values*, which is exactly what differs. | Two vocabularies coexist (shadcn names carrying Focal values); a reader must know the mapping; semantic tokens the design has but shadcn never named must be added by hand. |
| **B — Replace** | Import `colors_and_type.css` as the source of truth; rewire every primitive + the shell from `--background`/`--primary` onto `--color-bg-canvas`/`--color-accent`. | Cleanest 1:1 with the prototype's own token names; one vocabulary. | Touches **every** `ui/*` component and consuming screen; pulls in the Prima block + `[data-product]` selector machinery; large, churny diff; high regression surface in shadcn internals — directly against Surgical Changes. |
| **C — Hybrid** | Bridge for the core shadcn tokens **and** expose `--color-*` Allosta tokens alongside for new screen work. | Flexibility for later screens to use either name. | Two *live* token systems to keep in sync forever; ambiguity over which to use; speculative — no consumer needs `--color-*` yet (against Simplicity First). |

# Recommendation

Take **Option A (bridge)**, as agreed with the user. It is the minimum change that achieves design
1:1: what visually differs between the app and the prototype is almost entirely **token values**,
**shell composition detail**, and **primitive variants** — not token *names*. Re-anchoring values and
adding the handful of semantic tokens the design needs (success / warning / info, raised vs sunken
surface, accent-subtle) gets the whole app onto the Focal palette while leaving the 28 primitives and
every screen compiling unchanged. The tradeoff accepted: a reader must understand that the shadcn
names now carry Focal values — documented inline in `index.css` where the mapping lives.

On **structure**: this slice **re-styles existing files** (`index.css` + the five shell components +
the consumed `ui/*` primitives), not new architecture. On **slicing**: foundation first so each later
screen slice is layout-only. On **fidelity**: the shell + primitives are reproduced exactly against
`Shell.jsx` / `Primitives.jsx` / `app.css`; screens are deferred. The old app
(`apps/old-focal`) is consulted **only** to preserve behavior (routing, calendar switching, sign-out,
offline, i18n), never as a visual source.

# Out of scope

- Feature-screen internal layouts (calendar grid, goal-map canvas, tasks board, habits, analytics,
  budgets, heatmap, dashboard, settings) — each a later per-screen slice.
- The replace/hybrid token strategies (B/C above).
- The Prima token block / `[data-product="prima"]`.
- Any **net-new** behavior: a timezone control, additional languages or nav destinations, or
  rewiring the existing theme/language switches beyond restyling. (The theme + language switching that
  already exists is **preserved**, not added — see Assumptions.)
- Any server / API / contract / migration change. Frontend-only.
- Primitive public-prop/API redesign; new shadcn components not already in `ui/`; dependency bumps
  beyond what the restyle strictly needs.

# Open questions

- **Baseline commit before gate 4 (process — needs the user).** The shell + `ui/` primitives are
  untracked, so the diff-based gates can't see their changes. Recommended resolution: commit the
  current Focal-client WIP on `feature/focal-migration` as a baseline (house rule: commit only when
  the user asks), so the redesign lands as an isolatable diff. Alternative: `git add -N`/stage the
  untracked files so they appear in `git diff`. Not needed until gate 4; gates 1–3 are unaffected.
- **Verifiability of "looks like the design" (method, not blocker).** Visual fidelity is not
  unit-testable. This slice proves it via green lint / typecheck / test:run / build, the existing
  `AppShell.test.tsx` staying green (it asserts app-label/children render, sign-out, and
  dashboard-link show/hide gating — `AppShell.test.tsx:34-67`), and before/after screenshots
  (light + dark) against the prototype. Behaviors **not** in that test (routing, calendar switching,
  offline, meeting badge, theme + language persistence) are preserved **by construction** — this slice
  changes only class names/tokens, not their logic — and are spot-checked in the preview, not newly
  unit-tested. Pixel-diffing is explicitly not the bar (fidelity = 1:1 language, faithful layout).

# Success criteria

- [ ] `cd superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`
      all green.
- [ ] shadcn semantic tokens resolve to the Focal palette (primary = brand blue, destructive = coral),
      and **success / warning / info** + raised/sunken surface + accent-subtle tokens now exist — with
      **no token-name churn** in primitives and HSL-triplet format preserved.
- [ ] Sidebar + top bar / page header visually match `superapp/design/focal/Shell.jsx` in light **and**
      dark.
- [ ] Button (incl. `ai`), badge tones, card, input, select, dialog/sheet, tooltip match
      `superapp/design/focal/Primitives.jsx` + `app.css` in light **and** dark.
- [ ] `AppShell.test.tsx` stays green — it asserts app-label/children render, sign-out, and
      dashboard-link show/hide gating (`AppShell.test.tsx:34-67`); update it only for structural class
      changes, behavior assertions unchanged.
- [ ] Behavior preserved **by construction** (logic untouched; only classes/tokens change): routing,
      auth gate, meeting-badge count, offline indicator, calendar switching, sign-out, and **theme +
      language switching** — spot-checked in the preview (light + dark).
- [ ] No hardcoded user-facing strings; any new shell label present in `ru` + `en`.
- [ ] Diff touches only `index.css`, the five shell files, the consumed `ui/*` primitives, and — only
      if needed — `i18n/locales/{ru,en}.json` (a new shell label) and `AppShell.test.tsx` (structural
      class updates). No screen layout changes, no primitive prop/API changes, no server changes.
- [ ] Before/after screenshots (shell + primitives sampler, light + dark) demonstrate parity with the
      prototype.

# Findings: focal-analytics-section-order

> Output of the **explore gate** (`/gate-explore`). Two independent takes — Opus and GPT —
> synthesized. Small and findings-first; raw per-model answers in `.ai/scratch/` (gitignored).
> Not scored. Date: 2026-06-27.

Topic: the section **order** on the Analytics page differs between old focal
(`apps/old-focal/client/src/pages/Analytics.tsx`) and new focal
(`apps/focal/client/src/features/analytics/AnalyticsPage.tsx`). User attached 4 screenshots of the
OLD focal analytics page.

## Questions

1. What is OLD focal's analytics section render order?
2. What is NEW focal's analytics section render order?
3. How exactly do they differ — sections missing/extra, or pure order?
4. Why do they differ — intentional design decision or accidental bug?
5. What is the minimal, safe fix to restore the old order, and what breaks?
6. Should the order be restored (given the 100%-old-focal-parity mandate)?

## Consensus

> Both models reached these independently from the code. High confidence; evidence cited.

- **OLD order = Mission → Energy → Spheres → Deep Work → Projects → Products.** Confirmed two ways:
  the 4 screenshots, and the JSX render block — РАЗДЕЛ 1 Mission `Analytics.tsx:1934`, 2 Energy `:2259`,
  3 Spheres `:2595`, 4 Deep Work `:3002`, 5 Projects `:3168`, 6 Products `:3503`. (The earlier
  *compute*/useMemo blocks use a different legacy numbering — ignore them; the JSX is authoritative.)
  Confidence: High.

- **NEW order = Spheres → Mission → Projects → Products → Energy → Deep Work.** `AnalyticsPage.tsx`
  renders `<SpheresSection>` `:139`, `<MissionSection>` `:150`, `<ProjectsSection>` `:161`,
  `<ProductsSection>` `:172`, `<EnergySection>` `:182`, `<DeepWorkSection>` `:193`. Confidence: High.

- **Same six sections — none missing, none added. The user-reported issue is a pure reorder** (in the
  data state where products exist). Position map:

  | OLD | section | → NEW position |
  |---|---|---|
  | 1 | Mission | 2 |
  | 2 | Energy | 5 |
  | 3 | Spheres | 1 |
  | 4 | Deep Work | 6 |
  | 5 | Projects | 3 |
  | 6 | Products | 4 |

  Confidence: High.

- **Secondary, non-order gap GPT surfaced and verified: Products visibility differs.** OLD renders the
  Products card **conditionally** — `Analytics.tsx:3504` wraps it in `{parentProjectsWithProducts.length
  > 0 && (...)}` (hidden when the user has no products). NEW renders `<ProductsSection>`
  **unconditionally** (`AnalyticsPage.tsx:172`). In the user's screenshots products exist, so both show
  it; the divergence only bites on empty-product accounts. Confidence: High.

- **Cause: a deliberate redesign-era reorder — NOT a bug — but the new code's own docstring is false.**
  The parity slice-9 design scoped order *out*: `focal-parity-analytics-design.md:29-30` ("the new app
  **deliberately reordered** sections... feature-parity, **not DOM-order parity**") and `:131`
  (out-of-scope: "Section DOM reordering to match old-focal (intentional new-app layout, kept)").
  **Contradiction:** `AnalyticsPage.tsx` (~`:40-46`) docstring claims the sections are stacked
  "(Spheres → Mission → Projects → Products → Energy → Deep Work, **the old-focal order**)" — which is
  factually wrong; that is not the old-focal order. And **no UX rationale is documented anywhere** —
  the redesign analytics docs never mention the reorder; only the two parity-doc lines do, neither with
  a reason. Confidence: High.

- **The fix is small, safe, and frontend-only — but it is JSX + 2 comments + 1 test, not JSX alone.**
  Reorder the six JSX blocks in `AnalyticsPage.tsx:139-202` to Mission → Energy → Spheres → Deep Work
  → Projects → Products, and correct the two stale comments (`:20-23` SectionId comment + `:40-46`
  docstring). Safe because the sections are **data-independent siblings** — all fed from the one
  `useSpheresAnalyticsData(range, year)` result (`:57`); no cross-section deps. The PDF export follows
  automatically (it captures direct children in DOM order — `analyticsExport.ts:107-110,154`).
  **One test breaks and must be updated** (GPT caught this; Opus initially under-rated it):
  `AnalyticsPage.test.tsx:133-134` collapses section `[0]` and asserts no `<table>` — today `[0]`=Spheres
  (the only table in the mock state), after reorder `[0]`=Mission (no table) so Spheres' table stays and
  the assertion fails. Confidence: High on mechanics.

- **Both models recommend restoring the old order.** The focal-parity epic targets 100% old-focal
  parity with old-focal as the *exact binding source* (`focal-parity-analytics-design.md:10-11`),
  section order is user-visible behavior, the user is actively flagging it, and the code's own docstring
  already claims it *should* be old-focal order. Confidence: High that it's consistent with the mandate;
  the final call is the user's (it reverses a signed-off scope decision — see Divergence).

## Divergence

> Opus and GPT did not disagree on any fact here — they converged. The real fork is a **decision for
> you**, because restoring the order *reverses a documented, approved slice-9 choice*.

- **Restore the section order to old-focal?**
  - Both models: **Yes** — parity mandate + user-flagged + the docstring already claims it.
  - Counter-weight: slice-9 explicitly declared DOM-order out of scope and was **approved 9.4** that
    way (`focal-parity-analytics-handoff.md`). Reversing it is small but should be done knowingly.
  - **Decision needed:** confirm "yes, match old-focal order exactly." (My default: yes.)

- **Also restore OLD's *conditional* Products visibility** (hide the Products card when the user has no
  products), or keep NEW's always-render?
  - **Decision needed:** strict parity → hide-when-empty; simpler/always-visible → keep NEW. (My
    default: hide-when-empty, since it's the same binding-source logic and a trivial wrap.)

- **Period selector: per-section (OLD) vs one hoisted header control (NEW).** OLD has a Месяц/period
  picker inside *each* section (visible in the screenshots); NEW hoisted it to a single PageHeader
  control (`focal-parity-analytics-design.md:29`). Adjacent to the reported issue, not the issue itself.
  - **Decision needed:** keep the single hoisted selector (cleaner; my default), or restore per-section
    selectors for pixel-strict parity?

## Open

- **Was there ever a real UX reason for the redesign reorder?** It's asserted "intentional" but never
  justified in any doc. To close: only you know (it was your redesign) — if there was a deliberate UX
  intent, that would argue for keeping the new order despite the parity mandate.

## Decisions (user, 2026-06-27)

1. **Restore section order to old-focal — YES.**
2. **Restore conditional Products visibility — YES** (hide when no root project owns a product).
3. Period selector — left as the single hoisted header control (default; not raised as a complaint).

## Implemented (2026-06-27, lite — no gate flow)

Surgical frontend-only change in `apps/focal/client/src/features/analytics/`:
- **Reordered** the JSX section blocks in `AnalyticsPage.tsx` to Mission → Energy → Spheres → Deep Work
  → Projects → Products (old-focal order). PDF export follows DOM order automatically.
- **Gated Products** on `parentProjectsWithProducts(data.projects).length > 0` — old-focal's exact
  page-level condition (`old-focal/.../Analytics.tsx:3504`).
- **Fixed** the false docstring + the `SectionId`/`ALL_EXPANDED` order comment (now honestly old-focal
  order).
- **Updated** `AnalyticsPage.test.tsx`: the collapse test now targets the Spheres card via the table
  (`.shadcn-card` closest), order-independent.

Gates (run in `apps/focal/client`): `pnpm typecheck` clean · `pnpm exec biome check` clean on the 2
touched files · `pnpm test:run src/features/analytics` 160/160 pass · `pnpm build` ok.

**Merged** to `feature/focal-migration` via PR #102 (squash `3bc496d`); slice branch pruned (local +
remote). Built on an isolated git worktree off `feature/focal-migration` so the user's concurrent
`feat/focal-parity-calendar-buttons` branch was never touched.

## Open

- Period selector per-section (old) vs hoisted (new) — deferred by decision 3; revisit only if strict
  layout parity is later required.

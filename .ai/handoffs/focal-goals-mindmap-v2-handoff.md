# Stage
3-gate C (verify + ship) for `focal-goals-mindmap-v2` — Goals map layout & connections redesign.
Branch `feature/focal-goals-mindmap-v2` → base `feature/focal-migration`. Frontend-only.

# What changed
Four committed slices per `.ai/design/focal-goals-mindmap-v2-design.md`, plus the verify doer's
added ordering test:
1. **Layout core** — `layoutTree` rebuilt on d3-flextree (variable card sizes on both axes,
   contour packing) over a domain-derived `parents` map exported by `buildGraph`; one-shot
   re-layout after the cards report real measured sizes (guarded per payload, never persists).
2. **MAP mode** — third auto-arrange option: the classic two-sided mind map (single-child chain as
   a centred vertical spine, hub subtrees dealt greedily onto the lighter side, left side
   mirrored), localized ru+en.
3. **Edges v2** — the layout stamps each node's side toward its parent; `FloatingEdge` resolves
   anchor sides by a three-step precedence (persisted `mindmap_edges` handle → stamped side within
   a fixed 24px-biased boundary → geometry), distributes source anchors into per-sibling face
   segments (no shared-pixel fans, however far children are dragged), and the persisted per-edge
   styling already delivered in `init.edges` finally renders (field-whitelisted; null dash keeps
   the built product/activity dash — legacy `applyEdgeStylesFromDb` parity).
4. **Local create placement** — a newly created project/product/activity is born next to its
   parent card: the create APIs return the created id, `newNodeSlot` computes a collision-swept
   slot on the parent's open side, the slot is persisted before the refetch, and create refetches
   freeze every already-rendered card in place (pinned or not; the follow-up measured pass reuses
   the frozen pin map). Id-less responses recover via an id-diff over the refetched payload;
   ambiguous diffs keep the computed slot.

# Files touched
- apps/focal/client/package.json, pnpm-lock.yaml (root) — + d3-flextree@2.1.2
- apps/focal/client/src/types/d3-flextree.d.ts — new ambient declaration
- apps/focal/client/src/features/goals/layout.ts — flextree rewrite + MAP + side stamping + newNodeSlot
- apps/focal/client/src/features/goals/graph.ts — parents map, relativeSide, sibling anchor ranks, applyEdgeOverrides
- apps/focal/client/src/features/goals/FloatingEdge.tsx — rewritten anchor/side resolution
- apps/focal/client/src/features/goals/GoalsPage.tsx — parents/measure/freeze wiring, MAP dropdown item, create placement flows
- apps/focal/client/src/api/mindmap.ts — createProduct/createActivity return the created id
- apps/focal/client/src/i18n/locales/en.json, ru.json — focal.goals.layout.map
- Tests: layout.test.ts, FloatingEdge.test.ts, graph.test.ts, graph.edgeOverrides.test.ts (new),
  GoalsPage.measure.test.tsx (new), GoalsPage.createPlacement.test.tsx (new), GoalsPage.test.tsx

# Tests run
```sh
# worktree apps/focal/client
pnpm lint          # PASS (1 pre-existing TimeGrid suppression warning)
pnpm typecheck     # PASS
pnpm vitest run src/features/goals   # 18 files / 191 tests PASS
pnpm test:run      # 135/136 files; 1753/1756 — only the 3 pre-existing TasksPage failures
pnpm build         # PASS (pre-existing chunk-size warning)
# base checkout apps/focal/client (feature/focal-migration)
pnpm vitest run src/features/tasks/TasksPage.test.tsx  # 3 failed | 30 passed → failures pre-existing
```

# Verification output
```sh
Gate C verify (GPT doer): no production defect found; added the id-less pillar-create ordering
test; biome PASS, tsc PASS, goals 191/191, full 1753/1756 (3 pre-existing), build PASS.
Gate C release review (fresh Opus): APPROVED 9.4/10, risk Low — all runs independently
reproduced, pre-existing failures re-proven on base.
```

# Still needs review
- The 3 failing TasksPage tests and the TimeGrid lint warning are pre-existing on
  feature/focal-migration (proven by running them on the base checkout; see build log).
- `OVERRIDE_COLOR` accepts any 1–20-letter word as a named colour — inert in React style objects;
  a stricter check is a possible follow-up.
- Collapse/expand of branches is intentionally out of scope (a follow-up slice; the layout already
  takes a node subset so it lands without a rewrite).

# PR / release notes (for users — stage 5)
The Goal map is now readable at any size and its connections follow the hierarchy:
- **Clean default structure.** The map packs by real card sizes (wide cards no longer force huge
  gaps), deep branches interleave instead of spreading, and the first paint refines itself once
  the cards are measured.
- **New “Mind map” arrangement.** Auto-arrange now offers Top-to-bottom, Left-to-right, and a
  classic two-sided Mind map with the pyramid spine in the centre and balanced branches on both
  sides (RU: «Ментальная карта»).
- **Connections that stay put.** Edges leave a parent from distinct, ordered points toward each
  child (no more all-lines-from-one-pixel fans) and no longer flip sides while you drag a card
  around its parent. Custom edge styles saved in the legacy app (colour, width, dash, arrows,
  attachment sides) now render again.
- **New cards appear where you expect.** Creating a project, product, or activity places the new
  card right next to its parent and keeps it there after reload — and nothing else on your map
  moves. Your manually arranged cards always stay exactly where you put them.
No backend, schema, or data changes — reverting the frontend commits fully rolls this back.
Contains no secrets, tokens, keys, or PII.

# Status
OPUS APPROVED (9.4) — gate C release review, 2026-07-02.

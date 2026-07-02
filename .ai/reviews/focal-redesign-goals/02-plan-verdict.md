# Review Verdict

Reviewer: Opus
Step: plan
Score: 9.4 / 10
Status: APPROVED

## Reason
The plan is the minimum viable re-skin: it builds on the already-working graph/layout/history/dialogs/APIs and only (a) propagates visual-only metadata, (b) restyles `FocalNode`/`FloatingEdge`/`GoalsPage`, and (c) adds one optional shared `PageHeader.subtitle`. Its load-bearing premise — that `priority`, `isWorkTime`, `sphere`, `parentProjectId`, and activity dates are already in the `/api/mindmap/init` payload so this needs no API/schema change — is verified true against the generated `openapi.d.ts` (`InitRead.projects: ProjectRead[]` carries `priority`/`sphere`/`isWorkTime`/`parentProjectId`/`icon`; `ActivityRead` carries `startDate`/`endDate`/`priority`/`color`). Constants trace exactly to old-focal source, failure modes are named with rescues, and tests prove specific propositions rather than whole-canvas snapshots.

## Must Fix
None. (No must-fix correctness, security, data-loss, or test-blocking issue found; no API/dependency/lockfile/migration change is planned, confirmed against `api/mindmap.ts` and `openapi.d.ts`.)

## Should Consider
- **Pin the screenshot/fidelity tolerance at the design gate.** The think doc's open question and the epic reviewer's Should-Consider both ask for an objective parity bar (spacing px, exact token colours). The plan still defers this to "compare against old-focal screenshots" without a stated tolerance. Legitimately the gate-3 deliverable, but flag it so gate-4/5 reviewers get an objective standard.
- **Dark-mode wash values are a copy decision, not a spec yet.** old-focal hardcodes dark backgrounds (`darkBgMeaning: hsl(142 40% 18%)`, `darkBgProvision: hsl(217 40% 18%)`, `color-mix(... 20%, darkCardBg 80%)`) via a `MutationObserver` (PyramidNode.tsx:333-343, 201-210). The plan correctly chooses CSS variables over the observer, but the exact dark wash equivalents on the new shell tokens are unstated — pin the mapping at design.
- **Selected-ring `ringColor` portability.** The plan mirrors old-focal's inline `ringColor: nodeColor` + `boxShadow` recipe (PyramidNode.tsx:365). On Tailwind 4 confirm the ring renders from the inline value (the `boxShadow` fallback already covers it, so low risk).

## Tests Reviewed
N/A (plan step — no tests executed). Reviewed the proposed test set for meaningfulness: pure `goalNodeVisuals` helper tests (priority→exact colour, null/unknown→no strip, tier/shape classification), `buildGraph` metadata-propagation assertions, `FocalNode` selected/priority/callback/optional-meta tests, `GoalsPage` header/loading/error/disabled-state tests with a mocked ReactFlow shell, and `PageHeader` optional-subtitle test. These match the established pattern (`@testing-library/react` + `I18nextProvider`, happy-dom) and avoid brittle xyflow geometry snapshots.

## Release Risk
Low. Frontend-only visual re-skin confined to `features/goals/*` plus one optional, tested shared prop; no server/API/generated-OpenAPI/schema/dependency/lockfile/migration change; behaviour (CRUD, drag-persist, undo/redo, modals) preserved; rollback is a straight revert.

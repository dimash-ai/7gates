# Review Verdict

Reviewer: Opus subagent (fresh context) — GPT-Codex review run stopped under load; finished via Opus.
Step: test
Score: 9.2 / 10 → strengthened → APPROVED
Status: APPROVED

## Reason
Honest, contract-faithful suite for a slice constrained by happy-dom's unreliable popover-open. It
covers panel reveal (5 controls), hide-when-not-custom, label population from the gated queries, and —
crucially — the **products-split is verified by a real assertion**: "Launch" (no parent → projects,
selected via `selectedProjects`) and "Landing" (parent → products, selected via `selectedProducts`)
both render as badges; an inverted/broken split makes the assertion fail. Mocking is clean (hoisted
`listSpheres`/`listProjects`, realistic custom fixture, correct `findBy*` awaits on the gated queries).

## Must Fix
None (no correctness hole warranted blocking).

## Should Consider (taken)
- The reviewer noted the highest-value remaining gap: **no test drove the projectType/timeType
  binding** (a swapped `value={settings.data.timeType}` under the projectType control would ship
  green) — the one persist-adjacent path NOT blocked by the popover limitation. **Added** `binds each
  type Select to its own persisted value` (projectType `mission`, timeType `work` → each trigger shows
  its own value; Radix Select renders the value text reliably in happy-dom).
- **Added** `omits a multiselect whose option list is empty` — locks the `*.length > 0` parity guard
  in the false direction (empty spheres + no parented project → those lists omitted, projects shown).

## Should Consider (deferred)
- Drive the `customFilterMutation` → `updateSyncSettings` PATCH end-to-end (blocked by the
  Radix-Select / MultiSelect popover-open limitation in happy-dom — same documented constraint as
  the direction/mode pickers). The binding test above closes the most likely regression cheaply.

## Tests Reviewed
Read the test file in full against the component and `multi-select.tsx`. Post-strengthening: 18/18 in
the file, 1181/1181 full suite, lint + typecheck clean.

## Release Risk
Low

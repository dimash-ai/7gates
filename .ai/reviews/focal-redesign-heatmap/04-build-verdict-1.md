# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.7 / 10
Status: BLOCKED

## Reason
The heatmap reskin is broadly faithful to the old-focal contract, keeps the scope to the expected 6 files, preserves the API/heatmap logic, and adds meaningful coverage. However, the new shared `MultiSelect` ships invalid nested interactive markup, which is a concrete accessibility/DOM correctness defect in a reusable primitive.

## Must Fix
- `multi-select.tsx:148` renders each option as a `<button>`, and `:156` places the shadcn `Checkbox` (a Radix checkbox root rendered as a button by `checkbox.tsx:11`) inside it → `<button>` inside `<button>`, invalid DOM + unreliable assistive-tech semantics for the new generic primitive.

## Should Consider
- `multi-select.tsx:51` keeps the search query after the popover closes, so reopening can show a stale filtered/empty list.
- `multi-select.tsx:43` has fallback user-visible English strings; current heatmap usage passes localized text, but future consumers could bypass i18n.
- `HeatmapPage.test.tsx:217` covers sphere filtering but not the analogous project/product multi-select paths the plan requested.

## Resolution
Fixed in the amended commit (633eeb2): replaced the nested Radix `Checkbox` with a non-interactive `aria-hidden` indicator span + `Check` icon (old-focal's CommandItem pattern) — no button-in-button; reset the search query on popover close; added a project multi-select test path. Re-reviewed → 04-build-verdict-2.md (9.4 APPROVED).

## Release Risk
Medium

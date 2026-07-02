# Review Verdict

Reviewer: Opus subagent (fresh context). GPT-Codex was probed live and available, but its xhigh
review run was stopped (kept overrunning under the session's parallel load); the user opted to finish
via the in-process Opus reviewer instead.
Step: build (+ holistic review — gate 5 folded in)
Score: 9.4 / 10
Status: APPROVED

## Reason
Correct, idiomatic TanStack Query v5 work. The products/projects split predicate
(`parentProjectId` truthiness) is right for the `string | null` schema; `customEnabled` gating and the
`settings.data && settings.data.syncMode === 'custom'` reveal guard both narrow cleanly (tsc proves
it); the single shared `customFilterMutation` wires every field through one PATCH and its failure
joins the shared `role="alert"`. House rules pass: full en/ru key parity, no hardcoded strings, no
`any`, no spec IDs / AI attribution; the bare `['spheres']`/`['projects']` query keys deliberately
reuse the sibling `CalendarsPage` convention. Scope is tight — every line traces to the sub-slice.

## Must Fix
None

## Should Consider
- A multiselect is gated on `*.length > 0`; if a value is persisted (e.g. `selectedSpheres: ['s1']`)
  but `listSpheres()` returns `[]` / is mid-flight, the control (and its saved badges) is hidden, so
  the user can't see/clear it. Not data loss. Consider rendering the control when there's either an
  option or an existing selection. (Carried as a follow-up.)
- One shared `customFilterMutation.isPending` disables all five custom controls during any one save —
  acceptable for this low-frequency panel; cheaply prevents overlapping patches racing the same row.
- `settings.data.projectType || 'all'` treats an empty string as "all" — equivalent to `?? 'all'`
  given the field is a non-empty enum server-side.

## Tests Reviewed
`git diff feat/focal-gsync-settings -- apps/focal/client`; read the full component, `integrations.ts`,
`projects.ts`, `spheres.ts`, `multi-select.tsx`, and the generated openapi schemas. Confirmed `tsc -b`
clean and 16/16 (pre-strengthening) in the file.

## Release Risk
Low

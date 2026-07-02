# Review Verdict

Reviewer: GPT Codex
Step: review
Score: 8.6 / 10
Status: BLOCKED

## Reason
The token bridge and shell/primitive restyle are mostly scoped and type/lint clean, but one shared primitive utility issue still compiles into invalid CSS and breaks visual behavior in the select/dropdown/popover layer. Because this is a foundation slice, invalid shared primitive styling blocks the visual parity contract.

## Must Fix
- `apps/focal/client/src/components/ui/select.tsx:69`, `apps/focal/client/src/components/ui/dropdown-menu.tsx:47`, `apps/focal/client/src/components/ui/dropdown-menu.tsx:64`, and `apps/focal/client/src/components/ui/popover.tsx:20` use `max-h-[--radix-select-content-available-height]` / `origin-[--radix-...]`; Tailwind emits invalid declarations such as `max-height: --radix-select-content-available-height` and `transform-origin: --radix-...`, so Radix select max-height and menu/popover animation origins render wrong. Use `var(--...)` arbitrary values consistently.

## Should Consider
None

## Tests Reviewed
`git -C superapp --no-pager diff`, `git -C superapp status`, task/plan/design review, `git diff --check`, `biome check .`, `tsc --noEmit`, generated CSS inspection. `vitest run` could not start in the read-only sandbox.

## Release Risk
Medium

---
_Doer (Opus) note: finding verified against the built CSS (`max-height:--radix-...` / `transform-origin:--radix-...` were emitted invalid) and fixed in the same files by wrapping the bare custom properties in `var()`. This is a pre-existing Tailwind-4 bare-custom-property pattern from the shadcn primitives, on lines already in this slice's diff. Post-fix CSS emits `max-height:var(--radix-...)` / `transform-origin:var(--radix-...)`; `pnpm build` + `pnpm lint` green._

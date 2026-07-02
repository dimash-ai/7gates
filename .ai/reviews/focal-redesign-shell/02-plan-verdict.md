# Review Verdict

Reviewer: Opus
Step: plan
Score: 9.2 / 10
Status: APPROVED

## Reason
The plan is the minimum viable change — a value-swap inside the existing Tailwind 4 `@theme inline` structure, not a restructure — and I verified its load-bearing claims against source: the token-name parity (`focal/index.css:10-80` vs `old-focal/index.css`), the radius scale (`--radius-sm/md/lg .1875/.375/.5625rem` matches `old-focal/tailwind.config.ts:9-11` exactly), the re-anchor premise (old-focal defines none of `--surface-*`/`--accent-subtle`/`--overlay`/`--success`/`--focal-*`, all of which shipped primitives consume), and the behavioral safety net (`AppShell.test.tsx`/`PageToolbar.test.tsx` genuinely cover sign-out, dashboard gating, meeting badge, calendar refresh, dark toggle, and language). Failure modes are named with concrete catch-points and user-visible symptoms, slices are small with a verify command each, and the "don't delete a referenced token / keep the build green" invariant is enforceable via per-slice `pnpm build` + the contract test + the explicit no-name-deleted rule. Remaining gaps are non-blocking sharpening, not defects that break the build.

## Must Fix
None.

## Should Consider
- **Pin the `--focal-*` re-anchor to the full referenced ramp, not just the `-500` anchors.** `components/ui/badge.tsx:19-25` consumes a wide set of raw shades via arbitrary values — `--focal-green-700/300`, `--focal-amber-100/800/400/300`, `--focal-coral-700/300`, plus `--focal-blue-500`/`--focal-green-500` in `AppSidebar.tsx:57,69`. Slice 3 says re-anchor "referenced `--focal-*` raw tokens" but the contract test only proves "known Allosta primary anchors are gone." If the doer re-anchors only the commented `-500` anchors, the other ramp shades keep their Allosta hex; if they prune "unused" ramp entries, badge variants break. The plan's no-name-deleted invariant + `pnpm build` bound the second risk, but the first (stale ramp values) would pass the build silently. Have the test assert the full referenced ramp still resolves to old-focal-compatible values.
- **Flag that old-focal's `.dark` primary differs from its light primary.** The think-doc (input) states "`--primary 217 91% 48%`," which is correct for `:root` (`old-focal/index.css:29`) but old-focal's `.dark` uses `--primary 217 91% 60%` (`index.css:120`), and dark `--sidebar-primary`/`--sidebar-ring` are also `60%`. The plan's slice 2 correctly says "replace `:root` and `.dark` with old-focal's exact values" generically and does not bake in a wrong value, but a note steering the doer away from copying one HSL into both blocks would prevent a `dark-class-regression` (a failure mode the plan already lists).
- **`badge.tsx`/`dialog.tsx`/`select.tsx` etc. are out-of-scope primitives whose *rendering* changes via the token swap.** The plan keeps them unedited (correct, per Surgical Changes) but the re-skin's visual correctness on these primitives rests entirely on manual QA, since `themeTokens.test.ts` is text-level over `index.css` only. The plan acknowledges this ("Manual light/dark screenshot comparison… unit tests cannot assert"); just ensure the slice-6 visual pass explicitly includes a badge/dialog/select sample, not only shell chrome.

## Tests Reviewed
N/A (plan step — no code executed). I inspected the existing tests the plan relies on: `AppShell.test.tsx` (sign-out, dashboard gating ×3, meeting badge ×3, calendar refresh — confirmed present and asserting behavior) and `PageToolbar.test.tsx` (ai-chat nav, dark toggle+persist, language switch — confirmed). Verified `src/themeTokens.test.ts` does not yet exist (correct — it is the planned addition) and that `lint`/`typecheck`/`test:run`/`build` scripts exist in `package.json`.

## Release Risk
Low — single-app frontend theming slice; no server, API, schema, route, or dependency change; reversible by restoring the `index.css` value blocks and shell TSX. The token blast radius (every page inherits `index.css`) is the only real risk, and it is bounded by the contract test, full lint/typecheck/test/build, and the named no-token-drop invariant.

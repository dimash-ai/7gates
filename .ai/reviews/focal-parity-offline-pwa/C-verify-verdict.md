# Review Verdict

Reviewer: Opus
Step: verify
Score: 9.5 / 10
Status: APPROVED

## Reason
The verify gate was genuinely adversarial — it surfaced six real defects across five passes that all six gate-B reviews missed (queue purge on switch, in-flight replay fence, replayOwnerId token-race, iOS install miss, durable SW cache, involuntary-sign-out purge), each fixed and unit-tested in-session. I independently re-ran the full suite on Node 22 LTS (110 files, 1254 tests green), plus typecheck, lint (328 files), and build — all pass — and independently traced the highest-risk surface (cross-user offline mutation replay): the four-layer defense (ownership stamp → purge-on-identity-loss → in-flight generation fence → per-entry token-owner guard) genuinely closes cross-user replay with no remaining live-identity-change hole, and every link is covered by a risky-path test.

## Must Fix
None

## Should Consider
- The only path a legacy `userId`-less row replays under a different signed-in user is a cold start where that user has their *own* stored session (`AuthProvider.tsx:176` → `requestQueueReplay`, `queue.ts:117` does not drop a null-`userId` entry). This is the design's documented upgrade carve-out (success criterion lines 82-83, preserve-over-drop), and no *live* A→B identity change reaches replay (`AuthProvider.tsx:200-203` purges + returns first), so it is not a leak — but the legacy-row carve-out has a finite shelf life. Consider dropping the null-`userId` replay path in a future slice once no pre-slice queues can plausibly remain on devices.
- The 11 `pnpm lint:i18n` hardcoded-string errors are confirmed pre-existing — all six flagged files (`help/HelpPage.tsx`, `heatmap/HeatmapPage.tsx`, `dashboard/overview.tsx`, `habits/HabitJournal.tsx`, `analytics/sections/{Mission,Energy}Section.tsx`) are byte-identical between `feature/focal-migration` and HEAD, and the offending strings exist verbatim on the base. Not introduced here and not gating; worth a separate cleanup slice.
- Build emits a pre-existing chunk-size warning (`index` chunk ~1.56 MB); this slice's only `vite.config.ts` change is the `stampServiceWorker` plugin, so the warning is not attributable to it. Non-blocking.

## Tests Reviewed
Re-ran `cd apps/focal/client && pnpm test:run` (Node v22.22.3) → 110 files / 1254 tests passed; `pnpm typecheck`, `pnpm lint` (328 files), `pnpm build` → all green. Inspected `offline/queue.test.ts`, `offline/setup.test.ts`, `api/client.test.ts`, `features/auth/AuthProvider.test.tsx`, `offline/readCache.test.ts`, `lib/sw.test.ts`. Proved the i18n errors pre-existing via `git diff feature/focal-migration...HEAD` on each flagged file; scanned the full added diff for secrets/PII (none).

## Release Risk
Low

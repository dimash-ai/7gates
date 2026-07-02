# Verify Report — focal-parity-offline-pwa

Doer: GPT Codex (verify step, workspace-write). Binding spec: `.ai/design/focal-parity-offline-pwa-design.md`
(no `.ai/tasks` file — design approved at Gate A). Diffed `feature/focal-migration...HEAD`.

## Process

The verify gate ran adversarially over **five passes**. The first four each STOPPED on a real
production defect (the verifier does not patch production code — it reports for an in-session gate-B
fix); the fifth completed the verification with the suite green. Six defects were surfaced that all
six per-slice gate-B reviews missed — every one fixed + tested in-session:

1. **Queue not purged on account switch** — `onAuthStateChange` cleared React Query + read-cache but
   not the mutation queue, then replayed; a legacy userId-less row could replay under the new account.
   Fixed: purge + skip replay on a confirmed switch.
2. **In-flight replay survived a switch** — an already-running `replayQueue` (snapshotted list,
   per-entry network awaits) kept POSTing the prior user's entries under the new token. Fixed: a
   `replayGeneration` fence (`clearOfflineQueue` bumps it; `replayQueue` aborts when it changes).
3. **Token-resolution sub-entry race** — `apiFetch` resolves the live token async; a switch in that
   window could still send one entry under the new token. Fixed: `replayOwnerId` aborts the send
   (synchronously, before fetch) if the live user no longer matches.
4. **iOS install instructions missing** — a real design success-criterion (lines 95/157); iOS Safari
   never fires `beforeinstallprompt`. Fixed: `isIos()` + a manual "Add to Home Screen" banner.
5. **SW shell cache not durable** — nav/asset `cache.put` not awaited (SW could die before the write)
   and no install precache. Fixed: `await cache.put` + an `install` handler that precaches `/`.
6. **Queue not purged on involuntary sign-out** — the switch purge required `next != null`, so an
   external `SIGNED_OUT` (`onAuthStateChange → null`) left the queue behind. Fixed: purge on any
   prior-real-user identity loss (switch OR sign-out).

## Cross-user replay path — layered defense (final state)

Ownership stamp (drops a different stamped user's entries) → purge-on-identity-loss (switch + sign-out,
explicit + involuntary) → in-flight generation fence (aborts a running replay on purge) → per-entry
token-owner guard (`replayOwnerId` aborts a send if the live user changed after the token resolved).

## Scrutinized

Auth-ready deferred replay; queue ownership/purge/fence; read-cache scoping (`(dataOwnerId,
calendarId)`), date-window coverage + undated-task carve-out, cold-only read-through; OfflineSync
warming; status hook + indicator; SW app-shell caching (never `/api`, dev-disabled, build-stamped,
durable writes, install precache); install/update prompts (incl. iOS); pull-to-refresh; i18n en+ru;
stack/tooling rules. **No remaining binding-design miss or correctness/security defect.**

## Tests added in the verify pass

- `lib/pwa.test.ts`: `isIos()` detection (iPhone UA, iPadOS desktop-mode Safari via MacIntel +
  maxTouchPoints, non-touch Mac → false) + navigator-property restoration in afterEach.
- `features/auth/AuthProvider.test.tsx`: tightened the stored-session replay test to drive the real
  `getSession` path.

## Result

`pnpm typecheck` ✓ · `pnpm lint` ✓ (328 files) · `pnpm test:run` ✓ (110 files, **1254 tests**) ·
`pnpm build` ✓.

(Note: the verifier's shell is on Node 25, whose broken global `localStorage` breaks happy-dom; its
first Vitest run failed 141 environmentally and it correctly re-ran with
`NODE_OPTIONS=--no-experimental-webstorage` → all 1254 green. Re-confirmed green on Node 22 LTS in the
maintainer session.)

**The change is verified and ready.**

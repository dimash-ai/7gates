# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.7 / 10
Status: BLOCKED

_Slice B2 (read-cache + OfflineSync), round 1._

## Reason
The slice implements the main B2 shape cleanly: scoped stores, offline-only read-through, cold-query protection, warming, and purge wiring are present with focused tests. One range-awareness edge case violates the explicit read-cache contract and can over-return cached date-windowed data instead of missing.

## Must Fix
- `apps/focal/client/src/offline/readCache.ts` `inWindow` returns the full warmed list whenever `startDate` or `endDate` is missing. For date-windowed `events`/`tasks`, the contract says cached data is served only when the request window is known and fully within warmed coverage; otherwise it must MISS, not return a year of warmed rows.

## Should Consider
- Harden the default IndexedDB path against `indexedDB.open`/operation failures, not just `typeof indexedDB === 'undefined'`, so storage failures fall through as silent no-ops rather than escaping from the read-through.
- Add an AuthProvider wiring test proving `clearReadCache()` is called on explicit sign-out and user-change; current tests cover the primitive clear but not the purge integration.

## Tests Reviewed
Inspected the build log (`pnpm typecheck`, `pnpm lint`, `pnpm test:run` 1193 passed, `pnpm build` green); reviewed added `readCache`, `api/client`, and `OfflineSync` tests.

## Release Risk
Medium

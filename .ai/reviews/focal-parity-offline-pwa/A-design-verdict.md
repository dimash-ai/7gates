# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 7.6 / 10
Status: BLOCKED

## Reason
The design frames the hand-rolled approach well and the build slices are mostly coherent, but the PWA caching contract conflicts with the stated unhappy-path and security requirements. As written, it can mask online API failures and persist authenticated API data outside the proposed user-scoped read cache.

## Must Fix
- `.ai/design/focal-parity-offline-pwa-design.md:104` specifies a service-worker `NetworkFirst` cache for `/api`, but the design requires online GET failures to surface rather than be served from cache. A SW `/api` cache would sit below `apiFetch`, so `apiFetch` may receive stale success responses instead of observing the failure.
- The IndexedDB read cache is claimed cleared on the existing `queryClient.clear()` sign-out path, but the design adds a separate persistent IDB cache and no slice wires sign-out/user-change cleanup for it. The design must specify an actual read-cache purge or a complete partitioning strategy for user/data-owner/calendar scope.

## Should Consider
- Make B1 explicit that `networkMode: "always"` applies wherever offline mutations must execute, not just query defaults; otherwise React Query can pause mutation functions before `apiFetch` reaches the offline queue.
- Tighten the read-cache contract for path/query scoping, especially date-windowed `events`/`tasks` and `calendarId`/`dataOwnerId`.

## Tests Reviewed
N/A

## Release Risk
High

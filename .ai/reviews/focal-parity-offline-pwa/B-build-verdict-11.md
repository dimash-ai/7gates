# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 9.2 / 10
Status: APPROVED

_Slice B6 (offlineAwareMutation helper), round 2._

## Reason
The round-1 cold-cache rollback defect is fixed: `onError` removes the exact query when the snapshot is undefined and restores the snapshot otherwise, with a dedicated cold-cache rejection test asserting the optimistic entry is gone. The slice remains scoped to the helper and tests only, and the intended cancel/snapshot/optimistic, rollback, offline-persist, and online/offline invalidation behaviors are covered.

## Must Fix
None

## Should Consider
- A later test for queued network failures where `fetch` fails but `navigator.onLine` remains true, since `apiFetch` can queue that case and the helper keys defer/invalidate only off `navigator.onLine`.

## Tests Reviewed
Inspected `git show --stat HEAD`, `git diff HEAD~1 HEAD`, and the B6/round-1 build-log notes reporting `pnpm typecheck`, `pnpm lint`, `pnpm test:run` = 1243, and `pnpm build` green.

## Release Risk
Low

---

_Disposition of the Should-Consider: accepted as-is and deferred to the `focal-parity-offline-adopt`
follow-up. Keying `onSettled` off `navigator.onLine` is consistent with the rest of the offline layer
(OfflineSync warming, syncNow gating, the read-through). In the `onLine=true` but server-unreachable
edge, the mutation still queues (via apiFetch), the optimistic patch persists, and the online
`invalidate` triggers a refetch that fails — but `networkMode:"always"` retains the optimistic data
and the post-replay invalidate reconciles on real reconnect, so there is no data loss. The reviewer
flagged it as a deferrable "later test"; it becomes naturally testable once the helper is wired to a
real feature in the adopt slice._

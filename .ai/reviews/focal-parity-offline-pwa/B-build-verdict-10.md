# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.4 / 10
Status: BLOCKED

_Slice B6 (offlineAwareMutation helper), round 1._

## Reason
The helper matches the intended online/offline lifecycle for seeded caches, and the diff is correctly limited to the helper plus tests. However, rollback is incorrect when the cache had no prior data: TanStack Query v5 ignores `setQueryData(queryKey, undefined)`, so a rejected mutation can leave a phantom optimistic entry instead of restoring the undefined snapshot.

## Must Fix
- `offline/offlineAwareMutation.ts` restores an undefined snapshot with `queryClient.setQueryData(queryKey, context.snapshot)`, but `setQueryData(..., undefined)` is a no-op in TanStack Query v5. Reproduced with a cold `QueryClient`: optimistic `[{id:"2"}]` remained after `setQueryData(['rows'], undefined)`. Track whether a snapshot existed and remove/reset the query on rollback, and add a cold-cache rejection test.

## Should Consider
None

## Tests Reviewed
Inspected `git show --stat HEAD`, `git diff HEAD~1 HEAD`, the B6 build log, the design doc, and `offlineAwareMutation.test.tsx`; ran a targeted Node reproduction for undefined-snapshot rollback.

## Release Risk
Medium

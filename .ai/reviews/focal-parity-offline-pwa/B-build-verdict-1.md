# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 7.4 / 10
Status: BLOCKED

## Reason
The B1 config and queue mechanics are mostly in place, but the auth-ready replay is not actually using an auth-ready user identity. That creates a concrete data-loss/cross-user replay risk in the slice's central safety contract.

## Must Fix
- `apps/focal/client/src/features/auth/AuthProvider.tsx:166-170` and `:180-185` call `requestQueueReplay()` immediately after `setSession(...)`, while `sessionRef.current` is only refreshed from state during render at `:68-69`. `apps/focal/client/src/offline/setup.ts:63` captures `getCurrentUserId()` synchronously, and `apps/focal/client/src/offline/queue.ts:112-114` drops stamped entries when that value is null or stale. On cold reload this can delete the current user's queued mutations as "different user"; on account switch it can process the previous user's queue.
- `apps/focal/client/src/offline/setup.ts:81-84` still replays on any `online` event before the auth layer has established a current user. A reconnect during startup can hit the same `currentUserId === null` ownership path and drop stamped queue entries despite the deferred-until-auth-ready design.

## Should Consider
- Add a direct regression for replay 401 + `suppressAuthError`: the current tests cover `replayQueue` keeping a 401, but do not assert that the setup/client integration avoids invoking the global auth-error handler.

## Tests Reviewed
Ran `git -C superapp-offline --no-pager diff` and `git -C superapp-offline status`; inspected `.ai/runs/focal-parity-offline-pwa-build.txt` reporting green `typecheck`, `lint`, `test:run` 1171 tests, and `build`; inspected `queryClient.test.ts`, `queue.test.ts`, `setup.test.ts`, and `client.test.ts`.

## Release Risk
High

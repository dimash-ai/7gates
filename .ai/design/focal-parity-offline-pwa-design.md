# Design: focal-parity-offline-pwa

Slice 11 of the focal-parity epic: bring the new Focal client to old-focal's **offline + PWA**
behavior. Frontend-only; no server/API/schema change.

## Problem & decision

The new Focal client already has a solid **offline-write** path — a hand-rolled IndexedDB mutation
queue (`offline/{storage,queue,setup}.ts`) plus an `apiFetch` hook that, on a network failure,
enqueues the mutation and returns the optimistic body. What it is **missing** vs old-focal is the
rest of the offline/PWA surface: an offline **read** path (cached GETs), proactive cache-warming, a
rich online/offline indicator, the install + update PWA prompts, and pull-to-refresh.

**Decision: port old-focal's behavior, re-expressed against the new app's primitives — hand-rolled,
NOT `vite-plugin-pwa`.** old-focal's offline layer is built on `vite-plugin-pwa` + Workbox + `idb` +
array query keys; the new app deliberately hand-rolls its service worker, IndexedDB, and queue, uses
a typed `apiFetch` with string paths, and per-feature query keys. So most old-focal code cannot be
copied — it is the *behavior* we port, on the new app's surface.

**Rejected: adopt `vite-plugin-pwa`/Workbox.** It would replace the hand-registered `/sw.js` (which
must keep its push/notificationclick handlers), pull in Workbox + `idb` + a `vite.config` rewrite,
and change how the SW is built — a large blast radius against a codebase that intentionally went
hand-rolled. The reuse-first ladder says extend what already exists (the `offline/` module + the
hand-registered SW) before adding heavy new surface. The one capability `vite-plugin-pwa` gives "for
free" — update detection — is ~30 lines hand-rolled (`updatefound`/`statechange` + a `SKIP_WAITING`
postMessage). So we hand-roll and add **no new runtime dependency**.

**The single load-bearing change: `QueryClient` → `networkMode: "always"`** (+ `refetchOnReconnect:
false`, `refetchOnWindowFocus: false`, no-retry-offline). Today the new app's QueryClient is the
default `networkMode: "online"`, under which queries *pause* offline and *auto-refetch on reconnect*
— which would refetch ahead of the queue draining and wipe optimistic offline edits. old-focal
engineered around exactly this (its `queryClient.ts` CRITICAL comments). Read-cache is unsafe without
this config, so it ships first.

## Assumptions & scope

- **(confirmed)** The mutation-queue triad + `apiFetch` offline hook are reused; this slice adds the
  read + PWA-chrome layers around them **AND fixes two replay-safety bugs in the existing path**:
  (a) `main.tsx` starts `setupOfflineQueue` — which replays persisted mutations immediately — BEFORE
  `AuthProvider` registers the token getter, so a reload can replay a stored mutation with no bearer
  token; (b) `queue.ts` drops ALL 4xx on replay, so that tokenless replay's 401 permanently drops the
  mutation. This slice **defers the initial replay until auth is ready** (AuthProvider triggers it
  once it has a session, not `main.tsx` at import) and **treats a replay 401 as keep-and-stop
  (transient), not drop** (genuine client-rejections 400/403/404/409/422 still drop).
- **(confirmed)** `public/sw.js` is **push-only** and explicitly defers caching to "the PWA slice";
  it must keep its `push`/`notificationclick` handlers when we add a `message` (SKIP_WAITING) handler
  and (production-only) a fetch/cache handler.
- **(confirmed)** Read-cache + warming target the pages' actual READ endpoints: **events, tasks,
  projects** (per-entity lists) and **`/api/mindmap/init`** — the Goals page's aggregate read
  (`api/mindmap.ts`, `features/goals/GoalsPage.tsx`) — cached as a per-scope blob. (Goals *writes* hit
  `/api/activities` AND `/api/mindmap-nodes` — both queue paths, NOT read surfaces, so neither is a
  read-cache store; `/api/mindmap-nodes` is added to the queue allowlist so node move/resize/update
  queue offline. The new-sphere **inline-create transaction** — POST `/api/spheres`, then create the
  project, DELETE the sphere on rollback — is a non-atomic multi-write, so `/api/spheres` is
  **deliberately kept OUT of the allowlist**: offline it fails cleanly (the sphere is never created →
  no orphan) rather than queueing a partial transaction; creating a project under an EXISTING sphere
  queues normally. A friendlier offline-disabled UX for the new-sphere option is the
  `focal-parity-offline-adopt` follow-up.)
- **(unverified — build must read the real keys)** The exact per-feature query keys and list paths to
  warm/cache/refetch — the build inspects `features/{tasks,events,calendar,calendars,projects}` for
  the actual keys rather than assuming old-focal's array keys.
- **Scope split for `offlineAwareMutation` (reconciling plan slice 11):** the **reusable
  `offlineAwareMutation` helper — optimistic cache update + rollback — ships in THIS slice, with unit
  tests** (slice B6 below). Only the **per-feature adoption** (wiring the helper into each `features/*`
  `useMutation` with that feature's query key + entity updater) is deferred to a named follow-up
  **`focal-parity-offline-adopt`**, because it edits `features/*` mutation hooks and would collide with
  the in-flight Calendar / Goals / Google-sync slices — the same foundation-then-consumption split as
  slice 1 (context) → slice 2 (per-page). **Out of scope:** `vite-plugin-pwa`, Workbox runtime-caching
  of images, and any backend change.
- **Open questions:** **None blocking.** One decision taken here: old-focal mounted `PullToRefresh`
  **disabled**; this slice **enables it on mobile** (a no-op feature isn't parity) — flagged for the
  verify gate to confirm.

## Success criteria

- [ ] `QueryClient` sets `networkMode: "always"` on **both queries and mutations**,
      `refetchOnReconnect: false`, `refetchOnWindowFocus: false`, and a retry that never retries
      while offline / on 401.
- [ ] The read-cache **and the persistent mutation queue** are purged on sign-out / user-change — no
      cross-user reads and **no cross-user mutation replay**: queued mutations carry their creator's
      `userId` and replay only for that user, so a different user signing in (even after a cold start)
      replays none of them; **legacy userId-less rows from before this slice are preserved (replayed
      for the current user), not dropped on upgrade**.
- [ ] A persisted offline mutation does not replay before auth is ready (no tokenless 401→drop); a
      replay 401 keeps the mutation (transient), while other 4xx drop it.
- [ ] The read-cache is partitioned by `(dataOwnerId, calendarId)` and **range-aware** for
      date-windowed reads — an offline read never over-returns rows from another calendar scope or
      outside the warmed window (a window beyond coverage misses, not false-empties).
- [ ] A GET that fails on the network while offline returns IndexedDB-cached data (events / tasks /
      projects + the Goals `/api/mindmap/init` aggregate) instead of throwing; a miss surfaces the normal error.
- [ ] While online, `OfflineSync` warms the read-cache for the four entities on an interval (current
      calendar-year scope), so going offline leaves recent data viewable.
- [ ] The sidebar offline indicator is a popover: online/offline state, pending-mutation count,
      last-sync time, a "sync now" action (online + pending only), and the offline-limitations note.
- [ ] An install prompt appears for installable browsers (`beforeinstallprompt`) and iOS (manual
      instructions), is dismissible, and re-appears only after 7 days; not shown when already installed.
- [ ] When a new service worker is waiting, an update prompt appears; "update" activates it
      (skipWaiting) and reloads; it polls hourly and on tab refocus.
- [ ] On mobile, pulling down at scroll-top past the threshold refetches the active queries.
- [ ] `offlineAwareMutation` applies an optimistic cache update and rolls it back on rejection (unit-proven).
- [ ] The read-through serves cached data only for a **cold** query (no existing cache for the key), so
      an offline-queued mutation's optimistic data is never overwritten by stale read-cache on
      invalidate-on-settle.
- [ ] `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green; all new user-facing strings
      in ru + en; SW push still works; the fetch/cache SW does not run in dev (no HMR breakage).

## Build approach (slices)

Each slice is committed on `feat/focal-parity-offline-pwa` and gate-B reviewed before the next.

| # | slice | files | main failure mode | what its test proves |
|---|-------|-------|-------------------|----------------------|
| B1 | **QueryClient config + queue replay safety** | `api/queryClient.ts`, `offline/setup.ts`, `offline/queue.ts`, `features/auth/AuthProvider.tsx`, `main.tsx` (+ tests) | wrong mode re-introduces reconnect-refetch data loss; startup replay fires tokenless → 401 → mutation dropped | `networkMode:"always"` on **queries AND mutations** + `refetchOnReconnect/Focus:false` + offline/401 no-retry; **initial replay deferred until auth-ready** (AuthProvider triggers it post-session, not `main.tsx` at import); **replay treats 401 as keep+stop, other 4xx as drop**, and replay requests **suppress the global 401→sign-out** (a `suppressAuthError` flag) so a transient replay 401 keeps the entry instead of signing out (which would purge the queue) |
| B2 | **Read-cache + OfflineSync** | `offline/readCache.ts` (per-user IndexedDB stores: save/load **scoped by userId** + `clearReadCache()`), `api/client.ts` (`setReadCacheHandler` + GET read-through on `network_error`/offline ONLY), `offline/OfflineSync.tsx` (warming provider) mounted in `App.tsx`, `features/auth/AuthProvider.tsx` (purge read-cache on sign-out + user-change, beside the existing `queryClient.clear()`) | stale/partial cache; cache served while ONLINE masks a real error; cross-user cache read | a failed GET offline returns the current user's cached rows; online failures still throw; warming writes the four stores; **sign-out / user-change purges the read-cache**; IndexedDB-absent → no-op |
| B3 | **Offline status + rich indicator** | `offline/useOfflineStatus.ts` (online + lastSync + pending + syncNow, extends `queue.ts`), `offline/OfflineIndicator.tsx` (popover rewrite), i18n | wrong status (e.g. shows "synced" with pending) | popover shows offline/pending/last-sync; "sync now" replays + only when online+pending; error state |
| B4 | **PWA install + update prompts** | `components/InstallPrompt.tsx`, `components/UpdatePrompt.tsx`, `public/sw.js` (add `message`→`skipWaiting`; production CacheFirst for **static app-shell assets ONLY — never `/api`**), `main.tsx` (update wiring), `index.html` (PWA meta), mount in `App.tsx`, i18n | breaking push; HMR break in dev; prompt loops | install shows on `beforeinstallprompt`, hidden when standalone, 7-day re-show; update shows on waiting SW → skipWaiting+reload; push listeners intact |
| B5 | **Pull-to-refresh** | `hooks/use-pull-to-refresh.ts`, `components/PullToRefresh.tsx`, wrap `<main>` in `AppShell.tsx`, i18n | gesture conflicts with drag/scroll | mobile pull at scroll-top→ `refetchQueries({type:"active"})`; desktop = passthrough; ignores drag targets |
| B6 | **offlineAwareMutation helper** | `offline/offlineAwareMutation.ts` (+ test) | optimistic item lingers after a rejected replay; bad rollback | applies an optimistic cache patch + snapshot, rolls back on immediate error, resolves optimistically when offline-queued, and is reconciled to server truth by the post-replay invalidate (a 4xx-dropped mutation's optimistic change disappears). **Helper only — per-feature adoption is the `focal-parity-offline-adopt` follow-up** |

## Architecture & contracts

Reuse-first: the existing `offline/{storage,queue,setup}.ts` + `apiFetch` hooks stay; we add a
parallel **read-cache** module and a **status** hook, and global chrome. `api/client.ts` stays
decoupled from IndexedDB via injected handlers (same pattern as `setOfflineQueueHandler`).

| entity / interface | change | notes |
|--------------------|--------|-------|
| `api/queryClient.ts` | modify | `networkMode:"always"` on **both `queries` and `mutations`** defaults, `refetchOnReconnect:false`, `refetchOnWindowFocus:false`, `gcTime:24h`, retry: 0 offline / ≤3 online / never on 401 |
| `offline/readCache.ts` | add | hand-rolled IndexedDB stores `events/tasks/projects` (per-entity lists) + a `mindmapInit` aggregate store (the Goals `/api/mindmap/init` response cached as ONE blob per scope, so the Goals page renders offline), **partitioned by a scope key `${dataOwnerId}:${calendarId ?? 'main'}`** (mirroring the query keys' `withCal` calendar scope); `saveEntities(store, scopeKey, rows)` / `loadEntities(store, scopeKey)` (returns ONLY that scope's rows) / `clearReadCache()`; `lastSync` per scope. The read-through builds `scopeKey` from the request's `calendarId` + current `dataOwnerId`, so a main / shared-calendar read **cannot over-return** rows from another calendar scope. **Date-windowed stores (events/tasks): `saveEntities(store, scopeKey, rows, coverageRange)` persists the rows + the warmed `[start,end]` per scope (in `lastSync`/scope metadata); the read-through filters cached rows to the query's `[start,end]` and serves ONLY if that window ⊆ coverage — else MISS, never a false-empty. For `tasks`, an undated task (`dueDate == null`) matches EVERY window — mirroring `/api/tasks`, which always returns `due_date IS NULL` alongside the date filter — so offline task lists don't drop undated tasks.** projects aren't windowed → full scope set; `mindmapInit` is one aggregate blob keyed by scope (read-through maps `/api/mindmap/init` → the blob). Same raw-IDB style as `storage.ts` (no `idb` dep) |
| `api/client.ts` | modify | add `setReadCacheHandler((path,query)=>Promise<unknown\|undefined>)`; in `apiFetch` GET catch-branch, consult the read-cache **only when genuinely offline (`!navigator.onLine`)** AND only for a **cold query** — the handler (which holds the `QueryClient`) returns undefined when that key already has data, so a refetch/invalidate over an optimistic offline edit **misses → throws → `networkMode:"always"` retains the current/optimistic data** instead of overwriting it with stale cache. An online `network_error` (timeout) still throws. Add a `suppressAuthError` option so queue **replay** requests don't trigger the global 401→sign-out |
| `offline/OfflineSync.tsx` | add | provider; while `online && session && dataOwnerId`, warm events/tasks/projects + the Goals `/api/mindmap/init` aggregate (current-year window for events/tasks) on mount + interval, writing the stores; reuses feature query fns, not `fetchWithAuth` |
| `offline/useOfflineStatus.ts` | add | `{ isOnline, pendingCount, lastSync, syncStatus, syncError, syncNow() }`; listens to `online`/`offline` + `subscribeQueueChanged`; `syncNow()` routes through the **single guarded replay runner** exposed by `setupOfflineQueue` (its `replaying` re-entrancy guard + post-replay `invalidateQueries`), NOT `replayQueue` directly — so manual sync can't race/double the auto-replay or skip invalidation |
| `offline/setup.ts` | modify | expose the guarded `replay()` runner (online-event + `syncNow` both call it); defer the initial replay until AuthProvider signals auth-ready |
| `offline/OfflineIndicator.tsx` | modify | replace count-only badge with the shadcn `Popover` (verify installed) of status/pending/last-sync/sync-now/limitations |
| `components/{InstallPrompt,UpdatePrompt,PullToRefresh}.tsx` | add | old-focal behavior, new-app surface; mounted in `App.tsx` (prompts) / around `AppShell` `<main>` (pull) |
| `public/sw.js` | modify | **add** `message`→`skipWaiting` + a production-gated cache for the **app-shell: the navigation shell (`index.html` / `/`, so the installed PWA launches offline) + static same-origin JS/CSS/fonts/icons — NO `/api` caching**, so the SW never masks an online API failure (offline API reads are the app-level read-cache); **keep** `push`/`notificationclick` |
| `features/auth/AuthProvider.tsx` | modify | on `signOut` (explicit) and on a user-change `onAuthStateChange`, call `clearReadCache()` beside the existing `queryClient.clear()`. The mutation queue's cross-user safety is the per-mutation `userId` ownership stamp (below) — **not** a timing heuristic — so even a cold `null→session` startup followed by a *different* user's sign-in never replays the prior user's queued mutations (replay filters by owner); on a confirmed user-change also purge other-user queue entries to free storage |
| `offline/{queue,storage}.ts` | modify | **`QueuedMutation` gains an optional `userId`** (creator, stamped by `enqueueMutation` from the current session). **`replayQueue` replays entries where `userId === current` OR `userId` is absent** (LEGACY rows persisted before this slice — they carried no ownership, so replaying them for the current user preserves already-queued offline edits with no data loss and no NEW cross-user risk); a *different stamped* user's entries are dropped — the durable cross-user-replay guard with a safe upgrade path (the IndexedDB field is additive — no version-bump migration drops rows). Add `clearQueuedMutations()` + storage `clear()`. **Extend `isQueueablePath` to include `/api/mindmap-nodes`** (Goals node move/resize/update writes) so Goals edits queue offline — the current allowlist (events/tasks/activities) omits it. **`/api/spheres` is deliberately NOT added**: the new-sphere create is a non-atomic multi-write (sphere+project) that would orphan a sphere if the project replay drops, so it fails cleanly offline instead of queueing a partial transaction |
| `offline/offlineAwareMutation.ts` | add | `offlineAwareMutation(qc, { mutationFn, queryKey, optimisticUpdate })`: `onMutate` snapshots the cache + applies `optimisticUpdate`; `onError` (non-queued) restores the snapshot; offline → `apiFetch` queues + returns the optimistic body; the existing post-replay `invalidateQueries` reconciles a 4xx-dropped change away. **Helper + tests only; per-feature adoption = `focal-parity-offline-adopt` follow-up** |
| `main.tsx` | modify | wire update-detection (`registration.waiting`/`updatefound`→`statechange`) → notify `UpdatePrompt`; capture `beforeinstallprompt` |
| `index.html`, i18n `{en,ru}.json` | modify | PWA `<meta>` (apple-mobile-web-app-*, mobile-web-app-capable); add `focal.offline.*` (incl. the already-referenced `pending`), `pwa.install.*`, `pwa.update.*`, `pullToRefresh.*` |

## Flow (happy + unhappy)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| happy — warm | online, provider mounted | `OfflineSync` | events/tasks/projects + the Goals `/api/mindmap/init` aggregate written to IndexedDB on interval |
| happy — offline read | offline GET for a warmed entity | `apiFetch` GET catch → read-cache handler | cached rows returned; UI renders last-known data |
| offline read miss | offline GET, nothing cached | `apiFetch` | normal `network_error` thrown; query shows its error/empty state |
| cache must not mask | **online** GET fails (5xx/timeout) | `apiFetch` | read-cache **not** used (only on offline / `network_error`); real error surfaces |
| optimistic edit kept | offline mutation settles → page invalidates → refetch | read-through sees the key already has (optimistic) data → **miss** | `networkMode:"always"` keeps the current/optimistic data; stale read-cache does not clobber it |
| offline write | offline mutation | `apiFetch` (existing) → queue | enqueued; optimistic body returned; pending count ++ |
| app reload w/ queued mutations | app start | replay **deferred** until `AuthProvider` has a session | no tokenless replay; mutations wait for auth, then replay |
| reconnect / post-auth replay | `online` event OR auth-ready | `setup.ts` guarded `replay()` (gated on auth-ready) | success→remove; **401 → keep+stop, replay suppresses the global sign-out**; other 4xx→drop; 5xx/network→keep+stop (order preserved); invalidate |
| manual sync | user taps "sync now" | same guarded `replay()` via `syncNow` | one run (re-entrancy guard), then invalidate — no double-replay / no re-enqueue race |
| SW update waiting | new SW deployed | `main.tsx` detection → `UpdatePrompt` | prompt; "update" postMessages SKIP_WAITING → SW activates → reload |
| install | `beforeinstallprompt` / iOS | `InstallPrompt` | banner; dismiss persists 7 days; hidden if standalone |
| pull-to-refresh | mobile pull at scrollTop≤0 past threshold | `use-pull-to-refresh` | `refetchQueries({type:"active"})`; toast on done/error; desktop passthrough |
| IndexedDB absent | private mode / quota | `readCache`/`storage` guards | read-cache + queue silently no-op; app works online-only |
| user switch / sign-out | auth change | `AuthProvider` (`signOut` + `onAuthStateChange` userChanged) | `clearReadCache()` + `clearQueuedMutations()` + `queryClient.clear()` → no cross-user cached data **and no cross-user mutation replay** persists in IndexedDB |

## Test strategy, security & rollback

- **Test strategy:** Vitest unit/integration (happy-dom). Pure/unit: queryClient config assertions;
  read-cache save/load (incl. the `/api/mindmap/init` aggregate for Goals) + IndexedDB-absent no-op; `apiFetch` GET read-through (offline→cached,
  online-failure→throws, miss→throws); `useOfflineStatus` (online/offline transitions, pending,
  lastSync, syncNow gating); SW `message`/skipWaiting + push-listener-intact (unit on the handler);
  InstallPrompt (beforeinstallprompt capture, standalone guard, 7-day dismissal), UpdatePrompt
  (waiting→prompt→skipWaiting, **+ hourly + tab-refocus update polling**), PullToRefresh (mobile gesture math + desktop passthrough + drag-target
  ignore). **Cross-user isolation: a test proves sign-out / user-change purges both the read-cache
  and the mutation queue** (no stale rows; no queued mutation survives an account switch; a different
  user's sign-in replays none of the prior user's queued mutations via the `userId` ownership stamp). **Replay
  safety: a test proves the queue does not replay before auth-ready (no tokenless 401-drop); a replay
  401 keeps the mutation WITHOUT signing the user out, while other 4xx drop it; and `syncNow` runs
  through the guarded runner (no double-replay / no skipped invalidate). A date-windowed read returns
  only in-window rows (**plus undated `dueDate==null` tasks for task windows**) and misses (not
  false-empties) outside the warmed coverage.** **Scope:
  a calendar-scoped offline read returns only in-scope rows** — the read-through narrows the cached
  superset by the query's `calendarId` so it cannot over-return across shared-calendar scopes.
  "Verified" = the four `pnpm` checks green + push still fires.
- **Security:** read-cache holds the user's own already-authorized data in IndexedDB (local only, no
  new network/endpoint, no secrets) — same trust boundary as the existing queue. The read-cache is
  **partitioned by the `(dataOwnerId, calendarId)` scope key** (`loadEntities(store, scopeKey)` returns
  only that scope's rows) **and purged on sign-out + user-change** via `clearReadCache()` beside the
  existing `queryClient.clear()` (the IndexedDB store is separate persistent storage, so
  `queryClient.clear()` alone does NOT clear it). **Mutation-queue cross-user safety is the durable
  `userId` ownership stamp**: each queued mutation records its creator and `replayQueue` replays ONLY
  current-user-owned entries — so a queue surviving a cold `null→session` reload can never replay
  under a different signed-in user. The sign-out / user-change **purge of the queue is cleanup +
  defense-in-depth**, not the sole guard. No authz/injection/SSRF surface added. **The SW caches only
  static same-origin app-shell assets — never `/api` responses** — so it cannot serve stale authed
  data or mask an online API failure (offline API reads are the app-level read-cache only).
- **Rollback:** revert the slice commits. The fetch/cache SW is production-gated and versioned; a bad
  cache is cleared by shipping a bumped SW cache name (skipWaiting path) — no persistent/server state
  to migrate.

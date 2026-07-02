# Stage
3-gate · Gate C (verify) — final gate. Slice 11 (Offline / PWA) of the focal-parity epic. APPROVED, ready to ship.

# What changed
A complete offline-first + installable-PWA layer for the new Focal app, built as 6 gate-B slices then hardened by the verify gate:
- **B1** — react-query offline config (`networkMode:"always"`, no reconnect/focus refetch, offline/401 no-retry) + queue-replay safety (deferred-until-auth-ready replay, 401-keep-not-drop, `suppressAuthError`, per-mutation `userId` ownership stamp).
- **B2** — a hand-rolled IndexedDB **read-cache** (events/tasks/projects + the Goals aggregate), partitioned by `(dataOwnerId, calendarId)`, date-window-aware with an undated-task carve-out, served **cold-only** while offline so it never clobbers optimistic data; an `OfflineSync` provider warms it.
- **B3** — an offline-status hook + a rich indicator popover (online/offline/syncing/error/pending, relative last-sync, manual "sync now", offline limitations).
- **B4** — PWA **install** + **update** prompts and a service worker that caches only the app-shell (never `/api`, disabled on localhost), build-stamped so updates are detected.
- **B5** — pull-to-refresh on touch devices.
- **B6** — an `offlineAwareMutation` helper (optimistic patch + rollback + replay reconciliation; helper-only, per-feature adoption deferred to a `focal-parity-offline-adopt` follow-up).
- **Verify-gate fixes** — six cross-user/PWA defects the per-slice reviews missed (queue purge on account switch + involuntary sign-out; in-flight replay generation fence; per-entry token-owner guard; iOS install instructions; durable SW cache writes + install precache).

# Files touched
41 files, +3237 / −127 (all under `apps/focal/client/`):
- offline: `offline/{readCache,OfflineSync,useOfflineStatus,offlineAwareMutation}.ts(x)` (new) + `offline/{queue,setup,storage,OfflineIndicator}.ts(x)` (modified) + tests
- api: `api/{queryClient,client}.ts` (+ `queryClient.test.ts`)
- auth: `features/auth/AuthProvider.tsx` (+ `AuthProvider.test.tsx`)
- PWA: `lib/pwa.ts`, `public/sw.js`, `components/{InstallPrompt,UpdatePrompt}.tsx`, `main.tsx`, `index.html`, `vite.config.ts` (SW build-stamp plugin) + tests
- pull-to-refresh: `hooks/use-pull-to-refresh.ts`, `components/PullToRefresh.tsx`, `components/AppShell.tsx` + tests
- i18n: `i18n/locales/{en,ru}.json` (`focal.offline.*`, `focal.pwa.*`, `focal.pullToRefresh.*`)

# Tests run
```sh
cd apps/focal/client
pnpm typecheck   # tsc -b: 0 errors
pnpm lint        # biome: 328 files, 0 errors
pnpm test:run    # 110 files, 1254 tests passed
pnpm build       # production build OK (dist/sw.js build-stamped)
```

# Verification output
```sh
Test Files  110 passed (110)
     Tests  1254 passed (1254)
```
Gate-C verify (GPT doer, 5 passes) surfaced 6 real defects — all fixed + tested in-session. Opus release-gate review independently re-ran the suite (Node 22 LTS) and traced the cross-user replay path: **APPROVED 9.5 / 10, Release Risk Low.**

# Still needs review
- The legacy `userId`-less queue-row replay is the design's documented upgrade carve-out (preserve-over-drop). No live A→B identity change reaches replay (it purges + returns first), so it is not a leak — but consider dropping the null-`userId` replay path in a future slice once no pre-slice queues can remain on devices.
- `pnpm lint:i18n` reports 11 hardcoded-string errors — **proven pre-existing** (the 6 flagged files are byte-identical on `feature/focal-migration`; strings exist verbatim on base). Not introduced here; worth a separate cleanup slice.
- Pre-existing chunk-size build warning (`index` ~1.56 MB) — not attributable to this slice.

# PR / release notes (for users — stage 5)
Focal now works offline and installs like an app.
- **Keep working without a connection.** The calendar, tasks, projects, and goals you've recently opened stay readable when you go offline. A status indicator in the sidebar shows whether you're online and how many changes are waiting to sync.
- **Offline edits sync automatically.** Tasks, events, projects, and goal-map changes you make offline are queued and applied — in order — as soon as you're back online. They show immediately while you work and reconcile with the server on reconnect. (Your queued changes are tied to your account and are cleared when you sign out or switch accounts, so they never apply to the wrong account.)
- **Install Focal to your home screen.** A prompt offers to install Focal as a standalone app (with step-by-step instructions on iPhone/iPad), and you're notified when a new version is ready — one tap updates.
- **Pull to refresh.** On phones and tablets, pull down at the top of a page to refresh what's on screen.

# Status
VERIFY APPROVED (Opus 9.5) — gate-B slices B1–B6 all APPROVED (≥9.1) by cross-model review.

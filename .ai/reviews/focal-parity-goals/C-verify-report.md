**Verification Report**

Verified slice 8 diff under `apps/focal/client` only. I added one focused test: [GoalsPage.rename.test.tsx](/Users/allosta/Desktop/allosta/superapp-slice8/apps/focal/client/src/features/goals/GoalsPage.rename.test.tsx:107) proves inline project rename restores the server label after an optimistic update when the rename mutation rejects.

Production defect found/fixed: none found. No production files changed.

Exact `pnpm` commands were blocked by sandbox before script execution: `pnpm` tries to open temp files under `/Users/allosta/Desktop/allosta/superapp-slice8/_tmp_*`, outside the writable client root. Equivalent package-local binaries were green:

```text
./node_modules/.bin/tsc -b --pretty
(no output; exit 0)
```

```text
./node_modules/.bin/biome check .
Checked 284 files in 52ms. No fixes applied.
```

```text
NODE_OPTIONS=--localstorage-file=/tmp/goals-verify-ls ./node_modules/.bin/vitest run

 RUN  v4.1.8 /Users/allosta/Desktop/allosta/superapp-slice8/apps/focal/client

 Test Files  83 passed (83)
      Tests  957 passed (957)
   Start at  04:51:46
   Duration  7.93s (transform 4.85s, setup 12.49s, import 15.14s, tests 42.16s, environment 22.91s)
```

```text
./node_modules/.bin/vite build
vite v8.0.16 building client environment for production...
...
✓ built in 262ms
```

Exact `pnpm` failure shape, e.g. `pnpm typecheck`:

```text
[ERROR] EPERM: operation not permitted, open '/Users/allosta/Desktop/allosta/superapp-slice8/_tmp_82997_c1f8681136368ead704d150b8d13501e'
For help, run: pnpm help run
```

I18n parity: `translation.focal.goals.*` has 120 EN keys, missing RU keys: 0, extra RU keys: 0. I also checked the production diff for new hardcoded user-facing strings; none found.

Residual risk: no browser visual pass was run; this was code/test/build verification. The only unresolved gate issue is the sandbox-level `pnpm` wrapper failure, not client code failure.

**Verification Report**

Verified the focal Analytics frontend slice diff, old-focal threshold parity, export failure behavior, i18n key parity, and the full client through local project binaries. Literal `pnpm` commands are blocked by this sandbox before scripts start:

```text
$ pnpm typecheck
[ERROR] EPERM: operation not permitted, open '/Users/allosta/Desktop/allosta/superapp-slice9/_tmp_71706_db08182a4cc70c9ec9ca53b4ef55dc8c'
For help, run: pnpm help run
```

Tests added:
- [AnalyticsPage.test.tsx](/Users/allosta/Desktop/allosta/superapp-slice9/apps/focal/client/src/features/analytics/AnalyticsPage.test.tsx): uses mocked `html2canvas`/`jspdf`; proves export calls the real helper, disables while capture is pending, temporarily expands collapsed content, restores the collapsed snapshot on rejection, re-enables, and does not download after failure.
- [analyticsExport.test.ts](/Users/allosta/Desktop/allosta/superapp-slice9/apps/focal/client/src/features/analytics/analyticsExport.test.ts): proves capture-time width/overflow/text truncation relaxations are restored when a section capture rejects.
- [analyticsInsights.test.ts](/Users/allosta/Desktop/allosta/superapp-slice9/apps/focal/client/src/features/analytics/analyticsInsights.test.ts): adds mission underperformance, mission 90% boundary, spheres total deficit and 75% boundary, plus project/product lagging/ahead/underplanned and 80%/110% exclusive thresholds.
- [SpheresSection.test.tsx](/Users/allosta/Desktop/allosta/superapp-slice9/apps/focal/client/src/features/analytics/sections/SpheresSection.test.tsx): adds footer coloring boundary for exactly 75% completion.

Production defect found/fixed: none found. I made no production changes.

Green-bar outputs from equivalent local binaries:

```text
$ ./node_modules/.bin/tsc -b --pretty
(no output; exit 0)
```

```text
$ ./node_modules/.bin/biome check .
Checked 287 files in 49ms. No fixes applied.
```

```text
$ NODE_OPTIONS=--localstorage-file=/tmp/analytics-verify-ls ./node_modules/.bin/vitest run

 RUN  v4.1.8 /Users/allosta/Desktop/allosta/superapp-slice9/apps/focal/client

 Test Files  83 passed (83)
      Tests  956 passed (956)
   Start at  03:58:02
   Duration  7.97s (transform 4.96s, setup 12.46s, import 15.57s, tests 39.98s, environment 22.52s)
```

```text
$ ./node_modules/.bin/tsc -b && ./node_modules/.bin/vite build
vite v8.0.16 building client environment for production...

 WARN  advancedChunks option is deprecated, please use codeSplitting instead.

transforming...✓ 3165 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                               1.30 kB │ gzip:   0.50 kB
dist/assets/goals-DtxX27Jz.css               15.41 kB │ gzip:   2.56 kB
dist/assets/index-C_9Ni0We.css              121.54 kB │ gzip:  20.21 kB
dist/assets/typeof-B5XbjTb1.js                0.27 kB │ gzip:   0.16 kB
dist/assets/rolldown-runtime-QTnfLwEv.js      0.69 kB │ gzip:   0.42 kB
dist/assets/purify.es-C77DcmJ7.js            26.09 kB │ gzip:  10.18 kB
dist/assets/query-2RO1sNwO.js                35.38 kB │ gzip:  10.40 kB
dist/assets/dashboard-BppZd1Ea.js            37.30 kB │ gzip:   8.98 kB
dist/assets/i18n-D8poZ-Ws.js                 47.98 kB │ gzip:  15.67 kB
dist/assets/index.es-h6CeA3AJ.js            151.42 kB │ gzip:  48.90 kB
dist/assets/react-vendor-dxsECwXy.js        189.64 kB │ gzip:  59.65 kB
dist/assets/html2canvas-B9Ed0YNC.js         199.57 kB │ gzip:  46.79 kB
dist/assets/supabase-BuWAP_bE.js            201.34 kB │ gzip:  51.65 kB
dist/assets/goals-Bn8yG3jW.js               202.28 kB │ gzip:  62.47 kB
dist/assets/jspdf.es.min-BJ9sbVj-.js        399.55 kB │ gzip: 129.65 kB
dist/assets/index-CTSR7CO1.js             1,506.62 kB │ gzip: 399.95 kB

✓ built in 269ms
[plugin builtin:vite-reporter]
(!) Some chunks are larger than 500 kB after minification. Consider:
- Using dynamic import() to code-split the application
- Use build.rolldownOptions.output.codeSplitting to improve chunking: https://rolldown.rs/reference/OutputOptions.codeSplitting
- Adjust chunk size limit for this warning via build.chunkSizeWarningLimit.
```

i18n parity check:
- EN/RU key comparison: `missingInRu=0`; Russian has 18 extra plural-category keys.
- `i18next-cli lint` remains red with 11 hardcoded-string findings. The analytics `% (` findings in `MissionSection.tsx` and `EnergySection.tsx` already exist on `feature/focal-migration`; none came from my test hardening.

Residual risk: PDF rendering itself is covered with mocked `html2canvas`/`jspdf`, not a visual browser/PDF inspection. Literal `pnpm` gates could not be invoked in this sandbox because pnpm tries to write a temp file at the monorepo root, outside the writable roots.

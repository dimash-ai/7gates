# Verify report — focal-parity-calendar-buttons (GPT Codex doer)

> **Curation note (Opus, in-session).** GPT's verify also modified three out-of-scope test fixtures
> (`src/test/setup.ts`, `components/PageToolbar.test.tsx`, `features/heatmap/HeatmapPage.test.tsx`) to
> stub `localStorage` — a workaround for codex's sandbox, where the exact `pnpm typecheck && lint &&
> test:run && build` chain failed with `[ERROR] fetch failed` and GPT fell back to running the tools
> directly. Those changes are a **no-op in the normal env** (the `setup.ts` stub only triggers when
> `localStorage` is missing) and are scope creep, so they were **reverted**. GPT's 4 calendar test
> additions were **kept** and re-verified green in the normal env: `pnpm typecheck` PASS, `pnpm lint`
> PASS, `pnpm test:run` **1072 tests PASS** (1068 + 4), `pnpm build` PASS.

---

Verification report for `focal-parity-calendar-buttons`:

I scrutinized the production change against `.ai/design/focal-parity-calendar-buttons-design.md` and found no production-code defect requiring a gate-B fix.

Key paths checked:
- Task permission gate is `canEdit && canViewOtherPages`, not just calendar edit: `CalendarPage.tsx:176`, `:479`, `:614`.
- Event create remains calendar-write gated on `canEdit`: `CalendarPage.tsx:270`, `:470`.
- Discriminated editor branching keeps grid slot create/edit on `EventPopover` and rail event create on full `EventDialog`: `CalendarPage.tsx:261`, `:561`, `:584`.
- Blank-title guard prevents create API calls for both dialog and popover: `CalendarPage.tsx:297`.
- Full dialog optional event fields persist through shared `createPayload`: `eventsFilters.ts:381`.
- Create failures are not swallowed; event errors route into dialog/page error state: `CalendarPage.tsx:208`, `:594`.

Tests added/strengthened (kept):
- Task rail create rejection stays open and surfaces error: `CalendarPage.test.tsx`.
- Full event create forwards active shared calendar id.
- Full event create rejection stays open and shows save error.
- Grid popover blank-title guard makes no API call and does not open the full dialog.

Verification (normal env, after curation):
- `tsc -b`: pass.
- `biome check .`: pass, 298 files.
- `vitest run`: pass, 92 files / 1072 tests.
- `vite build`: pass; only the existing chunk-size warning.

Final status: only the in-scope `CalendarPage.test.tsx` strengthening remains; no production code patched, no `.ai/` writes by codex.

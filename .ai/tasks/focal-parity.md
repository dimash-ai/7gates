# Goal

Bring the new Focal client (`superapp/apps/focal/client`) to **100% user-facing functional
parity** with the production reference `superapp/apps/old-focal/client`. The completed re-skin
epic (`focal-redesign-pages`) matched the *look* but was scoped "presentation only — behavior
preserved"; a full old-vs-new audit (this session) found large **functional** gaps still open.
This epic frames and closes them, slice by slice, through the 7-gate pipeline.

# Scope

- Every functional parity gap surfaced by the audit, across all left-nav areas, organised as an
  ordered, dependency-aware set of 7-gate slices — **foundations-first**: the systemic gaps that
  per-area pages *depend on* lead; the *independent* systemic gaps are ordered by dependency, not
  priority; then per-area work.
- Cross-cutting gaps that repeat across pages: shared-calendar read-only (`canEdit` /
  `CalendarFilterContext`), display-timezone selection + DST conversion, the global AI assistant
  widget + voice, and offline/PWA (read-cache, install/update prompts, optimistic mutations).
- Per-area functional gaps: Tasks editor/filters, Events editor, Calendar (drag/resize, all-day,
  year view, prime-time, task panel, undo, bookings), Goals (reparent, edges, finance, undo),
  Habits (edit, notes, presets), Analytics (export, insights, summaries), Google two-way-sync,
  and small misc gaps.
- Backend additions a parity item strictly requires (e.g. task recurrence, event custom
  recurrence) — as explicitly flagged model + Alembic migration handoffs inside the owning slice,
  done by the developer, never faked client-side.

# Out of scope

- Auth / registration / password-reset / marketing-landing — assumed delivered by the shared
  `@allosta/auth` package per `superapp/CLAUDE.md` (confirm; if wanted inside focal it is its own
  epic, not a focal-client slice).
- Visual / token redesign — owned by `focal-redesign-pages`; this epic does not re-litigate look.
- Net-new features old-focal does not itself ship (no scope creep beyond parity); the new app's
  already-shipped extras (e.g. `/spheres`, `/projects` pages, Reserve % row) are kept, not removed.

# Acceptance criteria

- [ ] The think doc enumerates every audit area as an ordered set of 7-gate slices,
      **dependency-ordered (foundational systemic gaps first)**, each tracing back to it; the slice
      slugs + boundaries are a proposal settled per slice.
- [ ] Each slice, at its own ship gate: `cd superapp/apps/focal/client && pnpm lint &&
      pnpm typecheck && pnpm test:run && pnpm build` green with its own tests; surgical diff; ru+en;
      light + dark; the area's behavior matches `apps/old-focal`.
- [ ] Each backend-touching parity item is called out as a separate model + migration handoff,
      never faked in the client.
- [ ] The 4 systemic gaps are each addressed once (shared), not re-implemented per page.

# Verification commands

```sh
cd superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```

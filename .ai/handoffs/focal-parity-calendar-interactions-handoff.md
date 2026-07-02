# Stage

3-Gate flow — Gate C (verify), release gate. Feature `focal-parity-calendar-interactions` (parity slice 6).

# What changed

Direct-manipulation on the calendar time grid (day / 3-day / week), restoring old-focal parity:

- **B1 — drag-to-move:** press an event block and drag it to a new time and/or day. The block follows
  the pointer (it can cross day columns), snaps to 15-minute steps on drop, preserves its duration, and
  persists optimistically. Open-ended events stay open-ended.
- **B2 — edge-resize:** drag an event's top or bottom edge to change its start or end, snapped to 15
  minutes with a 15-minute minimum. The bottom edge gives an open-ended event a concrete end; the top
  edge moves only the start.

Both gestures are gated by `canEdit` (read-only shared calendars show no affordances and can't move or
resize), route recurring events through the existing scope dialog (this / following / all), roll the
block back on a failed save, and never emit an out-of-range time (the end-of-day boundary persists as
the backend-valid `23:59`). A plain click still opens the editor; a completed drag/resize does not.

# Files touched

- `apps/focal/client/src/features/calendar/dates.ts` — pure geometry helpers (snap/clamp/offset→minute, backend-valid `formatMinutes`).
- `apps/focal/client/src/features/calendar/EventBlock.tsx` — pointer drag-to-move (ghost) + top/bottom resize handles.
- `apps/focal/client/src/features/calendar/TimeGrid.tsx` — `resolveDrop` column geometry; threads `onMove`/`onResize`.
- `apps/focal/client/src/features/calendar/CalendarPage.tsx` — optimistic move/resize mutation + rollback; recurring scope routing.
- `apps/focal/client/src/features/calendar/{dates,EventBlock,TimeGrid,CalendarPage}.test.tsx` — unit + integration coverage.

# Tests run

```sh
cd superapp-parity/apps/focal/client
pnpm typecheck   # tsc -b: 0 errors
pnpm lint        # biome: 300 files, clean
pnpm test:run    # 93 files, 1120 tests passed
pnpm build       # production build OK
```

# Verification output

```sh
Test Files  93 passed (93)
     Tests  1120 passed (1120)
✓ built in ~0.3s
```

Gate A (design) APPROVED 9.2 · Gate B (build) B1 APPROVED 9.1, B2 APPROVED 9.0 · Gate C (verify) APPROVED 9.4.

# Still needs review

- Optional hardening (non-blocking, flagged by the release reviewer): reset `justDraggedRef` at the next
  `onPointerDown` so a completed drag whose trailing click never arrives can't swallow the next click. The
  current behavior is correct in all pointer-capable browsers and is covered by tests; this only removes a
  theoretical edge. Deferred as a follow-up.

# PR / release notes (for users — stage 5)

You can now reschedule calendar events by direct manipulation, just like the old app:

- **Drag an event** to move it to a new time — or a different day — in the day, 3-day, and week views. It
  snaps to 15-minute steps and keeps its length.
- **Drag the top or bottom edge** of an event to change when it starts or ends, snapped to 15 minutes.
- Changes save instantly and roll back with a message if the save fails. Editing a repeating event asks
  whether to apply the change to this event, this and following, or all.
- Read-only shared calendars stay view-only — no move or resize.

No secrets, tokens, keys, or PII in this text or the diff.

# Status

OPUS APPROVED (9.4) — release gate cleared. MERGED — PR #106 into `feature/focal-migration`
(merge commit `4d3a1d0`, 2026-06-28); remote slice branch deleted.

**Verification Report**

Scope checked: `git diff feature/focal-migration...HEAD` and `git status` were reviewed first. Initial worktree was clean; final diff touches only [HabitJournal.test.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.test.tsx:154), +44 test-only lines.

No production defect found. No production code or `.ai/` files changed.

What I scrutinized:

- Note/status write races: [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:253) gates writes with `entriesReady = isSuccess && !isFetching`; [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:260) serializes entry writes with `isEntryWriting`.
- Upsert data integrity: status and note are sent together for cell cycling and panel writes at [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:145), [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:188), and [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:272).
- Delete rejection behavior: confirm prevents Radix auto-close and closes only on success at [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:305) and [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:682).
- `canEdit` gating: mutations/buttons are early-returned or disabled across journal actions and dialog submit, including [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:214), [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:270), and [HabitCreateDialog.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitCreateDialog.tsx:182).
- Calendar scoping: habit create/update and journal entry/delete writes thread `calendarId` at [HabitCreateDialog.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitCreateDialog.tsx:149), [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:145), [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:166), and [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:196).
- Future-date guard: selected future dates block panel writes and future cells are disabled at [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:266) and [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:454).
- ru/en i18n parity: new habit keys are mirrored in [en.json](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/i18n/locales/en.json:881) and [ru.json](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/i18n/locales/ru.json:893). Script result: `missingRu=[]`; Russian has expected extra plural keys.
- Note injection safety: notes are controlled textarea values, not HTML sinks, at [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:579).

Tests strengthened:

- [HabitJournal.test.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.test.tsx:154): HTML-shaped note remains textarea data, creates no `img`, and is sent verbatim with status.
- [HabitJournal.test.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.test.tsx:322): shared-calendar journal writes pass `cal-shared` through `upsertEntry`, `deleteEntry`, and `deleteHabit`.
- Existing proof retained for future guard at [HabitJournal.test.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.test.tsx:348), post-write refetch lock at [HabitJournal.test.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.test.tsx:371), and delete rejection staying open at [HabitJournal.test.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.test.tsx:406).

Verification results:

- Focused journal suite: `17 passed / 17`.
- Local equivalent typecheck: passed.
- Local equivalent lint: passed, `281 files`.
- Full Vitest with `NODE_OPTIONS=--localstorage-file=/tmp/focal-s7-ls`: `80 files passed`, `947 tests passed`.
- Local equivalent build: passed; Vite emitted only chunk-size/deprecated-option warnings.
- Required exact command `cd superapp-slice7/apps/focal/client && pnpm typecheck && pnpm lint && pnpm test:run && pnpm build`: failed before running `typecheck` with `[ERROR] fetch failed` from the pnpm wrapper.
diff --git a/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.test.tsx b/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.test.tsx
index aa181f06b7b198e5d0bfbd1789ee374d18669fab..ff1e658f1138af06ac511df249e8011d113e3a2f
--- a/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.test.tsx
+++ b/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.test.tsx
@@ -151,6 +151,24 @@
     )
   })
 
+  it('treats note free text as textarea data and sends it verbatim', async () => {
+    const note = '<img src=x onerror=alert(1)> plain text'
+    mocked.listEntries.mockResolvedValue([entry({ status: 'no', note: null })])
+    const { container } = renderJournal()
+    await expandRow()
+
+    const noteField = screen.getByLabelText<HTMLTextAreaElement>(t('focal.habits.journal.note'))
+    await userEvent.type(noteField, note)
+    expect(noteField.value).toBe(note)
+    expect(container.querySelector('img')).toBeNull()
+
+    await userEvent.click(screen.getByRole('button', { name: t('focal.habits.journal.saveNote') }))
+    expect(mocked.upsertEntry).toHaveBeenCalledWith(
+      { habitId: 'h1', date: todayIso, status: 'no', note },
+      null,
+    )
+  })
+
   it('records a skip when a note is saved on a day with no prior status', async () => {
     mocked.listEntries.mockResolvedValue([])
     renderJournal()
@@ -301,6 +319,32 @@
     expect(mocked.deleteEntry).not.toHaveBeenCalled()
   })
 
+  it('threads the shared calendar id through direct journal writes', async () => {
+    mockHooks.calendar = { currentCalendarId: 'cal-shared', canEdit: true, canViewOtherPages: true }
+    mocked.listEntries.mockResolvedValue([entry({ status: 'yes', note: 'shared note' })])
+    renderJournal()
+    await expandRow()
+
+    await userEvent.click(screen.getByRole('button', { name: t('focal.habits.entryStatus.no') }))
+    await waitFor(() =>
+      expect(mocked.upsertEntry).toHaveBeenCalledWith(
+        { habitId: 'h1', date: todayIso, status: 'no', note: 'shared note' },
+        'cal-shared',
+      ),
+    )
+
+    await userEvent.click(screen.getByRole('button', { name: t('focal.habits.entryStatus.erase') }))
+    await waitFor(() =>
+      expect(mocked.deleteEntry).toHaveBeenCalledWith('h1', todayIso, 'cal-shared'),
+    )
+
+    await userEvent.click(screen.getByRole('button', { name: t('focal.habits.actions.delete') }))
+    await userEvent.click(
+      await screen.findByRole('button', { name: t('focal.habits.delete.confirm') }),
+    )
+    await waitFor(() => expect(mocked.deleteHabit).toHaveBeenCalledWith('h1', 'cal-shared'))
+  })
+
   it('disables the panel controls and writes nothing on a future date', async () => {
     mocked.listEntries.mockResolvedValue([])
     renderJournal()

tokens used
108 216
**Verification Report**

Scope checked: `git diff feature/focal-migration...HEAD` and `git status` were reviewed first. Initial worktree was clean; final diff touches only [HabitJournal.test.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.test.tsx:154), +44 test-only lines.

No production defect found. No production code or `.ai/` files changed.

What I scrutinized:

- Note/status write races: [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:253) gates writes with `entriesReady = isSuccess && !isFetching`; [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:260) serializes entry writes with `isEntryWriting`.
- Upsert data integrity: status and note are sent together for cell cycling and panel writes at [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:145), [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:188), and [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:272).
- Delete rejection behavior: confirm prevents Radix auto-close and closes only on success at [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:305) and [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:682).
- `canEdit` gating: mutations/buttons are early-returned or disabled across journal actions and dialog submit, including [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:214), [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:270), and [HabitCreateDialog.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitCreateDialog.tsx:182).
- Calendar scoping: habit create/update and journal entry/delete writes thread `calendarId` at [HabitCreateDialog.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitCreateDialog.tsx:149), [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:145), [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:166), and [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:196).
- Future-date guard: selected future dates block panel writes and future cells are disabled at [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:266) and [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:454).
- ru/en i18n parity: new habit keys are mirrored in [en.json](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/i18n/locales/en.json:881) and [ru.json](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/i18n/locales/ru.json:893). Script result: `missingRu=[]`; Russian has expected extra plural keys.
- Note injection safety: notes are controlled textarea values, not HTML sinks, at [HabitJournal.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.tsx:579).

Tests strengthened:

- [HabitJournal.test.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.test.tsx:154): HTML-shaped note remains textarea data, creates no `img`, and is sent verbatim with status.
- [HabitJournal.test.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.test.tsx:322): shared-calendar journal writes pass `cal-shared` through `upsertEntry`, `deleteEntry`, and `deleteHabit`.
- Existing proof retained for future guard at [HabitJournal.test.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.test.tsx:348), post-write refetch lock at [HabitJournal.test.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.test.tsx:371), and delete rejection staying open at [HabitJournal.test.tsx](/Users/allosta/Desktop/allosta/superapp-slice7/apps/focal/client/src/features/habits/HabitJournal.test.tsx:406).

Verification results:

- Focused journal suite: `17 passed / 17`.
- Local equivalent typecheck: passed.
- Local equivalent lint: passed, `281 files`.
- Full Vitest with `NODE_OPTIONS=--localstorage-file=/tmp/focal-s7-ls`: `80 files passed`, `947 tests passed`.
- Local equivalent build: passed; Vite emitted only chunk-size/deprecated-option warnings.
- Required exact command `cd superapp-slice7/apps/focal/client && pnpm typecheck && pnpm lint && pnpm test:run && pnpm build`: failed before running `typecheck` with `[ERROR] fetch failed` from the pnpm wrapper.

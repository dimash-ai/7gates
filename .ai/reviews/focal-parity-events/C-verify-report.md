**Verification Report**

Ran the required branch diff/status review first. Final status is one test-only change: [EventsPage.test.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/EventsPage.test.tsx:665). No production files changed.

I scrutinized the slice against `.ai/design/focal-parity-events-design.md` and found no production defect requiring a gate-B stop. Calendar scoping is threaded through event reads/writes at [api/events.ts](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/api/events.ts:17), [EventsPage.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/EventsPage.tsx:237), and dialog reference/tag calls at [EventDialog.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/EventDialog.tsx:95). `canEdit` gates save/delete at [EventsPage.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/EventsPage.tsx:304), and the dialog disables submit/delete at [EventDialog.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/EventDialog.tsx:542).

Security boundaries checked: client calendar scoping is only threading, not the security boundary; `contactIds` are not encoded in create/update payloads at [eventsFilters.ts](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/eventsFilters.ts:381) and [eventsFilters.ts](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/eventsFilters.ts:403). `otherParticipants` is bound as textarea text at [EventDialog.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/EventDialog.tsx:527), with no HTML injection sink found in the event dialog path.

Timezone isolation checked: controlled mode does not call global `setDisplayTimezone` at [TimezoneSelector.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/components/TimezoneSelector.tsx:121) and [TimezoneSelector.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/components/TimezoneSelector.tsx:176). Event dialog wires it into `draft.timezone` at [EventDialog.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/EventDialog.tsx:276).

Exact-patch update contract checked: new fields enter create only when set and enter update only when dirty at [eventsFilters.ts](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/eventsFilters.ts:381) and [eventsFilters.ts](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/eventsFilters.ts:417). Recurring edits route through pending scope before mutation at [EventsPage.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/EventsPage.tsx:318) and confirm at [EventsPage.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/EventsPage.tsx:335). ru/en dialog/status keys are present at [en.json](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/i18n/locales/en.json:2336) and [ru.json](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/i18n/locales/ru.json:2354).

Strengthened tests in [EventsPage.test.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/EventsPage.test.tsx:665):
- Event timezone through the dialog saves `Asia/Tokyo` and leaves `focal-display-timezone` unset.
- Existing tag multi-select plus inline tag-create saves both tag ids and asserts no `contactIds`.
- Editing description/location/status/otherParticipants round-trips, including literal `<img ...>` text.
- Read-only page/dialog paths fire no create/update/save/delete callbacks.
- Recurring edit now asserts no update before `RecurringScopeDialog` confirmation.

Verification commands: exact `pnpm` attempts failed before script execution with `[ERROR] fetch failed` under restricted network, so I ran the equivalent local binaries. Node’s built-in `localStorage` is unusable here, so Vitest used `NODE_OPTIONS=--localstorage-file=/tmp/focal-s5-ls`.

Results:
- Typecheck: passed.
- Lint: passed, 280 files checked.
- Tests: passed, 78 files / 938 tests.
- Build: passed, with existing Vite chunk-size/deprecated `advancedChunks` warnings.
diff --git a/superapp-slice5/apps/focal/client/src/features/events/EventsPage.test.tsx b/superapp-slice5/apps/focal/client/src/features/events/EventsPage.test.tsx
index 1148c2f349458ee8ed2c84068db1b14700245966..71fa4346e5313814e3fb8079a853863a3610d6ce
--- a/superapp-slice5/apps/focal/client/src/features/events/EventsPage.test.tsx
+++ b/superapp-slice5/apps/focal/client/src/features/events/EventsPage.test.tsx
@@ -1,5 +1,5 @@
 import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
-import { render, screen, waitFor, within } from '@testing-library/react'
+import { fireEvent, render, screen, waitFor, within } from '@testing-library/react'
 import userEvent from '@testing-library/user-event'
 import { I18nextProvider } from 'react-i18next'
 import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
@@ -10,10 +10,13 @@
 import * as productsApi from '../../api/products'
 import type { Project } from '../../api/projects'
 import * as projectsApi from '../../api/projects'
+import type { Tag } from '../../api/tags'
 import * as tagsApi from '../../api/tags'
+import { TimezoneProvider } from '../../hooks/use-timezone'
 import { i18n } from '../../i18n'
 import { getDateRangeFromPreset } from '../../lib/datePresetRange'
 import { toIsoDate } from '../calendar/dates'
+import { EventDialog } from './EventDialog'
 import { EventsPage } from './EventsPage'
 import { STORAGE_KEY } from './eventsFilters'
 
@@ -123,6 +126,13 @@
     ...overrides,
   }) as unknown as Activity
 
+const tag = (overrides: Partial<Tag> = {}): Tag => ({
+  id: 'tag-1',
+  name: 'Deep Work',
+  color: '#3b82f6',
+  ...overrides,
+})
+
 const renderPage = () => {
   const queryClient = new QueryClient({
     defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
@@ -130,13 +140,67 @@
   const view = render(
     <I18nextProvider i18n={i18n}>
       <QueryClientProvider client={queryClient}>
-        <EventsPage />
+        <TimezoneProvider>
+          <EventsPage />
+        </TimezoneProvider>
       </QueryClientProvider>
     </I18nextProvider>,
   )
   return { queryClient, ...view }
 }
 
+const renderReadOnlyDialog = () => {
+  const queryClient = new QueryClient({
+    defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
+  })
+  const props = {
+    onParticipantsChange: vi.fn(),
+    onPatch: vi.fn(),
+    onSave: vi.fn(),
+    onDelete: vi.fn(),
+    onOpenChange: vi.fn(),
+  }
+  render(
+    <I18nextProvider i18n={i18n}>
+      <QueryClientProvider client={queryClient}>
+        <TimezoneProvider>
+          <EventDialog
+            open
+            mode="edit"
+            draft={{
+              title: 'Locked',
+              date: todayIso,
+              startTime: '09:00',
+              endTime: '10:00',
+              recurrence: 'none',
+              recurrenceEndDate: null,
+              color: null,
+              completed: false,
+              projectId: null,
+              productId: null,
+              activityId: null,
+              description: 'Read-only notes',
+              location: 'Room 1',
+              status: 'planned',
+              timezone: null,
+              tags: [],
+              otherParticipants: 'Guests',
+            }}
+            recurring={false}
+            participants={[]}
+            isSaving={false}
+            isDeleting={false}
+            readOnly
+            errorMessage={null}
+            {...props}
+          />
+        </TimezoneProvider>
+      </QueryClientProvider>
+    </I18nextProvider>,
+  )
+  return props
+}
+
 const setupUser = () => userEvent.setup({ advanceTimers: vi.advanceTimersByTime })
 
 const openCreatePopover = async (user: ReturnType<typeof setupUser>) => {
@@ -496,6 +560,7 @@
     await user.clear(title)
     await user.type(title, 'Weekly sync (new)')
     await user.click(screen.getByRole('button', { name: tr('focal.calendar.edit.save') }))
+    expect(mocked.updateEvent).not.toHaveBeenCalled()
     await user.click(
       await screen.findByRole('radio', { name: tr('focal.calendar.edit.scopes.following') }),
     )
@@ -597,6 +662,116 @@
     )
   })
 
+  it('keeps event timezone isolated from the global display preference through the dialog', async () => {
+    const user = setupUser()
+    mocked.createEvent.mockResolvedValue(event({ id: 'new', title: 'Tokyo planning' }))
+    renderPage()
+
+    const title = await openCreatePopover(user)
+    await user.type(title, 'Tokyo planning')
+    expect(localStorage.getItem('focal-display-timezone')).toBeNull()
+
+    await user.click(screen.getByRole('button', { name: tr('focal.app.timezone.label') }))
+    await user.click(await screen.findByText('Tokyo'))
+
+    expect(screen.getByText('Asia/Tokyo')).toBeInTheDocument()
+    expect(localStorage.getItem('focal-display-timezone')).toBeNull()
+
+    await user.click(screen.getByRole('button', { name: tr('focal.calendar.form.submit') }))
+
+    await waitFor(() =>
+      expect(mocked.createEvent).toHaveBeenCalledWith(
+        expect.objectContaining({ title: 'Tokyo planning', timezone: 'Asia/Tokyo' }),
+        null,
+      ),
+    )
+  })
+
+  it('selects existing tags and an inline-created tag for the saved event', async () => {
+    calendarFilter.currentCalendarId = 'cal-tags'
+    mockedTags.listTags.mockResolvedValue([tag({ id: 'tag-existing', name: 'Deep Work' })])
+    mockedTags.createTag.mockResolvedValue(
+      tag({ id: 'tag-new', name: 'Focus Sprint', color: '#ef4444' }),
+    )
+    mocked.createEvent.mockResolvedValue(event({ id: 'new', title: 'Tagged event' }))
+    const user = setupUser()
+    renderPage()
+
+    const title = await openCreatePopover(user)
+    await user.type(title, 'Tagged event')
+    const dialog = screen.getByTestId('dialog-event')
+    const tagsCombobox = within(dialog)
+      .getAllByRole('combobox')
+      .find((element) => element.getAttribute('aria-haspopup') === 'dialog')
+    if (!tagsCombobox) throw new Error('Tags combobox not found')
+    await user.click(tagsCombobox)
+    await user.click(await screen.findByRole('option', { name: 'Deep Work' }))
+    await user.click(screen.getByRole('button', { name: tr('focal.tasks.dialog.createTag') }))
+    await user.type(screen.getByLabelText(tr('focal.tasks.dialog.tagName')), 'Focus Sprint')
+    await user.click(screen.getByRole('button', { name: tr('focal.tags.actions.create') }))
+
+    await waitFor(() =>
+      expect(mockedTags.createTag).toHaveBeenCalledWith(
+        { name: 'Focus Sprint', color: '#ef4444' },
+        'cal-tags',
+      ),
+    )
+    await user.click(screen.getByRole('button', { name: tr('focal.calendar.form.submit') }))
+
+    await waitFor(() => expect(mocked.createEvent).toHaveBeenCalled())
+    const payload = mocked.createEvent.mock.calls[0]?.[0]
+    expect(payload).toEqual(expect.objectContaining({ tags: ['tag-existing', 'tag-new'] }))
+    expect(payload).not.toHaveProperty('contactIds')
+  })
+
+  it('round-trips edited description, location, status, and free-text participants', async () => {
+    const injectedText = 'Alex <img src=x onerror=alert(1)>'
+    mocked.listEvents.mockResolvedValue([
+      event({
+        id: 'e8',
+        title: 'Planning',
+        description: 'Old notes',
+        location: 'Old room',
+        status: 'planned',
+        otherParticipants: 'Ana',
+      }),
+    ])
+    mocked.updateEvent.mockResolvedValue(event({ id: 'e8', title: 'Planning' }))
+    const user = setupUser()
+    renderPage()
+
+    await openEditPopover(user, 'Planning')
+    const description = screen.getByLabelText(tr('focal.events.dialog.description'))
+    const location = screen.getByLabelText(tr('focal.events.dialog.location'))
+    const otherParticipants = screen.getByLabelText(tr('focal.events.dialog.otherParticipants'))
+    expect(description).toHaveValue('Old notes')
+    expect(location).toHaveValue('Old room')
+    expect(screen.getByLabelText(tr('focal.events.dialog.status'))).toHaveValue('planned')
+    expect(otherParticipants).toHaveValue('Ana')
+
+    await user.clear(description)
+    await user.type(description, 'New notes')
+    await user.clear(location)
+    await user.type(location, 'New room')
+    await user.selectOptions(screen.getByLabelText(tr('focal.events.dialog.status')), 'confirmed')
+    await user.clear(otherParticipants)
+    await user.type(otherParticipants, injectedText)
+    expect(otherParticipants).toHaveValue(injectedText)
+    await user.click(screen.getByRole('button', { name: tr('focal.calendar.edit.save') }))
+
+    await waitFor(() => expect(mocked.updateEvent).toHaveBeenCalled())
+    const patch = mocked.updateEvent.mock.calls[0]?.[1]
+    expect(patch).toEqual(
+      expect.objectContaining({
+        description: 'New notes',
+        location: 'New room',
+        status: 'confirmed',
+        otherParticipants: injectedText,
+      }),
+    )
+    expect(patch).not.toHaveProperty('contactIds')
+  })
+
   it('fires no write from the dialog when the calendar is read-only', async () => {
     calendarFilter.canEdit = false
     mocked.listEvents.mockResolvedValue([event({ id: 'e7', title: 'Locked' })])
@@ -611,4 +786,24 @@
     expect(mocked.createEvent).not.toHaveBeenCalled()
     expect(mocked.updateEvent).not.toHaveBeenCalled()
   })
+
+  it('keeps the read-only EventDialog submit and delete callbacks inert', async () => {
+    const user = setupUser()
+    const props = renderReadOnlyDialog()
+
+    expect(screen.getByLabelText(tr('focal.calendar.form.title'))).toBeDisabled()
+    expect(screen.getByRole('button', { name: tr('focal.calendar.edit.save') })).toBeDisabled()
+    expect(screen.getByRole('button', { name: tr('focal.calendar.edit.delete') })).toBeDisabled()
+    expect(
+      screen.getByRole('button', { name: tr('focal.calendar.contactPicker.add') }),
+    ).toBeDisabled()
+
+    await user.click(screen.getByRole('button', { name: tr('focal.calendar.edit.save') }))
+    await user.click(screen.getByRole('button', { name: tr('focal.calendar.edit.delete') }))
+    fireEvent.submit(screen.getByTestId('event-dialog-form'))
+
+    expect(props.onSave).not.toHaveBeenCalled()
+    expect(props.onDelete).not.toHaveBeenCalled()
+    expect(props.onPatch).not.toHaveBeenCalled()
+  })
 })

tokens used
257 238
**Verification Report**

Ran the required branch diff/status review first. Final status is one test-only change: [EventsPage.test.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/EventsPage.test.tsx:665). No production files changed.

I scrutinized the slice against `.ai/design/focal-parity-events-design.md` and found no production defect requiring a gate-B stop. Calendar scoping is threaded through event reads/writes at [api/events.ts](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/api/events.ts:17), [EventsPage.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/EventsPage.tsx:237), and dialog reference/tag calls at [EventDialog.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/EventDialog.tsx:95). `canEdit` gates save/delete at [EventsPage.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/EventsPage.tsx:304), and the dialog disables submit/delete at [EventDialog.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/EventDialog.tsx:542).

Security boundaries checked: client calendar scoping is only threading, not the security boundary; `contactIds` are not encoded in create/update payloads at [eventsFilters.ts](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/eventsFilters.ts:381) and [eventsFilters.ts](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/eventsFilters.ts:403). `otherParticipants` is bound as textarea text at [EventDialog.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/EventDialog.tsx:527), with no HTML injection sink found in the event dialog path.

Timezone isolation checked: controlled mode does not call global `setDisplayTimezone` at [TimezoneSelector.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/components/TimezoneSelector.tsx:121) and [TimezoneSelector.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/components/TimezoneSelector.tsx:176). Event dialog wires it into `draft.timezone` at [EventDialog.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/EventDialog.tsx:276).

Exact-patch update contract checked: new fields enter create only when set and enter update only when dirty at [eventsFilters.ts](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/eventsFilters.ts:381) and [eventsFilters.ts](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/eventsFilters.ts:417). Recurring edits route through pending scope before mutation at [EventsPage.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/EventsPage.tsx:318) and confirm at [EventsPage.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/EventsPage.tsx:335). ru/en dialog/status keys are present at [en.json](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/i18n/locales/en.json:2336) and [ru.json](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/i18n/locales/ru.json:2354).

Strengthened tests in [EventsPage.test.tsx](/Users/allosta/Desktop/allosta/superapp-slice5/apps/focal/client/src/features/events/EventsPage.test.tsx:665):
- Event timezone through the dialog saves `Asia/Tokyo` and leaves `focal-display-timezone` unset.
- Existing tag multi-select plus inline tag-create saves both tag ids and asserts no `contactIds`.
- Editing description/location/status/otherParticipants round-trips, including literal `<img ...>` text.
- Read-only page/dialog paths fire no create/update/save/delete callbacks.
- Recurring edit now asserts no update before `RecurringScopeDialog` confirmation.

Verification commands: exact `pnpm` attempts failed before script execution with `[ERROR] fetch failed` under restricted network, so I ran the equivalent local binaries. Node’s built-in `localStorage` is unusable here, so Vitest used `NODE_OPTIONS=--localstorage-file=/tmp/focal-s5-ls`.

Results:
- Typecheck: passed.
- Lint: passed, 280 files checked.
- Tests: passed, 78 files / 938 tests.
- Build: passed, with existing Vite chunk-size/deprecated `advancedChunks` warnings.

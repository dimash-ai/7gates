Reading additional input from stdin...
OpenAI Codex v0.135.0
--------
workdir: /Users/allosta/Desktop/allosta
model: gpt-5.5
provider: openai
approval: never
sandbox: read-only
reasoning effort: xhigh
reasoning summaries: none
session id: 019f032b-8f10-7070-9d23-405e3ab46aeb
--------
user
# Reviewer Charter (any model)

You are acting **only as the reviewer** for one step of the 7-step pipeline. You did **not**
produce this work — the **other** model did. Opus reviews GPT's work; GPT reviews Opus's work.
Review it cold and judge independently. Treat your verdict as a gate, not a suggestion.

You are **read-only**: never edit, create, or delete any file. Return only the scored verdict.

## What you score

- correctness, regressions, missing tests, edge cases, security, maintainability
- whether the work matches the task/plan/design it claims to satisfy

Plus the four house principles (full text in root `CLAUDE.md`; severity in
`.ai/checklists/scoring-rubric.md`):
- **Think Before Coding** — silent wrong assumptions, ambiguity resolved without surfacing, missing tradeoffs.
- **Simplicity First** — overcomplication, speculative abstractions, bloat.
- **Surgical Changes** — edits unrelated to the task, style drift, code changed/removed the task didn't require.
- **Goal-Driven Execution** — missing or weak verifiable success criteria for the new behavior.

## How to review (every step)

- **Scope first.** Confirm exactly what the step demanded was produced — no more, no less. Unrelated files, "while I was in there" edits, and unaddressed requirements are the first finding.
- **Cite evidence.** Every Must Fix names the exact `file:line` (or failing command). An issue you cannot point to, or are unsure is real, is **Should Consider**, never Must Fix — never block a 9.0 on an unproven hunch.
- **Read beyond the diff for completeness.** When a change adds an enum/status/union value or a new case, open the sibling call-sites outside the diff and confirm every switch/handler covers it.
- **Don't flag context-correct patterns.** Best-effort cleanup, fire-and-forget calls, and "sloppy"-looking code that is the right engineering choice are not findings. Never suggest a refactor that only satisfies a linter; match the codebase's existing style.
- **Review adversarially.** Think like an attacker and a chaos engineer — races, resource leaks, silent data corruption, swallowed failures, unbounded retries. One concrete "here is how it breaks in production" finding beats generic "safer is better".

## Step-specific lenses

The slash command tells you which step you are reviewing. Apply the matching lens:

- **think** — Is the problem framed correctly? Are assumptions explicit and the chosen option justified against the alternatives? Is anything important unstated or unbounded?
- **plan** — Minimum viable change? Does existing code already solve part of it? Failure modes named (which error, caught where, what the user sees), not "handle errors"? Does it state what each test proves?
- **design** — Coupling, state transitions, data flow on the unhappy path (null/empty/upstream error). Are the interfaces/contracts and the data model sound? Are alternatives considered and rejected for stated reasons?
- **build** — Correctness, regressions, security, deviation from plan/design. Scope-first against the diff.
- **review** (you are scoring the *other* model's review pass) — Is the review correct, complete, and well-evidenced? Did it miss real defects, or raise false Must-Fixes? Score the **quality of the review**, not the underlying code directly.
- **test** — Do the tests cover the risky paths or just the happy path? Did the suite actually run green? Any unproven "pre-existing" failure is itself a Must Fix.
- **ship** — Use the release-gate prompt (`.ai/prompts/final-release-review.md`): whole-change security pass, PR text honesty, migrations/rollback, no secrets in shipped text.

Do not rewrite the solution. Do not request broad refactors unless they block correctness or a safe release.

## Scoring

Score 0–10 using `.ai/checklists/scoring-rubric.md`. Hard rules:
- Any **must-fix** issue caps the score at **8.9** (cannot be APPROVED).
- Any **security**, **data-loss**, or **build/test-breaking** issue caps the score at **7.9** or lower.
- Status is **APPROVED only if Score >= 9.0**; otherwise BLOCKED.

## Verdict format

Output EXACTLY this and nothing else:

```
# Review Verdict

Reviewer: <Opus | GPT Codex>
Step: <think | plan | design | build | review | test | ship>
Score: X.X / 10
Status: APPROVED or BLOCKED

## Reason
<1–3 sentences on why this score>

## Must Fix
<blocking issues as a list, or "None">

## Should Consider
<non-blocking suggestions, or "None">

## Tests Reviewed
<the tests/commands you inspected or ran, or "N/A" for think/plan/design>

## Release Risk
Low, Medium, or High
```
You are GPT Codex, the doer for the REVIEW step (re-run #4) of focal-parity-data-scope. Run 'git -C /Users/allosta/Desktop/allosta/superapp-slice2 --no-pager diff feature/focal-migration' and the log.

Your pass-4 Must-Fix (delegated other-pages writes copy unchecked FK links → cascade data loss) is now FIXED — verify and do not re-raise: app/services/activities.py create_activity/update_activity now call _require_owned_links(user_id, project_id, product_id) (a project/product must belong to the data owner, else RelatedRecordNotFoundError); app/services/activity_instances.py sync_instances now rejects an activity_id not owned by user_id. I also AUDITED the sibling other-pages write domains and confirmed they ALREADY validate owner FK linkage: tasks + events + bookings via _require_owned_link; projects.create_project via _owned(parent) + update via _guard_reparent; goals.create_goal/update_goal via _require_project. Regression: tests/test_calendar_scope_db.py::test_delegated_other_pages_writes_reject_non_owner_fk_links.

Earlier-settled, do NOT re-raise: the recurrence scope invariant is fully closed (effective-occurrence + master + override-range + delete-all sibling-group validation); meeting-request accept/reschedule are scoped by shared_calendar_id (no project links on meeting events); the AI 'calendars' management entity is denied to delegated callers; AI shared-calendar ASSISTANT mode is deferred to slice 12 per the documented design note; the editor-direct-route client UX guard is an accepted non-blocking Should-Consider.

Do a FINAL holistic pass: if there is genuinely nothing else release-blocking across the whole change (cross-cutting authz, leaks, injection, secrets, silent corruption, swallowed failures, backward-compat — note data_owner_dep opens its session only in shared mode so own-data stays DB-free), say so and APPROVE. Build gate APPROVED 9.2; backend ruff+mypy+1702 pytest pass (only pre-existing 12 OpenAI-env + 1 ProjectRead.icon fails); client typecheck+biome+828 vitest+build pass. Review against task .ai/tasks/focal-parity.md, plan .ai/plans/focal-parity-plan.md, design .ai/design/focal-parity-data-scope-design.md + .ai/design/focal-parity-design.md. Cite file:line. Read-only; NEVER edit. Output the verdict EXACTLY as the charter specifies (Reviewer: GPT Codex, Step: review).
2026-06-26T09:03:35.060783Z ERROR rmcp::transport::worker: worker quit with fatal: Transport channel closed, when AuthRequired(AuthRequiredError { www_authenticate_header: "Bearer realm=\"OAuth\", resource_metadata=\"https://mcp.linear.app/.well-known/oauth-protected-resource/mcp\", error=\"invalid_token\", error_description=\"Missing or invalid access token\"" })
2026-06-26T09:03:35.294423Z ERROR rmcp::transport::worker: worker quit with fatal: Transport channel closed, when AuthRequired(AuthRequiredError { www_authenticate_header: "Bearer realm=\"mcp\", resource_metadata=\"https://mcp.railway.com/.well-known/oauth-protected-resource\"" })
2026-06-26T09:03:35.380699Z ERROR rmcp::transport::worker: worker quit with fatal: Transport channel closed, when AuthRequired(AuthRequiredError { www_authenticate_header: "Bearer resource_metadata=\"https://mcp.figma.com/.well-known/oauth-protected-resource\",scope=\"mcp:connect\",authorization_uri=\"https://api.figma.com/.well-known/oauth-authorization-server\"" })
exec
/bin/zsh -lc 'git -C /Users/allosta/Desktop/allosta/superapp-slice2 status --short' in /Users/allosta/Desktop/allosta
 succeeded in 0ms:
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-nqzIBBFU' (errno=Operation not permitted)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-FSwr6V7F' (errno=Operation not permitted)

exec
/bin/zsh -lc 'git -C /Users/allosta/Desktop/allosta/superapp-slice2 --no-pager diff feature/focal-migration' in /Users/allosta/Desktop/allosta
 succeeded in 0ms:
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-TSoUm6Ac' (errno=Operation not permitted)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-KEYVq2ql' (errno=Operation not permitted)
diff --git a/apps/focal/client/src/api/activities.ts b/apps/focal/client/src/api/activities.ts
index 90cbb3a..89c2786 100644
--- a/apps/focal/client/src/api/activities.ts
+++ b/apps/focal/client/src/api/activities.ts
@@ -6,7 +6,18 @@ export type Activity = Schemas['ActivityRead']
 export type ActivityUpdate = Schemas['ActivityUpdate']
 
 // The list endpoint returns every activity for the user; callers filter by productId.
-export const listActivities = (): Promise<Activity[]> => apiFetch<Activity[]>('/api/activities')
+// `calendarId` (the active shared-calendar selection; null = own data) scopes the call to that
+// calendar's owner server-side.
+export const listActivities = (calendarId?: string | null): Promise<Activity[]> =>
+  apiFetch<Activity[]>('/api/activities', { query: { calendarId } })
 
-export const updateActivity = (id: string, patch: ActivityUpdate): Promise<Activity> =>
-  apiFetch<Activity>(`/api/activities/${id}`, { method: 'PATCH', body: patch })
+export const updateActivity = (
+  id: string,
+  patch: ActivityUpdate,
+  calendarId?: string | null,
+): Promise<Activity> =>
+  apiFetch<Activity>(`/api/activities/${id}`, {
+    method: 'PATCH',
+    body: patch,
+    query: { calendarId },
+  })
diff --git a/apps/focal/client/src/api/activityInstances.ts b/apps/focal/client/src/api/activityInstances.ts
index 8f6b8f7..0c66c75 100644
--- a/apps/focal/client/src/api/activityInstances.ts
+++ b/apps/focal/client/src/api/activityInstances.ts
@@ -6,18 +6,33 @@ export type ActivityInstance = Schemas['ActivityInstanceRead']
 export type ActivityInstanceUpdate = Schemas['ActivityInstanceUpdate']
 export type ActivityInstanceSyncRequest = Schemas['ActivityInstanceSyncRequest']
 
-export const listActivityInstances = (activityId: string): Promise<ActivityInstance[]> =>
-  apiFetch<ActivityInstance[]>('/api/activity-instances', { query: { activityId } })
+// `calendarId` (the active shared-calendar selection; null = own data) scopes the call to that
+// calendar's owner server-side.
+export const listActivityInstances = (
+  activityId: string,
+  calendarId?: string | null,
+): Promise<ActivityInstance[]> =>
+  apiFetch<ActivityInstance[]>('/api/activity-instances', { query: { activityId, calendarId } })
 
 export const updateActivityInstance = (
   id: string,
   patch: ActivityInstanceUpdate,
+  calendarId?: string | null,
 ): Promise<ActivityInstance> =>
-  apiFetch<ActivityInstance>(`/api/activity-instances/${id}`, { method: 'PATCH', body: patch })
+  apiFetch<ActivityInstance>(`/api/activity-instances/${id}`, {
+    method: 'PATCH',
+    body: patch,
+    query: { calendarId },
+  })
 
 // Reconcile the stored instances with the activity's planned yearly count (appends
 // missing rows, trims surplus ones). Returns the reconciled instance list.
 export const syncActivityInstances = (
   input: ActivityInstanceSyncRequest,
+  calendarId?: string | null,
 ): Promise<ActivityInstance[]> =>
-  apiFetch<ActivityInstance[]>('/api/activity-instances/sync', { method: 'POST', body: input })
+  apiFetch<ActivityInstance[]>('/api/activity-instances/sync', {
+    method: 'POST',
+    body: input,
+    query: { calendarId },
+  })
diff --git a/apps/focal/client/src/api/analytics.ts b/apps/focal/client/src/api/analytics.ts
index 139eaf6..9880545 100644
--- a/apps/focal/client/src/api/analytics.ts
+++ b/apps/focal/client/src/api/analytics.ts
@@ -3,10 +3,14 @@ import { apiFetch, type Schemas } from './client'
 export type SpheresAnalytics = Schemas['SpheresAnalyticsRead']
 export type SphereAnalytics = Schemas['SphereAnalytics']
 
+// `calendarId` (the active shared-calendar selection; null = own data) scopes the call to that
+// calendar owner's data server-side. `buildUrl` drops null/undefined query values, so passing it
+// straight through is a no-op when absent.
 export const getSpheresAnalytics = (
   periodStart: string,
   periodEnd: string,
+  calendarId?: string | null,
 ): Promise<SpheresAnalytics> =>
   apiFetch<SpheresAnalytics>('/api/analytics/spheres', {
-    query: { periodStart, periodEnd },
+    query: { periodStart, periodEnd, calendarId },
   })
diff --git a/apps/focal/client/src/api/events.ts b/apps/focal/client/src/api/events.ts
index 00cf4e1..5845f88 100644
--- a/apps/focal/client/src/api/events.ts
+++ b/apps/focal/client/src/api/events.ts
@@ -14,25 +14,47 @@ export interface RecurrenceTarget {
   occurrenceDate: string
 }
 
-export const listEvents = (startDate: string, endDate: string): Promise<CalendarEvent[]> =>
-  apiFetch<CalendarEvent[]>('/api/events', { query: { startDate, endDate } })
+// `calendarId` (the active shared-calendar selection; null = own/main) scopes a call to the calendar
+// owner's data server-side, RBAC-gated: reads return the owner's filtered events, writes apply on the
+// owner's calendar. Omitted/null → the caller's own data (unchanged). `buildUrl` drops null/undefined
+// query values, so passing it straight through is a no-op when absent.
+export const listEvents = (
+  startDate: string,
+  endDate: string,
+  calendarId?: string | null,
+): Promise<CalendarEvent[]> =>
+  apiFetch<CalendarEvent[]>('/api/events', { query: { startDate, endDate, calendarId } })
 
-export const createEvent = (input: EventCreate): Promise<CalendarEvent> =>
-  apiFetch<CalendarEvent>('/api/events', { method: 'POST', body: input })
+export const createEvent = (
+  input: EventCreate,
+  calendarId?: string | null,
+): Promise<CalendarEvent> =>
+  apiFetch<CalendarEvent>('/api/events', { method: 'POST', body: input, query: { calendarId } })
 
 export const updateEvent = (
   id: string,
   patch: EventUpdate,
   target?: RecurrenceTarget,
+  calendarId?: string | null,
 ): Promise<CalendarEvent> =>
   apiFetch<CalendarEvent>(`/api/events/${id}`, {
     method: 'PATCH',
     body: patch,
-    query: target && { recurrenceScope: target.scope, occurrenceDate: target.occurrenceDate },
+    query: {
+      ...(target && { recurrenceScope: target.scope, occurrenceDate: target.occurrenceDate }),
+      calendarId,
+    },
   })
 
-export const deleteEvent = (id: string, target?: RecurrenceTarget): Promise<void> =>
+export const deleteEvent = (
+  id: string,
+  target?: RecurrenceTarget,
+  calendarId?: string | null,
+): Promise<void> =>
   apiFetch<undefined>(`/api/events/${id}`, {
     method: 'DELETE',
-    query: target && { recurrenceScope: target.scope, occurrenceDate: target.occurrenceDate },
+    query: {
+      ...(target && { recurrenceScope: target.scope, occurrenceDate: target.occurrenceDate }),
+      calendarId,
+    },
   }).then(() => undefined)
diff --git a/apps/focal/client/src/api/goals.ts b/apps/focal/client/src/api/goals.ts
index 59e6634..40f356c 100644
--- a/apps/focal/client/src/api/goals.ts
+++ b/apps/focal/client/src/api/goals.ts
@@ -6,13 +6,23 @@ export type Goal = Schemas['GoalRead']
 export type GoalCreate = Schemas['GoalCreate']
 export type GoalUpdate = Schemas['GoalUpdate']
 
-export const listGoals = (): Promise<Goal[]> => apiFetch<Goal[]>('/api/goals')
+// `calendarId` (the active shared-calendar selection; null = own data) scopes the call to that
+// calendar's owner server-side.
+export const listGoals = (calendarId?: string | null): Promise<Goal[]> =>
+  apiFetch<Goal[]>('/api/goals', { query: { calendarId } })
 
-export const createGoal = (input: GoalCreate): Promise<Goal> =>
-  apiFetch<Goal>('/api/goals', { method: 'POST', body: input })
+export const createGoal = (input: GoalCreate, calendarId?: string | null): Promise<Goal> =>
+  apiFetch<Goal>('/api/goals', { method: 'POST', body: input, query: { calendarId } })
 
-export const updateGoal = (id: string, patch: GoalUpdate): Promise<Goal> =>
-  apiFetch<Goal>(`/api/goals/${id}`, { method: 'PATCH', body: patch })
+export const updateGoal = (
+  id: string,
+  patch: GoalUpdate,
+  calendarId?: string | null,
+): Promise<Goal> =>
+  apiFetch<Goal>(`/api/goals/${id}`, { method: 'PATCH', body: patch, query: { calendarId } })
 
-export const deleteGoal = (id: string): Promise<void> =>
-  apiFetch<{ success: boolean }>(`/api/goals/${id}`, { method: 'DELETE' }).then(() => undefined)
+export const deleteGoal = (id: string, calendarId?: string | null): Promise<void> =>
+  apiFetch<{ success: boolean }>(`/api/goals/${id}`, {
+    method: 'DELETE',
+    query: { calendarId },
+  }).then(() => undefined)
diff --git a/apps/focal/client/src/api/habits.ts b/apps/focal/client/src/api/habits.ts
index d095b1d..0fb02ab 100644
--- a/apps/focal/client/src/api/habits.ts
+++ b/apps/focal/client/src/api/habits.ts
@@ -14,42 +14,64 @@ export type EntryStatus = HabitEntryUpsert['status']
 export type HabitEntryStat = Schemas['HabitEntryStatRead']
 export type HabitStatsGranularity = 'day' | 'month'
 
-export const listHabits = (archived = false): Promise<Habit[]> =>
-  apiFetch<Habit[]>('/api/habits', { query: { archived } })
+// `calendarId` (the active shared-calendar selection; null = own data) scopes the call to that
+// calendar owner's data server-side. `buildUrl` drops null/undefined query values, so passing it
+// straight through is a no-op when absent.
+export const listHabits = (archived = false, calendarId?: string | null): Promise<Habit[]> =>
+  apiFetch<Habit[]>('/api/habits', { query: { archived, calendarId } })
 
-export const createHabit = (input: HabitCreate): Promise<Habit> =>
-  apiFetch<Habit>('/api/habits', { method: 'POST', body: input })
+export const createHabit = (input: HabitCreate, calendarId?: string | null): Promise<Habit> =>
+  apiFetch<Habit>('/api/habits', { method: 'POST', body: input, query: { calendarId } })
 
-export const updateHabit = (id: string, patch: HabitUpdate): Promise<Habit> =>
-  apiFetch<Habit>(`/api/habits/${id}`, { method: 'PATCH', body: patch })
+export const updateHabit = (
+  id: string,
+  patch: HabitUpdate,
+  calendarId?: string | null,
+): Promise<Habit> =>
+  apiFetch<Habit>(`/api/habits/${id}`, { method: 'PATCH', body: patch, query: { calendarId } })
 
 // Hard delete — entries cascade. Archiving is updateHabit(id, { isArchived: true }).
-export const deleteHabit = (id: string): Promise<void> =>
-  apiFetch<undefined>(`/api/habits/${id}`, { method: 'DELETE' }).then(() => undefined)
-
-export const restoreHabit = (id: string): Promise<Habit> =>
-  apiFetch<Habit>(`/api/habits/${id}/restore`, { method: 'POST' })
-
-export const reorderHabits = (orderedIds: string[]): Promise<void> =>
-  apiFetch<undefined>('/api/habits/reorder', { method: 'POST', body: { orderedIds } }).then(
+export const deleteHabit = (id: string, calendarId?: string | null): Promise<void> =>
+  apiFetch<undefined>(`/api/habits/${id}`, { method: 'DELETE', query: { calendarId } }).then(
     () => undefined,
   )
 
+export const restoreHabit = (id: string, calendarId?: string | null): Promise<Habit> =>
+  apiFetch<Habit>(`/api/habits/${id}/restore`, { method: 'POST', query: { calendarId } })
+
+export const reorderHabits = (orderedIds: string[], calendarId?: string | null): Promise<void> =>
+  apiFetch<undefined>('/api/habits/reorder', {
+    method: 'POST',
+    body: { orderedIds },
+    query: { calendarId },
+  }).then(() => undefined)
+
 // The backend computes streaks relative to the caller's local "today" (a required query param);
 // omitting it returns 422 and no streaks load.
-export const listStreaks = (today: string): Promise<HabitStreak[]> =>
-  apiFetch<HabitStreak[]>('/api/habits/streaks', { query: { today } })
+export const listStreaks = (today: string, calendarId?: string | null): Promise<HabitStreak[]> =>
+  apiFetch<HabitStreak[]>('/api/habits/streaks', { query: { today, calendarId } })
 
-export const listEntries = (start: string, end: string): Promise<HabitEntry[]> =>
-  apiFetch<HabitEntry[]>('/api/habit-entries', { query: { start, end } })
+export const listEntries = (
+  start: string,
+  end: string,
+  calendarId?: string | null,
+): Promise<HabitEntry[]> =>
+  apiFetch<HabitEntry[]>('/api/habit-entries', { query: { start, end, calendarId } })
 
-export const upsertEntry = (input: HabitEntryUpsert): Promise<HabitEntry> =>
-  apiFetch<HabitEntry>('/api/habit-entries', { method: 'POST', body: input })
+export const upsertEntry = (
+  input: HabitEntryUpsert,
+  calendarId?: string | null,
+): Promise<HabitEntry> =>
+  apiFetch<HabitEntry>('/api/habit-entries', { method: 'POST', body: input, query: { calendarId } })
 
-export const deleteEntry = (habitId: string, date: string): Promise<void> =>
+export const deleteEntry = (
+  habitId: string,
+  date: string,
+  calendarId?: string | null,
+): Promise<void> =>
   apiFetch<undefined>('/api/habit-entries', {
     method: 'DELETE',
-    query: { habitId, date },
+    query: { habitId, date, calendarId },
   }).then(() => undefined)
 
 // Aggregated entry counts for the charts tab. The tenant is derived from the JWT, so
@@ -58,5 +80,8 @@ export const listHabitEntryStats = (
   start: string,
   end: string,
   granularity: HabitStatsGranularity = 'month',
+  calendarId?: string | null,
 ): Promise<HabitEntryStat[]> =>
-  apiFetch<HabitEntryStat[]>('/api/habit-entries/stats', { query: { start, end, granularity } })
+  apiFetch<HabitEntryStat[]>('/api/habit-entries/stats', {
+    query: { start, end, granularity, calendarId },
+  })
diff --git a/apps/focal/client/src/api/meetingRequests.ts b/apps/focal/client/src/api/meetingRequests.ts
index 7b0e5a2..83681ed 100644
--- a/apps/focal/client/src/api/meetingRequests.ts
+++ b/apps/focal/client/src/api/meetingRequests.ts
@@ -5,27 +5,59 @@ import { apiFetch, type Schemas } from './client'
 export type MeetingRequest = Schemas['MeetingRequestRead']
 export type MeetingRequestAction = Schemas['MeetingRequestActionRead']
 
-export const listMeetingRequests = (): Promise<MeetingRequest[]> =>
-  apiFetch<MeetingRequest[]>('/api/meeting-requests')
-
-export const acceptMeetingRequest = (id: string): Promise<MeetingRequestAction> =>
-  apiFetch<MeetingRequestAction>(`/api/meeting-requests/${id}/accept`, { method: 'POST' })
+// `calendarId` (the active shared-calendar selection; null = own data) scopes the call to that
+// calendar owner's data server-side. `buildUrl` drops null/undefined query values, so passing it
+// straight through is a no-op when absent.
+export const listMeetingRequests = (calendarId?: string | null): Promise<MeetingRequest[]> =>
+  apiFetch<MeetingRequest[]>('/api/meeting-requests', { query: { calendarId } })
+
+export const acceptMeetingRequest = (
+  id: string,
+  calendarId?: string | null,
+): Promise<MeetingRequestAction> =>
+  apiFetch<MeetingRequestAction>(`/api/meeting-requests/${id}/accept`, {
+    method: 'POST',
+    query: { calendarId },
+  })
 
-export const declineMeetingRequest = (id: string): Promise<MeetingRequestAction> =>
-  apiFetch<MeetingRequestAction>(`/api/meeting-requests/${id}/decline`, { method: 'POST' })
+export const declineMeetingRequest = (
+  id: string,
+  calendarId?: string | null,
+): Promise<MeetingRequestAction> =>
+  apiFetch<MeetingRequestAction>(`/api/meeting-requests/${id}/decline`, {
+    method: 'POST',
+    query: { calendarId },
+  })
 
-export const tentativeMeetingRequest = (id: string): Promise<MeetingRequestAction> =>
-  apiFetch<MeetingRequestAction>(`/api/meeting-requests/${id}/tentative`, { method: 'POST' })
+export const tentativeMeetingRequest = (
+  id: string,
+  calendarId?: string | null,
+): Promise<MeetingRequestAction> =>
+  apiFetch<MeetingRequestAction>(`/api/meeting-requests/${id}/tentative`, {
+    method: 'POST',
+    query: { calendarId },
+  })
 
-export const acceptMeetingReschedule = (id: string): Promise<MeetingRequestAction> =>
+export const acceptMeetingReschedule = (
+  id: string,
+  calendarId?: string | null,
+): Promise<MeetingRequestAction> =>
   apiFetch<MeetingRequestAction>(`/api/meeting-requests/${id}/accept-reschedule`, {
     method: 'POST',
+    query: { calendarId },
   })
 
-export const declineMeetingReschedule = (id: string): Promise<MeetingRequestAction> =>
+export const declineMeetingReschedule = (
+  id: string,
+  calendarId?: string | null,
+): Promise<MeetingRequestAction> =>
   apiFetch<MeetingRequestAction>(`/api/meeting-requests/${id}/decline-reschedule`, {
     method: 'POST',
+    query: { calendarId },
   })
 
-export const deleteMeetingRequest = (id: string): Promise<void> =>
-  apiFetch<undefined>(`/api/meeting-requests/${id}`, { method: 'DELETE' }).then(() => undefined)
+export const deleteMeetingRequest = (id: string, calendarId?: string | null): Promise<void> =>
+  apiFetch<undefined>(`/api/meeting-requests/${id}`, {
+    method: 'DELETE',
+    query: { calendarId },
+  }).then(() => undefined)
diff --git a/apps/focal/client/src/api/mindmap.ts b/apps/focal/client/src/api/mindmap.ts
index ab24e99..8a9cdd2 100644
--- a/apps/focal/client/src/api/mindmap.ts
+++ b/apps/focal/client/src/api/mindmap.ts
@@ -3,37 +3,65 @@ import { apiFetch, type ResponseOf } from './client'
 // The unified MindMap payload: base nodes/edges + the user's projects and activities.
 export type MindmapInit = ResponseOf<'/api/mindmap/init', 'get'>
 
-export const getMindmapInit = (): Promise<MindmapInit> => apiFetch<MindmapInit>('/api/mindmap/init')
+// `calendarId` (the active shared-calendar selection; null = own data) scopes the call to that
+// calendar owner's data server-side. `buildUrl` drops null/undefined query values, so passing it
+// straight through is a no-op when absent.
+export const getMindmapInit = (calendarId?: string | null): Promise<MindmapInit> =>
+  apiFetch<MindmapInit>('/api/mindmap/init', { query: { calendarId } })
 
 // Persist a node's new canvas position to its backing entity. Fire-and-forget from the drag
 // handler — the node is already shown at the new spot; the caller resets on failure.
-export const moveProject = (id: string, x: number, y: number): Promise<void> =>
+export const moveProject = (
+  id: string,
+  x: number,
+  y: number,
+  calendarId?: string | null,
+): Promise<void> =>
   apiFetch<unknown>(`/api/projects/${id}`, {
     method: 'PATCH',
     body: { positionX: x, positionY: y },
+    query: { calendarId },
   }).then(() => undefined)
 
-export const moveActivity = (id: string, x: number, y: number): Promise<void> =>
+export const moveActivity = (
+  id: string,
+  x: number,
+  y: number,
+  calendarId?: string | null,
+): Promise<void> =>
   apiFetch<unknown>(`/api/activities/${id}`, {
     method: 'PATCH',
     body: { positionX: x, positionY: y },
+    query: { calendarId },
   }).then(() => undefined)
 
 // Persist a base pyramid node's position to its mindmap_nodes override (PUT upserts the row).
-export const moveNode = (id: string, x: number, y: number): Promise<void> =>
+export const moveNode = (
+  id: string,
+  x: number,
+  y: number,
+  calendarId?: string | null,
+): Promise<void> =>
   apiFetch<unknown>(`/api/mindmap-nodes/${id}`, {
     method: 'PUT',
     body: { positionX: x, positionY: y },
+    query: { calendarId },
   }).then(() => undefined)
 
 // Persist a node's resized dimensions to its mindmap_nodes override. The PUT partial-merges and
 // upserts a row for ANY node id — base (`life-goal`), project (`project-<id>`), or activity
 // (`activity-<id>`) — since the xyflow node id is itself the mindmap_nodes key. The saved size reads
 // back on the next /api/mindmap/init (init.nodes). Fire-and-forget from the resize handler.
-export const saveNodeSize = (id: string, width: number, height: number): Promise<void> =>
+export const saveNodeSize = (
+  id: string,
+  width: number,
+  height: number,
+  calendarId?: string | null,
+): Promise<void> =>
   apiFetch<unknown>(`/api/mindmap-nodes/${id}`, {
     method: 'PUT',
     body: { width, height },
+    query: { calendarId },
   }).then(() => undefined)
 
 // Persist a base node's editable attributes (label/description/colour/icon) to its mindmap_nodes
@@ -46,29 +74,39 @@ export const updateNode = (
     customColor?: string | null
     nodeData?: Record<string, unknown>
   },
+  calendarId?: string | null,
 ): Promise<void> =>
-  apiFetch<unknown>(`/api/mindmap-nodes/${id}`, { method: 'PUT', body: patch }).then(
-    () => undefined,
-  )
+  apiFetch<unknown>(`/api/mindmap-nodes/${id}`, {
+    method: 'PUT',
+    body: patch,
+    query: { calendarId },
+  }).then(() => undefined)
 
 export const createProject = (
   name: string,
   projectType: 'mission' | 'provision',
   parentType?: string,
+  calendarId?: string | null,
 ): Promise<void> =>
   apiFetch<unknown>('/api/projects', {
     method: 'POST',
     // parent_type files the project under a pyramid pillar (a base-node id); omitted for a plain
     // branch project created from the toolbar.
     body: { name, projectType, ...(parentType ? { parentType } : {}) },
+    query: { calendarId },
   }).then(() => undefined)
 
 // A product is a project nested under another project (parentProjectId); it inherits type/sphere/
 // colour from its parent on the server, so only the name is needed here.
-export const createProduct = (name: string, parentProjectId: string): Promise<void> =>
+export const createProduct = (
+  name: string,
+  parentProjectId: string,
+  calendarId?: string | null,
+): Promise<void> =>
   apiFetch<unknown>('/api/projects', {
     method: 'POST',
     body: { name, parentProjectId },
+    query: { calendarId },
   }).then(() => undefined)
 
 // An activity (leaf) hangs off either a project or a product (both are projects.id) — the parent
@@ -76,29 +114,45 @@ export const createProduct = (name: string, parentProjectId: string): Promise<vo
 export const createActivity = (
   name: string,
   parent: { projectId: string } | { productId: string },
+  calendarId?: string | null,
 ): Promise<void> =>
-  apiFetch<unknown>('/api/activities', { method: 'POST', body: { name, ...parent } }).then(
-    () => undefined,
-  )
+  apiFetch<unknown>('/api/activities', {
+    method: 'POST',
+    body: { name, ...parent },
+    query: { calendarId },
+  }).then(() => undefined)
 
 export const updateProject = (
   id: string,
   name: string,
   color: string,
   parentProjectId: string | null,
+  calendarId?: string | null,
 ): Promise<void> =>
   apiFetch<unknown>(`/api/projects/${id}`, {
     method: 'PATCH',
     body: { name, color, parentProjectId },
+    query: { calendarId },
   }).then(() => undefined)
 
-export const updateActivity = (id: string, name: string, color: string): Promise<void> =>
-  apiFetch<unknown>(`/api/activities/${id}`, { method: 'PATCH', body: { name, color } }).then(
+export const updateActivity = (
+  id: string,
+  name: string,
+  color: string,
+  calendarId?: string | null,
+): Promise<void> =>
+  apiFetch<unknown>(`/api/activities/${id}`, {
+    method: 'PATCH',
+    body: { name, color },
+    query: { calendarId },
+  }).then(() => undefined)
+
+export const deleteProject = (id: string, calendarId?: string | null): Promise<void> =>
+  apiFetch<unknown>(`/api/projects/${id}`, { method: 'DELETE', query: { calendarId } }).then(
     () => undefined,
   )
 
-export const deleteProject = (id: string): Promise<void> =>
-  apiFetch<unknown>(`/api/projects/${id}`, { method: 'DELETE' }).then(() => undefined)
-
-export const deleteActivity = (id: string): Promise<void> =>
-  apiFetch<unknown>(`/api/activities/${id}`, { method: 'DELETE' }).then(() => undefined)
+export const deleteActivity = (id: string, calendarId?: string | null): Promise<void> =>
+  apiFetch<unknown>(`/api/activities/${id}`, { method: 'DELETE', query: { calendarId } }).then(
+    () => undefined,
+  )
diff --git a/apps/focal/client/src/api/openapi.d.ts b/apps/focal/client/src/api/openapi.d.ts
index 4196fe6..b4901e8 100644
--- a/apps/focal/client/src/api/openapi.d.ts
+++ b/apps/focal/client/src/api/openapi.d.ts
@@ -5182,7 +5182,9 @@ export interface operations {
     };
     list_tags_api_tags_get: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -5214,7 +5216,9 @@ export interface operations {
     };
     create_tag_api_tags_post: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -5250,7 +5254,9 @@ export interface operations {
     };
     delete_tag_api_tags__tag_id__delete: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -5286,7 +5292,9 @@ export interface operations {
     };
     update_tag_api_tags__tag_id__patch: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -5324,7 +5332,9 @@ export interface operations {
     };
     list_spheres_api_spheres_get: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -5356,7 +5366,9 @@ export interface operations {
     };
     create_sphere_api_spheres_post: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -5392,7 +5404,9 @@ export interface operations {
     };
     get_sphere_api_spheres__sphere_id__get: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -5426,7 +5440,9 @@ export interface operations {
     };
     delete_sphere_api_spheres__sphere_id__delete: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -5462,7 +5478,9 @@ export interface operations {
     };
     update_sphere_api_spheres__sphere_id__patch: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -5500,7 +5518,9 @@ export interface operations {
     };
     list_projects_api_projects_get: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -5532,7 +5552,9 @@ export interface operations {
     };
     create_project_api_projects_post: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -5568,7 +5590,9 @@ export interface operations {
     };
     list_root_projects_api_projects_root_get: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -5600,7 +5624,9 @@ export interface operations {
     };
     get_project_api_projects__project_id__get: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -5634,7 +5660,9 @@ export interface operations {
     };
     delete_project_api_projects__project_id__delete: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -5670,7 +5698,9 @@ export interface operations {
     };
     update_project_api_projects__project_id__patch: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -5708,7 +5738,9 @@ export interface operations {
     };
     list_products_api_projects__project_id__products_get: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -5742,7 +5774,9 @@ export interface operations {
     };
     list_goals_api_goals_get: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -5774,7 +5808,9 @@ export interface operations {
     };
     create_goal_api_goals_post: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -5810,7 +5846,9 @@ export interface operations {
     };
     get_goal_api_goals__goal_id__get: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -5844,7 +5882,9 @@ export interface operations {
     };
     delete_goal_api_goals__goal_id__delete: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -5880,7 +5920,9 @@ export interface operations {
     };
     update_goal_api_goals__goal_id__patch: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -5918,7 +5960,9 @@ export interface operations {
     };
     list_activities_api_activities_get: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -5950,7 +5994,9 @@ export interface operations {
     };
     create_activity_api_activities_post: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -5986,7 +6032,9 @@ export interface operations {
     };
     get_activity_api_activities__activity_id__get: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -6020,7 +6068,9 @@ export interface operations {
     };
     delete_activity_api_activities__activity_id__delete: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -6056,7 +6106,9 @@ export interface operations {
     };
     update_activity_api_activities__activity_id__patch: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -6096,6 +6148,7 @@ export interface operations {
         parameters: {
             query: {
                 activityId: string;
+                calendarId?: string | null;
             };
             header?: {
                 authorization?: string | null;
@@ -6128,7 +6181,9 @@ export interface operations {
     };
     create_activity_instance_api_activity_instances_post: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -6164,7 +6219,9 @@ export interface operations {
     };
     sync_activity_instances_api_activity_instances_sync_post: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -6200,7 +6257,9 @@ export interface operations {
     };
     get_activity_instance_api_activity_instances__instance_id__get: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -6234,7 +6293,9 @@ export interface operations {
     };
     delete_activity_instance_api_activity_instances__instance_id__delete: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -6270,7 +6331,9 @@ export interface operations {
     };
     update_activity_instance_api_activity_instances__instance_id__patch: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -6311,6 +6374,7 @@ export interface operations {
             query?: {
                 startDate?: string | null;
                 endDate?: string | null;
+                calendarId?: string | null;
             };
             header?: {
                 authorization?: string | null;
@@ -6343,7 +6407,9 @@ export interface operations {
     };
     create_task_api_tasks_post: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -6379,7 +6445,9 @@ export interface operations {
     };
     get_task_api_tasks__task_id__get: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -6413,7 +6481,9 @@ export interface operations {
     };
     delete_task_api_tasks__task_id__delete: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -6449,7 +6519,9 @@ export interface operations {
     };
     update_task_api_tasks__task_id__patch: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -6487,7 +6559,9 @@ export interface operations {
     };
     mindmap_init_api_mindmap_init_get: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -6519,7 +6593,9 @@ export interface operations {
     };
     list_nodes_api_mindmap_nodes_get: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -6551,7 +6627,9 @@ export interface operations {
     };
     batch_nodes_api_mindmap_nodes_batch_post: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -6587,7 +6665,9 @@ export interface operations {
     };
     get_node_api_mindmap_nodes__node_id__get: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -6621,7 +6701,9 @@ export interface operations {
     };
     upsert_node_api_mindmap_nodes__node_id__put: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -6659,7 +6741,9 @@ export interface operations {
     };
     delete_node_api_mindmap_nodes__node_id__delete: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -6691,7 +6775,9 @@ export interface operations {
     };
     list_edges_api_mindmap_edges_get: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -6723,7 +6809,9 @@ export interface operations {
     };
     upsert_edge_api_mindmap_edges__edge_id__put: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -6761,7 +6849,9 @@ export interface operations {
     };
     delete_edge_api_mindmap_edges__edge_id__delete: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -6796,6 +6886,7 @@ export interface operations {
             query?: {
                 startDate?: string | null;
                 endDate?: string | null;
+                calendarId?: string | null;
             };
             header?: {
                 authorization?: string | null;
@@ -6828,7 +6919,9 @@ export interface operations {
     };
     create_event_api_events_post: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -6864,7 +6957,9 @@ export interface operations {
     };
     get_event_api_events__event_id__get: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -6901,6 +6996,7 @@ export interface operations {
             query?: {
                 recurrenceScope?: string | null;
                 occurrenceDate?: string | null;
+                calendarId?: string | null;
             };
             header?: {
                 authorization?: string | null;
@@ -6936,6 +7032,7 @@ export interface operations {
             query?: {
                 recurrenceScope?: string | null;
                 occurrenceDate?: string | null;
+                calendarId?: string | null;
             };
             header?: {
                 authorization?: string | null;
@@ -6977,6 +7074,7 @@ export interface operations {
             query?: {
                 startDate?: string | null;
                 endDate?: string | null;
+                calendarId?: string | null;
             };
             header?: {
                 authorization?: string | null;
@@ -7012,6 +7110,7 @@ export interface operations {
             query?: {
                 startDate?: string | null;
                 endDate?: string | null;
+                calendarId?: string | null;
             };
             header?: {
                 authorization?: string | null;
@@ -7044,7 +7143,9 @@ export interface operations {
     };
     create_booking_api_bookings_post: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -7080,7 +7181,9 @@ export interface operations {
     };
     get_booking_api_bookings__booking_id__get: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -7114,7 +7217,9 @@ export interface operations {
     };
     delete_booking_api_bookings__booking_id__delete: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -7146,7 +7251,9 @@ export interface operations {
     };
     update_booking_api_bookings__booking_id__patch: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -7709,6 +7816,7 @@ export interface operations {
         parameters: {
             query?: {
                 status?: string | null;
+                calendarId?: string | null;
             };
             header?: {
                 authorization?: string | null;
@@ -7741,7 +7849,9 @@ export interface operations {
     };
     meeting_requests_count_api_meeting_requests_count_get: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -7775,7 +7885,9 @@ export interface operations {
     };
     get_meeting_request_api_meeting_requests__request_id__get: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -7809,7 +7921,9 @@ export interface operations {
     };
     delete_meeting_request_api_meeting_requests__request_id__delete: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -7841,7 +7955,9 @@ export interface operations {
     };
     accept_meeting_request_api_meeting_requests__request_id__accept_post: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -7875,7 +7991,9 @@ export interface operations {
     };
     decline_meeting_request_api_meeting_requests__request_id__decline_post: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -7909,7 +8027,9 @@ export interface operations {
     };
     tentative_meeting_request_api_meeting_requests__request_id__tentative_post: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -7943,7 +8063,9 @@ export interface operations {
     };
     accept_meeting_reschedule_api_meeting_requests__request_id__accept_reschedule_post: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -7977,7 +8099,9 @@ export interface operations {
     };
     decline_meeting_reschedule_api_meeting_requests__request_id__decline_reschedule_post: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -8013,6 +8137,7 @@ export interface operations {
         parameters: {
             query?: {
                 archived?: boolean;
+                calendarId?: string | null;
             };
             header?: {
                 authorization?: string | null;
@@ -8045,7 +8170,9 @@ export interface operations {
     };
     create_habit_api_habits_post: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -8081,7 +8208,9 @@ export interface operations {
     };
     reorder_habits_api_habits_reorder_post: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -8117,6 +8246,7 @@ export interface operations {
         parameters: {
             query: {
                 today: string;
+                calendarId?: string | null;
             };
             header?: {
                 authorization?: string | null;
@@ -8149,7 +8279,9 @@ export interface operations {
     };
     get_habit_api_habits__habit_id__get: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -8183,7 +8315,9 @@ export interface operations {
     };
     delete_habit_api_habits__habit_id__delete: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -8215,7 +8349,9 @@ export interface operations {
     };
     update_habit_api_habits__habit_id__patch: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -8253,7 +8389,9 @@ export interface operations {
     };
     restore_habit_api_habits__habit_id__restore_post: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -8290,6 +8428,7 @@ export interface operations {
             query: {
                 start: string;
                 end: string;
+                calendarId?: string | null;
             };
             header?: {
                 authorization?: string | null;
@@ -8322,7 +8461,9 @@ export interface operations {
     };
     upsert_habit_entry_api_habit_entries_post: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -8361,6 +8502,7 @@ export interface operations {
             query: {
                 habitId: string;
                 date: string;
+                calendarId?: string | null;
             };
             header?: {
                 authorization?: string | null;
@@ -8395,6 +8537,7 @@ export interface operations {
                 start: string;
                 end: string;
                 granularity?: "day" | "month";
+                calendarId?: string | null;
             };
             header?: {
                 authorization?: string | null;
@@ -8427,7 +8570,9 @@ export interface operations {
     };
     get_time_budget_year_api_time_budgets__year__get: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -8461,7 +8606,9 @@ export interface operations {
     };
     update_time_budget_settings_api_time_budgets_settings__settings_id__patch: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -8499,7 +8646,9 @@ export interface operations {
     };
     create_category_api_time_budgets_categories_post: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -8535,7 +8684,9 @@ export interface operations {
     };
     delete_category_api_time_budgets_categories__category_id__delete: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -8567,7 +8718,9 @@ export interface operations {
     };
     update_category_api_time_budgets_categories__category_id__patch: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -8605,7 +8758,9 @@ export interface operations {
     };
     create_subcategory_api_time_budgets_subcategories_post: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -8641,7 +8796,9 @@ export interface operations {
     };
     delete_subcategory_api_time_budgets_subcategories__subcategory_id__delete: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -8673,7 +8830,9 @@ export interface operations {
     };
     update_subcategory_api_time_budgets_subcategories__subcategory_id__patch: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -8711,7 +8870,9 @@ export interface operations {
     };
     create_item_api_time_budgets_items_post: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -8747,7 +8908,9 @@ export interface operations {
     };
     delete_item_api_time_budgets_items__item_id__delete: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -8779,7 +8942,9 @@ export interface operations {
     };
     update_item_api_time_budgets_items__item_id__patch: {
         parameters: {
-            query?: never;
+            query?: {
+                calendarId?: string | null;
+            };
             header?: {
                 authorization?: string | null;
                 "x-demo-user-id"?: string | null;
@@ -8820,6 +8985,7 @@ export interface operations {
             query: {
                 periodStart: string;
                 periodEnd: string;
+                calendarId?: string | null;
             };
             header?: {
                 authorization?: string | null;
@@ -8855,6 +9021,7 @@ export interface operations {
             query?: {
                 startDate?: string | null;
                 endDate?: string | null;
+                calendarId?: string | null;
             };
             header?: {
                 authorization?: string | null;
diff --git a/apps/focal/client/src/api/products.ts b/apps/focal/client/src/api/products.ts
index f8dc64d..7831c83 100644
--- a/apps/focal/client/src/api/products.ts
+++ b/apps/focal/client/src/api/products.ts
@@ -4,5 +4,7 @@ import { apiFetch, type ResponseOf } from './client'
 // they share the ProjectRead shape returned by the products endpoint.
 export type Product = ResponseOf<'/api/projects/{project_id}/products', 'get'>[number]
 
-export const listProducts = (projectId: string): Promise<Product[]> =>
-  apiFetch<Product[]>(`/api/projects/${projectId}/products`)
+// `calendarId` (the active shared-calendar selection; null = own data) scopes the call to that
+// calendar's owner server-side; `buildUrl` drops it when null/undefined.
+export const listProducts = (projectId: string, calendarId?: string | null): Promise<Product[]> =>
+  apiFetch<Product[]>(`/api/projects/${projectId}/products`, { query: { calendarId } })
diff --git a/apps/focal/client/src/api/projects.ts b/apps/focal/client/src/api/projects.ts
index 4cfe793..23bf9c7 100644
--- a/apps/focal/client/src/api/projects.ts
+++ b/apps/focal/client/src/api/projects.ts
@@ -5,13 +5,23 @@ export type Project = ResponseOf<'/api/projects', 'get'>[number]
 export type ProjectCreate = Schemas['ProjectCreate']
 export type ProjectUpdate = Schemas['ProjectUpdate']
 
-export const listProjects = (): Promise<Project[]> => apiFetch<Project[]>('/api/projects')
+// `calendarId` (the active shared-calendar selection; null = own data) scopes the call to that
+// calendar's owner server-side.
+export const listProjects = (calendarId?: string | null): Promise<Project[]> =>
+  apiFetch<Project[]>('/api/projects', { query: { calendarId } })
 
-export const createProject = (input: ProjectCreate): Promise<Project> =>
-  apiFetch<Project>('/api/projects', { method: 'POST', body: input })
+export const createProject = (input: ProjectCreate, calendarId?: string | null): Promise<Project> =>
+  apiFetch<Project>('/api/projects', { method: 'POST', body: input, query: { calendarId } })
 
-export const updateProject = (id: string, patch: ProjectUpdate): Promise<Project> =>
-  apiFetch<Project>(`/api/projects/${id}`, { method: 'PATCH', body: patch })
+export const updateProject = (
+  id: string,
+  patch: ProjectUpdate,
+  calendarId?: string | null,
+): Promise<Project> =>
+  apiFetch<Project>(`/api/projects/${id}`, { method: 'PATCH', body: patch, query: { calendarId } })
 
-export const deleteProject = (id: string): Promise<void> =>
-  apiFetch<{ success: boolean }>(`/api/projects/${id}`, { method: 'DELETE' }).then(() => undefined)
+export const deleteProject = (id: string, calendarId?: string | null): Promise<void> =>
+  apiFetch<{ success: boolean }>(`/api/projects/${id}`, {
+    method: 'DELETE',
+    query: { calendarId },
+  }).then(() => undefined)
diff --git a/apps/focal/client/src/api/queryKeys.ts b/apps/focal/client/src/api/queryKeys.ts
new file mode 100644
index 0000000..ea22d92
--- /dev/null
+++ b/apps/focal/client/src/api/queryKeys.ts
@@ -0,0 +1,16 @@
+/**
+ * Append the active shared-calendar scope to a React Query key.
+ *
+ * A shared calendar selection (`currentCalendarId` from `useCalendarFilter`) must make every
+ * calendar-scoped query refetch the OWNER's data instead of serving the viewer's cached own-data —
+ * React Query treats a changed key as a new cache entry, so appending the scope does exactly that.
+ *
+ * `null` (the user's own / main calendar) returns the key UNCHANGED, so:
+ * - own-data cache entries stay byte-identical to before this slice,
+ * - base-tag prefix invalidations keep matching (`['events']` is still a prefix of
+ *   `['events', start, end, 'cal', id]`), so a single `invalidateQueries({ queryKey: ['events'] })`
+ *   still clears every calendar + window variant,
+ * - existing tests that assert the bare key (e.g. `{ queryKey: ['events'] }`) keep passing.
+ */
+export const withCal = (key: readonly unknown[], calendarId: string | null): readonly unknown[] =>
+  calendarId ? [...key, 'cal', calendarId] : key
diff --git a/apps/focal/client/src/api/spheres.ts b/apps/focal/client/src/api/spheres.ts
index c6de5ce..f77c0ad 100644
--- a/apps/focal/client/src/api/spheres.ts
+++ b/apps/focal/client/src/api/spheres.ts
@@ -6,13 +6,23 @@ export type Sphere = Schemas['SphereRead']
 export type SphereCreate = Schemas['SphereCreate']
 export type SphereUpdate = Schemas['SphereUpdate']
 
-export const listSpheres = (): Promise<Sphere[]> => apiFetch<Sphere[]>('/api/spheres')
+// `calendarId` (the active shared-calendar selection; null = own data) scopes the call to that
+// calendar's owner server-side.
+export const listSpheres = (calendarId?: string | null): Promise<Sphere[]> =>
+  apiFetch<Sphere[]>('/api/spheres', { query: { calendarId } })
 
-export const createSphere = (input: SphereCreate): Promise<Sphere> =>
-  apiFetch<Sphere>('/api/spheres', { method: 'POST', body: input })
+export const createSphere = (input: SphereCreate, calendarId?: string | null): Promise<Sphere> =>
+  apiFetch<Sphere>('/api/spheres', { method: 'POST', body: input, query: { calendarId } })
 
-export const updateSphere = (id: string, patch: SphereUpdate): Promise<Sphere> =>
-  apiFetch<Sphere>(`/api/spheres/${id}`, { method: 'PATCH', body: patch })
+export const updateSphere = (
+  id: string,
+  patch: SphereUpdate,
+  calendarId?: string | null,
+): Promise<Sphere> =>
+  apiFetch<Sphere>(`/api/spheres/${id}`, { method: 'PATCH', body: patch, query: { calendarId } })
 
-export const deleteSphere = (id: string): Promise<void> =>
-  apiFetch<{ success: boolean }>(`/api/spheres/${id}`, { method: 'DELETE' }).then(() => undefined)
+export const deleteSphere = (id: string, calendarId?: string | null): Promise<void> =>
+  apiFetch<{ success: boolean }>(`/api/spheres/${id}`, {
+    method: 'DELETE',
+    query: { calendarId },
+  }).then(() => undefined)
diff --git a/apps/focal/client/src/api/tags.ts b/apps/focal/client/src/api/tags.ts
index 95a9c38..db5e14b 100644
--- a/apps/focal/client/src/api/tags.ts
+++ b/apps/focal/client/src/api/tags.ts
@@ -6,13 +6,19 @@ export type Tag = Schemas['TagRead']
 export type TagCreate = Schemas['TagCreate']
 export type TagUpdate = Schemas['TagUpdate']
 
-export const listTags = (): Promise<Tag[]> => apiFetch<Tag[]>('/api/tags')
+// `calendarId` (the active shared-calendar selection; null = own data) scopes the call to that
+// calendar's owner server-side.
+export const listTags = (calendarId?: string | null): Promise<Tag[]> =>
+  apiFetch<Tag[]>('/api/tags', { query: { calendarId } })
 
-export const createTag = (input: TagCreate): Promise<Tag> =>
-  apiFetch<Tag>('/api/tags', { method: 'POST', body: input })
+export const createTag = (input: TagCreate, calendarId?: string | null): Promise<Tag> =>
+  apiFetch<Tag>('/api/tags', { method: 'POST', body: input, query: { calendarId } })
 
-export const updateTag = (id: string, patch: TagUpdate): Promise<Tag> =>
-  apiFetch<Tag>(`/api/tags/${id}`, { method: 'PATCH', body: patch })
+export const updateTag = (id: string, patch: TagUpdate, calendarId?: string | null): Promise<Tag> =>
+  apiFetch<Tag>(`/api/tags/${id}`, { method: 'PATCH', body: patch, query: { calendarId } })
 
-export const deleteTag = (id: string): Promise<void> =>
-  apiFetch<{ success: boolean }>(`/api/tags/${id}`, { method: 'DELETE' }).then(() => undefined)
+export const deleteTag = (id: string, calendarId?: string | null): Promise<void> =>
+  apiFetch<{ success: boolean }>(`/api/tags/${id}`, {
+    method: 'DELETE',
+    query: { calendarId },
+  }).then(() => undefined)
diff --git a/apps/focal/client/src/api/tasks.ts b/apps/focal/client/src/api/tasks.ts
index a46bb1f..fc33150 100644
--- a/apps/focal/client/src/api/tasks.ts
+++ b/apps/focal/client/src/api/tasks.ts
@@ -12,16 +12,39 @@ export interface TaskListParams {
 
 // The list is date-windowed server-side (default: the current calendar month plus
 // undated tasks); pass an explicit range to widen it.
-export const listTasks = (params: TaskListParams = {}): Promise<Task[]> =>
+// `calendarId` (the active shared-calendar selection; null = own data) scopes the call to that
+// calendar's owner server-side.
+export const listTasks = (
+  params: TaskListParams = {},
+  calendarId?: string | null,
+): Promise<Task[]> =>
   apiFetch<Task[]>('/api/tasks', {
-    query: { startDate: params.startDate, endDate: params.endDate },
+    query: { startDate: params.startDate, endDate: params.endDate, calendarId },
   })
 
-export const createTask = (input: TaskCreate): Promise<Schemas['TaskRead']> =>
-  apiFetch<Schemas['TaskRead']>('/api/tasks', { method: 'POST', body: input })
+export const createTask = (
+  input: TaskCreate,
+  calendarId?: string | null,
+): Promise<Schemas['TaskRead']> =>
+  apiFetch<Schemas['TaskRead']>('/api/tasks', {
+    method: 'POST',
+    body: input,
+    query: { calendarId },
+  })
 
-export const updateTask = (id: string, patch: TaskUpdate): Promise<Schemas['TaskRead']> =>
-  apiFetch<Schemas['TaskRead']>(`/api/tasks/${id}`, { method: 'PATCH', body: patch })
+export const updateTask = (
+  id: string,
+  patch: TaskUpdate,
+  calendarId?: string | null,
+): Promise<Schemas['TaskRead']> =>
+  apiFetch<Schemas['TaskRead']>(`/api/tasks/${id}`, {
+    method: 'PATCH',
+    body: patch,
+    query: { calendarId },
+  })
 
-export const deleteTask = (id: string): Promise<void> =>
-  apiFetch<{ success: boolean }>(`/api/tasks/${id}`, { method: 'DELETE' }).then(() => undefined)
+export const deleteTask = (id: string, calendarId?: string | null): Promise<void> =>
+  apiFetch<{ success: boolean }>(`/api/tasks/${id}`, {
+    method: 'DELETE',
+    query: { calendarId },
+  }).then(() => undefined)
diff --git a/apps/focal/client/src/api/timeBudgets.ts b/apps/focal/client/src/api/timeBudgets.ts
index 4d385f5..9e4f8e5 100644
--- a/apps/focal/client/src/api/timeBudgets.ts
+++ b/apps/focal/client/src/api/timeBudgets.ts
@@ -12,44 +12,71 @@ export type CategoryCreate = Schemas['TimeBudgetCategoryCreate']
 export type SubcategoryCreate = Schemas['TimeBudgetSubcategoryCreate']
 export type ItemCreate = Schemas['TimeBudgetItemCreate']
 
-export const getBudgetYear = (year: number): Promise<BudgetYear> =>
-  apiFetch<BudgetYear>(`/api/time-budgets/${year}`)
+// `calendarId` (the active shared-calendar selection; null = own data) scopes the call to that
+// calendar owner's data server-side. `buildUrl` drops null/undefined query values, so passing it
+// straight through is a no-op when absent.
+export const getBudgetYear = (year: number, calendarId?: string | null): Promise<BudgetYear> =>
+  apiFetch<BudgetYear>(`/api/time-budgets/${year}`, { query: { calendarId } })
 
 export const updateSettings = (
   settingsId: string,
   patch: BudgetSettingsUpdate,
+  calendarId?: string | null,
 ): Promise<BudgetSettings> =>
   apiFetch<BudgetSettings>(`/api/time-budgets/settings/${settingsId}`, {
     method: 'PATCH',
     body: patch,
+    query: { calendarId },
   })
 
-export const createCategory = (input: CategoryCreate): Promise<Schemas['TimeBudgetCategoryRead']> =>
-  apiFetch(`/api/time-budgets/categories`, { method: 'POST', body: input })
+export const createCategory = (
+  input: CategoryCreate,
+  calendarId?: string | null,
+): Promise<Schemas['TimeBudgetCategoryRead']> =>
+  apiFetch(`/api/time-budgets/categories`, { method: 'POST', body: input, query: { calendarId } })
 
-export const deleteCategory = (id: string): Promise<void> =>
-  apiFetch<undefined>(`/api/time-budgets/categories/${id}`, { method: 'DELETE' }).then(
-    () => undefined,
-  )
+export const deleteCategory = (id: string, calendarId?: string | null): Promise<void> =>
+  apiFetch<undefined>(`/api/time-budgets/categories/${id}`, {
+    method: 'DELETE',
+    query: { calendarId },
+  }).then(() => undefined)
 
 export const createSubcategory = (
   input: SubcategoryCreate,
+  calendarId?: string | null,
 ): Promise<Schemas['TimeBudgetSubcategoryRead']> =>
-  apiFetch(`/api/time-budgets/subcategories`, { method: 'POST', body: input })
+  apiFetch(`/api/time-budgets/subcategories`, {
+    method: 'POST',
+    body: input,
+    query: { calendarId },
+  })
 
-export const deleteSubcategory = (id: string): Promise<void> =>
-  apiFetch<undefined>(`/api/time-budgets/subcategories/${id}`, { method: 'DELETE' }).then(
-    () => undefined,
-  )
+export const deleteSubcategory = (id: string, calendarId?: string | null): Promise<void> =>
+  apiFetch<undefined>(`/api/time-budgets/subcategories/${id}`, {
+    method: 'DELETE',
+    query: { calendarId },
+  }).then(() => undefined)
 
-export const createItem = (input: ItemCreate): Promise<BudgetItem> =>
-  apiFetch<BudgetItem>(`/api/time-budgets/items`, { method: 'POST', body: input })
+export const createItem = (input: ItemCreate, calendarId?: string | null): Promise<BudgetItem> =>
+  apiFetch<BudgetItem>(`/api/time-budgets/items`, {
+    method: 'POST',
+    body: input,
+    query: { calendarId },
+  })
 
 export const updateItem = (
   id: string,
   patch: Schemas['TimeBudgetItemUpdate'],
+  calendarId?: string | null,
 ): Promise<BudgetItem> =>
-  apiFetch<BudgetItem>(`/api/time-budgets/items/${id}`, { method: 'PATCH', body: patch })
+  apiFetch<BudgetItem>(`/api/time-budgets/items/${id}`, {
+    method: 'PATCH',
+    body: patch,
+    query: { calendarId },
+  })
 
-export const deleteItem = (id: string): Promise<void> =>
-  apiFetch<undefined>(`/api/time-budgets/items/${id}`, { method: 'DELETE' }).then(() => undefined)
+export const deleteItem = (id: string, calendarId?: string | null): Promise<void> =>
+  apiFetch<undefined>(`/api/time-budgets/items/${id}`, {
+    method: 'DELETE',
+    query: { calendarId },
+  }).then(() => undefined)
diff --git a/apps/focal/client/src/components/AppShell.test.tsx b/apps/focal/client/src/components/AppShell.test.tsx
index f6668b5..5b9a625 100644
--- a/apps/focal/client/src/components/AppShell.test.tsx
+++ b/apps/focal/client/src/components/AppShell.test.tsx
@@ -10,7 +10,7 @@ import { AppShell } from './AppShell'
 const { signOut, getMe, apiFetch } = vi.hoisted(() => ({
   signOut: vi.fn<() => void>(),
   getMe: vi.fn<() => Promise<unknown>>(),
-  apiFetch: vi.fn<(path: string) => Promise<{ count: number }>>(),
+  apiFetch: vi.fn<(path: string, opts?: unknown) => Promise<{ count: number }>>(),
 }))
 vi.mock('../features/auth', () => ({
   useAuth: () => ({ user: { email: 'user@example.com' }, signOut }),
@@ -145,7 +145,11 @@ describe('AppShell', () => {
     const label = screen.getByText(i18n.t('focal.app.nav.meetingRequests'))
     const link = label.closest('a')
     expect(link).not.toBeNull()
-    await waitFor(() => expect(apiFetch).toHaveBeenCalledWith('/api/meeting-requests/count'))
+    await waitFor(() =>
+      expect(apiFetch).toHaveBeenCalledWith('/api/meeting-requests/count', {
+        query: { calendarId: null },
+      }),
+    )
     expect(link).not.toHaveTextContent(/\b0\b/)
   })
 
@@ -156,7 +160,11 @@ describe('AppShell', () => {
     const label = screen.getByText(i18n.t('focal.app.nav.meetingRequests'))
     const link = label.closest('a')
     expect(link).not.toBeNull()
-    await waitFor(() => expect(apiFetch).toHaveBeenCalledWith('/api/meeting-requests/count'))
+    await waitFor(() =>
+      expect(apiFetch).toHaveBeenCalledWith('/api/meeting-requests/count', {
+        query: { calendarId: null },
+      }),
+    )
     expect(link).not.toHaveTextContent(/\b\d+\b/)
   })
 
diff --git a/apps/focal/client/src/components/AppSidebar.tsx b/apps/focal/client/src/components/AppSidebar.tsx
index 23bd950..08766f2 100644
--- a/apps/focal/client/src/components/AppSidebar.tsx
+++ b/apps/focal/client/src/components/AppSidebar.tsx
@@ -24,6 +24,7 @@ import { useTranslation } from 'react-i18next'
 import { Link, useLocation } from 'wouter'
 import { apiFetch } from '@/api/client'
 import { getMe } from '@/api/me'
+import { withCal } from '@/api/queryKeys'
 import { CalendarSwitcher } from '@/components/CalendarSwitcher'
 import { Badge } from '@/components/ui/badge'
 import { Button } from '@/components/ui/button'
@@ -119,7 +120,8 @@ export const AppSidebar = () => {
   const [location] = useLocation()
   const { user, signOut } = useAuth()
   const { setOpenMobile, isMobile } = useSidebar()
-  const { canViewOtherPages, currentCalendar, currentCalendarRole } = useCalendarFilter()
+  const { canViewOtherPages, currentCalendar, currentCalendarId, currentCalendarRole } =
+    useCalendarFilter()
   // Viewing a calendar owned by someone else → show the "viewing X" banner.
   const viewingOthersCalendar = !!currentCalendar && currentCalendar.userId !== user?.id
 
@@ -127,8 +129,11 @@ export const AppSidebar = () => {
   const canAccessDashboard = me.data?.canAccessDashboard ?? false
 
   const meetingCount = useQuery({
-    queryKey: ['meeting-requests', 'count'],
-    queryFn: () => apiFetch<{ count: number }>('/api/meeting-requests/count'),
+    queryKey: withCal(['meeting-requests', 'count'], currentCalendarId),
+    queryFn: () =>
+      apiFetch<{ count: number }>('/api/meeting-requests/count', {
+        query: { calendarId: currentCalendarId },
+      }),
     staleTime: 60_000,
     refetchInterval: 60_000,
     retry: false,
diff --git a/apps/focal/client/src/features/analytics/useSpheresAnalyticsData.ts b/apps/focal/client/src/features/analytics/useSpheresAnalyticsData.ts
index 7592324..52721ae 100644
--- a/apps/focal/client/src/features/analytics/useSpheresAnalyticsData.ts
+++ b/apps/focal/client/src/features/analytics/useSpheresAnalyticsData.ts
@@ -2,7 +2,9 @@ import { useQuery } from '@tanstack/react-query'
 
 import { type CalendarEvent, listEvents } from '../../api/events'
 import { listProjects, type Project } from '../../api/projects'
+import { withCal } from '../../api/queryKeys'
 import { listSpheres, type Sphere } from '../../api/spheres'
+import { useCalendarFilter } from '../calendars/CalendarFilterContext'
 import { type PeriodRange, toIsoDate } from './analyticsPeriods'
 
 export interface SpheresAnalyticsData {
@@ -27,29 +29,33 @@ export const useSpheresAnalyticsData = (
   range: PeriodRange,
   anchorYear: number,
 ): SpheresAnalyticsData => {
+  const { currentCalendarId } = useCalendarFilter()
   const periodStart = toIsoDate(range.start)
   const periodEnd = toIsoDate(range.end)
   const yearStart = `${anchorYear}-01-01`
   const yearEnd = `${anchorYear}-12-31`
 
   const periodEventsQuery = useQuery({
-    queryKey: ['analytics', 'spheres', 'events', periodStart, periodEnd],
-    queryFn: () => listEvents(periodStart, periodEnd),
+    queryKey: withCal(
+      ['analytics', 'spheres', 'events', periodStart, periodEnd],
+      currentCalendarId,
+    ),
+    queryFn: () => listEvents(periodStart, periodEnd, currentCalendarId),
   })
 
   const yearEventsQuery = useQuery({
-    queryKey: ['analytics', 'spheres', 'trend-events', anchorYear],
-    queryFn: () => listEvents(yearStart, yearEnd),
+    queryKey: withCal(['analytics', 'spheres', 'trend-events', anchorYear], currentCalendarId),
+    queryFn: () => listEvents(yearStart, yearEnd, currentCalendarId),
   })
 
   const projectsQuery = useQuery({
-    queryKey: ['projects'],
-    queryFn: listProjects,
+    queryKey: withCal(['projects'], currentCalendarId),
+    queryFn: () => listProjects(currentCalendarId),
   })
 
   const spheresQuery = useQuery({
-    queryKey: ['spheres'],
-    queryFn: listSpheres,
+    queryKey: withCal(['spheres'], currentCalendarId),
+    queryFn: () => listSpheres(currentCalendarId),
   })
 
   return {
diff --git a/apps/focal/client/src/features/budgets/TimeBudgetsPage.test.tsx b/apps/focal/client/src/features/budgets/TimeBudgetsPage.test.tsx
index 986cf56..25897fe 100644
--- a/apps/focal/client/src/features/budgets/TimeBudgetsPage.test.tsx
+++ b/apps/focal/client/src/features/budgets/TimeBudgetsPage.test.tsx
@@ -125,7 +125,7 @@ describe('TimeBudgetsPage', () => {
     expect(screen.getByText(i18n.t('focal.budgets.projectsTime'))).toBeInTheDocument()
     expect(screen.getByText(i18n.t('focal.budgets.spheresTime'))).toBeInTheDocument()
     expect(screen.getByText('Health')).toBeInTheDocument()
-    expect(budgets.getBudgetYear).toHaveBeenCalledWith(year)
+    expect(budgets.getBudgetYear).toHaveBeenCalledWith(year, null)
   })
 
   it('navigates between years', async () => {
@@ -134,7 +134,7 @@ describe('TimeBudgetsPage', () => {
 
     await userEvent.click(screen.getByRole('button', { name: i18n.t('focal.budgets.prevYear') }))
 
-    expect(budgets.getBudgetYear).toHaveBeenCalledWith(year - 1)
+    expect(budgets.getBudgetYear).toHaveBeenCalledWith(year - 1, null)
   })
 
   it('saves an edited setting through the settings endpoint', async () => {
@@ -150,7 +150,7 @@ describe('TimeBudgetsPage', () => {
     await userEvent.type(input, '7')
     await userEvent.tab()
 
-    expect(budgets.updateSettings).toHaveBeenCalledWith('s1', { sleepHoursPerDay: 7 })
+    expect(budgets.updateSettings).toHaveBeenCalledWith('s1', { sleepHoursPerDay: 7 }, null)
   })
 
   it('saves edited work-time project hours through the projects endpoint', async () => {
@@ -167,6 +167,6 @@ describe('TimeBudgetsPage', () => {
     await userEvent.type(input, '500')
     await userEvent.tab()
 
-    expect(projects.updateProject).toHaveBeenCalledWith('wp1', { allocatedWorkHours: 500 })
+    expect(projects.updateProject).toHaveBeenCalledWith('wp1', { allocatedWorkHours: 500 }, null)
   })
 })
diff --git a/apps/focal/client/src/features/budgets/TimeBudgetsPage.tsx b/apps/focal/client/src/features/budgets/TimeBudgetsPage.tsx
index 3bb1825..46784ad 100644
--- a/apps/focal/client/src/features/budgets/TimeBudgetsPage.tsx
+++ b/apps/focal/client/src/features/budgets/TimeBudgetsPage.tsx
@@ -29,6 +29,7 @@ import {
   Tooltip,
 } from 'recharts'
 
+import { withCal } from '@/api/queryKeys'
 import { PageHeader } from '@/components/PageHeader'
 import { Button } from '@/components/ui/button'
 import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
@@ -43,6 +44,8 @@ import {
   SelectValue,
 } from '@/components/ui/select'
 
+import { useCalendarFilter } from '@/features/calendars/CalendarFilterContext'
+
 import { type Activity, listActivities, updateActivity } from '../../api/activities'
 import {
   type ActivityInstance,
@@ -200,6 +203,7 @@ interface ProjectItemProps {
   onToggleEnergy: (id: string, givesEnergy: boolean) => void
   energyTitle: (givesEnergy: boolean) => string
   editTitle: string
+  canEdit: boolean
 }
 
 const ProjectItem = ({
@@ -214,6 +218,7 @@ const ProjectItem = ({
   onToggleEnergy,
   energyTitle,
   editTitle,
+  canEdit,
 }: ProjectItemProps): ReactElement => {
   const givesEnergy = project.givesEnergy ?? true
   const projectColor = project.color || DEFAULT_COLOR
@@ -224,7 +229,8 @@ const ProjectItem = ({
         <button
           type="button"
           onClick={() => onToggleEnergy(project.id, !givesEnergy)}
-          className="cursor-pointer hover:scale-110 transition-transform shrink-0"
+          disabled={!canEdit}
+          className="cursor-pointer hover:scale-110 transition-transform shrink-0 disabled:cursor-default disabled:hover:scale-100"
           title={energyTitle(givesEnergy)}
         >
           {givesEnergy ? (
@@ -267,8 +273,9 @@ const ProjectItem = ({
         ) : (
           <button
             type="button"
-            className="inline-flex h-6 min-w-11 items-center justify-center rounded-md border border-primary/30 bg-primary/10 px-2 font-mono text-xs font-semibold tabular-nums text-primary transition-colors hover:border-primary"
+            className="inline-flex h-6 min-w-11 items-center justify-center rounded-md border border-primary/30 bg-primary/10 px-2 font-mono text-xs font-semibold tabular-nums text-primary transition-colors hover:border-primary disabled:cursor-default disabled:opacity-60 disabled:hover:border-primary/30"
             onClick={() => onStartEdit(project.id, project.allocatedWorkHours || 0)}
+            disabled={!canEdit}
             title={editTitle}
           >
             {(project.allocatedWorkHours || 0).toLocaleString()}
@@ -307,6 +314,7 @@ interface SphereItemProps {
   onToggleEnergy: (id: string, givesEnergy: boolean) => void
   energyTitle: (givesEnergy: boolean) => string
   editTitle: string
+  canEdit: boolean
 }
 
 const SphereItem = ({
@@ -327,13 +335,15 @@ const SphereItem = ({
   onToggleEnergy,
   energyTitle,
   editTitle,
+  canEdit,
 }: SphereItemProps): ReactElement => (
   <div className="flex items-center gap-2">
     <div className="flex items-center gap-1.5 min-w-[110px]">
       <button
         type="button"
         onClick={() => onToggleEnergy(category.id, !category.givesEnergy)}
-        className="cursor-pointer hover:scale-110 transition-transform shrink-0"
+        disabled={!canEdit}
+        className="cursor-pointer hover:scale-110 transition-transform shrink-0 disabled:cursor-default disabled:hover:scale-100"
         title={energyTitle(category.givesEnergy)}
       >
         {category.givesEnergy ? (
@@ -357,8 +367,9 @@ const SphereItem = ({
       ) : (
         <button
           type="button"
-          className="text-xs font-medium cursor-pointer hover:bg-muted px-1 rounded transition-colors truncate"
+          className="text-xs font-medium cursor-pointer hover:bg-muted px-1 rounded transition-colors truncate disabled:cursor-default disabled:hover:bg-transparent"
           onClick={() => onStartEditName(category.id, category.name)}
+          disabled={!canEdit}
           title={editTitle}
         >
           {category.name}
@@ -391,8 +402,9 @@ const SphereItem = ({
       ) : (
         <button
           type="button"
-          className="inline-flex h-6 min-w-11 items-center justify-center rounded-md border border-primary/30 bg-primary/10 px-2 font-mono text-xs font-semibold tabular-nums text-primary transition-colors hover:border-primary"
+          className="inline-flex h-6 min-w-11 items-center justify-center rounded-md border border-primary/30 bg-primary/10 px-2 font-mono text-xs font-semibold tabular-nums text-primary transition-colors hover:border-primary disabled:cursor-default disabled:opacity-60 disabled:hover:border-primary/30"
           onClick={() => onStartEdit(category.id, category.allocatedHours)}
+          disabled={!canEdit}
           title={editTitle}
         >
           {category.allocatedHours.toLocaleString()}
@@ -417,6 +429,7 @@ interface ProductHoursRowProps {
   onToggleEnergy: (id: string, givesEnergy: boolean) => void
   energyTitle: (givesEnergy: boolean) => string
   editTitle: string
+  canEdit: boolean
 }
 
 const ProductHoursRow = ({
@@ -426,6 +439,7 @@ const ProductHoursRow = ({
   onToggleEnergy,
   energyTitle,
   editTitle,
+  canEdit,
 }: ProductHoursRowProps): ReactElement => {
   const [isEditing, setIsEditing] = useState(false)
   const [hours, setHours] = useState(product.allocatedWorkHours || 0)
@@ -433,6 +447,7 @@ const ProductHoursRow = ({
   const productColor = product.color || DEFAULT_COLOR
 
   const handleSave = () => {
+    if (!canEdit) return
     onUpdate(hours)
     setIsEditing(false)
   }
@@ -443,7 +458,8 @@ const ProductHoursRow = ({
         <button
           type="button"
           onClick={() => onToggleEnergy(product.id, !givesEnergy)}
-          className="cursor-pointer hover:scale-110 transition-transform shrink-0"
+          disabled={!canEdit}
+          className="cursor-pointer hover:scale-110 transition-transform shrink-0 disabled:cursor-default disabled:hover:scale-100"
           title={energyTitle(givesEnergy)}
         >
           {givesEnergy ? (
@@ -489,8 +505,9 @@ const ProductHoursRow = ({
         ) : (
           <button
             type="button"
-            className="inline-flex h-6 min-w-11 items-center justify-center rounded-md border border-primary/30 bg-primary/10 px-2 font-mono text-xs font-semibold tabular-nums text-primary transition-colors hover:border-primary"
+            className="inline-flex h-6 min-w-11 items-center justify-center rounded-md border border-primary/30 bg-primary/10 px-2 font-mono text-xs font-semibold tabular-nums text-primary transition-colors hover:border-primary disabled:cursor-default disabled:opacity-60 disabled:hover:border-primary/30"
             onClick={() => setIsEditing(true)}
+            disabled={!canEdit}
             title={editTitle}
           >
             {(product.allocatedWorkHours || 0).toLocaleString()}
@@ -510,6 +527,9 @@ interface ProductsTimeBlockProps {
   onSelectProject: (projectId: string | null) => void
   t: Translate
   unit: string
+  currentCalendarId: string | null
+  canEdit: boolean
+  canViewOtherPages: boolean
 }
 
 // The "time on products" block: a project selector, an editable per-product list with a
@@ -520,6 +540,9 @@ const ProductsTimeBlock = ({
   onSelectProject,
   t,
   unit,
+  currentCalendarId,
+  canEdit,
+  canViewOtherPages,
 }: ProductsTimeBlockProps): ReactElement => {
   const queryClient = useQueryClient()
   const energyTitle = (givesEnergy: boolean) =>
@@ -531,9 +554,10 @@ const ProductsTimeBlock = ({
   )
 
   const { data: productsData = [] } = useQuery({
-    queryKey: ['products', selectedProjectId],
-    queryFn: () => (selectedProjectId ? listProducts(selectedProjectId) : Promise.resolve([])),
-    enabled: !!selectedProjectId,
+    queryKey: withCal(['products', selectedProjectId], currentCalendarId),
+    queryFn: () =>
+      selectedProjectId ? listProducts(selectedProjectId, currentCalendarId) : Promise.resolve([]),
+    enabled: !!selectedProjectId && (currentCalendarId === null || canViewOtherPages),
   })
 
   const sortedProducts = useMemo(
@@ -554,16 +578,20 @@ const ProductsTimeBlock = ({
   }, [])
 
   const { data: events = [] } = useQuery({
-    queryKey: ['events', eventsYearRange.startDate, eventsYearRange.endDate],
-    queryFn: () => listEvents(eventsYearRange.startDate, eventsYearRange.endDate),
+    queryKey: withCal(
+      ['events', eventsYearRange.startDate, eventsYearRange.endDate],
+      currentCalendarId,
+    ),
+    queryFn: () =>
+      listEvents(eventsYearRange.startDate, eventsYearRange.endDate, currentCalendarId),
     enabled: !!selectedProjectId && productsData.length > 0,
   })
 
   const updateProductHours = useMutation({
     mutationFn: ({ productId, hours }: { productId: string; hours: number }) =>
-      updateProject(productId, { allocatedWorkHours: hours }),
+      updateProject(productId, { allocatedWorkHours: hours }, currentCalendarId),
     onMutate: async ({ productId, hours }) => {
-      const queryKey = ['products', selectedProjectId]
+      const queryKey = withCal(['products', selectedProjectId], currentCalendarId)
       await queryClient.cancelQueries({ queryKey })
       const previousData = queryClient.getQueryData<Product[]>(queryKey)
       if (previousData) {
@@ -580,15 +608,17 @@ const ProductsTimeBlock = ({
       }
     },
     onSuccess: () => {
-      queryClient.invalidateQueries({ queryKey: ['products', selectedProjectId] })
+      queryClient.invalidateQueries({
+        queryKey: withCal(['products', selectedProjectId], currentCalendarId),
+      })
     },
   })
 
   const updateProductEnergy = useMutation({
     mutationFn: ({ productId, givesEnergy }: { productId: string; givesEnergy: boolean }) =>
-      updateProject(productId, { givesEnergy }),
+      updateProject(productId, { givesEnergy }, currentCalendarId),
     onMutate: async ({ productId, givesEnergy }) => {
-      const queryKey = ['products', selectedProjectId]
+      const queryKey = withCal(['products', selectedProjectId], currentCalendarId)
       await queryClient.cancelQueries({ queryKey })
       const previousData = queryClient.getQueryData<Product[]>(queryKey)
       if (previousData) {
@@ -605,8 +635,10 @@ const ProductsTimeBlock = ({
       }
     },
     onSuccess: () => {
-      queryClient.invalidateQueries({ queryKey: ['products', selectedProjectId] })
-      queryClient.invalidateQueries({ queryKey: ['projects'] })
+      queryClient.invalidateQueries({
+        queryKey: withCal(['products', selectedProjectId], currentCalendarId),
+      })
+      queryClient.invalidateQueries({ queryKey: withCal(['projects'], currentCalendarId) })
     },
   })
 
@@ -755,6 +787,7 @@ const ProductsTimeBlock = ({
                   }
                   energyTitle={energyTitle}
                   editTitle={t('focal.budgets.clickToEdit')}
+                  canEdit={canEdit}
                 />
               )
             })}
@@ -952,6 +985,9 @@ interface ActivitiesTimeBlockProps {
   selectedProjectId: string | null
   t: Translate
   unit: string
+  currentCalendarId: string | null
+  canEdit: boolean
+  canViewOtherPages: boolean
 }
 
 const PRODUCT_STORAGE_KEY = 'timeBudgets_selectedProductId'
@@ -962,6 +998,9 @@ const ActivitiesTimeBlock = ({
   selectedProjectId,
   t,
   unit,
+  currentCalendarId,
+  canEdit,
+  canViewOtherPages,
 }: ActivitiesTimeBlockProps): ReactElement => {
   const queryClient = useQueryClient()
 
@@ -984,15 +1023,16 @@ const ActivitiesTimeBlock = ({
   }, [selectedProjectId])
 
   const { data: productsData = [] } = useQuery({
-    queryKey: ['products', selectedProjectId],
-    queryFn: () => (selectedProjectId ? listProducts(selectedProjectId) : Promise.resolve([])),
-    enabled: !!selectedProjectId,
+    queryKey: withCal(['products', selectedProjectId], currentCalendarId),
+    queryFn: () =>
+      selectedProjectId ? listProducts(selectedProjectId, currentCalendarId) : Promise.resolve([]),
+    enabled: !!selectedProjectId && (currentCalendarId === null || canViewOtherPages),
   })
 
   const { data: allActivities = [] } = useQuery({
-    queryKey: ['activities'],
-    queryFn: listActivities,
-    enabled: !!selectedProductId,
+    queryKey: withCal(['activities'], currentCalendarId),
+    queryFn: () => listActivities(currentCalendarId),
+    enabled: !!selectedProductId && (currentCalendarId === null || canViewOtherPages),
   })
 
   const activitiesData = useMemo(
@@ -1013,19 +1053,22 @@ const ActivitiesTimeBlock = ({
       updates: { countPerYear?: number; hoursPerActivity?: number }
       activity: Activity
     }) => {
-      const updated = await updateActivity(activityId, updates)
+      const updated = await updateActivity(activityId, updates, currentCalendarId)
       if (updates.countPerYear !== undefined && updates.countPerYear !== activity.countPerYear) {
-        await syncActivityInstances({
-          activityId,
-          count: updates.countPerYear,
-          hoursPerActivity: updates.hoursPerActivity ?? activity.hoursPerActivity ?? 0,
-          activityName: activity.name,
-        })
+        await syncActivityInstances(
+          {
+            activityId,
+            count: updates.countPerYear,
+            hoursPerActivity: updates.hoursPerActivity ?? activity.hoursPerActivity ?? 0,
+            activityName: activity.name,
+          },
+          currentCalendarId,
+        )
       }
       return updated
     },
     onMutate: async ({ activityId, updates }) => {
-      const queryKey = ['activities']
+      const queryKey = withCal(['activities'], currentCalendarId)
       await queryClient.cancelQueries({ queryKey })
       const previousData = queryClient.getQueryData<Activity[]>(queryKey)
       if (previousData) {
@@ -1042,8 +1085,10 @@ const ActivitiesTimeBlock = ({
       }
     },
     onSuccess: (_data, variables) => {
-      queryClient.invalidateQueries({ queryKey: ['activities'] })
-      queryClient.invalidateQueries({ queryKey: ['activity-instances', variables.activityId] })
+      queryClient.invalidateQueries({ queryKey: withCal(['activities'], currentCalendarId) })
+      queryClient.invalidateQueries({
+        queryKey: withCal(['activity-instances', variables.activityId], currentCalendarId),
+      })
     },
   })
 
@@ -1059,10 +1104,12 @@ const ActivitiesTimeBlock = ({
         endDate?: string | null
         hoursPlanned?: number | null
       }
-    }) => updateActivityInstance(instanceId, updates),
+    }) => updateActivityInstance(instanceId, updates, currentCalendarId),
     onSuccess: (data) => {
       if (data?.activityId) {
-        queryClient.invalidateQueries({ queryKey: ['activity-instances', data.activityId] })
+        queryClient.invalidateQueries({
+          queryKey: withCal(['activity-instances', data.activityId], currentCalendarId),
+        })
       }
     },
   })
@@ -1210,6 +1257,9 @@ const ActivitiesTimeBlock = ({
                       parentGivesEnergy={selectedProduct?.givesEnergy ?? true}
                       t={t}
                       unit={unit}
+                      currentCalendarId={currentCalendarId}
+                      canEdit={canEdit}
+                      canViewOtherPages={canViewOtherPages}
                     />
                   )
                 })
@@ -1266,6 +1316,9 @@ interface ActivityRowProps {
   parentGivesEnergy: boolean
   t: Translate
   unit: string
+  currentCalendarId: string | null
+  canEdit: boolean
+  canViewOtherPages: boolean
 }
 
 const ActivityRow = ({
@@ -1278,6 +1331,9 @@ const ActivityRow = ({
   parentGivesEnergy,
   t,
   unit,
+  currentCalendarId,
+  canEdit,
+  canViewOtherPages,
 }: ActivityRowProps): ReactElement => {
   const [editingCount, setEditingCount] = useState(false)
   const [editingHours, setEditingHours] = useState(false)
@@ -1286,17 +1342,22 @@ const ActivityRow = ({
   const [isExpanded, setIsExpanded] = useState(false)
 
   const { data: instances = [] } = useQuery({
-    queryKey: ['activity-instances', activity.id],
-    queryFn: () => listActivityInstances(activity.id),
-    enabled: isExpanded && (activity.countPerYear || 0) > 0,
+    queryKey: withCal(['activity-instances', activity.id], currentCalendarId),
+    queryFn: () => listActivityInstances(activity.id, currentCalendarId),
+    enabled:
+      isExpanded &&
+      (activity.countPerYear || 0) > 0 &&
+      (currentCalendarId === null || canViewOtherPages),
   })
 
   const handleSaveCount = () => {
+    if (!canEdit) return
     onUpdate({ countPerYear: countValue })
     setEditingCount(false)
   }
 
   const handleSaveHours = () => {
+    if (!canEdit) return
     onUpdate({ hoursPerActivity: hoursValue })
     setEditingHours(false)
   }
@@ -1356,8 +1417,9 @@ const ActivityRow = ({
           ) : (
             <button
               type="button"
-              className="cursor-pointer hover:bg-muted px-2 py-0.5 rounded transition-colors"
+              className="cursor-pointer hover:bg-muted px-2 py-0.5 rounded transition-colors disabled:cursor-default disabled:hover:bg-transparent"
               onClick={() => setEditingCount(true)}
+              disabled={!canEdit}
               title={t('focal.budgets.clickToEdit')}
             >
               {activity.countPerYear || 1}
@@ -1389,8 +1451,9 @@ const ActivityRow = ({
           ) : (
             <button
               type="button"
-              className="cursor-pointer hover:bg-muted px-2 py-0.5 rounded transition-colors"
+              className="cursor-pointer hover:bg-muted px-2 py-0.5 rounded transition-colors disabled:cursor-default disabled:hover:bg-transparent"
               onClick={() => setEditingHours(true)}
+              disabled={!canEdit}
               title={t('focal.budgets.clickToEdit')}
             >
               {activity.hoursPerActivity || 0}
@@ -1458,6 +1521,7 @@ const ActivityRow = ({
                   t={t}
                   unit={unit}
                   activityColor={activityColor}
+                  canEdit={canEdit}
                 />
               )
             })
@@ -1482,6 +1546,7 @@ interface ActivityInstanceRowProps {
   t: Translate
   unit: string
   activityColor: string
+  canEdit: boolean
 }
 
 const ActivityInstanceRow = ({
@@ -1492,6 +1557,7 @@ const ActivityInstanceRow = ({
   t,
   unit,
   activityColor,
+  canEdit,
 }: ActivityInstanceRowProps): ReactElement => {
   const [editingName, setEditingName] = useState(false)
   const [editingHours, setEditingHours] = useState(false)
@@ -1519,16 +1585,19 @@ const ActivityInstanceRow = ({
       : 'text-muted-foreground'
 
   const handleSaveName = () => {
+    if (!canEdit) return
     if (nameValue !== instance.name) onUpdate({ name: nameValue })
     setEditingName(false)
   }
 
   const handleSaveHours = () => {
+    if (!canEdit) return
     onUpdate({ hoursPlanned: hoursValue })
     setEditingHours(false)
   }
 
   const handleDatesChange = (start: string, end: string) => {
+    if (!canEdit) return
     setStartDate(start)
     setEndDate(end)
     if (start && end) {
@@ -1573,8 +1642,9 @@ const ActivityInstanceRow = ({
         ) : (
           <button
             type="button"
-            className="cursor-pointer hover:bg-muted px-1 py-0.5 rounded transition-colors truncate block w-full text-left"
+            className="cursor-pointer hover:bg-muted px-1 py-0.5 rounded transition-colors truncate block w-full text-left disabled:cursor-default disabled:hover:bg-transparent"
             onClick={() => setEditingName(true)}
+            disabled={!canEdit}
             title={t('focal.budgets.clickToEdit')}
           >
             {instance.name}
@@ -1587,6 +1657,7 @@ const ActivityInstanceRow = ({
           <Input
             type="date"
             value={startDate}
+            disabled={!canEdit}
             onChange={(event) => {
               const newStart = event.target.value
               if (newStart) handleDatesChange(newStart, endDate || newStart)
@@ -1597,6 +1668,7 @@ const ActivityInstanceRow = ({
           <Input
             type="date"
             value={endDate}
+            disabled={!canEdit}
             onChange={(event) => {
               const newEnd = event.target.value
               if (newEnd && startDate) handleDatesChange(startDate, newEnd)
@@ -1615,6 +1687,7 @@ const ActivityInstanceRow = ({
             size="sm"
             className="h-5 w-5 p-0 text-muted-foreground hover:text-destructive"
             onClick={() => handleDatesChange('', '')}
+            disabled={!canEdit}
             title={t('focal.budgets.clearDates')}
           >
             ×
@@ -1648,8 +1721,9 @@ const ActivityInstanceRow = ({
         ) : (
           <button
             type="button"
-            className="cursor-pointer hover:bg-muted px-1 py-0.5 rounded transition-colors"
+            className="cursor-pointer hover:bg-muted px-1 py-0.5 rounded transition-colors disabled:cursor-default disabled:hover:bg-transparent"
             onClick={() => setEditingHours(true)}
+            disabled={!canEdit}
             title={t('focal.budgets.clickToEdit')}
           >
             {hoursValue}
@@ -1683,6 +1757,7 @@ const STORAGE_KEY = 'timeBudgets_selectedProjectId'
 export const TimeBudgetsPage = (): ReactElement => {
   const { t } = useTranslation()
   const queryClient = useQueryClient()
+  const { currentCalendarId, canEdit, canViewOtherPages } = useCalendarFilter()
 
   const unit = t('focal.budgets.unitShort')
   const unitYear = t('focal.budgets.unitPerYear')
@@ -1712,13 +1787,15 @@ export const TimeBudgetsPage = (): ReactElement => {
   }
 
   const { data, isLoading } = useQuery({
-    queryKey: ['time-budgets', year],
-    queryFn: () => getBudgetYear(year),
+    queryKey: withCal(['time-budgets', year], currentCalendarId),
+    queryFn: () => getBudgetYear(year, currentCalendarId),
+    enabled: currentCalendarId === null || canViewOtherPages,
   })
 
   const { data: projects = [] } = useQuery({
-    queryKey: ['projects'],
-    queryFn: listProjects,
+    queryKey: withCal(['projects'], currentCalendarId),
+    queryFn: () => listProjects(currentCalendarId),
+    enabled: currentCalendarId === null || canViewOtherPages,
   })
 
   const spheres = useMemo(
@@ -1741,9 +1818,9 @@ export const TimeBudgetsPage = (): ReactElement => {
 
   const updateSettingsMutation = useMutation({
     mutationFn: ({ id, updates }: { id: string; updates: Parameters<typeof updateSettings>[1] }) =>
-      updateSettings(id, updates),
+      updateSettings(id, updates, currentCalendarId),
     onMutate: async ({ updates }) => {
-      const queryKey = ['time-budgets', year]
+      const queryKey = withCal(['time-budgets', year], currentCalendarId)
       await queryClient.cancelQueries({ queryKey })
       const previousData =
         queryClient.getQueryData<Awaited<ReturnType<typeof getBudgetYear>>>(queryKey)
@@ -1774,9 +1851,9 @@ export const TimeBudgetsPage = (): ReactElement => {
         givesEnergy?: boolean
         name?: string
       }
-    }) => updateProject(id, updates),
+    }) => updateProject(id, updates, currentCalendarId),
     onMutate: async ({ id, updates }) => {
-      const queryKey = ['projects']
+      const queryKey = withCal(['projects'], currentCalendarId)
       await queryClient.cancelQueries({ queryKey })
       const previousData = queryClient.getQueryData<Project[]>(queryKey)
       if (previousData) {
@@ -1793,7 +1870,7 @@ export const TimeBudgetsPage = (): ReactElement => {
       }
     },
     onSuccess: () => {
-      queryClient.invalidateQueries({ queryKey: ['projects'] })
+      queryClient.invalidateQueries({ queryKey: withCal(['projects'], currentCalendarId) })
     },
   })
 
@@ -1847,6 +1924,7 @@ export const TimeBudgetsPage = (): ReactElement => {
     setEditValue(currentHours.toString())
   }
   const handleSaveEdit = (categoryId: string) => {
+    if (!canEdit) return
     const hours = parseInt(editValue, 10) || 0
     updateProjectMutation.mutate({ id: categoryId, updates: { allocatedHours: hours } })
     setEditingCategory(null)
@@ -1861,6 +1939,7 @@ export const TimeBudgetsPage = (): ReactElement => {
     setEditSphereNameValue(currentName)
   }
   const handleSaveEditName = (sphereId: string) => {
+    if (!canEdit) return
     if (editSphereNameValue.trim()) {
       updateProjectMutation.mutate({ id: sphereId, updates: { name: editSphereNameValue.trim() } })
     }
@@ -1873,6 +1952,7 @@ export const TimeBudgetsPage = (): ReactElement => {
   }
 
   const handleToggleEnergy = (sphereId: string, givesEnergy: boolean) => {
+    if (!canEdit) return
     updateProjectMutation.mutate({ id: sphereId, updates: { givesEnergy } })
   }
 
@@ -1881,6 +1961,7 @@ export const TimeBudgetsPage = (): ReactElement => {
     setEditProjectValue(currentHours.toString())
   }
   const handleSaveEditProject = (projectId: string) => {
+    if (!canEdit) return
     const hours = parseInt(editProjectValue, 10) || 0
     updateProjectMutation.mutate({ id: projectId, updates: { allocatedWorkHours: hours } })
     setEditingProject(null)
@@ -1890,6 +1971,7 @@ export const TimeBudgetsPage = (): ReactElement => {
     setEditProjectValue('')
   }
   const handleToggleProjectEnergy = (projectId: string, givesEnergy: boolean) => {
+    if (!canEdit) return
     updateProjectMutation.mutate({ id: projectId, updates: { givesEnergy } })
   }
 
@@ -1944,6 +2026,12 @@ export const TimeBudgetsPage = (): ReactElement => {
         centerActions={yearNavigator}
       />
 
+      {!canEdit && (
+        <div className="px-3 py-2 text-xs text-muted-foreground border-b bg-muted/30">
+          {t('focal.app.calendarFilter.readOnlyNotice')}
+        </div>
+      )}
+
       <div className="flex-1 overflow-auto p-3 md:p-4">
         <div className="space-y-4">
           {isTimeCalcCollapsed ? (
@@ -2028,6 +2116,7 @@ export const TimeBudgetsPage = (): ReactElement => {
                         <td className="text-right py-1 px-2 text-muted-foreground">
                           <EditableNumber
                             value={settings?.sleepHoursPerDay ?? 8}
+                            disabled={!canEdit}
                             onSave={(val) =>
                               settings?.id &&
                               updateSettingsMutation.mutate({
@@ -2058,6 +2147,7 @@ export const TimeBudgetsPage = (): ReactElement => {
                         <td className="text-right py-1 px-2 text-muted-foreground">
                           <EditableNumber
                             value={settings?.hygieneHoursPerDay ?? 1}
+                            disabled={!canEdit}
                             onSave={(val) =>
                               settings?.id &&
                               updateSettingsMutation.mutate({
@@ -2088,6 +2178,7 @@ export const TimeBudgetsPage = (): ReactElement => {
                         <td className="text-right py-1 px-2 text-muted-foreground">
                           <EditableNumber
                             value={settings?.eatingHoursPerDay ?? 2}
+                            disabled={!canEdit}
                             onSave={(val) =>
                               settings?.id &&
                               updateSettingsMutation.mutate({
@@ -2118,6 +2209,7 @@ export const TimeBudgetsPage = (): ReactElement => {
                           <div className="flex items-center justify-end">
                             <EditableNumber
                               value={settings?.workingDaysInYear ?? 246}
+                              disabled={!canEdit}
                               onSave={(val) =>
                                 settings?.id &&
                                 updateSettingsMutation.mutate({
@@ -2134,6 +2226,7 @@ export const TimeBudgetsPage = (): ReactElement => {
                         <td className="text-right py-1 px-2 font-semibold text-blue-700 dark:text-blue-300">
                           <EditableNumber
                             value={settings?.workingHoursPerDay ?? 8}
+                            disabled={!canEdit}
                             onSave={(val) =>
                               settings?.id &&
                               updateSettingsMutation.mutate({
@@ -2168,6 +2261,7 @@ export const TimeBudgetsPage = (): ReactElement => {
                           <span className="inline-flex items-center justify-end gap-1">
                             <EditableNumber
                               value={settings?.reservePercent ?? 10}
+                              disabled={!canEdit}
                               onSave={(val) =>
                                 settings?.id &&
                                 updateSettingsMutation.mutate({
@@ -2392,6 +2486,7 @@ export const TimeBudgetsPage = (): ReactElement => {
                               onToggleEnergy={handleToggleProjectEnergy}
                               energyTitle={energyTitle}
                               editTitle={t('focal.budgets.clickToEdit')}
+                              canEdit={canEdit}
                             />
                           )
                         })
@@ -2492,12 +2587,18 @@ export const TimeBudgetsPage = (): ReactElement => {
                 onSelectProject={handleSelectProjectForProducts}
                 t={t}
                 unit={unit}
+                currentCalendarId={currentCalendarId}
+                canEdit={canEdit}
+                canViewOtherPages={canViewOtherPages}
               />
 
               <ActivitiesTimeBlock
                 selectedProjectId={selectedProjectIdForProducts}
                 t={t}
                 unit={unit}
+                currentCalendarId={currentCalendarId}
+                canEdit={canEdit}
+                canViewOtherPages={canViewOtherPages}
               />
             </>
           )}
@@ -2573,6 +2674,7 @@ export const TimeBudgetsPage = (): ReactElement => {
                           onToggleEnergy={handleToggleEnergy}
                           energyTitle={energyTitle}
                           editTitle={t('focal.budgets.clickToEdit')}
+                          canEdit={canEdit}
                         />
                       )
                     })}
diff --git a/apps/focal/client/src/features/calendar/CalendarPage.test.tsx b/apps/focal/client/src/features/calendar/CalendarPage.test.tsx
index 010f8a9..658860c 100644
--- a/apps/focal/client/src/features/calendar/CalendarPage.test.tsx
+++ b/apps/focal/client/src/features/calendar/CalendarPage.test.tsx
@@ -118,7 +118,7 @@ describe('CalendarPage', () => {
     renderPage()
 
     expect(await screen.findByText('Standup')).toBeInTheDocument()
-    expect(mocked.listEvents).toHaveBeenCalledWith(weekStartIso, weekEndIso)
+    expect(mocked.listEvents).toHaveBeenCalledWith(weekStartIso, weekEndIso, null)
   })
 
   it('navigates to the previous week', async () => {
@@ -129,7 +129,7 @@ describe('CalendarPage', () => {
 
     const previousStart = toIsoDate(addDays(mondayOf(new Date()), -7))
     const previousEnd = toIsoDate(addDays(mondayOf(new Date()), -1))
-    expect(mocked.listEvents).toHaveBeenCalledWith(previousStart, previousEnd)
+    expect(mocked.listEvents).toHaveBeenCalledWith(previousStart, previousEnd, null)
   })
 
   it('creates an event from the slot popover', async () => {
@@ -142,15 +142,18 @@ describe('CalendarPage', () => {
     await user.click(screen.getByRole('button', { name: tr('focal.calendar.form.submit') }))
 
     await waitFor(() =>
-      expect(mocked.createEvent).toHaveBeenCalledWith({
-        title: 'Review',
-        date: todayIso,
-        startTime: '09:00',
-        endTime: '10:00',
-        status: 'planned',
-        completed: false,
-        recurrence: 'none',
-      }),
+      expect(mocked.createEvent).toHaveBeenCalledWith(
+        {
+          title: 'Review',
+          date: todayIso,
+          startTime: '09:00',
+          endTime: '10:00',
+          status: 'planned',
+          completed: false,
+          recurrence: 'none',
+        },
+        null,
+      ),
     )
   })
 
@@ -207,7 +210,7 @@ describe('CalendarPage', () => {
       await screen.findByRole('combobox', { name: tr('focal.calendar.popover.project') }),
       'p1',
     )
-    await waitFor(() => expect(mockedProducts.listProducts).toHaveBeenCalledWith('p1'))
+    await waitFor(() => expect(mockedProducts.listProducts).toHaveBeenCalledWith('p1', null))
     await user.selectOptions(
       await screen.findByRole('combobox', { name: tr('focal.calendar.popover.product') }),
       'pr1',
@@ -328,7 +331,7 @@ describe('CalendarPage', () => {
     await user.click(await screen.findByText('Standup'))
     await user.click(await screen.findByRole('button', { name: tr('focal.calendar.edit.delete') }))
 
-    await waitFor(() => expect(mocked.deleteEvent).toHaveBeenCalledWith('e1', undefined))
+    await waitFor(() => expect(mocked.deleteEvent).toHaveBeenCalledWith('e1', undefined, null))
   })
 
   it('deletes a recurring occurrence with the chosen scope', async () => {
@@ -347,10 +350,14 @@ describe('CalendarPage', () => {
     await user.click(screen.getByRole('button', { name: tr('focal.calendar.scopeDialog.confirm') }))
 
     await waitFor(() =>
-      expect(mocked.deleteEvent).toHaveBeenCalledWith('e2', {
-        scope: 'following',
-        occurrenceDate: weekStartIso,
-      }),
+      expect(mocked.deleteEvent).toHaveBeenCalledWith(
+        'e2',
+        {
+          scope: 'following',
+          occurrenceDate: weekStartIso,
+        },
+        null,
+      ),
     )
   })
 
@@ -369,10 +376,14 @@ describe('CalendarPage', () => {
     )
 
     await waitFor(() => expect(mocked.deleteEvent).toHaveBeenCalledTimes(1))
-    expect(mocked.deleteEvent).toHaveBeenCalledWith('e6', {
-      scope: 'single',
-      occurrenceDate: weekStartIso,
-    })
+    expect(mocked.deleteEvent).toHaveBeenCalledWith(
+      'e6',
+      {
+        scope: 'single',
+        occurrenceDate: weekStartIso,
+      },
+      null,
+    )
   })
 
   it('saves edits to a recurring occurrence with the chosen scope', async () => {
@@ -404,6 +415,7 @@ describe('CalendarPage', () => {
           recurrence: 'daily',
         },
         { scope: 'single', occurrenceDate: weekStartIso },
+        null,
       ),
     )
   })
@@ -523,7 +535,7 @@ describe('CalendarPage', () => {
     await user.click(screen.getByRole('button', { name: tr('focal.calendar.prevWeek') }))
     await user.click(screen.getByRole('button', { name: tr('focal.calendar.today') }))
 
-    expect(mocked.listEvents).toHaveBeenLastCalledWith(weekStartIso, weekEndIso)
+    expect(mocked.listEvents).toHaveBeenLastCalledWith(weekStartIso, weekEndIso, null)
   })
 })
 
@@ -556,11 +568,15 @@ describe('CalendarPage views', () => {
   it('switches to the day view and queries a single day', async () => {
     const user = setupUser()
     renderPage()
-    await waitFor(() => expect(mocked.listEvents).toHaveBeenCalledWith(weekStartIso, weekEndIso))
+    await waitFor(() =>
+      expect(mocked.listEvents).toHaveBeenCalledWith(weekStartIso, weekEndIso, null),
+    )
 
     await user.click(banner().getByRole('button', { name: viewTab('day') }))
 
-    await waitFor(() => expect(mocked.listEvents).toHaveBeenLastCalledWith(todayIso, todayIso))
+    await waitFor(() =>
+      expect(mocked.listEvents).toHaveBeenLastCalledWith(todayIso, todayIso, null),
+    )
   })
 
   it('switches to the 3-day view and queries three days', async () => {
@@ -570,7 +586,7 @@ describe('CalendarPage views', () => {
     await user.click(banner().getByRole('button', { name: viewTab('3day') }))
 
     const end = toIsoDate(addDays(new Date(), 2))
-    await waitFor(() => expect(mocked.listEvents).toHaveBeenLastCalledWith(todayIso, end))
+    await waitFor(() => expect(mocked.listEvents).toHaveBeenLastCalledWith(todayIso, end, null))
   })
 
   it('switches to the month view and queries the six-week grid window', async () => {
@@ -580,7 +596,7 @@ describe('CalendarPage views', () => {
     await user.click(banner().getByRole('button', { name: viewTab('month') }))
 
     const [start, end] = monthWindow(new Date())
-    await waitFor(() => expect(mocked.listEvents).toHaveBeenLastCalledWith(start, end))
+    await waitFor(() => expect(mocked.listEvents).toHaveBeenLastCalledWith(start, end, null))
   })
 
   it('steps a whole month with next while in the month view', async () => {
@@ -591,7 +607,7 @@ describe('CalendarPage views', () => {
     await user.click(banner().getByRole('button', { name: navNext('month') }))
 
     const [start, end] = monthWindow(addMonthsClamped(new Date(), 1))
-    await waitFor(() => expect(mocked.listEvents).toHaveBeenLastCalledWith(start, end))
+    await waitFor(() => expect(mocked.listEvents).toHaveBeenLastCalledWith(start, end, null))
   })
 
   it('renders the 42-cell month grid with previews + a +N overflow and zooms to a clicked day', async () => {
@@ -614,20 +630,22 @@ describe('CalendarPage views', () => {
     await user.click(screen.getByRole('button', { name: monthDayCell(new Date(2026, 5, 10), 4) }))
 
     await waitFor(() =>
-      expect(mocked.listEvents).toHaveBeenLastCalledWith('2026-06-10', '2026-06-10'),
+      expect(mocked.listEvents).toHaveBeenLastCalledWith('2026-06-10', '2026-06-10', null),
     )
   })
 
   it('moves the main grid to a picked mini-month day, preserving the current view', async () => {
     const user = setupUser()
     renderPage()
-    await waitFor(() => expect(mocked.listEvents).toHaveBeenCalledWith(weekStartIso, weekEndIso))
+    await waitFor(() =>
+      expect(mocked.listEvents).toHaveBeenCalledWith(weekStartIso, weekEndIso, null),
+    )
 
     // 2026-06-08 is the Monday of the week before the anchor's week.
     await user.click(rail().getByRole('button', { name: miniDay(new Date(2026, 5, 8)) }))
 
     await waitFor(() =>
-      expect(mocked.listEvents).toHaveBeenLastCalledWith('2026-06-08', '2026-06-14'),
+      expect(mocked.listEvents).toHaveBeenLastCalledWith('2026-06-08', '2026-06-14', null),
     )
     // Still the week view (now-line is hidden because that week excludes today).
     expect(banner().getByRole('button', { name: viewTab('week') })).toHaveAttribute(
@@ -639,7 +657,9 @@ describe('CalendarPage views', () => {
   it('browses the mini-month with its chevrons without re-querying the main grid', async () => {
     const user = setupUser()
     renderPage()
-    await waitFor(() => expect(mocked.listEvents).toHaveBeenCalledWith(weekStartIso, weekEndIso))
+    await waitFor(() =>
+      expect(mocked.listEvents).toHaveBeenCalledWith(weekStartIso, weekEndIso, null),
+    )
     mocked.listEvents.mockClear()
 
     await user.click(rail().getByRole('button', { name: tr('focal.calendar.miniMonth.next') }))
@@ -652,18 +672,24 @@ describe('CalendarPage views', () => {
   it('switches views and navigates via keyboard shortcuts', async () => {
     const user = setupUser()
     renderPage()
-    await waitFor(() => expect(mocked.listEvents).toHaveBeenCalledWith(weekStartIso, weekEndIso))
+    await waitFor(() =>
+      expect(mocked.listEvents).toHaveBeenCalledWith(weekStartIso, weekEndIso, null),
+    )
 
     await user.keyboard('d')
-    await waitFor(() => expect(mocked.listEvents).toHaveBeenLastCalledWith(todayIso, todayIso))
+    await waitFor(() =>
+      expect(mocked.listEvents).toHaveBeenLastCalledWith(todayIso, todayIso, null),
+    )
 
     await user.keyboard('n')
     const tomorrow = toIsoDate(addDays(new Date(), 1))
-    await waitFor(() => expect(mocked.listEvents).toHaveBeenLastCalledWith(tomorrow, tomorrow))
+    await waitFor(() =>
+      expect(mocked.listEvents).toHaveBeenLastCalledWith(tomorrow, tomorrow, null),
+    )
 
     await user.keyboard('m')
     const [start, end] = monthWindow(addDays(new Date(), 1))
-    await waitFor(() => expect(mocked.listEvents).toHaveBeenLastCalledWith(start, end))
+    await waitFor(() => expect(mocked.listEvents).toHaveBeenLastCalledWith(start, end, null))
   })
 
   it('ignores view shortcuts while a popover input is focused', async () => {
@@ -754,15 +780,18 @@ describe('CalendarPage views', () => {
     await user.click(screen.getByRole('button', { name: tr('focal.calendar.form.submit') }))
 
     await waitFor(() =>
-      expect(mocked.createEvent).toHaveBeenCalledWith({
-        title: 'In day view',
-        date: todayIso,
-        startTime: '09:00',
-        endTime: '10:00',
-        status: 'planned',
-        completed: false,
-        recurrence: 'none',
-      }),
+      expect(mocked.createEvent).toHaveBeenCalledWith(
+        {
+          title: 'In day view',
+          date: todayIso,
+          startTime: '09:00',
+          endTime: '10:00',
+          status: 'planned',
+          completed: false,
+          recurrence: 'none',
+        },
+        null,
+      ),
     )
   })
 })
diff --git a/apps/focal/client/src/features/calendar/CalendarPage.tsx b/apps/focal/client/src/features/calendar/CalendarPage.tsx
index c32f059..6c7787e 100644
--- a/apps/focal/client/src/features/calendar/CalendarPage.tsx
+++ b/apps/focal/client/src/features/calendar/CalendarPage.tsx
@@ -3,9 +3,11 @@ import { Calendar as CalendarIcon, ChevronLeft, ChevronRight } from 'lucide-reac
 import { useCallback, useEffect, useState } from 'react'
 import { useTranslation } from 'react-i18next'
 
+import { withCal } from '@/api/queryKeys'
 import { PageHeader } from '@/components/PageHeader'
 import { Button } from '@/components/ui/button'
 import { Card } from '@/components/ui/card'
+import { useCalendarFilter } from '@/features/calendars/CalendarFilterContext'
 import { cn } from '@/lib/utils'
 
 import {
@@ -171,16 +173,17 @@ export const CalendarPage = () => {
   const { t, i18n } = useTranslation()
   const queryClient = useQueryClient()
   const locale = i18n.resolvedLanguage ?? i18n.language
+  const { currentCalendarId, canEdit } = useCalendarFilter()
 
   const [view, setView] = useState<CalendarView>('week')
   const [anchor, setAnchor] = useState(() => new Date())
   const { days, startIso, endIso } = windowFor(view, anchor)
   const todayIso = toIsoDate(new Date())
 
-  const eventsKey = ['events', startIso, endIso] as const
+  const eventsKey = withCal(['events', startIso, endIso], currentCalendarId)
   const events = useQuery({
     queryKey: eventsKey,
-    queryFn: () => listEvents(startIso, endIso),
+    queryFn: () => listEvents(startIso, endIso, currentCalendarId),
   })
 
   const [popover, setPopover] = useState<PopoverState | null>(null)
@@ -209,7 +212,7 @@ export const CalendarPage = () => {
   }
 
   const createMutation = useMutation({
-    mutationFn: (input: EventCreate) => createEvent(input),
+    mutationFn: (input: EventCreate) => createEvent(input, currentCalendarId),
     onSuccess: async () => {
       closePopover()
       setParticipants([])
@@ -224,7 +227,7 @@ export const CalendarPage = () => {
       event: CalendarEvent
       patch: EventUpdate
       target: RecurrenceTarget | undefined
-    }) => updateEvent(vars.event.id, vars.patch, vars.target),
+    }) => updateEvent(vars.event.id, vars.patch, vars.target, currentCalendarId),
     onSuccess: async () => {
       closePopover()
       setPendingOp(null)
@@ -236,7 +239,7 @@ export const CalendarPage = () => {
 
   const deleteMutation = useMutation({
     mutationFn: (vars: { event: CalendarEvent; target: RecurrenceTarget | undefined }) =>
-      deleteEvent(vars.event.id, vars.target),
+      deleteEvent(vars.event.id, vars.target, currentCalendarId),
     onSuccess: async () => {
       closePopover()
       setPendingOp(null)
@@ -247,6 +250,7 @@ export const CalendarPage = () => {
   })
 
   const openCreate = (dateIso: string, hour: number, anchorSource: AnchorSource) => {
+    if (!canEdit) return
     setPopover({ mode: 'create', event: null, anchor: anchorSource })
     setDraft(createDraft(dateIso, hour))
     setDirty(new Set())
@@ -272,6 +276,7 @@ export const CalendarPage = () => {
   }
 
   const handleSave = () => {
+    if (!canEdit) return
     if (!popover || !draft) return
     if (popover.mode === 'create') {
       createMutation.mutate(createPayload(draft))
@@ -285,6 +290,7 @@ export const CalendarPage = () => {
   }
 
   const handleDelete = () => {
+    if (!canEdit) return
     const event = popover?.event
     if (!event) return
     if (isRecurring(event)) setPendingOp({ mode: 'delete', event })
@@ -441,6 +447,11 @@ export const CalendarPage = () => {
             {/* Region reserved for the upcoming side panel (a later slice). */}
           </aside>
           <main className="flex min-w-0 flex-1 flex-col gap-3 overflow-hidden">
+            {!canEdit && (
+              <p className="rounded-md border border-border bg-muted px-3 py-2 text-sm text-muted-foreground">
+                {t('focal.app.calendarFilter.readOnlyNotice')}
+              </p>
+            )}
             {errorMessage && (
               <p
                 role="alert"
@@ -477,6 +488,7 @@ export const CalendarPage = () => {
                   events={events.data ?? []}
                   todayIso={todayIso}
                   locale={locale}
+                  canEdit={canEdit}
                   onCreate={openCreate}
                   onEdit={openEdit}
                 />
@@ -491,6 +503,7 @@ export const CalendarPage = () => {
           open
           mode={popover.mode}
           anchor={popover.anchor}
+          readOnly={!canEdit}
           draft={draft}
           recurring={popover.event ? isRecurring(popover.event) : false}
           participants={participants}
diff --git a/apps/focal/client/src/features/calendar/EventPopover.tsx b/apps/focal/client/src/features/calendar/EventPopover.tsx
index 27a3935..03bc1c2 100644
--- a/apps/focal/client/src/features/calendar/EventPopover.tsx
+++ b/apps/focal/client/src/features/calendar/EventPopover.tsx
@@ -2,12 +2,13 @@ import { useQuery } from '@tanstack/react-query'
 import { Trash2 } from 'lucide-react'
 import { useMemo, useRef } from 'react'
 import { useTranslation } from 'react-i18next'
-
+import { withCal } from '@/api/queryKeys'
 import { Button } from '@/components/ui/button'
 import { Checkbox } from '@/components/ui/checkbox'
 import { Input } from '@/components/ui/input'
 import { Label } from '@/components/ui/label'
 import { Popover, PopoverAnchor, PopoverContent } from '@/components/ui/popover'
+import { useCalendarFilter } from '@/features/calendars/CalendarFilterContext'
 import { listActivities } from '../../api/activities'
 import { listProducts } from '../../api/products'
 import { listProjects } from '../../api/projects'
@@ -50,6 +51,8 @@ export interface EventPopoverProps {
   participants: PrimaContact[]
   isSaving: boolean
   isDeleting: boolean
+  /** When true, renders the event as view-only — every field is locked and Save/Delete are disabled. */
+  readOnly?: boolean
   onParticipantsChange: (next: PrimaContact[]) => void
   onPatch: (patch: Partial<EventDraft>) => void
   onSave: () => void
@@ -72,6 +75,7 @@ export const EventPopover = ({
   participants,
   isSaving,
   isDeleting,
+  readOnly = false,
   onParticipantsChange,
   onPatch,
   onSave,
@@ -79,6 +83,10 @@ export const EventPopover = ({
   onOpenChange,
 }: EventPopoverProps) => {
   const { t } = useTranslation()
+  const { currentCalendarId, canViewOtherPages } = useCalendarFilter()
+  // Reference lookups hit other-pages domains; gate them so a participant without other-pages
+  // access doesn't fire a 403 against the owner's projects/products/activities.
+  const canReadReference = currentCalendarId === null || canViewOtherPages
 
   // Stable virtual anchor whose rect reads the latest captured element (live while connected, else
   // the snapshot rect) — Radix repositions the popover against the real grid click.
@@ -92,16 +100,20 @@ export const EventPopover = ({
     },
   })
 
-  const projects = useQuery({ queryKey: ['projects'], queryFn: listProjects, enabled: open })
+  const projects = useQuery({
+    queryKey: withCal(['projects'], currentCalendarId),
+    queryFn: () => listProjects(currentCalendarId),
+    enabled: canReadReference && open,
+  })
   const products = useQuery({
-    queryKey: ['products', draft.projectId],
-    queryFn: () => listProducts(draft.projectId as string),
-    enabled: open && !!draft.projectId,
+    queryKey: withCal(['products', draft.projectId], currentCalendarId),
+    queryFn: () => listProducts(draft.projectId as string, currentCalendarId),
+    enabled: canReadReference && open && !!draft.projectId,
   })
   const activities = useQuery({
-    queryKey: ['activities'],
-    queryFn: listActivities,
-    enabled: open && !!draft.productId,
+    queryKey: withCal(['activities'], currentCalendarId),
+    queryFn: () => listActivities(currentCalendarId),
+    enabled: canReadReference && open && !!draft.productId,
   })
 
   // Products endpoint returns the project's child rows; project options are the root projects only.
@@ -151,8 +163,10 @@ export const EventPopover = ({
           <Input
             data-event-title="true"
             value={draft.title}
+            readOnly={readOnly}
             onChange={(event) => onPatch({ title: event.target.value })}
             onKeyDown={(event) => {
+              if (readOnly) return
               if (event.key === 'Enter') onSave()
             }}
             placeholder={t('focal.calendar.form.titlePlaceholder')}
@@ -176,6 +190,7 @@ export const EventPopover = ({
               type="date"
               className={fieldClass}
               value={draft.date}
+              disabled={readOnly}
               onChange={(event) => onPatch({ date: event.target.value })}
               aria-label={t('focal.calendar.form.date')}
             />
@@ -187,6 +202,7 @@ export const EventPopover = ({
               type="time"
               className={fieldClass}
               value={draft.startTime}
+              disabled={readOnly}
               onChange={(event) => onPatch({ startTime: event.target.value })}
               aria-label={t('focal.calendar.form.start')}
             />
@@ -198,6 +214,7 @@ export const EventPopover = ({
               type="time"
               className={fieldClass}
               value={draft.endTime}
+              disabled={readOnly}
               onChange={(event) => onPatch({ endTime: event.target.value })}
               aria-label={t('focal.calendar.form.end')}
             />
@@ -209,6 +226,7 @@ export const EventPopover = ({
           <Checkbox
             id="event-done"
             checked={draft.completed}
+            disabled={readOnly}
             onCheckedChange={(value) => onPatch({ completed: value === true })}
           />
           <Label htmlFor="event-done" className="cursor-pointer font-normal text-foreground">
@@ -236,6 +254,7 @@ export const EventPopover = ({
             <select
               className={fieldClass}
               value={draft.projectId ?? ''}
+              disabled={readOnly}
               onChange={(event) =>
                 onPatch({
                   projectId: event.target.value || null,
@@ -256,7 +275,7 @@ export const EventPopover = ({
           <select
             className={fieldClass}
             value={draft.productId ?? ''}
-            disabled={!draft.projectId}
+            disabled={readOnly || !draft.projectId}
             onChange={(event) =>
               onPatch({ productId: event.target.value || null, activityId: null })
             }
@@ -272,7 +291,7 @@ export const EventPopover = ({
           <select
             className={fieldClass}
             value={draft.activityId ?? ''}
-            disabled={!draft.productId}
+            disabled={readOnly || !draft.productId}
             onChange={(event) => onPatch({ activityId: event.target.value || null })}
             aria-label={t('focal.calendar.popover.activity')}
           >
@@ -294,6 +313,7 @@ export const EventPopover = ({
             id="event-recurrence"
             className={fieldClass}
             value={draft.recurrence}
+            disabled={readOnly}
             onChange={(event) => onPatch({ recurrence: event.target.value })}
             aria-label={t('focal.calendar.form.recurrence')}
           >
@@ -311,6 +331,7 @@ export const EventPopover = ({
             <button
               key={color}
               type="button"
+              disabled={readOnly}
               onClick={() => onPatch({ color })}
               title={color}
               aria-label={t('focal.calendar.popover.colorSwatch', { color })}
@@ -334,14 +355,14 @@ export const EventPopover = ({
               variant="destructive"
               size="sm"
               onClick={onDelete}
-              disabled={isDeleting}
+              disabled={readOnly || isDeleting}
             >
               <Trash2 className="h-4 w-4" />
               {t('focal.calendar.edit.delete')}
             </Button>
           )}
           <div className="flex-1" />
-          <Button type="button" size="sm" onClick={onSave} disabled={isSaving}>
+          <Button type="button" size="sm" onClick={onSave} disabled={readOnly || isSaving}>
             {mode === 'create' ? t('focal.calendar.form.submit') : t('focal.calendar.edit.save')}
           </Button>
         </div>
diff --git a/apps/focal/client/src/features/calendar/TimeGrid.tsx b/apps/focal/client/src/features/calendar/TimeGrid.tsx
index 92a81a0..486e4cd 100644
--- a/apps/focal/client/src/features/calendar/TimeGrid.tsx
+++ b/apps/focal/client/src/features/calendar/TimeGrid.tsx
@@ -27,6 +27,8 @@ export interface TimeGridProps {
   todayIso: string
   /** BCP-47 locale for the weekday header. */
   locale: string
+  /** When false (read-only shared calendar), the click-to-create slots are disabled. */
+  canEdit: boolean
   onCreate: (dateIso: string, hour: number, anchor: AnchorSource) => void
   onEdit: (event: CalendarEvent, anchor: AnchorSource) => void
 }
@@ -37,7 +39,15 @@ export interface TimeGridProps {
  * click-to-create slots, the lane-laid-out event blocks, and the now-line **only** on the column
  * whose date is today (which exists only when today is among the visible days).
  */
-export const TimeGrid = ({ days, events, todayIso, locale, onCreate, onEdit }: TimeGridProps) => {
+export const TimeGrid = ({
+  days,
+  events,
+  todayIso,
+  locale,
+  canEdit,
+  onCreate,
+  onEdit,
+}: TimeGridProps) => {
   const { t } = useTranslation()
   const dayName = new Intl.DateTimeFormat(locale, { weekday: 'short' })
 
@@ -101,7 +111,11 @@ export const TimeGrid = ({ days, events, todayIso, locale, onCreate, onEdit }: T
                 <button
                   key={hour}
                   type="button"
-                  className="block w-full border-b border-border/50 hover:bg-accent"
+                  disabled={!canEdit}
+                  className={cn(
+                    'block w-full border-b border-border/50',
+                    canEdit && 'hover:bg-accent',
+                  )}
                   style={{ height: HOUR_HEIGHT }}
                   onClick={(domEvent) =>
                     onCreate(dateIso, hour, {
diff --git a/apps/focal/client/src/features/calendars/CalendarsPage.tsx b/apps/focal/client/src/features/calendars/CalendarsPage.tsx
index 110ec1d..e8526c4 100644
--- a/apps/focal/client/src/features/calendars/CalendarsPage.tsx
+++ b/apps/focal/client/src/features/calendars/CalendarsPage.tsx
@@ -147,8 +147,8 @@ interface FilterEditorProps {
 /** old-focal's «Что показывается» editor: a type Select + the per-type value control. */
 const FilterEditor = ({ draft, onChange }: FilterEditorProps) => {
   const { t } = useTranslation()
-  const spheres = useQuery({ queryKey: ['spheres'], queryFn: listSpheres })
-  const projects = useQuery({ queryKey: ['projects'], queryFn: listProjects })
+  const spheres = useQuery({ queryKey: ['spheres'], queryFn: () => listSpheres() })
+  const projects = useQuery({ queryKey: ['projects'], queryFn: () => listProjects() })
 
   if (draft.kind === 'unsupported') {
     return (
@@ -319,8 +319,8 @@ const CalendarCard = ({
 }: CalendarCardProps) => {
   const { t } = useTranslation()
   const { user } = useAuth()
-  const spheres = useQuery({ queryKey: ['spheres'], queryFn: listSpheres })
-  const projects = useQuery({ queryKey: ['projects'], queryFn: listProjects })
+  const spheres = useQuery({ queryKey: ['spheres'], queryFn: () => listSpheres() })
+  const projects = useQuery({ queryKey: ['projects'], queryFn: () => listProjects() })
 
   // Independent (multi-open) section state, matching old-focal: opening one section does not
   // close the others.
@@ -838,14 +838,17 @@ export const CalendarsPage = () => {
   const sidebar = useSidebarOptional()
   const queryClient = useQueryClient()
 
-  const mine = useQuery({ queryKey: ['shared-calendars', 'mine'], queryFn: listMyCalendars })
+  const mine = useQuery({
+    queryKey: ['shared-calendars', 'mine'],
+    queryFn: () => listMyCalendars(),
+  })
   const accessible = useQuery({
     queryKey: ['shared-calendars', 'accessible'],
-    queryFn: listAccessibleCalendars,
+    queryFn: () => listAccessibleCalendars(),
   })
   const myParticipation = useQuery({
     queryKey: ['shared-calendars', 'my-participation'],
-    queryFn: listMyParticipation,
+    queryFn: () => listMyParticipation(),
   })
 
   const [message, setMessage] = useState<string | null>(null)
diff --git a/apps/focal/client/src/features/events/EventsPage.test.tsx b/apps/focal/client/src/features/events/EventsPage.test.tsx
index b7cf641..9c46f8f 100644
--- a/apps/focal/client/src/features/events/EventsPage.test.tsx
+++ b/apps/focal/client/src/features/events/EventsPage.test.tsx
@@ -168,7 +168,7 @@ describe('EventsPage', () => {
     renderPage()
 
     expect(await screen.findByText('Quarterly review')).toBeInTheDocument()
-    expect(mocked.listEvents).toHaveBeenCalledWith(monthStart, monthEnd)
+    expect(mocked.listEvents).toHaveBeenCalledWith(monthStart, monthEnd, null)
     expect(screen.getByText(tr('focal.events.upcomingEvents'))).toBeInTheDocument()
     expect(screen.getByText(tr('focal.events.projectType.mission'))).toBeInTheDocument()
     expect(screen.getByText(tr('focal.events.status.confirmed'))).toBeInTheDocument()
@@ -250,7 +250,9 @@ describe('EventsPage', () => {
     ])
     renderPage()
 
-    await waitFor(() => expect(mocked.listEvents).toHaveBeenCalledWith('2026-06-10', '2026-06-12'))
+    await waitFor(() =>
+      expect(mocked.listEvents).toHaveBeenCalledWith('2026-06-10', '2026-06-12', null),
+    )
     expect(await screen.findByText('Inside range')).toBeInTheDocument()
     expect(screen.queryByText('Outside range')).not.toBeInTheDocument()
   })
@@ -340,15 +342,18 @@ describe('EventsPage', () => {
     await user.click(screen.getByRole('button', { name: tr('focal.calendar.form.submit') }))
 
     await waitFor(() =>
-      expect(mocked.createEvent).toHaveBeenCalledWith({
-        title: 'Review',
-        date: todayIso,
-        startTime: '09:00',
-        endTime: '10:00',
-        status: 'planned',
-        completed: false,
-        recurrence: 'none',
-      }),
+      expect(mocked.createEvent).toHaveBeenCalledWith(
+        {
+          title: 'Review',
+          date: todayIso,
+          startTime: '09:00',
+          endTime: '10:00',
+          status: 'planned',
+          completed: false,
+          recurrence: 'none',
+        },
+        null,
+      ),
     )
     await waitFor(() => expect(invalidate).toHaveBeenCalledWith({ queryKey: ['events'] }))
   })
@@ -407,7 +412,7 @@ describe('EventsPage', () => {
     await openEditPopover(user, 'Standup')
     await user.click(screen.getByRole('button', { name: tr('focal.calendar.edit.delete') }))
 
-    await waitFor(() => expect(mocked.deleteEvent).toHaveBeenCalledWith('e1', undefined))
+    await waitFor(() => expect(mocked.deleteEvent).toHaveBeenCalledWith('e1', undefined, null))
   })
 
   it('deletes a non-recurring event from the row delete action', async () => {
@@ -421,7 +426,7 @@ describe('EventsPage', () => {
       screen.getByRole('button', { name: tr('focal.events.actions.delete', { title: 'Standup' }) }),
     )
 
-    await waitFor(() => expect(mocked.deleteEvent).toHaveBeenCalledWith('e1', undefined))
+    await waitFor(() => expect(mocked.deleteEvent).toHaveBeenCalledWith('e1', undefined, null))
   })
 
   it('routes a recurring row delete through the scope dialog before deleting', async () => {
@@ -486,6 +491,7 @@ describe('EventsPage', () => {
         'r1',
         expect.objectContaining({ title: 'Weekly sync (new)', recurrence: 'weekly' }),
         { scope: 'following', occurrenceDate: todayIso },
+        null,
       ),
     )
   })
@@ -512,10 +518,14 @@ describe('EventsPage', () => {
     await user.click(screen.getByRole('button', { name: tr('focal.calendar.scopeDialog.confirm') }))
 
     await waitFor(() =>
-      expect(mocked.deleteEvent).toHaveBeenCalledWith('r2', {
-        scope: 'all',
-        occurrenceDate: todayIso,
-      }),
+      expect(mocked.deleteEvent).toHaveBeenCalledWith(
+        'r2',
+        {
+          scope: 'all',
+          occurrenceDate: todayIso,
+        },
+        null,
+      ),
     )
   })
 
diff --git a/apps/focal/client/src/features/events/EventsPage.tsx b/apps/focal/client/src/features/events/EventsPage.tsx
index 909a0ac..b78daf8 100644
--- a/apps/focal/client/src/features/events/EventsPage.tsx
+++ b/apps/focal/client/src/features/events/EventsPage.tsx
@@ -18,6 +18,7 @@ import {
 import { type MouseEvent, useEffect, useMemo, useRef, useState } from 'react'
 import { useTranslation } from 'react-i18next'
 
+import { withCal } from '@/api/queryKeys'
 import { PageHeader } from '@/components/PageHeader'
 import { Badge } from '@/components/ui/badge'
 import { Button } from '@/components/ui/button'
@@ -49,6 +50,7 @@ import { toIsoDate } from '../calendar/dates'
 import { type AnchorSource, type EventDraft, EventPopover } from '../calendar/EventPopover'
 import type { PrimaContact } from '../calendar/primaContacts'
 import { RecurringScopeDialog } from '../calendar/RecurringScopeDialog'
+import { useCalendarFilter } from '../calendars/CalendarFilterContext'
 import {
   activeFiltersCount,
   countOrphans,
@@ -103,6 +105,7 @@ export const EventsPage = () => {
   const { t, i18n } = useTranslation()
   const locale = i18n.resolvedLanguage ?? i18n.language
   const queryClient = useQueryClient()
+  const { currentCalendarId, canEdit, canViewOtherPages } = useCalendarFilter()
 
   const todayYmd = toIsoDate(new Date())
 
@@ -114,18 +117,30 @@ export const EventsPage = () => {
     saveEventFilters(filters)
   }, [filters])
 
-  // Deferred: old-focal scoped this query by CalendarFilterContext (dataOwnerId / currentCalendarId)
-  // to view a shared calendar. The new app has no such context yet, so the page shows the signed-in
-  // user's own events and never sends a client-supplied userId/calendarId — flagged, not faked.
   const range = useMemo(() => eventsQueryRange(filters, todayYmd), [filters, todayYmd])
   const eventsQuery = useQuery({
-    queryKey: ['events', range.startDate, range.endDate],
-    queryFn: () => listEvents(range.startDate, range.endDate),
+    queryKey: withCal(['events', range.startDate, range.endDate], currentCalendarId),
+    queryFn: () => listEvents(range.startDate, range.endDate, currentCalendarId),
   })
 
-  const projectsQuery = useQuery({ queryKey: ['projects'], queryFn: listProjects })
-  const activitiesQuery = useQuery({ queryKey: ['activities'], queryFn: listActivities })
-  const tagsQuery = useQuery({ queryKey: ['tags'], queryFn: listTags })
+  // Reference-data queries hit other-pages domains; gate them so a participant without other-pages
+  // access doesn't fire a 403 (own/main calendar is unaffected — currentCalendarId is null there).
+  const referenceEnabled = currentCalendarId === null || canViewOtherPages
+  const projectsQuery = useQuery({
+    queryKey: withCal(['projects'], currentCalendarId),
+    queryFn: () => listProjects(currentCalendarId),
+    enabled: referenceEnabled,
+  })
+  const activitiesQuery = useQuery({
+    queryKey: withCal(['activities'], currentCalendarId),
+    queryFn: () => listActivities(currentCalendarId),
+    enabled: referenceEnabled,
+  })
+  const tagsQuery = useQuery({
+    queryKey: withCal(['tags'], currentCalendarId),
+    queryFn: () => listTags(currentCalendarId),
+    enabled: referenceEnabled,
+  })
   // Surface a localized notice when a filter-option list fails to load; the events list still
   // renders, and the product/activity selects additionally disable when their option list is empty.
   const optionsError = projectsQuery.isError || activitiesQuery.isError || tagsQuery.isError
@@ -219,7 +234,7 @@ export const EventsPage = () => {
   }
 
   const createMutation = useMutation({
-    mutationFn: (input: EventCreate) => createEvent(input),
+    mutationFn: (input: EventCreate) => createEvent(input, currentCalendarId),
     onSuccess: async () => {
       closePopover()
       setParticipants([])
@@ -234,7 +249,7 @@ export const EventsPage = () => {
       event: CalendarEvent
       patch: EventUpdate
       target: RecurrenceTarget | undefined
-    }) => updateEvent(vars.event.id, vars.patch, vars.target),
+    }) => updateEvent(vars.event.id, vars.patch, vars.target, currentCalendarId),
     onSuccess: async () => {
       closePopover()
       setPendingOp(null)
@@ -246,7 +261,7 @@ export const EventsPage = () => {
 
   const deleteMutation = useMutation({
     mutationFn: (vars: { event: CalendarEvent; target: RecurrenceTarget | undefined }) =>
-      deleteEvent(vars.event.id, vars.target),
+      deleteEvent(vars.event.id, vars.target, currentCalendarId),
     onSuccess: async () => {
       closePopover()
       setPendingOp(null)
@@ -286,6 +301,7 @@ export const EventsPage = () => {
   }
 
   const handleSave = () => {
+    if (!canEdit) return
     if (!popover || !draft) return
     // A blank title never reaches the API (old-focal's required-title guard).
     if (!draft.title.trim()) {
@@ -306,6 +322,7 @@ export const EventsPage = () => {
   // Delete an event from anywhere (row action or popover): recurring events route through the scope
   // dialog; one-off events delete immediately (old-focal parity — no extra confirm step).
   const requestDelete = (event: CalendarEvent) => {
+    if (!canEdit) return
     if (isRecurring(event)) setPendingOp({ mode: 'delete', event })
     else deleteMutation.mutate({ event, target: undefined })
   }
@@ -463,6 +480,7 @@ export const EventsPage = () => {
             onClick={(clickEvent: MouseEvent<HTMLButtonElement>) =>
               openEdit(event, clickEvent.currentTarget)
             }
+            disabled={!canEdit}
             aria-label={t('focal.events.actions.edit', { title: event.title })}
             data-testid={`button-edit-event-${event.id}`}
           >
@@ -474,7 +492,10 @@ export const EventsPage = () => {
             variant="ghost"
             className="h-7 w-7"
             onClick={() => requestDelete(event)}
-            disabled={deleteMutation.isPending && deleteMutation.variables?.event.id === event.id}
+            disabled={
+              !canEdit ||
+              (deleteMutation.isPending && deleteMutation.variables?.event.id === event.id)
+            }
             aria-label={t('focal.events.actions.delete', { title: event.title })}
             data-testid={`button-delete-event-${event.id}`}
           >
@@ -515,6 +536,7 @@ export const EventsPage = () => {
               size="sm"
               className="gap-1"
               onClick={openCreate}
+              disabled={!canEdit}
             >
               <Plus className="h-4 w-4" aria-hidden="true" />
               {t('focal.events.add')}
@@ -587,6 +609,12 @@ export const EventsPage = () => {
 
       <div className="flex-1 overflow-auto p-4 md:p-6">
         <div className="mx-auto max-w-4xl space-y-6">
+          {!canEdit && (
+            <p className="rounded-md border bg-muted/40 px-3 py-2 text-muted-foreground text-sm">
+              {t('focal.app.calendarFilter.readOnlyNotice')}
+            </p>
+          )}
+
           {showFilters && (
             <Card className="bg-muted/30">
               <CardContent className="space-y-2 p-3">
@@ -848,6 +876,7 @@ export const EventsPage = () => {
           anchor={popover.anchor}
           draft={draft}
           recurring={popover.event ? isRecurring(popover.event) : false}
+          readOnly={!canEdit}
           participants={participants}
           isSaving={createMutation.isPending || updateMutation.isPending}
           isDeleting={deleteMutation.isPending}
diff --git a/apps/focal/client/src/features/goals/ActivityEditModal.tsx b/apps/focal/client/src/features/goals/ActivityEditModal.tsx
index 97b4880..2b2736a 100644
--- a/apps/focal/client/src/features/goals/ActivityEditModal.tsx
+++ b/apps/focal/client/src/features/goals/ActivityEditModal.tsx
@@ -30,12 +30,21 @@ const COLORS = [
 
 interface ActivityEditModalProps {
   activity: MindmapInit['activities'][number]
+  /** The active shared-calendar scope (null = own data) threaded into the write wrappers. */
+  calendarId: string | null
+  /** False on a read-only shared calendar — disables Save/Delete (the modal stays viewable). */
+  canEdit: boolean
   onClose: () => void
 }
 
 /** The edit dialog for an activity (leaf) node: name + colour, plus delete. Self-contained — it owns
  * its own mutations and refreshes the mindmap (`mindmap-init`) cache on change. */
-export const ActivityEditModal = ({ activity, onClose }: ActivityEditModalProps) => {
+export const ActivityEditModal = ({
+  activity,
+  calendarId,
+  canEdit,
+  onClose,
+}: ActivityEditModalProps) => {
   const { t } = useTranslation()
   const queryClient = useQueryClient()
   const nameId = useId()
@@ -46,14 +55,14 @@ export const ActivityEditModal = ({ activity, onClose }: ActivityEditModalProps)
 
   const refresh = () => queryClient.invalidateQueries({ queryKey: ['mindmap-init'] })
   const save = useMutation({
-    mutationFn: () => updateActivity(activity.id, name, color),
+    mutationFn: () => updateActivity(activity.id, name, color, calendarId),
     onSuccess: async () => {
       await refresh()
       onClose()
     },
   })
   const remove = useMutation({
-    mutationFn: () => deleteActivity(activity.id),
+    mutationFn: () => deleteActivity(activity.id, calendarId),
     onSuccess: async () => {
       await refresh()
       onClose()
@@ -61,6 +70,15 @@ export const ActivityEditModal = ({ activity, onClose }: ActivityEditModalProps)
   })
   const busy = save.isPending || remove.isPending
 
+  const onSave = () => {
+    if (!canEdit) return
+    save.mutate()
+  }
+  const onRemove = () => {
+    if (!canEdit) return
+    remove.mutate()
+  }
+
   return (
     <Dialog
       open
@@ -109,8 +127,8 @@ export const ActivityEditModal = ({ activity, onClose }: ActivityEditModalProps)
               <Button
                 type="button"
                 variant="destructive"
-                disabled={busy}
-                onClick={() => remove.mutate()}
+                disabled={busy || !canEdit}
+                onClick={onRemove}
               >
                 {t('focal.goals.edit.confirmDelete')}
               </Button>
@@ -123,12 +141,13 @@ export const ActivityEditModal = ({ activity, onClose }: ActivityEditModalProps)
               type="button"
               variant="ghost"
               className="text-destructive hover:text-destructive"
+              disabled={!canEdit}
               onClick={() => setConfirmingDelete(true)}
             >
               {t('focal.goals.activityEdit.delete')}
             </Button>
           )}
-          <Button type="button" disabled={busy} onClick={() => save.mutate()}>
+          <Button type="button" disabled={busy || !canEdit} onClick={onSave}>
             {t('focal.goals.edit.save')}
           </Button>
         </DialogFooter>
diff --git a/apps/focal/client/src/features/goals/FocalNode.test.tsx b/apps/focal/client/src/features/goals/FocalNode.test.tsx
index 4a5700e..7610b17 100644
--- a/apps/focal/client/src/features/goals/FocalNode.test.tsx
+++ b/apps/focal/client/src/features/goals/FocalNode.test.tsx
@@ -31,6 +31,7 @@ const handlers: GoalsContextValue = {
   onAddProject: vi.fn(),
   onAddChild: vi.fn(),
   onResizeNode: vi.fn(),
+  canEdit: true,
 }
 
 const renderNode = (data: FocalNodeData) =>
diff --git a/apps/focal/client/src/features/goals/FocalNode.tsx b/apps/focal/client/src/features/goals/FocalNode.tsx
index c5c7631..4fa7f66 100644
--- a/apps/focal/client/src/features/goals/FocalNode.tsx
+++ b/apps/focal/client/src/features/goals/FocalNode.tsx
@@ -34,6 +34,7 @@ export const FocalNode = ({ id, data }: NodeProps<FocalNodeType>) => {
   const Icon = projectIcon(data.icon)
   const color = data.color
   const goalTier = tier(data)
+  const canEdit = goals?.canEdit ?? true
   const stripColor = priorityStripColor(data.priority)
   const showWorkPill = !data.isActivity && (data.isWorkTime != null || data.sphere != null)
   const showActivityDates = !!data.isActivity && (!!data.startDate || !!data.endDate)
@@ -48,7 +49,7 @@ export const FocalNode = ({ id, data }: NodeProps<FocalNodeType>) => {
           size. */}
       <NodeResizer
         color="#3b82f6"
-        isVisible
+        isVisible={canEdit}
         minWidth={140}
         minHeight={56}
         onResizeEnd={(_event, params) => goals?.onResizeNode?.(id, params.width, params.height)}
@@ -92,7 +93,7 @@ export const FocalNode = ({ id, data }: NodeProps<FocalNodeType>) => {
             {data.description}
           </p>
         )}
-        {pillar && goals && (
+        {pillar && goals && canEdit && (
           <button
             type="button"
             className={`mt-2 ${ADD_BUTTON_CLASS}`}
@@ -104,7 +105,7 @@ export const FocalNode = ({ id, data }: NodeProps<FocalNodeType>) => {
             {t(pillar.earning ? 'focal.goals.add.earningButton' : 'focal.goals.add.button')}
           </button>
         )}
-        {addChild && goals && (
+        {addChild && goals && canEdit && (
           <button
             type="button"
             className={`mt-2 ${ADD_BUTTON_CLASS}`}
diff --git a/apps/focal/client/src/features/goals/GoalsPage.tsx b/apps/focal/client/src/features/goals/GoalsPage.tsx
index 2118269..160841c 100644
--- a/apps/focal/client/src/features/goals/GoalsPage.tsx
+++ b/apps/focal/client/src/features/goals/GoalsPage.tsx
@@ -15,6 +15,7 @@ import { ArrowDown, ArrowRight, ChevronDown, Redo2, Undo2 } from 'lucide-react'
 import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
 import { useTranslation } from 'react-i18next'
 
+import { withCal } from '@/api/queryKeys'
 import { PageHeader } from '@/components/PageHeader'
 import { Button } from '@/components/ui/button'
 import {
@@ -24,6 +25,7 @@ import {
   DropdownMenuLabel,
   DropdownMenuTrigger,
 } from '@/components/ui/dropdown-menu'
+import { useCalendarFilter } from '@/features/calendars/CalendarFilterContext'
 import {
   createActivity,
   createProduct,
@@ -59,7 +61,11 @@ const edgeTypes = { floating: FloatingEdge }
 export const GoalsPage = () => {
   const { t } = useTranslation()
   const queryClient = useQueryClient()
-  const init = useQuery({ queryKey: ['mindmap-init'], queryFn: getMindmapInit })
+  const { currentCalendarId, canEdit } = useCalendarFilter()
+  const init = useQuery({
+    queryKey: withCal(['mindmap-init'], currentCalendarId),
+    queryFn: () => getMindmapInit(currentCalendarId),
+  })
 
   const [nodes, setNodes, onNodesChange] = useNodesState<FocalNodeType>([])
   const [edges, setEdges, onEdgesChange] = useEdgesState<Edge>([])
@@ -130,43 +136,48 @@ export const GoalsPage = () => {
         setCreateChild({ kind, parentId, label: parentLabel })
       },
       onResizeNode: (id, width, height) => {
+        if (!canEdit) return
         // Persist the new size fire-and-forget — the canvas already shows it (NodeResizer +
         // onNodesChange updated the live node dimensions during the drag).
-        void saveNodeSize(id, width, height)
+        void saveNodeSize(id, width, height, currentCalendarId)
         // Mirror it into the cached payload (like the move mutation) so a remount within staleTime
         // reopens at the resized size: merge into the node's overlay row, or append a fresh one
         // (the size override is keyed off init.nodes by the xyflow node id).
-        queryClient.setQueryData<MindmapInit>(['mindmap-init'], (current) => {
-          if (!current) return current
-          const existing = current.nodes.find((node) => node.id === id)
-          if (existing) {
-            return {
-              ...current,
-              nodes: current.nodes.map((node) =>
-                node.id === id ? { ...node, width, height } : node,
-              ),
+        queryClient.setQueryData<MindmapInit>(
+          withCal(['mindmap-init'], currentCalendarId),
+          (current) => {
+            if (!current) return current
+            const existing = current.nodes.find((node) => node.id === id)
+            if (existing) {
+              return {
+                ...current,
+                nodes: current.nodes.map((node) =>
+                  node.id === id ? { ...node, width, height } : node,
+                ),
+              }
             }
-          }
-          const row: MindmapInit['nodes'][number] = {
-            id,
-            userId: '',
-            positionX: null,
-            positionY: null,
-            width,
-            height,
-            label: null,
-            description: null,
-            fullDescription: null,
-            customColor: null,
-            nodeData: null,
-            createdAt: '',
-            updatedAt: '',
-          }
-          return { ...current, nodes: [...current.nodes, row] }
-        })
+            const row: MindmapInit['nodes'][number] = {
+              id,
+              userId: '',
+              positionX: null,
+              positionY: null,
+              width,
+              height,
+              label: null,
+              description: null,
+              fullDescription: null,
+              customColor: null,
+              nodeData: null,
+              createdAt: '',
+              updatedAt: '',
+            }
+            return { ...current, nodes: [...current.nodes, row] }
+          },
+        )
       },
+      canEdit,
     }),
-    [queryClient],
+    [queryClient, currentCalendarId, canEdit],
   )
 
   // Rebuild the graph whenever the payload changes; xyflow then owns the live node/edge state
@@ -196,7 +207,7 @@ export const GoalsPage = () => {
             : target.kind === 'activity'
               ? moveActivity
               : moveNode
-        void persist(target.id, node.position.x, node.position.y)
+        void persist(target.id, node.position.x, node.position.y, currentCalendarId)
       }
       return
     }
@@ -213,16 +224,16 @@ export const GoalsPage = () => {
       }),
     )
     setEdges(graph.edges)
-  }, [init.data, label, describe, setNodes, setEdges])
+  }, [init.data, label, describe, setNodes, setEdges, currentCalendarId])
 
   const invalidate = () => queryClient.invalidateQueries({ queryKey: ['mindmap-init'] })
 
   const move = useMutation({
     mutationFn: ({ id, x, y }: { id: string; x: number; y: number }) => {
       const target = parseNodeId(id)
-      if (target.kind === 'project') return moveProject(target.id, x, y)
-      if (target.kind === 'activity') return moveActivity(target.id, x, y)
-      return moveNode(target.id, x, y)
+      if (target.kind === 'project') return moveProject(target.id, x, y, currentCalendarId)
+      if (target.kind === 'activity') return moveActivity(target.id, x, y, currentCalendarId)
+      return moveNode(target.id, x, y, currentCalendarId)
     },
     // Mirror the move into the cached payload so the new position survives a remount: with the 30s
     // staleTime, navigating away and back re-reads the cache without refetching and would otherwise
@@ -230,23 +241,26 @@ export const GoalsPage = () => {
     onMutate: ({ id, x, y }) => {
       const target = parseNodeId(id)
       if (target.kind === 'base') return
-      queryClient.setQueryData<MindmapInit>(['mindmap-init'], (current) => {
-        if (!current) return current
-        if (target.kind === 'project') {
+      queryClient.setQueryData<MindmapInit>(
+        withCal(['mindmap-init'], currentCalendarId),
+        (current) => {
+          if (!current) return current
+          if (target.kind === 'project') {
+            return {
+              ...current,
+              projects: current.projects.map((project) =>
+                project.id === target.id ? { ...project, positionX: x, positionY: y } : project,
+              ),
+            }
+          }
           return {
             ...current,
-            projects: current.projects.map((project) =>
-              project.id === target.id ? { ...project, positionX: x, positionY: y } : project,
+            activities: current.activities.map((activity) =>
+              activity.id === target.id ? { ...activity, positionX: x, positionY: y } : activity,
             ),
           }
-        }
-        return {
-          ...current,
-          activities: current.activities.map((activity) =>
-            activity.id === target.id ? { ...activity, positionX: x, positionY: y } : activity,
-          ),
-        }
-      })
+        },
+      )
     },
     // Base pyramid nodes persist to the mindmap_nodes override (init.nodes), not the project/activity
     // tables — refetch after saving one so a remount reads its saved spot. Projects/activities are
@@ -261,6 +275,7 @@ export const GoalsPage = () => {
   // Apply a position to a node both locally (so the canvas updates outside a drag) and on the
   // server, reusing the move mutation's snap-back-on-error behaviour.
   const moveNodeTo = (id: string, x: number, y: number) => {
+    if (!canEdit) return
     setNodes((current) =>
       current.map((node) => (node.id === id ? { ...node, position: { x, y } } : node)),
     )
@@ -271,6 +286,7 @@ export const GoalsPage = () => {
   // save the tidied positions of the user's own nodes so the arrangement survives a reload (the
   // base pyramid is deterministic scaffolding and has no persistence endpoint).
   const reArrange = (next: LayoutDirection) => {
+    if (!canEdit) return
     directionRef.current = next
     const laid = layoutTree(nodes, edges, next)
     setNodes(laid)
@@ -318,7 +334,7 @@ export const GoalsPage = () => {
     mutationFn: ({ name, parentType }: { name: string; parentType: string }) =>
       // projectType is always 'provision' now: the mission/provision branch concept was retired when
       // Mission became a pure spine — a project belongs to a pillar (parentType), not a branch.
-      createProject(name, 'provision', parentType),
+      createProject(name, 'provision', parentType, currentCalendarId),
     onSuccess: async () => {
       setDialog(null)
       setCreatePillar(null)
@@ -334,7 +350,7 @@ export const GoalsPage = () => {
     }: {
       name: string
       parent: { projectId: string } | { productId: string }
-    }) => createActivity(name, parent),
+    }) => createActivity(name, parent, currentCalendarId),
     onSuccess: async () => {
       setDialog(null)
       setCreateChild(null)
@@ -345,7 +361,7 @@ export const GoalsPage = () => {
 
   const createProductMut = useMutation({
     mutationFn: ({ name, parentProjectId }: { name: string; parentProjectId: string }) =>
-      createProduct(name, parentProjectId),
+      createProduct(name, parentProjectId, currentCalendarId),
     onSuccess: async () => {
       setCreateChild(null)
       arrangeNextRef.current = true
@@ -407,6 +423,7 @@ export const GoalsPage = () => {
               dragStart.current = { id: node.id, x: node.position.x, y: node.position.y }
             }}
             onNodeDragStop={(_event, node) => {
+              if (!canEdit) return
               const start = dragStart.current
               dragStart.current = null
               const moved =
@@ -426,6 +443,7 @@ export const GoalsPage = () => {
             onNodeDoubleClick={(_event, node) => setEditing(node)}
             nodeTypes={nodeTypes}
             edgeTypes={edgeTypes}
+            nodesDraggable={canEdit}
             nodesConnectable={false}
             elementsSelectable={false}
             fitView
@@ -441,7 +459,7 @@ export const GoalsPage = () => {
                 size="icon"
                 variant="outline"
                 onClick={onUndo}
-                disabled={history.undo.length === 0}
+                disabled={history.undo.length === 0 || !canEdit}
                 aria-label={t('focal.goals.history.undo')}
                 title={t('focal.goals.history.undo')}
               >
@@ -452,7 +470,7 @@ export const GoalsPage = () => {
                 size="icon"
                 variant="outline"
                 onClick={onRedo}
-                disabled={history.redo.length === 0}
+                disabled={history.redo.length === 0 || !canEdit}
                 aria-label={t('focal.goals.history.redo')}
                 title={t('focal.goals.history.redo')}
               >
@@ -467,16 +485,21 @@ export const GoalsPage = () => {
                 </DropdownMenuTrigger>
                 <DropdownMenuContent align="start">
                   <DropdownMenuLabel>{t('focal.goals.layout.direction')}</DropdownMenuLabel>
-                  <DropdownMenuItem onSelect={() => reArrange('TB')}>
+                  <DropdownMenuItem disabled={!canEdit} onSelect={() => reArrange('TB')}>
                     <ArrowDown className="h-4 w-4" />
                     {t('focal.goals.layout.topBottom')}
                   </DropdownMenuItem>
-                  <DropdownMenuItem onSelect={() => reArrange('LR')}>
+                  <DropdownMenuItem disabled={!canEdit} onSelect={() => reArrange('LR')}>
                     <ArrowRight className="h-4 w-4" />
                     {t('focal.goals.layout.leftRight')}
                   </DropdownMenuItem>
                 </DropdownMenuContent>
               </DropdownMenu>
+              {!canEdit && (
+                <p className="flex items-center rounded-md border border-border bg-muted/50 px-3 text-sm text-muted-foreground">
+                  {t('focal.app.calendarFilter.readOnlyNotice')}
+                </p>
+              )}
             </Panel>
             <Background
               variant={BackgroundVariant.Dots}
@@ -539,16 +562,26 @@ export const GoalsPage = () => {
         <ProjectEditModal
           key={editing.id}
           project={editingProject}
+          calendarId={currentCalendarId}
+          canEdit={canEdit}
           onClose={() => setEditing(null)}
         />
       )}
       {editing && editingTarget?.kind === 'base' && (
-        <NodeEditModal key={editing.id} node={editing} onClose={() => setEditing(null)} />
+        <NodeEditModal
+          key={editing.id}
+          node={editing}
+          calendarId={currentCalendarId}
+          canEdit={canEdit}
+          onClose={() => setEditing(null)}
+        />
       )}
       {editing && editingTarget?.kind === 'activity' && editingActivity && (
         <ActivityEditModal
           key={editing.id}
           activity={editingActivity}
+          calendarId={currentCalendarId}
+          canEdit={canEdit}
           onClose={() => setEditing(null)}
         />
       )}
diff --git a/apps/focal/client/src/features/goals/NodeEditModal.tsx b/apps/focal/client/src/features/goals/NodeEditModal.tsx
index b47608f..0e52e4a 100644
--- a/apps/focal/client/src/features/goals/NodeEditModal.tsx
+++ b/apps/focal/client/src/features/goals/NodeEditModal.tsx
@@ -3,6 +3,7 @@ import { Check, Lock } from 'lucide-react'
 import { useId, useState } from 'react'
 import { useTranslation } from 'react-i18next'
 
+import { withCal } from '@/api/queryKeys'
 import { Button } from '@/components/ui/button'
 import {
   Dialog,
@@ -32,20 +33,24 @@ const COLORS = [
 
 interface NodeEditModalProps {
   node: FocalNodeType
+  /** The active shared-calendar scope (null = own data) threaded into the cache read + write. */
+  calendarId: string | null
+  /** False on a read-only shared calendar — disables Save (the modal stays viewable). */
+  canEdit: boolean
   onClose: () => void
 }
 
 /** The edit dialog for a base/structural pyramid node (Цель жизни, Миссия, the four pillars). Edits
  * the node's label, description, colour and icon — persisted as a mindmap_nodes override. Base nodes
  * are fixed scaffolding, so there is no delete (a locked note explains why). */
-export const NodeEditModal = ({ node, onClose }: NodeEditModalProps) => {
+export const NodeEditModal = ({ node, calendarId, canEdit, onClose }: NodeEditModalProps) => {
   const { t } = useTranslation()
   const queryClient = useQueryClient()
   const titleId = useId()
   const descId = useId()
 
   // The description isn't carried on the canvas node — read the saved override from the init cache.
-  const init = queryClient.getQueryData<MindmapInit>(['mindmap-init'])
+  const init = queryClient.getQueryData<MindmapInit>(withCal(['mindmap-init'], calendarId))
   const saved = init?.nodes.find((entry) => entry.id === node.id)
 
   const [label, setLabel] = useState(node.data.label)
@@ -55,19 +60,28 @@ export const NodeEditModal = ({ node, onClose }: NodeEditModalProps) => {
 
   const save = useMutation({
     mutationFn: () =>
-      updateNode(node.id, {
-        label,
-        description: description || null,
-        customColor: color,
-        // A custom lucide icon replaces the built-in emoji glyph; clearing it removes the override.
-        nodeData: icon ? { icon } : {},
-      }),
+      updateNode(
+        node.id,
+        {
+          label,
+          description: description || null,
+          customColor: color,
+          // A custom lucide icon replaces the built-in emoji glyph; clearing it removes the override.
+          nodeData: icon ? { icon } : {},
+        },
+        calendarId,
+      ),
     onSuccess: async () => {
       await queryClient.invalidateQueries({ queryKey: ['mindmap-init'] })
       onClose()
     },
   })
 
+  const onSave = () => {
+    if (!canEdit) return
+    save.mutate()
+  }
+
   return (
     <Dialog
       open
@@ -169,7 +183,7 @@ export const NodeEditModal = ({ node, onClose }: NodeEditModalProps) => {
           <Button type="button" variant="ghost" onClick={onClose}>
             {t('focal.goals.nodeEdit.cancel')}
           </Button>
-          <Button type="button" disabled={save.isPending} onClick={() => save.mutate()}>
+          <Button type="button" disabled={save.isPending || !canEdit} onClick={onSave}>
             {t('focal.goals.nodeEdit.save')}
           </Button>
         </DialogFooter>
diff --git a/apps/focal/client/src/features/goals/ProjectEditModal.tsx b/apps/focal/client/src/features/goals/ProjectEditModal.tsx
index e1dc99a..01d7fe2 100644
--- a/apps/focal/client/src/features/goals/ProjectEditModal.tsx
+++ b/apps/focal/client/src/features/goals/ProjectEditModal.tsx
@@ -3,6 +3,7 @@ import { Check } from 'lucide-react'
 import { useId, useState } from 'react'
 import { useTranslation } from 'react-i18next'
 
+import { withCal } from '@/api/queryKeys'
 import { Button } from '@/components/ui/button'
 import {
   Dialog,
@@ -42,12 +43,21 @@ const PRIORITIES = ['low', 'medium', 'high'] as const
 
 interface ProjectEditModalProps {
   project: Project
+  /** The active shared-calendar scope (null = own data) threaded into the read/write wrappers. */
+  calendarId: string | null
+  /** False on a read-only shared calendar — disables Save/Delete (the modal stays viewable). */
+  canEdit: boolean
   onClose: () => void
 }
 
 /** The edit dialog for a project node: core fields, an icon picker, and a colour. Self-contained —
  * it owns its own save/delete mutations and refreshes the mindmap (`mindmap-init`) cache on change. */
-export const ProjectEditModal = ({ project, onClose }: ProjectEditModalProps) => {
+export const ProjectEditModal = ({
+  project,
+  calendarId,
+  canEdit,
+  onClose,
+}: ProjectEditModalProps) => {
   const { t } = useTranslation()
   const queryClient = useQueryClient()
   const titleId = useId()
@@ -62,23 +72,30 @@ export const ProjectEditModal = ({ project, onClose }: ProjectEditModalProps) =>
   const [color, setColor] = useState(project.color ?? COLORS[0])
   const [confirmingDelete, setConfirmingDelete] = useState(false)
 
-  const spheresQuery = useQuery({ queryKey: ['spheres'], queryFn: listSpheres })
+  const spheresQuery = useQuery({
+    queryKey: withCal(['spheres'], calendarId),
+    queryFn: () => listSpheres(calendarId),
+  })
 
   const refreshMindmap = () => queryClient.invalidateQueries({ queryKey: ['mindmap-init'] })
 
   const save = useMutation({
     mutationFn: () =>
-      updateProject(project.id, {
-        name,
-        priority,
-        isWorkTime,
-        // Work-time projects carry no sphere (the legacy work-time rule); a non-work project keeps
-        // an optional sphere.
-        sphere: isWorkTime ? null : sphere || null,
-        description: description || null,
-        icon,
-        color,
-      }),
+      updateProject(
+        project.id,
+        {
+          name,
+          priority,
+          isWorkTime,
+          // Work-time projects carry no sphere (the legacy work-time rule); a non-work project keeps
+          // an optional sphere.
+          sphere: isWorkTime ? null : sphere || null,
+          description: description || null,
+          icon,
+          color,
+        },
+        calendarId,
+      ),
     onSuccess: async () => {
       await refreshMindmap()
       onClose()
@@ -86,7 +103,7 @@ export const ProjectEditModal = ({ project, onClose }: ProjectEditModalProps) =>
   })
 
   const remove = useMutation({
-    mutationFn: () => deleteProject(project.id),
+    mutationFn: () => deleteProject(project.id, calendarId),
     onSuccess: async () => {
       await refreshMindmap()
       onClose()
@@ -96,6 +113,15 @@ export const ProjectEditModal = ({ project, onClose }: ProjectEditModalProps) =>
   const spheres = spheresQuery.data ?? []
   const busy = save.isPending || remove.isPending
 
+  const onSave = () => {
+    if (!canEdit) return
+    save.mutate()
+  }
+  const onRemove = () => {
+    if (!canEdit) return
+    remove.mutate()
+  }
+
   return (
     <Dialog
       open
@@ -236,8 +262,8 @@ export const ProjectEditModal = ({ project, onClose }: ProjectEditModalProps) =>
               <Button
                 type="button"
                 variant="destructive"
-                disabled={busy}
-                onClick={() => remove.mutate()}
+                disabled={busy || !canEdit}
+                onClick={onRemove}
               >
                 {t('focal.goals.edit.confirmDelete')}
               </Button>
@@ -250,12 +276,13 @@ export const ProjectEditModal = ({ project, onClose }: ProjectEditModalProps) =>
               type="button"
               variant="ghost"
               className="text-destructive hover:text-destructive"
+              disabled={!canEdit}
               onClick={() => setConfirmingDelete(true)}
             >
               {t('focal.goals.edit.delete')}
             </Button>
           )}
-          <Button type="button" disabled={busy} onClick={() => save.mutate()}>
+          <Button type="button" disabled={busy || !canEdit} onClick={onSave}>
             {t('focal.goals.edit.save')}
           </Button>
         </DialogFooter>
diff --git a/apps/focal/client/src/features/goals/goalsContext.ts b/apps/focal/client/src/features/goals/goalsContext.ts
index c87fe09..ebc2e18 100644
--- a/apps/focal/client/src/features/goals/goalsContext.ts
+++ b/apps/focal/client/src/features/goals/goalsContext.ts
@@ -13,6 +13,9 @@ export interface GoalsContextValue {
   /** Persist a node's resized dimensions (fired by the on-card NodeResizer when a drag ends). `id` is
    * the xyflow node id (= the mindmap_nodes key); the page writes it through and mirrors the cache. */
   onResizeNode: (id: string, width: number, height: number) => void
+  /** Whether the active calendar may be edited. False on a read-only shared calendar hides the
+   * on-card "+ child" buttons and the resize affordance (true on the own/main calendar). */
+  canEdit: boolean
 }
 
 export const GoalsContext = createContext<GoalsContextValue | null>(null)
diff --git a/apps/focal/client/src/features/habits/HabitCharts.tsx b/apps/focal/client/src/features/habits/HabitCharts.tsx
index c7b7180..6bd9018 100644
--- a/apps/focal/client/src/features/habits/HabitCharts.tsx
+++ b/apps/focal/client/src/features/habits/HabitCharts.tsx
@@ -13,6 +13,7 @@ import {
   YAxis,
 } from 'recharts'
 
+import { withCal } from '@/api/queryKeys'
 import { Button } from '@/components/ui/button'
 import {
   Select,
@@ -30,6 +31,7 @@ import {
   TableHeader,
   TableRow,
 } from '@/components/ui/table'
+import { useCalendarFilter } from '@/features/calendars/CalendarFilterContext'
 import { cn } from '@/lib/utils'
 
 import { listHabitEntryStats, listHabits } from '../../api/habits'
@@ -59,6 +61,7 @@ interface ChartTooltipProps {
 
 export const HabitCharts = () => {
   const { t } = useTranslation()
+  const { currentCalendarId } = useCalendarFilter()
   const monthNames = useMemo(
     () => t('focal.habits.monthNamesShort', { returnObjects: true }) as string[],
     [t],
@@ -85,10 +88,17 @@ export const HabitCharts = () => {
   const periodStart = formatDateStr(subtractPeriod(now, config))
   const periodEnd = formatDateStr(now)
 
-  const habitsQuery = useQuery({ queryKey: HABITS_KEY, queryFn: () => listHabits() })
+  const habitsQuery = useQuery({
+    queryKey: withCal(HABITS_KEY, currentCalendarId),
+    queryFn: () => listHabits(false, currentCalendarId),
+  })
   const statsQuery = useQuery({
-    queryKey: [...HABITS_KEY, 'stats', periodStart, periodEnd, config.granularity],
-    queryFn: () => listHabitEntryStats(periodStart, periodEnd, config.granularity),
+    queryKey: withCal(
+      [...HABITS_KEY, 'stats', periodStart, periodEnd, config.granularity],
+      currentCalendarId,
+    ),
+    queryFn: () =>
+      listHabitEntryStats(periodStart, periodEnd, config.granularity, currentCalendarId),
   })
 
   const habits = habitsQuery.data ?? []
diff --git a/apps/focal/client/src/features/habits/HabitCreateDialog.tsx b/apps/focal/client/src/features/habits/HabitCreateDialog.tsx
index 21dff08..063c014 100644
--- a/apps/focal/client/src/features/habits/HabitCreateDialog.tsx
+++ b/apps/focal/client/src/features/habits/HabitCreateDialog.tsx
@@ -47,6 +47,10 @@ const clampTargetDays = (value: number): number =>
 interface HabitCreateDialogProps {
   open: boolean
   onOpenChange: (open: boolean) => void
+  /** Active calendar scope — the new habit targets this calendar's owner (null = own/main). */
+  calendarId: string | null
+  /** Whether the viewer may create on the active calendar; false disables submit. */
+  canEdit: boolean
   /** sortOrder for the new habit — the current active-habit count from the controller. */
   sortOrder: number
   /** Invalidate the shared habits queries + clear the page error banner. */
@@ -58,6 +62,8 @@ interface HabitCreateDialogProps {
 export const HabitCreateDialog = ({
   open,
   onOpenChange,
+  calendarId,
+  canEdit,
   sortOrder,
   onCreated,
   onError,
@@ -79,7 +85,7 @@ export const HabitCreateDialog = ({
   }
 
   const createMutation = useMutation({
-    mutationFn: (input: HabitCreate) => createHabit(input),
+    mutationFn: (input: HabitCreate) => createHabit(input, calendarId),
     onSuccess: async () => {
       reset()
       onOpenChange(false)
@@ -91,6 +97,7 @@ export const HabitCreateDialog = ({
   const trimmed = name.trim()
 
   const submit = () => {
+    if (!canEdit) return
     if (!trimmed) return
     createMutation.mutate({
       name,
@@ -224,7 +231,11 @@ export const HabitCreateDialog = ({
           >
             {t('focal.habits.dialog.cancel')}
           </Button>
-          <Button type="button" onClick={submit} disabled={!trimmed || createMutation.isPending}>
+          <Button
+            type="button"
+            onClick={submit}
+            disabled={!canEdit || !trimmed || createMutation.isPending}
+          >
             {t('focal.habits.dialog.submit')}
           </Button>
         </DialogFooter>
diff --git a/apps/focal/client/src/features/habits/HabitJournal.tsx b/apps/focal/client/src/features/habits/HabitJournal.tsx
index 62c0936..ccee70d 100644
--- a/apps/focal/client/src/features/habits/HabitJournal.tsx
+++ b/apps/focal/client/src/features/habits/HabitJournal.tsx
@@ -11,8 +11,10 @@ import {
 import { useMemo, useState } from 'react'
 import { useTranslation } from 'react-i18next'
 
+import { withCal } from '@/api/queryKeys'
 import { Button } from '@/components/ui/button'
 import { Skeleton } from '@/components/ui/skeleton'
+import { useCalendarFilter } from '@/features/calendars/CalendarFilterContext'
 import { cn } from '@/lib/utils'
 
 import {
@@ -60,6 +62,7 @@ interface HabitJournalProps {
 
 export const HabitJournal = ({ onMutationError, onMutationSuccess }: HabitJournalProps) => {
   const { t } = useTranslation()
+  const { currentCalendarId, canEdit } = useCalendarFilter()
 
   const dayNames = [
     t('focal.habits.dayNames.sun'),
@@ -81,19 +84,22 @@ export const HabitJournal = ({ onMutationError, onMutationSuccess }: HabitJourna
   const weekEnd = days[days.length - 1] ?? todayIso
   const anchorIso = toIsoDate(anchor)
 
-  const habits = useQuery({ queryKey: HABITS_KEY, queryFn: () => listHabits() })
+  const habits = useQuery({
+    queryKey: withCal(HABITS_KEY, currentCalendarId),
+    queryFn: () => listHabits(false, currentCalendarId),
+  })
   const archived = useQuery({
-    queryKey: [...HABITS_KEY, 'archived'],
-    queryFn: () => listHabits(true),
+    queryKey: withCal([...HABITS_KEY, 'archived'], currentCalendarId),
+    queryFn: () => listHabits(true, currentCalendarId),
     enabled: showArchived,
   })
   const streaks = useQuery({
-    queryKey: [...HABITS_KEY, 'streaks', todayIso],
-    queryFn: () => listStreaks(todayIso),
+    queryKey: withCal([...HABITS_KEY, 'streaks', todayIso], currentCalendarId),
+    queryFn: () => listStreaks(todayIso, currentCalendarId),
   })
   const entries = useQuery({
-    queryKey: [...HABITS_KEY, 'entries', weekStart, weekEnd],
-    queryFn: () => listEntries(weekStart, weekEnd),
+    queryKey: withCal([...HABITS_KEY, 'entries', weekStart, weekEnd], currentCalendarId),
+    queryFn: () => listEntries(weekStart, weekEnd, currentCalendarId),
   })
 
   const onSuccess = () => onMutationSuccess()
@@ -104,8 +110,11 @@ export const HabitJournal = ({ onMutationError, onMutationSuccess }: HabitJourna
       // null is the cycle's "clear the entry" sentinel — distinct from an unknown status,
       // which falls back to starting the cycle at "yes".
       const next = NEXT_STATUS[vars.current]
-      if (next === null) return deleteEntry(vars.habitId, vars.date)
-      return upsertEntry({ habitId: vars.habitId, date: vars.date, status: next ?? 'yes' })
+      if (next === null) return deleteEntry(vars.habitId, vars.date, currentCalendarId)
+      return upsertEntry(
+        { habitId: vars.habitId, date: vars.date, status: next ?? 'yes' },
+        currentCalendarId,
+      )
     },
     onSuccess,
     onError,
@@ -114,20 +123,20 @@ export const HabitJournal = ({ onMutationError, onMutationSuccess }: HabitJourna
   const archiveMutation = useMutation({
     mutationFn: (vars: { habit: Habit; archive: boolean }) =>
       vars.archive
-        ? updateHabit(vars.habit.id, { isArchived: true }).then(() => undefined)
-        : restoreHabit(vars.habit.id).then(() => undefined),
+        ? updateHabit(vars.habit.id, { isArchived: true }, currentCalendarId).then(() => undefined)
+        : restoreHabit(vars.habit.id, currentCalendarId).then(() => undefined),
     onSuccess,
     onError,
   })
 
   const deleteMutation = useMutation({
-    mutationFn: (id: string) => deleteHabit(id),
+    mutationFn: (id: string) => deleteHabit(id, currentCalendarId),
     onSuccess,
     onError,
   })
 
   const reorderMutation = useMutation({
-    mutationFn: (orderedIds: string[]) => reorderHabits(orderedIds),
+    mutationFn: (orderedIds: string[]) => reorderHabits(orderedIds, currentCalendarId),
     onSuccess,
     onError,
   })
@@ -143,6 +152,7 @@ export const HabitJournal = ({ onMutationError, onMutationSuccess }: HabitJourna
       ?.status ?? 'none'
 
   const move = (index: number, delta: -1 | 1) => {
+    if (!canEdit) return
     const ids = active.map((habit) => habit.id)
     const target = index + delta
     const a = ids[index]
@@ -153,6 +163,16 @@ export const HabitJournal = ({ onMutationError, onMutationSuccess }: HabitJourna
     reorderMutation.mutate(ids)
   }
 
+  const setArchived = (habit: Habit, archive: boolean) => {
+    if (!canEdit) return
+    archiveMutation.mutate({ habit, archive })
+  }
+
+  const removeHabit = (id: string) => {
+    if (!canEdit) return
+    deleteMutation.mutate(id)
+  }
+
   const navigateWeek = (direction: -1 | 1) => {
     const nextAnchor = addDays(anchor, DAYS_SHOWN * direction)
     setAnchor(nextAnchor)
@@ -280,8 +300,8 @@ export const HabitJournal = ({ onMutationError, onMutationSuccess }: HabitJourna
                       const isSelectedDay = iso === selectedIso
                       // Until the week's entries have loaded (or if they failed), every cell reads
                       // "none" — so keep them non-interactive so a tap can't overwrite an unloaded
-                      // yes/no/skip with a fresh "yes".
-                      const cellDisabled = isFuture || !entries.isSuccess
+                      // yes/no/skip with a fresh "yes". Read-only viewers can't cycle status either.
+                      const cellDisabled = isFuture || !entries.isSuccess || !canEdit
                       const fill =
                         status in STATUS_FILL ? STATUS_FILL[status as EntryStatus] : undefined
                       return (
@@ -302,6 +322,7 @@ export const HabitJournal = ({ onMutationError, onMutationSuccess }: HabitJourna
                           style={fill ? { backgroundColor: fill, borderColor: fill } : undefined}
                           onClick={() => {
                             setSelectedIso(iso)
+                            if (!canEdit) return
                             toggleMutation.mutate({ habitId: habit.id, date: iso, current: status })
                           }}
                           aria-label={t('focal.habits.dayCell', { date: iso, status })}
@@ -317,7 +338,7 @@ export const HabitJournal = ({ onMutationError, onMutationSuccess }: HabitJourna
                     variant="ghost"
                     className="h-8 w-8"
                     onClick={() => move(index, -1)}
-                    disabled={index === 0 || reorderMutation.isPending}
+                    disabled={index === 0 || reorderMutation.isPending || !canEdit}
                     aria-label={t('focal.habits.actions.moveUp')}
                   >
                     <ChevronUp className="h-4 w-4" />
@@ -328,7 +349,7 @@ export const HabitJournal = ({ onMutationError, onMutationSuccess }: HabitJourna
                     variant="ghost"
                     className="h-8 w-8"
                     onClick={() => move(index, 1)}
-                    disabled={index === active.length - 1 || reorderMutation.isPending}
+                    disabled={index === active.length - 1 || reorderMutation.isPending || !canEdit}
                     aria-label={t('focal.habits.actions.moveDown')}
                   >
                     <ChevronDown className="h-4 w-4" />
@@ -337,8 +358,8 @@ export const HabitJournal = ({ onMutationError, onMutationSuccess }: HabitJourna
                     type="button"
                     size="sm"
                     variant="outline"
-                    onClick={() => archiveMutation.mutate({ habit, archive: true })}
-                    disabled={archiveMutation.isPending}
+                    onClick={() => setArchived(habit, true)}
+                    disabled={archiveMutation.isPending || !canEdit}
                   >
                     {t('focal.habits.actions.archive')}
                   </Button>
@@ -389,8 +410,8 @@ export const HabitJournal = ({ onMutationError, onMutationSuccess }: HabitJourna
                     size="sm"
                     variant="outline"
                     className="h-7 gap-1 text-xs"
-                    onClick={() => archiveMutation.mutate({ habit, archive: false })}
-                    disabled={archiveMutation.isPending}
+                    onClick={() => setArchived(habit, false)}
+                    disabled={archiveMutation.isPending || !canEdit}
                   >
                     <ArchiveRestore className="h-3 w-3" />
                     {t('focal.habits.actions.restore')}
@@ -400,8 +421,8 @@ export const HabitJournal = ({ onMutationError, onMutationSuccess }: HabitJourna
                     size="icon"
                     variant="ghost"
                     className="h-7 w-7 text-destructive"
-                    onClick={() => deleteMutation.mutate(habit.id)}
-                    disabled={deleteMutation.isPending}
+                    onClick={() => removeHabit(habit.id)}
+                    disabled={deleteMutation.isPending || !canEdit}
                     aria-label={t('focal.habits.actions.delete')}
                   >
                     <Trash2 className="h-3 w-3" />
diff --git a/apps/focal/client/src/features/habits/HabitsPage.test.tsx b/apps/focal/client/src/features/habits/HabitsPage.test.tsx
index 1ff99c5..f380560 100644
--- a/apps/focal/client/src/features/habits/HabitsPage.test.tsx
+++ b/apps/focal/client/src/features/habits/HabitsPage.test.tsx
@@ -116,15 +116,18 @@ describe('HabitsPage', () => {
       within(dialog).getByRole('button', { name: t('focal.habits.dialog.submit') }),
     )
 
-    expect(mocked.createHabit).toHaveBeenCalledWith({
-      name: 'Walk',
-      color: '#3b82f6',
-      type: 'positive',
-      frequency: 'daily',
-      targetDaysPerWeek: 7,
-      isArchived: false,
-      sortOrder: 0,
-    })
+    expect(mocked.createHabit).toHaveBeenCalledWith(
+      {
+        name: 'Walk',
+        color: '#3b82f6',
+        type: 'positive',
+        frequency: 'daily',
+        targetDaysPerWeek: 7,
+        isArchived: false,
+        sortOrder: 0,
+      },
+      null,
+    )
     await waitFor(() => expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['habits'] }))
     await waitFor(() => expect(screen.queryByRole('dialog')).not.toBeInTheDocument())
   })
@@ -211,18 +214,21 @@ describe('HabitsPage', () => {
         name: t('focal.habits.dayCell', { date: todayIso, status: 'none' }),
       }),
     )
-    expect(mocked.upsertEntry).toHaveBeenCalledWith({
-      habitId: 'h1',
-      date: todayIso,
-      status: 'yes',
-    })
+    expect(mocked.upsertEntry).toHaveBeenCalledWith(
+      {
+        habitId: 'h1',
+        date: todayIso,
+        status: 'yes',
+      },
+      null,
+    )
 
     await userEvent.click(
       screen.getByRole('button', {
         name: t('focal.habits.dayCell', { date: yesterdayIso, status: 'skip' }),
       }),
     )
-    expect(mocked.deleteEntry).toHaveBeenCalledWith('h1', yesterdayIso)
+    expect(mocked.deleteEntry).toHaveBeenCalledWith('h1', yesterdayIso, null)
   })
 
   it('disables day cells until the week entries load, so a tap cannot overwrite an unloaded status', async () => {
@@ -245,13 +251,18 @@ describe('HabitsPage', () => {
 
     await screen.findByText('Reading')
     const initialEnd = todayIso
-    expect(mocked.listEntries).toHaveBeenCalledWith(toIsoDate(addDays(new Date(), -6)), initialEnd)
+    expect(mocked.listEntries).toHaveBeenCalledWith(
+      toIsoDate(addDays(new Date(), -6)),
+      initialEnd,
+      null,
+    )
 
     await userEvent.click(screen.getByRole('button', { name: t('focal.habits.journal.prevWeek') }))
     await waitFor(() =>
       expect(mocked.listEntries).toHaveBeenCalledWith(
         toIsoDate(addDays(new Date(), -13)),
         toIsoDate(addDays(new Date(), -7)),
+        null,
       ),
     )
 
@@ -261,6 +272,7 @@ describe('HabitsPage', () => {
       expect(mocked.listEntries).toHaveBeenLastCalledWith(
         toIsoDate(addDays(new Date(), -6)),
         todayIso,
+        null,
       ),
     )
   })
@@ -282,14 +294,14 @@ describe('HabitsPage', () => {
       name: t('focal.habits.actions.moveDown'),
     })
     await userEvent.click(downButtons[0] as HTMLElement)
-    expect(mocked.reorderHabits).toHaveBeenCalledWith(['h3', 'h1'])
+    expect(mocked.reorderHabits).toHaveBeenCalledWith(['h3', 'h1'], null)
 
     // Archive the first active habit.
     const archiveButtons = screen.getAllByRole('button', {
       name: t('focal.habits.actions.archive'),
     })
     await userEvent.click(archiveButtons[0] as HTMLElement)
-    expect(mocked.updateHabit).toHaveBeenCalledWith('h1', { isArchived: true })
+    expect(mocked.updateHabit).toHaveBeenCalledWith('h1', { isArchived: true }, null)
 
     // Expand the archived section, then restore + delete.
     await userEvent.click(
@@ -298,10 +310,10 @@ describe('HabitsPage', () => {
     await userEvent.click(
       await screen.findByRole('button', { name: t('focal.habits.actions.restore') }),
     )
-    expect(mocked.restoreHabit).toHaveBeenCalledWith('h2')
+    expect(mocked.restoreHabit).toHaveBeenCalledWith('h2', null)
 
     await userEvent.click(screen.getByRole('button', { name: t('focal.habits.actions.delete') }))
-    expect(mocked.deleteHabit).toHaveBeenCalledWith('h2')
+    expect(mocked.deleteHabit).toHaveBeenCalledWith('h2', null)
   })
 
   it('loads chart stats on the charts tab and renders the summary table', async () => {
@@ -378,10 +390,13 @@ describe('HabitsPage', () => {
         name: t('focal.habits.dayCell', { date: todayIso, status: 'none' }),
       }),
     )
-    expect(mocked.upsertEntry).toHaveBeenCalledWith({
-      habitId: 'h1',
-      date: todayIso,
-      status: 'yes',
-    })
+    expect(mocked.upsertEntry).toHaveBeenCalledWith(
+      {
+        habitId: 'h1',
+        date: todayIso,
+        status: 'yes',
+      },
+      null,
+    )
   })
 })
diff --git a/apps/focal/client/src/features/habits/HabitsPage.tsx b/apps/focal/client/src/features/habits/HabitsPage.tsx
index 7b56e87..7c50a5f 100644
--- a/apps/focal/client/src/features/habits/HabitsPage.tsx
+++ b/apps/focal/client/src/features/habits/HabitsPage.tsx
@@ -3,9 +3,11 @@ import { Plus, Repeat } from 'lucide-react'
 import { useState } from 'react'
 import { useTranslation } from 'react-i18next'
 
+import { withCal } from '@/api/queryKeys'
 import { PageHeader } from '@/components/PageHeader'
 import { Button } from '@/components/ui/button'
 import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
+import { useCalendarFilter } from '@/features/calendars/CalendarFilterContext'
 
 import { listHabits } from '../../api/habits'
 import { HabitCharts } from './HabitCharts'
@@ -17,13 +19,17 @@ const HABITS_KEY = ['habits'] as const
 export const HabitsPage = () => {
   const { t } = useTranslation()
   const queryClient = useQueryClient()
+  const { currentCalendarId, canEdit } = useCalendarFilter()
 
   const [createOpen, setCreateOpen] = useState(false)
   const [errorMessage, setErrorMessage] = useState<string | null>(null)
 
   // Shared with the journal under the same key, so the count for the new habit's sortOrder
   // comes straight from cache without a second request.
-  const habits = useQuery({ queryKey: HABITS_KEY, queryFn: () => listHabits() })
+  const habits = useQuery({
+    queryKey: withCal(HABITS_KEY, currentCalendarId),
+    queryFn: () => listHabits(false, currentCalendarId),
+  })
 
   const invalidate = () => queryClient.invalidateQueries({ queryKey: HABITS_KEY })
 
@@ -50,7 +56,7 @@ export const HabitsPage = () => {
         icon={Repeat}
         title={t('focal.app.nav.habits')}
         rightActions={
-          <Button size="sm" onClick={() => setCreateOpen(true)}>
+          <Button size="sm" onClick={() => setCreateOpen(true)} disabled={!canEdit}>
             <Plus className="mr-1 h-4 w-4" />
             {t('focal.habits.dialog.add')}
           </Button>
@@ -71,6 +77,11 @@ export const HabitsPage = () => {
               {errorMessage}
             </p>
           )}
+          {!canEdit && (
+            <p className="mt-3 rounded-md border border-border bg-muted/50 px-3 py-2 text-sm text-muted-foreground">
+              {t('focal.app.calendarFilter.readOnlyNotice')}
+            </p>
+          )}
         </div>
 
         <TabsContent value="journal" className="mt-0 flex-1 overflow-auto px-4 pb-4 md:px-6">
@@ -89,6 +100,8 @@ export const HabitsPage = () => {
       <HabitCreateDialog
         open={createOpen}
         onOpenChange={setCreateOpen}
+        calendarId={currentCalendarId}
+        canEdit={canEdit}
         sortOrder={(habits.data ?? []).length}
         onCreated={onCreated}
         onError={onMutationError}
diff --git a/apps/focal/client/src/features/heatmap/HeatmapPage.test.tsx b/apps/focal/client/src/features/heatmap/HeatmapPage.test.tsx
index d9e5a14..bcac928 100644
--- a/apps/focal/client/src/features/heatmap/HeatmapPage.test.tsx
+++ b/apps/focal/client/src/features/heatmap/HeatmapPage.test.tsx
@@ -152,7 +152,7 @@ describe('HeatmapPage', () => {
     const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime })
     renderPage()
     await waitFor(() =>
-      expect(mockedEvents.listEvents).toHaveBeenCalledWith('2026-01-01', '2026-12-31'),
+      expect(mockedEvents.listEvents).toHaveBeenCalledWith('2026-01-01', '2026-12-31', null),
     )
 
     const prevYear = () =>
@@ -164,13 +164,13 @@ describe('HeatmapPage', () => {
 
     await user.click(prevYear())
     await waitFor(() =>
-      expect(mockedEvents.listEvents).toHaveBeenCalledWith('2025-01-01', '2025-12-31'),
+      expect(mockedEvents.listEvents).toHaveBeenCalledWith('2025-01-01', '2025-12-31', null),
     )
 
     await user.click(nextYear())
     await user.click(nextYear())
     await waitFor(() =>
-      expect(mockedEvents.listEvents).toHaveBeenCalledWith('2026-01-01', '2026-12-31'),
+      expect(mockedEvents.listEvents).toHaveBeenCalledWith('2026-01-01', '2026-12-31', null),
     )
   })
 
diff --git a/apps/focal/client/src/features/heatmap/HeatmapPage.tsx b/apps/focal/client/src/features/heatmap/HeatmapPage.tsx
index a0e6073..64b856a 100644
--- a/apps/focal/client/src/features/heatmap/HeatmapPage.tsx
+++ b/apps/focal/client/src/features/heatmap/HeatmapPage.tsx
@@ -12,6 +12,7 @@ import { useEffect, useMemo, useState } from 'react'
 import { useTranslation } from 'react-i18next'
 import { Link, useLocation } from 'wouter'
 
+import { withCal } from '@/api/queryKeys'
 import { PageToolbar } from '@/components/PageToolbar'
 import { Alert, AlertDescription } from '@/components/ui/alert'
 import { Button } from '@/components/ui/button'
@@ -27,6 +28,7 @@ import {
 import { SidebarTrigger, useSidebarOptional } from '@/components/ui/sidebar'
 import { Skeleton } from '@/components/ui/skeleton'
 import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip'
+import { useCalendarFilter } from '@/features/calendars/CalendarFilterContext'
 
 import { type CalendarEvent, listEvents } from '../../api/events'
 import { listProjects } from '../../api/projects'
@@ -78,6 +80,7 @@ const isoDate = (year: number, month: number, day: number): string =>
 
 export const HeatmapPage = () => {
   const { t, i18n } = useTranslation()
+  const { currentCalendarId, canViewOtherPages } = useCalendarFilter()
   const [, navigate] = useLocation()
   const sidebar = useSidebarOptional()
 
@@ -107,15 +110,23 @@ export const HeatmapPage = () => {
   const yearStart = `${year}-01-01`
   const yearEnd = `${year}-12-31`
   const events = useQuery({
-    queryKey: ['events', yearStart, yearEnd],
-    queryFn: () => listEvents(yearStart, yearEnd),
+    queryKey: withCal(['events', yearStart, yearEnd], currentCalendarId),
+    queryFn: () => listEvents(yearStart, yearEnd, currentCalendarId),
   })
   const budget = useQuery({
-    queryKey: ['budgets', year],
-    queryFn: () => getBudgetYear(year),
+    queryKey: withCal(['time-budgets', year], currentCalendarId),
+    queryFn: () => getBudgetYear(year, currentCalendarId),
+  })
+  const projects = useQuery({
+    queryKey: withCal(['projects'], currentCalendarId),
+    queryFn: () => listProjects(currentCalendarId),
+    enabled: currentCalendarId === null || canViewOtherPages,
+  })
+  const spheres = useQuery({
+    queryKey: withCal(['spheres'], currentCalendarId),
+    queryFn: () => listSpheres(currentCalendarId),
+    enabled: currentCalendarId === null || canViewOtherPages,
   })
-  const projects = useQuery({ queryKey: ['projects'], queryFn: listProjects })
-  const spheres = useQuery({ queryKey: ['spheres'], queryFn: listSpheres })
 
   const workingHoursPerDay = budget.data?.settings.workingHoursPerDay ?? 8
 
diff --git a/apps/focal/client/src/features/meetings/MeetingRequestsPage.test.tsx b/apps/focal/client/src/features/meetings/MeetingRequestsPage.test.tsx
index 396cb04..f589da7 100644
--- a/apps/focal/client/src/features/meetings/MeetingRequestsPage.test.tsx
+++ b/apps/focal/client/src/features/meetings/MeetingRequestsPage.test.tsx
@@ -441,7 +441,7 @@ describe('MeetingRequestsPage', () => {
       card.getByRole('button', { name: tr('focal.meetingRequests.actions.accept.new') }),
     )
 
-    await waitFor(() => expect(mocked.acceptMeetingRequest).toHaveBeenCalledWith('r1'))
+    await waitFor(() => expect(mocked.acceptMeetingRequest).toHaveBeenCalledWith('r1', null))
     await waitFor(() => expect(mocked.listMeetingRequests).toHaveBeenCalledTimes(2))
   })
 
@@ -458,7 +458,7 @@ describe('MeetingRequestsPage', () => {
       card.getByRole('button', { name: tr('focal.meetingRequests.actions.decline.new') }),
     )
 
-    await waitFor(() => expect(mocked.declineMeetingRequest).toHaveBeenCalledWith('r1'))
+    await waitFor(() => expect(mocked.declineMeetingRequest).toHaveBeenCalledWith('r1', null))
     await waitFor(() => expect(mocked.listMeetingRequests).toHaveBeenCalledTimes(2))
   })
 
@@ -475,7 +475,7 @@ describe('MeetingRequestsPage', () => {
       card.getByRole('button', { name: tr('focal.meetingRequests.actions.tentative') }),
     )
 
-    await waitFor(() => expect(mocked.tentativeMeetingRequest).toHaveBeenCalledWith('r1'))
+    await waitFor(() => expect(mocked.tentativeMeetingRequest).toHaveBeenCalledWith('r1', null))
     await waitFor(() => expect(mocked.listMeetingRequests).toHaveBeenCalledTimes(2))
   })
 
@@ -498,7 +498,7 @@ describe('MeetingRequestsPage', () => {
       card.getByRole('button', { name: tr('focal.meetingRequests.actions.accept.reschedule') }),
     )
 
-    await waitFor(() => expect(mocked.acceptMeetingReschedule).toHaveBeenCalledWith('r1'))
+    await waitFor(() => expect(mocked.acceptMeetingReschedule).toHaveBeenCalledWith('r1', null))
     expect(mocked.acceptMeetingRequest).not.toHaveBeenCalled()
     await waitFor(() => expect(mocked.listMeetingRequests).toHaveBeenCalledTimes(2))
   })
@@ -522,7 +522,7 @@ describe('MeetingRequestsPage', () => {
       card.getByRole('button', { name: tr('focal.meetingRequests.actions.decline.reschedule') }),
     )
 
-    await waitFor(() => expect(mocked.declineMeetingReschedule).toHaveBeenCalledWith('r1'))
+    await waitFor(() => expect(mocked.declineMeetingReschedule).toHaveBeenCalledWith('r1', null))
     expect(mocked.declineMeetingRequest).not.toHaveBeenCalled()
   })
 
@@ -544,7 +544,7 @@ describe('MeetingRequestsPage', () => {
       card.getByRole('button', { name: tr('focal.meetingRequests.actions.accept.cancel') }),
     )
 
-    await waitFor(() => expect(mocked.acceptMeetingRequest).toHaveBeenCalledWith('cancel-1'))
+    await waitFor(() => expect(mocked.acceptMeetingRequest).toHaveBeenCalledWith('cancel-1', null))
     expect(mocked.acceptMeetingReschedule).not.toHaveBeenCalled()
   })
 
@@ -563,7 +563,7 @@ describe('MeetingRequestsPage', () => {
       card.getByRole('button', { name: tr('focal.meetingRequests.actions.decline.cancel') }),
     )
 
-    await waitFor(() => expect(mocked.declineMeetingRequest).toHaveBeenCalledWith('cancel-1'))
+    await waitFor(() => expect(mocked.declineMeetingRequest).toHaveBeenCalledWith('cancel-1', null))
     expect(mocked.declineMeetingReschedule).not.toHaveBeenCalled()
   })
 
@@ -576,7 +576,7 @@ describe('MeetingRequestsPage', () => {
 
     await user.click(card.getByRole('button', { name: tr('focal.meetingRequests.actions.delete') }))
 
-    await waitFor(() => expect(mocked.deleteMeetingRequest).toHaveBeenCalledWith('r1'))
+    await waitFor(() => expect(mocked.deleteMeetingRequest).toHaveBeenCalledWith('r1', null))
     await waitFor(() => expect(mocked.listMeetingRequests).toHaveBeenCalledTimes(2))
   })
 
diff --git a/apps/focal/client/src/features/meetings/MeetingRequestsPage.tsx b/apps/focal/client/src/features/meetings/MeetingRequestsPage.tsx
index 69cab8a..4e89a2a 100644
--- a/apps/focal/client/src/features/meetings/MeetingRequestsPage.tsx
+++ b/apps/focal/client/src/features/meetings/MeetingRequestsPage.tsx
@@ -18,7 +18,7 @@ import {
 } from 'lucide-react'
 import { useEffect, useState } from 'react'
 import { useTranslation } from 'react-i18next'
-
+import { withCal } from '@/api/queryKeys'
 import { PageHeader } from '@/components/PageHeader'
 import { Badge } from '@/components/ui/badge'
 import { Button } from '@/components/ui/button'
@@ -32,7 +32,7 @@ import {
   SelectValue,
 } from '@/components/ui/select'
 import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
-
+import { useCalendarFilter } from '@/features/calendars/CalendarFilterContext'
 import {
   acceptMeetingRequest,
   acceptMeetingReschedule,
@@ -43,6 +43,7 @@ import {
   type MeetingRequest,
   tentativeMeetingRequest,
 } from '../../api/meetingRequests'
+
 import { listAccessibleCalendars } from '../../api/sharedCalendars'
 import {
   type CalendarFilterValue,
@@ -123,6 +124,7 @@ const TYPE_FILTER_ICON: Record<
 interface MeetingRequestCardProps {
   request: MeetingRequest
   isResponding: boolean
+  canEdit: boolean
   onAccept: (request: MeetingRequest) => void
   onDecline: (request: MeetingRequest) => void
   onTentative: (request: MeetingRequest) => void
@@ -138,6 +140,7 @@ interface MeetingRequestCardProps {
 const MeetingRequestCard = ({
   request,
   isResponding,
+  canEdit,
   onAccept,
   onDecline,
   onTentative,
@@ -158,7 +161,7 @@ const MeetingRequestCard = ({
   const status = requestStatusOf(request)
   const type = requestTypeOf(request)
   const { icon: TypeIcon, color: typeColor } = TYPE_CONFIG[type]
-  const isDisabled = loadingAction !== null || isResponding
+  const isDisabled = loadingAction !== null || isResponding || !canEdit
 
   const runAction = (action: 'accept' | 'decline' | 'tentative', fn: () => void) => () => {
     if (isDisabled) return
@@ -327,9 +330,13 @@ const MeetingRequestCard = ({
 export const MeetingRequestsPage = () => {
   const { t } = useTranslation()
   const queryClient = useQueryClient()
+  const { currentCalendarId, canEdit } = useCalendarFilter()
 
-  const requests = useQuery({ queryKey: REQUESTS_KEY, queryFn: listMeetingRequests })
-  const calendars = useQuery({ queryKey: CALENDARS_KEY, queryFn: listAccessibleCalendars })
+  const requests = useQuery({
+    queryKey: withCal(REQUESTS_KEY, currentCalendarId),
+    queryFn: () => listMeetingRequests(currentCalendarId),
+  })
+  const calendars = useQuery({ queryKey: CALENDARS_KEY, queryFn: () => listAccessibleCalendars() })
 
   const [statusFilter, setStatusFilter] = useState<StatusFilter>('all')
   const [typeFilter, setTypeFilter] = useState<RequestTypeFilter>('all')
@@ -351,7 +358,7 @@ export const MeetingRequestsPage = () => {
   const onActionSuccess = (messageKey: string) => async () => {
     setErrorMessage(null)
     setMessage(t(messageKey))
-    await queryClient.invalidateQueries({ queryKey: REQUESTS_KEY })
+    await queryClient.invalidateQueries({ queryKey: withCal(REQUESTS_KEY, currentCalendarId) })
   }
 
   const onActionError = (errorKey: string) => (error: unknown) => {
@@ -364,37 +371,37 @@ export const MeetingRequestsPage = () => {
   }
 
   const acceptMutation = useMutation({
-    mutationFn: (id: string) => acceptMeetingRequest(id),
+    mutationFn: (id: string) => acceptMeetingRequest(id, currentCalendarId),
     onSuccess: onActionSuccess('focal.meetingRequests.messages.accepted'),
     onError: onActionError('focal.meetingRequests.errors.accept'),
   })
 
   const declineMutation = useMutation({
-    mutationFn: (id: string) => declineMeetingRequest(id),
+    mutationFn: (id: string) => declineMeetingRequest(id, currentCalendarId),
     onSuccess: onActionSuccess('focal.meetingRequests.messages.declined'),
     onError: onActionError('focal.meetingRequests.errors.decline'),
   })
 
   const tentativeMutation = useMutation({
-    mutationFn: (id: string) => tentativeMeetingRequest(id),
+    mutationFn: (id: string) => tentativeMeetingRequest(id, currentCalendarId),
     onSuccess: onActionSuccess('focal.meetingRequests.messages.tentative'),
     onError: onActionError('focal.meetingRequests.errors.tentative'),
   })
 
   const acceptRescheduleMutation = useMutation({
-    mutationFn: (id: string) => acceptMeetingReschedule(id),
+    mutationFn: (id: string) => acceptMeetingReschedule(id, currentCalendarId),
     onSuccess: onActionSuccess('focal.meetingRequests.messages.rescheduleAccepted'),
     onError: onActionError('focal.meetingRequests.errors.rescheduleAccept'),
   })
 
   const declineRescheduleMutation = useMutation({
-    mutationFn: (id: string) => declineMeetingReschedule(id),
+    mutationFn: (id: string) => declineMeetingReschedule(id, currentCalendarId),
     onSuccess: onActionSuccess('focal.meetingRequests.messages.rescheduleDeclined'),
     onError: onActionError('focal.meetingRequests.errors.rescheduleDecline'),
   })
 
   const deleteMutation = useMutation({
-    mutationFn: (id: string) => deleteMeetingRequest(id),
+    mutationFn: (id: string) => deleteMeetingRequest(id, currentCalendarId),
     onSuccess: onActionSuccess('focal.meetingRequests.messages.deleted'),
     onError: onActionError('focal.meetingRequests.errors.delete'),
   })
@@ -420,6 +427,7 @@ export const MeetingRequestsPage = () => {
   })
 
   const handleAccept = (request: MeetingRequest) => {
+    if (!canEdit) return
     if (requestTypeOf(request) === 'reschedule') {
       acceptRescheduleMutation.mutate(request.id)
       return
@@ -428,6 +436,7 @@ export const MeetingRequestsPage = () => {
   }
 
   const handleDecline = (request: MeetingRequest) => {
+    if (!canEdit) return
     if (requestTypeOf(request) === 'reschedule') {
       declineRescheduleMutation.mutate(request.id)
       return
@@ -435,6 +444,16 @@ export const MeetingRequestsPage = () => {
     declineMutation.mutate(request.id)
   }
 
+  const handleTentative = (request: MeetingRequest) => {
+    if (!canEdit) return
+    tentativeMutation.mutate(request.id)
+  }
+
+  const handleDelete = (id: string) => {
+    if (!canEdit) return
+    deleteMutation.mutate(id)
+  }
+
   const pendingBadge =
     counts.pending > 0 ? (
       <Badge
@@ -457,6 +476,15 @@ export const MeetingRequestsPage = () => {
 
       <div className="flex-1 overflow-auto p-4 md:p-6">
         <div className="mx-auto max-w-4xl space-y-6">
+          {!canEdit && (
+            <p
+              role="status"
+              className="rounded-md border border-border bg-muted px-3 py-2 text-sm text-muted-foreground"
+            >
+              {t('focal.app.calendarFilter.readOnlyNotice')}
+            </p>
+          )}
+
           <div className="flex flex-wrap gap-3">
             <div className="relative min-w-[200px] flex-1">
               <Search className="-translate-y-1/2 absolute top-1/2 left-3 h-4 w-4 text-muted-foreground" />
@@ -633,10 +661,11 @@ export const MeetingRequestsPage = () => {
                       <MeetingRequestCard
                         request={request}
                         isResponding={isResponding}
+                        canEdit={canEdit}
                         onAccept={handleAccept}
                         onDecline={handleDecline}
-                        onTentative={(target) => tentativeMutation.mutate(target.id)}
-                        onDelete={(id) => deleteMutation.mutate(id)}
+                        onTentative={(target) => handleTentative(target)}
+                        onDelete={handleDelete}
                       />
                     </li>
                   ))}
diff --git a/apps/focal/client/src/features/projects/ProjectsPage.test.tsx b/apps/focal/client/src/features/projects/ProjectsPage.test.tsx
index d8cd984..9a60b8e 100644
--- a/apps/focal/client/src/features/projects/ProjectsPage.test.tsx
+++ b/apps/focal/client/src/features/projects/ProjectsPage.test.tsx
@@ -100,12 +100,15 @@ describe('ProjectsPage', () => {
       screen.getByRole('button', { name: i18n.t('focal.projects.form.submit') }),
     )
 
-    expect(mockedProjects.createProject).toHaveBeenCalledWith({
-      name: 'Ops',
-      projectType: 'provision',
-      isWorkTime: true,
-      sphere: null,
-    })
+    expect(mockedProjects.createProject).toHaveBeenCalledWith(
+      {
+        name: 'Ops',
+        projectType: 'provision',
+        isWorkTime: true,
+        sphere: null,
+      },
+      null,
+    )
   })
 
   it('offers the sphere selector once work-time is unchecked', async () => {
@@ -148,9 +151,12 @@ describe('ProjectsPage', () => {
       screen.getByRole('button', { name: i18n.t('focal.projects.products.add') }),
     )
 
-    expect(mockedProjects.createProject).toHaveBeenCalledWith({
-      name: 'Website',
-      parentProjectId: 'p1',
-    })
+    expect(mockedProjects.createProject).toHaveBeenCalledWith(
+      {
+        name: 'Website',
+        parentProjectId: 'p1',
+      },
+      null,
+    )
   })
 })
diff --git a/apps/focal/client/src/features/projects/ProjectsPage.tsx b/apps/focal/client/src/features/projects/ProjectsPage.tsx
index 64f24c6..b827b56 100644
--- a/apps/focal/client/src/features/projects/ProjectsPage.tsx
+++ b/apps/focal/client/src/features/projects/ProjectsPage.tsx
@@ -3,11 +3,13 @@ import { FolderTree, Pencil, Plus, Trash2 } from 'lucide-react'
 import { type FormEvent, useState } from 'react'
 import { useTranslation } from 'react-i18next'
 
+import { withCal } from '@/api/queryKeys'
 import { Badge } from '@/components/ui/badge'
 import { Button } from '@/components/ui/button'
 import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
 import { Input } from '@/components/ui/input'
 import { Label } from '@/components/ui/label'
+import { useCalendarFilter } from '@/features/calendars/CalendarFilterContext'
 
 import {
   createProject,
@@ -39,9 +41,16 @@ type EditDraft = {
 export const ProjectsPage = () => {
   const { t } = useTranslation()
   const queryClient = useQueryClient()
+  const { currentCalendarId, canEdit } = useCalendarFilter()
 
-  const projects = useQuery({ queryKey: PROJECTS_KEY, queryFn: listProjects })
-  const spheres = useQuery({ queryKey: SPHERES_KEY, queryFn: listSpheres })
+  const projects = useQuery({
+    queryKey: withCal(PROJECTS_KEY, currentCalendarId),
+    queryFn: () => listProjects(currentCalendarId),
+  })
+  const spheres = useQuery({
+    queryKey: withCal(SPHERES_KEY, currentCalendarId),
+    queryFn: () => listSpheres(currentCalendarId),
+  })
 
   const [name, setName] = useState('')
   const [projectType, setProjectType] = useState<ProjectType>('provision')
@@ -62,7 +71,7 @@ export const ProjectsPage = () => {
     )
 
   const createMutation = useMutation({
-    mutationFn: (input: ProjectCreate) => createProject(input),
+    mutationFn: (input: ProjectCreate) => createProject(input, currentCalendarId),
     onSuccess: async () => {
       setName('')
       setErrorMessage(null)
@@ -72,7 +81,7 @@ export const ProjectsPage = () => {
   })
 
   const createProductMutation = useMutation({
-    mutationFn: (input: ProjectCreate) => createProject(input),
+    mutationFn: (input: ProjectCreate) => createProject(input, currentCalendarId),
     onSuccess: async (_created, input) => {
       if (input.parentProjectId) {
         setProductNames((names) => ({ ...names, [String(input.parentProjectId)]: '' }))
@@ -84,7 +93,8 @@ export const ProjectsPage = () => {
   })
 
   const updateMutation = useMutation({
-    mutationFn: (vars: { id: string; patch: ProjectUpdate }) => updateProject(vars.id, vars.patch),
+    mutationFn: (vars: { id: string; patch: ProjectUpdate }) =>
+      updateProject(vars.id, vars.patch, currentCalendarId),
     onSuccess: async () => {
       setEditingId(null)
       setDraft(null)
@@ -95,7 +105,7 @@ export const ProjectsPage = () => {
   })
 
   const deleteMutation = useMutation({
-    mutationFn: (id: string) => deleteProject(id),
+    mutationFn: (id: string) => deleteProject(id, currentCalendarId),
     onSuccess: async () => {
       setErrorMessage(null)
       await invalidate()
@@ -105,6 +115,7 @@ export const ProjectsPage = () => {
 
   const onCreate = (event: FormEvent<HTMLFormElement>) => {
     event.preventDefault()
+    if (!canEdit) return
     createMutation.mutate({
       name,
       projectType,
@@ -115,6 +126,7 @@ export const ProjectsPage = () => {
   }
 
   const onAddProduct = (parent: Project) => {
+    if (!canEdit) return
     const productName = (productNames[parent.id] ?? '').trim()
     if (!productName) return
     // Products inherit type / sphere / work-time / color from the parent on the backend.
@@ -122,6 +134,7 @@ export const ProjectsPage = () => {
   }
 
   const startEdit = (project: Project) => {
+    if (!canEdit) return
     setEditingId(project.id)
     setDraft({
       name: project.name,
@@ -132,7 +145,7 @@ export const ProjectsPage = () => {
   }
 
   const saveEdit = (project: Project) => {
-    if (!draft) return
+    if (!canEdit || !draft) return
     updateMutation.mutate({
       id: project.id,
       patch: {
@@ -174,6 +187,14 @@ export const ProjectsPage = () => {
             </Badge>
           )}
         </div>
+        {!canEdit && (
+          <p
+            role="status"
+            className="border-t border-border bg-muted/40 px-4 py-2 text-sm text-muted-foreground md:px-6"
+          >
+            {t('focal.app.calendarFilter.readOnlyNotice')}
+          </p>
+        )}
       </header>
 
       <div className="flex-1 overflow-auto p-4 md:p-6">
@@ -247,7 +268,11 @@ export const ProjectsPage = () => {
                     </select>
                   </div>
                 )}
-                <Button type="submit" className="gap-2" disabled={createMutation.isPending}>
+                <Button
+                  type="submit"
+                  className="gap-2"
+                  disabled={!canEdit || createMutation.isPending}
+                >
                   <Plus className="h-4 w-4" aria-hidden="true" />
                   {t('focal.projects.form.submit')}
                 </Button>
@@ -322,7 +347,7 @@ export const ProjectsPage = () => {
                             type="button"
                             size="sm"
                             onClick={() => saveEdit(project)}
-                            disabled={updateMutation.isPending}
+                            disabled={!canEdit || updateMutation.isPending}
                           >
                             {t('focal.projects.actions.save')}
                           </Button>
@@ -363,6 +388,7 @@ export const ProjectsPage = () => {
                             variant="ghost"
                             className="gap-2"
                             onClick={() => startEdit(project)}
+                            disabled={!canEdit}
                           >
                             <Pencil className="h-4 w-4" aria-hidden="true" />
                             {t('focal.projects.actions.edit')}
@@ -372,8 +398,11 @@ export const ProjectsPage = () => {
                             size="sm"
                             variant="ghost"
                             className="gap-2 text-destructive"
-                            onClick={() => deleteMutation.mutate(project.id)}
-                            disabled={deleteMutation.isPending}
+                            onClick={() => {
+                              if (!canEdit) return
+                              deleteMutation.mutate(project.id)
+                            }}
+                            disabled={!canEdit || deleteMutation.isPending}
                           >
                             <Trash2 className="h-4 w-4" aria-hidden="true" />
                             {t('focal.projects.actions.delete')}
@@ -405,8 +434,11 @@ export const ProjectsPage = () => {
                                 size="sm"
                                 variant="ghost"
                                 className="gap-2 text-destructive"
-                                onClick={() => deleteMutation.mutate(product.id)}
-                                disabled={deleteMutation.isPending}
+                                onClick={() => {
+                                  if (!canEdit) return
+                                  deleteMutation.mutate(product.id)
+                                }}
+                                disabled={!canEdit || deleteMutation.isPending}
                               >
                                 <Trash2 className="h-4 w-4" aria-hidden="true" />
                                 {t('focal.projects.actions.delete')}
@@ -433,7 +465,7 @@ export const ProjectsPage = () => {
                             variant="secondary"
                             className="gap-2"
                             onClick={() => onAddProduct(project)}
-                            disabled={createProductMutation.isPending}
+                            disabled={!canEdit || createProductMutation.isPending}
                           >
                             <Plus className="h-4 w-4" aria-hidden="true" />
                             {t('focal.projects.products.add')}
diff --git a/apps/focal/client/src/features/spheres/SpheresPage.test.tsx b/apps/focal/client/src/features/spheres/SpheresPage.test.tsx
index 0280462..bb38fe6 100644
--- a/apps/focal/client/src/features/spheres/SpheresPage.test.tsx
+++ b/apps/focal/client/src/features/spheres/SpheresPage.test.tsx
@@ -79,13 +79,16 @@ describe('SpheresPage', () => {
     await userEvent.type(await screen.findByLabelText(i18n.t('focal.spheres.form.name')), 'Sport')
     await userEvent.click(screen.getByRole('button', { name: i18n.t('focal.spheres.form.submit') }))
 
-    expect(mocked.createSphere).toHaveBeenCalledWith({
-      name: 'Sport',
-      color: '#3b82f6',
-      priority: 'medium',
-      allocatedHours: 0,
-      sortOrder: 0,
-    })
+    expect(mocked.createSphere).toHaveBeenCalledWith(
+      {
+        name: 'Sport',
+        color: '#3b82f6',
+        priority: 'medium',
+        allocatedHours: 0,
+        sortOrder: 0,
+      },
+      null,
+    )
   })
 
   it('deletes a sphere', async () => {
@@ -97,6 +100,6 @@ describe('SpheresPage', () => {
       await screen.findByRole('button', { name: i18n.t('focal.spheres.actions.delete') }),
     )
 
-    expect(mocked.deleteSphere).toHaveBeenCalledWith('1')
+    expect(mocked.deleteSphere).toHaveBeenCalledWith('1', null)
   })
 })
diff --git a/apps/focal/client/src/features/spheres/SpheresPage.tsx b/apps/focal/client/src/features/spheres/SpheresPage.tsx
index d623d46..610ba0b 100644
--- a/apps/focal/client/src/features/spheres/SpheresPage.tsx
+++ b/apps/focal/client/src/features/spheres/SpheresPage.tsx
@@ -2,12 +2,13 @@ import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
 import { Orbit, Pencil, Plus, Trash2, Zap } from 'lucide-react'
 import { type FormEvent, useState } from 'react'
 import { useTranslation } from 'react-i18next'
-
+import { withCal } from '@/api/queryKeys'
 import { Badge } from '@/components/ui/badge'
 import { Button } from '@/components/ui/button'
 import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
 import { Input } from '@/components/ui/input'
 import { Label } from '@/components/ui/label'
+import { useCalendarFilter } from '@/features/calendars/CalendarFilterContext'
 
 import {
   createSphere,
@@ -47,8 +48,12 @@ const draftFrom = (sphere: Sphere): EditDraft => ({
 export const SpheresPage = () => {
   const { t } = useTranslation()
   const queryClient = useQueryClient()
+  const { currentCalendarId, canEdit } = useCalendarFilter()
 
-  const spheres = useQuery({ queryKey: SPHERES_KEY, queryFn: listSpheres })
+  const spheres = useQuery({
+    queryKey: withCal(SPHERES_KEY, currentCalendarId),
+    queryFn: () => listSpheres(currentCalendarId),
+  })
 
   const [name, setName] = useState('')
   const [color, setColor] = useState(DEFAULT_COLOR)
@@ -58,7 +63,8 @@ export const SpheresPage = () => {
   const [draft, setDraft] = useState<EditDraft | null>(null)
   const [errorMessage, setErrorMessage] = useState<string | null>(null)
 
-  const invalidate = () => queryClient.invalidateQueries({ queryKey: SPHERES_KEY })
+  const invalidate = () =>
+    queryClient.invalidateQueries({ queryKey: withCal(SPHERES_KEY, currentCalendarId) })
 
   const onMutationError = (error: unknown) =>
     setErrorMessage(
@@ -68,7 +74,7 @@ export const SpheresPage = () => {
     )
 
   const createMutation = useMutation({
-    mutationFn: (input: SphereCreate) => createSphere(input),
+    mutationFn: (input: SphereCreate) => createSphere(input, currentCalendarId),
     onSuccess: async () => {
       setName('')
       setColor(DEFAULT_COLOR)
@@ -81,7 +87,8 @@ export const SpheresPage = () => {
   })
 
   const updateMutation = useMutation({
-    mutationFn: (vars: { id: string; patch: SphereUpdate }) => updateSphere(vars.id, vars.patch),
+    mutationFn: (vars: { id: string; patch: SphereUpdate }) =>
+      updateSphere(vars.id, vars.patch, currentCalendarId),
     onSuccess: async () => {
       setEditingId(null)
       setDraft(null)
@@ -92,7 +99,7 @@ export const SpheresPage = () => {
   })
 
   const deleteMutation = useMutation({
-    mutationFn: (id: string) => deleteSphere(id),
+    mutationFn: (id: string) => deleteSphere(id, currentCalendarId),
     onSuccess: async () => {
       setErrorMessage(null)
       await invalidate()
@@ -102,15 +109,27 @@ export const SpheresPage = () => {
 
   const onCreate = (event: FormEvent<HTMLFormElement>) => {
     event.preventDefault()
+    if (!canEdit) return
     createMutation.mutate({ name, color, priority, allocatedHours, sortOrder: 0 })
   }
 
   const startEdit = (sphere: Sphere) => {
+    if (!canEdit) return
     setEditingId(sphere.id)
     setDraft(draftFrom(sphere))
     setErrorMessage(null)
   }
 
+  const onSave = (sphere: Sphere) => {
+    if (!canEdit || !draft) return
+    updateMutation.mutate({ id: sphere.id, patch: draft })
+  }
+
+  const onDelete = (id: string) => {
+    if (!canEdit) return
+    deleteMutation.mutate(id)
+  }
+
   const sorted = [...(spheres.data ?? [])].sort(
     (a, b) => a.sortOrder - b.sortOrder || a.name.localeCompare(b.name),
   )
@@ -132,6 +151,14 @@ export const SpheresPage = () => {
             </Badge>
           )}
         </div>
+        {!canEdit && (
+          <p
+            role="status"
+            className="border-t border-border bg-muted/40 px-4 py-2 text-sm text-muted-foreground md:px-6"
+          >
+            {t('focal.app.calendarFilter.readOnlyNotice')}
+          </p>
+        )}
       </header>
 
       <div className="flex-1 overflow-auto p-4 md:p-6">
@@ -202,7 +229,11 @@ export const SpheresPage = () => {
                     aria-label={t('focal.spheres.form.hours')}
                   />
                 </div>
-                <Button type="submit" className="gap-2" disabled={createMutation.isPending}>
+                <Button
+                  type="submit"
+                  className="gap-2"
+                  disabled={!canEdit || createMutation.isPending}
+                >
                   <Plus className="h-4 w-4" aria-hidden="true" />
                   {t('focal.spheres.form.submit')}
                 </Button>
@@ -307,8 +338,8 @@ export const SpheresPage = () => {
                         <Button
                           type="button"
                           size="sm"
-                          onClick={() => updateMutation.mutate({ id: sphere.id, patch: draft })}
-                          disabled={updateMutation.isPending}
+                          onClick={() => onSave(sphere)}
+                          disabled={!canEdit || updateMutation.isPending}
                         >
                           {t('focal.spheres.actions.save')}
                         </Button>
@@ -357,6 +388,7 @@ export const SpheresPage = () => {
                           variant="ghost"
                           className="gap-2"
                           onClick={() => startEdit(sphere)}
+                          disabled={!canEdit}
                         >
                           <Pencil className="h-4 w-4" aria-hidden="true" />
                           {t('focal.spheres.actions.edit')}
@@ -366,8 +398,8 @@ export const SpheresPage = () => {
                           size="sm"
                           variant="ghost"
                           className="gap-2 text-destructive"
-                          onClick={() => deleteMutation.mutate(sphere.id)}
-                          disabled={deleteMutation.isPending}
+                          onClick={() => onDelete(sphere.id)}
+                          disabled={!canEdit || deleteMutation.isPending}
                         >
                           <Trash2 className="h-4 w-4" aria-hidden="true" />
                           {t('focal.spheres.actions.delete')}
diff --git a/apps/focal/client/src/features/tags/TagsPage.test.tsx b/apps/focal/client/src/features/tags/TagsPage.test.tsx
index e159f5e..4dd9ea0 100644
--- a/apps/focal/client/src/features/tags/TagsPage.test.tsx
+++ b/apps/focal/client/src/features/tags/TagsPage.test.tsx
@@ -78,7 +78,7 @@ describe('TagsPage', () => {
     await user.click(screen.getByRole('button', { name: i18n.t('focal.tags.actions.save') }))
 
     await waitFor(() =>
-      expect(mocked.createTag).toHaveBeenCalledWith({ name: 'Focus', color: '#22c55e' }),
+      expect(mocked.createTag).toHaveBeenCalledWith({ name: 'Focus', color: '#22c55e' }, null),
     )
   })
 
@@ -171,7 +171,11 @@ describe('TagsPage', () => {
     await user.click(screen.getByRole('button', { name: i18n.t('focal.tags.actions.save') }))
 
     await waitFor(() =>
-      expect(mocked.updateTag).toHaveBeenCalledWith('1', { name: 'Planning', color: '#22c55e' }),
+      expect(mocked.updateTag).toHaveBeenCalledWith(
+        '1',
+        { name: 'Planning', color: '#22c55e' },
+        null,
+      ),
     )
     await waitFor(() => expect(mocked.listTags).toHaveBeenCalledTimes(2))
   })
@@ -247,7 +251,7 @@ describe('TagsPage', () => {
 
     await user.click(screen.getByRole('button', { name: i18n.t('focal.tags.actions.delete') }))
 
-    await waitFor(() => expect(mocked.deleteTag).toHaveBeenCalledWith('1'))
+    await waitFor(() => expect(mocked.deleteTag).toHaveBeenCalledWith('1', null))
     await waitFor(() => expect(mocked.listTags).toHaveBeenCalledTimes(2))
   })
 
diff --git a/apps/focal/client/src/features/tags/TagsPage.tsx b/apps/focal/client/src/features/tags/TagsPage.tsx
index a9481aa..1da2701 100644
--- a/apps/focal/client/src/features/tags/TagsPage.tsx
+++ b/apps/focal/client/src/features/tags/TagsPage.tsx
@@ -2,13 +2,14 @@ import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
 import { Check, Pencil, Plus, Search, Tags, Trash2, X } from 'lucide-react'
 import { useMemo, useState } from 'react'
 import { useTranslation } from 'react-i18next'
-
+import { withCal } from '@/api/queryKeys'
 import { PageToolbar } from '@/components/PageToolbar'
 import { Badge } from '@/components/ui/badge'
 import { Button } from '@/components/ui/button'
 import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
 import { Input } from '@/components/ui/input'
 import { SidebarTrigger, useSidebarOptional } from '@/components/ui/sidebar'
+import { useCalendarFilter } from '@/features/calendars/CalendarFilterContext'
 
 import { createTag, deleteTag, listTags, type Tag, type TagCreate, updateTag } from '../../api/tags'
 
@@ -61,11 +62,15 @@ const ColorSwatches = ({
 export const TagsPage = () => {
   const { t } = useTranslation()
   const queryClient = useQueryClient()
+  const { currentCalendarId, canEdit } = useCalendarFilter()
   // The collapse toggle only renders inside the sidebar shell, so the page stays renderable
   // standalone (e.g. in tests) — same pattern as PageHeader.
   const sidebar = useSidebarOptional()
 
-  const tags = useQuery({ queryKey: TAGS_KEY, queryFn: listTags })
+  const tags = useQuery({
+    queryKey: withCal(TAGS_KEY, currentCalendarId),
+    queryFn: () => listTags(currentCalendarId),
+  })
 
   const [searchQuery, setSearchQuery] = useState('')
   const [isAdding, setIsAdding] = useState(false)
@@ -82,7 +87,8 @@ export const TagsPage = () => {
     return query ? list.filter((tag) => tag.name.toLowerCase().includes(query)) : list
   }, [tags.data, searchQuery])
 
-  const invalidate = () => queryClient.invalidateQueries({ queryKey: TAGS_KEY })
+  const invalidate = () =>
+    queryClient.invalidateQueries({ queryKey: withCal(TAGS_KEY, currentCalendarId) })
 
   const onMutationError = (error: unknown) =>
     setErrorMessage(
@@ -92,7 +98,7 @@ export const TagsPage = () => {
     )
 
   const createMutation = useMutation({
-    mutationFn: (input: TagCreate) => createTag(input),
+    mutationFn: (input: TagCreate) => createTag(input, currentCalendarId),
     onSuccess: async () => {
       setIsAdding(false)
       setNewName('')
@@ -105,7 +111,7 @@ export const TagsPage = () => {
 
   const updateMutation = useMutation({
     mutationFn: (vars: { id: string; name: string; color: string }) =>
-      updateTag(vars.id, { name: vars.name, color: vars.color }),
+      updateTag(vars.id, { name: vars.name, color: vars.color }, currentCalendarId),
     onSuccess: async () => {
       setEditingId(null)
       setErrorMessage(null)
@@ -115,7 +121,7 @@ export const TagsPage = () => {
   })
 
   const deleteMutation = useMutation({
-    mutationFn: (id: string) => deleteTag(id),
+    mutationFn: (id: string) => deleteTag(id, currentCalendarId),
     onSuccess: async () => {
       setErrorMessage(null)
       await invalidate()
@@ -135,6 +141,7 @@ export const TagsPage = () => {
   }
 
   const submitAdd = () => {
+    if (!canEdit) return
     if (!newName.trim()) return
     createMutation.mutate({ name: newName.trim(), color: newColor })
   }
@@ -147,6 +154,7 @@ export const TagsPage = () => {
   }
 
   const submitEdit = () => {
+    if (!canEdit) return
     if (!editingId || !editName.trim()) return
     updateMutation.mutate({ id: editingId, name: editName.trim(), color: editColor })
   }
@@ -186,7 +194,7 @@ export const TagsPage = () => {
   )
 
   const addButton = (
-    <Button type="button" className="shrink-0 gap-2" onClick={openAdd}>
+    <Button type="button" className="shrink-0 gap-2" onClick={openAdd} disabled={!canEdit}>
       <Plus className="h-4 w-4" aria-hidden="true" />
       {t('focal.tags.add')}
     </Button>
@@ -214,6 +222,12 @@ export const TagsPage = () => {
 
       <div className="flex-1 overflow-auto p-4 md:p-6">
         <div className="mx-auto max-w-3xl space-y-4">
+          {!canEdit && (
+            <p className="rounded-md border bg-muted/40 px-3 py-2 text-muted-foreground text-sm">
+              {t('focal.app.calendarFilter.readOnlyNotice')}
+            </p>
+          )}
+
           {errorMessage && (
             <p
               role="alert"
@@ -334,6 +348,7 @@ export const TagsPage = () => {
                       variant="ghost"
                       size="icon"
                       onClick={() => startEdit(tag)}
+                      disabled={!canEdit}
                       aria-label={t('focal.tags.actions.edit')}
                     >
                       <Pencil className="h-4 w-4" aria-hidden="true" />
@@ -343,7 +358,7 @@ export const TagsPage = () => {
                       variant="ghost"
                       size="icon"
                       onClick={() => deleteMutation.mutate(tag.id)}
-                      disabled={deleteMutation.isPending}
+                      disabled={!canEdit || deleteMutation.isPending}
                       aria-label={t('focal.tags.actions.delete')}
                     >
                       <Trash2 className="h-4 w-4" aria-hidden="true" />
diff --git a/apps/focal/client/src/features/tasks/TasksPage.test.tsx b/apps/focal/client/src/features/tasks/TasksPage.test.tsx
index eea21f2..78075c8 100644
--- a/apps/focal/client/src/features/tasks/TasksPage.test.tsx
+++ b/apps/focal/client/src/features/tasks/TasksPage.test.tsx
@@ -379,11 +379,14 @@ describe('TasksPage', () => {
     await user.click(screen.getByRole('button', { name: labels.formSubmit() }))
 
     await waitFor(() =>
-      expect(mocked.createTask).toHaveBeenCalledWith({
-        title: 'Write spec',
-        priority: 'medium',
-        projectId: null,
-      }),
+      expect(mocked.createTask).toHaveBeenCalledWith(
+        {
+          title: 'Write spec',
+          priority: 'medium',
+          projectId: null,
+        },
+        null,
+      ),
     )
   })
 
@@ -400,11 +403,14 @@ describe('TasksPage', () => {
     await user.click(screen.getByRole('button', { name: labels.formSubmit() }))
 
     await waitFor(() =>
-      expect(mocked.createTask).toHaveBeenCalledWith({
-        title: 'Write spec',
-        priority: 'medium',
-        projectId: 'p1',
-      }),
+      expect(mocked.createTask).toHaveBeenCalledWith(
+        {
+          title: 'Write spec',
+          priority: 'medium',
+          projectId: 'p1',
+        },
+        null,
+      ),
     )
   })
 
@@ -418,7 +424,9 @@ describe('TasksPage', () => {
 
     await user.click(screen.getByRole('checkbox'))
 
-    await waitFor(() => expect(mocked.updateTask).toHaveBeenCalledWith('1', { completed: true }))
+    await waitFor(() =>
+      expect(mocked.updateTask).toHaveBeenCalledWith('1', { completed: true }, null),
+    )
     await waitFor(() => expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['tasks'] }))
   })
 
@@ -432,7 +440,7 @@ describe('TasksPage', () => {
 
     await user.click(screen.getByRole('button', { name: labels.delete() }))
 
-    await waitFor(() => expect(mocked.deleteTask).toHaveBeenCalledWith('1'))
+    await waitFor(() => expect(mocked.deleteTask).toHaveBeenCalledWith('1', null))
     await waitFor(() => expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['tasks'] }))
   })
 
diff --git a/apps/focal/client/src/features/tasks/TasksPage.tsx b/apps/focal/client/src/features/tasks/TasksPage.tsx
index 42ff179..acee7cd 100644
--- a/apps/focal/client/src/features/tasks/TasksPage.tsx
+++ b/apps/focal/client/src/features/tasks/TasksPage.tsx
@@ -3,11 +3,13 @@ import { AlertTriangle, CheckSquare, Filter, Pencil, Plus, Trash2 } from 'lucide
 import { type FormEvent, type ReactElement, useMemo, useRef, useState } from 'react'
 import { useTranslation } from 'react-i18next'
 
+import { withCal } from '@/api/queryKeys'
 import { PageHeader } from '@/components/PageHeader'
 import { Badge } from '@/components/ui/badge'
 import { Button } from '@/components/ui/button'
 import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
 import { Checkbox } from '@/components/ui/checkbox'
+import { useCalendarFilter } from '@/features/calendars/CalendarFilterContext'
 
 import { listProjects } from '../../api/projects'
 import {
@@ -57,6 +59,7 @@ interface TaskRowProps {
   onToggle: (task: Task, completed: boolean) => void
   onDelete: (id: string) => void
   deleting: boolean
+  canEdit: boolean
   t: Translate
 }
 
@@ -68,6 +71,7 @@ const ActiveTaskRow = ({
   onToggle,
   onDelete,
   deleting,
+  canEdit,
   t,
 }: TaskRowProps): ReactElement => {
   const orphanReason = task.orphanReason
@@ -94,6 +98,7 @@ const ActiveTaskRow = ({
       <Checkbox
         checked={task.completed ?? false}
         onCheckedChange={(checked) => onToggle(task, checked === true)}
+        disabled={!canEdit}
         aria-label={t('focal.tasks.actions.toggleComplete')}
       />
       {task.isOrphan && <AlertTriangle className="h-4 w-4 text-red-500 shrink-0" />}
@@ -132,7 +137,7 @@ const ActiveTaskRow = ({
         size="icon"
         variant="ghost"
         onClick={() => onDelete(task.id)}
-        disabled={deleting}
+        disabled={deleting || !canEdit}
         aria-label={t('focal.tasks.actions.delete')}
       >
         <Trash2 className="h-4 w-4" />
@@ -149,6 +154,7 @@ const CompletedTaskRow = ({
   onToggle,
   onDelete,
   deleting,
+  canEdit,
   t,
 }: TaskRowProps): ReactElement => (
   <div
@@ -169,6 +175,7 @@ const CompletedTaskRow = ({
     <Checkbox
       checked={task.completed ?? false}
       onCheckedChange={(checked) => onToggle(task, checked === true)}
+      disabled={!canEdit}
       aria-label={t('focal.tasks.actions.toggleComplete')}
     />
     <span className="flex-1 line-through">{task.title}</span>
@@ -176,7 +183,7 @@ const CompletedTaskRow = ({
       size="icon"
       variant="ghost"
       onClick={() => onDelete(task.id)}
-      disabled={deleting}
+      disabled={deleting || !canEdit}
       aria-label={t('focal.tasks.actions.delete')}
     >
       <Trash2 className="h-4 w-4" />
@@ -187,9 +194,16 @@ const CompletedTaskRow = ({
 export const TasksPage = () => {
   const { t } = useTranslation()
   const queryClient = useQueryClient()
+  const { currentCalendarId, canEdit } = useCalendarFilter()
 
-  const tasks = useQuery({ queryKey: TASKS_KEY, queryFn: () => listTasks() })
-  const projects = useQuery({ queryKey: ['projects'], queryFn: () => listProjects() })
+  const tasks = useQuery({
+    queryKey: withCal(TASKS_KEY, currentCalendarId),
+    queryFn: () => listTasks({}, currentCalendarId),
+  })
+  const projects = useQuery({
+    queryKey: withCal(['projects'], currentCalendarId),
+    queryFn: () => listProjects(currentCalendarId),
+  })
 
   // Quick-add draft (the interim create path; the full dialog is a follow-up).
   const titleInputRef = useRef<HTMLInputElement>(null)
@@ -225,7 +239,7 @@ export const TasksPage = () => {
     )
 
   const createMutation = useMutation({
-    mutationFn: (input: TaskCreate) => createTask(input),
+    mutationFn: (input: TaskCreate) => createTask(input, currentCalendarId),
     onSuccess: async () => {
       setTitle('')
       setErrorMessage(null)
@@ -236,7 +250,7 @@ export const TasksPage = () => {
 
   const toggleMutation = useMutation({
     mutationFn: ({ task, completed }: { task: Task; completed: boolean }) =>
-      updateTask(task.id, { completed }),
+      updateTask(task.id, { completed }, currentCalendarId),
     onSuccess: async () => {
       setErrorMessage(null)
       await invalidate()
@@ -245,7 +259,7 @@ export const TasksPage = () => {
   })
 
   const deleteMutation = useMutation({
-    mutationFn: (id: string) => deleteTask(id),
+    mutationFn: (id: string) => deleteTask(id, currentCalendarId),
     onSuccess: async () => {
       setErrorMessage(null)
       await invalidate()
@@ -255,12 +269,19 @@ export const TasksPage = () => {
 
   const onCreate = (event: FormEvent<HTMLFormElement>) => {
     event.preventDefault()
+    if (!canEdit) return
     if (!title.trim()) return
     createMutation.mutate({ title: title.trim(), priority, projectId: projectId || null })
   }
 
-  const onToggle = (task: Task, completed: boolean) => toggleMutation.mutate({ task, completed })
-  const onDelete = (id: string) => deleteMutation.mutate(id)
+  const onToggle = (task: Task, completed: boolean) => {
+    if (!canEdit) return
+    toggleMutation.mutate({ task, completed })
+  }
+  const onDelete = (id: string) => {
+    if (!canEdit) return
+    deleteMutation.mutate(id)
+  }
 
   const allTasks = tasks.data ?? []
   const filtered = allTasks.filter((task) => {
@@ -287,7 +308,7 @@ export const TasksPage = () => {
     <Button
       size="icon"
       onClick={() => titleInputRef.current?.focus()}
-      disabled={createMutation.isPending}
+      disabled={createMutation.isPending || !canEdit}
       aria-label={t('focal.tasks.actions.add')}
     >
       <Plus className="h-4 w-4" />
@@ -393,12 +414,22 @@ export const TasksPage = () => {
                 </option>
               ))}
             </select>
-            <Button type="submit" disabled={createMutation.isPending} className="gap-1.5">
+            <Button
+              type="submit"
+              disabled={createMutation.isPending || !canEdit}
+              className="gap-1.5"
+            >
               <Plus className="h-4 w-4" />
               {t('focal.tasks.form.submit')}
             </Button>
           </form>
 
+          {!canEdit && (
+            <p className="rounded-md border border-border bg-muted/50 px-3 py-2 text-sm text-muted-foreground">
+              {t('focal.app.calendarFilter.readOnlyNotice')}
+            </p>
+          )}
+
           {tasks.isLoading && (
             <div className="py-8 text-center text-muted-foreground">{t('focal.tasks.loading')}</div>
           )}
@@ -424,6 +455,7 @@ export const TasksPage = () => {
                         onToggle={onToggle}
                         onDelete={onDelete}
                         deleting={deleteMutation.isPending}
+                        canEdit={canEdit}
                         t={t}
                       />
                     ))}
@@ -447,6 +479,7 @@ export const TasksPage = () => {
                         onToggle={onToggle}
                         onDelete={onDelete}
                         deleting={deleteMutation.isPending}
+                        canEdit={canEdit}
                         t={t}
                       />
                     ))}
diff --git a/apps/focal/client/src/i18n/locales/en.json b/apps/focal/client/src/i18n/locales/en.json
index 5c0bcaa..a652caa 100644
--- a/apps/focal/client/src/i18n/locales/en.json
+++ b/apps/focal/client/src/i18n/locales/en.json
@@ -183,6 +183,7 @@
         "calendarFilter": {
           "loadError": "Couldn't load calendars",
           "myCalendars": "My calendars",
+          "readOnlyNotice": "Read-only — you don't have permission to edit this calendar.",
           "retry": "Retry",
           "roles": {
             "developer": "Developer",
diff --git a/apps/focal/client/src/i18n/locales/ru.json b/apps/focal/client/src/i18n/locales/ru.json
index 8a4f3f7..ac0cc44 100644
--- a/apps/focal/client/src/i18n/locales/ru.json
+++ b/apps/focal/client/src/i18n/locales/ru.json
@@ -187,6 +187,7 @@
         "calendarFilter": {
           "loadError": "Не удалось загрузить календари",
           "myCalendars": "Мои календари",
+          "readOnlyNotice": "Только просмотр — у вас нет прав на редактирование этого календаря.",
           "retry": "Повторить",
           "roles": {
             "developer": "Разработчик",
diff --git a/apps/focal/server/app/ai/chat_support.py b/apps/focal/server/app/ai/chat_support.py
index 9c3a6fa..3b30d49 100644
--- a/apps/focal/server/app/ai/chat_support.py
+++ b/apps/focal/server/app/ai/chat_support.py
@@ -145,9 +145,13 @@ def memory_scope(conversation_id: str, data_owner: str, auth_user_id: str) -> st
     return conversation_id.strip()[:100]
 
 
-def resolve_data_owner(body_user_id: object, auth_user_id: str) -> str:
-    """The data owner for the request: the body's userId only when it is a UUID (a
-    shared-calendar view); the authenticated user otherwise. Never trusts free text."""
+def memory_scope_owner(body_user_id: object, auth_user_id: str) -> str:
+    """The owner component of the conversation-MEMORY scope key only — NOT a data-access decision.
+    Returns the body's userId when it is a UUID, else the authenticated user, so a shared-calendar
+    bucket's memory clears under the same key the chat route wrote it with. It does NOT authorize
+    access to that owner's data and must NOT be used to scope reads/writes — it deliberately trusts
+    any UUID (the rows it keys are themselves filtered by the authenticated user_id). For RBAC-gated
+    data-owner resolution use ``app.data_scope.resolve_ai_data_owner``."""
     if isinstance(body_user_id, str) and UUID_RE.match(body_user_id.strip()):
         return body_user_id.strip()
     return auth_user_id
diff --git a/apps/focal/server/app/api/activities.py b/apps/focal/server/app/api/activities.py
index 7118fb6..bd96471 100644
--- a/apps/focal/server/app/api/activities.py
+++ b/apps/focal/server/app/api/activities.py
@@ -2,13 +2,16 @@ from collections.abc import AsyncIterator
 
 from fastapi import APIRouter, Depends, status
 
+from app.data_scope import DataDomain, data_owner_dep
 from app.db import get_sessionmaker
-from app.deps import get_current_user_id
 from app.schemas.activities import ActivityCreate, ActivityRead, ActivityUpdate
 from app.services.activities import ActivitiesService
 
 router = APIRouter(prefix="/api/activities", tags=["activities"])
 
+_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
+_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
+
 
 async def get_activities_service() -> AsyncIterator[ActivitiesService]:
     # DB-backed only: the cascade/transaction behavior is DB-semantic.
@@ -18,7 +21,7 @@ async def get_activities_service() -> AsyncIterator[ActivitiesService]:
 
 @router.get("", response_model=list[ActivityRead])
 async def list_activities(
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: ActivitiesService = Depends(get_activities_service),
 ) -> list[ActivityRead]:
     return await service.list_activities(user_id)
@@ -27,7 +30,7 @@ async def list_activities(
 @router.post("", response_model=ActivityRead, status_code=status.HTTP_201_CREATED)
 async def create_activity(
     payload: ActivityCreate,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: ActivitiesService = Depends(get_activities_service),
 ) -> ActivityRead:
     return await service.create_activity(user_id, payload)
@@ -36,7 +39,7 @@ async def create_activity(
 @router.get("/{activity_id}", response_model=ActivityRead)
 async def get_activity(
     activity_id: str,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: ActivitiesService = Depends(get_activities_service),
 ) -> ActivityRead:
     return await service.get_activity(user_id, activity_id)
@@ -46,7 +49,7 @@ async def get_activity(
 async def update_activity(
     activity_id: str,
     payload: ActivityUpdate,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: ActivitiesService = Depends(get_activities_service),
 ) -> ActivityRead:
     return await service.update_activity(user_id, activity_id, payload)
@@ -55,7 +58,7 @@ async def update_activity(
 @router.delete("/{activity_id}")
 async def delete_activity(
     activity_id: str,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: ActivitiesService = Depends(get_activities_service),
 ) -> dict[str, bool]:
     await service.delete_activity(user_id, activity_id)
diff --git a/apps/focal/server/app/api/activity_instances.py b/apps/focal/server/app/api/activity_instances.py
index f4f5ace..9d81485 100644
--- a/apps/focal/server/app/api/activity_instances.py
+++ b/apps/focal/server/app/api/activity_instances.py
@@ -2,8 +2,8 @@ from collections.abc import AsyncIterator
 
 from fastapi import APIRouter, Depends, Query, status
 
+from app.data_scope import DataDomain, data_owner_dep
 from app.db import get_sessionmaker
-from app.deps import get_current_user_id
 from app.schemas.activity_instances import (
     ActivityInstanceCreate,
     ActivityInstanceRead,
@@ -14,6 +14,9 @@ from app.services.activity_instances import ActivityInstancesService
 
 router = APIRouter(prefix="/api/activity-instances", tags=["activity-instances"])
 
+_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
+_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
+
 
 async def get_activity_instances_service() -> AsyncIterator[ActivityInstancesService]:
     # DB-backed only: the booking lifecycle and cascade behavior are DB-semantic.
@@ -24,7 +27,7 @@ async def get_activity_instances_service() -> AsyncIterator[ActivityInstancesSer
 @router.get("", response_model=list[ActivityInstanceRead])
 async def list_activity_instances(
     activity_id: str = Query(alias="activityId"),
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: ActivityInstancesService = Depends(get_activity_instances_service),
 ) -> list[ActivityInstanceRead]:
     return await service.list_instances(user_id, activity_id)
@@ -33,7 +36,7 @@ async def list_activity_instances(
 @router.post("", response_model=ActivityInstanceRead, status_code=status.HTTP_201_CREATED)
 async def create_activity_instance(
     payload: ActivityInstanceCreate,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: ActivityInstancesService = Depends(get_activity_instances_service),
 ) -> ActivityInstanceRead:
     return await service.create_instance(user_id, payload)
@@ -43,7 +46,7 @@ async def create_activity_instance(
 @router.post("/sync", response_model=list[ActivityInstanceRead])
 async def sync_activity_instances(
     payload: ActivityInstanceSyncRequest,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: ActivityInstancesService = Depends(get_activity_instances_service),
 ) -> list[ActivityInstanceRead]:
     return await service.sync_instances(user_id, payload)
@@ -52,7 +55,7 @@ async def sync_activity_instances(
 @router.get("/{instance_id}", response_model=ActivityInstanceRead)
 async def get_activity_instance(
     instance_id: str,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: ActivityInstancesService = Depends(get_activity_instances_service),
 ) -> ActivityInstanceRead:
     return await service.get_instance(user_id, instance_id)
@@ -62,7 +65,7 @@ async def get_activity_instance(
 async def update_activity_instance(
     instance_id: str,
     payload: ActivityInstanceUpdate,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: ActivityInstancesService = Depends(get_activity_instances_service),
 ) -> ActivityInstanceRead:
     return await service.update_instance(user_id, instance_id, payload)
@@ -71,7 +74,7 @@ async def update_activity_instance(
 @router.delete("/{instance_id}")
 async def delete_activity_instance(
     instance_id: str,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: ActivityInstancesService = Depends(get_activity_instances_service),
 ) -> dict[str, bool]:
     await service.delete_instance(user_id, instance_id)
diff --git a/apps/focal/server/app/api/ai.py b/apps/focal/server/app/api/ai.py
index 722c422..057fc45 100644
--- a/apps/focal/server/app/api/ai.py
+++ b/apps/focal/server/app/api/ai.py
@@ -17,8 +17,8 @@ from app.ai.chat_support import (
     format_question_for_display,
     get_fallback_questions,
     memory_scope,
+    memory_scope_owner,
     normalize_question,
-    resolve_data_owner,
 )
 from app.ai_gateway import log_ai_gateway_event
 from app.db import get_sessionmaker
@@ -109,7 +109,7 @@ async def clear_conversation(
     """Clear the server-side dialog memory for one bucket. The scope key recomputes
     with the same formula the chat route uses when writing, so shared-calendar buckets
     clear correctly. resetType="reset" marks an implicit tab/owner switch in telemetry."""
-    owner = resolve_data_owner(data_owner_id, user_id)
+    owner = memory_scope_owner(data_owner_id, user_id)
     effective_scope = memory_scope(conversation_id, owner, user_id)
     failed_event = (
         "CONVERSATION_RESET_FAILED" if reset_type == "reset" else "CONVERSATION_CLEAR_FAILED"
diff --git a/apps/focal/server/app/api/ai_chat.py b/apps/focal/server/app/api/ai_chat.py
index fe5f243..1cfce64 100644
--- a/apps/focal/server/app/api/ai_chat.py
+++ b/apps/focal/server/app/api/ai_chat.py
@@ -38,7 +38,6 @@ from app.ai.chat_support import (
     get_tab_label,
     load_conversation_history,
     memory_scope,
-    resolve_data_owner,
 )
 from app.ai.embeddings import (
     MAX_PROMPT_INPUT_TOKENS,
@@ -68,8 +67,9 @@ from app.ai_gateway import (
 )
 from app.api.ai import get_ai_session, router
 from app.config import get_settings
+from app.data_scope import DataDomain, require_ai_write, resolve_ai_data_owner
 from app.deps import get_current_tier, get_current_user_id
-from app.errors import AppError, ValidationError
+from app.errors import AppError, PermissionDeniedError, ValidationError
 from app.models.activities import Activity
 
 log = structlog.get_logger(__name__)
@@ -201,7 +201,7 @@ async def ai_chat(
 
     effective_tab_id = (payload.tab_id or "").strip() or "calendar"
     effective_view = (payload.view_type or "").strip() or "default"
-    data_owner = resolve_data_owner(payload.user_id, auth_user_id)
+    data_owner = await resolve_ai_data_owner(session, auth_user_id, payload.user_id)
     scope_id = memory_scope(effective_tab_id, data_owner, auth_user_id)
     tab_label = get_tab_label(effective_tab_id)
     tab_context_line = (
@@ -250,6 +250,12 @@ async def ai_chat(
         else (classification.target_entity if use_gpt_entity else resolved_tab_id)
     )
 
+    # Shared-calendar MANAGEMENT (the "calendars" entity) is owner-only and NOT delegatable: a
+    # full_access/developer assistant resolved to another owner must not read or create that owner's
+    # shared calendars/participants through the AI (it falls under the other-pages gate otherwise).
+    if data_owner != auth_user_id and target_entity == "calendars":
+        raise PermissionDeniedError("Shared-calendar management is not available for another user")
+
     async def reply_general(text: str, *, save: bool = True) -> dict[str, Any]:
         if save:
             await append_conversation_messages(
@@ -307,6 +313,16 @@ async def ai_chat(
             "Что именно создать? Уточните: событие, задачу или что-то другое."
         )
 
+    if classification.intent == "create" and data_owner != auth_user_id:
+        await require_ai_write(
+            session,
+            auth_user_id,
+            data_owner,
+            domain=DataDomain.CALENDAR
+            if (target_entity or "") in ("calendar", "events")
+            else DataDomain.OTHER_PAGES,
+        )
+
     if classification.intent in ("query", "analytics", "create"):
         user_tz = _sanitize_timezone(payload.display_timezone)
         now_hours, now_minutes = _now_in_timezone(user_tz) if user_tz else (None, None)
diff --git a/apps/focal/server/app/api/analytics.py b/apps/focal/server/app/api/analytics.py
index 47ce347..72f6aca 100644
--- a/apps/focal/server/app/api/analytics.py
+++ b/apps/focal/server/app/api/analytics.py
@@ -3,13 +3,16 @@ from datetime import date
 
 from fastapi import APIRouter, Depends, Query
 
+from app.data_scope import DataDomain, data_owner_dep
 from app.db import get_sessionmaker
-from app.deps import get_current_user_id
 from app.schemas.analytics import SpheresAnalyticsRead
 from app.services.analytics import AnalyticsService
 
 router = APIRouter(prefix="/api/analytics", tags=["analytics"])
 
+_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
+_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
+
 
 async def get_analytics_service() -> AsyncIterator[AnalyticsService]:
     async with get_sessionmaker()() as session:
@@ -20,7 +23,7 @@ async def get_analytics_service() -> AsyncIterator[AnalyticsService]:
 async def spheres_analytics(
     period_start: date = Query(..., alias="periodStart"),
     period_end: date = Query(..., alias="periodEnd"),
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: AnalyticsService = Depends(get_analytics_service),
 ) -> SpheresAnalyticsRead:
     return await service.spheres(user_id, period_start=period_start, period_end=period_end)
diff --git a/apps/focal/server/app/api/bookings.py b/apps/focal/server/app/api/bookings.py
index 3bbef8f..92cdf5a 100644
--- a/apps/focal/server/app/api/bookings.py
+++ b/apps/focal/server/app/api/bookings.py
@@ -7,6 +7,7 @@ from app.db import get_sessionmaker
 from app.deps import current_utc_date, get_current_user_id
 from app.schemas.bookings import BookingCreate, BookingRead, BookingUpdate
 from app.services.bookings import BookingsService
+from app.services.shared_calendars import SharedCalendarsService
 
 router = APIRouter(prefix="/api/bookings", tags=["bookings"])
 
@@ -16,23 +17,40 @@ async def get_bookings_service() -> AsyncIterator[BookingsService]:
         yield BookingsService(session)
 
 
+async def get_shared_service() -> AsyncIterator[SharedCalendarsService]:
+    # In shared mode (a `calendarId` is supplied) bookings are RBAC-gated and held to the calendar's
+    # saved filter (bookings carry project links) through this service — the scope invariant.
+    async with get_sessionmaker()() as session:
+        yield SharedCalendarsService(session)
+
+
 @router.get("", response_model=list[BookingRead])
 async def list_bookings(
     start_date: str | None = Query(default=None, alias="startDate"),
     end_date: str | None = Query(default=None, alias="endDate"),
+    calendar_id: str | None = Query(default=None, alias="calendarId"),
     user_id: str = Depends(get_current_user_id),
     today: date = Depends(current_utc_date),
     service: BookingsService = Depends(get_bookings_service),
+    shared: SharedCalendarsService = Depends(get_shared_service),
 ) -> list[BookingRead]:
+    if calendar_id:
+        return await shared.list_bookings(
+            user_id, calendar_id, start=start_date, end=end_date, today=today
+        )
     return await service.list_bookings(user_id, start=start_date, end=end_date, today=today)
 
 
 @router.post("", response_model=BookingRead)
 async def create_booking(
     payload: BookingCreate,
+    calendar_id: str | None = Query(default=None, alias="calendarId"),
     user_id: str = Depends(get_current_user_id),
     service: BookingsService = Depends(get_bookings_service),
+    shared: SharedCalendarsService = Depends(get_shared_service),
 ) -> BookingRead:
+    if calendar_id:
+        return await shared.create_booking(user_id, calendar_id, payload)
     return await service.create_booking(user_id, payload)
 
 
@@ -41,9 +59,13 @@ async def create_booking(
 @router.get("/{booking_id}", response_model=BookingRead)
 async def get_booking(
     booking_id: str,
+    calendar_id: str | None = Query(default=None, alias="calendarId"),
     user_id: str = Depends(get_current_user_id),
     service: BookingsService = Depends(get_bookings_service),
+    shared: SharedCalendarsService = Depends(get_shared_service),
 ) -> BookingRead:
+    if calendar_id:
+        return await shared.get_booking(user_id, calendar_id, booking_id)
     return await service.get_booking(user_id, booking_id)
 
 
@@ -51,17 +73,26 @@ async def get_booking(
 async def update_booking(
     booking_id: str,
     payload: BookingUpdate,
+    calendar_id: str | None = Query(default=None, alias="calendarId"),
     user_id: str = Depends(get_current_user_id),
     service: BookingsService = Depends(get_bookings_service),
+    shared: SharedCalendarsService = Depends(get_shared_service),
 ) -> BookingRead:
+    if calendar_id:
+        return await shared.update_booking(user_id, calendar_id, booking_id, payload)
     return await service.update_booking(user_id, booking_id, payload)
 
 
 @router.delete("/{booking_id}", status_code=status.HTTP_204_NO_CONTENT)
 async def delete_booking(
     booking_id: str,
+    calendar_id: str | None = Query(default=None, alias="calendarId"),
     user_id: str = Depends(get_current_user_id),
     service: BookingsService = Depends(get_bookings_service),
+    shared: SharedCalendarsService = Depends(get_shared_service),
 ) -> Response:
-    await service.delete_booking(user_id, booking_id)
+    if calendar_id:
+        await shared.delete_booking(user_id, calendar_id, booking_id)
+    else:
+        await service.delete_booking(user_id, booking_id)
     return Response(status_code=status.HTTP_204_NO_CONTENT)
diff --git a/apps/focal/server/app/api/calendar.py b/apps/focal/server/app/api/calendar.py
index c54ecb0..97cc34f 100644
--- a/apps/focal/server/app/api/calendar.py
+++ b/apps/focal/server/app/api/calendar.py
@@ -7,6 +7,7 @@ from app.db import get_sessionmaker
 from app.deps import current_utc_date, get_current_user_id
 from app.schemas.calendar import EnrichedEventRead, EventCreate, EventUpdate
 from app.services.calendar import CalendarService
+from app.services.shared_calendars import SharedCalendarsService
 
 router = APIRouter(prefix="/api/events", tags=["events"])
 
@@ -18,23 +19,40 @@ async def get_calendar_service() -> AsyncIterator[CalendarService]:
         yield CalendarService(session)
 
 
+async def get_shared_service() -> AsyncIterator[SharedCalendarsService]:
+    # In shared mode (a `calendarId` is supplied) every event read/write is RBAC-gated and held to
+    # the calendar's saved filter through this service — the calendar-domain scope invariant.
+    async with get_sessionmaker()() as session:
+        yield SharedCalendarsService(session)
+
+
 @router.get("", response_model=list[EnrichedEventRead])
 async def list_events(
     start_date: str | None = Query(default=None, alias="startDate"),
     end_date: str | None = Query(default=None, alias="endDate"),
+    calendar_id: str | None = Query(default=None, alias="calendarId"),
     user_id: str = Depends(get_current_user_id),
     today: date = Depends(current_utc_date),
     service: CalendarService = Depends(get_calendar_service),
+    shared: SharedCalendarsService = Depends(get_shared_service),
 ) -> list[EnrichedEventRead]:
+    if calendar_id:
+        return await shared.list_events(
+            user_id, calendar_id, start=start_date, end=end_date, today=today
+        )
     return await service.list_events(user_id, start=start_date, end=end_date, today=today)
 
 
 @router.post("", response_model=EnrichedEventRead)
 async def create_event(
     payload: EventCreate,
+    calendar_id: str | None = Query(default=None, alias="calendarId"),
     user_id: str = Depends(get_current_user_id),
     service: CalendarService = Depends(get_calendar_service),
+    shared: SharedCalendarsService = Depends(get_shared_service),
 ) -> EnrichedEventRead:
+    if calendar_id:
+        return await shared.create_event(user_id, calendar_id, payload)
     return await service.create_event(user_id, payload)
 
 
@@ -43,9 +61,13 @@ async def create_event(
 @router.get("/{event_id}", response_model=EnrichedEventRead)
 async def get_event(
     event_id: str,
+    calendar_id: str | None = Query(default=None, alias="calendarId"),
     user_id: str = Depends(get_current_user_id),
     service: CalendarService = Depends(get_calendar_service),
+    shared: SharedCalendarsService = Depends(get_shared_service),
 ) -> EnrichedEventRead:
+    if calendar_id:
+        return await shared.get_event(user_id, calendar_id, event_id)
     return await service.get_event(user_id, event_id)
 
 
@@ -58,9 +80,20 @@ async def update_event(
     payload: EventUpdate,
     recurrence_scope: str | None = Query(default=None, alias="recurrenceScope"),
     occurrence_date: date | None = Query(default=None, alias="occurrenceDate"),
+    calendar_id: str | None = Query(default=None, alias="calendarId"),
     user_id: str = Depends(get_current_user_id),
     service: CalendarService = Depends(get_calendar_service),
+    shared: SharedCalendarsService = Depends(get_shared_service),
 ) -> EnrichedEventRead:
+    if calendar_id:
+        return await shared.update_event(
+            user_id,
+            calendar_id,
+            event_id,
+            payload,
+            scope=recurrence_scope,
+            occurrence_date=occurrence_date,
+        )
     return await service.update_event(
         user_id, event_id, payload, scope=recurrence_scope, occurrence_date=occurrence_date
     )
@@ -71,10 +104,21 @@ async def delete_event(
     event_id: str,
     recurrence_scope: str | None = Query(default=None, alias="recurrenceScope"),
     occurrence_date: date | None = Query(default=None, alias="occurrenceDate"),
+    calendar_id: str | None = Query(default=None, alias="calendarId"),
     user_id: str = Depends(get_current_user_id),
     service: CalendarService = Depends(get_calendar_service),
+    shared: SharedCalendarsService = Depends(get_shared_service),
 ) -> Response:
-    await service.delete_event(
-        user_id, event_id, scope=recurrence_scope, occurrence_date=occurrence_date
-    )
+    if calendar_id:
+        await shared.delete_event(
+            user_id,
+            calendar_id,
+            event_id,
+            scope=recurrence_scope,
+            occurrence_date=occurrence_date,
+        )
+    else:
+        await service.delete_event(
+            user_id, event_id, scope=recurrence_scope, occurrence_date=occurrence_date
+        )
     return Response(status_code=status.HTTP_204_NO_CONTENT)
diff --git a/apps/focal/server/app/api/calendar_init.py b/apps/focal/server/app/api/calendar_init.py
index 20c10fd..c6b5a4c 100644
--- a/apps/focal/server/app/api/calendar_init.py
+++ b/apps/focal/server/app/api/calendar_init.py
@@ -7,6 +7,7 @@ from app.db import get_sessionmaker
 from app.deps import current_utc_date, get_current_user_id
 from app.schemas.calendar import CalendarInitRead
 from app.services.calendar_init import CalendarInitService
+from app.services.shared_calendars import SharedCalendarsService
 
 router = APIRouter(prefix="/api/calendar", tags=["calendar"])
 
@@ -16,12 +17,34 @@ async def get_calendar_init_service() -> AsyncIterator[CalendarInitService]:
         yield CalendarInitService(session)
 
 
+async def get_shared_service() -> AsyncIterator[SharedCalendarsService]:
+    async with get_sessionmaker()() as session:
+        yield SharedCalendarsService(session)
+
+
 @router.get("/init", response_model=CalendarInitRead)
 async def calendar_init(
     start_date: str | None = Query(default=None, alias="startDate"),
     end_date: str | None = Query(default=None, alias="endDate"),
+    calendar_id: str | None = Query(default=None, alias="calendarId"),
     user_id: str = Depends(get_current_user_id),
     today: date = Depends(current_utc_date),
     service: CalendarInitService = Depends(get_calendar_init_service),
+    shared: SharedCalendarsService = Depends(get_shared_service),
 ) -> CalendarInitRead:
-    return await service.get_init(user_id, start=start_date, end=end_date, today=today)
+    if not calendar_id:
+        return await service.get_init(user_id, start=start_date, end=end_date, today=today)
+    # Shared mode — mixed aggregate: events + bookings filtered via the calendar gate; tasks +
+    # projects only when the caller may view the owner's other pages (init_scope resolves all).
+    events, bookings, owner_id, include_other_pages = await shared.init_scope(
+        user_id, calendar_id, start=start_date, end=end_date, today=today
+    )
+    return await service.get_shared_init(
+        owner_id,
+        events=events,
+        bookings=bookings,
+        include_other_pages=include_other_pages,
+        start=start_date,
+        end=end_date,
+        today=today,
+    )
diff --git a/apps/focal/server/app/api/goals.py b/apps/focal/server/app/api/goals.py
index 07307e1..229ea9b 100644
--- a/apps/focal/server/app/api/goals.py
+++ b/apps/focal/server/app/api/goals.py
@@ -2,13 +2,16 @@ from collections.abc import AsyncIterator
 
 from fastapi import APIRouter, Depends, status
 
+from app.data_scope import DataDomain, data_owner_dep
 from app.db import get_sessionmaker
-from app.deps import get_current_user_id
 from app.schemas.goals import GoalCreate, GoalRead, GoalUpdate
 from app.services.goals import GoalsService
 
 router = APIRouter(prefix="/api/goals", tags=["goals"])
 
+_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
+_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
+
 
 async def get_goals_service() -> AsyncIterator[GoalsService]:
     async with get_sessionmaker()() as session:
@@ -17,7 +20,7 @@ async def get_goals_service() -> AsyncIterator[GoalsService]:
 
 @router.get("", response_model=list[GoalRead])
 async def list_goals(
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: GoalsService = Depends(get_goals_service),
 ) -> list[GoalRead]:
     return await service.list_goals(user_id)
@@ -26,7 +29,7 @@ async def list_goals(
 @router.post("", response_model=GoalRead, status_code=status.HTTP_201_CREATED)
 async def create_goal(
     payload: GoalCreate,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: GoalsService = Depends(get_goals_service),
 ) -> GoalRead:
     return await service.create_goal(user_id, payload)
@@ -35,7 +38,7 @@ async def create_goal(
 @router.get("/{goal_id}", response_model=GoalRead)
 async def get_goal(
     goal_id: str,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: GoalsService = Depends(get_goals_service),
 ) -> GoalRead:
     return await service.get_goal(user_id, goal_id)
@@ -45,7 +48,7 @@ async def get_goal(
 async def update_goal(
     goal_id: str,
     payload: GoalUpdate,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: GoalsService = Depends(get_goals_service),
 ) -> GoalRead:
     return await service.update_goal(user_id, goal_id, payload)
@@ -54,7 +57,7 @@ async def update_goal(
 @router.delete("/{goal_id}")
 async def delete_goal(
     goal_id: str,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: GoalsService = Depends(get_goals_service),
 ) -> dict[str, bool]:
     await service.delete_goal(user_id, goal_id)
diff --git a/apps/focal/server/app/api/habit_entries.py b/apps/focal/server/app/api/habit_entries.py
index 33a320c..1e3bfa5 100644
--- a/apps/focal/server/app/api/habit_entries.py
+++ b/apps/focal/server/app/api/habit_entries.py
@@ -4,18 +4,21 @@ from typing import Literal
 from fastapi import APIRouter, Depends, Query, Response, status
 
 from app.api.habits import get_habits_service
-from app.deps import get_current_user_id
+from app.data_scope import DataDomain, data_owner_dep
 from app.schemas.habit import HabitEntryRead, HabitEntryStatRead, HabitEntryUpsert
 from app.services.habits import HabitsService
 
 router = APIRouter(prefix="/api/habit-entries", tags=["habit-entries"])
 
+_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
+_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
+
 
 @router.get("", response_model=list[HabitEntryRead])
 async def list_habit_entries(
     start: date = Query(...),
     end: date = Query(...),
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: HabitsService = Depends(get_habits_service),
 ) -> list[HabitEntryRead]:
     return await service.list_entries(user_id, start=start, end=end)
@@ -26,7 +29,7 @@ async def habit_entry_stats(
     start: date = Query(...),
     end: date = Query(...),
     granularity: Literal["day", "month"] = Query(default="month"),
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: HabitsService = Depends(get_habits_service),
 ) -> list[HabitEntryStatRead]:
     return await service.entry_stats(user_id, start=start, end=end, granularity=granularity)
@@ -35,7 +38,7 @@ async def habit_entry_stats(
 @router.post("", response_model=HabitEntryRead, status_code=status.HTTP_201_CREATED)
 async def upsert_habit_entry(
     payload: HabitEntryUpsert,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: HabitsService = Depends(get_habits_service),
 ) -> HabitEntryRead:
     return await service.upsert_entry(user_id, payload)
@@ -45,7 +48,7 @@ async def upsert_habit_entry(
 async def delete_habit_entry(
     habit_id: str = Query(..., alias="habitId"),
     entry_date: date = Query(..., alias="date"),
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: HabitsService = Depends(get_habits_service),
 ) -> Response:
     await service.delete_entry(user_id, habit_id=habit_id, day=entry_date)
diff --git a/apps/focal/server/app/api/habits.py b/apps/focal/server/app/api/habits.py
index ba24842..b22a65c 100644
--- a/apps/focal/server/app/api/habits.py
+++ b/apps/focal/server/app/api/habits.py
@@ -3,13 +3,16 @@ from datetime import date
 
 from fastapi import APIRouter, Depends, Query, Response, status
 
+from app.data_scope import DataDomain, data_owner_dep
 from app.db import get_sessionmaker
-from app.deps import get_current_user_id
 from app.schemas.habit import HabitCreate, HabitRead, HabitReorder, HabitStreakRead, HabitUpdate
 from app.services.habits import HabitsService
 
 router = APIRouter(prefix="/api/habits", tags=["habits"])
 
+_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
+_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
+
 
 async def get_habits_service() -> AsyncIterator[HabitsService]:
     async with get_sessionmaker()() as session:
@@ -19,7 +22,7 @@ async def get_habits_service() -> AsyncIterator[HabitsService]:
 @router.get("", response_model=list[HabitRead])
 async def list_habits(
     archived: bool = Query(default=False),
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: HabitsService = Depends(get_habits_service),
 ) -> list[HabitRead]:
     return await service.list_habits(user_id, archived=archived)
@@ -29,7 +32,7 @@ async def list_habits(
 @router.post("/reorder", status_code=status.HTTP_204_NO_CONTENT)
 async def reorder_habits(
     payload: HabitReorder,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: HabitsService = Depends(get_habits_service),
 ) -> Response:
     await service.reorder_habits(user_id, payload.ordered_ids)
@@ -39,7 +42,7 @@ async def reorder_habits(
 @router.post("", response_model=HabitRead, status_code=status.HTTP_201_CREATED)
 async def create_habit(
     payload: HabitCreate,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: HabitsService = Depends(get_habits_service),
 ) -> HabitRead:
     return await service.create_habit(user_id, payload)
@@ -49,7 +52,7 @@ async def create_habit(
 @router.get("/streaks", response_model=list[HabitStreakRead])
 async def habit_streaks(
     today: date = Query(...),
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: HabitsService = Depends(get_habits_service),
 ) -> list[HabitStreakRead]:
     return await service.streaks(user_id, today)
@@ -58,7 +61,7 @@ async def habit_streaks(
 @router.get("/{habit_id}", response_model=HabitRead)
 async def get_habit(
     habit_id: str,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: HabitsService = Depends(get_habits_service),
 ) -> HabitRead:
     return await service.get_habit(user_id, habit_id)
@@ -68,7 +71,7 @@ async def get_habit(
 async def update_habit(
     habit_id: str,
     payload: HabitUpdate,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: HabitsService = Depends(get_habits_service),
 ) -> HabitRead:
     return await service.update_habit(user_id, habit_id, payload)
@@ -77,7 +80,7 @@ async def update_habit(
 @router.delete("/{habit_id}", status_code=status.HTTP_204_NO_CONTENT)
 async def delete_habit(
     habit_id: str,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: HabitsService = Depends(get_habits_service),
 ) -> Response:
     await service.delete_habit(user_id, habit_id)
@@ -87,7 +90,7 @@ async def delete_habit(
 @router.post("/{habit_id}/restore", response_model=HabitRead)
 async def restore_habit(
     habit_id: str,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: HabitsService = Depends(get_habits_service),
 ) -> HabitRead:
     return await service.restore_habit(user_id, habit_id)
diff --git a/apps/focal/server/app/api/meeting_requests.py b/apps/focal/server/app/api/meeting_requests.py
index cef6c69..3a4bf62 100644
--- a/apps/focal/server/app/api/meeting_requests.py
+++ b/apps/focal/server/app/api/meeting_requests.py
@@ -2,13 +2,20 @@ from collections.abc import AsyncIterator
 
 from fastapi import APIRouter, Depends, Query, Response, status
 
+from app.data_scope import DataDomain, data_owner_dep
 from app.db import get_sessionmaker
-from app.deps import get_current_user_id
 from app.schemas.meeting_request import MeetingRequestActionRead, MeetingRequestRead
 from app.services.meeting_requests import MeetingRequestsService
 
 router = APIRouter(prefix="/api/meeting-requests", tags=["meeting-requests"])
 
+# Calendar-domain: read = any accepted participant, write (responding to / deleting an owner's
+# request) = canEdit. `_owner_*` resolves the data owner from `calendarId`; the same `calendarId`
+# also scopes each request to the selected calendar (requests carry `shared_calendar_id`), so a
+# participant of one calendar never reads/acts on the owner's requests for another.
+_owner_read = data_owner_dep(DataDomain.CALENDAR, "read")
+_owner_write = data_owner_dep(DataDomain.CALENDAR, "write")
+
 
 async def get_meeting_requests_service() -> AsyncIterator[MeetingRequestsService]:
     async with get_sessionmaker()() as session:
@@ -19,79 +26,92 @@ async def get_meeting_requests_service() -> AsyncIterator[MeetingRequestsService
 @router.get("", response_model=list[MeetingRequestRead])
 async def list_meeting_requests(
     status_filter: str | None = Query(default=None, alias="status"),
-    user_id: str = Depends(get_current_user_id),
+    calendar_id: str | None = Query(default=None, alias="calendarId"),
+    user_id: str = Depends(_owner_read),
     service: MeetingRequestsService = Depends(get_meeting_requests_service),
 ) -> list[MeetingRequestRead]:
-    return await service.list_requests(user_id, status=status_filter)
+    return await service.list_requests(user_id, status=status_filter, calendar_id=calendar_id)
 
 
 @router.get("/count")
 async def meeting_requests_count(
-    user_id: str = Depends(get_current_user_id),
+    calendar_id: str | None = Query(default=None, alias="calendarId"),
+    user_id: str = Depends(_owner_read),
     service: MeetingRequestsService = Depends(get_meeting_requests_service),
 ) -> dict[str, int]:
-    return {"count": await service.pending_count(user_id)}
+    return {"count": await service.pending_count(user_id, calendar_id=calendar_id)}
 
 
 @router.get("/{request_id}", response_model=MeetingRequestRead)
 async def get_meeting_request(
     request_id: str,
-    user_id: str = Depends(get_current_user_id),
+    calendar_id: str | None = Query(default=None, alias="calendarId"),
+    user_id: str = Depends(_owner_read),
     service: MeetingRequestsService = Depends(get_meeting_requests_service),
 ) -> MeetingRequestRead:
-    return await service.get_request(user_id, request_id)
+    return await service.get_request(user_id, request_id, calendar_id=calendar_id)
 
 
 @router.delete("/{request_id}", status_code=status.HTTP_204_NO_CONTENT)
 async def delete_meeting_request(
     request_id: str,
-    user_id: str = Depends(get_current_user_id),
+    calendar_id: str | None = Query(default=None, alias="calendarId"),
+    user_id: str = Depends(_owner_write),
     service: MeetingRequestsService = Depends(get_meeting_requests_service),
 ) -> Response:
-    await service.delete_request(user_id, request_id)
+    await service.delete_request(user_id, request_id, calendar_id=calendar_id)
     return Response(status_code=status.HTTP_204_NO_CONTENT)
 
 
 @router.post("/{request_id}/accept", response_model=MeetingRequestActionRead)
 async def accept_meeting_request(
     request_id: str,
-    user_id: str = Depends(get_current_user_id),
+    calendar_id: str | None = Query(default=None, alias="calendarId"),
+    user_id: str = Depends(_owner_write),
     service: MeetingRequestsService = Depends(get_meeting_requests_service),
 ) -> MeetingRequestActionRead:
-    return await service.respond(user_id, request_id, "accepted")
+    return await service.respond(user_id, request_id, "accepted", calendar_id=calendar_id)
 
 
 @router.post("/{request_id}/decline", response_model=MeetingRequestActionRead)
 async def decline_meeting_request(
     request_id: str,
-    user_id: str = Depends(get_current_user_id),
+    calendar_id: str | None = Query(default=None, alias="calendarId"),
+    user_id: str = Depends(_owner_write),
     service: MeetingRequestsService = Depends(get_meeting_requests_service),
 ) -> MeetingRequestActionRead:
-    return await service.respond(user_id, request_id, "declined")
+    return await service.respond(user_id, request_id, "declined", calendar_id=calendar_id)
 
 
 @router.post("/{request_id}/tentative", response_model=MeetingRequestActionRead)
 async def tentative_meeting_request(
     request_id: str,
-    user_id: str = Depends(get_current_user_id),
+    calendar_id: str | None = Query(default=None, alias="calendarId"),
+    user_id: str = Depends(_owner_write),
     service: MeetingRequestsService = Depends(get_meeting_requests_service),
 ) -> MeetingRequestActionRead:
-    return await service.respond(user_id, request_id, "tentative")
+    return await service.respond(user_id, request_id, "tentative", calendar_id=calendar_id)
 
 
 @router.post("/{request_id}/accept-reschedule", response_model=MeetingRequestActionRead)
 async def accept_meeting_reschedule(
     request_id: str,
-    user_id: str = Depends(get_current_user_id),
+    calendar_id: str | None = Query(default=None, alias="calendarId"),
+    user_id: str = Depends(_owner_write),
     service: MeetingRequestsService = Depends(get_meeting_requests_service),
 ) -> MeetingRequestActionRead:
-    return await service.respond_reschedule(user_id, request_id, accept=True)
+    return await service.respond_reschedule(
+        user_id, request_id, accept=True, calendar_id=calendar_id
+    )
 
 
 @router.post("/{request_id}/decline-reschedule", response_model=MeetingRequestActionRead)
 async def decline_meeting_reschedule(
     request_id: str,
-    user_id: str = Depends(get_current_user_id),
+    calendar_id: str | None = Query(default=None, alias="calendarId"),
+    user_id: str = Depends(_owner_write),
     service: MeetingRequestsService = Depends(get_meeting_requests_service),
 ) -> MeetingRequestActionRead:
-    return await service.respond_reschedule(user_id, request_id, accept=False)
+    return await service.respond_reschedule(
+        user_id, request_id, accept=False, calendar_id=calendar_id
+    )
diff --git a/apps/focal/server/app/api/mindmap.py b/apps/focal/server/app/api/mindmap.py
index 6d26bd3..c45e36c 100644
--- a/apps/focal/server/app/api/mindmap.py
+++ b/apps/focal/server/app/api/mindmap.py
@@ -2,13 +2,16 @@ from collections.abc import AsyncIterator
 
 from fastapi import APIRouter, Depends, Response, status
 
+from app.data_scope import DataDomain, data_owner_dep
 from app.db import get_sessionmaker
-from app.deps import get_current_user_id
 from app.schemas.mindmap import BatchNodes, EdgeRead, EdgeUpsert, InitRead, NodeRead, NodeUpsert
 from app.services.mindmap import MindmapService
 
 router = APIRouter(tags=["mindmap"])
 
+_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
+_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
+
 
 async def get_mindmap_service() -> AsyncIterator[MindmapService]:
     # DB-backed only: the composite-PK upsert + transactional batch are DB-semantic.
@@ -18,7 +21,7 @@ async def get_mindmap_service() -> AsyncIterator[MindmapService]:
 
 @router.get("/api/mindmap/init", response_model=InitRead)
 async def mindmap_init(
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: MindmapService = Depends(get_mindmap_service),
 ) -> InitRead:
     return await service.get_init(user_id)
@@ -29,7 +32,7 @@ async def mindmap_init(
 
 @router.get("/api/mindmap-nodes", response_model=list[NodeRead])
 async def list_nodes(
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: MindmapService = Depends(get_mindmap_service),
 ) -> list[NodeRead]:
     return await service.list_nodes(user_id)
@@ -38,7 +41,7 @@ async def list_nodes(
 @router.post("/api/mindmap-nodes/batch", response_model=list[NodeRead])
 async def batch_nodes(
     payload: BatchNodes,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: MindmapService = Depends(get_mindmap_service),
 ) -> list[NodeRead]:
     return await service.batch_upsert_nodes(user_id, payload.nodes)
@@ -49,7 +52,7 @@ async def batch_nodes(
 @router.get("/api/mindmap-nodes/{node_id}", response_model=NodeRead)
 async def get_node(
     node_id: str,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: MindmapService = Depends(get_mindmap_service),
 ) -> NodeRead:
     return await service.get_node(user_id, node_id)
@@ -59,7 +62,7 @@ async def get_node(
 async def upsert_node(
     node_id: str,
     payload: NodeUpsert,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: MindmapService = Depends(get_mindmap_service),
 ) -> NodeRead:
     return await service.upsert_node(user_id, node_id, payload)
@@ -68,7 +71,7 @@ async def upsert_node(
 @router.delete("/api/mindmap-nodes/{node_id}", status_code=status.HTTP_204_NO_CONTENT)
 async def delete_node(
     node_id: str,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: MindmapService = Depends(get_mindmap_service),
 ) -> Response:
     await service.delete_node(user_id, node_id)
@@ -80,7 +83,7 @@ async def delete_node(
 
 @router.get("/api/mindmap-edges", response_model=list[EdgeRead])
 async def list_edges(
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: MindmapService = Depends(get_mindmap_service),
 ) -> list[EdgeRead]:
     return await service.list_edges(user_id)
@@ -90,7 +93,7 @@ async def list_edges(
 async def upsert_edge(
     edge_id: str,
     payload: EdgeUpsert,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: MindmapService = Depends(get_mindmap_service),
 ) -> EdgeRead:
     return await service.upsert_edge(user_id, edge_id, payload)
@@ -99,7 +102,7 @@ async def upsert_edge(
 @router.delete("/api/mindmap-edges/{edge_id}", status_code=status.HTTP_204_NO_CONTENT)
 async def delete_edge(
     edge_id: str,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: MindmapService = Depends(get_mindmap_service),
 ) -> Response:
     await service.delete_edge(user_id, edge_id)
diff --git a/apps/focal/server/app/api/projects.py b/apps/focal/server/app/api/projects.py
index 76cfa4b..72024ac 100644
--- a/apps/focal/server/app/api/projects.py
+++ b/apps/focal/server/app/api/projects.py
@@ -2,13 +2,16 @@ from collections.abc import AsyncIterator
 
 from fastapi import APIRouter, Depends, status
 
+from app.data_scope import DataDomain, data_owner_dep
 from app.db import get_sessionmaker
-from app.deps import get_current_user_id
 from app.schemas.projects import ProjectCreate, ProjectRead, ProjectUpdate
 from app.services.projects import ProjectsService
 
 router = APIRouter(prefix="/api/projects", tags=["projects"])
 
+_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
+_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
+
 
 async def get_projects_service() -> AsyncIterator[ProjectsService]:
     # DB-backed only (no in-memory fallback): create-inheritance, the delete cascade, and the
@@ -19,7 +22,7 @@ async def get_projects_service() -> AsyncIterator[ProjectsService]:
 
 @router.get("", response_model=list[ProjectRead])
 async def list_projects(
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: ProjectsService = Depends(get_projects_service),
 ) -> list[ProjectRead]:
     return await service.list_projects(user_id)
@@ -28,7 +31,7 @@ async def list_projects(
 # Declared before "/{project_id}" so the static route is not shadowed by the dynamic one.
 @router.get("/root", response_model=list[ProjectRead])
 async def list_root_projects(
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: ProjectsService = Depends(get_projects_service),
 ) -> list[ProjectRead]:
     return await service.list_root_projects(user_id)
@@ -37,7 +40,7 @@ async def list_root_projects(
 @router.post("", response_model=ProjectRead, status_code=status.HTTP_201_CREATED)
 async def create_project(
     payload: ProjectCreate,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: ProjectsService = Depends(get_projects_service),
 ) -> ProjectRead:
     return await service.create_project(user_id, payload)
@@ -46,7 +49,7 @@ async def create_project(
 @router.get("/{project_id}", response_model=ProjectRead)
 async def get_project(
     project_id: str,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: ProjectsService = Depends(get_projects_service),
 ) -> ProjectRead:
     return await service.get_project(user_id, project_id)
@@ -55,7 +58,7 @@ async def get_project(
 @router.get("/{project_id}/products", response_model=list[ProjectRead])
 async def list_products(
     project_id: str,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: ProjectsService = Depends(get_projects_service),
 ) -> list[ProjectRead]:
     return await service.list_products(user_id, project_id)
@@ -65,7 +68,7 @@ async def list_products(
 async def update_project(
     project_id: str,
     payload: ProjectUpdate,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: ProjectsService = Depends(get_projects_service),
 ) -> ProjectRead:
     return await service.update_project(user_id, project_id, payload)
@@ -74,7 +77,7 @@ async def update_project(
 @router.delete("/{project_id}")
 async def delete_project(
     project_id: str,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: ProjectsService = Depends(get_projects_service),
 ) -> dict[str, bool]:
     await service.delete_project(user_id, project_id)
diff --git a/apps/focal/server/app/api/spheres.py b/apps/focal/server/app/api/spheres.py
index 325d193..f46e83a 100644
--- a/apps/focal/server/app/api/spheres.py
+++ b/apps/focal/server/app/api/spheres.py
@@ -2,13 +2,16 @@ from collections.abc import AsyncIterator
 
 from fastapi import APIRouter, Depends, status
 
+from app.data_scope import DataDomain, data_owner_dep
 from app.db import get_sessionmaker
-from app.deps import get_current_user_id
 from app.schemas.spheres import SphereCreate, SphereRead, SphereUpdate
 from app.services.spheres import SpheresService
 
 router = APIRouter(prefix="/api/spheres", tags=["spheres"])
 
+_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
+_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
+
 
 async def get_spheres_service() -> AsyncIterator[SpheresService]:
     # DB-backed only (no in-memory fallback): the cascade/transaction behavior is DB-semantic.
@@ -18,7 +21,7 @@ async def get_spheres_service() -> AsyncIterator[SpheresService]:
 
 @router.get("", response_model=list[SphereRead])
 async def list_spheres(
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: SpheresService = Depends(get_spheres_service),
 ) -> list[SphereRead]:
     return await service.list_spheres(user_id)
@@ -27,7 +30,7 @@ async def list_spheres(
 @router.post("", response_model=SphereRead, status_code=status.HTTP_201_CREATED)
 async def create_sphere(
     payload: SphereCreate,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: SpheresService = Depends(get_spheres_service),
 ) -> SphereRead:
     return await service.create_sphere(user_id, payload)
@@ -36,7 +39,7 @@ async def create_sphere(
 @router.get("/{sphere_id}", response_model=SphereRead)
 async def get_sphere(
     sphere_id: str,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: SpheresService = Depends(get_spheres_service),
 ) -> SphereRead:
     return await service.get_sphere(user_id, sphere_id)
@@ -46,7 +49,7 @@ async def get_sphere(
 async def update_sphere(
     sphere_id: str,
     payload: SphereUpdate,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: SpheresService = Depends(get_spheres_service),
 ) -> SphereRead:
     return await service.update_sphere(user_id, sphere_id, payload)
@@ -55,7 +58,7 @@ async def update_sphere(
 @router.delete("/{sphere_id}")
 async def delete_sphere(
     sphere_id: str,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: SpheresService = Depends(get_spheres_service),
 ) -> dict[str, bool]:
     await service.delete_sphere(user_id, sphere_id)
diff --git a/apps/focal/server/app/api/stats.py b/apps/focal/server/app/api/stats.py
index 47f12f6..673e6d7 100644
--- a/apps/focal/server/app/api/stats.py
+++ b/apps/focal/server/app/api/stats.py
@@ -3,13 +3,17 @@ from datetime import date
 
 from fastapi import APIRouter, Depends, Query
 
+from app.data_scope import DataDomain, data_owner_dep
 from app.db import get_sessionmaker
-from app.deps import current_utc_date, get_current_user_id
+from app.deps import current_utc_date
 from app.schemas.stats import OrphanStatsRead
 from app.services.stats import StatsService
 
 router = APIRouter(prefix="/api/stats", tags=["stats"])
 
+_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
+_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
+
 
 async def get_stats_service() -> AsyncIterator[StatsService]:
     async with get_sessionmaker()() as session:
@@ -20,7 +24,7 @@ async def get_stats_service() -> AsyncIterator[StatsService]:
 async def orphan_stats(
     start_date: str | None = Query(default=None, alias="startDate"),
     end_date: str | None = Query(default=None, alias="endDate"),
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     today: date = Depends(current_utc_date),
     service: StatsService = Depends(get_stats_service),
 ) -> OrphanStatsRead:
diff --git a/apps/focal/server/app/api/tags.py b/apps/focal/server/app/api/tags.py
index b2728cd..66be3b7 100644
--- a/apps/focal/server/app/api/tags.py
+++ b/apps/focal/server/app/api/tags.py
@@ -3,14 +3,17 @@ from collections.abc import AsyncIterator
 from fastapi import APIRouter, Depends
 
 from app.config import get_settings
+from app.data_scope import DataDomain, data_owner_dep
 from app.db import get_sessionmaker
-from app.deps import get_current_user_id
 from app.schemas.tags import TagCreate, TagRead, TagUpdate
 from app.services.tags import SqlAlchemyTagsRepository, TagsService
 from app.services.tags import tags_service as in_memory_tags_service
 
 router = APIRouter(prefix="/api/tags", tags=["tags"])
 
+_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
+_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
+
 
 async def get_tags_service() -> AsyncIterator[TagsService]:
     """Choose the backing store by config: a real async SQLAlchemy repository when
@@ -25,7 +28,7 @@ async def get_tags_service() -> AsyncIterator[TagsService]:
 
 @router.get("", response_model=list[TagRead])
 async def list_tags(
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: TagsService = Depends(get_tags_service),
 ) -> list[TagRead]:
     return await service.list_tags(user_id)
@@ -34,7 +37,7 @@ async def list_tags(
 @router.post("", response_model=TagRead)
 async def create_tag(
     payload: TagCreate,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: TagsService = Depends(get_tags_service),
 ) -> TagRead:
     return await service.create_tag(user_id, payload)
@@ -44,7 +47,7 @@ async def create_tag(
 async def update_tag(
     tag_id: str,
     payload: TagUpdate,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: TagsService = Depends(get_tags_service),
 ) -> TagRead:
     return await service.update_tag(user_id, tag_id, payload)
@@ -53,7 +56,7 @@ async def update_tag(
 @router.delete("/{tag_id}")
 async def delete_tag(
     tag_id: str,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: TagsService = Depends(get_tags_service),
 ) -> dict[str, bool]:
     await service.delete_tag(user_id, tag_id)
diff --git a/apps/focal/server/app/api/tasks.py b/apps/focal/server/app/api/tasks.py
index 7e1628b..ab85268 100644
--- a/apps/focal/server/app/api/tasks.py
+++ b/apps/focal/server/app/api/tasks.py
@@ -3,13 +3,17 @@ from datetime import date
 
 from fastapi import APIRouter, Depends, Query
 
+from app.data_scope import DataDomain, data_owner_dep
 from app.db import get_sessionmaker
-from app.deps import current_utc_date, get_current_user_id
+from app.deps import current_utc_date
 from app.schemas.tasks import EnrichedTaskRead, TaskCreate, TaskRead, TaskUpdate
 from app.services.tasks import TasksService
 
 router = APIRouter(prefix="/api/tasks", tags=["tasks"])
 
+_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
+_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
+
 
 async def get_tasks_service() -> AsyncIterator[TasksService]:
     # DB-backed only (no in-memory fallback): the enrichment join, link-ownership, and the
@@ -22,7 +26,7 @@ async def get_tasks_service() -> AsyncIterator[TasksService]:
 async def list_tasks(
     start_date: str | None = Query(default=None, alias="startDate"),
     end_date: str | None = Query(default=None, alias="endDate"),
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     today: date = Depends(current_utc_date),
     service: TasksService = Depends(get_tasks_service),
 ) -> list[EnrichedTaskRead]:
@@ -32,7 +36,7 @@ async def list_tasks(
 @router.post("", response_model=TaskRead)
 async def create_task(
     payload: TaskCreate,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     today: date = Depends(current_utc_date),
     service: TasksService = Depends(get_tasks_service),
 ) -> TaskRead:
@@ -44,7 +48,7 @@ async def create_task(
 @router.get("/{task_id}", response_model=EnrichedTaskRead)
 async def get_task(
     task_id: str,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: TasksService = Depends(get_tasks_service),
 ) -> EnrichedTaskRead:
     return await service.get_task(user_id, task_id)
@@ -54,7 +58,7 @@ async def get_task(
 async def update_task(
     task_id: str,
     payload: TaskUpdate,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     today: date = Depends(current_utc_date),
     service: TasksService = Depends(get_tasks_service),
 ) -> TaskRead:
@@ -64,7 +68,7 @@ async def update_task(
 @router.delete("/{task_id}")
 async def delete_task(
     task_id: str,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: TasksService = Depends(get_tasks_service),
 ) -> dict[str, bool]:
     await service.delete_task(user_id, task_id)
diff --git a/apps/focal/server/app/api/time_budgets.py b/apps/focal/server/app/api/time_budgets.py
index 20ab03b..6521dc2 100644
--- a/apps/focal/server/app/api/time_budgets.py
+++ b/apps/focal/server/app/api/time_budgets.py
@@ -2,8 +2,8 @@ from collections.abc import AsyncIterator
 
 from fastapi import APIRouter, Depends, Response, status
 
+from app.data_scope import DataDomain, data_owner_dep
 from app.db import get_sessionmaker
-from app.deps import get_current_user_id
 from app.schemas.time_budget import (
     TimeBudgetCategoryCreate,
     TimeBudgetCategoryRead,
@@ -22,6 +22,9 @@ from app.services.time_budgets import TimeBudgetsService
 
 router = APIRouter(prefix="/api/time-budgets", tags=["time-budgets"])
 
+_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
+_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
+
 
 async def get_time_budgets_service() -> AsyncIterator[TimeBudgetsService]:
     async with get_sessionmaker()() as session:
@@ -31,7 +34,7 @@ async def get_time_budgets_service() -> AsyncIterator[TimeBudgetsService]:
 @router.get("/{year}", response_model=TimeBudgetYearRead)
 async def get_time_budget_year(
     year: int,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_read),
     service: TimeBudgetsService = Depends(get_time_budgets_service),
 ) -> TimeBudgetYearRead:
     return await service.get_year(user_id, year)
@@ -41,7 +44,7 @@ async def get_time_budget_year(
 async def update_time_budget_settings(
     settings_id: str,
     payload: TimeBudgetSettingsUpdate,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: TimeBudgetsService = Depends(get_time_budgets_service),
 ) -> TimeBudgetSettingsRead:
     return await service.update_settings(user_id, settings_id, payload)
@@ -52,7 +55,7 @@ async def update_time_budget_settings(
 )
 async def create_category(
     payload: TimeBudgetCategoryCreate,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: TimeBudgetsService = Depends(get_time_budgets_service),
 ) -> TimeBudgetCategoryRead:
     return await service.create_category(user_id, payload)
@@ -62,7 +65,7 @@ async def create_category(
 async def update_category(
     category_id: str,
     payload: TimeBudgetCategoryUpdate,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: TimeBudgetsService = Depends(get_time_budgets_service),
 ) -> TimeBudgetCategoryRead:
     return await service.update_category(user_id, category_id, payload)
@@ -71,7 +74,7 @@ async def update_category(
 @router.delete("/categories/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
 async def delete_category(
     category_id: str,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: TimeBudgetsService = Depends(get_time_budgets_service),
 ) -> Response:
     await service.delete_category(user_id, category_id)
@@ -83,7 +86,7 @@ async def delete_category(
 )
 async def create_subcategory(
     payload: TimeBudgetSubcategoryCreate,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: TimeBudgetsService = Depends(get_time_budgets_service),
 ) -> TimeBudgetSubcategoryRead:
     return await service.create_subcategory(user_id, payload)
@@ -93,7 +96,7 @@ async def create_subcategory(
 async def update_subcategory(
     subcategory_id: str,
     payload: TimeBudgetSubcategoryUpdate,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: TimeBudgetsService = Depends(get_time_budgets_service),
 ) -> TimeBudgetSubcategoryRead:
     return await service.update_subcategory(user_id, subcategory_id, payload)
@@ -102,7 +105,7 @@ async def update_subcategory(
 @router.delete("/subcategories/{subcategory_id}", status_code=status.HTTP_204_NO_CONTENT)
 async def delete_subcategory(
     subcategory_id: str,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: TimeBudgetsService = Depends(get_time_budgets_service),
 ) -> Response:
     await service.delete_subcategory(user_id, subcategory_id)
@@ -112,7 +115,7 @@ async def delete_subcategory(
 @router.post("/items", response_model=TimeBudgetItemRead, status_code=status.HTTP_201_CREATED)
 async def create_item(
     payload: TimeBudgetItemCreate,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: TimeBudgetsService = Depends(get_time_budgets_service),
 ) -> TimeBudgetItemRead:
     return await service.create_item(user_id, payload)
@@ -122,7 +125,7 @@ async def create_item(
 async def update_item(
     item_id: str,
     payload: TimeBudgetItemUpdate,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: TimeBudgetsService = Depends(get_time_budgets_service),
 ) -> TimeBudgetItemRead:
     return await service.update_item(user_id, item_id, payload)
@@ -131,7 +134,7 @@ async def update_item(
 @router.delete("/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
 async def delete_item(
     item_id: str,
-    user_id: str = Depends(get_current_user_id),
+    user_id: str = Depends(_owner_write),
     service: TimeBudgetsService = Depends(get_time_budgets_service),
 ) -> Response:
     await service.delete_item(user_id, item_id)
diff --git a/apps/focal/server/app/data_scope.py b/apps/focal/server/app/data_scope.py
new file mode 100644
index 0000000..5fb9834
--- /dev/null
+++ b/apps/focal/server/app/data_scope.py
@@ -0,0 +1,184 @@
+"""Assistant-mode data scoping — the load-bearing cross-user authorization boundary.
+
+When a shared-calendar participant views/edits the calendar OWNER's data (rather than their own),
+the only thing standing between caller C and owner O's rows is the RBAC check here: the domain
+service sessions bypass RLS, so the app-layer ``WHERE user_id == effective_owner`` filter is the
+tenant boundary and ``resolve_data_owner`` chooses ``effective_owner``. Get the role sets wrong and
+it leaks.
+
+The gates are NOT uniform — they split by domain, tracking the two shared-calendar permission
+dimensions (``can_edit`` = event editing; ``can_view_other_pages`` = access to non-calendar pages):
+
+- **calendar** (events / calendar-init / bookings / meeting-requests): READ = any accepted
+  participant (viewer+); WRITE = ``can_edit`` (owner / full_access / editor).
+- **other-pages** (tasks/projects/activities/mindmap/goals/spheres/time-budgets/tags/habits/…):
+  READ = ``can_view_other_pages`` (owner/full_access/developer); WRITE = that ∩ write
+  (owner/full_access — a ``developer`` is read-only and an ``editor`` cannot view other pages).
+
+Checks are set-membership, not rank: developer/viewer/requester share rank 10 yet differ across
+these sets. Calendar-domain endpoints additionally enforce the calendar's saved filter server-side
+(list reads via the filtered shared path, by-id/create validated against the filter) — that scope
+enforcement lives at each calendar endpoint; this module resolves the owner + authorizes the role.
+"""
+
+import re
+from collections.abc import AsyncIterator
+from enum import StrEnum
+
+from fastapi import Depends, Query
+from sqlalchemy import select
+from sqlalchemy.ext.asyncio import AsyncSession
+
+from app.db import get_sessionmaker
+from app.deps import get_current_user_id
+from app.errors import NotFoundError, PermissionDeniedError
+from app.models.shared_calendar import SharedCalendar, SharedCalendarParticipant
+from app.rbac import get_resource_role
+
+_UUID_RE = re.compile(
+    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
+)
+
+
+class DataDomain(StrEnum):
+    """Which gate set a route's data falls under (see module docstring)."""
+
+    CALENDAR = "calendar"
+    OTHER_PAGES = "other_pages"
+
+
+# Role sets per (domain, action). Set-membership, never rank (developer != viewer at rank 10).
+CALENDAR_READ_ROLES = frozenset(
+    {"owner", "full_access", "editor", "developer", "viewer", "requester"}
+)  # any accepted participant may read the shared calendar's events
+CALENDAR_WRITE_ROLES = frozenset({"owner", "full_access", "editor"})  # == can_edit
+OTHER_PAGES_READ_ROLES = frozenset({"owner", "full_access", "developer"})  # == can_view_other_pages
+OTHER_PAGES_WRITE_ROLES = frozenset({"owner", "full_access"})  # can_view_other_pages ∩ write
+
+_GATES: dict[tuple[DataDomain, str], frozenset[str]] = {
+    (DataDomain.CALENDAR, "read"): CALENDAR_READ_ROLES,
+    (DataDomain.CALENDAR, "write"): CALENDAR_WRITE_ROLES,
+    (DataDomain.OTHER_PAGES, "read"): OTHER_PAGES_READ_ROLES,
+    (DataDomain.OTHER_PAGES, "write"): OTHER_PAGES_WRITE_ROLES,
+}
+
+
+async def resolve_data_owner(
+    session: AsyncSession,
+    caller_id: str,
+    calendar_id: str | None,
+    *,
+    domain: DataDomain,
+    action: str = "read",
+) -> str:
+    """The effective data owner for the request, authorized by the caller's shared-calendar role.
+
+    ``calendar_id`` absent → the caller's own data (today's behavior, backward compatible). Else the
+    calendar is resolved; if the caller owns it the owner is the caller (own data); otherwise the
+    caller's accepted participant role must be in the gate for ``(domain, action)`` — else 403 — and
+    the calendar owner's id is returned for the service to filter by. A missing calendar → 404.
+    """
+    if not calendar_id:
+        return caller_id
+    calendar = await session.get(SharedCalendar, calendar_id)
+    if calendar is None:
+        raise NotFoundError("Shared calendar not found")
+    if calendar.user_id == caller_id:
+        return caller_id  # the caller's own calendar → own data, full access
+    role = await get_resource_role(session, calendar_id, caller_id)
+    if role is None or role not in _GATES[(domain, action)]:
+        raise PermissionDeniedError(
+            "Insufficient role for this data on the shared calendar"
+        )
+    return calendar.user_id
+
+
+async def _scope_session(
+    calendarId: str | None = Query(default=None),
+) -> AsyncIterator[AsyncSession | None]:
+    """A short-lived session for the RBAC lookup, independent of the route's service session
+    (mirrors ``rbac._rbac_session``). Opened ONLY in shared mode (a ``calendarId`` is supplied) —
+    an own-data request never touches the DB engine, so the DB-free in-memory path (no
+    ``DATABASE_URL``) keeps working exactly as before this slice."""
+    if not calendarId:
+        yield None
+        return
+    async with get_sessionmaker()() as session:
+        yield session
+
+
+def data_owner_dep(domain: DataDomain, action: str = "read"):
+    """FastAPI dependency factory: resolves the effective data owner from an optional ``calendarId``
+    query param + the caller's role, gated by ``(domain, action)``. Drop-in replacement for
+    ``Depends(get_current_user_id)`` on a scoped route — returns the owner id to filter by. With no
+    ``calendarId`` it returns the caller WITHOUT opening a session (own-data, backward compatible).
+    """
+
+    async def dependency(
+        calendarId: str | None = Query(default=None),
+        caller_id: str = Depends(get_current_user_id),
+        session: AsyncSession | None = Depends(_scope_session),
+    ) -> str:
+        if not calendarId or session is None:
+            return caller_id
+        return await resolve_data_owner(
+            session, caller_id, calendarId, domain=domain, action=action
+        )
+
+    return dependency
+
+
+# --- AI chat scoping ---------------------------------------------------------
+# The AI chat carries a target owner id (not a calendar id), so it can't use the calendar-keyed
+# dependency above. These resolve the caller's best accepted role across ALL calendars owned by the
+# target and gate against the same role sets — closing the IDOR where any UUID was trusted.
+
+
+async def accepted_assist_roles(
+    session: AsyncSession, caller_id: str, owner_id: str
+) -> frozenset[str]:
+    """ALL accepted participant roles the caller holds across calendars owned by ``owner_id``
+    (``{"owner"}`` when the caller IS the owner; empty when there is no accepted participation). The
+    AI gates test set-membership against this — NOT a single "best" role: developer/viewer/requester
+    share a ``ROLE_RANK`` yet differ across the gate sets, so a rank-max could pick a tied role that
+    fails the gate while another held role would have passed."""
+    if caller_id == owner_id:
+        return frozenset({"owner"})
+    rows = await session.execute(
+        select(SharedCalendarParticipant.role)
+        .join(SharedCalendar, SharedCalendar.id == SharedCalendarParticipant.shared_calendar_id)
+        .where(
+            SharedCalendar.user_id == owner_id,
+            SharedCalendarParticipant.user_id == caller_id,
+            SharedCalendarParticipant.invite_status == "accepted",
+        )
+    )
+    return frozenset(role for (role,) in rows.all())
+
+
+async def resolve_ai_data_owner(session: AsyncSession, caller_id: str, requested: object) -> str:
+    """The AI chat's effective data owner, RBAC-gated (closes the IDOR). A client-supplied target
+    owner is served ONLY if the caller holds an other-pages READ role (owner/full_access/developer)
+    on a calendar owned by that user — otherwise 403. Absent / non-UUID / own id → the caller."""
+    if not isinstance(requested, str):
+        return caller_id
+    target = requested.strip()
+    if not target or target == caller_id or not _UUID_RE.match(target):
+        return caller_id
+    roles = await accepted_assist_roles(session, caller_id, target)
+    if not (roles & OTHER_PAGES_READ_ROLES):
+        raise PermissionDeniedError("Not authorized to view this user's data")
+    return target
+
+
+async def require_ai_write(
+    session: AsyncSession, caller_id: str, owner_id: str, *, domain: DataDomain
+) -> None:
+    """Before an AI create/update/delete intent writes the owner's data, require the caller to hold
+    a role in that domain's write gate (calendar → owner/full_access/editor; other-pages →
+    owner/full_access). No-op when the caller is the owner."""
+    if caller_id == owner_id:
+        return
+    roles = await accepted_assist_roles(session, caller_id, owner_id)
+    if not (roles & _GATES[(domain, "write")]):
+        raise PermissionDeniedError("Not authorized to modify this user's data")
diff --git a/apps/focal/server/app/services/activities.py b/apps/focal/server/app/services/activities.py
index 8e7f4f6..9539781 100644
--- a/apps/focal/server/app/services/activities.py
+++ b/apps/focal/server/app/services/activities.py
@@ -1,8 +1,9 @@
 from sqlalchemy import select
 from sqlalchemy.ext.asyncio import AsyncSession
 
-from app.errors import NotFoundError
+from app.errors import NotFoundError, RelatedRecordNotFoundError
 from app.models.activities import Activity
+from app.models.projects import Project
 from app.schemas.activities import ActivityCreate, ActivityRead, ActivityUpdate
 
 
@@ -28,8 +29,10 @@ class ActivitiesService:
     async def create_activity(self, user_id: str, payload: ActivityCreate) -> ActivityRead:
         # Set only the fields the client sent so the model's column defaults apply to the rest
         # (e.g. status="planned", positions 0) instead of being overwritten with null.
+        data = payload.model_dump(exclude_unset=True)
+        await self._require_owned_links(user_id, data.get("project_id"), data.get("product_id"))
         activity = Activity(user_id=user_id)
-        for field, value in payload.model_dump(exclude_unset=True).items():
+        for field, value in data.items():
             setattr(activity, field, value)
         self.session.add(activity)
         await self.session.commit()
@@ -40,12 +43,26 @@ class ActivitiesService:
         self, user_id: str, activity_id: str, payload: ActivityUpdate
     ) -> ActivityRead:
         activity = await self._require(user_id, activity_id)
-        for field, value in payload.model_dump(exclude_unset=True).items():
+        data = payload.model_dump(exclude_unset=True)
+        await self._require_owned_links(user_id, data.get("project_id"), data.get("product_id"))
+        for field, value in data.items():
             setattr(activity, field, value)
         await self.session.commit()
         await self.session.refresh(activity)
         return ActivityRead.model_validate(activity)
 
+    async def _require_owned_links(
+        self, user_id: str, project_id: str | None, product_id: str | None
+    ) -> None:
+        """A project_id/product_id must belong to the data owner. In a delegated (shared assistant)
+        write the payload could otherwise point the owner's activity at the CALLER's own project and
+        then cascade-delete the owner's row by deleting that project — so reject non-owned links."""
+        for link_id in (project_id, product_id):
+            if link_id is not None:
+                project = await self.session.get(Project, link_id)
+                if project is None or project.user_id != user_id:
+                    raise RelatedRecordNotFoundError("Related record not found")
+
     async def delete_activity(self, user_id: str, activity_id: str) -> None:
         activity = await self._require(user_id, activity_id)
         await self.session.delete(activity)
diff --git a/apps/focal/server/app/services/activity_instances.py b/apps/focal/server/app/services/activity_instances.py
index 066b1b6..9bd0c6f 100644
--- a/apps/focal/server/app/services/activity_instances.py
+++ b/apps/focal/server/app/services/activity_instances.py
@@ -1,7 +1,7 @@
 from sqlalchemy import select
 from sqlalchemy.ext.asyncio import AsyncSession
 
-from app.errors import NotFoundError
+from app.errors import NotFoundError, RelatedRecordNotFoundError
 from app.models.activities import Activity
 from app.models.activity_instances import ActivityInstance
 from app.models.bookings import Booking
@@ -99,6 +99,12 @@ class ActivityInstancesService:
     async def sync_instances(
         self, user_id: str, payload: ActivityInstanceSyncRequest
     ) -> list[ActivityInstanceRead]:
+        # The activity must belong to the data owner — a delegated (shared assistant) write must not
+        # attach the owner's instances to the CALLER's own activity (and then cascade-delete them by
+        # deleting that activity).
+        activity = await self.session.get(Activity, payload.activity_id)
+        if activity is None or activity.user_id != user_id:
+            raise RelatedRecordNotFoundError("Related record not found")
         result = await self.session.execute(
             select(ActivityInstance)
             .where(
diff --git a/apps/focal/server/app/services/calendar.py b/apps/focal/server/app/services/calendar.py
index 3de00bc..830e28c 100644
--- a/apps/focal/server/app/services/calendar.py
+++ b/apps/focal/server/app/services/calendar.py
@@ -1,4 +1,5 @@
 import datetime
+from dataclasses import dataclass
 from datetime import UTC
 from typing import Any
 from uuid import uuid4
@@ -26,6 +27,21 @@ from app.models.calendar import CalendarEvent, CalendarEventOverride
 from app.models.projects import Project
 from app.schemas.calendar import EnrichedEventRead, EventCreate, EventRead, EventUpdate
 
+
+@dataclass
+class ProjectedFilterEvent:
+    """An un-persisted event's filterable projection (the FilterableEvent shape) — the fields a
+    create/update WOULD enrich to from its project links, for a shared-calendar filter check made
+    BEFORE the row is written (so a rejected write never persists). Not frozen: the FilterableEvent
+    protocol expects settable attributes."""
+
+    is_work_time: bool
+    sphere: str | None
+    project_id: str | None
+    product_id: str | None
+    project_type: str | None
+
+
 # Fields an override snapshots (the event's overridable set; recurrence fields stay on the master).
 _OVERRIDE_FIELDS = (
     "title",
@@ -668,6 +684,93 @@ class CalendarService:
             project.priority if project is not None else None,
         )
 
+    async def projected_filter_event(
+        self, user_id: str, project_id: str | None, product_id: str | None
+    ) -> ProjectedFilterEvent:
+        """The filterable fields an event/booking with these project links WOULD enrich to — so a
+        shared-calendar write can be rejected for falling outside the calendar's filter BEFORE it is
+        persisted. Mirrors the project resolution in ``_enrich_one`` (by project_id/product_id
+        only — activity_id never affects the filter fields)."""
+        projects = await self._owned_projects(user_id)
+        return self._project_links(projects, project_id, product_id)
+
+    async def projected_filter_events(
+        self, user_id: str, links: list[tuple[str | None, str | None]]
+    ) -> list[ProjectedFilterEvent]:
+        """Batch of ``projected_filter_event`` — loads the owner's projects ONCE, then projects each
+        ``(project_id, product_id)`` pair — to filter a whole bookings list without N queries."""
+        projects = await self._owned_projects(user_id)
+        return [self._project_links(projects, pid, prod) for pid, prod in links]
+
+    async def override_links(
+        self, master_id: str, *, since: datetime.date | None = None
+    ) -> list[tuple[str | None, str | None]]:
+        """The (project_id, product_id) links of a recurring master's per-occurrence overrides (from
+        ``since`` onward when given). A series-affecting shared write (all / following) edits or
+        deletes these overrides, so the caller checks none of them is outside the calendar's
+        filter — otherwise the write would silently mutate a hidden out-of-filter occurrence."""
+        stmt = select(CalendarEventOverride.project_id, CalendarEventOverride.product_id).where(
+            CalendarEventOverride.recurring_event_id == master_id
+        )
+        if since is not None:
+            stmt = stmt.where(CalendarEventOverride.occurrence_date >= since)
+        result = await self.session.execute(stmt)
+        return [(pid, prod) for pid, prod in result.all()]
+
+    async def delete_all_target_links(
+        self, user_id: str, master_id: str
+    ) -> list[tuple[str | None, str | None]]:
+        """Every (project_id, product_id) link a scope=all DELETE would touch — it cascades the
+        whole recurrence GROUP, not just the resolved master. A prior "following" split leaves
+        SIBLING masters in the group with their own (possibly different) links, so a shared
+        delete-all can be rejected if any affected occurrence is out-of-filter."""
+        master = await self._require(user_id, master_id)
+        gid = recurrence_group_id(
+            group_id=master.recurrence_group_id,
+            recurrence=master.recurrence,
+            recurring_event_id=master.recurring_event_id,
+            event_id=master.id,
+        )
+        if gid is None:
+            masters = [master]
+        else:
+            result = await self.session.execute(
+                select(CalendarEvent).where(
+                    CalendarEvent.user_id == user_id,
+                    or_(CalendarEvent.recurrence_group_id == gid, CalendarEvent.id == gid),
+                )
+            )
+            masters = list(result.scalars().all())
+        links = [(m.project_id, m.product_id) for m in masters]
+        for m in masters:
+            links.extend(await self.override_links(m.id))
+        return links
+
+    async def _owned_projects(self, user_id: str) -> dict[str, Project]:
+        result = await self.session.execute(select(Project).where(Project.user_id == user_id))
+        return {p.id: p for p in result.scalars().all()}
+
+    def _project_links(
+        self, projects: dict[str, Project], project_id: str | None, product_id: str | None
+    ) -> ProjectedFilterEvent:
+        project = projects.get(project_id) if project_id else None
+        product = projects.get(product_id) if product_id else None
+        if project is not None and project.parent_project_id:
+            product = project
+            project = projects.get(project.parent_project_id)
+        is_work_time = (
+            project.is_work_time
+            if project is not None and project.is_work_time is not None
+            else True
+        )
+        return ProjectedFilterEvent(
+            is_work_time=is_work_time,
+            sphere=project.sphere if project is not None else None,
+            project_id=project.id if project is not None else None,
+            product_id=product.id if product is not None else None,
+            project_type=project.project_type if project is not None else None,
+        )
+
     async def _enrich(self, user_id: str, items: list[_EnrichItem]) -> list[EnrichedEventRead]:
         result = await self.session.execute(select(Project).where(Project.user_id == user_id))
         projects = {p.id: p for p in result.scalars().all()}
diff --git a/apps/focal/server/app/services/calendar_init.py b/apps/focal/server/app/services/calendar_init.py
index 9c7c71d..ac16381 100644
--- a/apps/focal/server/app/services/calendar_init.py
+++ b/apps/focal/server/app/services/calendar_init.py
@@ -2,7 +2,8 @@ import datetime
 
 from sqlalchemy.ext.asyncio import AsyncSession
 
-from app.schemas.calendar import CalendarInitRead
+from app.schemas.bookings import BookingRead
+from app.schemas.calendar import CalendarInitRead, EnrichedEventRead
 from app.services.bookings import BookingsService
 from app.services.calendar import CalendarService
 from app.services.projects import ProjectsService
@@ -32,3 +33,27 @@ class CalendarInitService:
         bookings = await self._bookings.list_bookings(user_id, start=start, end=end, today=today)
         projects = await self._projects.list_projects(user_id)
         return CalendarInitRead(events=events, tasks=tasks, bookings=bookings, projects=projects)
+
+    async def get_shared_init(
+        self,
+        owner_id: str,
+        *,
+        events: list[EnrichedEventRead],
+        bookings: list[BookingRead],
+        include_other_pages: bool,
+        start: str | None,
+        end: str | None,
+        today: datetime.date,
+    ) -> CalendarInitRead:
+        """Shared-mode aggregate. ``events`` and ``bookings`` arrive pre-filtered from the
+        shared-calendar path (calendar gate). Tasks/projects are the owner's ONLY when the caller
+        can view the owner's OTHER pages (canViewOtherPages) — otherwise empty arrays. The response
+        schema requires the keys (emptied, never omitted), so an editor/viewer never receives the
+        owner's non-calendar data through this aggregate."""
+        if include_other_pages:
+            tasks = await self._tasks.list_tasks(owner_id, start=start, end=end, today=today)
+            projects = await self._projects.list_projects(owner_id)
+            return CalendarInitRead(
+                events=events, tasks=tasks, bookings=bookings, projects=projects
+            )
+        return CalendarInitRead(events=events, tasks=[], bookings=bookings, projects=[])
diff --git a/apps/focal/server/app/services/meeting_requests.py b/apps/focal/server/app/services/meeting_requests.py
index 4223581..cc01da8 100644
--- a/apps/focal/server/app/services/meeting_requests.py
+++ b/apps/focal/server/app/services/meeting_requests.py
@@ -41,28 +41,40 @@ class MeetingRequestsService:
         self.session = session
 
     async def list_requests(
-        self, user_id: str, *, status: str | None = None
+        self, user_id: str, *, status: str | None = None, calendar_id: str | None = None
     ) -> list[MeetingRequestRead]:
+        # A meeting request belongs to a specific shared calendar (shared_calendar_id), so in shared
+        # mode it is scoped to the selected calendar — a viewer of one calendar never sees the
+        # owner's requests for another. Absent calendar_id → all the owner's requests (own-data).
         stmt = select(MeetingRequest).where(MeetingRequest.user_id == user_id)
+        if calendar_id:
+            stmt = stmt.where(MeetingRequest.shared_calendar_id == calendar_id)
         if status:
             stmt = stmt.where(MeetingRequest.status == status)
         stmt = stmt.order_by(MeetingRequest.start_time.desc())
         result = await self.session.execute(stmt)
         return [MeetingRequestRead.model_validate(row) for row in result.scalars().all()]
 
-    async def pending_count(self, user_id: str) -> int:
-        result = await self.session.execute(
+    async def pending_count(self, user_id: str, *, calendar_id: str | None = None) -> int:
+        stmt = (
             select(func.count())
             .select_from(MeetingRequest)
             .where(MeetingRequest.user_id == user_id, MeetingRequest.status == "pending")
         )
+        if calendar_id:
+            stmt = stmt.where(MeetingRequest.shared_calendar_id == calendar_id)
+        result = await self.session.execute(stmt)
         return int(result.scalar_one())
 
-    async def get_request(self, user_id: str, request_id: str) -> MeetingRequestRead:
-        return MeetingRequestRead.model_validate(await self._owned(user_id, request_id))
+    async def get_request(
+        self, user_id: str, request_id: str, *, calendar_id: str | None = None
+    ) -> MeetingRequestRead:
+        return MeetingRequestRead.model_validate(
+            await self._owned(user_id, request_id, calendar_id=calendar_id)
+        )
 
     async def respond(
-        self, user_id: str, request_id: str, response: str
+        self, user_id: str, request_id: str, response: str, *, calendar_id: str | None = None
     ) -> MeetingRequestActionRead:
         """Answer a plain invitation: accepted / declined / tentative. Accept creates the
         focal calendar event (once — a re-accept reuses the linked event); decline removes
@@ -70,7 +82,7 @@ class MeetingRequestsService:
         response carries no status guard — the user may change their answer."""
         if response not in RESPONSE_STATUSES:
             raise ConflictError(f"Unknown meeting response '{response}'")
-        row = await self._owned(user_id, request_id)
+        row = await self._owned(user_id, request_id, calendar_id=calendar_id)
         row.status = response
         row.responded_at = datetime.now(UTC)
 
@@ -113,14 +125,14 @@ class MeetingRequestsService:
         return self._action_result(row, event)
 
     async def respond_reschedule(
-        self, user_id: str, request_id: str, *, accept: bool
+        self, user_id: str, request_id: str, *, accept: bool, calendar_id: str | None = None
     ) -> MeetingRequestActionRead:
         """Answer a proposed reschedule. The request's start/end already hold the
         proposed time; the originals hold the pre-change time. Accept keeps the proposal
         and re-times the linked event; decline reverts both the request and the event to
         the original time. Unlike plain responses these are one-shot: only a pending
         reschedule request can be answered."""
-        row = await self._owned(user_id, request_id)
+        row = await self._owned(user_id, request_id, calendar_id=calendar_id)
         if row.request_type != "reschedule":
             raise ConflictError("Not a reschedule request")
         if row.status != "pending":
@@ -157,33 +169,36 @@ class MeetingRequestsService:
             await send_reschedule_response_push(self.session, user_id, row.title, accept, row.id)
         return self._action_result(row, event)
 
-    async def delete_request(self, user_id: str, request_id: str) -> None:
+    async def delete_request(
+        self, user_id: str, request_id: str, *, calendar_id: str | None = None
+    ) -> None:
         # Atomic, tenant- and status-scoped: only a declined request the caller owns is removed,
-        # so a concurrent status change can't race between the check and the delete.
-        result = await self.session.execute(
-            delete(MeetingRequest)
-            .where(
-                MeetingRequest.id == request_id,
-                MeetingRequest.user_id == user_id,
-                MeetingRequest.status == "declined",
-            )
-            .returning(MeetingRequest.id)
+        # so a concurrent status change can't race between the check and the delete. In shared mode
+        # the request must also belong to the selected calendar.
+        stmt = delete(MeetingRequest).where(
+            MeetingRequest.id == request_id,
+            MeetingRequest.user_id == user_id,
+            MeetingRequest.status == "declined",
         )
+        if calendar_id:
+            stmt = stmt.where(MeetingRequest.shared_calendar_id == calendar_id)
+        result = await self.session.execute(stmt.returning(MeetingRequest.id))
         if result.scalar_one_or_none() is not None:
             await self.session.commit()
             return
-        # Nothing deleted: 404 if missing/other-user, else 409 (exists but not declined).
-        await self._owned(user_id, request_id)
+        # Nothing deleted: 404 if missing/other-user/other-calendar, else 409 (not declined).
+        await self._owned(user_id, request_id, calendar_id=calendar_id)
         raise ConflictError("Only declined requests can be deleted")
 
-    async def _owned(self, user_id: str, request_id: str) -> MeetingRequest:
-        row = (
-            await self.session.execute(
-                select(MeetingRequest).where(
-                    MeetingRequest.id == request_id, MeetingRequest.user_id == user_id
-                )
-            )
-        ).scalar_one_or_none()
+    async def _owned(
+        self, user_id: str, request_id: str, *, calendar_id: str | None = None
+    ) -> MeetingRequest:
+        stmt = select(MeetingRequest).where(
+            MeetingRequest.id == request_id, MeetingRequest.user_id == user_id
+        )
+        if calendar_id:
+            stmt = stmt.where(MeetingRequest.shared_calendar_id == calendar_id)
+        row = (await self.session.execute(stmt)).scalar_one_or_none()
         if row is None:
             raise NotFoundError("Meeting request not found")
         return row
diff --git a/apps/focal/server/app/services/shared_calendars.py b/apps/focal/server/app/services/shared_calendars.py
index dfd518d..2ead281 100644
--- a/apps/focal/server/app/services/shared_calendars.py
+++ b/apps/focal/server/app/services/shared_calendars.py
@@ -6,13 +6,15 @@ from sqlalchemy import func, select, text, update
 from sqlalchemy.ext.asyncio import AsyncSession
 
 from app.domain.invite_code import generate_invite_code
-from app.domain.shared_calendar_filter import apply_shared_calendar_filter
+from app.domain.recurrence import build_occurrence_event_id, parse_occurrence_event_id
+from app.domain.shared_calendar_filter import FilterableEvent, apply_shared_calendar_filter
 from app.errors import ConflictError, NotFoundError, PermissionDeniedError
 from app.models.shared_calendar import SharedCalendar, SharedCalendarParticipant
 from app.models.users import User
 from app.rbac import ROLE_RANK, get_resource_role
 from app.rls import INVITE_CODE_GUC
-from app.schemas.calendar import EnrichedEventRead
+from app.schemas.bookings import BookingCreate, BookingRead, BookingUpdate
+from app.schemas.calendar import EnrichedEventRead, EventCreate, EventUpdate
 from app.schemas.shared_calendar import (
     AccessibleSharedCalendarRead,
     JoinRequest,
@@ -27,6 +29,7 @@ from app.schemas.shared_calendar import (
     SharedCalendarRead,
     SharedCalendarUpdate,
 )
+from app.services.bookings import BookingsService
 from app.services.calendar import CalendarService
 
 
@@ -207,6 +210,241 @@ class SharedCalendarsService:
         # A viewer+ participant reads the OWNER's events (RBAC-gated cross-tenant share), filtered
         # by the calendar's saved filter. Events reuse the recurrence-expanded + enriched list.
         calendar, _ = await self._resolve_access(user_id, calendar_id, "viewer")
+        return await self._filtered_owner_events(calendar, start=start, end=end, today=today)
+
+    async def get_event(self, user_id: str, calendar_id: str, event_id: str) -> EnrichedEventRead:
+        # By-id read in shared mode: the event must be the owner's AND within this calendar's
+        # filter, else it is not part of this shared calendar → 404 (never raw
+        # CalendarService.get_event, which would expose owner events outside the filter).
+        calendar, _ = await self._resolve_access(user_id, calendar_id, "viewer")
+        event = await CalendarService(self.session).get_event(calendar.user_id, event_id)
+        if not self._in_filter(calendar, event):
+            raise NotFoundError("Event not found")
+        return event
+
+    async def create_event(
+        self, user_id: str, calendar_id: str, payload: EventCreate
+    ) -> EnrichedEventRead:
+        # Write in shared mode needs canEdit (owner/full_access/editor — rank >= editor) AND the new
+        # event must land WITHIN this calendar's filter — an editor cannot author owner events
+        # outside the shared calendar's scope (→ 403). Checked before the write, so a rejected
+        # create never persists.
+        calendar, _ = await self._resolve_access(user_id, calendar_id, "editor")
+        if not await self._links_in_filter(calendar, payload.project_id, payload.product_id):
+            raise PermissionDeniedError("Event falls outside this calendar's filter")
+        return await CalendarService(self.session).create_event(calendar.user_id, payload)
+
+    async def update_event(
+        self,
+        user_id: str,
+        calendar_id: str,
+        event_id: str,
+        payload: EventUpdate,
+        *,
+        scope: str | None,
+        occurrence_date: date | None,
+    ) -> EnrichedEventRead:
+        # The touched events must already be in-filter (can't reach out-of-scope owner events), AND
+        # the edit must not MOVE the result out — the post-edit project links must still match the
+        # filter. "all" edits the master, so its post-state derives from the master; "single" /
+        # "following" derive from the occurrence (a "following" split clones it into a new series).
+        # Only project_id/product_id change filter membership; an unset link keeps the base's.
+        calendar, occurrence, master = await self._writable_event_target(
+            user_id, calendar_id, event_id, scope=scope, occurrence_date=occurrence_date
+        )
+        base = master if scope == "all" else occurrence
+        patch = payload.model_dump(exclude_unset=True)
+        post_project_id = patch["project_id"] if "project_id" in patch else base.project_id
+        post_product_id = patch["product_id"] if "product_id" in patch else base.product_id
+        if not await self._links_in_filter(calendar, post_project_id, post_product_id):
+            raise PermissionDeniedError("Event would move outside this calendar's filter")
+        return await CalendarService(self.session).update_event(
+            calendar.user_id, event_id, payload, scope=scope, occurrence_date=occurrence_date
+        )
+
+    async def delete_event(
+        self,
+        user_id: str,
+        calendar_id: str,
+        event_id: str,
+        *,
+        scope: str | None,
+        occurrence_date: date | None,
+    ) -> None:
+        calendar, _, _ = await self._writable_event_target(
+            user_id, calendar_id, event_id, scope=scope, occurrence_date=occurrence_date
+        )
+        # A scope=all DELETE is the only op that cascades the WHOLE recurrence group — it can reach
+        # a SIBLING master left by a prior "following" split with out-of-filter links. So validate
+        # the full delete-all blast radius (every group master + their overrides), not just the
+        # resolved master _writable_event_target checked. (update-all edits one master in place;
+        # following-delete truncates one master — neither crosses the group.)
+        resolved_scope = scope or (
+            "single" if parse_occurrence_event_id(event_id) is not None else "all"
+        )
+        if resolved_scope == "all":
+            parsed = parse_occurrence_event_id(event_id)
+            master_id = parsed[0] if parsed is not None else event_id
+            svc = CalendarService(self.session)
+            links = await svc.delete_all_target_links(calendar.user_id, master_id)
+            projected = await svc.projected_filter_events(calendar.user_id, links)
+            if not all(self._in_filter(calendar, p) for p in projected):
+                raise PermissionDeniedError(
+                    "The recurrence group includes occurrences outside this calendar's filter"
+                )
+        await CalendarService(self.session).delete_event(
+            calendar.user_id, event_id, scope=scope, occurrence_date=occurrence_date
+        )
+
+    # --- bookings (calendar-domain, filtered like events: they carry project links) --------------
+
+    async def list_bookings(
+        self, user_id: str, calendar_id: str, *, start: str | None, end: str | None, today: date
+    ) -> list[BookingRead]:
+        calendar, _ = await self._resolve_access(user_id, calendar_id, "viewer")
+        bookings = await BookingsService(self.session).list_bookings(
+            calendar.user_id, start=start, end=end, today=today
+        )
+        return await self._filter_bookings(calendar, bookings)
+
+    async def get_booking(self, user_id: str, calendar_id: str, booking_id: str) -> BookingRead:
+        calendar, _ = await self._resolve_access(user_id, calendar_id, "viewer")
+        booking = await BookingsService(self.session).get_booking(calendar.user_id, booking_id)
+        if not await self._links_in_filter(calendar, booking.project_id, booking.product_id):
+            raise NotFoundError("Booking not found")
+        return booking
+
+    async def create_booking(
+        self, user_id: str, calendar_id: str, payload: BookingCreate
+    ) -> BookingRead:
+        calendar, _ = await self._resolve_access(user_id, calendar_id, "editor")
+        if not await self._links_in_filter(calendar, payload.project_id, payload.product_id):
+            raise PermissionDeniedError("Booking falls outside this calendar's filter")
+        return await BookingsService(self.session).create_booking(calendar.user_id, payload)
+
+    async def update_booking(
+        self, user_id: str, calendar_id: str, booking_id: str, payload: BookingUpdate
+    ) -> BookingRead:
+        calendar, existing = await self._writable_booking(user_id, calendar_id, booking_id)
+        patch = payload.model_dump(exclude_unset=True)
+        post_project_id = patch["project_id"] if "project_id" in patch else existing.project_id
+        post_product_id = patch["product_id"] if "product_id" in patch else existing.product_id
+        if not await self._links_in_filter(calendar, post_project_id, post_product_id):
+            raise PermissionDeniedError("Booking would move outside this calendar's filter")
+        return await BookingsService(self.session).update_booking(
+            calendar.user_id, booking_id, payload
+        )
+
+    async def delete_booking(self, user_id: str, calendar_id: str, booking_id: str) -> None:
+        calendar, _ = await self._writable_booking(user_id, calendar_id, booking_id)
+        await BookingsService(self.session).delete_booking(calendar.user_id, booking_id)
+
+    async def _writable_booking(
+        self, user_id: str, calendar_id: str, booking_id: str
+    ) -> tuple[SharedCalendar, BookingRead]:
+        calendar, _ = await self._resolve_access(user_id, calendar_id, "editor")
+        existing = await BookingsService(self.session).get_booking(calendar.user_id, booking_id)
+        if not await self._links_in_filter(calendar, existing.project_id, existing.product_id):
+            raise PermissionDeniedError("Booking is outside this calendar's filter")
+        return calendar, existing
+
+    async def _filter_bookings(
+        self, calendar: SharedCalendar, bookings: list[BookingRead]
+    ) -> list[BookingRead]:
+        # Bookings carry project links but not the derived is_work_time/sphere, so project them
+        # through the owner's projects (one load) before applying the calendar's saved filter.
+        if not bookings:
+            return bookings
+        projections = await CalendarService(self.session).projected_filter_events(
+            calendar.user_id, [(b.project_id, b.product_id) for b in bookings]
+        )
+        return [
+            booking
+            for booking, projected in zip(bookings, projections, strict=True)
+            if self._in_filter(calendar, projected)
+        ]
+
+    async def init_scope(
+        self, user_id: str, calendar_id: str, *, start: str | None, end: str | None, today: date
+    ) -> tuple[list[EnrichedEventRead], list[BookingRead], str, bool]:
+        """For the calendar-init mixed aggregate: the filtered owner events + filtered owner
+        bookings, the resolved owner id, and whether the caller may also see the owner's OTHER pages
+        (tasks/projects) — i.e. holds an other-pages read role (owner/full_access/developer). An
+        editor/viewer/requester gets the filtered events/bookings but the other-pages flag is
+        False."""
+        calendar, role = await self._resolve_access(user_id, calendar_id, "viewer")
+        events = await self._filtered_owner_events(calendar, start=start, end=end, today=today)
+        raw_bookings = await BookingsService(self.session).list_bookings(
+            calendar.user_id, start=start, end=end, today=today
+        )
+        bookings = await self._filter_bookings(calendar, raw_bookings)
+        return events, bookings, calendar.user_id, role in ("owner", "full_access", "developer")
+
+    async def _writable_event_target(
+        self,
+        user_id: str,
+        calendar_id: str,
+        event_id: str,
+        *,
+        scope: str | None,
+        occurrence_date: date | None,
+    ) -> tuple[SharedCalendar, EnrichedEventRead, EnrichedEventRead]:
+        # by-id WRITE: canEdit role AND every event the write touches is in-filter. The EFFECTIVE
+        # occurrence the write resolves to must be in-filter — resolved exactly as CalendarService
+        # does (an occurrence id OR a master id + occurrenceDate both name one occurrence), so
+        # a hidden out-of-filter occurrence can't be reached either way. A series-affecting scope
+        # (all / following) ALSO touches the recurring MASTER (edited or truncated; "following"
+        # splits the occurrence into a new series), so it must be in-filter too. Returns the
+        # occurrence + the post-edit base (the master for "all", else the occurrence).
+        calendar, _ = await self._resolve_access(user_id, calendar_id, "editor")
+        svc = CalendarService(self.session)
+        parsed = parse_occurrence_event_id(event_id)
+        target_date: date | None
+        if parsed is not None:
+            master_id, target_date = parsed[0], (occurrence_date or parsed[1])
+        else:
+            master_id, target_date = event_id, occurrence_date
+        occ_id = (
+            build_occurrence_event_id(master_id, target_date)
+            if target_date is not None
+            else master_id
+        )
+        occurrence = await svc.get_event(calendar.user_id, occ_id)
+        if not self._in_filter(calendar, occurrence):
+            raise PermissionDeniedError("Event is outside this calendar's filter")
+        master = occurrence
+        if scope in ("all", "following"):
+            if target_date is not None:
+                master = await svc.get_event(calendar.user_id, master_id)
+                if not self._in_filter(calendar, master):
+                    raise PermissionDeniedError("Series master is outside this calendar's filter")
+            # The operation edits/clears the series' per-occurrence overrides across the affected
+            # range ("following" from target_date, "all" the whole series). NONE of those hidden
+            # override occurrences may be out-of-filter — else the write would silently mutate or
+            # delete an owner occurrence the caller can't even see in this shared calendar.
+            since = target_date if scope == "following" else None
+            override_links = await svc.override_links(master_id, since=since)
+            if override_links:
+                projected = await svc.projected_filter_events(calendar.user_id, override_links)
+                if not all(self._in_filter(calendar, p) for p in projected):
+                    raise PermissionDeniedError(
+                        "An occurrence in the affected range is outside this calendar's filter"
+                    )
+        return calendar, occurrence, master
+
+    async def _links_in_filter(
+        self, calendar: SharedCalendar, project_id: str | None, product_id: str | None
+    ) -> bool:
+        """Whether an event with these project links would pass the calendar's filter — the
+        pre-write check for create/move (filter fields derive entirely from the project links)."""
+        projected = await CalendarService(self.session).projected_filter_event(
+            calendar.user_id, project_id, product_id
+        )
+        return self._in_filter(calendar, projected)
+
+    async def _filtered_owner_events(
+        self, calendar: SharedCalendar, *, start: str | None, end: str | None, today: date
+    ) -> list[EnrichedEventRead]:
         events = await CalendarService(self.session).list_events(
             calendar.user_id, start=start, end=end, today=today
         )
@@ -217,6 +455,16 @@ class SharedCalendarsService:
             filter_rules=calendar.filter_rules,
         )
 
+    def _in_filter(self, calendar: SharedCalendar, event: FilterableEvent) -> bool:
+        return bool(
+            apply_shared_calendar_filter(
+                [event],
+                filter_type=calendar.filter_type,
+                filter_value=calendar.filter_value,
+                filter_rules=calendar.filter_rules,
+            )
+        )
+
     async def _resolve_access(
         self, user_id: str, calendar_id: str, minimum: str
     ) -> tuple[SharedCalendar, str]:
diff --git a/apps/focal/server/tests/test_ai_chat_support_db.py b/apps/focal/server/tests/test_ai_chat_support_db.py
index 39a8000..3f76dbd 100644
--- a/apps/focal/server/tests/test_ai_chat_support_db.py
+++ b/apps/focal/server/tests/test_ai_chat_support_db.py
@@ -154,9 +154,9 @@ def test_memory_scope_formula_matches_for_own_and_shared_buckets() -> None:
     assert support.memory_scope("calendar", "me", "me") == "calendar"
     shared = support.memory_scope("calendar", "0e2cdfce-1111-2222-3333-444455556666", "me")
     assert shared == "calendar:0e2cdfce-1111-2222-3333-444455556666"
-    assert support.resolve_data_owner("not-a-uuid", "me") == "me"
+    assert support.memory_scope_owner("not-a-uuid", "me") == "me"
     assert (
-        support.resolve_data_owner("0e2cdfce-1111-2222-3333-444455556666", "me")
+        support.memory_scope_owner("0e2cdfce-1111-2222-3333-444455556666", "me")
         == "0e2cdfce-1111-2222-3333-444455556666"
     )
 
diff --git a/apps/focal/server/tests/test_calendar_scope_db.py b/apps/focal/server/tests/test_calendar_scope_db.py
new file mode 100644
index 0000000..2498c53
--- /dev/null
+++ b/apps/focal/server/tests/test_calendar_scope_db.py
@@ -0,0 +1,790 @@
+"""DB-backed route tests for the calendar-domain scope invariant (slice 2b / B3).
+
+Asserts the contract from the data-scope design for shared-mode calendar endpoints:
+- every READ returns only objects within the calendar's saved filter (list via the filtered path; a
+  by-id read of an out-of-filter owner event → 404);
+- every WRITE needs canEdit AND the target within the filter (viewer → 403; editor on an
+  out-of-filter event → 403);
+- the calendar_init mixed aggregate gates tasks/projects behind canViewOtherPages while still
+  serving filtered events to a viewer;
+- bookings (project filter) and meeting-requests (shared_calendar_id) are scoped to the selected
+  calendar, not just owner-resolved — read = viewer+, write = canEdit;
+- with no calendarId every endpoint keeps its own-data behavior (backward compatible).
+
+Skipped unless DATABASE_URL is set; run vs local Docker Postgres."""
+
+import asyncio
+import os
+from collections.abc import AsyncIterator, Coroutine
+from datetime import UTC, date, datetime
+from typing import Any
+from uuid import uuid4
+
+import pytest
+from fastapi import Header
+from fastapi.testclient import TestClient
+from sqlalchemy import text
+from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
+from sqlalchemy.pool import NullPool
+
+import app.api.bookings as bookings_api
+import app.api.calendar as calendar_api
+import app.api.calendar_init as calendar_init_api
+from app.api.bookings import get_bookings_service
+from app.api.meeting_requests import get_meeting_requests_service
+from app.api.projects import get_projects_service
+from app.api.shared_calendars import get_shared_calendars_service
+from app.api.tasks import get_tasks_service
+from app.data_scope import _scope_session
+from app.deps import current_utc_date, get_current_user_id
+from app.main import app
+from app.models.base import Base
+from app.models.meeting_request import MeetingRequest
+from app.models.shared_calendar import SharedCalendarParticipant
+from app.services.bookings import BookingsService
+from app.services.calendar import CalendarService
+from app.services.calendar_init import CalendarInitService
+from app.services.meeting_requests import MeetingRequestsService
+from app.services.projects import ProjectsService
+from app.services.shared_calendars import SharedCalendarsService
+from app.services.tasks import TasksService
+
+DB_URL = os.getenv("DATABASE_URL")
+pytestmark = pytest.mark.skipif(not DB_URL, reason="DATABASE_URL not set")
+
+_engine = create_async_engine(DB_URL, poolclass=NullPool) if DB_URL else None
+_sessionmaker = async_sessionmaker(_engine, expire_on_commit=False) if DB_URL else None
+
+TODAY = date(2026, 1, 15)
+WINDOW = {"startDate": "2026-01-15", "endDate": "2026-01-20"}
+
+
+def _run[T](coro: Coroutine[Any, Any, T]) -> T:
+    return asyncio.run(coro)
+
+
+async def _override_shared() -> AsyncIterator[SharedCalendarsService]:
+    async with _sessionmaker() as session:
+        yield SharedCalendarsService(session)
+
+
+async def _override_calendar() -> AsyncIterator[CalendarService]:
+    async with _sessionmaker() as session:
+        yield CalendarService(session)
+
+
+async def _override_projects() -> AsyncIterator[ProjectsService]:
+    async with _sessionmaker() as session:
+        yield ProjectsService(session)
+
+
+async def _override_tasks() -> AsyncIterator[TasksService]:
+    async with _sessionmaker() as session:
+        yield TasksService(session)
+
+
+async def _override_bookings() -> AsyncIterator[BookingsService]:
+    async with _sessionmaker() as session:
+        yield BookingsService(session)
+
+
+async def _override_meetings() -> AsyncIterator[MeetingRequestsService]:
+    async with _sessionmaker() as session:
+        yield MeetingRequestsService(session)
+
+
+async def _override_init() -> AsyncIterator[CalendarInitService]:
+    async with _sessionmaker() as session:
+        yield CalendarInitService(session)
+
+
+async def _override_scope_session() -> AsyncIterator[Any]:
+    async with _sessionmaker() as session:
+        yield session
+
+
+@pytest.fixture(scope="module", autouse=True)
+def _schema() -> AsyncIterator[None]:
+    async def setup() -> None:
+        async with _engine.begin() as conn:
+            await conn.execute(text("CREATE SCHEMA IF NOT EXISTS focal"))
+            await conn.run_sync(Base.metadata.create_all)
+
+    _run(setup())
+    yield
+
+
+async def _demo_user_id(x_demo_user_id: str | None = Header(default=None)) -> str:
+    return x_demo_user_id or "demo-user"
+
+
+app.dependency_overrides[get_current_user_id] = _demo_user_id
+app.dependency_overrides[current_utc_date] = lambda: TODAY
+
+
+@pytest.fixture(autouse=True)
+def _db_backend() -> AsyncIterator[None]:
+    overrides = {
+        get_shared_calendars_service: _override_shared,
+        calendar_api.get_calendar_service: _override_calendar,
+        calendar_api.get_shared_service: _override_shared,
+        calendar_init_api.get_calendar_init_service: _override_init,
+        calendar_init_api.get_shared_service: _override_shared,
+        bookings_api.get_shared_service: _override_shared,
+        get_projects_service: _override_projects,
+        get_tasks_service: _override_tasks,
+        get_bookings_service: _override_bookings,
+        get_meeting_requests_service: _override_meetings,
+        # The owner-resolution dependency on bookings/meeting-requests opens its own session via the
+        # app's pooled engine; point it at the NullPool test maker so it is loop-safe here.
+        _scope_session: _override_scope_session,
+    }
+    app.dependency_overrides.update(overrides)
+
+    async def truncate() -> None:
+        async with _engine.begin() as conn:
+            await conn.execute(
+                text(
+                    "TRUNCATE focal.shared_calendar_participants, focal.shared_calendars, "
+                    "focal.calendar_event_overrides, focal.calendar_events, focal.bookings, "
+                    "focal.meeting_requests, focal.tasks, focal.projects, focal.activities CASCADE"
+                )
+            )
+
+    _run(truncate())
+    yield
+    for dep in overrides:
+        app.dependency_overrides.pop(dep, None)
+
+
+client = TestClient(app)
+
+
+def _h(user: str) -> dict[str, str]:
+    return {"X-Demo-User-Id": user}
+
+
+def _create_cal(user: str, **body: object) -> dict:
+    base: dict[str, object] = {"name": "Cal"}
+    base.update(body)
+    return client.post("/api/shared-calendars", headers=_h(user), json=base).json()
+
+
+def _event(user: str, **body: object) -> dict:
+    return client.post("/api/events", headers=_h(user), json=body).json()
+
+
+def _project(user: str, **body: object) -> str:
+    return client.post("/api/projects", headers=_h(user), json=body).json()["id"]
+
+
+def _booking(user: str, **body: object) -> dict:
+    return client.post("/api/bookings", headers=_h(user), json=body).json()
+
+
+def _meeting_request(owner: str, calendar_id: str, title: str) -> str:
+    rid = str(uuid4())
+
+    async def go() -> None:
+        async with _sessionmaker() as session:
+            session.add(
+                MeetingRequest(
+                    id=rid,
+                    user_id=owner,
+                    shared_calendar_id=calendar_id,
+                    google_event_id=str(uuid4()),
+                    google_calendar_id="g-cal",
+                    title=title,
+                    start_time=datetime(2026, 1, 16, 9, 0, tzinfo=UTC),
+                    end_time=datetime(2026, 1, 16, 10, 0, tzinfo=UTC),
+                    organizer_email="organizer@example.com",
+                    status="pending",
+                )
+            )
+            await session.commit()
+
+    _run(go())
+    return rid
+
+
+def _participant(cid: str, user_id: str, role: str, *, invite_status: str = "accepted") -> None:
+    async def go() -> None:
+        async with _sessionmaker() as session:
+            session.add(
+                SharedCalendarParticipant(
+                    shared_calendar_id=cid, user_id=user_id, role=role, invite_status=invite_status
+                )
+            )
+            await session.commit()
+
+    _run(go())
+
+
+# --- a calendar with a work-time filter + an in/out-of-filter event pair -------
+
+
+def _work_calendar_fixture() -> tuple[str, str, str]:
+    """Owner has a work event (in filter) and a home event (out of filter); returns
+    (calendar_id, in_filter_event_id, out_of_filter_event_id)."""
+    work = _event("owner", title="work", date="2026-01-16", startTime="09:00")  # no project → work
+    home_pid = _project("owner", name="Home", isWorkTime=False, sphere="Family")
+    home = _event("owner", title="home", date="2026-01-16", startTime="10:00", projectId=home_pid)
+    cal = _create_cal("owner", name="Work", filterType="isWorkTime", filterValue="true")
+    return cal["id"], work["id"], home["id"]
+
+
+# --- list read: filtered through the shared path -----------------------------
+
+
+def test_shared_list_returns_only_in_filter_events() -> None:
+    cid, _, _ = _work_calendar_fixture()
+    _participant(cid, "viewer-user", "viewer")
+    rows = client.get(
+        "/api/events", headers=_h("viewer-user"), params={**WINDOW, "calendarId": cid}
+    ).json()
+    assert {r["title"] for r in rows} == {"work"}  # the home event is filtered out
+
+
+def test_own_data_unaffected_without_calendar_id() -> None:
+    _event("solo", title="mine", date="2026-01-16", startTime="09:00")
+    rows = client.get("/api/events", headers=_h("solo"), params=WINDOW).json()
+    assert {r["title"] for r in rows} == {"mine"}  # unchanged own-data path
+
+
+# --- by-id read: out-of-filter → 404 -----------------------------------------
+
+
+def test_by_id_read_in_filter_ok_out_of_filter_404() -> None:
+    cid, work_id, home_id = _work_calendar_fixture()
+    _participant(cid, "viewer-user", "viewer")
+    assert (
+        client.get(
+            f"/api/events/{work_id}", headers=_h("viewer-user"), params={"calendarId": cid}
+        ).status_code
+        == 200
+    )
+    # the home event is the owner's but outside this calendar's filter → not visible here
+    assert (
+        client.get(
+            f"/api/events/{home_id}", headers=_h("viewer-user"), params={"calendarId": cid}
+        ).status_code
+        == 404
+    )
+
+
+# --- writes: canEdit + within filter -----------------------------------------
+
+
+def test_viewer_cannot_write_events() -> None:
+    cid, work_id, _ = _work_calendar_fixture()
+    _participant(cid, "viewer-user", "viewer")
+    create = client.post(
+        "/api/events",
+        headers=_h("viewer-user"),
+        params={"calendarId": cid},
+        json={"title": "x", "date": "2026-01-16", "startTime": "11:00"},
+    )
+    assert create.status_code == 403
+    patch = client.patch(
+        f"/api/events/{work_id}",
+        headers=_h("viewer-user"),
+        params={"calendarId": cid},
+        json={"title": "renamed"},
+    )
+    assert patch.status_code == 403
+
+
+def test_editor_write_in_filter_ok_out_of_filter_403() -> None:
+    cid, work_id, home_id = _work_calendar_fixture()
+    _participant(cid, "editor-user", "editor")
+    ok = client.patch(
+        f"/api/events/{work_id}",
+        headers=_h("editor-user"),
+        params={"calendarId": cid},
+        json={"title": "renamed"},
+    )
+    assert ok.status_code == 200
+    # the out-of-filter owner event is unreachable for a write through this calendar
+    blocked = client.patch(
+        f"/api/events/{home_id}",
+        headers=_h("editor-user"),
+        params={"calendarId": cid},
+        json={"title": "renamed"},
+    )
+    assert blocked.status_code == 403
+
+
+def test_create_outside_filter_is_forbidden() -> None:
+    pid_a = _project("owner", name="A")
+    pid_b = _project("owner", name="B")
+    cid = _create_cal("owner", name="OnlyA", filterType="project", filterValue=pid_a)["id"]
+    _participant(cid, "editor-user", "editor")
+    in_filter = client.post(
+        "/api/events",
+        headers=_h("editor-user"),
+        params={"calendarId": cid},
+        json={"title": "x", "date": "2026-01-16", "startTime": "09:00", "projectId": pid_a},
+    )
+    assert in_filter.status_code == 200  # linked to the filtered project → allowed
+    out_of_filter = client.post(
+        "/api/events",
+        headers=_h("editor-user"),
+        params={"calendarId": cid},
+        json={"title": "y", "date": "2026-01-16", "startTime": "10:00", "projectId": pid_b},
+    )
+    assert out_of_filter.status_code == 403  # an editor cannot author outside the calendar's scope
+
+
+def test_update_moving_event_out_of_filter_is_forbidden() -> None:
+    pid_a = _project("owner", name="A")
+    pid_b = _project("owner", name="B")
+    evt = _event("owner", title="a-evt", date="2026-01-16", startTime="09:00", projectId=pid_a)
+    cid = _create_cal("owner", name="OnlyA", filterType="project", filterValue=pid_a)["id"]
+    _participant(cid, "editor-user", "editor")
+    # an edit that does not touch the project link stays in-filter → allowed
+    rename = client.patch(
+        f"/api/events/{evt['id']}",
+        headers=_h("editor-user"),
+        params={"calendarId": cid},
+        json={"title": "renamed"},
+    )
+    assert rename.status_code == 200
+    # re-linking it to a project outside the filter would move it out of this calendar → 403
+    moved = client.patch(
+        f"/api/events/{evt['id']}",
+        headers=_h("editor-user"),
+        params={"calendarId": cid},
+        json={"projectId": pid_b},
+    )
+    assert moved.status_code == 403
+
+
+def test_series_write_through_in_filter_occurrence_cannot_reach_out_of_filter_master() -> None:
+    pid_a = _project("owner", name="A")
+    pid_b = _project("owner", name="B")
+    # a daily recurring master linked to project B — OUTSIDE a "project A" calendar
+    _event(
+        "owner",
+        title="series",
+        date="2026-01-16",
+        startTime="09:00",
+        projectId=pid_b,
+        recurrence="daily",
+    )
+    rows = client.get(
+        "/api/events",
+        headers=_h("owner"),
+        params={"startDate": "2026-01-16", "endDate": "2026-01-18"},
+    ).json()
+    occ_id = next(r["id"] for r in rows if r["date"] == "2026-01-17")
+    # the owner overrides THAT single occurrence into project A → it now passes the filter
+    assert (
+        client.patch(
+            f"/api/events/{occ_id}",
+            headers=_h("owner"),
+            params={"recurrenceScope": "single", "occurrenceDate": "2026-01-17"},
+            json={"projectId": pid_a},
+        ).status_code
+        == 200
+    )
+    cid = _create_cal("owner", name="OnlyA", filterType="project", filterValue=pid_a)["id"]
+    _participant(cid, "editor-user", "editor")
+    # the editor may edit the in-filter occurrence at SINGLE scope...
+    assert (
+        client.patch(
+            f"/api/events/{occ_id}",
+            headers=_h("editor-user"),
+            params={"calendarId": cid, "recurrenceScope": "single", "occurrenceDate": "2026-01-17"},
+            json={"title": "x"},
+        ).status_code
+        == 200
+    )
+    # ...but NOT reach the whole series — the master is project B, outside this calendar (→ 403)
+    assert (
+        client.patch(
+            f"/api/events/{occ_id}",
+            headers=_h("editor-user"),
+            params={"calendarId": cid, "recurrenceScope": "all"},
+            json={"title": "y"},
+        ).status_code
+        == 403
+    )
+    assert (
+        client.delete(
+            f"/api/events/{occ_id}",
+            headers=_h("editor-user"),
+            params={"calendarId": cid, "recurrenceScope": "all"},
+        ).status_code
+        == 403
+    )
+
+
+def test_following_split_through_out_of_filter_occurrence_is_forbidden() -> None:
+    # The inverse of the case above: a VISIBLE in-filter master with a HIDDEN out-of-filter override
+    # occurrence. A "following" split clones the occurrence's links into the new series, so it must
+    # be blocked even though the master is in-filter.
+    pid_a = _project("owner", name="A")
+    pid_b = _project("owner", name="B")
+    _event(
+        "owner",
+        title="series",
+        date="2026-01-16",
+        startTime="09:00",
+        projectId=pid_a,
+        recurrence="daily",
+    )
+    rows = client.get(
+        "/api/events",
+        headers=_h("owner"),
+        params={"startDate": "2026-01-16", "endDate": "2026-01-18"},
+    ).json()
+    occ_id = next(r["id"] for r in rows if r["date"] == "2026-01-17")
+    # owner overrides that occurrence OUT of the project-A filter (into project B)
+    assert (
+        client.patch(
+            f"/api/events/{occ_id}",
+            headers=_h("owner"),
+            params={"recurrenceScope": "single", "occurrenceDate": "2026-01-17"},
+            json={"projectId": pid_b},
+        ).status_code
+        == 200
+    )
+    cid = _create_cal("owner", name="OnlyA", filterType="project", filterValue=pid_a)["id"]
+    _participant(cid, "editor-user", "editor")
+    # an editor cannot split "following" / delete from the hidden out-of-filter occurrence
+    assert (
+        client.patch(
+            f"/api/events/{occ_id}",
+            headers=_h("editor-user"),
+            params={
+                "calendarId": cid,
+                "recurrenceScope": "following",
+                "occurrenceDate": "2026-01-17",
+            },
+            json={"title": "x"},
+        ).status_code
+        == 403
+    )
+    assert (
+        client.delete(
+            f"/api/events/{occ_id}",
+            headers=_h("editor-user"),
+            params={
+                "calendarId": cid,
+                "recurrenceScope": "following",
+                "occurrenceDate": "2026-01-17",
+            },
+        ).status_code
+        == 403
+    )
+
+
+def test_following_split_via_master_id_and_occurrence_date_is_forbidden() -> None:
+    # The same escape through the raw master-id + occurrenceDate API shape (not a synthetic
+    # occurrence id): the effective occurrence the write resolves to is out of filter.
+    pid_a = _project("owner", name="A")
+    pid_b = _project("owner", name="B")
+    master = _event(
+        "owner",
+        title="series",
+        date="2026-01-16",
+        startTime="09:00",
+        projectId=pid_a,
+        recurrence="daily",
+    )
+    master_id = master["id"]
+    rows = client.get(
+        "/api/events",
+        headers=_h("owner"),
+        params={"startDate": "2026-01-16", "endDate": "2026-01-18"},
+    ).json()
+    occ_id = next(r["id"] for r in rows if r["date"] == "2026-01-17")
+    assert (
+        client.patch(
+            f"/api/events/{occ_id}",
+            headers=_h("owner"),
+            params={"recurrenceScope": "single", "occurrenceDate": "2026-01-17"},
+            json={"projectId": pid_b},
+        ).status_code
+        == 200  # the hidden out-of-filter override must actually be created for the test to bite
+    )
+    cid = _create_cal("owner", name="OnlyA", filterType="project", filterValue=pid_a)["id"]
+    _participant(cid, "editor-user", "editor")
+    # editor targets the hidden out-of-filter occurrence via the MASTER id + occurrenceDate → 403
+    assert (
+        client.patch(
+            f"/api/events/{master_id}",
+            headers=_h("editor-user"),
+            params={
+                "calendarId": cid,
+                "recurrenceScope": "following",
+                "occurrenceDate": "2026-01-17",
+            },
+            json={"title": "x"},
+        ).status_code
+        == 403
+    )
+
+
+def test_following_with_out_of_filter_future_override_is_forbidden() -> None:
+    # A series the editor CAN see (master project A, in-filter) but with a HIDDEN out-of-filter
+    # override at a FUTURE date. A "following" split before that date would delete the hidden
+    # override, so it must be blocked even though the occurrence + master are both in-filter.
+    pid_a = _project("owner", name="A")
+    pid_b = _project("owner", name="B")
+    _event(
+        "owner",
+        title="series",
+        date="2026-01-16",
+        startTime="09:00",
+        projectId=pid_a,
+        recurrence="daily",
+    )
+    rows = client.get(
+        "/api/events",
+        headers=_h("owner"),
+        params={"startDate": "2026-01-16", "endDate": "2026-01-19"},
+    ).json()
+    occ_18 = next(r["id"] for r in rows if r["date"] == "2026-01-18")
+    occ_17 = next(r["id"] for r in rows if r["date"] == "2026-01-17")
+    assert (
+        client.patch(
+            f"/api/events/{occ_18}",
+            headers=_h("owner"),
+            params={"recurrenceScope": "single", "occurrenceDate": "2026-01-18"},
+            json={"projectId": pid_b},
+        ).status_code
+        == 200  # the hidden out-of-filter override at 2026-01-18 must exist for the test to bite
+    )
+    cid = _create_cal("owner", name="OnlyA", filterType="project", filterValue=pid_a)["id"]
+    _participant(cid, "editor-user", "editor")
+    # "following" from 2026-01-17 would wipe the hidden out-of-filter override at 2026-01-18 → 403
+    assert (
+        client.patch(
+            f"/api/events/{occ_17}",
+            headers=_h("editor-user"),
+            params={
+                "calendarId": cid,
+                "recurrenceScope": "following",
+                "occurrenceDate": "2026-01-17",
+            },
+            json={"title": "x"},
+        ).status_code
+        == 403
+    )
+
+
+def test_delete_all_cannot_cascade_to_an_out_of_filter_sibling_master() -> None:
+    # A "following" split leaves a SIBLING master in the same recurrence group; if that sibling is
+    # out-of-filter, a scope=all DELETE (which cascades the whole group) must be blocked even though
+    # the resolved master the caller addressed is in-filter.
+    pid_a = _project("owner", name="A")
+    pid_b = _project("owner", name="B")
+    master = _event(
+        "owner",
+        title="series",
+        date="2026-01-16",
+        startTime="09:00",
+        projectId=pid_a,
+        recurrence="daily",
+    )
+    master_a = master["id"]
+    rows = client.get(
+        "/api/events",
+        headers=_h("owner"),
+        params={"startDate": "2026-01-16", "endDate": "2026-01-19"},
+    ).json()
+    occ_18 = next(r["id"] for r in rows if r["date"] == "2026-01-18")
+    # owner splits "following" from 2026-01-18 into project B → a sibling master_B in the same group
+    assert (
+        client.patch(
+            f"/api/events/{occ_18}",
+            headers=_h("owner"),
+            params={"recurrenceScope": "following", "occurrenceDate": "2026-01-18"},
+            json={"projectId": pid_b},
+        ).status_code
+        == 200
+    )
+    cid = _create_cal("owner", name="OnlyA", filterType="project", filterValue=pid_a)["id"]
+    _participant(cid, "editor-user", "editor")
+    # delete-all on the in-filter master_A would cascade-delete the out-of-filter sibling master_B
+    assert (
+        client.delete(
+            f"/api/events/{master_a}",
+            headers=_h("editor-user"),
+            params={"calendarId": cid, "recurrenceScope": "all"},
+        ).status_code
+        == 403
+    )
+
+
+def test_delegated_other_pages_writes_reject_non_owner_fk_links() -> None:
+    # In a delegated (shared assistant) other-pages write the payload FKs must belong to the OWNER,
+    # not the caller — else the caller could attach the owner's row to their OWN project/activity
+    # and later cascade-delete it. activities + activity-instances now validate this (tasks/events/
+    # bookings/projects/goals already did).
+    from app.errors import RelatedRecordNotFoundError
+    from app.models.activities import Activity
+    from app.schemas.activities import ActivityCreate
+    from app.schemas.activity_instances import ActivityInstanceSyncRequest
+    from app.services.activities import ActivitiesService
+    from app.services.activity_instances import ActivityInstancesService
+
+    caller_pid = _project("caller", name="Caller's own project")  # owned by 'caller', not 'owner'
+
+    async def go() -> None:
+        async with _sessionmaker() as session:
+            caller_activity = Activity(user_id="caller", name="a")
+            session.add(caller_activity)
+            await session.commit()
+            with pytest.raises(RelatedRecordNotFoundError):
+                await ActivitiesService(session).create_activity(
+                    "owner", ActivityCreate(name="x", project_id=caller_pid)
+                )
+            with pytest.raises(RelatedRecordNotFoundError):
+                await ActivityInstancesService(session).sync_instances(
+                    "owner",
+                    ActivityInstanceSyncRequest(
+                        activity_id=caller_activity.id, count=1, activity_name="a"
+                    ),
+                )
+
+    _run(go())
+
+
+# --- calendar_init mixed aggregate -------------------------------------------
+
+
+def test_calendar_init_gates_other_pages_but_serves_filtered_events() -> None:
+    cid, _, _ = _work_calendar_fixture()
+    client.post("/api/tasks", headers=_h("owner"), json={"title": "owner-task"})
+    _participant(cid, "viewer-user", "viewer")  # no canViewOtherPages
+    _participant(cid, "dev-user", "developer")  # canViewOtherPages, read-only
+
+    viewer = client.get(
+        "/api/calendar/init", headers=_h("viewer-user"), params={**WINDOW, "calendarId": cid}
+    ).json()
+    assert {e["title"] for e in viewer["events"]} == {"work"}  # filtered events served
+    assert viewer["tasks"] == [] and viewer["projects"] == []  # other pages withheld
+
+    dev = client.get(
+        "/api/calendar/init", headers=_h("dev-user"), params={**WINDOW, "calendarId": cid}
+    ).json()
+    assert {t["title"] for t in dev["tasks"]} == {"owner-task"}  # canViewOtherPages → owner's tasks
+
+
+# --- bookings + meeting-requests: calendar-domain role gates ------------------
+
+
+def test_shared_bookings_are_filtered_to_the_calendar() -> None:
+    pid_a = _project("owner", name="A")
+    pid_b = _project("owner", name="B")
+    a = _booking("owner", title="ba", startDate="2026-01-16", endDate="2026-01-16", projectId=pid_a)
+    b = _booking("owner", title="bb", startDate="2026-01-16", endDate="2026-01-16", projectId=pid_b)
+    cid = _create_cal("owner", name="OnlyA", filterType="project", filterValue=pid_a)["id"]
+    _participant(cid, "viewer-user", "viewer")
+    rows = client.get(
+        "/api/bookings", headers=_h("viewer-user"), params={**WINDOW, "calendarId": cid}
+    ).json()
+    assert {r["title"] for r in rows} == {"ba"}  # only the project-A booking, not project-B's
+    # a by-id read of the out-of-filter booking is not visible in this calendar → 404
+    assert (
+        client.get(
+            f"/api/bookings/{b['id']}", headers=_h("viewer-user"), params={"calendarId": cid}
+        ).status_code
+        == 404
+    )
+    assert (
+        client.get(
+            f"/api/bookings/{a['id']}", headers=_h("viewer-user"), params={"calendarId": cid}
+        ).status_code
+        == 200
+    )
+
+
+def test_shared_meeting_requests_are_scoped_to_the_calendar() -> None:
+    cal_x = _create_cal("owner", name="X", filterType="all")["id"]
+    cal_y = _create_cal("owner", name="Y", filterType="all")["id"]
+    _meeting_request("owner", cal_x, "for-x")
+    _meeting_request("owner", cal_y, "for-y")
+    _participant(cal_x, "viewer-user", "viewer")
+    rows = client.get(
+        "/api/meeting-requests", headers=_h("viewer-user"), params={"calendarId": cal_x}
+    ).json()
+    assert {r["title"] for r in rows} == {"for-x"}  # calendar X's request only, never calendar Y's
+
+
+def test_meeting_request_action_is_scoped_to_the_selected_calendar() -> None:
+    # The same shared_calendar_id boundary on the WRITE (accept) path: an editor holding edit on
+    # calendar X cannot act on a request that belongs to calendar Y by passing calendarId=X → 404.
+    cal_x = _create_cal("owner", name="X", filterType="all")["id"]
+    cal_y = _create_cal("owner", name="Y", filterType="all")["id"]
+    rid_y = _meeting_request("owner", cal_y, "for-y")
+    _participant(cal_x, "editor-user", "editor")
+    assert (
+        client.post(
+            f"/api/meeting-requests/{rid_y}/accept",
+            headers=_h("editor-user"),
+            params={"calendarId": cal_x},
+        ).status_code
+        == 404
+    )
+
+
+def test_bookings_read_gate_and_write_gate() -> None:
+    cal = _create_cal("owner", name="C", filterType="all")
+    cid = cal["id"]
+    _participant(cid, "viewer-user", "viewer")
+    assert (
+        client.get(
+            "/api/bookings", headers=_h("viewer-user"), params={"calendarId": cid}
+        ).status_code
+        == 200
+    )
+    assert (
+        client.get("/api/bookings", headers=_h("stranger"), params={"calendarId": cid}).status_code
+        == 403
+    )
+    # write needs canEdit — a viewer is denied before the service runs (DELETE has no body → 403)
+    assert (
+        client.delete(
+            "/api/bookings/missing", headers=_h("viewer-user"), params={"calendarId": cid}
+        ).status_code
+        == 403
+    )
+
+
+def test_meeting_requests_read_gate_and_write_gate() -> None:
+    cal = _create_cal("owner", name="C", filterType="all")
+    cid = cal["id"]
+    _participant(cid, "viewer-user", "viewer")
+    _participant(cid, "editor-user", "editor")
+    assert (
+        client.get(
+            "/api/meeting-requests", headers=_h("viewer-user"), params={"calendarId": cid}
+        ).status_code
+        == 200
+    )
+    assert (
+        client.get(
+            "/api/meeting-requests", headers=_h("stranger"), params={"calendarId": cid}
+        ).status_code
+        == 403
+    )
+    # responding is a write (canEdit): viewer denied, editor passes the gate then 404s on the id
+    assert (
+        client.post(
+            "/api/meeting-requests/missing/accept",
+            headers=_h("viewer-user"),
+            params={"calendarId": cid},
+        ).status_code
+        == 403
+    )
+    assert (
+        client.post(
+            "/api/meeting-requests/missing/accept",
+            headers=_h("editor-user"),
+            params={"calendarId": cid},
+        ).status_code
+        == 404
+    )
diff --git a/apps/focal/server/tests/test_data_scope_db.py b/apps/focal/server/tests/test_data_scope_db.py
new file mode 100644
index 0000000..acc6de1
--- /dev/null
+++ b/apps/focal/server/tests/test_data_scope_db.py
@@ -0,0 +1,303 @@
+"""DB-backed tests for the assistant-mode data-scoping boundary (app.data_scope).
+
+This module IS the cross-user authorization boundary: domain service sessions bypass RLS, so the
+role gates here are the only thing between a shared-calendar participant and the calendar OWNER's
+rows. The tests assert the domain-split gates (calendar vs other-pages, read vs write) by
+set-membership — including the IDOR regression for the AI chat path (a non-participant, or a
+participant without an other-pages read role, must NOT resolve to the victim's data).
+
+Skipped unless DATABASE_URL is set; run vs local Docker Postgres."""
+
+import asyncio
+import os
+from collections.abc import Coroutine
+from typing import Any
+from uuid import uuid4
+
+import pytest
+from sqlalchemy import text
+from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
+from sqlalchemy.pool import NullPool
+
+from app.data_scope import (
+    DataDomain,
+    accepted_assist_roles,
+    require_ai_write,
+    resolve_ai_data_owner,
+    resolve_data_owner,
+)
+from app.errors import NotFoundError, PermissionDeniedError
+from app.models.base import Base
+from app.models.shared_calendar import SharedCalendar, SharedCalendarParticipant
+
+DB_URL = os.getenv("DATABASE_URL")
+pytestmark = pytest.mark.skipif(not DB_URL, reason="DATABASE_URL not set")
+
+_engine = create_async_engine(DB_URL, poolclass=NullPool) if DB_URL else None
+_sessionmaker = async_sessionmaker(_engine, expire_on_commit=False) if DB_URL else None
+
+# A real UUID — resolve_ai_data_owner only trusts a UUID-shaped requested id (the IDOR fix), so the
+# owner whose data the AI caller targets must look like one.
+OWNER = "00000000-0000-4000-8000-000000000001"
+ALL_ROLES = ("owner", "full_access", "editor", "developer", "viewer", "requester")
+
+
+def _run[T](coro: Coroutine[Any, Any, T]) -> T:
+    return asyncio.run(coro)
+
+
+@pytest.fixture(scope="module", autouse=True)
+def _schema():
+    async def setup() -> None:
+        async with _engine.begin() as conn:
+            await conn.execute(text("CREATE SCHEMA IF NOT EXISTS focal"))
+            await conn.run_sync(Base.metadata.create_all)
+
+    _run(setup())
+    yield
+
+
+@pytest.fixture(autouse=True)
+def _truncate():
+    async def go() -> None:
+        async with _engine.begin() as conn:
+            await conn.execute(
+                text("TRUNCATE focal.shared_calendar_participants, focal.shared_calendars CASCADE")
+            )
+
+    _run(go())
+    yield
+
+
+def _seed_calendar(owner: str = OWNER) -> str:
+    cid = str(uuid4())
+
+    async def go() -> None:
+        async with _sessionmaker() as session:
+            session.add(SharedCalendar(id=cid, user_id=owner, name="Work"))
+            await session.commit()
+
+    _run(go())
+    return cid
+
+
+def _seed_participant(
+    calendar_id: str, user_id: str, role: str, *, invite_status: str = "accepted"
+) -> None:
+    async def go() -> None:
+        async with _sessionmaker() as session:
+            session.add(
+                SharedCalendarParticipant(
+                    shared_calendar_id=calendar_id,
+                    user_id=user_id,
+                    role=role,
+                    invite_status=invite_status,
+                )
+            )
+            await session.commit()
+
+    _run(go())
+
+
+def _resolve(caller: str, calendar_id: str | None, domain: DataDomain, action: str = "read") -> str:
+    async def go() -> str:
+        async with _sessionmaker() as session:
+            return await resolve_data_owner(
+                session, caller, calendar_id, domain=domain, action=action
+            )
+
+    return _run(go())
+
+
+def _ai_owner(caller: str, requested: object) -> str:
+    async def go() -> str:
+        async with _sessionmaker() as session:
+            return await resolve_ai_data_owner(session, caller, requested)
+
+    return _run(go())
+
+
+def _assist_roles(caller: str, owner: str) -> frozenset[str]:
+    async def go() -> frozenset[str]:
+        async with _sessionmaker() as session:
+            return await accepted_assist_roles(session, caller, owner)
+
+    return _run(go())
+
+
+def _require_write(caller: str, owner: str, domain: DataDomain) -> None:
+    async def go() -> None:
+        async with _sessionmaker() as session:
+            await require_ai_write(session, caller, owner, domain=domain)
+
+    _run(go())
+
+
+# --- resolve_data_owner: own data is backward compatible ---------------------
+
+
+def test_no_calendar_id_resolves_to_caller_for_every_gate() -> None:
+    # The whole installed base calls these endpoints with no calendarId — they must keep getting
+    # their own data, for both domains and both actions, with no DB lookup required.
+    for domain in (DataDomain.CALENDAR, DataDomain.OTHER_PAGES):
+        for action in ("read", "write"):
+            assert _resolve("anybody", None, domain, action) == "anybody"
+
+
+def test_own_calendar_resolves_to_caller() -> None:
+    cid = _seed_calendar(owner="me")
+    assert _resolve("me", cid, DataDomain.OTHER_PAGES, "write") == "me"
+
+
+def test_missing_calendar_is_not_found() -> None:
+    with pytest.raises(NotFoundError):
+        _resolve("me", str(uuid4()), DataDomain.CALENDAR, "read")
+
+
+# --- resolve_data_owner: calendar domain gates -------------------------------
+
+
+def test_calendar_read_allows_every_accepted_role() -> None:
+    for role in ALL_ROLES:
+        cid = _seed_calendar()
+        _seed_participant(cid, "guest", role)
+        assert _resolve("guest", cid, DataDomain.CALENDAR, "read") == OWNER
+
+
+def test_calendar_write_allows_only_can_edit_roles() -> None:
+    can_edit = {"owner", "full_access", "editor"}
+    for role in ALL_ROLES:
+        cid = _seed_calendar()
+        _seed_participant(cid, "guest", role)
+        if role in can_edit:
+            assert _resolve("guest", cid, DataDomain.CALENDAR, "write") == OWNER
+        else:
+            with pytest.raises(PermissionDeniedError):
+                _resolve("guest", cid, DataDomain.CALENDAR, "write")
+
+
+# --- resolve_data_owner: other-pages domain gates ----------------------------
+
+
+def test_other_pages_read_allows_only_can_view_other_pages() -> None:
+    can_view = {"owner", "full_access", "developer"}
+    for role in ALL_ROLES:
+        cid = _seed_calendar()
+        _seed_participant(cid, "guest", role)
+        if role in can_view:
+            assert _resolve("guest", cid, DataDomain.OTHER_PAGES, "read") == OWNER
+        else:
+            with pytest.raises(PermissionDeniedError):
+                _resolve("guest", cid, DataDomain.OTHER_PAGES, "read")
+
+
+def test_other_pages_write_allows_only_owner_and_full_access() -> None:
+    can_write = {"owner", "full_access"}
+    for role in ALL_ROLES:
+        cid = _seed_calendar()
+        _seed_participant(cid, "guest", role)
+        if role in can_write:
+            assert _resolve("guest", cid, DataDomain.OTHER_PAGES, "write") == OWNER
+        else:
+            with pytest.raises(PermissionDeniedError):
+                _resolve("guest", cid, DataDomain.OTHER_PAGES, "write")
+
+
+def test_pending_invite_grants_no_access() -> None:
+    cid = _seed_calendar()
+    _seed_participant(cid, "guest", "full_access", invite_status="pending")
+    with pytest.raises(PermissionDeniedError):
+        _resolve("guest", cid, DataDomain.CALENDAR, "read")
+
+
+# --- accepted_assist_roles ---------------------------------------------------
+
+
+def test_assist_roles_is_owner_for_self() -> None:
+    assert _assist_roles(OWNER, OWNER) == frozenset({"owner"})
+
+
+def test_assist_roles_collects_every_accepted_role_across_calendars() -> None:
+    # The set — not a single rank-max — so a tied rank-10 role (e.g. viewer) can't mask another held
+    # role (e.g. developer) that would pass a set-membership gate.
+    c1, c2 = _seed_calendar(), _seed_calendar()
+    _seed_participant(c1, "guest", "viewer")
+    _seed_participant(c2, "guest", "developer")
+    assert _assist_roles("guest", OWNER) == frozenset({"viewer", "developer"})
+
+
+def test_assist_roles_ignores_pending_and_strangers() -> None:
+    cid = _seed_calendar()
+    _seed_participant(cid, "guest", "developer", invite_status="pending")
+    assert _assist_roles("guest", OWNER) == frozenset()
+    assert _assist_roles("nobody", OWNER) == frozenset()
+
+
+# --- resolve_ai_data_owner: the IDOR boundary --------------------------------
+
+
+def test_ai_owner_falls_back_to_caller_for_absent_or_self_or_garbage() -> None:
+    for requested in (None, "", "   ", 123, "me", "not-a-uuid"):
+        assert _ai_owner("me", requested) == "me"
+
+
+def test_ai_owner_serves_victim_data_only_with_other_pages_read_role() -> None:
+    can_view = {"full_access", "developer"}  # owner is the self case, handled separately
+    # The roles aggregate across ALL of a target's calendars, so each role gets a fresh victim —
+    # otherwise the caller's earlier role would leak into the next iteration.
+    for role in ("full_access", "developer", "editor", "viewer", "requester"):
+        victim = str(uuid4())
+        cid = _seed_calendar(owner=victim)
+        _seed_participant(cid, "caller", role)
+        if role in can_view:
+            assert _ai_owner("caller", victim) == victim
+        else:
+            with pytest.raises(PermissionDeniedError):
+                _ai_owner("caller", victim)
+
+
+def test_ai_owner_allows_when_a_tied_rank_role_grants_access() -> None:
+    # The caller holds viewer on one calendar and developer on another (both the victim's, same
+    # rank 10). A rank-max could surface viewer and wrongly deny; set-membership sees developer.
+    victim = str(uuid4())
+    _seed_participant(_seed_calendar(owner=victim), "caller", "viewer")
+    _seed_participant(_seed_calendar(owner=victim), "caller", "developer")
+    assert _ai_owner("caller", victim) == victim
+
+
+def test_ai_owner_rejects_a_total_stranger() -> None:
+    # The core IDOR: a valid UUID the caller has no relationship with must NOT resolve to that data.
+    _seed_calendar()
+    with pytest.raises(PermissionDeniedError):
+        _ai_owner("stranger", OWNER)
+
+
+# --- require_ai_write --------------------------------------------------------
+
+
+def test_require_ai_write_is_a_noop_for_self() -> None:
+    _require_write("me", "me", DataDomain.OTHER_PAGES)  # no raise
+
+
+def test_require_ai_write_other_pages_needs_owner_or_full_access() -> None:
+    for role, allowed in (("full_access", True), ("developer", False), ("viewer", False)):
+        victim = str(uuid4())
+        cid = _seed_calendar(owner=victim)
+        _seed_participant(cid, "caller", role)
+        if allowed:
+            _require_write("caller", victim, DataDomain.OTHER_PAGES)
+        else:
+            with pytest.raises(PermissionDeniedError):
+                _require_write("caller", victim, DataDomain.OTHER_PAGES)
+
+
+def test_require_ai_write_calendar_needs_can_edit() -> None:
+    for role, allowed in (("editor", True), ("developer", False), ("requester", False)):
+        victim = str(uuid4())
+        cid = _seed_calendar(owner=victim)
+        _seed_participant(cid, "caller", role)
+        if allowed:
+            _require_write("caller", victim, DataDomain.CALENDAR)
+        else:
+            with pytest.raises(PermissionDeniedError):
+                _require_write("caller", victim, DataDomain.CALENDAR)
diff --git a/apps/focal/server/tests/test_route_scope_partition.py b/apps/focal/server/tests/test_route_scope_partition.py
new file mode 100644
index 0000000..df991ab
--- /dev/null
+++ b/apps/focal/server/tests/test_route_scope_partition.py
@@ -0,0 +1,95 @@
+"""Closed-partition guard for the assistant-mode data-scoping design.
+
+Every per-user data route must resolve its EFFECTIVE owner through ``data_scope.data_owner_dep``
+(or, for the calendar scope-invariant + AI buckets, branch on ``calendarId`` inside the handler).
+A scoped route that injects ``get_current_user_id`` directly silently serves the CALLER's own data
+in shared mode instead of the owner's — a scope leak. These tests fail the build if (a) a
+calendar/other-pages router reverts to raw ``get_current_user_id``, or (b) a brand-new router keeps
+direct ``get_current_user_id`` without being deliberately classified, forcing a
+calendar/other-pages/self-only decision for any route added later.
+
+Pure route introspection — no DB, always runs."""
+
+import inspect
+
+from fastapi.params import Depends as DependsParam
+
+from app.deps import get_current_user_id
+from app.main import app
+
+# Owner resolved by data_owner_dep — a direct get_current_user_id on any of these routes is a leak.
+SCOPED_VIA_DEP = {
+    "activities",
+    "activity_instances",
+    "analytics",
+    "goals",
+    "habit_entries",
+    "habits",
+    "meeting_requests",
+    "mindmap",
+    "projects",
+    "spheres",
+    "stats",
+    "tags",
+    "tasks",
+    "time_budgets",
+}
+
+# Routers that legitimately keep direct get_current_user_id: the calendar scope-invariant set
+# (calendar / calendar_init / bookings — they branch on calendarId through SharedCalendarsService to
+# apply the filter), the AI domain (resolve_ai_data_owner), and the self-only surfaces (the caller's
+# own account / admin / export, plus already-RBAC'd sharing).
+DIRECT_GCUI_OK = {
+    "calendar",
+    "calendar_init",
+    "bookings",
+    "ai",
+    "ai_chat",
+    "agent_tokens",
+    "backup",
+    "ical",
+    "integrations",
+    "push",
+    "settings",
+    "shared_calendars",
+    "user_account",
+}
+
+
+def _direct_gcui_modules() -> dict[str, list[str]]:
+    """{api-module: [endpoint names]} for routes whose OWN signature injects get_current_user_id
+    (the nested injection inside data_owner_dep is not a top-level param, so scoped routes don't
+    appear here)."""
+    found: dict[str, list[str]] = {}
+    for route in app.routes:
+        endpoint = getattr(route, "endpoint", None)
+        if endpoint is None or not endpoint.__module__.startswith("app.api."):
+            continue
+        injects = any(
+            isinstance(p.default, DependsParam) and p.default.dependency is get_current_user_id
+            for p in inspect.signature(endpoint).parameters.values()
+        )
+        if injects:
+            found.setdefault(endpoint.__module__.rsplit(".", 1)[1], []).append(endpoint.__name__)
+    return found
+
+
+def test_scoped_routers_resolve_owner_not_raw_caller() -> None:
+    direct = _direct_gcui_modules()
+    leaks = {m: eps for m, eps in direct.items() if m in SCOPED_VIA_DEP}
+    assert not leaks, (
+        f"scoped routes still on raw get_current_user_id (must use data_owner_dep): {leaks}"
+    )
+
+
+def test_no_unclassified_get_current_user_id_router() -> None:
+    unclassified = set(_direct_gcui_modules()) - DIRECT_GCUI_OK
+    assert not unclassified, (
+        f"unclassified get_current_user_id routers: {sorted(unclassified)} — classify each as "
+        "calendar scope-invariant, ai-domain, other-pages (swap to data_owner_dep), or self-only"
+    )
+
+
+def test_classification_sets_are_disjoint() -> None:
+    # A module cannot be both scoped-via-dep and direct-gcui-ok — the partition must be clean.
+    assert not (SCOPED_VIA_DEP & DIRECT_GCUI_OK)

exec
/bin/zsh -lc 'git -C /Users/allosta/Desktop/allosta/superapp-slice2 --no-pager log --oneline --decorate --graph --max-count=30' in /Users/allosta/Desktop/allosta
 succeeded in 0ms:
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-eboRFs2U' (errno=Operation not permitted)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-tjLoOkhj' (errno=Operation not permitted)
* f121291 (HEAD -> feat/focal-parity-data-scope) Validate that activity and activity-instance FK links belong to the data owner so delegated other-pages writes cannot inject the caller's own project or activity
* e924efd Wrap a long docstring line
* 46a9d26 Validate the full delete-all recurrence-group blast radius so a shared editor cannot cascade-delete an out-of-filter sibling master
* 4862146 Block shared series writes that would touch out-of-filter override occurrences, and deny owner-only calendar management to delegated AI callers
* 41b9d63 Add a meeting-request accept cross-calendar scope test pinning the shared_calendar_id guard on the write path
* 552a1c6 Assert the override-creation step in the recurrence regression fixture so it fails at the cause
* a8232ce Resolve the effective occurrence from event id and occurrenceDate before the shared-write filter check, closing the master-id-plus-occurrenceDate recurrence escape
* d04e330 Validate both the occurrence and the master for series-scope shared writes to close the following-split filter escape, and rename the AI memory-scope owner helper to deter misuse
* a7d00a0 Open the owner-resolution session only in shared mode so own-data requests keep the DB-free in-memory path
* d9d672f Scope habit creation to the active calendar, read-only gate the Projects/Spheres/Habits write pages, and regenerate the client OpenAPI types
* cb94d19 Filter shared-mode bookings by the calendar's saved filter and meeting-requests by shared_calendar_id, including the calendar-init aggregate
* ebb90a8 Close the recurrence-scope filter escape, scope the sidebar meeting-count to the active calendar, and gate AI owner resolution by role-set membership
* 5a0837d Scope slice-2 AI changes to the IDOR fix and defer shared-calendar AI assistant mode to the AI slice
* 8f97a5e Enforce the calendar filter on shared-mode event writes and AI event reads, and scope the tasks-page projects query to the active calendar
* f385bc4 Scope client data fetches to the selected shared calendar and gate page writes read-only when the viewer lacks edit access
* 6a18e93 Add the closed-partition route guard so a scoped route on raw get_current_user_id or an unclassified router fails the build
* d102be3 Wire the calendar domain to the scope invariant: filtered shared event reads/writes, role-gated bookings and meeting-requests, and the gated calendar-init aggregate
* fe199fc Add the central data-scope authorization test suite covering both domain gates and the AI IDOR regression
* 83eee08 Close the AI-chat data-owner IDOR with an RBAC-gated resolver and per-intent write gate
* 042442c Add assistant-mode data-owner resolver and wire it onto the other-pages domain routers
* 3e9fdd3 (feature/focal-migration) feat(focal): shared-calendar switcher + role-aware sidebar (parity slice 1) (#92)
* 014134a Remove the goal-linking section from the project edit modal (#91)
*   da0e5b1 Merge pull request #90 from Allosta-Group/feat/focal-goals-create-relayout
|\  
| * 844f149 fix(focal): auto-arrange after a goal-map create using measured card sizes so new nodes do not overlap
|/  
*   3e11be2 Merge pull request #89 from Allosta-Group/feat/focal-goals-stored-position-guard
|\  
| * f8fcd6f fix(focal): ignore stray non-base and 0,0 goal-map position overrides so nodes are not pinned to the corner
|/  
*   52b203e Merge pull request #88 from Allosta-Group/feat/focal-goalmap-resize-hover
|\  
| * 02a3b92 feat(focal): resize goal-map nodes on edge hover without selecting first
|/  
*   17c0c25 Merge pull request #87 from Allosta-Group/feat/focal-goals-edge-side-centers
|\  
| * c2f04cf fix(focal): attach goal-map edges at the centre of the facing card side

exec
/bin/zsh -lc 'git -C /Users/allosta/Desktop/allosta/superapp-slice2 --no-pager diff --name-only feature/focal-migration' in /Users/allosta/Desktop/allosta
 succeeded in 0ms:
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-b8siu9gR' (errno=Operation not permitted)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-X0FIDbdU' (errno=Operation not permitted)
apps/focal/client/src/api/activities.ts
apps/focal/client/src/api/activityInstances.ts
apps/focal/client/src/api/analytics.ts
apps/focal/client/src/api/events.ts
apps/focal/client/src/api/goals.ts
apps/focal/client/src/api/habits.ts
apps/focal/client/src/api/meetingRequests.ts
apps/focal/client/src/api/mindmap.ts
apps/focal/client/src/api/openapi.d.ts
apps/focal/client/src/api/products.ts
apps/focal/client/src/api/projects.ts
apps/focal/client/src/api/queryKeys.ts
apps/focal/client/src/api/spheres.ts
apps/focal/client/src/api/tags.ts
apps/focal/client/src/api/tasks.ts
apps/focal/client/src/api/timeBudgets.ts
apps/focal/client/src/components/AppShell.test.tsx
apps/focal/client/src/components/AppSidebar.tsx
apps/focal/client/src/features/analytics/useSpheresAnalyticsData.ts
apps/focal/client/src/features/budgets/TimeBudgetsPage.test.tsx
apps/focal/client/src/features/budgets/TimeBudgetsPage.tsx
apps/focal/client/src/features/calendar/CalendarPage.test.tsx
apps/focal/client/src/features/calendar/CalendarPage.tsx
apps/focal/client/src/features/calendar/EventPopover.tsx
apps/focal/client/src/features/calendar/TimeGrid.tsx
apps/focal/client/src/features/calendars/CalendarsPage.tsx
apps/focal/client/src/features/events/EventsPage.test.tsx
apps/focal/client/src/features/events/EventsPage.tsx
apps/focal/client/src/features/goals/ActivityEditModal.tsx
apps/focal/client/src/features/goals/FocalNode.test.tsx
apps/focal/client/src/features/goals/FocalNode.tsx
apps/focal/client/src/features/goals/GoalsPage.tsx
apps/focal/client/src/features/goals/NodeEditModal.tsx
apps/focal/client/src/features/goals/ProjectEditModal.tsx
apps/focal/client/src/features/goals/goalsContext.ts
apps/focal/client/src/features/habits/HabitCharts.tsx
apps/focal/client/src/features/habits/HabitCreateDialog.tsx
apps/focal/client/src/features/habits/HabitJournal.tsx
apps/focal/client/src/features/habits/HabitsPage.test.tsx
apps/focal/client/src/features/habits/HabitsPage.tsx
apps/focal/client/src/features/heatmap/HeatmapPage.test.tsx
apps/focal/client/src/features/heatmap/HeatmapPage.tsx
apps/focal/client/src/features/meetings/MeetingRequestsPage.test.tsx
apps/focal/client/src/features/meetings/MeetingRequestsPage.tsx
apps/focal/client/src/features/projects/ProjectsPage.test.tsx
apps/focal/client/src/features/projects/ProjectsPage.tsx
apps/focal/client/src/features/spheres/SpheresPage.test.tsx
apps/focal/client/src/features/spheres/SpheresPage.tsx
apps/focal/client/src/features/tags/TagsPage.test.tsx
apps/focal/client/src/features/tags/TagsPage.tsx
apps/focal/client/src/features/tasks/TasksPage.test.tsx
apps/focal/client/src/features/tasks/TasksPage.tsx
apps/focal/client/src/i18n/locales/en.json
apps/focal/client/src/i18n/locales/ru.json
apps/focal/server/app/ai/chat_support.py
apps/focal/server/app/api/activities.py
apps/focal/server/app/api/activity_instances.py
apps/focal/server/app/api/ai.py
apps/focal/server/app/api/ai_chat.py
apps/focal/server/app/api/analytics.py
apps/focal/server/app/api/bookings.py
apps/focal/server/app/api/calendar.py
apps/focal/server/app/api/calendar_init.py
apps/focal/server/app/api/goals.py
apps/focal/server/app/api/habit_entries.py
apps/focal/server/app/api/habits.py
apps/focal/server/app/api/meeting_requests.py
apps/focal/server/app/api/mindmap.py
apps/focal/server/app/api/projects.py
apps/focal/server/app/api/spheres.py
apps/focal/server/app/api/stats.py
apps/focal/server/app/api/tags.py
apps/focal/server/app/api/tasks.py
apps/focal/server/app/api/time_budgets.py
apps/focal/server/app/data_scope.py
apps/focal/server/app/services/activities.py
apps/focal/server/app/services/activity_instances.py
apps/focal/server/app/services/calendar.py
apps/focal/server/app/services/calendar_init.py
apps/focal/server/app/services/meeting_requests.py
apps/focal/server/app/services/shared_calendars.py
apps/focal/server/tests/test_ai_chat_support_db.py
apps/focal/server/tests/test_calendar_scope_db.py
apps/focal/server/tests/test_data_scope_db.py
apps/focal/server/tests/test_route_scope_partition.py

exec
/bin/zsh -lc 'git -C /Users/allosta/Desktop/allosta/superapp-slice2 --no-pager diff --stat feature/focal-migration' in /Users/allosta/Desktop/allosta
 succeeded in 0ms:
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-s60yL7x1' (errno=Operation not permitted)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-Z5MJQFuZ' (errno=Operation not permitted)
 apps/focal/client/src/api/activities.ts            |  17 +-
 apps/focal/client/src/api/activityInstances.ts     |  23 +-
 apps/focal/client/src/api/analytics.ts             |   6 +-
 apps/focal/client/src/api/events.ts                |  36 +-
 apps/focal/client/src/api/goals.ts                 |  24 +-
 apps/focal/client/src/api/habits.ts                |  71 +-
 apps/focal/client/src/api/meetingRequests.ts       |  58 +-
 apps/focal/client/src/api/mindmap.ts               |  92 ++-
 apps/focal/client/src/api/openapi.d.ts             | 319 +++++++--
 apps/focal/client/src/api/products.ts              |   6 +-
 apps/focal/client/src/api/projects.ts              |  24 +-
 apps/focal/client/src/api/queryKeys.ts             |  16 +
 apps/focal/client/src/api/spheres.ts               |  24 +-
 apps/focal/client/src/api/tags.ts                  |  20 +-
 apps/focal/client/src/api/tasks.ts                 |  39 +-
 apps/focal/client/src/api/timeBudgets.ts           |  63 +-
 apps/focal/client/src/components/AppShell.test.tsx |  14 +-
 apps/focal/client/src/components/AppSidebar.tsx    |  11 +-
 .../features/analytics/useSpheresAnalyticsData.ts  |  22 +-
 .../src/features/budgets/TimeBudgetsPage.test.tsx  |   8 +-
 .../src/features/budgets/TimeBudgetsPage.tsx       | 208 ++++--
 .../src/features/calendar/CalendarPage.test.tsx    | 117 +--
 .../client/src/features/calendar/CalendarPage.tsx  |  23 +-
 .../client/src/features/calendar/EventPopover.tsx  |  45 +-
 .../client/src/features/calendar/TimeGrid.tsx      |  18 +-
 .../src/features/calendars/CalendarsPage.tsx       |  17 +-
 .../client/src/features/events/EventsPage.test.tsx |  44 +-
 .../client/src/features/events/EventsPage.tsx      |  53 +-
 .../src/features/goals/ActivityEditModal.tsx       |  31 +-
 .../client/src/features/goals/FocalNode.test.tsx   |   1 +
 apps/focal/client/src/features/goals/FocalNode.tsx |   7 +-
 apps/focal/client/src/features/goals/GoalsPage.tsx | 145 ++--
 .../client/src/features/goals/NodeEditModal.tsx    |  34 +-
 .../client/src/features/goals/ProjectEditModal.tsx |  61 +-
 .../client/src/features/goals/goalsContext.ts      |   3 +
 .../client/src/features/habits/HabitCharts.tsx     |  16 +-
 .../src/features/habits/HabitCreateDialog.tsx      |  15 +-
 .../client/src/features/habits/HabitJournal.tsx    |  67 +-
 .../client/src/features/habits/HabitsPage.test.tsx |  65 +-
 .../client/src/features/habits/HabitsPage.tsx      |  17 +-
 .../src/features/heatmap/HeatmapPage.test.tsx      |   6 +-
 .../client/src/features/heatmap/HeatmapPage.tsx    |  23 +-
 .../features/meetings/MeetingRequestsPage.test.tsx |  16 +-
 .../src/features/meetings/MeetingRequestsPage.tsx  |  57 +-
 .../src/features/projects/ProjectsPage.test.tsx    |  26 +-
 .../client/src/features/projects/ProjectsPage.tsx  |  60 +-
 .../src/features/spheres/SpheresPage.test.tsx      |  19 +-
 .../client/src/features/spheres/SpheresPage.tsx    |  54 +-
 .../client/src/features/tags/TagsPage.test.tsx     |  10 +-
 apps/focal/client/src/features/tags/TagsPage.tsx   |  31 +-
 .../client/src/features/tasks/TasksPage.test.tsx   |  32 +-
 apps/focal/client/src/features/tasks/TasksPage.tsx |  55 +-
 apps/focal/client/src/i18n/locales/en.json         |   1 +
 apps/focal/client/src/i18n/locales/ru.json         |   1 +
 apps/focal/server/app/ai/chat_support.py           |  10 +-
 apps/focal/server/app/api/activities.py            |  15 +-
 apps/focal/server/app/api/activity_instances.py    |  17 +-
 apps/focal/server/app/api/ai.py                    |   4 +-
 apps/focal/server/app/api/ai_chat.py               |  22 +-
 apps/focal/server/app/api/analytics.py             |   7 +-
 apps/focal/server/app/api/bookings.py              |  33 +-
 apps/focal/server/app/api/calendar.py              |  50 +-
 apps/focal/server/app/api/calendar_init.py         |  25 +-
 apps/focal/server/app/api/goals.py                 |  15 +-
 apps/focal/server/app/api/habit_entries.py         |  13 +-
 apps/focal/server/app/api/habits.py                |  21 +-
 apps/focal/server/app/api/meeting_requests.py      |  58 +-
 apps/focal/server/app/api/mindmap.py               |  23 +-
 apps/focal/server/app/api/projects.py              |  19 +-
 apps/focal/server/app/api/spheres.py               |  15 +-
 apps/focal/server/app/api/stats.py                 |   8 +-
 apps/focal/server/app/api/tags.py                  |  13 +-
 apps/focal/server/app/api/tasks.py                 |  16 +-
 apps/focal/server/app/api/time_budgets.py          |  27 +-
 apps/focal/server/app/data_scope.py                | 184 +++++
 apps/focal/server/app/services/activities.py       |  23 +-
 .../server/app/services/activity_instances.py      |   8 +-
 apps/focal/server/app/services/calendar.py         | 103 +++
 apps/focal/server/app/services/calendar_init.py    |  27 +-
 apps/focal/server/app/services/meeting_requests.py |  73 +-
 apps/focal/server/app/services/shared_calendars.py | 252 ++++++-
 apps/focal/server/tests/test_ai_chat_support_db.py |   4 +-
 apps/focal/server/tests/test_calendar_scope_db.py  | 790 +++++++++++++++++++++
 apps/focal/server/tests/test_data_scope_db.py      | 303 ++++++++
 .../server/tests/test_route_scope_partition.py     |  95 +++
 85 files changed, 3763 insertions(+), 781 deletions(-)

exec
/bin/zsh -lc 'git -C /Users/allosta/Desktop/allosta/superapp-slice2 --no-pager diff --check feature/focal-migration' in /Users/allosta/Desktop/allosta
 succeeded in 0ms:
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-vs8Cq3T5' (errno=Operation not permitted)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-Xy8QwPRK' (errno=Operation not permitted)

exec
/bin/zsh -lc "sed -n '1,360p' .ai/design/focal-parity-design.md" in /Users/allosta/Desktop/allosta/superapp-slice2
exec
/bin/zsh -lc "sed -n '1,360p' .ai/design/focal-parity-data-scope-design.md" in /Users/allosta/Desktop/allosta/superapp-slice2
exec
/bin/zsh -lc "sed -n '1,320p' .ai/plans/focal-parity-plan.md" in /Users/allosta/Desktop/allosta/superapp-slice2
 exited 1 in 0ms:
sed: .ai/design/focal-parity-data-scope-design.md: No such file or directory

 exited 1 in 0ms:
sed: .ai/design/focal-parity-design.md: No such file or directory

 exited 1 in 0ms:
sed: .ai/plans/focal-parity-plan.md: No such file or directory

exec
/bin/zsh -lc "sed -n '1,260p' .ai/tasks/focal-parity.md" in /Users/allosta/Desktop/allosta/superapp-slice2
 exited 1 in 0ms:
sed: .ai/tasks/focal-parity.md: No such file or directory

exec
/bin/zsh -lc "sed -n '1,240p' .ai/checklists/scoring-rubric.md" in /Users/allosta/Desktop/allosta/superapp-slice2
 exited 1 in 0ms:
sed: .ai/checklists/scoring-rubric.md: No such file or directory

exec
/bin/zsh -lc 'ls -la /Users/allosta/Desktop/allosta' in /Users/allosta/Desktop/allosta
 succeeded in 0ms:
total 72
drwxr-xr-x@ 16 allosta  staff   512 Jun 25 22:15 .
drwx------+  8 allosta  staff   256 Jun 23 19:56 ..
-rw-r--r--@  1 allosta  staff  8196 Jun 17 17:18 .DS_Store
drwxr-xr-x@ 14 allosta  staff   448 Jun  6 08:51 .ai
drwxr-xr-x@  4 allosta  staff   128 Jun 22 21:34 .claude
drwxr-xr-x@ 17 allosta  staff   544 Jun 26 12:36 .git
-rw-r--r--@  1 allosta  staff   142 Jun  6 08:49 .gitignore
drwxr-xr-x@  3 allosta  staff    96 Jun 17 19:17 .pnpm-store
drwxr-xr-x@  2 allosta  staff    64 Jun 25 11:39 .worktrees
-rw-r--r--@  1 allosta  staff  1730 Jun  6 08:49 AGENTS.md
-rw-r--r--@  1 allosta  staff  2903 Jun  6 08:12 CLAUDE.md
-rw-r--r--@  1 allosta  staff   964 May 29 15:27 Makefile
-rw-r--r--@  1 allosta  staff  3652 Jun 14 15:14 README.md
-rw-r--r--@  1 allosta  staff  2859 Jun 25 16:08 goals-page-stale-wip.patch
drwxr-xr-x@ 25 allosta  staff   800 Jun 25 22:13 superapp
drwxr-xr-x@ 20 allosta  staff   640 Jun 26 11:55 superapp-slice2

exec
/bin/zsh -lc "find /Users/allosta/Desktop/allosta -maxdepth 4 -path '*/.ai/*' -type f | sort | sed -n '1,200p'" in /Users/allosta/Desktop/allosta
 succeeded in 0ms:
/Users/allosta/Desktop/allosta/.ai/README.md
/Users/allosta/Desktop/allosta/.ai/archive/README.md
/Users/allosta/Desktop/allosta/.ai/archive/prompts-legacy/claude-builder.md
/Users/allosta/Desktop/allosta/.ai/archive/prompts-legacy/codex-reviewer.md
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/.gitkeep
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/_d3a-gate1-instr.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/_d3a-gate2-instr.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/_d3a-gate3-instr.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/_d3a-gate4-instr.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/_d3a-gate5-instr.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/_d3b-gate1-instr.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/_gate1-instr.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/_gate2-instr.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/_gate3-instr.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/_gate3r3-instr.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/_gate4-instr.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/_gate5-instr.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-events-code.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-events-final.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-events-plan-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-events-plan.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-events-task.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-events-tests-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-events-tests.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-goals-budgets-code.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-goals-budgets-final.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-goals-budgets-plan-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-goals-budgets-plan.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-goals-budgets-task.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-goals-budgets-tests.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-ical-alias-code.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-ical-alias-final.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-ical-alias-plan.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-ical-alias-task.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-ical-alias-tests.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-ical-feed-code.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-ical-feed-final.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-ical-feed-plan-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-ical-feed-plan.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-ical-feed-task.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-ical-feed-tests-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-ical-feed-tests.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-logs-code.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-logs-final.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-logs-plan-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-logs-plan.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-logs-task.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-logs-tests.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-rate-limit-code.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-rate-limit-final.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-rate-limit-plan.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-rate-limit-task.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-rate-limit-tests-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-rate-limit-tests.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-tasks-code.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-tasks-final.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-tasks-plan-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-tasks-plan.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-tasks-task.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-tasks-tests-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-tasks-tests.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-token-logs-code.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-token-logs-final.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-token-logs-plan-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-token-logs-plan.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-token-logs-task.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-token-logs-tests.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-tokens-code-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-tokens-code.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-tokens-final-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-tokens-final.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-tokens-plan.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-tokens-task-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-tokens-task.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-tokens-tests-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-agent-tokens-tests.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-analytics-spheres-code.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-analytics-spheres-final.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-analytics-spheres-plan-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-analytics-spheres-plan-3.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-analytics-spheres-plan.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-analytics-spheres-task.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-analytics-spheres-tests.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-bookings-01-task-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-bookings-01-task.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-bookings-02-plan-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-bookings-02-plan.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-bookings-03-code.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-bookings-04-test-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-bookings-04-test.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-bookings-05-final.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-events-01-task-10.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-events-01-task-11.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-events-01-task-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-events-01-task-3.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-events-01-task-4.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-events-01-task-5.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-events-01-task-6.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-events-01-task-7.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-events-01-task-8.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-events-01-task-9.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-events-01-task.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-events-02-plan-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-events-02-plan.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-events-03-code-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-events-03-code.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-events-04-test-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-events-04-test-3.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-events-04-test.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-events-05-final-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-events-05-final.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-events-verify.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-init-01-task.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-init-02-plan.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-init-03-code.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-init-04-test-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-init-04-test.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-init-05-final-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-init-05-final.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-recurrence-read-01-task-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-recurrence-read-01-task.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-recurrence-read-02-plan-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-recurrence-read-02-plan.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-recurrence-read-03-code-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-recurrence-read-03-code.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-recurrence-read-04-test-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-recurrence-read-04-test.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-recurrence-read-05-final.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-recurrence-read-verify.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-recurrence-write-01-task-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-recurrence-write-01-task.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-recurrence-write-02-plan-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-recurrence-write-02-plan.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-recurrence-write-03-code-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-recurrence-write-03-code.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-recurrence-write-04-test-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-recurrence-write-04-test-3.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-recurrence-write-04-test.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-recurrence-write-05-final-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-calendar-recurrence-write-05-final.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-habits-crud-code-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-habits-crud-code.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-habits-crud-final.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-habits-crud-plan.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-habits-crud-task-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-habits-crud-task.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-habits-crud-tests-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-habits-crud-tests.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-habits-entries-code.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-habits-entries-final.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-habits-entries-plan.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-habits-entries-task.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-habits-entries-tests-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-habits-entries-tests.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-ical-serializer-code.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-ical-serializer-final.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-ical-serializer-plan-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-ical-serializer-plan.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-ical-serializer-task-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-ical-serializer-task.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-ical-serializer-tests-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-ical-serializer-tests.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-meeting-requests-read-code.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-meeting-requests-read-final-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-meeting-requests-read-final.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-meeting-requests-read-plan-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-meeting-requests-read-plan.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-meeting-requests-read-task.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-meeting-requests-read-tests.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-mindmap-graph-03-code-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-mindmap-graph-03-code.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-mindmap-graph-04-test-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-mindmap-graph-04-test.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-mindmap-graph-05-final-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-mindmap-graph-05-final.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-mindmap-graph-plan-r1.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-mindmap-graph-plan-r2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-mindmap-graph-plan-r3.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-mindmap-graph-plan-r4.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-mindmap-graph-task-r1.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-mindmap-graph-task-r2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-mindmap-graph-task-r3.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-mindmap-graph-task-r4.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-mindmap-graph-task-r5.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-mindmap-graph-task-r6.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-mindmap-graph-verify.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-shared-calendars-crud-01-task-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-shared-calendars-crud-01-task.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-shared-calendars-crud-02-plan-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-shared-calendars-crud-02-plan.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-shared-calendars-crud-03-code.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-shared-calendars-crud-04-test-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-shared-calendars-crud-04-test.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-shared-calendars-crud-05-final-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-shared-calendars-crud-05-final.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-shared-calendars-events-01-task.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-shared-calendars-events-02-plan-2.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-shared-calendars-events-02-plan.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-shared-calendars-events-03-code.txt
/Users/allosta/Desktop/allosta/.ai/archive/runs-legacy/focal-shared-calendars-events-04-test.txt

exec
/bin/zsh -lc "ls -la /Users/allosta/Desktop/allosta/superapp-slice2 | sed -n '1,120p'" in /Users/allosta/Desktop/allosta
 succeeded in 0ms:
total 752
drwxr-xr-x@ 20 allosta  staff     640 Jun 26 11:55 .
drwxr-xr-x@ 16 allosta  staff     512 Jun 25 22:15 ..
-rw-r--r--@  1 allosta  staff     715 Jun 25 17:26 .dockerignore
-rw-r--r--@  1 allosta  staff      79 Jun 25 17:26 .git
drwxr-xr-x@  3 allosta  staff      96 Jun 25 17:26 .github
-rw-r--r--@  1 allosta  staff    1366 Jun 25 17:26 .gitignore
-rw-r--r--@  1 allosta  staff   47901 Jun 25 17:26 AGENTS.md
-rw-r--r--@  1 allosta  staff    9084 Jun 25 17:26 ARCHITECTURE.md
-rw-r--r--@  1 allosta  staff   35052 Jun 25 17:26 CLAUDE.md
-rw-r--r--@  1 allosta  staff    4203 Jun 25 17:26 README.md
drwxr-xr-x@  4 allosta  staff     128 Jun 25 17:26 apps
drwxr-xr-x@ 18 allosta  staff     576 Jun 25 17:26 docs
drwxr-xr-x@  5 allosta  staff     160 Jun 25 17:26 node_modules
-rw-r--r--@  1 allosta  staff     138 Jun 25 17:26 package.json
-rw-r--r--@  1 allosta  staff  247306 Jun 25 17:26 pnpm-lock.yaml
-rw-r--r--@  1 allosta  staff     415 Jun 25 17:26 pnpm-workspace.yaml
-rw-r--r--@  1 allosta  staff    4804 Jun 25 17:26 posthog-setup-report.md
drwxr-xr-x@  8 allosta  staff     256 Jun 25 17:26 prompts
drwxr-xr-x@ 12 allosta  staff     384 Jun 25 17:26 scripts
drwxr-xr-x@  3 allosta  staff      96 Jun 25 17:26 shared

exec
/bin/zsh -lc "find /Users/allosta/Desktop/allosta/.ai -maxdepth 4 -type f | grep -E '(focal-parity|scoring-rubric|final-release)' | sort" in /Users/allosta/Desktop/allosta
 succeeded in 0ms:
/Users/allosta/Desktop/allosta/.ai/checklists/scoring-rubric.md
/Users/allosta/Desktop/allosta/.ai/design/focal-parity-data-scope-design.md
/Users/allosta/Desktop/allosta/.ai/design/focal-parity-design.md
/Users/allosta/Desktop/allosta/.ai/handoffs/focal-parity-shared-calendar-handoff.md
/Users/allosta/Desktop/allosta/.ai/handoffs/focal-parity-timezone-PR.md
/Users/allosta/Desktop/allosta/.ai/plans/focal-parity-plan.md
/Users/allosta/Desktop/allosta/.ai/prompts/final-release-review.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/03-design-verdict-2.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/03-design-verdict-3.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/03-design-verdict-4.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/03-design-verdict-5.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/03-design-verdict-6.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/03-design-verdict-7.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/03-design-verdict-8.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/03-design-verdict.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/04-build-verdict-1.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/04-build-verdict-9.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/05-review-pass-2.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/05-review-pass-3.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/05-review-pass-4.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/05-review-pass-5.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/05-review-pass.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/05-review-verdict-2.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/05-review-verdict.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-timezone/04-build-verdict-1.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-timezone/04-build-verdict-2.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-timezone/04-build-verdict-3.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-timezone/05-review-pass.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-timezone/05-review-verdict.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-timezone/06-test-verdict.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-timezone/07-ship-verdict.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/01-think-verdict-2.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/01-think-verdict.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/02-plan-verdict.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/03-design-verdict-2.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/03-design-verdict.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/04-build-verdict-1.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/04-build-verdict-2.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/04-build-verdict-3.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/05-review-pass.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/05-review-verdict.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/06-test-verdict.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/07-ship-verdict.md
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-01-think-2.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-01-think.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-03-design-2.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-03-design.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-04-build-2.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-04-build-3.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-04-build.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-05-review-pass-2.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-05-review-pass-3.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-05-review-pass-4.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-05-review-pass.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-07-ship.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-data-scope-03-design-2.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-data-scope-03-design-3.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-data-scope-03-design-4.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-data-scope-03-design-5.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-data-scope-03-design-6.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-data-scope-03-design-7.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-data-scope-03-design-8.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-data-scope-03-design-9.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-data-scope-03-design.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-test.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-timezone-04-build-2.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-timezone-04-build-3.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-timezone-04-build-4.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-timezone-04-build.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-timezone-05-review-pass-2.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-timezone-05-review-pass.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-timezone-test.txt
/Users/allosta/Desktop/allosta/.ai/tasks/focal-parity.md
/Users/allosta/Desktop/allosta/.ai/think/focal-parity.md

exec
/bin/zsh -lc "find /Users/allosta/Desktop/allosta -path '*/focal-parity*' -type f -o -path '*/scoring-rubric.md' -type f | sort" in /Users/allosta/Desktop/allosta
exec
/bin/zsh -lc "find /Users/allosta/Desktop/allosta/superapp-slice2 -maxdepth 4 -type f | grep -E '(focal-parity|scoring-rubric|final-release)' | sort" in /Users/allosta/Desktop/allosta
 succeeded in 0ms:
 succeeded in 2506ms:
/Users/allosta/Desktop/allosta/.ai/checklists/scoring-rubric.md
/Users/allosta/Desktop/allosta/.ai/design/focal-parity-data-scope-design.md
/Users/allosta/Desktop/allosta/.ai/design/focal-parity-design.md
/Users/allosta/Desktop/allosta/.ai/handoffs/focal-parity-shared-calendar-handoff.md
/Users/allosta/Desktop/allosta/.ai/handoffs/focal-parity-timezone-PR.md
/Users/allosta/Desktop/allosta/.ai/plans/focal-parity-plan.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/03-design-verdict-2.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/03-design-verdict-3.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/03-design-verdict-4.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/03-design-verdict-5.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/03-design-verdict-6.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/03-design-verdict-7.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/03-design-verdict-8.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/03-design-verdict.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/04-build-verdict-1.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/04-build-verdict-9.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/05-review-pass-2.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/05-review-pass-3.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/05-review-pass-4.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/05-review-pass-5.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/05-review-pass.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/05-review-verdict-2.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/05-review-verdict.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-timezone/04-build-verdict-1.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-timezone/04-build-verdict-2.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-timezone/04-build-verdict-3.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-timezone/05-review-pass.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-timezone/05-review-verdict.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-timezone/06-test-verdict.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-timezone/07-ship-verdict.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/01-think-verdict-2.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/01-think-verdict.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/02-plan-verdict.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/03-design-verdict-2.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/03-design-verdict.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/04-build-verdict-1.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/04-build-verdict-2.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/04-build-verdict-3.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/05-review-pass.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/05-review-verdict.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/06-test-verdict.md
/Users/allosta/Desktop/allosta/.ai/reviews/focal-parity/07-ship-verdict.md
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-01-think-2.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-01-think.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-03-design-2.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-03-design.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-04-build-2.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-04-build-3.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-04-build.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-05-review-pass-2.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-05-review-pass-3.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-05-review-pass-4.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-05-review-pass.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-07-ship.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-data-scope-03-design-2.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-data-scope-03-design-3.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-data-scope-03-design-4.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-data-scope-03-design-5.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-data-scope-03-design-6.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-data-scope-03-design-7.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-data-scope-03-design-8.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-data-scope-03-design-9.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-data-scope-03-design.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-test.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-timezone-04-build-2.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-timezone-04-build-3.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-timezone-04-build-4.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-timezone-04-build.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-timezone-05-review-pass-2.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-timezone-05-review-pass.txt
/Users/allosta/Desktop/allosta/.ai/runs/focal-parity-timezone-test.txt
/Users/allosta/Desktop/allosta/.ai/tasks/focal-parity.md
/Users/allosta/Desktop/allosta/.ai/think/focal-parity.md
/Users/allosta/Desktop/allosta/superapp/.git/logs/refs/heads/feat/focal-parity-data-scope
/Users/allosta/Desktop/allosta/superapp/.git/refs/heads/feat/focal-parity-data-scope

exec
/bin/zsh -lc "sed -n '1,260p' /Users/allosta/Desktop/allosta/.ai/tasks/focal-parity.md" in /Users/allosta/Desktop/allosta
exec
/bin/zsh -lc "sed -n '1,340p' /Users/allosta/Desktop/allosta/.ai/plans/focal-parity-plan.md" in /Users/allosta/Desktop/allosta
 succeeded in 0ms:
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

 succeeded in 0ms:
# Summary

Bring the new Focal client to old-focal functional parity as an ordered epic of independently
reviewable slices, not as one large diff. Old-focal remains the behavioral source of truth; the
new app's existing extra pages/features stay unless they conflict with parity. The first slices add
the two foundations that later pages consume: shared-calendar role/data scope and display timezone.
Per-area slices then close Tasks, Events, Calendar, Habits, Goals, Analytics, and Google sync. The
independent systemic slices, offline/PWA and the global assistant/voice flow, come after the page
work because the page work does not depend on them.

Backend gaps are explicit handoffs inside their owning slice. Task recurrence plus multi-participant
fields, and event custom recurrence beyond the current simple recurrence fields, must be added in
the FastAPI models/schemas/services with autogenerated Alembic migrations by the developer or
interactive Claude Code. The client must not fake those fields.

# Files to change

This is an epic file list. Each build gate must touch only the rows needed for its current slice and
leave the client checks green. Exact component extraction can change at design gate, but the owning
modules should stay within these paths.

| path | change | why |
|------|--------|-----|
| `superapp/apps/focal/client/src/App.tsx` | modify | mount `CalendarFilterProvider`, `TimezoneProvider`, offline/PWA shell, and the global assistant only when their slices land |
| `superapp/apps/focal/client/src/features/calendars/CalendarFilterContext.tsx` | add | old-focal-compatible selected-calendar, role, `canEdit`, `dataOwnerId`, assistant-mode, and `matchesFilter` provider |
| `superapp/apps/focal/client/src/features/calendars/CalendarFilterContext.test.tsx` | add | role matrix, selection persistence, stale selection, auto-select, and filter semantics |
| `superapp/apps/focal/client/src/components/CalendarSwitcher.tsx` | modify | replace the static "My calendar" control with main/shared calendar selection and refresh |
| `superapp/apps/focal/client/src/components/AppSidebar.tsx` | modify | apply shared-calendar limited menu, viewing banner/status, Google sync status, and cleanup badges |
| `superapp/apps/focal/client/src/components/AppShell.tsx` | modify | host shell-level banners/prompts without page-specific duplication |
| `superapp/apps/focal/client/src/components/PageToolbar.tsx` and `PageToolbar.test.tsx` | modify | keep route-to-chat behavior until the assistant slice, then add the old-focal per-page entry point |
| `superapp/apps/focal/client/src/api/client.ts` | modify | preserve typed API errors while adding cache/offline hooks only in the offline slice |
| `superapp/apps/focal/client/src/api/queryClient.ts` | modify | add shared invalidation/cache helpers needed by timezone/offline/parity mutations |
| `superapp/apps/focal/client/src/api/{events,tasks,goals,timeBudgets,tags,analytics,integrations,sharedCalendars}.ts` | modify | pass owner/calendar scope where existing backend endpoints already support it; expose missing integration helpers |
| `superapp/apps/focal/client/src/hooks/use-timezone.tsx` | add | client display-timezone provider and selector state |
| `superapp/apps/focal/client/src/hooks/use-time-format.ts` | add | old-focal time-label helpers consumed by Calendar, Events, and AI cards |
| `superapp/apps/focal/client/src/lib/timezone.ts` | add | DST-aware client conversion helpers, aligned with old-focal and the existing backend timezone port |
| `superapp/apps/focal/client/src/components/TimezoneSelector.tsx` | add | old-focal display timezone selector |
| `superapp/apps/focal/client/src/features/{calendar,events,aichat}/*` | modify | consume display timezone and per-event timezone consistently |
| `superapp/apps/focal/client/src/features/tasks/TasksPage.tsx` and `TasksPage.test.tsx` | modify | full task editor/info/filter/search/schedule/tag/drag parity and shared-calendar gating |
| `superapp/apps/focal/client/src/components/TaskDialog.tsx` | add | old-focal create/edit task dialog after backend handoff lands |
| `superapp/apps/focal/client/src/components/TaskInfoDialog.tsx` | add | old-focal read/action task dialog with `canEdit` gating |
| `superapp/apps/focal/client/src/components/TagManager.tsx` | add or adapt | tag-management UI reused by Tasks and parity pages if no equivalent exists |
| `superapp/apps/focal/client/src/features/events/EventsPage.tsx` and `EventsPage.test.tsx` | modify | full Events page editor and shared-calendar/timezone behavior |
| `superapp/apps/focal/client/src/components/EventDialog.tsx` | add | old-focal event create/edit dialog fields |
| `superapp/apps/focal/client/src/components/EventInfoDialog.tsx` | add | old-focal event info/action dialog with recurrence scope and `canEdit` gating |
| `superapp/apps/focal/client/src/features/calendar/{CalendarPage,TimeGrid,MonthView,MiniMonth,EventBlock,EventPopover,RecurringScopeDialog}.tsx` | modify | year view, all-day, drag/resize, task panel, undo, bookings/notes/filter layers, mini dots, and info actions |
| `superapp/apps/focal/client/src/features/calendar/{dates,lanes,primaContacts}.ts` | modify | pure helpers for calendar layout/interaction parity |
| `superapp/apps/focal/client/src/features/calendar/*.test.tsx` and `*.test.ts` | modify/add | calendar interaction, layout, recurrence, and timezone tests |
| `superapp/apps/focal/client/src/components/{TaskPanel,BookingDialog,PrimeTimeDialog}.tsx` | add as needed | old-focal calendar-side panels and dialogs not currently present in the new client |
| `superapp/apps/focal/client/src/features/budgets/TimeBudgetsPage.tsx` and test | modify | shared-calendar `canEdit` and data-owner gating only; feature is otherwise parity-complete |
| `superapp/apps/focal/client/src/features/tags/TagsPage.tsx` and test | modify | shared-calendar `canEdit` and cleanup badges only; feature is otherwise parity-complete |
| `superapp/apps/focal/client/src/features/habits/{HabitsPage,HabitCreateDialog,HabitJournal,HabitCharts}.tsx` | modify | habit edit, per-day notes, presets, category/description/project link, Yes/No/Skip/Erase, delete confirm, reorder |
| `superapp/apps/focal/client/src/features/habits/*.test.tsx` and `*.test.ts` | modify/add | habit behavior parity coverage |
| `superapp/apps/focal/client/src/features/goals/*` | modify | drag-to-reparent, edge editing, finance/budget fields, schedule-to-calendar, multi-select, undo/redo, and product-less activity fix |
| `superapp/apps/focal/client/src/features/goals/*.test.tsx` and `*.test.ts` | modify/add | graph, history, node, edge, and regression coverage |
| `superapp/apps/focal/client/src/features/analytics/*` | modify | PDF export, insight blocks, Spheres summaries/footer, help popovers, collapsible sections |
| `superapp/apps/focal/client/src/features/dashboard/*` | modify | export localization, timeout, and abort hardening only |
| `superapp/apps/focal/client/src/features/calendars/{CalendarsPage,GoogleSyncPanel}.tsx` | modify | advanced Google two-way-sync UI, main-calendar Google section, invite reveal/copy |
| `superapp/apps/focal/client/src/components/GoogleCalendarSyncAdvanced.tsx` | add | old-focal advanced sync settings and actions, backed by existing/new integration API helpers |
| `superapp/apps/focal/client/src/features/aichat/*` | modify | recommended questions, global entry integration, voice clarification handoff, and timezone-aware cards |
| `superapp/apps/focal/client/src/components/{AIAssistantWidget,AIClarificationDialog,VoiceControl}.tsx` | add | old-focal global assistant widget, clarification create flow, and voice control |
| `superapp/apps/focal/client/src/hooks/useVoiceNavigation.ts` | add | route-level voice navigation behavior |
| `superapp/apps/focal/client/src/offline/*` | modify/add | extend existing mutation queue with read cache, richer indicator, optimistic offline mutations, rollback, and tests |
| `superapp/apps/focal/client/src/components/{InstallPrompt,UpdatePrompt,PullToRefresh}.tsx` | add | old-focal PWA prompts and refresh gesture |
| `superapp/apps/focal/client/public/{manifest.webmanifest,sw.js}` | modify | PWA install/update/read-cache behavior |
| `superapp/apps/focal/client/src/features/{meetings,legal}/**/*` | modify | cleanup-only gaps: meeting accept invalidation, legal theme/language toggles |
| `superapp/apps/focal/client/src/i18n/locales/{en,ru}.json` | modify | all new visible strings, aria labels, notices, errors, and prompts |
| `superapp/apps/focal/client/package.json` and `pnpm-lock.yaml` | modify only if needed | add `@dnd-kit/*` only if list drag/drop slices cannot stay simpler with existing pointer/@xyflow patterns |
| `superapp/apps/focal/server/app/models/tasks.py` | developer handoff | add task recurrence and multi-participant storage; unattended Codex does not generate the migration |
| `superapp/apps/focal/server/app/schemas/tasks.py` | developer handoff | expose task recurrence and multi-participant write/read contract |
| `superapp/apps/focal/server/app/services/tasks.py` and tests | developer handoff | persist and validate the new task fields |
| `superapp/apps/focal/server/app/models/calendar.py` | developer handoff | add event custom recurrence storage if old-focal custom recurrence is not representable by current fields |
| `superapp/apps/focal/server/app/schemas/calendar.py` | developer handoff | expose custom recurrence write/read contract |
| `superapp/apps/focal/server/app/services/calendar.py` and tests | developer handoff | persist/expand/edit custom recurrence consistently |
| `superapp/apps/focal/server/alembic/versions/<rev>_*.py` | developer handoff | autogenerated and reviewed migrations paired with the model changes |
| `superapp/apps/focal/server/app/{schemas,services,api}/integrations.py` and Google sync tests | modify only if existing endpoints are insufficient | support advanced sync settings/actions that the current backend does not yet expose |
| `superapp/apps/focal/client/src/api/openapi.d.ts` | regenerate after backend handoffs | keep client types aligned with FastAPI OpenAPI |

Old-focal files under `superapp/apps/old-focal/client` are read-only reference files and must not be
modified by this epic.

# Implementation slices

Every slice below is a separate build-review unit. Each slice must keep unrelated pages working and
run the relevant focused tests plus the full client command set before handoff.

1. **Shared calendar context and shell.**
   - Add `CalendarFilterContext` using existing `sharedCalendars.ts` API wrappers.
   - Preserve old-focal semantics: `main` localStorage sentinel, first-login auto-select for
     only-participant users, last-known selected calendar during refetch, main-calendar name/color
     normalization, `owner/full_access/editor/developer/viewer/requester` role matrix, `dataOwnerId`,
     `isViewingAsAssistant`, `canEdit`, `canViewOtherPages`, `canManageCalendars`, and `matchesFilter`.
   - Replace the static `CalendarSwitcher` with a selector over main, owned, and participating
     calendars.
   - Add sidebar limited-menu behavior for roles that cannot view other pages, plus a shell viewing
     banner/status.
   - Verify with provider and shell tests only; page mutations are still unchanged in this slice.

2. **Shared calendar data scope and read-only gates.**
   - Wire existing Tasks, Events, Calendar, Time Budgets, Goals, Tags, and Analytics queries/mutations
     to consume `dataOwnerId`, `currentCalendarId`, `matchesFilter`, and `canEdit` where backend
     contracts already support those parameters.
   - Block mutation handlers before calling APIs when `canEdit` is false; disabled controls must have
     accessible labels/tooltips and a visible read-only notice.
   - Keep each page's current features otherwise unchanged.
   - Verify with page tests that no mutation API is called in read-only mode and that assistant-mode
     views owner data instead of the viewer's data.

3. **Display timezone foundation.**
   - Port the old-focal client timezone provider/selector and pure conversion helpers, using the same
     DST expectations as the existing backend timezone tests.
   - Render Calendar, Events, and AI message cards through the selected display timezone while preserving
     per-event timezone storage.
   - Persist selector choice; invalid IANA values fall back to the browser/default display zone without
     corrupting event data.
   - Verify with unit DST tests and focused page/card render tests.

4. **Tasks backend handoff, then task UI parity.**
   - Backend handoff first: task recurrence and multi-participant/contact fields are model/schema/service
     changes with migration and regenerated OpenAPI.
   - Add `TaskDialog`, `TaskInfoDialog`, old-focal filter/search panel, schedule-to-calendar, tag manager,
     and drag/drop behavior after the backend contract exists.
   - Retain existing create/update/delete APIs and `taskSort.ts` ordering unless a test proves they cannot
     express old-focal behavior.
   - Verify dialog field persistence, filters, scheduling, tags, drag/drop order, and `canEdit` gates.

5. **Events editor parity.**
   - Add or adapt `EventDialog` for description, location, tags, participants, status, event timezone,
     recurrence end, and shared-calendar gating.
   - Backend handoff only for old-focal custom recurrence that cannot fit the existing `recurrence`,
     `recurrenceEndDate`, and recurrence exception fields.
   - Verify create/edit/read flows, participant persistence, timezone conversion, recurrence scope, and
     read-only mode.

6. **Calendar interaction parity.**
   - Split during design/build if needed, but keep sub-slices green:
     year view and mini-month dots; all-day band and variable row heights; scroll-to-work and prime time;
     drag-to-move and resize; task panel plus task/event conversion; undo stack; bookings/notes/filter
     layer; read-only `EventInfoDialog`; recurrence-end UI.
   - Consume the shared-calendar and timezone foundations instead of duplicating local state.
   - Verify pointer/keyboard interactions, recurrence scope, undo boundaries, and no mutation in read-only
     mode.

7. **Habits parity.**
   - Add edit habit, per-day notes, recommended presets, category/description/project link, explicit
     Yes/No/Skip/Erase, delete confirmation, and drag reorder.
   - Use the current habits backend fields; no schema handoff is expected unless implementation proves a
     field is absent.
   - Verify every entry state transition, note persistence, project/category fields, reorder persistence,
     delete confirmation, and read-only behavior if scoped by shared calendars.

8. **Goals graph parity.**
   - Add drag-to-reparent with move preview/affected counts, edge styling editor, budget/finance node
     fields, schedule-to-calendar from a node, full-description editor, multi-select/group move,
     drag-to-create-child, and complete undo/redo coverage.
   - Fix the known regression where an activity cannot be added to a product-less project.
   - Verify graph helper units, React Flow interaction tests, undo/redo history, schedule-to-calendar
     payloads, and the product-less activity regression.

9. **Analytics and dashboard export parity.**
   - Add Analytics PDF export, four per-section insight blocks, Spheres summary cards and totals footer,
     metric help popovers, and per-section collapse.
   - Harden Dashboard export localization, timeout, and abort handling without changing unrelated dashboard
     analytics.
   - Verify export calls, generated section data, collapse persistence, help popovers, localization, abort,
     and timeout failure states.

10. **Advanced Google sync parity.**
    - Replace the minimal `GoogleSyncPanel` with old-focal advanced sync controls: direction, modes
      all/work/custom, custom filters, inbound/outbound request settings, notifications, auto-sync interval,
      sync now, delete imported, main-calendar Google section, invite-code reveal/copy, and OAuth
      success/error toasts.
    - Reuse existing integration endpoints where possible; add backend endpoint/schema/service tests only
      for old-focal controls that the current backend cannot represent.
    - Verify settings load/save, OAuth redirects, sync actions, delete-imported action, copy/reveal, and
      every failure toast.

11. **Offline and PWA parity.**
    - Extend the existing IndexedDB mutation queue rather than replacing it.
    - Add read-cache storage, `OfflineSync`, rich offline indicator popover, install/update prompts,
      pull-to-refresh, and `offlineAwareMutation` with optimistic data plus rollback.
    - Keep replay order and the current 4xx drop / transient keep rule unless old-focal parity requires a
      narrower behavior and tests prove it.
    - Verify IndexedDB unavailable fallback, read-cache hit/miss, optimistic update/rollback, replay order,
      prompts, service-worker update, and pull-to-refresh.

12. **Global assistant and voice parity.**
    - Add global `AIAssistantWidget`, per-page Sparkles entry, recommended questions, `AIClarificationDialog`,
      voice clarification/TTS create flow, continuous voice mode, and voice navigation.
    - Keep chat orchestration in the existing Focal backend/service contracts; do not move Whisper/TTS/chat
      orchestration into a new shared service inside this slice.
    - Verify widget open/close/persistence, question suggestions, clarification state machine, create-event
      and create-task payloads, voice unsupported/denied/offline states, TTS fallback, and navigation.

13. **Cleanup parity sweep.**
    - Invalidate calendar events after meeting-request accept; add theme/language toggles on public legal
      pages; add type-to-confirm on calendar delete; add Tasks/Events orphan-count sidebar badges; close
      any residual audit gaps found during the earlier slices.
    - Do not use this slice for opportunistic refactors.
    - Verify each small residual gap with a focused test and rerun the full client checks.

# Tests

Each bullet names what the test proves. Slice implementations can add more focused tests, but should
not drop these behaviors without updating the plan/design first.

- **`CalendarFilterContext` role matrix:** proves main/owner/full_access/editor/developer/viewer/requester
  produce the old-focal `canEdit`, `canViewOtherPages`, `canManageCalendars`, `dataOwnerId`, and
  assistant-mode values.
- **`CalendarFilterContext` selection persistence:** proves `main` and shared-calendar ids round-trip
  through localStorage, stale refetches keep the last known calendar, and only-participant first entry
  auto-selects the first accessible calendar.
- **`CalendarFilterContext` `matchesFilter`:** proves `isWorkTime`, sphere, project, product,
  projectType, and custom filter rules include/exclude the same event shapes as old-focal.
- **`CalendarSwitcher` render/actions:** proves main, owned, and participating calendars render with
  colors/roles; choosing one updates context and invalidates affected queries.
- **`AppSidebar` limited menu:** proves roles without `canViewOtherPages` only see allowed nav items and
  that dashboard/admin-only logic still applies.
- **Read-only page gates:** one focused test per Tasks, Events, Calendar, Time Budgets, Goals, Tags, and
  Analytics proves a disabled/hidden mutation control never calls its API while the page still renders
  read data.
- **Assistant data-owner scope:** proves full-access/developer views request owner-scoped data, while
  editor/viewer/requester do not silently mix owner data into unrelated pages.
- **Timezone pure conversion:** proves UTC/Almaty, LA spring-forward, Berlin spring-forward, New York
  fall-back, invalid timezone fallback, empty time, and same-zone identity.
- **Timezone provider/selector:** proves selector persistence, invalid saved value fallback, and that
  Calendar/Events/AI card labels use display timezone without changing stored event timezone.
- **Task backend contract tests:** prove recurrence and multi-participant/contact fields validate,
  persist, serialize through OpenAPI, and do not regress existing task create/update/delete behavior.
- **Task dialog tests:** prove create/edit fields, recurrence, participants, tags, project/product/activity
  cascade, due date/time, schedule-to-calendar, and info-dialog actions produce the correct API payloads.
- **Task filters/search tests:** prove search, orphan/classified/active/completed, priority, tag, project,
  date, and drag/drop filters/order match old-focal and preserve `taskSort.ts` ordering where applicable.
- **Events editor tests:** prove description, location, tags, participants, status, timezone, recurrence
  end/custom recurrence, and read-only controls persist and render after refetch.
- **Calendar layout tests:** prove year view, all-day band, variable row heights, scroll-to-work, mini-month
  dots, prime-time, and timezone labels render for dense and empty days.
- **Calendar interaction tests:** prove drag move, resize, task/event conversion, recurrence-scope updates,
  bookings/notes visibility, undo/redo, keyboard-accessible actions, and read-only blocking.
- **Habits tests:** prove edit habit, presets, category/description/project link, note persistence, each
  Yes/No/Skip/Erase state, delete confirmation, and reorder persistence.
- **Goals graph tests:** prove drag-to-reparent, affected counts, edge styling, budget/finance fields,
  schedule-to-calendar, full description, multi-select/group move, drag-to-create-child, undo/redo, and
  product-less activity creation.
- **Analytics tests:** prove each insight block, Spheres summary/totals, metric popover, collapse state,
  and PDF export payload/layout.
- **Dashboard export tests:** prove localized export labels, abort signal handling, timeout error, and
  no stale successful export after cancellation.
- **Google sync tests:** prove connection status, calendar selection, settings save, custom filter controls,
  sync-now/import/export/delete-imported actions, OAuth success/error toasts, invite-code reveal/copy, and
  backend error display.
- **Offline storage tests:** prove queue insertion order, 4xx drop, transient keep, IndexedDB unavailable
  fallback, read-cache write/read/expiry, and cross-session replay.
- **Offline UI/mutation tests:** prove offline indicator popover, optimistic mutation, rollback on replay
  rejection, broad invalidation after replay, install/update prompts, and pull-to-refresh.
- **Assistant widget tests:** prove global mount excludes public legal pages if intended, opens from page
  buttons, saves/clears transcript, shows recommended questions, and does not duplicate `/aichat` state.
- **Voice/clarification tests:** prove unsupported browser, permission denied, offline, network failure,
  continuous listening stop, clarification state machine, TTS fallback, and voice navigation route changes.
- **Cleanup tests:** prove meeting accept invalidates calendar events, public legal theme/language toggles
  work unauthenticated, calendar delete requires type-to-confirm, and orphan badges count correctly.

Required verification per client slice:

```sh
cd superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```

Required verification for any backend handoff slice:

```sh
cd superapp/apps/focal/server && make verify && uv run alembic check
```

For slices with a new migration, the developer-owned handoff also runs:

```sh
cd superapp/apps/focal/server && uv run alembic upgrade head
```

# Error & rescue map

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| `sharedCalendar.accessibleLoadFailed` | `listAccessibleCalendars` rejects / `ApiError` | `CalendarFilterContext` query error branch | Main calendar remains usable; switcher shows localized load failure and retry |
| `sharedCalendar.participationLoadFailed` | `listMyParticipation` rejects / `ApiError` | `CalendarFilterContext` query error branch | Role-dependent pages default to no unsafe cross-owner permissions and show localized role-load warning |
| `sharedCalendar.staleSavedSelection` | saved id is absent from accessible calendars | provider reconciliation | Last known selected calendar is kept during refetch; if confirmed unavailable, user is moved to main calendar with notice |
| `sharedCalendar.readOnlyMutation` | no exception; `canEdit === false` | page action guard before mutation | Control is disabled or action is blocked; localized read-only notice; no API request |
| `sharedCalendar.filterMismatch` | no exception; event/task does not match selected calendar filter | `matchesFilter` consumer | Item is hidden from the selected calendar view, not deleted |
| `timezone.invalidZone` | invalid IANA value | timezone helper/provider sanitizer | Display falls back to default/browser timezone; event data is unchanged |
| `timezone.dstBoundaryRegression` | no runtime exception; wrong converted label would be a bug | timezone unit tests | Prevented by tests; user sees DST-correct wall time |
| `backend.taskFieldsMissing` | OpenAPI lacks task recurrence/participant fields | task slice preflight/typecheck | Task parity UI does not ship; slice blocks for developer migration handoff |
| `backend.eventCustomRecurrenceMissing` | OpenAPI cannot represent old-focal custom recurrence | events slice preflight/typecheck | Custom recurrence controls do not ship; slice blocks for developer migration handoff |
| `calendar.dragMutationFailed` | `updateEvent` rejects / `ApiError` | Calendar drag/resize mutation `onError` | Event snaps back; localized error; undo stack remains consistent |
| `calendar.undoUnavailable` | no stored inverse operation | undo command guard | Undo control disabled or shows localized "nothing to undo" message |
| `habit.entryMutationFailed` | habit entry mutation rejects / `ApiError` | Habit entry mutation `onError` | Cell returns to server state and shows localized error |
| `goals.reparentRejected` | graph update rejects / `ApiError` | Goals mutation `onError` | Node/edge positions roll back; affected-count preview closes with error |
| `analytics.exportFailed` | PDF/export promise rejects | export action catch | Localized export error; page remains interactive |
| `dashboard.exportAborted` | `AbortError` | dashboard export controller | Export stops without stale success toast |
| `dashboard.exportTimeout` | timeout error | dashboard export controller | Localized timeout error and retry action |
| `google.oauthError` | OAuth callback query carries error or status endpoint rejects | Google sync panel callback/status handling | Localized connection failure toast and reconnect action |
| `google.syncActionFailed` | sync/import/export/delete action rejects / `ApiError` | action mutation `onError` | Localized failure toast with current settings preserved |
| `offline.indexedDbUnavailable` | IndexedDB open/request rejects or `indexedDB` undefined | offline setup/storage guards | Offline cache/queue disabled; normal network errors surface; no data corruption |
| `offline.readCacheMiss` | cache has no valid entry | offline-aware query helper | Normal online fetch runs if available; offline user sees localized unavailable state |
| `offline.optimisticReplayRejected` | replay receives 4xx `ApiError` | queue replay and optimistic rollback path | Optimistic row is rolled back or refetched; indicator shows dropped/rejected state |
| `offline.replayTransientFailure` | network/5xx during replay | queue replay transient branch | Entry remains queued; user sees pending count; later replay retries in order |
| `pwa.updateAvailable` | service worker has waiting update | update prompt controller | User sees localized update prompt and can apply/reload |
| `voice.unsupportedOrDenied` | missing SpeechRecognition / permission error | `VoiceControl` state machine | Voice control shows localized unsupported/denied message; text input still works |
| `voice.ttsUnavailable` | `speechSynthesis` unavailable or speak fails | TTS guard | Assistant continues silently with localized non-blocking notice |
| `assistant.streamInterrupted` | SSE stream drops before done | existing chat SSE error path / widget adapter | Partial response is kept and marked interrupted |

# Review lenses (pre-answer before gate2-plan)

- **Scope / strategy** - This is the minimum viable strategy for a parity epic: dependencies first,
  then page slices, then independent systemic slices. It reuses existing API wrappers, tests, React Query,
  offline queue, `@xyflow/react`, and FastAPI contracts instead of replacing them. Auth, landing, and visual
  redesign stay out of scope.
- **Architecture** - Shared-calendar scope and timezone are central providers because many pages consume
  them. Page slices consume those providers and remain page-local where possible. Backend schema changes are
  isolated to their owning domain and paired with migration/OpenAPI handoffs. Offline extends the current
  queue rather than creating a parallel network stack.
- **Design** - User-facing states are planned for loading, empty, error, read-only, offline, optimistic,
  rollback, OAuth failure, voice unsupported, and export abort/timeout. Controls must remain localized in
  ru/en, keyboard-accessible, and responsive without introducing a second visual redesign.
- **DevEx** - Each build slice has a small owner surface and focused tests. No new dependency is planned
  except a possible `@dnd-kit/*` addition for list drag/drop if the design gate proves it is simpler than
  custom pointer code. Generated OpenAPI changes happen only after backend handoffs.

# Risks & migrations

- **Epic size:** implementing this as one PR would be unreviewable. Rollout is mandatory by the numbered
  slices above; each slice must leave the app green.
- **Shared-calendar data leakage:** `dataOwnerId` and `currentCalendarId` must not become client-only
  security. Backend endpoints must continue enforcing tenant/RBAC rules. Tests must include non-owned data.
- **Backend migrations:** task recurrence/multi-participant and event custom recurrence are schema changes.
  Per `superapp/CLAUDE.md`, unattended Codex edits models only; developer or interactive Claude Code
  generates and reviews Alembic migrations in the same change set. Rollback is standard migration rollback
  plus hiding dependent client controls until OpenAPI matches.
- **Service worker/cache:** stale assets or stale read-cache data can persist across sessions. Use versioned
  caches, update prompts, and tests for cache invalidation; rollback by shipping a SW version that clears the

exec
/bin/zsh -lc "sed -n '1,420p' /Users/allosta/Desktop/allosta/.ai/design/focal-parity-design.md" in /Users/allosta/Desktop/allosta
 succeeded in 0ms:
# Design summary

This is the **epic-level** architecture for reaching old-focal functional parity. It fixes the two
decisions everything hinges on — **(1)** a single shared `CalendarFilterContext` that owns
selected-calendar + role + `canEdit`/`dataOwnerId` and a uniform read-only gating pattern that every
page consumes, and **(2)** a single `TimezoneProvider` + pure DST helpers that Calendar/Events/AI
cards render through. Both are ported in behavior from old-focal but re-expressed on the new stack
(React 19, typed `api/*`, React Query, Wouter, Tailwind 4) over the **existing** FastAPI endpoints.
Everything else (offline/PWA, assistant/voice, and each per-area page) consumes these foundations;
per-page component-level design is **deferred to each slice's own gate-3** — this doc sets the
contracts they must honor, not their internal layout.

Two hard boundaries set here and inherited by every slice:
- **Client scoping is not security.** `dataOwnerId`/`currentCalendarId`/`canEdit` shape what the UI
  *requests and shows*; the **backend RBAC + RLS remain the enforcement**. No mutation is "safe"
  because the client hid a button.
- **No faked backend fields.** Where parity needs a column the new schema lacks (task recurrence +
  multi-participant; event custom recurrence), the slice **blocks on a developer-owned model +
  Alembic migration**; the client wires it only after OpenAPI regenerates.

Traces to: `.ai/think/focal-parity.md` (Recommendation, Phases A/B/C) and
`.ai/plans/focal-parity-plan.md` (slices 1–13, files table, error map).

# Architecture

```
App (AuthGate → AppShell)
 ├─ CalendarFilterProvider ── useCalendarFilter() ──────────────┐  (slice 1)
 │     state: currentCalendarId, role, canEdit, dataOwnerId,    │
 │            isViewingAsAssistant, matchesFilter               │
 │     source: api/sharedCalendars.ts (accessible + my-         │
 │             participation) via React Query                   │
 ├─ TimezoneProvider ──────── useTimezone()/useTimeFormat() ────┤  (slice 3)
 │     state: displayTimezone (localStorage); lib/timezone.ts   │
 │     pure DST helpers (port of old-focal shared/timezone.ts)  │
 ├─ AppShell                                                    │
 │   ├─ AppSidebar  ── limited-menu via canViewOtherPages,      │
 │   │                 viewing banner, sync/orphan badges       │
 │   ├─ CalendarSwitcher ── selects main/owned/participating    │
 │   ├─ PageToolbar ── (slice 12) opens AIAssistantWidget       │
 │   └─ <page> ── consumes canEdit + dataOwnerId + displayTz ───┘
 └─ offline/ (slice 11): queue + read-cache + offlineAwareMutation
```

- **Ownership.** `CalendarFilterContext` lives in `features/calendars/` (it owns calendar identity);
  `TimezoneProvider`/helpers live in `hooks/` + `lib/`. Both mount in `App.tsx` **inside the auth
  gate**, wrapping the authed tree, so every page and the shell can read them. Public `/privacy`,
  `/terms` stay outside both providers.
- **Coupling is one-directional.** Pages depend on the two contexts; the contexts depend only on
  `api/*` + auth. No page imports another page. The offline layer wraps `api/queryClient.ts` and is
  invisible to pages except through the existing mutation hooks.
- **Reuse, don't rebuild.** New `api/sharedCalendars.ts` and the `src/offline/{queue,storage,setup}`
  modules already exist; this epic extends them. `@xyflow/react` (goals), Recharts (analytics),
  and the existing chat SSE transport are reused, not replaced.

# Data model

No client-persistent **database** tables. Client persistent state is browser storage; the only
**schema** changes are the two backend handoffs.

| entity | change | notes |
|--------|--------|-------|
| localStorage `focal_current_calendar_id` | reuse old-focal key | `"main"` sentinel = explicit main-calendar choice; absent = first entry. Auto-select the first accessible calendar **only when `isOnlyParticipant`** (user owns no calendars); an ordinary user with no saved choice defaults to **main**, never an arbitrary shared calendar |
| localStorage `focal:calendars:main-name` / `focal:calendars:main-color` | reuse | the **same keys the new calendars page already writes** (build corrected the earlier old-focal `focal_main_calendar_*` assumption); the calendars page dispatches `mainCalendarUpdated` so the switcher live-syncs. No legacy-name normalization — the new calendars page stores raw names with a localized default, so old-focal's `normalizeMainCalendarName` is intentionally not ported |
| localStorage display-timezone key | add | selected IANA zone; invalid/missing → browser default, never corrupts event data |
| IndexedDB offline store | extend | existing mutation queue + **new** read-cache namespace (events/tasks/projects/goals), versioned for invalidation |
| `focal.tasks` (server) | **handoff** | add recurrence + multi-participant (`contact_ids`/`other_participants`) columns; SQLAlchemy model + autogenerated Alembic migration by developer |
| `focal.events`/calendar (server) | **handoff** | add custom-recurrence (interval + unit) representation if not expressible by current `recurrence`/`recurrenceEndDate` fields |

# Interfaces & contracts

**`useCalendarFilter(): CalendarFilterContextType`** — ported 1:1 in semantics from old-focal
`client/src/context/CalendarFilterContext.tsx`:
- `currentCalendarId: string | null` (`null` = main), `setCurrentCalendarId(id)`, `currentCalendar`,
  `calendars`, `participatingCalendars`, `isOnlyParticipant`, `mainCalendarName/Color`, `isMainCalendar`, `isLoading`.
- `currentCalendarRole: 'owner'|'full_access'|'editor'|'developer'|'viewer'|'requester'|null`.
- **Main-calendar / owned-calendar override (first):** when `currentCalendarId === null` (main, role
  `null`) **or** the selected calendar is one the user owns (`currentCalendar.userId === user.id`),
  rights are full — `canEdit = canViewOtherPages = canManageCalendars = true`,
  `dataOwnerId = calendarOwnerId =` the signed-in user, `isViewingAsAssistant = false`. This override
  is evaluated *before* the role-based rules below (matches old-focal's
  `!stableCurrentCalendar` / `userId === current user` branches).
- Derived rights for a **shared** (non-owned) calendar (exact old-focal rules):
  `canEdit = role ∈ {owner, full_access, editor}`;
  `canViewOtherPages = role ∈ {owner, full_access, developer}`; `canManageCalendars = role === owner`.
  An unknown / not-yet-loaded participation defaults to **no write, no other-pages**, with
  `dataOwnerId =` the calendar owner (show owner data; never mix in the viewer's own data).
- `dataOwnerId` = owner id when `isViewingAsAssistant` (`role ∈ {full_access, developer}`), else the
  signed-in user; plus `calendarOwnerId` and `isViewingAsAssistant`.
- `matchesFilter(event) => boolean` over `filterType ∈ {isWorkTime, sphere, project, product, projectType, custom}`.
- Backed by the new typed `api/sharedCalendars.ts` (accessible + my-participation), not `fetchWithAuth`.

**Read-only gating pattern (every mutating page consumes):**
1. Render: disable/hide mutation controls when `!canEdit`, each with an accessible label/tooltip + a
   visible read-only notice. 2. Guard: every mutation handler early-returns (with localized notice)
   when `!canEdit` **before** calling the API. 3. Scope: pass `dataOwnerId`/`currentCalendarId` into
   queries that already accept them; `matchesFilter` hides non-matching items (hide, never delete).

**`useTimezone()` / `useTimeFormat()`** + `lib/timezone.ts` pure helpers — DST-aware wall-time
conversion (Intl-based port of old-focal `shared/timezone.ts`), matching the existing backend
`test_timezone.py` DST fixtures. Display zone is presentational; stored per-event `timezone` is never
mutated by display.

**Backend handoff contracts** (developer-owned; client codes against regenerated `openapi.d.ts`):
- Task: `recurrence` (none/daily/weekly/monthly/yearly + end) and multi-participant
  (`contactIds: string[]`, `otherParticipants: string`).
- Event: `customRecurrence: { interval: number; unit: 'day'|'week'|'month'|'year' }` — **only if** the
  existing `recurrence` / `recurrenceEndDate` / recurrence-exception fields cannot already represent
  old-focal's custom interval; confirm against the current schema at the events slice's gate before
  treating it as a handoff (it may be UI-only).

**`offlineAwareMutation`** — wraps a React Query mutation: optimistic cache patch + reversible
rollback, enqueue on offline, ordered replay on reconnect, broad invalidate after replay; preserves
the existing 4xx-drop / transient-keep rule.

# Flow (happy + unhappy paths)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| happy — select calendar | user picks calendar in switcher | `CalendarFilterProvider` | context updates, queries refetch by changed key, pages re-scope |
| happy — read-only view | viewer/requester opens a shared calendar | each page via `canEdit` | data renders; mutation controls disabled with notice |
| accessible/participation load fails | `api/sharedCalendars` rejects | provider query error branch | main calendar stays usable; switcher shows localized retry; roles default to **no** unsafe cross-owner write |
| stale saved selection | saved id missing from accessible set during refetch | provider `stableCurrentCalendar` (last-known ref) | keep last-known calendar; only fall to main if confirmed gone |
| read-only mutation attempt | `canEdit === false` | page handler guard (pre-API) | no request sent; localized read-only notice |
| filter mismatch | event/task fails `matchesFilter` | consumer | item hidden from the selected view (not deleted) |
| invalid display timezone | bad IANA value in storage | tz provider sanitizer | fall back to browser default; event data unchanged |
| backend field missing | OpenAPI lacks task recurrence / event custom-recurrence | slice preflight/typecheck | dependent UI does not ship; slice blocks for migration handoff |
| offline replay rejected | 4xx during queued replay | offline rollback path | optimistic patch rolled back/refetched; indicator shows dropped state |
| offline replay transient | network/5xx during replay | queue transient branch | entry stays queued in order; pending count shown; retried later |

# Alternatives rejected

- **Per-page local role/permission state** instead of a shared context — duplication and drift
  across 7 pages; the same `canEdit` logic re-implemented each time. (Plan option B.) Rejected.
- **Client-side permission enforcement as the boundary** — a hidden button is not security. Backend
  RBAC + RLS stay authoritative; the client only scopes/affords. Rejected as a *security* model.
- **Epoch/offset timezone math** — old-focal deliberately does Intl wall-time conversion to stay
  DST-correct; epoch math reintroduces the spring-forward/fall-back bugs. Rejected.
- **Replacing the offline queue** with a new network stack — the existing `src/offline/*` queue is
  sound; we extend it (read-cache + optimistic) rather than fork it. Rejected.
- **One mega-PR** for the whole epic — unreviewable; build proceeds strictly per numbered slice,
  each leaving `lint/typecheck/test:run/build` green. Rejected.

# Test strategy

- **Unit (pure):** timezone DST cases (Almaty no-DST, LA spring-forward, NY fall-back, invalid zone
  fallback, empty/same-zone) aligned to backend fixtures; `matchesFilter` per `filterType`; the role
  → rights matrix; `taskSort` preserved.
- **Component:** `CalendarSwitcher` selection + query invalidation; `AppSidebar` limited menu for
  `!canViewOtherPages`; one **read-only gate** test per Tasks/Events/Calendar/TimeBudgets/Goals/
  Tags/Analytics proving a disabled control never calls its API while read data still renders;
  assistant-mode proving owner-scoped fetch.
- **Per-slice:** each page slice adds focused tests for its restored behavior (dialogs, filters,
  drag/resize, undo, export, sync settings, offline, voice) per the plan's test list.
- **Backend handoffs:** model/schema/service tests prove the new task/event fields validate,
  persist, and serialize through OpenAPI without regressing existing CRUD; `alembic check` clean.
- **"Verified" per slice:** `cd superapp/apps/focal/client && pnpm lint && pnpm typecheck &&
  pnpm test:run && pnpm build` green; backend handoff slices also `cd …/server && make verify &&
  uv run alembic check`.

# Security & release notes

- **Authorization stays server-side.** `dataOwnerId`/`currentCalendarId` are request *scoping*;
  every shared-calendar test must include a non-owned-data path proving the backend (RBAC + RLS),
  not the client, blocks unauthorized reads/writes. Client guards exist for UX, not enforcement.
- **No secrets in the client / shipped text.** No tokens or PII added to bundles, handoffs, or PR
  bodies.
- **PWA cache safety.** Read-cache + service worker are **versioned**; an update prompt + versioned
  caches prevent stale assets or stale per-user data leaking across sessions; rollback = ship a SW
  version that clears the parity caches.
- **Google two-way sync** (slice 10) can create/delete external events — destructive actions need
  explicit confirmation + visible settings summaries + tests before ship.
- **Migrations** (handoffs) ship with their model change in the same set; rollback = standard
  migration down + keep dependent client controls hidden until OpenAPI matches.
- **Release shape.** Independently shippable slices, foundations (1→3) first; each slice is its own
  PR per `apps/focal/CLAUDE.md` branching (`feat/focal-<slug>` → `feature/focal-migration`).

exec
/bin/zsh -lc "sed -n '1,420p' /Users/allosta/Desktop/allosta/.ai/design/focal-parity-data-scope-design.md" in /Users/allosta/Desktop/allosta
 succeeded in 0ms:
# Design summary

Slice 2 of the focal-parity epic — **shared-calendar read-only gating + assistant-mode data
scoping**. It splits into three independently-shippable parts; the decision that everything hinges
on is **the security model**: serving calendar-owner O's data to caller C is authorized **only** by
an app-layer RBAC check (RLS faithfully serves whatever owner id the app picks), so a single
**RBAC-gated `resolve_data_owner` dependency** is the load-bearing boundary.

- **2a — client read-only gating (no backend dep, ships first).** Each mutating page consumes
  `canEdit` from the slice-1 `CalendarFilterContext`: disable every create/edit/delete/toggle
  control when `!canEdit`, early-return mutation handlers with a visible read-only notice. Pages:
  Tasks, Events, Calendar, Time Budgets, Goals, Tags (Analytics has no mutations).
- **2b — backend assistant-mode owner scoping (security-critical).** A shared, RBAC-gated
  `resolve_data_owner` FastAPI dependency replaces `get_current_user_id` on domain read/write
  endpoints (behind an optional `calendarId` query param). **It also closes a live IDOR**: the
  existing `app/ai/chat_support.py:148` `resolve_data_owner` trusts any UUID with **no RBAC** —
  `/api/ai/chat` currently lets any authenticated caller read any user's data by passing their
  `userId`. This work makes that path RBAC-gated.
- **2c — client wiring.** Thread `currentCalendarId` into the typed `api/*` modules' query params +
  React Query keys so pages load/write the owner's data in assistant mode; shared-calendar event
  reads call `GET /api/shared-calendars/{id}/events` (server-side filter). `matchesFilter` stays a
  client-side UX narrowing for the user's **own** filter-calendars only — never the shared-calendar
  security boundary (which is enforced server-side).

Traces to: `.ai/think/focal-parity.md`, `.ai/plans/focal-parity-plan.md` (slice 2 "Shared calendar
data scope and read-only gates"), and `.ai/design/focal-parity-design.md` (which deferred scoping to
"where backend supports it" — it does not yet, so 2b designs that support).

# Architecture

```
Client (2a/2c)                         Backend (2b)
─────────────                          ───────────
useCalendarFilter() → canEdit          resolve_data_owner(calendarId?, caller, *, domain, action)
  → disable controls, guard handlers     ├─ no calendarId → caller.id  (own data, today's behavior)
  → read-only notice                     └─ calendarId → load SharedCalendar → owner = calendar.user_id
useCalendarFilter() → currentCalendarId       check caller's accepted role vs the (domain, action) gate:
  → api/*.ts pass calendarId on              calendar    READ viewer+            WRITE {owner,full_access,editor}
    read query + write body                  other-pages READ {owner,FA,developer} WRITE {owner,full_access}
  → query keys include calendarId            else → PermissionDeniedError (403)
  → matchesFilter() on event lists           return owner id  → service(owner_id, …) unchanged
```

- **Backend injection point:** the first arg to every service method (already a plain `user_id`
  param). For **other-pages** domains, swapping `get_current_user_id` → `resolve_data_owner` is a
  **zero service-layer change** (services take `user_id` as a parameter, and the whole owner dataset
  is what a `canViewOtherPages` role may see). The **calendar** domain is NOT a bare swap: a
  shared-calendar event read must apply the calendar's saved **filter server-side**, so it routes
  through the existing `SharedCalendarsService.list_events` (`shared_calendars.py:204` — RBAC-checks
  viewer+, fetches the owner's events, **applies the calendar filter**) rather than raw
  `CalendarService.list_events(owner)` which returns ALL owner events. **All** calendar event writes —
  create (`POST /api/events`, `calendar.py:32`) **and** by-id (`PATCH`/`DELETE /api/events/{id}`,
  `calendar.py:55`) — must verify the event matches the selected calendar's filtered scope + the
  caller's calendar write role, not merely match owner id (else an editor could create/move owner
  events outside the shared calendar's filter).
- **Reuse, don't reinvent:** build `resolve_data_owner` from existing blocks —
  `SharedCalendarsService._resolve_access` (`shared_calendars.py:220`, owner lookup + accepted-role
  fetch + rank gate for writes), `rbac.get_resource_role` (`rbac.py:27`), the `can_view_other_pages`
  set (`shared_calendars.py:201`) for the read gate, and `PermissionDeniedError` (`errors.py:40`).
- **One dependency, applied uniformly:** ~all `app/api/*` routers share the
  `get_current_user_id → user_id → WHERE user_id ==` shape, so the dependency retrofits them
  endpoint-by-endpoint without per-domain bespoke logic.
- **Client (2a) is page-local:** each page imports `useCalendarFilter`, gates its own controls; no
  cross-page coupling. (2c adds `calendarId` to the `api/*` modules the pages already call.)

# Data model

| entity | change | notes |
|--------|--------|-------|
| (none — no schema change) | — | Owner-only domain tables stay owner-keyed. **The cross-tenant boundary is the app-layer filter, not RLS:** the domain-router service sessions run under the owner DB role and **bypass RLS** (the `app.user_id` GUC is pinned only on the auth heal-session, never on the domain service sessions — `db.py:81`, `auth.py:111`). Assistant mode therefore changes the effective `user_id` passed into the service (the `WHERE user_id == owner` filter), chosen by `resolve_data_owner`. **No schema change, no migration.** |
| optional RLS hardening (deferred) | additive `sharing_select` policies on domain tables via `SECURITY DEFINER` participation helpers, mirroring the calendar tables | defense-in-depth only; the app-RBAC gate is sufficient and is the load-bearing boundary. A separate hand-written migration if ever wanted. **Out of scope for 2b.** |

# Interfaces & contracts

**Backend — `resolve_data_owner` (new shared dependency, `app/deps.py` or `app/auth.py`):**
- `resolve_data_owner(calendar_id, caller, session, *, domain, action) -> owner_id`. Returns `caller`
  when `calendar_id` is None (own data, backward-compatible). Else resolves the calendar
  (`owner = calendar.user_id`) and checks the caller's **accepted** participant role against the gate
  for `(domain, action)`. **The gates are NOT uniform — they split by domain**, tracking slice-1's two
  permission dimensions (`canEdit` = event editing; `canViewOtherPages` = access to non-calendar pages):

  | domain | READ roles | WRITE roles |
  |---|---|---|
  | **calendar** (events, calendar_init, bookings, meeting_requests) | any accepted participant (viewer+) — the shared calendar's purpose; matches the existing `list_events` `_resolve_access(.., "viewer")` | `{owner, full_access, editor}` (= `canEdit`) |
  | **other-pages** (tasks, projects, activities, activity_instances, mindmap/goals, spheres, time_budgets, tags, habits, habit_entries, stats, analytics) | `{owner, full_access, developer}` (= `canViewOtherPages`) | `{owner, full_access}` (= `canViewOtherPages` ∩ write) |

  Raises `PermissionDeniedError` (403) when the role isn't in the gate. **Crux — the write gate is NOT
  uniform:** an `editor` (`canEdit=true`, `canViewOtherPages=false`) may write the owner's calendar
  events but is **denied** reads AND writes on the owner's non-calendar data (it cannot even view those
  pages); a `developer` reads non-calendar data but **never writes** it. Checks are **set-membership,
  not rank** (`developer`/`viewer`/`requester` share rank 10 yet differ across these sets).
- **AI-chat fix (read/write split — the AI route does BOTH):** `/api/ai/chat` resolves the data-owner
  scope once (`ai_chat.py:204`) and then dispatches **both** read intents (query/analytics) **and**
  write intents — the create/update/delete entity handlers write owner-scoped rows
  (`app/ai/entity_handlers.py` create paths ~997/1320/1415). So one gate is not enough: apply the
  **other-pages read gate** (`owner/full_access/developer` — the AI surfaces the owner's
  tasks/goals/activities) to authorize the owner-scoped read, and before any create/update/delete
  entity handler mutates owner data apply the **write gate of that entity's domain** (calendar event
  → `{owner, full_access, editor}`; non-calendar entity like task/goal → `{owner, full_access}`) — a
  `developer` (read-only) is **forbidden to write** (403), and an `editor` is denied **non-calendar**
  entity writes (it cannot view those pages). Replace the UUID-only
  `app/ai/chat_support.py:resolve_data_owner` (the IDOR) with the read-gated resolver, and add the
  write-gate check at the create-intent dispatch in `ai_chat.py` before owner-scoped mutation.

**Per-endpoint contract:** read endpoints gain an optional `calendarId` query param + their **domain's
read gate**; write endpoints accept `calendarId` (query or body) + their **domain's write gate**.
Absent `calendarId` → unchanged own-data behavior (backward compatible).

**Scoped endpoints — a closed partition by domain (so no route leaks AND the right gate applies):**
A route is *scoped* iff it reads/writes per-user domain data via `Depends(get_current_user_id)`.
Slice 2b converts **every** such route to `resolve_data_owner` with its **domain's** gate (the table
above): the read gate on every `GET`, the write gate on every mutation (`POST`/`PATCH`/`PUT`/`DELETE`,
incl. the non-CRUD `POST /api/activity-instances/sync` and `POST /api/mindmap-nodes/batch`, and the
full `time_budgets.py` write surface). Every `get_current_user_id`-injecting router is classified into
**exactly one** of three buckets:
- **calendar-domain** (read = viewer+, write = `canEdit`) — `calendar` (events), `bookings`,
  `meeting_requests`. **Scope invariant — covers EVERY route (list / by-id / aggregate / create /
  write), no per-path exceptions:** in shared mode every calendar-domain **READ** returns only
  objects within the selected calendar's **filtered scope** — list reads route through the filtered
  shared path (`GET /api/shared-calendars/{id}/events`), and a **by-id** read of an object outside
  the filter → **404** (not visible in this calendar), never raw `CalendarService.get_event(owner,
  id)` (`calendar.py:139`); every calendar-domain **WRITE** — create (`POST /api/events`), by-id
  (`PATCH`/`DELETE /api/events/{id}`), bookings, and accept-request — validates the object is within
  the filtered scope + the caller's calendar write role, else **403**. So neither a viewer (by-id
  read) nor an editor (create/move) can reach owner objects outside the shared calendar's filter.
- **mixed aggregate** — `calendar_init`: returns events/bookings (**calendar** gate, filtered) **and**
  tasks/projects (**other-pages** gate). In shared mode each payload part is gated by its own domain;
  the tasks/projects keys are returned as **empty arrays** (the response schema requires the keys —
  they are not omitted) unless the caller satisfies the other-pages read gate (`canViewOtherPages`),
  so an editor/viewer/requester never receives non-calendar data through it.
- **other-pages-domain** (read = `canViewOtherPages`, write = `{owner, full_access}`): `tasks`,
  `projects`, `activities`, `activity_instances`, `mindmap` (collection + standalone nodes/edges),
  `goals`, `spheres`, `time_budgets`, `tags`, `habits`, `habit_entries`, `stats`, `analytics`. (No
  `/api/products` route — products are modeled on `projects`/`activities`.)
- **ai-domain** — `ai`, `ai_chat`: per-intent — owner-scoped reads via the **other-pages** read gate
  (the AI surfaces the owner's tasks/goals/activities); entity writes via **that entity's domain**
  write gate (calendar event → calendar write; task/goal → other-pages write). The route threads the
  selected `calendarId` into the entity context so **event-backed** intents honor the calendar filter
  server-side: event reads use the filtered shared-calendar path (not raw
  `CalendarService.list_events` at `entity_handlers.py:411`), and event writes validate against the
  calendar's filtered scope. A **mixed** AI answer that combines events + tasks includes the owner's
  tasks **only if** the caller satisfies the other-pages read gate (`canViewOtherPages`) — a
  viewer/editor gets the filtered events but **not** the owner's tasks. This bucket replaces the
  UUID-only `resolve_data_owner` (the IDOR fix). Classified explicitly so the guard passes.

  > **Slice-2 scope refinement (2026-06-26):** only the **IDOR fix** ships in slice 2 — the AI's
  > `resolve_data_owner` is replaced by the RBAC-gated `resolve_ai_data_owner` + the create-intent
  > write gate, closing the live cross-user hole. The remaining AI shared-calendar **assistant mode**
  > — deriving the data owner from the selected `calendarId`, the event-vs-other-pages **domain-split
  > gating** (filtered events for a viewer, owner tasks only for `canViewOtherPages`), filtered AI
  > event reads, and `calendarId`-scoped AI event **create** — is **deferred to slice 12 (AI
  > assistant + voice)**, where the AI surface is built out in full. It requires splitting the AI's
  > single data-owner into per-domain owners (events vs other-pages) through the entity context, a
  > redesign that belongs with that slice rather than the data-scope foundations here. Slice 2 leaves
  > the AI strictly own-data (plus the IDOR gate); it does **not** thread `calendarId` into the chat
  > path, so there is no partially-wired assistant surface to mis-scope.
- **self-only** (stays on `get_current_user_id`, never owner-scoped): `me`, `settings`,
  `integrations`, `push`, `agent_tokens`, `user_account`, `backup`, `dashboard`, `ical` (the caller's
  own account/admin/export surfaces) and `shared_calendars` (already RBAC-gated).

**Completeness is a closed-partition build check:** grep `Depends(get_current_user_id)` across
`app/api/`, then assert (a) every calendar/other-pages route routes through `resolve_data_owner` with
the **correct domain gate**, (b) self-only routes intentionally remain, and **(c) every matched route
is classified into one bucket** — an **unclassified** `get_current_user_id` route fails the build,
forcing a deliberate calendar/other-pages/self-only decision for any route added later. A scoped
route still on `get_current_user_id`, on the wrong domain gate, or unclassified, is a build-blocking
leak.

**Client — `api/*.ts`:** read functions accept an optional `calendarId` appended as a query param; mutation functions pass it where the endpoint supports it; React Query keys include `calendarId` so a calendar switch refetches. Pages read `currentCalendarId` from `useCalendarFilter`.

# Flow (happy + unhappy paths)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| happy — own data | no `calendarId` | `resolve_data_owner` | caller's id → unchanged behavior |
| happy — assistant read | full_access/developer views owner's calendar | `resolve_data_owner` read gate | returns owner id → service serves owner's rows |
| happy — assistant write | owner/full_access/editor | write gate | owner id → write applies as owner |
| read-only control | `!canEdit` (viewer/developer/requester) | page (2a) | control disabled + read-only notice; handler early-returns |
| unauthorized scope | caller has no / insufficient role on `calendarId` | `resolve_data_owner` | `PermissionDeniedError` → 403 |
| IDOR attempt | caller passes a victim `userId`/`calendarId` they don't participate in | RBAC gate | 403 (was: silently served — the bug being fixed) |
| missing calendar | bad `calendarId` | `_resolve_access` | 404 |
| stale/revoked role | role removed after selection | RBAC gate (per request) | next request 403; client fails closed (slice 1) |

# Alternatives rejected

- **Per-endpoint ad-hoc owner checks** — duplicates the RBAC across ~15 endpoints, drift-prone and
  a security risk. Rejected for one shared dependency.
- **RLS-enforced cross-domain sharing policies now** (additive `sharing_select` on every domain
  table) — real defense-in-depth, but adds a hand-written migration per table and isn't required
  for correctness (the app-RBAC gate is the boundary). Deferred, not in 2b.
- **Trust a client-supplied owner/userId (the current AI-chat behavior)** — that *is* the IDOR.
  Rejected; replaced by the RBAC gate.
- **Faking `calendarId`/owner params client-side without backend support** — explicitly forbidden by
  the epic (no faked params). 2b adds the real backend support first.

# Test strategy

- **Backend authz (the load-bearing tests), split by domain:**
  - *other-pages* (tasks/goals/time-budgets/tags/…): READ by owner/full_access/developer → 200; READ
    **denied (403)** for editor/viewer/requester/non-participant; WRITE by owner/full_access → 200;
    WRITE **denied** for developer/editor/viewer/requester — incl. the non-CRUD sync/batch routes and
    the full Time Budgets write surface.
  - *calendar* (events/bookings/meeting_requests): READ by **any accepted participant (viewer+)** →
    200 and returns **only objects matching the calendar's filter**; a **by-id** read of an object
    outside the filter → **404**; denied for non-participant. WRITE — event **create AND** by-id
    edit/delete (and accept-request) — by owner/full_access/editor → 200 **only when the object
    matches the calendar's filtered scope**; a create/move/edit that would fall outside the filter →
    403; all writes **denied** for developer/viewer/requester.
  - *calendar_init mixed aggregate*: a viewer/editor (no `canViewOtherPages`) gets filtered events but
    **empty** `tasks`/`projects` arrays; a full_access/developer gets the owner's tasks/projects too.
  - *AI event intents*: an owner-scoped AI event read returns only filter-matching events (uses the
    filtered shared path, not raw `list_events`); an AI event write outside the filter → 403.
  - no `calendarId` → own data unchanged (backward compat).
  - **IDOR regression:** a non-participant passing a victim's `userId`/`calendarId` to `/api/ai/chat`
    and to scoped domain endpoints gets 403; an `editor` writing a **non-calendar** entity via
    `/api/ai/chat` is denied; a `developer` writing anything via `/api/ai/chat` is denied.
  - **closed-partition guard:** a test asserts every `Depends(get_current_user_id)` route in `app/api/`
    is classified (calendar / other-pages / self-only) — no route left unclassified.
  - Real-DB transaction-rollback fixtures (per repo test rules).
- **Client 2a:** per-page — a `!canEdit` render disables every mutating control and the handler does
  not call its API (mirrors slice-1's read-only gate tests).
- **Client 2c:** the api modules append `calendarId`; query keys include it; `matchesFilter` narrows
  the Calendar/Events list to the selected calendar.
- **Verified:** `cd apps/focal/server && make verify && uv run alembic check` (no migration, so
  `alembic check` stays clean) + `cd apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.

# Security & release notes

- **The RBAC gate is the entire cross-user boundary.** The domain service sessions **bypass RLS**
  (the GUC is never pinned on them), so the app-layer `WHERE user_id == effective_owner` filter is
  the only tenant boundary — and `resolve_data_owner` chooses `effective_owner`. So the resolver
  must be correct: **accepted** participation only, the right role **sets** (set-membership, **not**
  rank — `developer` vs `viewer` share rank 10), and distinct read vs write thresholds (a
  `developer` reads but must not write). Every scoped endpoint (incl. aggregate routes like
  `/api/calendar/init`, `/api/stats/*`, `/api/analytics/*`) MUST route through it; a missed endpoint
  is a leak. (RLS stays a dormant backstop on these sessions; activating it on owner data is the
  deferred defense-in-depth hardening above, not required for correctness.)
- **Two gate domains close the `editor` over-grant.** `editor` has `canEdit` but **not**
  `canViewOtherPages`, so it is permitted only on the **calendar** write gate (event edits) and is
  **denied** the owner's non-calendar data entirely (no read, no write); `developer` gets non-calendar
  **reads** but no writes; `viewer`/`requester` keep read access to the shared calendar's events (the
  existing viewer+ path) and nothing else. A single uniform write gate would have let an `editor`
  mutate the owner's hidden tasks/goals/time-budgets — the domain split prevents that.
- **Fixes a live IDOR** (`app/ai/chat_support.py:148` + `ai_chat.py`/`ai.py`): currently any
  authenticated user can read another user's activities/events via `/api/ai/chat` by supplying their
  UUID. 2b closes it. This is the highest-priority item and could be hotfixed ahead of the rest.
- **Backward compatible / no migration:** absent `calendarId`, every endpoint behaves exactly as
  today; rollback = revert the code (no schema state to undo). Backend model edits are limited to
  api/deps/auth + service call-sites; **no SQLAlchemy model or Alembic change** — so this stays
  inside interactive-Claude-Code's lane (not an unattended-agent migration).
- **Developer-owned review:** 2b changes the auth/RBAC surface; it ships with the authz tests above
  and a security pass before merge.

exec
/bin/zsh -lc "sed -n '1,260p' /Users/allosta/Desktop/allosta/.ai/checklists/scoring-rubric.md" in /Users/allosta/Desktop/allosta
 succeeded in 0ms:
# Review Scoring Rubric

Every review — by Opus or by GPT (Codex), in either direction — ends with a **Score out of 10**
and a **Status**. This file defines both, and applies identically regardless of which model reviews.

## Bands

| Score      | Status   | Meaning                                            |
|------------|----------|----------------------------------------------------|
| 9.0–10.0   | APPROVED | Good to go.                                        |
| 8.0–8.9    | BLOCKED  | Close. Mostly good; fix issues / strengthen tests. |
| 6.0–7.9    | BLOCKED  | Meaningful correctness, design, or test gaps.      |
| 0.0–5.9    | BLOCKED  | Failed review. Likely needs significant rework.    |

## Score meaning

- **10** — Excellent. Correct, well-tested, low risk, clean implementation.
- **9.0–9.9** — Approved. Minor non-blocking issues only.
- **8.0–8.9** — Not approved yet. Mostly good, but needs fixes or stronger tests.
- **6.0–7.9** — Blocked. Meaningful correctness, design, or test gaps.
- **Below 6** — Rejected. Significant rework likely needed.

## Hard caps (override the band)

- Any **must-fix** issue caps the score at **8.9** — it cannot be APPROVED.
- Any **security**, **data-loss**, or **build/test-breaking** issue caps the score at **7.9** or lower.
- A review may score **9.0+ only if** there are no must-fix correctness, security, data-loss,
  or test-blocking issues.

## Principle violations → severity

The four house principles (root `CLAUDE.md`) are scored, not optional:

| Principle violated | Severity |
|--------------------|----------|
| **Surgical Changes** — unrelated edits, drive-by refactors, style churn | **must-fix** (caps at 8.9) |
| **Surgical Changes** — code changed/removed that wasn't understood and breaks behavior | build/test or data-loss cap (**7.9** or lower) |
| **Goal-Driven Execution** — new behavior with no verifiable success criteria / tests | **must-fix**, test-blocking (caps at 8.9) |
| **Think Before Coding** — a silent wrong assumption that affects correctness | **must-fix** (caps at 8.9) |
| **Simplicity First** — clear overcomplication or speculative abstraction | **Should Consider**; **must-fix** if it harms correctness or maintainability enough to warrant rework |

## Findings discipline

- A **Must Fix** must cite concrete evidence — the exact `file:line` or the failing command/output. An issue you cannot point to, or are unsure is real, is **Should Consider** and must NOT cap the score or block a 9.0.
- A failing or skipped check counts as "pre-existing" only when proven on the base branch; an unproven "not related to my change" claim is itself a **must-fix**.
- A secret, credential, or PII that would ship in external text (PR body, handoff, issue) is a **security** issue → caps at **7.9** or lower.

## The gate

```
The doer produces the step's artifact.
The reviewer (the other model) scores it.
Score >= 9.0  → APPROVED → proceed.
Score <  9.0  → BLOCKED  → the doer fixes the Must Fix items and resubmits for re-score.
```

exec
/bin/zsh -lc "sed -n '1,260p' /Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/05-review-verdict-2.md" in /Users/allosta/Desktop/allosta
 succeeded in 0ms:
# Review Verdict

Reviewer: Opus
Step: review
Score: 7.6 / 10
Status: BLOCKED

## Reason
GPT's pass-3 review (APPROVED 9.2) was thorough and verified both prior fixes, the IDOR closure, the route-partition guard, and correctly declined to flag the Python-3.14-valid `except KeyError, ValueError:` — but it MISSED a real cross-tenant data-loss escape: a scope=all DELETE cascades the whole recurrence GROUP (`calendar.py` `_delete_all`, `WHERE recurrence_group_id == gid OR id == gid`), and a prior "following" split leaves a SIBLING master with out-of-filter links in that group. `_writable_event_target` validated only the resolved master + its overrides. A missed data-loss defect caps review quality below APPROVED.

## Must Fix
- The CODE defect (sibling-master delete-all escape) has been FIXED: shared_calendars.delete_event now validates the full delete-all blast radius via CalendarService.delete_all_target_links (every group master + their overrides), regression test test_delete_all_cannot_cascade_to_an_out_of_filter_sibling_master.

## Should Consider
- GPT's editor-direct-route Should-Consider is correctly non-blocking.

## Release Risk
Low (after the fix)

exec
/bin/zsh -lc "sed -n '1,260p' /Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/05-review-pass-5.md" in /Users/allosta/Desktop/allosta
exec
/bin/zsh -lc "sed -n '1,260p' /Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/05-review-pass-4.md" in /Users/allosta/Desktop/allosta
 succeeded in 0ms:
Reading additional input from stdin...
OpenAI Codex v0.135.0
--------
workdir: /Users/allosta/Desktop/allosta
model: gpt-5.5
provider: openai
approval: never
sandbox: read-only
reasoning effort: xhigh
reasoning summaries: none
session id: 019f032b-8f10-7070-9d23-405e3ab46aeb
--------
user
# Reviewer Charter (any model)

You are acting **only as the reviewer** for one step of the 7-step pipeline. You did **not**
produce this work — the **other** model did. Opus reviews GPT's work; GPT reviews Opus's work.
Review it cold and judge independently. Treat your verdict as a gate, not a suggestion.

You are **read-only**: never edit, create, or delete any file. Return only the scored verdict.

## What you score

- correctness, regressions, missing tests, edge cases, security, maintainability
- whether the work matches the task/plan/design it claims to satisfy

Plus the four house principles (full text in root `CLAUDE.md`; severity in
`.ai/checklists/scoring-rubric.md`):
- **Think Before Coding** — silent wrong assumptions, ambiguity resolved without surfacing, missing tradeoffs.
- **Simplicity First** — overcomplication, speculative abstractions, bloat.
- **Surgical Changes** — edits unrelated to the task, style drift, code changed/removed the task didn't require.
- **Goal-Driven Execution** — missing or weak verifiable success criteria for the new behavior.

## How to review (every step)

- **Scope first.** Confirm exactly what the step demanded was produced — no more, no less. Unrelated files, "while I was in there" edits, and unaddressed requirements are the first finding.
- **Cite evidence.** Every Must Fix names the exact `file:line` (or failing command). An issue you cannot point to, or are unsure is real, is **Should Consider**, never Must Fix — never block a 9.0 on an unproven hunch.
- **Read beyond the diff for completeness.** When a change adds an enum/status/union value or a new case, open the sibling call-sites outside the diff and confirm every switch/handler covers it.
- **Don't flag context-correct patterns.** Best-effort cleanup, fire-and-forget calls, and "sloppy"-looking code that is the right engineering choice are not findings. Never suggest a refactor that only satisfies a linter; match the codebase's existing style.
- **Review adversarially.** Think like an attacker and a chaos engineer — races, resource leaks, silent data corruption, swallowed failures, unbounded retries. One concrete "here is how it breaks in production" finding beats generic "safer is better".

## Step-specific lenses

The slash command tells you which step you are reviewing. Apply the matching lens:

- **think** — Is the problem framed correctly? Are assumptions explicit and the chosen option justified against the alternatives? Is anything important unstated or unbounded?
- **plan** — Minimum viable change? Does existing code already solve part of it? Failure modes named (which error, caught where, what the user sees), not "handle errors"? Does it state what each test proves?
- **design** — Coupling, state transitions, data flow on the unhappy path (null/empty/upstream error). Are the interfaces/contracts and the data model sound? Are alternatives considered and rejected for stated reasons?
- **build** — Correctness, regressions, security, deviation from plan/design. Scope-first against the diff.
- **review** (you are scoring the *other* model's review pass) — Is the review correct, complete, and well-evidenced? Did it miss real defects, or raise false Must-Fixes? Score the **quality of the review**, not the underlying code directly.
- **test** — Do the tests cover the risky paths or just the happy path? Did the suite actually run green? Any unproven "pre-existing" failure is itself a Must Fix.
- **ship** — Use the release-gate prompt (`.ai/prompts/final-release-review.md`): whole-change security pass, PR text honesty, migrations/rollback, no secrets in shipped text.

Do not rewrite the solution. Do not request broad refactors unless they block correctness or a safe release.

## Scoring

Score 0–10 using `.ai/checklists/scoring-rubric.md`. Hard rules:
- Any **must-fix** issue caps the score at **8.9** (cannot be APPROVED).
- Any **security**, **data-loss**, or **build/test-breaking** issue caps the score at **7.9** or lower.
- Status is **APPROVED only if Score >= 9.0**; otherwise BLOCKED.

## Verdict format

Output EXACTLY this and nothing else:

```
# Review Verdict

Reviewer: <Opus | GPT Codex>
Step: <think | plan | design | build | review | test | ship>
Score: X.X / 10
Status: APPROVED or BLOCKED

## Reason
<1–3 sentences on why this score>

## Must Fix
<blocking issues as a list, or "None">

## Should Consider
<non-blocking suggestions, or "None">

## Tests Reviewed
<the tests/commands you inspected or ran, or "N/A" for think/plan/design>

## Release Risk
Low, Medium, or High
```
You are GPT Codex, the doer for the REVIEW step (re-run #4) of focal-parity-data-scope. Run 'git -C /Users/allosta/Desktop/allosta/superapp-slice2 --no-pager diff feature/focal-migration' and the log.

Your pass-4 Must-Fix (delegated other-pages writes copy unchecked FK links → cascade data loss) is now FIXED — verify and do not re-raise: app/services/activities.py create_activity/update_activity now call _require_owned_links(user_id, project_id, product_id) (a project/product must belong to the data owner, else RelatedRecordNotFoundError); app/services/activity_instances.py sync_instances now rejects an activity_id not owned by user_id. I also AUDITED the sibling other-pages write domains and confirmed they ALREADY validate owner FK linkage: tasks + events + bookings via _require_owned_link; projects.create_project via _owned(parent) + update via _guard_reparent; goals.create_goal/update_goal via _require_project. Regression: tests/test_calendar_scope_db.py::test_delegated_other_pages_writes_reject_non_owner_fk_links.

Earlier-settled, do NOT re-raise: the recurrence scope invariant is fully closed (effective-occurrence + master + override-range + delete-all sibling-group validation); meeting-request accept/reschedule are scoped by shared_calendar_id (no project links on meeting events); the AI 'calendars' management entity is denied to delegated callers; AI shared-calendar ASSISTANT mode is deferred to slice 12 per the documented design note; the editor-direct-route client UX guard is an accepted non-blocking Should-Consider.

Do a FINAL holistic pass: if there is genuinely nothing else release-blocking across the whole change (cross-cutting authz, leaks, injection, secrets, silent corruption, swallowed failures, backward-compat — note data_owner_dep opens its session only in shared mode so own-data stays DB-free), say so and APPROVE. Build gate APPROVED 9.2; backend ruff+mypy+1702 pytest pass (only pre-existing 12 OpenAI-env + 1 ProjectRead.icon fails); client typecheck+biome+828 vitest+build pass. Review against task .ai/tasks/focal-parity.md, plan .ai/plans/focal-parity-plan.md, design .ai/design/focal-parity-data-scope-design.md + .ai/design/focal-parity-design.md. Cite file:line. Read-only; NEVER edit. Output the verdict EXACTLY as the charter specifies (Reviewer: GPT Codex, Step: review).
2026-06-26T09:03:35.060783Z ERROR rmcp::transport::worker: worker quit with fatal: Transport channel closed, when AuthRequired(AuthRequiredError { www_authenticate_header: "Bearer realm=\"OAuth\", resource_metadata=\"https://mcp.linear.app/.well-known/oauth-protected-resource/mcp\", error=\"invalid_token\", error_description=\"Missing or invalid access token\"" })
2026-06-26T09:03:35.294423Z ERROR rmcp::transport::worker: worker quit with fatal: Transport channel closed, when AuthRequired(AuthRequiredError { www_authenticate_header: "Bearer realm=\"mcp\", resource_metadata=\"https://mcp.railway.com/.well-known/oauth-protected-resource\"" })
2026-06-26T09:03:35.380699Z ERROR rmcp::transport::worker: worker quit with fatal: Transport channel closed, when AuthRequired(AuthRequiredError { www_authenticate_header: "Bearer resource_metadata=\"https://mcp.figma.com/.well-known/oauth-protected-resource\",scope=\"mcp:connect\",authorization_uri=\"https://api.figma.com/.well-known/oauth-authorization-server\"" })
exec
/bin/zsh -lc 'git -C /Users/allosta/Desktop/allosta/superapp-slice2 status --short' in /Users/allosta/Desktop/allosta
 succeeded in 0ms:
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-nqzIBBFU' (errno=Operation not permitted)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-FSwr6V7F' (errno=Operation not permitted)

exec
/bin/zsh -lc 'git -C /Users/allosta/Desktop/allosta/superapp-slice2 --no-pager diff feature/focal-migration' in /Users/allosta/Desktop/allosta
 succeeded in 0ms:
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-TSoUm6Ac' (errno=Operation not permitted)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-KEYVq2ql' (errno=Operation not permitted)
diff --git a/apps/focal/client/src/api/activities.ts b/apps/focal/client/src/api/activities.ts
index 90cbb3a..89c2786 100644
--- a/apps/focal/client/src/api/activities.ts
+++ b/apps/focal/client/src/api/activities.ts
@@ -6,7 +6,18 @@ export type Activity = Schemas['ActivityRead']
 export type ActivityUpdate = Schemas['ActivityUpdate']
 
 // The list endpoint returns every activity for the user; callers filter by productId.
-export const listActivities = (): Promise<Activity[]> => apiFetch<Activity[]>('/api/activities')
+// `calendarId` (the active shared-calendar selection; null = own data) scopes the call to that
+// calendar's owner server-side.
+export const listActivities = (calendarId?: string | null): Promise<Activity[]> =>
+  apiFetch<Activity[]>('/api/activities', { query: { calendarId } })
 
-export const updateActivity = (id: string, patch: ActivityUpdate): Promise<Activity> =>
-  apiFetch<Activity>(`/api/activities/${id}`, { method: 'PATCH', body: patch })
+export const updateActivity = (
+  id: string,
+  patch: ActivityUpdate,
+  calendarId?: string | null,
+): Promise<Activity> =>
+  apiFetch<Activity>(`/api/activities/${id}`, {
+    method: 'PATCH',
+    body: patch,
+    query: { calendarId },
+  })
diff --git a/apps/focal/client/src/api/activityInstances.ts b/apps/focal/client/src/api/activityInstances.ts
index 8f6b8f7..0c66c75 100644
--- a/apps/focal/client/src/api/activityInstances.ts
+++ b/apps/focal/client/src/api/activityInstances.ts
@@ -6,18 +6,33 @@ export type ActivityInstance = Schemas['ActivityInstanceRead']
 export type ActivityInstanceUpdate = Schemas['ActivityInstanceUpdate']
 export type ActivityInstanceSyncRequest = Schemas['ActivityInstanceSyncRequest']
 
-export const listActivityInstances = (activityId: string): Promise<ActivityInstance[]> =>
-  apiFetch<ActivityInstance[]>('/api/activity-instances', { query: { activityId } })
+// `calendarId` (the active shared-calendar selection; null = own data) scopes the call to that
+// calendar's owner server-side.
+export const listActivityInstances = (
+  activityId: string,
+  calendarId?: string | null,
+): Promise<ActivityInstance[]> =>
+  apiFetch<ActivityInstance[]>('/api/activity-instances', { query: { activityId, calendarId } })
 
 export const updateActivityInstance = (
   id: string,
   patch: ActivityInstanceUpdate,
+  calendarId?: string | null,
 ): Promise<ActivityInstance> =>
-  apiFetch<ActivityInstance>(`/api/activity-instances/${id}`, { method: 'PATCH', body: patch })
+  apiFetch<ActivityInstance>(`/api/activity-instances/${id}`, {
+    method: 'PATCH',
+    body: patch,
+    query: { calendarId },
+  })
 
 // Reconcile the stored instances with the activity's planned yearly count (appends
 // missing rows, trims surplus ones). Returns the reconciled instance list.
 export const syncActivityInstances = (
   input: ActivityInstanceSyncRequest,
+  calendarId?: string | null,
 ): Promise<ActivityInstance[]> =>
-  apiFetch<ActivityInstance[]>('/api/activity-instances/sync', { method: 'POST', body: input })
+  apiFetch<ActivityInstance[]>('/api/activity-instances/sync', {
+    method: 'POST',
+    body: input,
+    query: { calendarId },
+  })
diff --git a/apps/focal/client/src/api/analytics.ts b/apps/focal/client/src/api/analytics.ts
index 139eaf6..9880545 100644
--- a/apps/focal/client/src/api/analytics.ts
+++ b/apps/focal/client/src/api/analytics.ts
@@ -3,10 +3,14 @@ import { apiFetch, type Schemas } from './client'
 export type SpheresAnalytics = Schemas['SpheresAnalyticsRead']
 export type SphereAnalytics = Schemas['SphereAnalytics']
 
+// `calendarId` (the active shared-calendar selection; null = own data) scopes the call to that
+// calendar owner's data server-side. `buildUrl` drops null/undefined query values, so passing it
+// straight through is a no-op when absent.
 export const getSpheresAnalytics = (
   periodStart: string,
   periodEnd: string,
+  calendarId?: string | null,
 ): Promise<SpheresAnalytics> =>
   apiFetch<SpheresAnalytics>('/api/analytics/spheres', {
-    query: { periodStart, periodEnd },
+    query: { periodStart, periodEnd, calendarId },
   })
diff --git a/apps/focal/client/src/api/events.ts b/apps/focal/client/src/api/events.ts
index 00cf4e1..5845f88 100644
--- a/apps/focal/client/src/api/events.ts
+++ b/apps/focal/client/src/api/events.ts
@@ -14,25 +14,47 @@ export interface RecurrenceTarget {
   occurrenceDate: string
 }
 
-export const listEvents = (startDate: string, endDate: string): Promise<CalendarEvent[]> =>
-  apiFetch<CalendarEvent[]>('/api/events', { query: { startDate, endDate } })
+// `calendarId` (the active shared-calendar selection; null = own/main) scopes a call to the calendar
+// owner's data server-side, RBAC-gated: reads return the owner's filtered events, writes apply on the
+// owner's calendar. Omitted/null → the caller's own data (unchanged). `buildUrl` drops null/undefined
+// query values, so passing it straight through is a no-op when absent.
+export const listEvents = (
+  startDate: string,
+  endDate: string,
+  calendarId?: string | null,
+): Promise<CalendarEvent[]> =>
+  apiFetch<CalendarEvent[]>('/api/events', { query: { startDate, endDate, calendarId } })
 
-export const createEvent = (input: EventCreate): Promise<CalendarEvent> =>
-  apiFetch<CalendarEvent>('/api/events', { method: 'POST', body: input })
+export const createEvent = (
+  input: EventCreate,
+  calendarId?: string | null,
+): Promise<CalendarEvent> =>
+  apiFetch<CalendarEvent>('/api/events', { method: 'POST', body: input, query: { calendarId } })
 
 export const updateEvent = (
   id: string,
   patch: EventUpdate,
   target?: RecurrenceTarget,
+  calendarId?: string | null,
 ): Promise<CalendarEvent> =>
   apiFetch<CalendarEvent>(`/api/events/${id}`, {
     method: 'PATCH',
     body: patch,
-    query: target && { recurrenceScope: target.scope, occurrenceDate: target.occurrenceDate },
+    query: {
+      ...(target && { recurrenceScope: target.scope, occurrenceDate: target.occurrenceDate }),
+      calendarId,
+    },
   })
 
-export const deleteEvent = (id: string, target?: RecurrenceTarget): Promise<void> =>
+export const deleteEvent = (
+  id: string,
+  target?: RecurrenceTarget,
+  calendarId?: string | null,
+): Promise<void> =>
   apiFetch<undefined>(`/api/events/${id}`, {
     method: 'DELETE',
-    query: target && { recurrenceScope: target.scope, occurrenceDate: target.occurrenceDate },
+    query: {
+      ...(target && { recurrenceScope: target.scope, occurrenceDate: target.occurrenceDate }),
+      calendarId,
+    },

 succeeded in 0ms:
Reading additional input from stdin...
OpenAI Codex v0.135.0
--------
workdir: /Users/allosta/Desktop/allosta
model: gpt-5.5
provider: openai
approval: never
sandbox: read-only
reasoning effort: xhigh
reasoning summaries: none
session id: 019f031e-5b9f-72b1-8dc5-a6e35f580d34
--------
user
# Reviewer Charter (any model)

You are acting **only as the reviewer** for one step of the 7-step pipeline. You did **not**
produce this work — the **other** model did. Opus reviews GPT's work; GPT reviews Opus's work.
Review it cold and judge independently. Treat your verdict as a gate, not a suggestion.

You are **read-only**: never edit, create, or delete any file. Return only the scored verdict.

## What you score

- correctness, regressions, missing tests, edge cases, security, maintainability
- whether the work matches the task/plan/design it claims to satisfy

Plus the four house principles (full text in root `CLAUDE.md`; severity in
`.ai/checklists/scoring-rubric.md`):
- **Think Before Coding** — silent wrong assumptions, ambiguity resolved without surfacing, missing tradeoffs.
- **Simplicity First** — overcomplication, speculative abstractions, bloat.
- **Surgical Changes** — edits unrelated to the task, style drift, code changed/removed the task didn't require.
- **Goal-Driven Execution** — missing or weak verifiable success criteria for the new behavior.

## How to review (every step)

- **Scope first.** Confirm exactly what the step demanded was produced — no more, no less. Unrelated files, "while I was in there" edits, and unaddressed requirements are the first finding.
- **Cite evidence.** Every Must Fix names the exact `file:line` (or failing command). An issue you cannot point to, or are unsure is real, is **Should Consider**, never Must Fix — never block a 9.0 on an unproven hunch.
- **Read beyond the diff for completeness.** When a change adds an enum/status/union value or a new case, open the sibling call-sites outside the diff and confirm every switch/handler covers it.
- **Don't flag context-correct patterns.** Best-effort cleanup, fire-and-forget calls, and "sloppy"-looking code that is the right engineering choice are not findings. Never suggest a refactor that only satisfies a linter; match the codebase's existing style.
- **Review adversarially.** Think like an attacker and a chaos engineer — races, resource leaks, silent data corruption, swallowed failures, unbounded retries. One concrete "here is how it breaks in production" finding beats generic "safer is better".

## Step-specific lenses

The slash command tells you which step you are reviewing. Apply the matching lens:

- **think** — Is the problem framed correctly? Are assumptions explicit and the chosen option justified against the alternatives? Is anything important unstated or unbounded?
- **plan** — Minimum viable change? Does existing code already solve part of it? Failure modes named (which error, caught where, what the user sees), not "handle errors"? Does it state what each test proves?
- **design** — Coupling, state transitions, data flow on the unhappy path (null/empty/upstream error). Are the interfaces/contracts and the data model sound? Are alternatives considered and rejected for stated reasons?
- **build** — Correctness, regressions, security, deviation from plan/design. Scope-first against the diff.
- **review** (you are scoring the *other* model's review pass) — Is the review correct, complete, and well-evidenced? Did it miss real defects, or raise false Must-Fixes? Score the **quality of the review**, not the underlying code directly.
- **test** — Do the tests cover the risky paths or just the happy path? Did the suite actually run green? Any unproven "pre-existing" failure is itself a Must Fix.
- **ship** — Use the release-gate prompt (`.ai/prompts/final-release-review.md`): whole-change security pass, PR text honesty, migrations/rollback, no secrets in shipped text.

Do not rewrite the solution. Do not request broad refactors unless they block correctness or a safe release.

## Scoring

Score 0–10 using `.ai/checklists/scoring-rubric.md`. Hard rules:
- Any **must-fix** issue caps the score at **8.9** (cannot be APPROVED).
- Any **security**, **data-loss**, or **build/test-breaking** issue caps the score at **7.9** or lower.
- Status is **APPROVED only if Score >= 9.0**; otherwise BLOCKED.

## Verdict format

Output EXACTLY this and nothing else:

```
# Review Verdict

Reviewer: <Opus | GPT Codex>
Step: <think | plan | design | build | review | test | ship>
Score: X.X / 10
Status: APPROVED or BLOCKED

## Reason
<1–3 sentences on why this score>

## Must Fix
<blocking issues as a list, or "None">

## Should Consider
<non-blocking suggestions, or "None">

## Tests Reviewed
<the tests/commands you inspected or ran, or "N/A" for think/plan/design>

## Release Risk
Low, Medium, or High
```
You are GPT Codex, the doer for the REVIEW step (re-run #3) of focal-parity-data-scope. Run 'git -C /Users/allosta/Desktop/allosta/superapp-slice2 --no-pager diff feature/focal-migration' and the log 'feature/focal-migration..HEAD'.

A holistic re-review found one defect your pass-3 missed; it is now FIXED — verify and do not re-raise: the scope=all DELETE recurrence-GROUP escape. app/services/shared_calendars.py delete_event now, for resolved scope 'all', validates the FULL delete-all blast radius via CalendarService.delete_all_target_links(owner, master_id) — EVERY master in the recurrence group (a prior 'following' split leaves sibling masters with their own links via _new_master_from_occurrence) PLUS all their overrides — and rejects (403) if any is out-of-filter. Regression test: tests/test_calendar_scope_db.py::test_delete_all_cannot_cascade_to_an_out_of_filter_sibling_master. (update-all edits one master in place; following-delete truncates one master — neither cross the group.)

The full recurrence scope-invariant for shared writes is now: _writable_event_target validates the EFFECTIVE occurrence (event-id OR master-id+occurrenceDate) + the master + every override in the affected range; delete-all additionally validates every sibling master in the group. Do NOT re-raise any recurrence-occurrence/override/sibling variant.

Also already settled (do NOT re-raise): meeting-request accept/reschedule are scoped by shared_calendar_id not the project-filter (meeting events have no project links); the AI 'calendars' management entity is denied to delegated callers (ai_chat.py); AI shared-calendar ASSISTANT mode is deferred to slice 12 per the documented design note; the editor-direct-route client UX guard is an accepted non-blocking Should-Consider.

Do a final holistic pass for anything ELSE genuinely release-blocking that remains (cross-cutting authz, leaks, injection, secrets, silent corruption, swallowed failures, backward-compat). If there is truly nothing left, say so and APPROVE. Build gate APPROVED 9.2; backend ruff+mypy+1701 pytest pass (only pre-existing 12 OpenAI-env + 1 ProjectRead.icon fails); client typecheck+biome+828 vitest+build pass. Review against task .ai/tasks/focal-parity.md, plan .ai/plans/focal-parity-plan.md, design .ai/design/focal-parity-data-scope-design.md + .ai/design/focal-parity-design.md. Cite file:line. Read-only; NEVER edit. Output the verdict EXACTLY as the charter specifies (Reviewer: GPT Codex, Step: review).
2026-06-26T08:49:09.961678Z ERROR rmcp::transport::worker: worker quit with fatal: Transport channel closed, when AuthRequired(AuthRequiredError { www_authenticate_header: "Bearer realm=\"OAuth\", resource_metadata=\"https://mcp.linear.app/.well-known/oauth-protected-resource/mcp\", error=\"invalid_token\", error_description=\"Missing or invalid access token\"" })
2026-06-26T08:49:10.107855Z ERROR rmcp::transport::worker: worker quit with fatal: Transport channel closed, when AuthRequired(AuthRequiredError { www_authenticate_header: "Bearer realm=\"mcp\", resource_metadata=\"https://mcp.railway.com/.well-known/oauth-protected-resource\"" })
2026-06-26T08:49:10.205448Z ERROR rmcp::transport::worker: worker quit with fatal: Transport channel closed, when AuthRequired(AuthRequiredError { www_authenticate_header: "Bearer resource_metadata=\"https://mcp.figma.com/.well-known/oauth-protected-resource\",scope=\"mcp:connect\",authorization_uri=\"https://api.figma.com/.well-known/oauth-authorization-server\"" })
exec
/bin/zsh -lc 'git --no-pager log --oneline --decorate feature/focal-migration..HEAD' in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-VQjkXqaR' (errno=Operation not permitted)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-qknHJ7vv' (errno=Operation not permitted)
e924efd (HEAD -> feat/focal-parity-data-scope) Wrap a long docstring line
46a9d26 Validate the full delete-all recurrence-group blast radius so a shared editor cannot cascade-delete an out-of-filter sibling master
4862146 Block shared series writes that would touch out-of-filter override occurrences, and deny owner-only calendar management to delegated AI callers
41b9d63 Add a meeting-request accept cross-calendar scope test pinning the shared_calendar_id guard on the write path
552a1c6 Assert the override-creation step in the recurrence regression fixture so it fails at the cause
a8232ce Resolve the effective occurrence from event id and occurrenceDate before the shared-write filter check, closing the master-id-plus-occurrenceDate recurrence escape
d04e330 Validate both the occurrence and the master for series-scope shared writes to close the following-split filter escape, and rename the AI memory-scope owner helper to deter misuse
a7d00a0 Open the owner-resolution session only in shared mode so own-data requests keep the DB-free in-memory path
d9d672f Scope habit creation to the active calendar, read-only gate the Projects/Spheres/Habits write pages, and regenerate the client OpenAPI types
cb94d19 Filter shared-mode bookings by the calendar's saved filter and meeting-requests by shared_calendar_id, including the calendar-init aggregate
ebb90a8 Close the recurrence-scope filter escape, scope the sidebar meeting-count to the active calendar, and gate AI owner resolution by role-set membership
5a0837d Scope slice-2 AI changes to the IDOR fix and defer shared-calendar AI assistant mode to the AI slice
8f97a5e Enforce the calendar filter on shared-mode event writes and AI event reads, and scope the tasks-page projects query to the active calendar
f385bc4 Scope client data fetches to the selected shared calendar and gate page writes read-only when the viewer lacks edit access
6a18e93 Add the closed-partition route guard so a scoped route on raw get_current_user_id or an unclassified router fails the build
d102be3 Wire the calendar domain to the scope invariant: filtered shared event reads/writes, role-gated bookings and meeting-requests, and the gated calendar-init aggregate
fe199fc Add the central data-scope authorization test suite covering both domain gates and the AI IDOR regression
83eee08 Close the AI-chat data-owner IDOR with an RBAC-gated resolver and per-intent write gate
042442c Add assistant-mode data-owner resolver and wire it onto the other-pages domain routers

exec
/bin/zsh -lc 'git --no-pager diff feature/focal-migration' in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-mdkIgeZh' (errno=Operation not permitted)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-vb0PwKEM' (errno=Operation not permitted)
diff --git a/apps/focal/client/src/api/activities.ts b/apps/focal/client/src/api/activities.ts
index 90cbb3a..89c2786 100644
--- a/apps/focal/client/src/api/activities.ts
+++ b/apps/focal/client/src/api/activities.ts
@@ -6,7 +6,18 @@ export type Activity = Schemas['ActivityRead']
 export type ActivityUpdate = Schemas['ActivityUpdate']
 
 // The list endpoint returns every activity for the user; callers filter by productId.
-export const listActivities = (): Promise<Activity[]> => apiFetch<Activity[]>('/api/activities')
+// `calendarId` (the active shared-calendar selection; null = own data) scopes the call to that
+// calendar's owner server-side.
+export const listActivities = (calendarId?: string | null): Promise<Activity[]> =>
+  apiFetch<Activity[]>('/api/activities', { query: { calendarId } })
 
-export const updateActivity = (id: string, patch: ActivityUpdate): Promise<Activity> =>
-  apiFetch<Activity>(`/api/activities/${id}`, { method: 'PATCH', body: patch })
+export const updateActivity = (
+  id: string,
+  patch: ActivityUpdate,
+  calendarId?: string | null,
+): Promise<Activity> =>
+  apiFetch<Activity>(`/api/activities/${id}`, {
+    method: 'PATCH',
+    body: patch,
+    query: { calendarId },
+  })
diff --git a/apps/focal/client/src/api/activityInstances.ts b/apps/focal/client/src/api/activityInstances.ts
index 8f6b8f7..0c66c75 100644
--- a/apps/focal/client/src/api/activityInstances.ts
+++ b/apps/focal/client/src/api/activityInstances.ts
@@ -6,18 +6,33 @@ export type ActivityInstance = Schemas['ActivityInstanceRead']
 export type ActivityInstanceUpdate = Schemas['ActivityInstanceUpdate']
 export type ActivityInstanceSyncRequest = Schemas['ActivityInstanceSyncRequest']
 
-export const listActivityInstances = (activityId: string): Promise<ActivityInstance[]> =>
-  apiFetch<ActivityInstance[]>('/api/activity-instances', { query: { activityId } })
+// `calendarId` (the active shared-calendar selection; null = own data) scopes the call to that
+// calendar's owner server-side.
+export const listActivityInstances = (
+  activityId: string,
+  calendarId?: string | null,
+): Promise<ActivityInstance[]> =>
+  apiFetch<ActivityInstance[]>('/api/activity-instances', { query: { activityId, calendarId } })
 
 export const updateActivityInstance = (
   id: string,
   patch: ActivityInstanceUpdate,
+  calendarId?: string | null,
 ): Promise<ActivityInstance> =>
-  apiFetch<ActivityInstance>(`/api/activity-instances/${id}`, { method: 'PATCH', body: patch })
+  apiFetch<ActivityInstance>(`/api/activity-instances/${id}`, {
+    method: 'PATCH',
+    body: patch,
+    query: { calendarId },
+  })
 
 // Reconcile the stored instances with the activity's planned yearly count (appends
 // missing rows, trims surplus ones). Returns the reconciled instance list.
 export const syncActivityInstances = (
   input: ActivityInstanceSyncRequest,
+  calendarId?: string | null,
 ): Promise<ActivityInstance[]> =>
-  apiFetch<ActivityInstance[]>('/api/activity-instances/sync', { method: 'POST', body: input })
+  apiFetch<ActivityInstance[]>('/api/activity-instances/sync', {
+    method: 'POST',
+    body: input,
+    query: { calendarId },
+  })
diff --git a/apps/focal/client/src/api/analytics.ts b/apps/focal/client/src/api/analytics.ts
index 139eaf6..9880545 100644
--- a/apps/focal/client/src/api/analytics.ts
+++ b/apps/focal/client/src/api/analytics.ts
@@ -3,10 +3,14 @@ import { apiFetch, type Schemas } from './client'
 export type SpheresAnalytics = Schemas['SpheresAnalyticsRead']
 export type SphereAnalytics = Schemas['SphereAnalytics']
 
+// `calendarId` (the active shared-calendar selection; null = own data) scopes the call to that
+// calendar owner's data server-side. `buildUrl` drops null/undefined query values, so passing it
+// straight through is a no-op when absent.
 export const getSpheresAnalytics = (
   periodStart: string,
   periodEnd: string,
+  calendarId?: string | null,
 ): Promise<SpheresAnalytics> =>
   apiFetch<SpheresAnalytics>('/api/analytics/spheres', {
-    query: { periodStart, periodEnd },
+    query: { periodStart, periodEnd, calendarId },
   })
diff --git a/apps/focal/client/src/api/events.ts b/apps/focal/client/src/api/events.ts
index 00cf4e1..5845f88 100644
--- a/apps/focal/client/src/api/events.ts
+++ b/apps/focal/client/src/api/events.ts
@@ -14,25 +14,47 @@ export interface RecurrenceTarget {
   occurrenceDate: string
 }
 
-export const listEvents = (startDate: string, endDate: string): Promise<CalendarEvent[]> =>
-  apiFetch<CalendarEvent[]>('/api/events', { query: { startDate, endDate } })
+// `calendarId` (the active shared-calendar selection; null = own/main) scopes a call to the calendar
+// owner's data server-side, RBAC-gated: reads return the owner's filtered events, writes apply on the
+// owner's calendar. Omitted/null → the caller's own data (unchanged). `buildUrl` drops null/undefined
+// query values, so passing it straight through is a no-op when absent.
+export const listEvents = (
+  startDate: string,
+  endDate: string,
+  calendarId?: string | null,
+): Promise<CalendarEvent[]> =>
+  apiFetch<CalendarEvent[]>('/api/events', { query: { startDate, endDate, calendarId } })
 
-export const createEvent = (input: EventCreate): Promise<CalendarEvent> =>
-  apiFetch<CalendarEvent>('/api/events', { method: 'POST', body: input })
+export const createEvent = (
+  input: EventCreate,
+  calendarId?: string | null,
+): Promise<CalendarEvent> =>
+  apiFetch<CalendarEvent>('/api/events', { method: 'POST', body: input, query: { calendarId } })
 
 export const updateEvent = (
   id: string,
   patch: EventUpdate,
   target?: RecurrenceTarget,
+  calendarId?: string | null,
 ): Promise<CalendarEvent> =>
   apiFetch<CalendarEvent>(`/api/events/${id}`, {
     method: 'PATCH',

exec
/bin/zsh -lc "sed -n '1,260p' /Users/allosta/Desktop/allosta/.ai/reviews/focal-parity-data-scope/04-build-verdict-9.md" in /Users/allosta/Desktop/allosta
 succeeded in 0ms:
# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 9.2 / 10
Status: APPROVED

## Reason
The prior recurrence escape is closed: `_writable_event_target` now resolves the effective occurrence from either synthetic occurrence id or `master_id + occurrenceDate`, and validates that occurrence plus the master for series-affecting scopes before delegating to `CalendarService`. The broader diff matches the documented slice boundary, keeps AI shared-calendar assistant mode deferred, and has focused backend regression coverage for the cross-user calendar-scope invariant.

## Must Fix
None

## Should Consider
- Add an assertion on the setup owner patch in `tests/test_calendar_scope_db.py` so the regression fixture fails closer to the cause if the hidden occurrence override ever stops being created. (Done in a follow-up commit.)

## Release Risk
Medium

---
Build gate took 9 review passes (7.0 → 7.8 → 7.6 → 7.6 → 8.4 → 7.8 → 7.8 → 7.8 → 9.2). Each BLOCK surfaced a real
cross-user calendar-scope gap: create/move filter validation, AI event filtering (deferred to slice 12), TasksPage
projects scoping, recurrence-scope master escape, sidebar meeting-count, best_assist_role tie, bookings + meeting-request
filtering, calendar_init bookings, DB-free own-data session, habit-create calendarId + read-only gating, and three
recurrence-occurrence escape shapes. Local: backend ruff+mypy+1698 pytest (only pre-existing OpenAI-env + ProjectRead.icon
fails); client typecheck+biome+828 vitest+build.

exec
/bin/zsh -lc "nl -ba apps/focal/server/app/data_scope.py | sed -n '1,260p'" in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
     1	"""Assistant-mode data scoping — the load-bearing cross-user authorization boundary.
     2	
     3	When a shared-calendar participant views/edits the calendar OWNER's data (rather than their own),
     4	the only thing standing between caller C and owner O's rows is the RBAC check here: the domain
     5	service sessions bypass RLS, so the app-layer ``WHERE user_id == effective_owner`` filter is the
     6	tenant boundary and ``resolve_data_owner`` chooses ``effective_owner``. Get the role sets wrong and
     7	it leaks.
     8	
     9	The gates are NOT uniform — they split by domain, tracking the two shared-calendar permission
    10	dimensions (``can_edit`` = event editing; ``can_view_other_pages`` = access to non-calendar pages):
    11	
    12	- **calendar** (events / calendar-init / bookings / meeting-requests): READ = any accepted
    13	  participant (viewer+); WRITE = ``can_edit`` (owner / full_access / editor).
    14	- **other-pages** (tasks/projects/activities/mindmap/goals/spheres/time-budgets/tags/habits/…):
    15	  READ = ``can_view_other_pages`` (owner/full_access/developer); WRITE = that ∩ write
    16	  (owner/full_access — a ``developer`` is read-only and an ``editor`` cannot view other pages).
    17	
    18	Checks are set-membership, not rank: developer/viewer/requester share rank 10 yet differ across
    19	these sets. Calendar-domain endpoints additionally enforce the calendar's saved filter server-side
    20	(list reads via the filtered shared path, by-id/create validated against the filter) — that scope
    21	enforcement lives at each calendar endpoint; this module resolves the owner + authorizes the role.
    22	"""
    23	
    24	import re
    25	from collections.abc import AsyncIterator
    26	from enum import StrEnum
    27	
    28	from fastapi import Depends, Query
    29	from sqlalchemy import select
    30	from sqlalchemy.ext.asyncio import AsyncSession
    31	
    32	from app.db import get_sessionmaker
    33	from app.deps import get_current_user_id
    34	from app.errors import NotFoundError, PermissionDeniedError
    35	from app.models.shared_calendar import SharedCalendar, SharedCalendarParticipant
    36	from app.rbac import get_resource_role
    37	
    38	_UUID_RE = re.compile(
    39	    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
    40	)
    41	
    42	
    43	class DataDomain(StrEnum):
    44	    """Which gate set a route's data falls under (see module docstring)."""
    45	
    46	    CALENDAR = "calendar"
    47	    OTHER_PAGES = "other_pages"
    48	
    49	
    50	# Role sets per (domain, action). Set-membership, never rank (developer != viewer at rank 10).
    51	CALENDAR_READ_ROLES = frozenset(
    52	    {"owner", "full_access", "editor", "developer", "viewer", "requester"}
    53	)  # any accepted participant may read the shared calendar's events
    54	CALENDAR_WRITE_ROLES = frozenset({"owner", "full_access", "editor"})  # == can_edit
    55	OTHER_PAGES_READ_ROLES = frozenset({"owner", "full_access", "developer"})  # == can_view_other_pages
    56	OTHER_PAGES_WRITE_ROLES = frozenset({"owner", "full_access"})  # can_view_other_pages ∩ write
    57	
    58	_GATES: dict[tuple[DataDomain, str], frozenset[str]] = {
    59	    (DataDomain.CALENDAR, "read"): CALENDAR_READ_ROLES,
    60	    (DataDomain.CALENDAR, "write"): CALENDAR_WRITE_ROLES,
    61	    (DataDomain.OTHER_PAGES, "read"): OTHER_PAGES_READ_ROLES,
    62	    (DataDomain.OTHER_PAGES, "write"): OTHER_PAGES_WRITE_ROLES,
    63	}
    64	
    65	
    66	async def resolve_data_owner(
    67	    session: AsyncSession,
    68	    caller_id: str,
    69	    calendar_id: str | None,
    70	    *,
    71	    domain: DataDomain,
    72	    action: str = "read",
    73	) -> str:
    74	    """The effective data owner for the request, authorized by the caller's shared-calendar role.
    75	
    76	    ``calendar_id`` absent → the caller's own data (today's behavior, backward compatible). Else the
    77	    calendar is resolved; if the caller owns it the owner is the caller (own data); otherwise the
    78	    caller's accepted participant role must be in the gate for ``(domain, action)`` — else 403 — and
    79	    the calendar owner's id is returned for the service to filter by. A missing calendar → 404.
    80	    """
    81	    if not calendar_id:
    82	        return caller_id
    83	    calendar = await session.get(SharedCalendar, calendar_id)
    84	    if calendar is None:
    85	        raise NotFoundError("Shared calendar not found")
    86	    if calendar.user_id == caller_id:
    87	        return caller_id  # the caller's own calendar → own data, full access
    88	    role = await get_resource_role(session, calendar_id, caller_id)
    89	    if role is None or role not in _GATES[(domain, action)]:
    90	        raise PermissionDeniedError(
    91	            "Insufficient role for this data on the shared calendar"
    92	        )
    93	    return calendar.user_id
    94	
    95	
    96	async def _scope_session(
    97	    calendarId: str | None = Query(default=None),
    98	) -> AsyncIterator[AsyncSession | None]:
    99	    """A short-lived session for the RBAC lookup, independent of the route's service session
   100	    (mirrors ``rbac._rbac_session``). Opened ONLY in shared mode (a ``calendarId`` is supplied) —
   101	    an own-data request never touches the DB engine, so the DB-free in-memory path (no
   102	    ``DATABASE_URL``) keeps working exactly as before this slice."""
   103	    if not calendarId:
   104	        yield None
   105	        return
   106	    async with get_sessionmaker()() as session:
   107	        yield session
   108	
   109	
   110	def data_owner_dep(domain: DataDomain, action: str = "read"):
   111	    """FastAPI dependency factory: resolves the effective data owner from an optional ``calendarId``
   112	    query param + the caller's role, gated by ``(domain, action)``. Drop-in replacement for
   113	    ``Depends(get_current_user_id)`` on a scoped route — returns the owner id to filter by. With no
   114	    ``calendarId`` it returns the caller WITHOUT opening a session (own-data, backward compatible).
   115	    """
   116	
   117	    async def dependency(
   118	        calendarId: str | None = Query(default=None),
   119	        caller_id: str = Depends(get_current_user_id),
   120	        session: AsyncSession | None = Depends(_scope_session),
   121	    ) -> str:
   122	        if not calendarId or session is None:
   123	            return caller_id
   124	        return await resolve_data_owner(
   125	            session, caller_id, calendarId, domain=domain, action=action
   126	        )
   127	
   128	    return dependency
   129	
   130	
   131	# --- AI chat scoping ---------------------------------------------------------
   132	# The AI chat carries a target owner id (not a calendar id), so it can't use the calendar-keyed
   133	# dependency above. These resolve the caller's best accepted role across ALL calendars owned by the
   134	# target and gate against the same role sets — closing the IDOR where any UUID was trusted.
   135	
   136	
   137	async def accepted_assist_roles(
   138	    session: AsyncSession, caller_id: str, owner_id: str
   139	) -> frozenset[str]:
   140	    """ALL accepted participant roles the caller holds across calendars owned by ``owner_id``
   141	    (``{"owner"}`` when the caller IS the owner; empty when there is no accepted participation). The
   142	    AI gates test set-membership against this — NOT a single "best" role: developer/viewer/requester
   143	    share a ``ROLE_RANK`` yet differ across the gate sets, so a rank-max could pick a tied role that
   144	    fails the gate while another held role would have passed."""
   145	    if caller_id == owner_id:
   146	        return frozenset({"owner"})
   147	    rows = await session.execute(
   148	        select(SharedCalendarParticipant.role)
   149	        .join(SharedCalendar, SharedCalendar.id == SharedCalendarParticipant.shared_calendar_id)
   150	        .where(
   151	            SharedCalendar.user_id == owner_id,
   152	            SharedCalendarParticipant.user_id == caller_id,
   153	            SharedCalendarParticipant.invite_status == "accepted",
   154	        )
   155	    )
   156	    return frozenset(role for (role,) in rows.all())
   157	
   158	
   159	async def resolve_ai_data_owner(session: AsyncSession, caller_id: str, requested: object) -> str:
   160	    """The AI chat's effective data owner, RBAC-gated (closes the IDOR). A client-supplied target
   161	    owner is served ONLY if the caller holds an other-pages READ role (owner/full_access/developer)
   162	    on a calendar owned by that user — otherwise 403. Absent / non-UUID / own id → the caller."""
   163	    if not isinstance(requested, str):
   164	        return caller_id
   165	    target = requested.strip()
   166	    if not target or target == caller_id or not _UUID_RE.match(target):
   167	        return caller_id
   168	    roles = await accepted_assist_roles(session, caller_id, target)
   169	    if not (roles & OTHER_PAGES_READ_ROLES):
   170	        raise PermissionDeniedError("Not authorized to view this user's data")
   171	    return target
   172	
   173	
   174	async def require_ai_write(
   175	    session: AsyncSession, caller_id: str, owner_id: str, *, domain: DataDomain
   176	) -> None:
   177	    """Before an AI create/update/delete intent writes the owner's data, require the caller to hold
   178	    a role in that domain's write gate (calendar → owner/full_access/editor; other-pages →
   179	    owner/full_access). No-op when the caller is the owner."""
   180	    if caller_id == owner_id:
   181	        return
   182	    roles = await accepted_assist_roles(session, caller_id, owner_id)
   183	    if not (roles & _GATES[(domain, "write")]):
   184	        raise PermissionDeniedError("Not authorized to modify this user's data")

exec
/bin/zsh -lc "nl -ba apps/focal/server/app/api/activities.py | sed -n '1,220p'" in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
     1	from collections.abc import AsyncIterator
     2	
     3	from fastapi import APIRouter, Depends, status
     4	
     5	from app.data_scope import DataDomain, data_owner_dep
     6	from app.db import get_sessionmaker
     7	from app.schemas.activities import ActivityCreate, ActivityRead, ActivityUpdate
     8	from app.services.activities import ActivitiesService
     9	
    10	router = APIRouter(prefix="/api/activities", tags=["activities"])
    11	
    12	_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
    13	_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
    14	
    15	
    16	async def get_activities_service() -> AsyncIterator[ActivitiesService]:
    17	    # DB-backed only: the cascade/transaction behavior is DB-semantic.
    18	    async with get_sessionmaker()() as session:
    19	        yield ActivitiesService(session)
    20	
    21	
    22	@router.get("", response_model=list[ActivityRead])
    23	async def list_activities(
    24	    user_id: str = Depends(_owner_read),
    25	    service: ActivitiesService = Depends(get_activities_service),
    26	) -> list[ActivityRead]:
    27	    return await service.list_activities(user_id)
    28	
    29	
    30	@router.post("", response_model=ActivityRead, status_code=status.HTTP_201_CREATED)
    31	async def create_activity(
    32	    payload: ActivityCreate,
    33	    user_id: str = Depends(_owner_write),
    34	    service: ActivitiesService = Depends(get_activities_service),
    35	) -> ActivityRead:
    36	    return await service.create_activity(user_id, payload)
    37	
    38	
    39	@router.get("/{activity_id}", response_model=ActivityRead)
    40	async def get_activity(
    41	    activity_id: str,
    42	    user_id: str = Depends(_owner_read),
    43	    service: ActivitiesService = Depends(get_activities_service),
    44	) -> ActivityRead:
    45	    return await service.get_activity(user_id, activity_id)
    46	
    47	
    48	@router.patch("/{activity_id}", response_model=ActivityRead)
    49	async def update_activity(
    50	    activity_id: str,
    51	    payload: ActivityUpdate,
    52	    user_id: str = Depends(_owner_write),
    53	    service: ActivitiesService = Depends(get_activities_service),
    54	) -> ActivityRead:
    55	    return await service.update_activity(user_id, activity_id, payload)
    56	
    57	
    58	@router.delete("/{activity_id}")
    59	async def delete_activity(
    60	    activity_id: str,
    61	    user_id: str = Depends(_owner_write),
    62	    service: ActivitiesService = Depends(get_activities_service),
    63	) -> dict[str, bool]:
    64	    await service.delete_activity(user_id, activity_id)
    65	    return {"success": True}

exec
/bin/zsh -lc "nl -ba apps/focal/server/app/services/activities.py | sed -n '1,260p'" in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
     1	from sqlalchemy import select
     2	from sqlalchemy.ext.asyncio import AsyncSession
     3	
     4	from app.errors import NotFoundError, RelatedRecordNotFoundError
     5	from app.models.activities import Activity
     6	from app.models.projects import Project
     7	from app.schemas.activities import ActivityCreate, ActivityRead, ActivityUpdate
     8	
     9	
    10	class ActivitiesService:
    11	    """Activity CRUD against ``focal.activities``, tenant-scoped to the authenticated user.
    12	    Activities are the MindMap's leaf nodes (under a project/product). Mirrors legacy
    13	    ``/api/activities`` but scopes every lookup by ``user_id`` for tenant isolation."""
    14	
    15	    def __init__(self, session: AsyncSession) -> None:
    16	        self.session = session
    17	
    18	    async def list_activities(self, user_id: str) -> list[ActivityRead]:
    19	        result = await self.session.execute(
    20	            select(Activity)
    21	            .where(Activity.user_id == user_id)
    22	            .order_by(Activity.sort_order, Activity.created_at)
    23	        )
    24	        return [ActivityRead.model_validate(row) for row in result.scalars().all()]
    25	
    26	    async def get_activity(self, user_id: str, activity_id: str) -> ActivityRead:
    27	        return ActivityRead.model_validate(await self._require(user_id, activity_id))
    28	
    29	    async def create_activity(self, user_id: str, payload: ActivityCreate) -> ActivityRead:
    30	        # Set only the fields the client sent so the model's column defaults apply to the rest
    31	        # (e.g. status="planned", positions 0) instead of being overwritten with null.
    32	        data = payload.model_dump(exclude_unset=True)
    33	        await self._require_owned_links(user_id, data.get("project_id"), data.get("product_id"))
    34	        activity = Activity(user_id=user_id)
    35	        for field, value in data.items():
    36	            setattr(activity, field, value)
    37	        self.session.add(activity)
    38	        await self.session.commit()
    39	        await self.session.refresh(activity)
    40	        return ActivityRead.model_validate(activity)
    41	
    42	    async def update_activity(
    43	        self, user_id: str, activity_id: str, payload: ActivityUpdate
    44	    ) -> ActivityRead:
    45	        activity = await self._require(user_id, activity_id)
    46	        data = payload.model_dump(exclude_unset=True)
    47	        await self._require_owned_links(user_id, data.get("project_id"), data.get("product_id"))
    48	        for field, value in data.items():
    49	            setattr(activity, field, value)
    50	        await self.session.commit()
    51	        await self.session.refresh(activity)
    52	        return ActivityRead.model_validate(activity)
    53	
    54	    async def _require_owned_links(
    55	        self, user_id: str, project_id: str | None, product_id: str | None
    56	    ) -> None:
    57	        """A project_id/product_id must belong to the data owner. In a delegated (shared assistant)
    58	        write the payload could otherwise point the owner's activity at the CALLER's own project and
    59	        then cascade-delete the owner's row by deleting that project — so reject non-owned links."""
    60	        for link_id in (project_id, product_id):
    61	            if link_id is not None:
    62	                project = await self.session.get(Project, link_id)
    63	                if project is None or project.user_id != user_id:
    64	                    raise RelatedRecordNotFoundError("Related record not found")
    65	
    66	    async def delete_activity(self, user_id: str, activity_id: str) -> None:
    67	        activity = await self._require(user_id, activity_id)
    68	        await self.session.delete(activity)
    69	        await self.session.commit()
    70	
    71	    async def _require(self, user_id: str, activity_id: str) -> Activity:
    72	        activity = await self.session.get(Activity, activity_id)
    73	        if activity is None or activity.user_id != user_id:
    74	            raise NotFoundError("Activity not found")
    75	        return activity

exec
/bin/zsh -lc "nl -ba apps/focal/server/app/services/activity_instances.py | sed -n '1,220p'" in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
     1	from sqlalchemy import select
     2	from sqlalchemy.ext.asyncio import AsyncSession
     3	
     4	from app.errors import NotFoundError, RelatedRecordNotFoundError
     5	from app.models.activities import Activity
     6	from app.models.activity_instances import ActivityInstance
     7	from app.models.bookings import Booking
     8	from app.models.projects import Project
     9	from app.schemas.activity_instances import (
    10	    ActivityInstanceCreate,
    11	    ActivityInstanceRead,
    12	    ActivityInstanceSyncRequest,
    13	    ActivityInstanceUpdate,
    14	)
    15	
    16	_DEFAULT_BOOKING_COLOR = "#f43f5e"
    17	
    18	
    19	class ActivityInstancesService:
    20	    """Activity-instance CRUD plus the calendar-booking lifecycle bound to it: setting
    21	    both dates on an instance creates (or re-times) an automatic booking, clearing them
    22	    removes it, and deleting the instance removes the booking with it. ``sync``
    23	    reconciles the instance list with the activity's planned yearly count. Mirrors
    24	    legacy ``/api/activity-instances`` (routes.ts:4091) but scopes every lookup by
    25	    ``user_id`` — the legacy handlers trusted the client-sent ids unscoped."""
    26	
    27	    def __init__(self, session: AsyncSession) -> None:
    28	        self.session = session
    29	
    30	    async def list_instances(self, user_id: str, activity_id: str) -> list[ActivityInstanceRead]:
    31	        result = await self.session.execute(
    32	            select(ActivityInstance)
    33	            .where(
    34	                ActivityInstance.user_id == user_id,
    35	                ActivityInstance.activity_id == activity_id,
    36	            )
    37	            .order_by(ActivityInstance.sort_order)
    38	        )
    39	        return [ActivityInstanceRead.model_validate(row) for row in result.scalars().all()]
    40	
    41	    async def get_instance(self, user_id: str, instance_id: str) -> ActivityInstanceRead:
    42	        return ActivityInstanceRead.model_validate(await self._require(user_id, instance_id))
    43	
    44	    async def create_instance(
    45	        self, user_id: str, payload: ActivityInstanceCreate
    46	    ) -> ActivityInstanceRead:
    47	        instance = ActivityInstance(user_id=user_id)
    48	        for field, value in payload.model_dump(exclude_unset=True).items():
    49	            setattr(instance, field, value)
    50	        self.session.add(instance)
    51	        await self.session.commit()
    52	        await self.session.refresh(instance)
    53	        return ActivityInstanceRead.model_validate(instance)
    54	
    55	    async def update_instance(
    56	        self, user_id: str, instance_id: str, payload: ActivityInstanceUpdate
    57	    ) -> ActivityInstanceRead:
    58	        instance = await self._require(user_id, instance_id)
    59	        updates = payload.model_dump(exclude_unset=True)
    60	
    61	        final_name = updates.get("name", instance.name)
    62	        final_start = updates.get("start_date", instance.start_date)
    63	        final_end = updates.get("end_date", instance.end_date)
    64	        dates_changed = final_start != instance.start_date or final_end != instance.end_date
    65	
    66	        # The auto-booking lifecycle: both dates present keeps a booking in sync with the
    67	        # instance; losing either date removes it.
    68	        if final_start and final_end:
    69	            booking = await self._linked_booking(instance)
    70	            if booking is not None:
    71	                if dates_changed or final_name != instance.name:
    72	                    booking.title = final_name
    73	                    booking.start_date = final_start
    74	                    booking.end_date = final_end
    75	            else:
    76	                instance.booking_id = (
    77	                    await self._create_auto_booking(instance, final_name, final_start, final_end)
    78	                ).id
    79	        elif instance.booking_id is not None:
    80	            booking = await self._linked_booking(instance)
    81	            if booking is not None:
    82	                await self.session.delete(booking)
    83	            instance.booking_id = None
    84	
    85	        for field, value in updates.items():
    86	            setattr(instance, field, value)
    87	        await self.session.commit()
    88	        await self.session.refresh(instance)
    89	        return ActivityInstanceRead.model_validate(instance)
    90	
    91	    async def delete_instance(self, user_id: str, instance_id: str) -> None:
    92	        instance = await self._require(user_id, instance_id)
    93	        booking = await self._linked_booking(instance)
    94	        if booking is not None:
    95	            await self.session.delete(booking)
    96	        await self.session.delete(instance)
    97	        await self.session.commit()
    98	
    99	    async def sync_instances(
   100	        self, user_id: str, payload: ActivityInstanceSyncRequest
   101	    ) -> list[ActivityInstanceRead]:
   102	        # The activity must belong to the data owner — a delegated (shared assistant) write must not
   103	        # attach the owner's instances to the CALLER's own activity (and then cascade-delete them by
   104	        # deleting that activity).
   105	        activity = await self.session.get(Activity, payload.activity_id)
   106	        if activity is None or activity.user_id != user_id:
   107	            raise RelatedRecordNotFoundError("Related record not found")
   108	        result = await self.session.execute(
   109	            select(ActivityInstance)
   110	            .where(
   111	                ActivityInstance.user_id == user_id,
   112	                ActivityInstance.activity_id == payload.activity_id,
   113	            )
   114	            .order_by(ActivityInstance.sort_order)
   115	        )
   116	        current = list(result.scalars().all())
   117	
   118	        if payload.count > len(current):
   119	            for index in range(len(current), payload.count):
   120	                self.session.add(
   121	                    ActivityInstance(
   122	                        user_id=user_id,
   123	                        activity_id=payload.activity_id,
   124	                        name=f"{payload.activity_name} #{index + 1}",
   125	                        hours_planned=payload.hours_per_activity,
   126	                        sort_order=index,
   127	                    )
   128	                )
   129	        elif payload.count < len(current):
   130	            # Surplus instances go from the end, each taking its auto booking with it.
   131	            for instance in current[payload.count :]:
   132	                booking = await self._linked_booking(instance)
   133	                if booking is not None:
   134	                    await self.session.delete(booking)
   135	                await self.session.delete(instance)
   136	
   137	        await self.session.commit()
   138	        return await self.list_instances(user_id, payload.activity_id)
   139	
   140	    async def _require(self, user_id: str, instance_id: str) -> ActivityInstance:
   141	        instance = await self.session.get(ActivityInstance, instance_id)
   142	        if instance is None or instance.user_id != user_id:
   143	            raise NotFoundError("Activity instance not found")
   144	        return instance
   145	
   146	    async def _linked_booking(self, instance: ActivityInstance) -> Booking | None:
   147	        if instance.booking_id is None:
   148	            return None
   149	        return await self.session.get(Booking, instance.booking_id)
   150	
   151	    async def _create_auto_booking(
   152	        self, instance: ActivityInstance, title: str, start_date, end_date
   153	    ) -> Booking:
   154	        # The booking inherits the parent activity's project linkage and color, and the
   155	        # project's mission/provision type — same enrichment the legacy handler did.
   156	        activity = await self.session.get(Activity, instance.activity_id)
   157	        project_type = None
   158	        if activity is not None and activity.project_id is not None:
   159	            project = await self.session.get(Project, activity.project_id)
   160	            project_type = project.project_type if project is not None else None
   161	        description = (
   162	            f'Автоматическая бронь для мероприятия "{activity.name}"'
   163	            if activity is not None
   164	            else "Автоматическая бронь"
   165	        )
   166	        booking = Booking(
   167	            user_id=instance.user_id,
   168	            title=title,
   169	            description=description,
   170	            project_id=activity.project_id if activity is not None else None,
   171	            project_type=project_type,
   172	            product_id=activity.product_id if activity is not None else None,
   173	            start_date=start_date,
   174	            end_date=end_date,
   175	            color=(activity.color if activity is not None and activity.color else None)
   176	            or _DEFAULT_BOOKING_COLOR,
   177	            source_type="activity_instance",
   178	            source_id=instance.id,
   179	        )
   180	        self.session.add(booking)
   181	        await self.session.flush()
   182	        return booking

exec
/bin/zsh -lc "nl -ba apps/focal/server/app/api/activity_instances.py | sed -n '1,180p'" in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
     1	from collections.abc import AsyncIterator
     2	
     3	from fastapi import APIRouter, Depends, Query, status
     4	
     5	from app.data_scope import DataDomain, data_owner_dep
     6	from app.db import get_sessionmaker
     7	from app.schemas.activity_instances import (
     8	    ActivityInstanceCreate,
     9	    ActivityInstanceRead,
    10	    ActivityInstanceSyncRequest,
    11	    ActivityInstanceUpdate,
    12	)
    13	from app.services.activity_instances import ActivityInstancesService
    14	
    15	router = APIRouter(prefix="/api/activity-instances", tags=["activity-instances"])
    16	
    17	_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
    18	_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
    19	
    20	
    21	async def get_activity_instances_service() -> AsyncIterator[ActivityInstancesService]:
    22	    # DB-backed only: the booking lifecycle and cascade behavior are DB-semantic.
    23	    async with get_sessionmaker()() as session:
    24	        yield ActivityInstancesService(session)
    25	
    26	
    27	@router.get("", response_model=list[ActivityInstanceRead])
    28	async def list_activity_instances(
    29	    activity_id: str = Query(alias="activityId"),
    30	    user_id: str = Depends(_owner_read),
    31	    service: ActivityInstancesService = Depends(get_activity_instances_service),
    32	) -> list[ActivityInstanceRead]:
    33	    return await service.list_instances(user_id, activity_id)
    34	
    35	
    36	@router.post("", response_model=ActivityInstanceRead, status_code=status.HTTP_201_CREATED)
    37	async def create_activity_instance(
    38	    payload: ActivityInstanceCreate,
    39	    user_id: str = Depends(_owner_write),
    40	    service: ActivityInstancesService = Depends(get_activity_instances_service),
    41	) -> ActivityInstanceRead:
    42	    return await service.create_instance(user_id, payload)
    43	
    44	
    45	# Static /sync is declared before /{instance_id} so the id route can't shadow it.
    46	@router.post("/sync", response_model=list[ActivityInstanceRead])
    47	async def sync_activity_instances(
    48	    payload: ActivityInstanceSyncRequest,
    49	    user_id: str = Depends(_owner_write),
    50	    service: ActivityInstancesService = Depends(get_activity_instances_service),
    51	) -> list[ActivityInstanceRead]:
    52	    return await service.sync_instances(user_id, payload)
    53	
    54	
    55	@router.get("/{instance_id}", response_model=ActivityInstanceRead)
    56	async def get_activity_instance(
    57	    instance_id: str,
    58	    user_id: str = Depends(_owner_read),
    59	    service: ActivityInstancesService = Depends(get_activity_instances_service),
    60	) -> ActivityInstanceRead:
    61	    return await service.get_instance(user_id, instance_id)
    62	
    63	
    64	@router.patch("/{instance_id}", response_model=ActivityInstanceRead)
    65	async def update_activity_instance(
    66	    instance_id: str,
    67	    payload: ActivityInstanceUpdate,
    68	    user_id: str = Depends(_owner_write),
    69	    service: ActivityInstancesService = Depends(get_activity_instances_service),
    70	) -> ActivityInstanceRead:
    71	    return await service.update_instance(user_id, instance_id, payload)
    72	
    73	
    74	@router.delete("/{instance_id}")
    75	async def delete_activity_instance(
    76	    instance_id: str,
    77	    user_id: str = Depends(_owner_write),
    78	    service: ActivityInstancesService = Depends(get_activity_instances_service),
    79	) -> dict[str, bool]:
    80	    await service.delete_instance(user_id, instance_id)
    81	    return {"success": True}

exec
/bin/zsh -lc "nl -ba apps/focal/server/app/schemas/activity_instances.py | sed -n '1,220p'" in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
     1	from datetime import date, datetime
     2	
     3	from pydantic import BaseModel, ConfigDict, Field
     4	from pydantic.alias_generators import to_camel
     5	
     6	
     7	class _Camel(BaseModel):
     8	    # Accept legacy camelCase (and snake_case) on input; serialize camelCase via by_alias.
     9	    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)
    10	
    11	
    12	class ActivityInstanceCreate(_Camel):
    13	    activity_id: str
    14	    name: str = Field(min_length=1)
    15	    start_date: date | None = None
    16	    end_date: date | None = None
    17	    hours_planned: int | None = None
    18	    sort_order: int | None = None
    19	
    20	
    21	class ActivityInstanceUpdate(_Camel):
    22	    # Dates are clearable: an explicit null removes the date (and with it the auto
    23	    # booking), while an omitted field keeps the stored value.
    24	    name: str | None = Field(default=None, min_length=1)
    25	    start_date: date | None = None
    26	    end_date: date | None = None
    27	    hours_planned: int | None = None
    28	    sort_order: int | None = None
    29	
    30	
    31	class ActivityInstanceSyncRequest(_Camel):
    32	    """Reconcile the instance list with the activity's planned yearly count: missing
    33	    instances are appended as "<activityName> #N", surplus ones are removed from the
    34	    end together with their auto bookings."""
    35	
    36	    activity_id: str
    37	    count: int = Field(ge=0)
    38	    hours_per_activity: int = 0
    39	    activity_name: str = Field(min_length=1)
    40	
    41	
    42	class ActivityInstanceRead(_Camel):
    43	    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True, from_attributes=True)
    44	
    45	    id: str
    46	    user_id: str
    47	    activity_id: str
    48	    name: str
    49	    start_date: date | None
    50	    end_date: date | None
    51	    hours_planned: int | None
    52	    booking_id: str | None
    53	    sort_order: int | None
    54	    created_at: datetime
    55	    updated_at: datetime

exec
/bin/zsh -lc 'rg "create_activity_instance|/activity-instances|ActivityInstanceCreate|activity_instances" apps/focal/client/src apps/focal/server/tests -n' in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
apps/focal/server/tests/test_activity_instances_db.py:1:"""DB-backed integration tests for /api/activity-instances: CRUD, the automatic
apps/focal/server/tests/test_activity_instances_db.py:17:from app.api.activity_instances import get_activity_instances_service
apps/focal/server/tests/test_activity_instances_db.py:24:from app.services.activity_instances import ActivityInstancesService
apps/focal/server/tests/test_activity_instances_db.py:62:    app.dependency_overrides[get_activity_instances_service] = _override_service
apps/focal/server/tests/test_activity_instances_db.py:68:                    "TRUNCATE focal.activity_instances, focal.bookings, "
apps/focal/server/tests/test_activity_instances_db.py:75:    app.dependency_overrides.pop(get_activity_instances_service, None)
apps/focal/server/tests/test_activity_instances_db.py:114:    response = client.post("/api/activity-instances", headers=_h(user), json=payload)
apps/focal/server/tests/test_activity_instances_db.py:123:    assert client.get("/api/activity-instances", headers=_h("u")).status_code == 422
apps/focal/server/tests/test_activity_instances_db.py:125:        "/api/activity-instances", headers=_h("u"), params={"activityId": activity_id}
apps/focal/server/tests/test_activity_instances_db.py:143:    url = f"/api/activity-instances/{instance['id']}"
apps/focal/server/tests/test_activity_instances_db.py:148:        "/api/activity-instances", headers=_h("stranger"), params={"activityId": activity_id}
apps/focal/server/tests/test_activity_instances_db.py:157:        f"/api/activity-instances/{instance['id']}",
apps/focal/server/tests/test_activity_instances_db.py:177:        f"/api/activity-instances/{instance['id']}",
apps/focal/server/tests/test_activity_instances_db.py:182:        f"/api/activity-instances/{instance['id']}",
apps/focal/server/tests/test_activity_instances_db.py:196:        f"/api/activity-instances/{instance['id']}",
apps/focal/server/tests/test_activity_instances_db.py:201:        f"/api/activity-instances/{instance['id']}",
apps/focal/server/tests/test_activity_instances_db.py:214:        f"/api/activity-instances/{instance['id']}",
apps/focal/server/tests/test_activity_instances_db.py:218:    response = client.delete(f"/api/activity-instances/{instance['id']}", headers=_h("u"))
apps/focal/server/tests/test_activity_instances_db.py:221:        client.get(f"/api/activity-instances/{instance['id']}", headers=_h("u")).status_code == 404
apps/focal/server/tests/test_activity_instances_db.py:229:        "/api/activity-instances/sync",
apps/focal/server/tests/test_activity_instances_db.py:241:        "/api/activity-instances/sync",
apps/focal/server/tests/test_activity_instances_db.py:246:        "/api/activity-instances", headers=_h("u"), params={"activityId": activity_id}
apps/focal/server/tests/test_activity_instances_db.py:250:        f"/api/activity-instances/{last['id']}",
apps/focal/server/tests/test_activity_instances_db.py:255:        "/api/activity-instances/sync",
apps/focal/server/tests/test_etl_migrate_legacy.py:42:        "activity_instances": {"activities"},
apps/focal/server/tests/test_etl_migrate_legacy.py:48:    assert order.index("projects") < order.index("activities") < order.index("activity_instances")
apps/focal/server/tests/test_route_scope_partition.py:23:    "activity_instances",
apps/focal/server/tests/test_ai_entity_handlers_db.py:70:    "focal.projects, focal.activities, focal.activity_instances, focal.habits, "
apps/focal/server/tests/test_calendar_scope_db.py:629:    from app.schemas.activity_instances import ActivityInstanceSyncRequest
apps/focal/server/tests/test_calendar_scope_db.py:631:    from app.services.activity_instances import ActivityInstancesService
apps/focal/client/src/api/openapi.d.ts:262:    "/api/activity-instances": {
apps/focal/client/src/api/openapi.d.ts:270:        get: operations["list_activity_instances_api_activity_instances_get"];
apps/focal/client/src/api/openapi.d.ts:273:        post: operations["create_activity_instance_api_activity_instances_post"];
apps/focal/client/src/api/openapi.d.ts:280:    "/api/activity-instances/sync": {
apps/focal/client/src/api/openapi.d.ts:290:        post: operations["sync_activity_instances_api_activity_instances_sync_post"];
apps/focal/client/src/api/openapi.d.ts:297:    "/api/activity-instances/{instance_id}": {
apps/focal/client/src/api/openapi.d.ts:305:        get: operations["get_activity_instance_api_activity_instances__instance_id__get"];
apps/focal/client/src/api/openapi.d.ts:309:        delete: operations["delete_activity_instance_api_activity_instances__instance_id__delete"];
apps/focal/client/src/api/openapi.d.ts:313:        patch: operations["update_activity_instance_api_activity_instances__instance_id__patch"];
apps/focal/client/src/api/openapi.d.ts:2281:        /** ActivityInstanceCreate */
apps/focal/client/src/api/openapi.d.ts:2282:        ActivityInstanceCreate: {
apps/focal/client/src/api/openapi.d.ts:6147:    list_activity_instances_api_activity_instances_get: {
apps/focal/client/src/api/openapi.d.ts:6182:    create_activity_instance_api_activity_instances_post: {
apps/focal/client/src/api/openapi.d.ts:6196:                "application/json": components["schemas"]["ActivityInstanceCreate"];
apps/focal/client/src/api/openapi.d.ts:6220:    sync_activity_instances_api_activity_instances_sync_post: {
apps/focal/client/src/api/openapi.d.ts:6258:    get_activity_instance_api_activity_instances__instance_id__get: {
apps/focal/client/src/api/openapi.d.ts:6294:    delete_activity_instance_api_activity_instances__instance_id__delete: {
apps/focal/client/src/api/openapi.d.ts:6332:    update_activity_instance_api_activity_instances__instance_id__patch: {
apps/focal/client/src/api/activityInstances.ts:15:  apiFetch<ActivityInstance[]>('/api/activity-instances', { query: { activityId, calendarId } })
apps/focal/client/src/api/activityInstances.ts:22:  apiFetch<ActivityInstance>(`/api/activity-instances/${id}`, {
apps/focal/client/src/api/activityInstances.ts:34:  apiFetch<ActivityInstance[]>('/api/activity-instances/sync', {

exec
/bin/zsh -lc "nl -ba apps/focal/server/app/models/activity_instances.py | sed -n '1,180p'" in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
     1	from datetime import date
     2	from uuid import uuid4
     3	
     4	from sqlalchemy import Date, ForeignKey, Integer, String
     5	from sqlalchemy.orm import Mapped, mapped_column
     6	
     7	from app.models.base import Base, TimestampMixin
     8	
     9	
    10	class ActivityInstance(TimestampMixin, Base):
    11	    __tablename__ = "activity_instances"
    12	    __table_args__ = ({"schema": "focal"},)
    13	
    14	    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid4()))
    15	    user_id: Mapped[str] = mapped_column(String, index=True, nullable=False)
    16	    activity_id: Mapped[str] = mapped_column(
    17	        String, ForeignKey("focal.activities.id", ondelete="CASCADE"), index=True, nullable=False
    18	    )
    19	    name: Mapped[str] = mapped_column(String(255), nullable=False)
    20	    start_date: Mapped[date | None] = mapped_column(Date)
    21	    end_date: Mapped[date | None] = mapped_column(Date)
    22	    hours_planned: Mapped[int | None] = mapped_column(Integer, default=0)
    23	    booking_id: Mapped[str | None] = mapped_column(
    24	        String, ForeignKey("focal.bookings.id", ondelete="SET NULL"), index=True
    25	    )
    26	    sort_order: Mapped[int | None] = mapped_column(Integer, default=0)

exec
/bin/zsh -lc 'rg "activity_id" apps/focal/server/app/services apps/focal/server/app/api apps/focal/server/tests/test_calendar_scope_db.py -n' in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
apps/focal/server/tests/test_calendar_scope_db.py:648:                        activity_id=caller_activity.id, count=1, activity_name="a"
apps/focal/server/app/services/activity_instances.py:30:    async def list_instances(self, user_id: str, activity_id: str) -> list[ActivityInstanceRead]:
apps/focal/server/app/services/activity_instances.py:35:                ActivityInstance.activity_id == activity_id,
apps/focal/server/app/services/activity_instances.py:105:        activity = await self.session.get(Activity, payload.activity_id)
apps/focal/server/app/services/activity_instances.py:112:                ActivityInstance.activity_id == payload.activity_id,
apps/focal/server/app/services/activity_instances.py:123:                        activity_id=payload.activity_id,
apps/focal/server/app/services/activity_instances.py:138:        return await self.list_instances(user_id, payload.activity_id)
apps/focal/server/app/services/activity_instances.py:156:        activity = await self.session.get(Activity, instance.activity_id)
apps/focal/server/app/services/backup.py:189:                activity_id=remap(row.get("activityId")),
apps/focal/server/app/services/backup.py:198:                activity_id=remap(row.get("activityId")),
apps/focal/server/app/services/backup.py:210:                activity_id=remap(row.get("activityId")),
apps/focal/server/app/services/activities.py:26:    async def get_activity(self, user_id: str, activity_id: str) -> ActivityRead:
apps/focal/server/app/services/activities.py:27:        return ActivityRead.model_validate(await self._require(user_id, activity_id))
apps/focal/server/app/services/activities.py:43:        self, user_id: str, activity_id: str, payload: ActivityUpdate
apps/focal/server/app/services/activities.py:45:        activity = await self._require(user_id, activity_id)
apps/focal/server/app/services/activities.py:66:    async def delete_activity(self, user_id: str, activity_id: str) -> None:
apps/focal/server/app/services/activities.py:67:        activity = await self._require(user_id, activity_id)
apps/focal/server/app/services/activities.py:71:    async def _require(self, user_id: str, activity_id: str) -> Activity:
apps/focal/server/app/services/activities.py:72:        activity = await self.session.get(Activity, activity_id)
apps/focal/server/app/api/activity_instances.py:29:    activity_id: str = Query(alias="activityId"),
apps/focal/server/app/api/activity_instances.py:33:    return await service.list_instances(user_id, activity_id)
apps/focal/server/app/api/activities.py:39:@router.get("/{activity_id}", response_model=ActivityRead)
apps/focal/server/app/api/activities.py:41:    activity_id: str,
apps/focal/server/app/api/activities.py:45:    return await service.get_activity(user_id, activity_id)
apps/focal/server/app/api/activities.py:48:@router.patch("/{activity_id}", response_model=ActivityRead)
apps/focal/server/app/api/activities.py:50:    activity_id: str,
apps/focal/server/app/api/activities.py:55:    return await service.update_activity(user_id, activity_id, payload)
apps/focal/server/app/api/activities.py:58:@router.delete("/{activity_id}")
apps/focal/server/app/api/activities.py:60:    activity_id: str,
apps/focal/server/app/api/activities.py:64:    await service.delete_activity(user_id, activity_id)
apps/focal/server/app/services/calendar.py:66:    "activity_id",
apps/focal/server/app/services/calendar.py:179:            user_id, payload.project_id, payload.product_id, payload.activity_id
apps/focal/server/app/services/calendar.py:182:            user_id, payload.project_id, payload.product_id, payload.activity_id
apps/focal/server/app/services/calendar.py:206:            activity_id=payload.activity_id,
apps/focal/server/app/services/calendar.py:304:            data.get("activity_id") is not None
apps/focal/server/app/services/calendar.py:305:            and await self._owned_activity(user_id, data["activity_id"]) is None
apps/focal/server/app/services/calendar.py:324:            user_id, event.project_id, event.product_id, event.activity_id
apps/focal/server/app/services/calendar.py:391:            user_id, merged["project_id"], merged["product_id"], merged["activity_id"]
apps/focal/server/app/services/calendar.py:400:            user_id, merged["project_id"], merged["product_id"], merged["activity_id"]
apps/focal/server/app/services/calendar.py:465:        activity_id = pick("activity_id")
apps/focal/server/app/services/calendar.py:466:        await self._require_owned_link(user_id, project_id, product_id, activity_id)
apps/focal/server/app/services/calendar.py:467:        level, score = await self._compute_priority(user_id, project_id, product_id, activity_id)
apps/focal/server/app/services/calendar.py:499:            activity_id=activity_id,
apps/focal/server/app/services/calendar.py:644:    async def _owned_activity(self, user_id: str, activity_id: str | None) -> Activity | None:
apps/focal/server/app/services/calendar.py:645:        if not activity_id:
apps/focal/server/app/services/calendar.py:647:        activity = await self.session.get(Activity, activity_id)
apps/focal/server/app/services/calendar.py:657:        activity_id: str | None,
apps/focal/server/app/services/calendar.py:662:        if activity_id is not None and await self._owned_activity(user_id, activity_id) is None:
apps/focal/server/app/services/calendar.py:670:        activity_id: str | None,
apps/focal/server/app/services/calendar.py:674:        activity = await self._owned_activity(user_id, activity_id)
apps/focal/server/app/services/calendar.py:693:        only — activity_id never affects the filter fields)."""
apps/focal/server/app/services/calendar.py:800:        # Resolve from the STORED project_id/product_id only (not activity_id), scoped to the user's
apps/focal/server/app/services/tasks.py:59:            user_id, payload.project_id, payload.product_id, payload.activity_id
apps/focal/server/app/services/tasks.py:65:            activity_id=payload.activity_id,
apps/focal/server/app/services/tasks.py:81:            activity_id=payload.activity_id,
apps/focal/server/app/services/tasks.py:108:            data.get("activity_id") is not None
apps/focal/server/app/services/tasks.py:109:            and await self._owned_activity(user_id, data["activity_id"]) is None
apps/focal/server/app/services/tasks.py:126:            activity_id=task.activity_id,
apps/focal/server/app/services/tasks.py:157:    async def _owned_activity(self, user_id: str, activity_id: str | None) -> Activity | None:
apps/focal/server/app/services/tasks.py:158:        if not activity_id:
apps/focal/server/app/services/tasks.py:160:        activity = await self.session.get(Activity, activity_id)
apps/focal/server/app/services/tasks.py:170:        activity_id: str | None,
apps/focal/server/app/services/tasks.py:175:        if activity_id is not None and await self._owned_activity(user_id, activity_id) is None:
apps/focal/server/app/services/tasks.py:191:        activity_id: str | None,
apps/focal/server/app/services/tasks.py:211:        activity_id: str | None,
apps/focal/server/app/services/tasks.py:216:            user_id, project_id, product_id, activity_id

exec
/bin/zsh -lc "nl -ba apps/focal/server/app/services/goals.py | sed -n '1,300p'" in /Users/allosta/Desktop/allosta/superapp-slice2
exec
/bin/zsh -lc "nl -ba apps/focal/server/app/services/tasks.py | sed -n '1,280p'" in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
     1	from sqlalchemy import select
     2	from sqlalchemy.ext.asyncio import AsyncSession
     3	
     4	from app.errors import NotFoundError
     5	from app.models.goals import Goal
     6	from app.models.projects import Project
     7	from app.schemas.goals import GoalCreate, GoalRead, GoalUpdate
     8	
     9	
    10	class GoalsService:
    11	    """Goal CRUD against ``focal.goals``, tenant-scoped to the authenticated user. Backs the
    12	    Edit-Project modal's Goals section, where a goal links to a project via ``project_id``."""
    13	
    14	    def __init__(self, session: AsyncSession) -> None:
    15	        self.session = session
    16	
    17	    async def list_goals(self, user_id: str) -> list[GoalRead]:
    18	        result = await self.session.execute(
    19	            select(Goal).where(Goal.user_id == user_id).order_by(Goal.created_at)
    20	        )
    21	        return [GoalRead.model_validate(row) for row in result.scalars().all()]
    22	
    23	    async def get_goal(self, user_id: str, goal_id: str) -> GoalRead:
    24	        return GoalRead.model_validate(await self._require(user_id, goal_id))
    25	
    26	    async def create_goal(self, user_id: str, payload: GoalCreate) -> GoalRead:
    27	        if payload.project_id is not None:
    28	            await self._require_project(user_id, payload.project_id)
    29	        goal = Goal(
    30	            user_id=user_id,
    31	            title=payload.title,
    32	            description=payload.description,
    33	            color=payload.color or "#3b82f6",
    34	            project_id=payload.project_id,
    35	            parent_goal_id=payload.parent_goal_id,
    36	            status=payload.status or "active",
    37	            progress=payload.progress or 0,
    38	            position_x=payload.position_x,
    39	            position_y=payload.position_y,
    40	        )
    41	        self.session.add(goal)
    42	        await self.session.commit()
    43	        await self.session.refresh(goal)
    44	        return GoalRead.model_validate(goal)
    45	
    46	    async def update_goal(self, user_id: str, goal_id: str, payload: GoalUpdate) -> GoalRead:
    47	        goal = await self._require(user_id, goal_id)
    48	        # A non-null project_id means "link" — verify it's the caller's project. An explicit null
    49	        # (in the unset-excluded dump) flows through as an unlink; that needs no ownership check.
    50	        if payload.project_id is not None:
    51	            await self._require_project(user_id, payload.project_id)
    52	        for field, value in payload.model_dump(exclude_unset=True).items():
    53	            setattr(goal, field, value)
    54	        await self.session.commit()
    55	        await self.session.refresh(goal)
    56	        return GoalRead.model_validate(goal)
    57	
    58	    async def delete_goal(self, user_id: str, goal_id: str) -> None:
    59	        goal = await self._require(user_id, goal_id)
    60	        await self.session.delete(goal)
    61	        await self.session.commit()
    62	
    63	    async def _require(self, user_id: str, goal_id: str) -> Goal:
    64	        goal = await self.session.get(Goal, goal_id)
    65	        if goal is None or goal.user_id != user_id:
    66	            raise NotFoundError("Goal not found")
    67	        return goal
    68	
    69	    async def _require_project(self, user_id: str, project_id: str) -> None:
    70	        project = await self.session.get(Project, project_id)
    71	        if project is None or project.user_id != user_id:
    72	            raise NotFoundError("Project not found")

 succeeded in 0ms:
     1	from datetime import UTC, date, datetime
     2	
     3	from sqlalchemy import and_, or_, select
     4	from sqlalchemy.ext.asyncio import AsyncSession
     5	
     6	from app.domain.completion import transition_completed_at
     7	from app.domain.daterange import get_date_range
     8	from app.domain.priority import max_hierarchy_priority, priority_score, urgency_score
     9	from app.errors import NotFoundError, RelatedRecordNotFoundError
    10	from app.models.activities import Activity
    11	from app.models.life_spheres import LifeSphere
    12	from app.models.projects import Project
    13	from app.models.tasks import Task
    14	from app.schemas.tasks import EnrichedTaskRead, TaskCreate, TaskRead, TaskUpdate
    15	
    16	
    17	class TasksService:
    18	    """Task CRUD against ``focal.tasks``, tenant-scoped to the user. Ports legacy
    19	    ``/api/tasks`` (focal/server/routes.ts:2976) + the priority/completion logic in storage.ts."""
    20	
    21	    def __init__(self, session: AsyncSession) -> None:
    22	        self.session = session
    23	
    24	    async def list_tasks(
    25	        self, user_id: str, *, start: str | None, end: str | None, today: date
    26	    ) -> list[EnrichedTaskRead]:
    27	        window_start, window_end = get_date_range(start, end, today=today)
    28	        stmt = (
    29	            select(Task, Project)
    30	            .outerjoin(
    31	                Project,
    32	                and_(Task.project_id == Project.id, Project.user_id == user_id),
    33	            )
    34	            .where(
    35	                Task.user_id == user_id,
    36	                or_(
    37	                    and_(Task.due_date >= window_start, Task.due_date <= window_end),
    38	                    Task.due_date.is_(None),
    39	                ),
    40	            )
    41	            .order_by(Task.created_at.desc())
    42	        )
    43	        rows = (await self.session.execute(stmt)).all()
    44	        products = await self._products_set(user_id)
    45	        enriched: list[EnrichedTaskRead] = []
    46	        for task, project in rows:
    47	            has_products = project is not None and project.id in products
    48	            enriched.append(self._enrich(task, project, project_has_products=has_products))
    49	        return enriched
    50	
    51	    async def get_task(self, user_id: str, task_id: str) -> EnrichedTaskRead:
    52	        task = await self._require(user_id, task_id)
    53	        project = await self._owned_project(user_id, task.project_id) if task.project_id else None
    54	        has_products = await self._project_has_products(user_id, task.project_id)
    55	        return self._enrich(task, project, project_has_products=has_products)
    56	
    57	    async def create_task(self, user_id: str, payload: TaskCreate, *, today: date) -> TaskRead:
    58	        await self._require_owned_link(
    59	            user_id, payload.project_id, payload.product_id, payload.activity_id
    60	        )
    61	        score, level = await self._compute_priority(
    62	            user_id,
    63	            project_id=payload.project_id,
    64	            product_id=payload.product_id,
    65	            activity_id=payload.activity_id,
    66	            due_date=payload.due_date,
    67	            today=today,
    68	        )
    69	        task = Task(
    70	            user_id=user_id,
    71	            title=payload.title,
    72	            description=payload.description,
    73	            due_date=payload.due_date,
    74	            due_time=payload.due_time,
    75	            priority=payload.priority if payload.priority is not None else "medium",
    76	            tags=payload.tags,
    77	            contact_id=payload.contact_id,
    78	            goal_id=payload.goal_id,
    79	            project_id=payload.project_id,
    80	            product_id=payload.product_id,
    81	            activity_id=payload.activity_id,
    82	            priority_score=score,
    83	            priority_level=level,
    84	        )
    85	        self.session.add(task)
    86	        await self.session.commit()
    87	        await self.session.refresh(task)
    88	        return TaskRead.model_validate(task)
    89	
    90	    async def update_task(
    91	        self, user_id: str, task_id: str, payload: TaskUpdate, *, today: date
    92	    ) -> TaskRead:
    93	        task = await self._require(user_id, task_id)
    94	        data = payload.model_dump(exclude_unset=True)
    95	        # `completed: null` means "no completion change" (not "write NULL"); the transition below is
    96	        # the only thing that may touch the completion state.
    97	        if data.get("completed") is None:
    98	            data.pop("completed", None)
    99	
   100	        # Validate ownership of any link the client is setting to a non-null value.
   101	        for field in ("project_id", "product_id"):
   102	            if (
   103	                data.get(field) is not None
   104	                and await self._owned_project(user_id, data[field]) is None
   105	            ):
   106	                raise RelatedRecordNotFoundError("Related record not found")
   107	        if (
   108	            data.get("activity_id") is not None
   109	            and await self._owned_activity(user_id, data["activity_id"]) is None
   110	        ):
   111	            raise RelatedRecordNotFoundError("Related record not found")
   112	
   113	        # completed_at moves only on a real completed transition (read the OLD value first).
   114	        completed_patch = transition_completed_at(
   115	            task.completed, data.get("completed"), now=datetime.now(UTC)
   116	        )
   117	        for field, value in data.items():
   118	            setattr(task, field, value)
   119	        for field, value in completed_patch.items():
   120	            setattr(task, field, value)
   121	
   122	        score, level = await self._compute_priority(
   123	            user_id,
   124	            project_id=task.project_id,
   125	            product_id=task.product_id,
   126	            activity_id=task.activity_id,
   127	            due_date=task.due_date,
   128	            today=today,
   129	        )
   130	        task.priority_score = score
   131	        task.priority_level = level
   132	        await self.session.commit()
   133	        await self.session.refresh(task)
   134	        return TaskRead.model_validate(task)
   135	
   136	    async def delete_task(self, user_id: str, task_id: str) -> None:
   137	        task = await self._require(user_id, task_id)
   138	        await self.session.delete(task)
   139	        await self.session.commit()
   140	
   141	    # --- helpers -------------------------------------------------------------
   142	
   143	    async def _require(self, user_id: str, task_id: str) -> Task:
   144	        task = await self.session.get(Task, task_id)
   145	        if task is None or task.user_id != user_id:
   146	            raise NotFoundError("Task not found")
   147	        return task
   148	
   149	    async def _owned_project(self, user_id: str, project_id: str | None) -> Project | None:
   150	        if not project_id:
   151	            return None
   152	        project = await self.session.get(Project, project_id)
   153	        if project is None or project.user_id != user_id:
   154	            return None
   155	        return project
   156	
   157	    async def _owned_activity(self, user_id: str, activity_id: str | None) -> Activity | None:
   158	        if not activity_id:
   159	            return None
   160	        activity = await self.session.get(Activity, activity_id)
   161	        if activity is None or activity.user_id != user_id:
   162	            return None
   163	        return activity
   164	
   165	    async def _require_owned_link(
   166	        self,
   167	        user_id: str,
   168	        project_id: str | None,
   169	        product_id: str | None,
   170	        activity_id: str | None,
   171	    ) -> None:
   172	        for pid in (project_id, product_id):
   173	            if pid is not None and await self._owned_project(user_id, pid) is None:
   174	                raise RelatedRecordNotFoundError("Related record not found")
   175	        if activity_id is not None and await self._owned_activity(user_id, activity_id) is None:
   176	            raise RelatedRecordNotFoundError("Related record not found")
   177	
   178	    async def _sphere_by_name(self, user_id: str, name: str) -> LifeSphere | None:
   179	        result = await self.session.execute(
   180	            select(LifeSphere)
   181	            .where(LifeSphere.user_id == user_id, LifeSphere.name == name)
   182	            .limit(1)
   183	        )
   184	        return result.scalars().first()
   185	
   186	    async def _hierarchy_context(
   187	        self,
   188	        user_id: str,
   189	        project_id: str | None,
   190	        product_id: str | None,
   191	        activity_id: str | None,
   192	    ) -> tuple[Project | None, Project | None, LifeSphere | None]:
   193	        # `activity` is deferred to Phase 4 (its hierarchy term is 0; the legacy
   194	        # activity?.projectId/productId fallbacks are inert here).
   195	        product = await self._owned_project(user_id, product_id)
   196	        resolved_project_id = project_id
   197	        if resolved_project_id is None and product is not None and product.parent_project_id:
   198	            resolved_project_id = product.parent_project_id
   199	        project = await self._owned_project(user_id, resolved_project_id)
   200	        sphere: LifeSphere | None = None
   201	        if project is not None and project.is_work_time is False and project.sphere:
   202	            sphere = await self._sphere_by_name(user_id, project.sphere)
   203	        return project, product, sphere
   204	
   205	    async def _compute_priority(
   206	        self,
   207	        user_id: str,
   208	        *,
   209	        project_id: str | None,
   210	        product_id: str | None,
   211	        activity_id: str | None,
   212	        due_date: date | None,
   213	        today: date,
   214	    ) -> tuple[float, str]:
   215	        project, product, sphere = await self._hierarchy_context(
   216	            user_id, project_id, product_id, activity_id
   217	        )
   218	        # Nullish-coalescing: the FIRST non-None value (legacy `project?.x ?? product?/sphere?.x ??
   219	        # default`, storage.ts:967,976) — not boolean `or`, and not "first present row".
   220	        project_type: str | None = None
   221	        if project is not None:
   222	            project_type = project.project_type
   223	        if project_type is None and product is not None:
   224	            project_type = product.project_type
   225	        mission = 1.0 if project_type == "mission" else 0.0
   226	        hierarchy = max_hierarchy_priority(
   227	            [
   228	                None,  # activity deferred (Phase 4)
   229	                product.priority if product is not None else None,
   230	                project.priority if project is not None else None,
   231	                sphere.priority if sphere is not None else None,
   232	            ]
   233	        )
   234	        urgency = urgency_score(due_date, today=today)
   235	        # gives_energy falls through to the sphere only when the project's value is None.
   236	        gives_energy: bool | None = None
   237	        if project is not None:
   238	            gives_energy = project.gives_energy
   239	        if gives_energy is None and sphere is not None:
   240	            gives_energy = sphere.gives_energy
   241	        energy = 1.0 if gives_energy else 0.0
   242	        return priority_score(mission, hierarchy, urgency, energy)
   243	
   244	    async def _products_set(self, user_id: str) -> set[str]:
   245	        result = await self.session.execute(
   246	            select(Project.parent_project_id)
   247	            .where(Project.user_id == user_id, Project.parent_project_id.is_not(None))
   248	            .distinct()
   249	        )
   250	        return {row[0] for row in result.all() if row[0] is not None}
   251	
   252	    async def _project_has_products(self, user_id: str, project_id: str | None) -> bool:
   253	        if not project_id:
   254	            return False
   255	        result = await self.session.execute(
   256	            select(Project.id)
   257	            .where(Project.parent_project_id == project_id, Project.user_id == user_id)
   258	            .limit(1)
   259	        )
   260	        return result.first() is not None
   261	
   262	    def _enrich(
   263	        self, task: Task, project: Project | None, *, project_has_products: bool
   264	    ) -> EnrichedTaskRead:
   265	        is_orphan = False
   266	        orphan_reason: str | None = None
   267	        if not task.project_id:
   268	            is_orphan = True
   269	            orphan_reason = "noProject"
   270	        elif project_has_products and not task.product_id:
   271	            is_orphan = True
   272	            orphan_reason = "noProduct"
   273	        data = TaskRead.model_validate(task).model_dump()
   274	        data.update(
   275	            project_type=project.project_type if project is not None else None,
   276	            sphere=project.sphere if project is not None else None,
   277	            project_name=project.name if project is not None else None,
   278	            is_work_time=(
   279	                project.is_work_time
   280	                if project is not None and project.is_work_time is not None

exec
/bin/zsh -lc "nl -ba apps/focal/server/app/services/projects.py | sed -n '1,340p'" in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
     1	from typing import Any
     2	
     3	from sqlalchemy import func, select
     4	from sqlalchemy.ext.asyncio import AsyncSession
     5	
     6	from app.errors import (
     7	    ConflictError,
     8	    InvalidProjectTypeError,
     9	    NotFoundError,
    10	    ParentProjectNotFoundError,
    11	)
    12	from app.models.projects import Project
    13	from app.schemas.projects import ProjectCreate, ProjectRead, ProjectUpdate
    14	
    15	_PROJECT_TYPES = ("mission", "provision")
    16	_BUDGET_BASE_X = 900.0
    17	_BUDGET_BASE_Y = 600.0
    18	_BUDGET_STEP_Y = 80.0
    19	
    20	
    21	class ProjectsService:
    22	    """Project/product CRUD against ``focal.projects``, tenant-scoped to the authenticated user.
    23	    Mirrors legacy ``/api/projects`` create/update/delete (focal/server/routes.ts:3621-3794)."""
    24	
    25	    def __init__(self, session: AsyncSession) -> None:
    26	        self.session = session
    27	
    28	    async def get_project(self, user_id: str, project_id: str) -> ProjectRead:
    29	        return ProjectRead.model_validate(await self._require(user_id, project_id))
    30	
    31	    async def list_projects(self, user_id: str) -> list[ProjectRead]:
    32	        result = await self.session.execute(
    33	            select(Project).where(Project.user_id == user_id).order_by(Project.sort_order)
    34	        )
    35	        return [ProjectRead.model_validate(row) for row in result.scalars().all()]
    36	
    37	    async def list_root_projects(self, user_id: str) -> list[ProjectRead]:
    38	        result = await self.session.execute(
    39	            select(Project)
    40	            .where(Project.user_id == user_id, Project.parent_project_id.is_(None))
    41	            .order_by(Project.sort_order)
    42	        )
    43	        return [ProjectRead.model_validate(row) for row in result.scalars().all()]
    44	
    45	    async def list_products(self, user_id: str, parent_id: str) -> list[ProjectRead]:
    46	        # Legacy filters by parent_project_id AND user_id, so a missing/non-owned parent
    47	        # yields an empty list (no existence leak); no 404.
    48	        result = await self.session.execute(
    49	            select(Project)
    50	            .where(Project.parent_project_id == parent_id, Project.user_id == user_id)
    51	            .order_by(Project.sort_order)
    52	        )
    53	        return [ProjectRead.model_validate(row) for row in result.scalars().all()]
    54	
    55	    async def create_project(self, user_id: str, payload: ProjectCreate) -> ProjectRead:
    56	        # A product (parentProjectId set) inherits attributes from its parent; an explicit body
    57	        # value still wins (legacy `value ?? inherited ?? default`). The parent must be owned.
    58	        inherited: dict[str, Any] = {}
    59	        if payload.parent_project_id is not None:
    60	            parent = await self._owned(user_id, payload.parent_project_id)
    61	            if parent is None:
    62	                raise ParentProjectNotFoundError("Parent project not found")
    63	            inherited = {
    64	                "project_type": parent.project_type,
    65	                "sphere": parent.sphere,
    66	                "is_work_time": parent.is_work_time if parent.is_work_time is not None else True,
    67	                "color": parent.color,
    68	            }
    69	
    70	        # Nullish resolution (legacy `body ?? parent ?? default`): an explicit "" reaches
    71	        # validation and is rejected, rather than silently falling back to the default.
    72	        project_type = payload.project_type
    73	        if project_type is None:
    74	            project_type = inherited.get("project_type")
    75	        if project_type is None:
    76	            project_type = "provision"
    77	        self._validate_project_type(project_type)
    78	
    79	        is_work_time = payload.is_work_time
    80	        if is_work_time is None:
    81	            is_work_time = inherited.get("is_work_time")
    82	        if is_work_time is None:
    83	            is_work_time = True
    84	
    85	        resolved_sphere = payload.sphere if payload.sphere is not None else inherited.get("sphere")
    86	        # Legacy coerces the sphere to null for a work-time project on create.
    87	        sphere = None if is_work_time else resolved_sphere
    88	        color = payload.color
    89	        if color is None:
    90	            color = inherited.get("color")
    91	        if color is None:
    92	            color = "#3b82f6"
    93	
    94	        position_x = payload.position_x or 0.0
    95	        position_y = payload.position_y or 0.0
    96	        if (
    97	            not is_work_time
    98	            and payload.parent_type == "budget"
    99	            and not payload.position_x
   100	            and not payload.position_y
   101	        ):
   102	            # Auto-place a new life-sphere (budget) node below the last one (legacy 3666-3679).
   103	            count = await self._count_budget_projects(user_id)
   104	            position_x = _BUDGET_BASE_X
   105	            position_y = _BUDGET_BASE_Y + count * _BUDGET_STEP_Y
   106	
   107	        project = Project(
   108	            user_id=user_id,
   109	            name=payload.name,
   110	            description=payload.description,
   111	            color=color,
   112	            priority=payload.priority if payload.priority is not None else "medium",
   113	            project_type=project_type,
   114	            sphere=sphere,
   115	            is_work_time=is_work_time,
   116	            position_x=position_x,
   117	            position_y=position_y,
   118	            parent_type=payload.parent_type,
   119	            parent_project_id=payload.parent_project_id,
   120	            status=payload.status or "active",
   121	            sort_order=payload.sort_order or 0,
   122	            allocated_hours=payload.allocated_hours or 0,
   123	            gives_energy=payload.gives_energy if payload.gives_energy is not None else True,
   124	            icon=payload.icon,
   125	        )
   126	        self.session.add(project)
   127	        await self.session.commit()
   128	        await self.session.refresh(project)
   129	        return ProjectRead.model_validate(project)
   130	
   131	    async def update_project(
   132	        self, user_id: str, project_id: str, payload: ProjectUpdate
   133	    ) -> ProjectRead:
   134	        project = await self._require(user_id, project_id)
   135	        data = payload.model_dump(exclude_unset=True)
   136	        if data.get("project_type") is not None:
   137	            self._validate_project_type(data["project_type"])
   138	        if "parent_project_id" in data:
   139	            await self._guard_reparent(user_id, project_id, data["parent_project_id"])
   140	        # Update preserves the sphere (no work-time coercion); reparenting is guarded above.
   141	        for field, value in data.items():
   142	            setattr(project, field, value)
   143	        await self.session.commit()
   144	        await self.session.refresh(project)
   145	        return ProjectRead.model_validate(project)
   146	
   147	    async def delete_project(self, user_id: str, project_id: str) -> None:
   148	        project = await self._require(user_id, project_id)
   149	        # Child products fall via the parent_project_id ON DELETE CASCADE.
   150	        await self.session.delete(project)
   151	        await self.session.commit()
   152	
   153	    def _validate_project_type(self, value: str) -> None:
   154	        if value not in _PROJECT_TYPES:
   155	            raise InvalidProjectTypeError(f"project_type must be one of {_PROJECT_TYPES}")
   156	
   157	    async def _guard_reparent(
   158	        self, user_id: str, project_id: str, new_parent_id: str | None
   159	    ) -> None:
   160	        # Moving to the root (null parent) is always allowed. Otherwise the new parent must be owned
   161	        # by the user and must be neither the project itself nor one of its descendants — either
   162	        # would create a cycle in the project tree.
   163	        if new_parent_id is None:
   164	            return
   165	        if new_parent_id == project_id:
   166	            raise ConflictError("A project cannot be its own parent")
   167	        current: str | None = new_parent_id
   168	        for _ in range(1000):
   169	            if current is None:
   170	                return
   171	            parent = await self._owned(user_id, current)
   172	            if parent is None:
   173	                raise ParentProjectNotFoundError("Parent project not found")
   174	            if parent.id == project_id:
   175	                raise ConflictError("A project cannot be moved under its own descendant")
   176	            current = parent.parent_project_id
   177	
   178	    async def _require(self, user_id: str, project_id: str) -> Project:
   179	        project = await self.session.get(Project, project_id)
   180	        if project is None or project.user_id != user_id:
   181	            raise NotFoundError("Project not found")
   182	        return project
   183	
   184	    async def _owned(self, user_id: str, project_id: str) -> Project | None:
   185	        project = await self.session.get(Project, project_id)
   186	        if project is None or project.user_id != user_id:
   187	            return None
   188	        return project
   189	
   190	    async def _count_budget_projects(self, user_id: str) -> int:
   191	        result = await self.session.execute(
   192	            select(func.count())
   193	            .select_from(Project)
   194	            .where(Project.user_id == user_id, Project.parent_type == "budget")
   195	        )
   196	        return result.scalar_one()

exec
/bin/zsh -lc "nl -ba apps/focal/server/app/services/habits.py | sed -n '1,300p'" in /Users/allosta/Desktop/allosta/superapp-slice2
exec
/bin/zsh -lc "nl -ba apps/focal/server/app/services/time_budgets.py | sed -n '1,320p'" in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
     1	from calendar import isleap
     2	
     3	from sqlalchemy import select
     4	from sqlalchemy.dialects.postgresql import insert as pg_insert
     5	from sqlalchemy.ext.asyncio import AsyncSession
     6	
     7	from app.errors import NotFoundError
     8	from app.models.time_budget import (
     9	    TimeBudgetCategory,
    10	    TimeBudgetItem,
    11	    TimeBudgetSettings,
    12	    TimeBudgetSubcategory,
    13	)
    14	from app.schemas.time_budget import (
    15	    TimeBudgetCategoryCreate,
    16	    TimeBudgetCategoryNode,
    17	    TimeBudgetCategoryRead,
    18	    TimeBudgetCategoryUpdate,
    19	    TimeBudgetItemCreate,
    20	    TimeBudgetItemRead,
    21	    TimeBudgetItemUpdate,
    22	    TimeBudgetSettingsRead,
    23	    TimeBudgetSettingsUpdate,
    24	    TimeBudgetSubcategoryCreate,
    25	    TimeBudgetSubcategoryNode,
    26	    TimeBudgetSubcategoryRead,
    27	    TimeBudgetSubcategoryUpdate,
    28	    TimeBudgetYearRead,
    29	)
    30	
    31	_DEFAULT_CATEGORIES = (
    32	    {"name": "Я", "color": "#3b82f6", "allocated_hours": 1420, "sort_order": 0},
    33	    {"name": "Семья", "color": "#22c55e", "allocated_hours": 1000, "sort_order": 1},
    34	    {"name": "Бизнес", "color": "#f59e0b", "allocated_hours": 2325, "sort_order": 2},
    35	)
    36	
    37	
    38	class TimeBudgetsService:
    39	    """Time-budget settings + the year aggregate, tenant-scoped to the user. Ports the legacy
    40	    get-or-create GET /api/time-budgets/:year (routes.ts:5216) and PATCH settings."""
    41	
    42	    def __init__(self, session: AsyncSession) -> None:
    43	        self.session = session
    44	
    45	    async def get_year(self, user_id: str, year: int) -> TimeBudgetYearRead:
    46	        settings = await self._get_or_create_settings(user_id, year)
    47	        categories = await self._load_tree(settings.id)
    48	        return TimeBudgetYearRead(
    49	            settings=TimeBudgetSettingsRead.model_validate(settings), categories=categories
    50	        )
    51	
    52	    async def update_settings(
    53	        self, user_id: str, settings_id: str, payload: TimeBudgetSettingsUpdate
    54	    ) -> TimeBudgetSettingsRead:
    55	        settings = await self.session.get(TimeBudgetSettings, settings_id)
    56	        if settings is None or settings.user_id != user_id:
    57	            raise NotFoundError("Time budget settings not found")
    58	        for field, value in payload.model_dump(exclude_unset=True).items():
    59	            setattr(settings, field, value)
    60	        await self.session.commit()
    61	        await self.session.refresh(settings)
    62	        return TimeBudgetSettingsRead.model_validate(settings)
    63	
    64	    async def _get_or_create_settings(self, user_id: str, year: int) -> TimeBudgetSettings:
    65	        # Atomic get-or-create on the (user_id, year) unique key: only the request that wins the
    66	        # insert seeds the default categories; a concurrent loser falls through to the re-select.
    67	        stmt = (
    68	            pg_insert(TimeBudgetSettings)
    69	            .values(user_id=user_id, year=year, total_days_in_year=366 if isleap(year) else 365)
    70	            .on_conflict_do_nothing(index_elements=["user_id", "year"])
    71	            .returning(TimeBudgetSettings.id)
    72	        )
    73	        created_id = (await self.session.execute(stmt)).scalar_one_or_none()
    74	        if created_id is not None:
    75	            self.session.add_all(
    76	                [
    77	                    TimeBudgetCategory(user_id=user_id, settings_id=created_id, **category)
    78	                    for category in _DEFAULT_CATEGORIES
    79	                ]
    80	            )
    81	        await self.session.commit()
    82	        return (
    83	            await self.session.execute(
    84	                select(TimeBudgetSettings).where(
    85	                    TimeBudgetSettings.user_id == user_id, TimeBudgetSettings.year == year
    86	                )
    87	            )
    88	        ).scalar_one()
    89	
    90	    async def _load_tree(self, settings_id: str) -> list[TimeBudgetCategoryNode]:
    91	        categories = list(
    92	            (
    93	                await self.session.execute(
    94	                    select(TimeBudgetCategory)
    95	                    .where(TimeBudgetCategory.settings_id == settings_id)
    96	                    .order_by(TimeBudgetCategory.sort_order)
    97	                )
    98	            )
    99	            .scalars()
   100	            .all()
   101	        )
   102	        if not categories:
   103	            return []
   104	        subcategories = list(
   105	            (
   106	                await self.session.execute(
   107	                    select(TimeBudgetSubcategory)
   108	                    .where(TimeBudgetSubcategory.category_id.in_([c.id for c in categories]))
   109	                    .order_by(TimeBudgetSubcategory.sort_order)
   110	                )
   111	            )
   112	            .scalars()
   113	            .all()
   114	        )
   115	        items_by_sub: dict[str, list[TimeBudgetItemRead]] = {}
   116	        if subcategories:
   117	            items = (
   118	                (
   119	                    await self.session.execute(
   120	                        select(TimeBudgetItem)
   121	                        .where(TimeBudgetItem.subcategory_id.in_([s.id for s in subcategories]))
   122	                        .order_by(TimeBudgetItem.sort_order)
   123	                    )
   124	                )
   125	                .scalars()
   126	                .all()
   127	            )
   128	            for item in items:
   129	                if item.subcategory_id is not None:
   130	                    items_by_sub.setdefault(item.subcategory_id, []).append(
   131	                        TimeBudgetItemRead.model_validate(item)
   132	                    )
   133	        subs_by_cat: dict[str, list[TimeBudgetSubcategoryNode]] = {}
   134	        for sub in subcategories:
   135	            node = TimeBudgetSubcategoryNode(
   136	                **TimeBudgetSubcategoryRead.model_validate(sub).model_dump(),
   137	                items=items_by_sub.get(sub.id, []),
   138	            )
   139	            if sub.category_id is not None:
   140	                subs_by_cat.setdefault(sub.category_id, []).append(node)
   141	        return [
   142	            TimeBudgetCategoryNode(
   143	                **TimeBudgetCategoryRead.model_validate(category).model_dump(),
   144	                subcategories=subs_by_cat.get(category.id, []),
   145	            )
   146	            for category in categories
   147	        ]
   148	
   149	    async def _require_owned[M](self, model: type[M], row_id: str, user_id: str) -> M:
   150	        row = await self.session.get(model, row_id)
   151	        if row is None or getattr(row, "user_id", None) != user_id:
   152	            raise NotFoundError("Time budget record not found")
   153	        return row
   154	
   155	    async def create_category(
   156	        self, user_id: str, payload: TimeBudgetCategoryCreate
   157	    ) -> TimeBudgetCategoryRead:
   158	        await self._require_owned(TimeBudgetSettings, payload.settings_id, user_id)
   159	        row = TimeBudgetCategory(user_id=user_id, **payload.model_dump())
   160	        self.session.add(row)
   161	        await self.session.commit()
   162	        await self.session.refresh(row)
   163	        return TimeBudgetCategoryRead.model_validate(row)
   164	
   165	    async def update_category(
   166	        self, user_id: str, category_id: str, payload: TimeBudgetCategoryUpdate
   167	    ) -> TimeBudgetCategoryRead:
   168	        row = await self._require_owned(TimeBudgetCategory, category_id, user_id)
   169	        for field, value in payload.model_dump(exclude_unset=True).items():
   170	            setattr(row, field, value)
   171	        await self.session.commit()
   172	        await self.session.refresh(row)
   173	        return TimeBudgetCategoryRead.model_validate(row)
   174	
   175	    async def delete_category(self, user_id: str, category_id: str) -> None:
   176	        row = await self._require_owned(TimeBudgetCategory, category_id, user_id)
   177	        await self.session.delete(row)  # subcategories + items fall via ON DELETE CASCADE
   178	        await self.session.commit()
   179	
   180	    async def create_subcategory(
   181	        self, user_id: str, payload: TimeBudgetSubcategoryCreate
   182	    ) -> TimeBudgetSubcategoryRead:
   183	        await self._require_owned(TimeBudgetCategory, payload.category_id, user_id)
   184	        row = TimeBudgetSubcategory(user_id=user_id, **payload.model_dump())
   185	        self.session.add(row)
   186	        await self.session.commit()
   187	        await self.session.refresh(row)
   188	        return TimeBudgetSubcategoryRead.model_validate(row)
   189	
   190	    async def update_subcategory(
   191	        self, user_id: str, subcategory_id: str, payload: TimeBudgetSubcategoryUpdate
   192	    ) -> TimeBudgetSubcategoryRead:
   193	        row = await self._require_owned(TimeBudgetSubcategory, subcategory_id, user_id)
   194	        for field, value in payload.model_dump(exclude_unset=True).items():
   195	            setattr(row, field, value)
   196	        await self.session.commit()
   197	        await self.session.refresh(row)
   198	        return TimeBudgetSubcategoryRead.model_validate(row)
   199	
   200	    async def delete_subcategory(self, user_id: str, subcategory_id: str) -> None:
   201	        row = await self._require_owned(TimeBudgetSubcategory, subcategory_id, user_id)
   202	        await self.session.delete(row)  # items fall via ON DELETE CASCADE
   203	        await self.session.commit()
   204	
   205	    async def create_item(self, user_id: str, payload: TimeBudgetItemCreate) -> TimeBudgetItemRead:
   206	        await self._require_owned(TimeBudgetSubcategory, payload.subcategory_id, user_id)
   207	        row = TimeBudgetItem(user_id=user_id, **payload.model_dump())
   208	        self.session.add(row)
   209	        await self.session.commit()
   210	        await self.session.refresh(row)
   211	        return TimeBudgetItemRead.model_validate(row)
   212	
   213	    async def update_item(
   214	        self, user_id: str, item_id: str, payload: TimeBudgetItemUpdate
   215	    ) -> TimeBudgetItemRead:
   216	        row = await self._require_owned(TimeBudgetItem, item_id, user_id)
   217	        for field, value in payload.model_dump(exclude_unset=True).items():
   218	            setattr(row, field, value)
   219	        await self.session.commit()
   220	        await self.session.refresh(row)
   221	        return TimeBudgetItemRead.model_validate(row)
   222	
   223	    async def delete_item(self, user_id: str, item_id: str) -> None:
   224	        row = await self._require_owned(TimeBudgetItem, item_id, user_id)
   225	        await self.session.delete(row)
   226	        await self.session.commit()

 succeeded in 0ms:
     1	from collections import defaultdict
     2	from datetime import date, timedelta
     3	
     4	from sqlalchemy import delete, func, select, update
     5	from sqlalchemy.dialects.postgresql import insert as pg_insert
     6	from sqlalchemy.ext.asyncio import AsyncSession
     7	
     8	from app.errors import NotFoundError, RelatedRecordNotFoundError
     9	from app.models.habits import Habit, HabitEntry
    10	from app.models.projects import Project
    11	from app.schemas.habit import (
    12	    HabitCreate,
    13	    HabitEntryRead,
    14	    HabitEntryStatRead,
    15	    HabitEntryUpsert,
    16	    HabitRead,
    17	    HabitStreakRead,
    18	    HabitUpdate,
    19	)
    20	
    21	
    22	class HabitsService:
    23	    """Habit lifecycle (CRUD + archive/restore + reorder) against focal.habits, tenant-scoped to the
    24	    user. Ports the legacy /api/habits endpoints (routes.ts:3175)."""
    25	
    26	    def __init__(self, session: AsyncSession) -> None:
    27	        self.session = session
    28	
    29	    async def list_habits(self, user_id: str, *, archived: bool = False) -> list[HabitRead]:
    30	        stmt = select(Habit).where(Habit.user_id == user_id)
    31	        if archived:
    32	            stmt = stmt.where(Habit.is_archived.is_(True)).order_by(Habit.updated_at)
    33	        else:
    34	            stmt = stmt.where(Habit.is_archived.is_(False)).order_by(Habit.sort_order)
    35	        result = await self.session.execute(stmt)
    36	        return [HabitRead.model_validate(row) for row in result.scalars().all()]
    37	
    38	    async def get_habit(self, user_id: str, habit_id: str) -> HabitRead:
    39	        return HabitRead.model_validate(await self._require(user_id, habit_id))
    40	
    41	    async def create_habit(self, user_id: str, payload: HabitCreate) -> HabitRead:
    42	        await self._require_owned_project(user_id, payload.project_id)
    43	        habit = Habit(user_id=user_id, **payload.model_dump())
    44	        self.session.add(habit)
    45	        await self.session.commit()
    46	        await self.session.refresh(habit)
    47	        return HabitRead.model_validate(habit)
    48	
    49	    async def update_habit(self, user_id: str, habit_id: str, payload: HabitUpdate) -> HabitRead:
    50	        habit = await self._require(user_id, habit_id)
    51	        data = payload.model_dump(exclude_unset=True)
    52	        if "project_id" in data:
    53	            await self._require_owned_project(user_id, data["project_id"])
    54	        for field, value in data.items():
    55	            setattr(habit, field, value)
    56	        await self.session.commit()
    57	        await self.session.refresh(habit)
    58	        return HabitRead.model_validate(habit)
    59	
    60	    async def delete_habit(self, user_id: str, habit_id: str) -> None:
    61	        habit = await self._require(user_id, habit_id)
    62	        await self.session.delete(habit)  # entries fall via the habit_id ON DELETE CASCADE
    63	        await self.session.commit()
    64	
    65	    async def restore_habit(self, user_id: str, habit_id: str) -> HabitRead:
    66	        habit = await self._require(user_id, habit_id)
    67	        habit.is_archived = False
    68	        await self.session.commit()
    69	        await self.session.refresh(habit)
    70	        return HabitRead.model_validate(habit)
    71	
    72	    async def reorder_habits(self, user_id: str, ordered_ids: list[str]) -> None:
    73	        # Per-row, user-scoped: a foreign/unknown id matches nothing (no-op, no cross-tenant write).
    74	        for index, habit_id in enumerate(ordered_ids):
    75	            await self.session.execute(
    76	                update(Habit)
    77	                .where(Habit.id == habit_id, Habit.user_id == user_id)
    78	                .values(sort_order=index)
    79	            )
    80	        await self.session.commit()
    81	
    82	    async def _require(self, user_id: str, habit_id: str) -> Habit:
    83	        habit = await self.session.get(Habit, habit_id)
    84	        if habit is None or habit.user_id != user_id:
    85	            raise NotFoundError("Habit not found")
    86	        return habit
    87	
    88	    async def _require_owned_project(self, user_id: str, project_id: str | None) -> None:
    89	        if project_id is None:
    90	            return
    91	        project = await self.session.get(Project, project_id)
    92	        if project is None or project.user_id != user_id:
    93	            raise RelatedRecordNotFoundError("Related record not found")
    94	
    95	    async def list_entries(self, user_id: str, *, start: date, end: date) -> list[HabitEntryRead]:
    96	        result = await self.session.execute(
    97	            select(HabitEntry).where(
    98	                HabitEntry.user_id == user_id,
    99	                HabitEntry.date >= start,
   100	                HabitEntry.date <= end,
   101	            )
   102	        )
   103	        return [HabitEntryRead.model_validate(row) for row in result.scalars().all()]
   104	
   105	    async def upsert_entry(self, user_id: str, payload: HabitEntryUpsert) -> HabitEntryRead:
   106	        await self._require(user_id, payload.habit_id)  # the habit must be the caller's
   107	        stmt = pg_insert(HabitEntry).values(
   108	            habit_id=payload.habit_id,
   109	            user_id=user_id,
   110	            date=payload.date,
   111	            status=payload.status,
   112	            note=payload.note,
   113	        )
   114	        # On conflict only status/note move (legacy upsert); user_id stays the original inserter's.
   115	        await self.session.execute(
   116	            stmt.on_conflict_do_update(
   117	                index_elements=["habit_id", "date"],
   118	                set_={"status": payload.status, "note": payload.note},
   119	            )
   120	        )
   121	        await self.session.commit()
   122	        entry = (
   123	            await self.session.execute(
   124	                select(HabitEntry).where(
   125	                    HabitEntry.habit_id == payload.habit_id, HabitEntry.date == payload.date
   126	                )
   127	            )
   128	        ).scalar_one()
   129	        return HabitEntryRead.model_validate(entry)
   130	
   131	    async def delete_entry(self, user_id: str, *, habit_id: str, day: date) -> None:
   132	        await self._require(user_id, habit_id)
   133	        await self.session.execute(
   134	            delete(HabitEntry).where(HabitEntry.habit_id == habit_id, HabitEntry.date == day)
   135	        )
   136	        await self.session.commit()
   137	
   138	    async def streaks(self, user_id: str, today: date) -> list[HabitStreakRead]:
   139	        habit_ids = list(
   140	            (
   141	                await self.session.execute(
   142	                    select(Habit.id).where(Habit.user_id == user_id, Habit.is_archived.is_(False))
   143	                )
   144	            )
   145	            .scalars()
   146	            .all()
   147	        )
   148	        if not habit_ids:
   149	            return []
   150	        year_ago = today - timedelta(days=365)
   151	        rows = (
   152	            await self.session.execute(
   153	                select(HabitEntry.habit_id, HabitEntry.date, HabitEntry.status).where(
   154	                    HabitEntry.habit_id.in_(habit_ids),
   155	                    HabitEntry.date >= year_ago,
   156	                    HabitEntry.date <= today,
   157	                )
   158	            )
   159	        ).all()
   160	        by_habit: dict[str, dict[date, str]] = defaultdict(dict)
   161	        for habit_id, entry_date, status in rows:
   162	            by_habit[habit_id][entry_date] = status
   163	        results: list[HabitStreakRead] = []
   164	        for habit_id in habit_ids:
   165	            day_status = by_habit.get(habit_id, {})
   166	            streak = 0
   167	            cursor = today
   168	            for _ in range(365):
   169	                status = day_status.get(cursor)
   170	                if status == "yes":
   171	                    streak += 1
   172	                elif status == "skip":
   173	                    pass  # a skipped day does not increment the streak, but does not break it
   174	                else:
   175	                    break
   176	                cursor -= timedelta(days=1)
   177	            results.append(HabitStreakRead(habit_id=habit_id, streak=streak))
   178	        return results
   179	
   180	    async def entry_stats(
   181	        self, user_id: str, *, start: date, end: date, granularity: str
   182	    ) -> list[HabitEntryStatRead]:
   183	        fmt = "YYYY-MM-DD" if granularity == "day" else "YYYY-MM"
   184	        period = func.to_char(HabitEntry.date, fmt).label("period")
   185	        rows = (
   186	            await self.session.execute(
   187	                select(
   188	                    HabitEntry.habit_id.label("habit_id"),
   189	                    period,
   190	                    func.count().filter(HabitEntry.status == "yes").label("yes"),
   191	                    func.count().filter(HabitEntry.status == "no").label("no"),
   192	                    func.count().filter(HabitEntry.status == "skip").label("skip"),
   193	                )
   194	                .where(
   195	                    HabitEntry.user_id == user_id,
   196	                    HabitEntry.date >= start,
   197	                    HabitEntry.date <= end,
   198	                )
   199	                .group_by(HabitEntry.habit_id, period)
   200	                .order_by(period)
   201	            )
   202	        ).all()
   203	        return [
   204	            HabitEntryStatRead(
   205	                habit_id=r.habit_id, period=r.period, yes=r.yes, no=r.no, skip=r.skip
   206	            )
   207	            for r in rows
   208	        ]

exec
/bin/zsh -lc "nl -ba apps/focal/server/app/schemas/goals.py | sed -n '1,200p'" in /Users/allosta/Desktop/allosta/superapp-slice2
exec
/bin/zsh -lc "nl -ba apps/focal/server/app/models/goals.py | sed -n '1,180p'" in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
     1	from uuid import uuid4
     2	
     3	from sqlalchemy import Float, ForeignKey, Integer, String, Text
     4	from sqlalchemy.orm import Mapped, mapped_column
     5	
     6	from app.models.base import Base, TimestampMixin
     7	
     8	
     9	class Goal(TimestampMixin, Base):
    10	    __tablename__ = "goals"
    11	    __table_args__ = ({"schema": "focal"},)
    12	
    13	    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid4()))
    14	    user_id: Mapped[str] = mapped_column(String, index=True, nullable=False)
    15	    title: Mapped[str] = mapped_column(Text, nullable=False)
    16	    description: Mapped[str | None] = mapped_column(Text)
    17	    color: Mapped[str | None] = mapped_column(String(20), default="#3b82f6")
    18	    position_x: Mapped[float | None] = mapped_column(Float, default=0)
    19	    position_y: Mapped[float | None] = mapped_column(Float, default=0)
    20	    parent_goal_id: Mapped[str | None] = mapped_column(
    21	        String, ForeignKey("focal.goals.id", ondelete="SET NULL")
    22	    )
    23	    status: Mapped[str | None] = mapped_column(String(20), default="active")
    24	    progress: Mapped[int | None] = mapped_column(Integer, default=0)
    25	    # Link to the project this goal belongs to (the Edit-Project modal's Goals section); SET NULL on
    26	    # project delete so the goal survives, just unlinked.
    27	    project_id: Mapped[str | None] = mapped_column(
    28	        String, ForeignKey("focal.projects.id", ondelete="SET NULL"), index=True
    29	    )

 succeeded in 0ms:
     1	from datetime import datetime
     2	
     3	from pydantic import BaseModel, ConfigDict, Field
     4	from pydantic.alias_generators import to_camel
     5	
     6	
     7	class _Camel(BaseModel):
     8	    # Accept legacy camelCase (and snake_case) on input; serialize camelCase via by_alias.
     9	    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)
    10	
    11	
    12	class GoalCreate(_Camel):
    13	    title: str = Field(min_length=1)
    14	    description: str | None = None
    15	    color: str | None = None
    16	    project_id: str | None = None
    17	    parent_goal_id: str | None = None
    18	    status: str | None = None
    19	    progress: int | None = None
    20	    position_x: float | None = None
    21	    position_y: float | None = None
    22	
    23	
    24	# A supplied `projectId` (link) is validated against the caller's own projects in the service.
    25	# An explicit `projectId: null` unlinks; omitting it leaves the link untouched.
    26	class GoalUpdate(_Camel):
    27	    title: str | None = Field(default=None, min_length=1)
    28	    description: str | None = None
    29	    color: str | None = None
    30	    project_id: str | None = None
    31	    parent_goal_id: str | None = None
    32	    status: str | None = None
    33	    progress: int | None = None
    34	    position_x: float | None = None
    35	    position_y: float | None = None
    36	
    37	
    38	class GoalRead(_Camel):
    39	    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True, from_attributes=True)
    40	
    41	    id: str
    42	    user_id: str
    43	    title: str
    44	    description: str | None
    45	    color: str | None
    46	    position_x: float | None
    47	    position_y: float | None
    48	    parent_goal_id: str | None
    49	    status: str | None
    50	    progress: int | None
    51	    project_id: str | None
    52	    created_at: datetime
    53	    updated_at: datetime

exec
/bin/zsh -lc 'rg "parent_goal_id|parentGoalId" apps/focal -n' in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
apps/focal/server/scripts/etl/migrate_legacy.py:28:SELF_FK: dict[str, str] = {"projects": "parent_project_id", "goals": "parent_goal_id"}
apps/focal/docs/contract-freeze/schema-snapshot.json:2879:          "column_name": "parent_goal_id",
apps/focal/docs/contract-freeze/schema-snapshot.json:2929:          "column_name": "parent_goal_id",
apps/focal/docs/contract-freeze/schema-snapshot.json:2947:          "def": "CREATE INDEX idx_goals_parent_id ON public.goals USING btree (parent_goal_id)",
apps/focal/server/alembic/versions/2026_06_02_1521-25938473715d_focal_baseline.py:33:        sa.Column("parent_goal_id", sa.String(), nullable=True),
apps/focal/server/alembic/versions/2026_06_02_1521-25938473715d_focal_baseline.py:39:            ["parent_goal_id"],
apps/focal/server/alembic/versions/2026_06_02_1521-25938473715d_focal_baseline.py:41:            name=op.f("fk_goals_parent_goal_id_goals"),
apps/focal/server/tests/test_agent_goals_budgets_db.py:87:    parent_goal_id: str | None = None,
apps/focal/server/tests/test_agent_goals_budgets_db.py:95:        parent_goal_id=parent_goal_id,
apps/focal/server/tests/test_agent_goals_budgets_db.py:158:        "parentGoalId",
apps/focal/server/tests/test_agent_goals_budgets_db.py:171:            parent_goal_id=parent_id,
apps/focal/server/tests/test_agent_goals_budgets_db.py:179:    assert child["parentGoalId"] == parent_id
apps/focal/docs/contract-freeze/tables.json:1879:          "focal": "parent_goal_id",
apps/focal/docs/contract-freeze/tables.json:1881:          "legacy": "parent_goal_id",
apps/focal/server/app/ai/help_corpus.py:465:  Право: goals:read. Поля: id, title, description, status, progress, parentGoalId
apps/focal/server/app/services/backup.py:175:        for row in (g for g in goals if not g.get("parentGoalId")):
apps/focal/server/app/services/backup.py:176:            add(Goal, row, parent_goal_id=None)
apps/focal/server/app/services/backup.py:177:        for row in (g for g in goals if g.get("parentGoalId")):
apps/focal/server/app/services/backup.py:178:            add(Goal, row, parent_goal_id=remap(row.get("parentGoalId")))
apps/focal/client/src/api/openapi.d.ts:2503:            parentGoalId: string | null;
apps/focal/client/src/api/openapi.d.ts:3410:            parentGoalId?: string | null;
apps/focal/client/src/api/openapi.d.ts:3437:            parentGoalId: string | null;
apps/focal/client/src/api/openapi.d.ts:3466:            parentGoalId?: string | null;
apps/focal/server/app/services/goals.py:35:            parent_goal_id=payload.parent_goal_id,
apps/focal/server/app/schemas/agent_api.py:84:    parent_goal_id: str | None
apps/focal/client/src/features/help/HelpPage.tsx:2009:      "parentGoalId": null
apps/focal/server/tests/test_models_db.py:231:def test_deleting_a_parent_goal_nulls_child_parent_goal_id() -> None:
apps/focal/server/tests/test_models_db.py:234:        await _commit(Goal(id="g_child", user_id="u", title="child", parent_goal_id="g_parent"))
apps/focal/server/tests/test_models_db.py:240:            assert child is not None and child.parent_goal_id is None
apps/focal/server/app/schemas/goals.py:17:    parent_goal_id: str | None = None
apps/focal/server/app/schemas/goals.py:31:    parent_goal_id: str | None = None
apps/focal/server/app/schemas/goals.py:48:    parent_goal_id: str | None
apps/focal/server/tests/test_etl_migrate_legacy.py:62:    assert etl.SELF_FK == {"projects": "parent_project_id", "goals": "parent_goal_id"}
apps/focal/server/tests/test_backup_db.py:116:            session.add(Goal(user_id=user, title="Sub", parent_goal_id=goal.id))
apps/focal/server/tests/test_backup_db.py:171:    sub_goal = next(g for g in imported["goals"] if g["parentGoalId"])
apps/focal/server/tests/test_backup_db.py:172:    main_goal = next(g for g in imported["goals"] if not g["parentGoalId"])
apps/focal/server/tests/test_backup_db.py:173:    assert sub_goal["parentGoalId"] == main_goal["id"]
apps/focal/server/app/models/goals.py:20:    parent_goal_id: Mapped[str | None] = mapped_column(

exec
/bin/zsh -lc "nl -ba apps/focal/server/tests/test_calendar_scope_db.py | sed -n '600,690p'" in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
   600	        client.patch(
   601	            f"/api/events/{occ_18}",
   602	            headers=_h("owner"),
   603	            params={"recurrenceScope": "following", "occurrenceDate": "2026-01-18"},
   604	            json={"projectId": pid_b},
   605	        ).status_code
   606	        == 200
   607	    )
   608	    cid = _create_cal("owner", name="OnlyA", filterType="project", filterValue=pid_a)["id"]
   609	    _participant(cid, "editor-user", "editor")
   610	    # delete-all on the in-filter master_A would cascade-delete the out-of-filter sibling master_B
   611	    assert (
   612	        client.delete(
   613	            f"/api/events/{master_a}",
   614	            headers=_h("editor-user"),
   615	            params={"calendarId": cid, "recurrenceScope": "all"},
   616	        ).status_code
   617	        == 403
   618	    )
   619	
   620	
   621	def test_delegated_other_pages_writes_reject_non_owner_fk_links() -> None:
   622	    # In a delegated (shared assistant) other-pages write the payload FKs must belong to the OWNER,
   623	    # not the caller — else the caller could attach the owner's row to their OWN project/activity
   624	    # and later cascade-delete it. activities + activity-instances now validate this (tasks/events/
   625	    # bookings/projects/goals already did).
   626	    from app.errors import RelatedRecordNotFoundError
   627	    from app.models.activities import Activity
   628	    from app.schemas.activities import ActivityCreate
   629	    from app.schemas.activity_instances import ActivityInstanceSyncRequest
   630	    from app.services.activities import ActivitiesService
   631	    from app.services.activity_instances import ActivityInstancesService
   632	
   633	    caller_pid = _project("caller", name="Caller's own project")  # owned by 'caller', not 'owner'
   634	
   635	    async def go() -> None:
   636	        async with _sessionmaker() as session:
   637	            caller_activity = Activity(user_id="caller", name="a")
   638	            session.add(caller_activity)
   639	            await session.commit()
   640	            with pytest.raises(RelatedRecordNotFoundError):
   641	                await ActivitiesService(session).create_activity(
   642	                    "owner", ActivityCreate(name="x", project_id=caller_pid)
   643	                )
   644	            with pytest.raises(RelatedRecordNotFoundError):
   645	                await ActivityInstancesService(session).sync_instances(
   646	                    "owner",
   647	                    ActivityInstanceSyncRequest(
   648	                        activity_id=caller_activity.id, count=1, activity_name="a"
   649	                    ),
   650	                )
   651	
   652	    _run(go())
   653	
   654	
   655	# --- calendar_init mixed aggregate -------------------------------------------
   656	
   657	
   658	def test_calendar_init_gates_other_pages_but_serves_filtered_events() -> None:
   659	    cid, _, _ = _work_calendar_fixture()
   660	    client.post("/api/tasks", headers=_h("owner"), json={"title": "owner-task"})
   661	    _participant(cid, "viewer-user", "viewer")  # no canViewOtherPages
   662	    _participant(cid, "dev-user", "developer")  # canViewOtherPages, read-only
   663	
   664	    viewer = client.get(
   665	        "/api/calendar/init", headers=_h("viewer-user"), params={**WINDOW, "calendarId": cid}
   666	    ).json()
   667	    assert {e["title"] for e in viewer["events"]} == {"work"}  # filtered events served
   668	    assert viewer["tasks"] == [] and viewer["projects"] == []  # other pages withheld
   669	
   670	    dev = client.get(
   671	        "/api/calendar/init", headers=_h("dev-user"), params={**WINDOW, "calendarId": cid}
   672	    ).json()
   673	    assert {t["title"] for t in dev["tasks"]} == {"owner-task"}  # canViewOtherPages → owner's tasks
   674	
   675	
   676	# --- bookings + meeting-requests: calendar-domain role gates ------------------
   677	
   678	
   679	def test_shared_bookings_are_filtered_to_the_calendar() -> None:
   680	    pid_a = _project("owner", name="A")
   681	    pid_b = _project("owner", name="B")
   682	    a = _booking("owner", title="ba", startDate="2026-01-16", endDate="2026-01-16", projectId=pid_a)
   683	    b = _booking("owner", title="bb", startDate="2026-01-16", endDate="2026-01-16", projectId=pid_b)
   684	    cid = _create_cal("owner", name="OnlyA", filterType="project", filterValue=pid_a)["id"]
   685	    _participant(cid, "viewer-user", "viewer")
   686	    rows = client.get(
   687	        "/api/bookings", headers=_h("viewer-user"), params={**WINDOW, "calendarId": cid}
   688	    ).json()
   689	    assert {r["title"] for r in rows} == {"ba"}  # only the project-A booking, not project-B's
   690	    # a by-id read of the out-of-filter booking is not visible in this calendar → 404

exec
/bin/zsh -lc "nl -ba apps/focal/server/app/api/calendar.py | sed -n '1,300p'" in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
     1	from collections.abc import AsyncIterator
     2	from datetime import date
     3	
     4	from fastapi import APIRouter, Depends, Query, Response, status
     5	
     6	from app.db import get_sessionmaker
     7	from app.deps import current_utc_date, get_current_user_id
     8	from app.schemas.calendar import EnrichedEventRead, EventCreate, EventUpdate
     9	from app.services.calendar import CalendarService
    10	from app.services.shared_calendars import SharedCalendarsService
    11	
    12	router = APIRouter(prefix="/api/events", tags=["events"])
    13	
    14	
    15	async def get_calendar_service() -> AsyncIterator[CalendarService]:
    16	    # DB-backed only: the enrichment join, link-ownership, date-window, and SET-NULL FKs are all
    17	    # DB-semantic.
    18	    async with get_sessionmaker()() as session:
    19	        yield CalendarService(session)
    20	
    21	
    22	async def get_shared_service() -> AsyncIterator[SharedCalendarsService]:
    23	    # In shared mode (a `calendarId` is supplied) every event read/write is RBAC-gated and held to
    24	    # the calendar's saved filter through this service — the calendar-domain scope invariant.
    25	    async with get_sessionmaker()() as session:
    26	        yield SharedCalendarsService(session)
    27	
    28	
    29	@router.get("", response_model=list[EnrichedEventRead])
    30	async def list_events(
    31	    start_date: str | None = Query(default=None, alias="startDate"),
    32	    end_date: str | None = Query(default=None, alias="endDate"),
    33	    calendar_id: str | None = Query(default=None, alias="calendarId"),
    34	    user_id: str = Depends(get_current_user_id),
    35	    today: date = Depends(current_utc_date),
    36	    service: CalendarService = Depends(get_calendar_service),
    37	    shared: SharedCalendarsService = Depends(get_shared_service),
    38	) -> list[EnrichedEventRead]:
    39	    if calendar_id:
    40	        return await shared.list_events(
    41	            user_id, calendar_id, start=start_date, end=end_date, today=today
    42	        )
    43	    return await service.list_events(user_id, start=start_date, end=end_date, today=today)
    44	
    45	
    46	@router.post("", response_model=EnrichedEventRead)
    47	async def create_event(
    48	    payload: EventCreate,
    49	    calendar_id: str | None = Query(default=None, alias="calendarId"),
    50	    user_id: str = Depends(get_current_user_id),
    51	    service: CalendarService = Depends(get_calendar_service),
    52	    shared: SharedCalendarsService = Depends(get_shared_service),
    53	) -> EnrichedEventRead:
    54	    if calendar_id:
    55	        return await shared.create_event(user_id, calendar_id, payload)
    56	    return await service.create_event(user_id, payload)
    57	
    58	
    59	# `event_id` is an opaque str (never a typed UUID), so an unknown/malformed id reaches the scoped
    60	# lookup and returns the typed not_found (404), not FastAPI's path-validation 422.
    61	@router.get("/{event_id}", response_model=EnrichedEventRead)
    62	async def get_event(
    63	    event_id: str,
    64	    calendar_id: str | None = Query(default=None, alias="calendarId"),
    65	    user_id: str = Depends(get_current_user_id),
    66	    service: CalendarService = Depends(get_calendar_service),
    67	    shared: SharedCalendarsService = Depends(get_shared_service),
    68	) -> EnrichedEventRead:
    69	    if calendar_id:
    70	        return await shared.get_event(user_id, calendar_id, event_id)
    71	    return await service.get_event(user_id, event_id)
    72	
    73	
    74	# `recurrenceScope` (single/following/all) + `occurrenceDate` scope a recurring mutation; both are
    75	# optional query params (legacy used a PATCH body, but a query keeps DELETE — which has no body —
    76	# symmetric). A malformed `occurrenceDate` is a typed 422 via the FastAPI date parse.
    77	@router.patch("/{event_id}", response_model=EnrichedEventRead)
    78	async def update_event(
    79	    event_id: str,
    80	    payload: EventUpdate,
    81	    recurrence_scope: str | None = Query(default=None, alias="recurrenceScope"),
    82	    occurrence_date: date | None = Query(default=None, alias="occurrenceDate"),
    83	    calendar_id: str | None = Query(default=None, alias="calendarId"),
    84	    user_id: str = Depends(get_current_user_id),
    85	    service: CalendarService = Depends(get_calendar_service),
    86	    shared: SharedCalendarsService = Depends(get_shared_service),
    87	) -> EnrichedEventRead:
    88	    if calendar_id:
    89	        return await shared.update_event(
    90	            user_id,
    91	            calendar_id,
    92	            event_id,
    93	            payload,
    94	            scope=recurrence_scope,
    95	            occurrence_date=occurrence_date,
    96	        )
    97	    return await service.update_event(
    98	        user_id, event_id, payload, scope=recurrence_scope, occurrence_date=occurrence_date
    99	    )
   100	
   101	
   102	@router.delete("/{event_id}", status_code=status.HTTP_204_NO_CONTENT)
   103	async def delete_event(
   104	    event_id: str,
   105	    recurrence_scope: str | None = Query(default=None, alias="recurrenceScope"),
   106	    occurrence_date: date | None = Query(default=None, alias="occurrenceDate"),
   107	    calendar_id: str | None = Query(default=None, alias="calendarId"),
   108	    user_id: str = Depends(get_current_user_id),
   109	    service: CalendarService = Depends(get_calendar_service),
   110	    shared: SharedCalendarsService = Depends(get_shared_service),
   111	) -> Response:
   112	    if calendar_id:
   113	        await shared.delete_event(
   114	            user_id,
   115	            calendar_id,
   116	            event_id,
   117	            scope=recurrence_scope,
   118	            occurrence_date=occurrence_date,
   119	        )
   120	    else:
   121	        await service.delete_event(
   122	            user_id, event_id, scope=recurrence_scope, occurrence_date=occurrence_date
   123	        )
   124	    return Response(status_code=status.HTTP_204_NO_CONTENT)

exec
/bin/zsh -lc "nl -ba apps/focal/server/app/services/calendar.py | sed -n '1,260p'" in /Users/allosta/Desktop/allosta/superapp-slice2
exec
/bin/zsh -lc "nl -ba apps/focal/server/app/services/shared_calendars.py | sed -n '1,360p'" in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
     1	import datetime
     2	from dataclasses import dataclass
     3	from datetime import UTC
     4	from typing import Any
     5	from uuid import uuid4
     6	
     7	from sqlalchemy import delete, or_, select
     8	from sqlalchemy.dialects.postgresql import insert as pg_insert
     9	from sqlalchemy.ext.asyncio import AsyncSession
    10	
    11	from app.domain.completion import transition_completed_at
    12	from app.domain.daterange import get_date_range
    13	from app.domain.priority import event_priority_from_hierarchy
    14	from app.domain.recurrence import (
    15	    RECURRENCE_TYPES,
    16	    build_occurrence_event_id,
    17	    is_recurring_type,
    18	    occurrence_dates_in_range,
    19	    parse_occurrence_event_id,
    20	    previous_occurrence,
    21	    recurrence_group_id,
    22	)
    23	from app.errors import NotFoundError, RelatedRecordNotFoundError, ValidationError
    24	from app.models.activities import Activity
    25	from app.models.base import utcnow
    26	from app.models.calendar import CalendarEvent, CalendarEventOverride
    27	from app.models.projects import Project
    28	from app.schemas.calendar import EnrichedEventRead, EventCreate, EventRead, EventUpdate
    29	
    30	
    31	@dataclass
    32	class ProjectedFilterEvent:
    33	    """An un-persisted event's filterable projection (the FilterableEvent shape) — the fields a
    34	    create/update WOULD enrich to from its project links, for a shared-calendar filter check made
    35	    BEFORE the row is written (so a rejected write never persists). Not frozen: the FilterableEvent
    36	    protocol expects settable attributes."""
    37	
    38	    is_work_time: bool
    39	    sphere: str | None
    40	    project_id: str | None
    41	    product_id: str | None
    42	    project_type: str | None
    43	
    44	
    45	# Fields an override snapshots (the event's overridable set; recurrence fields stay on the master).
    46	_OVERRIDE_FIELDS = (
    47	    "title",
    48	    "date",
    49	    "start_time",
    50	    "end_time",
    51	    "description",
    52	    "location",
    53	    "color",
    54	    "timezone",
    55	    "other_participants",
    56	    "priority",
    57	    "priority_score",
    58	    "priority_level",
    59	    "status",
    60	    "completed",
    61	    "completed_at",
    62	    "tags",
    63	    "contact_ids",
    64	    "project_id",
    65	    "product_id",
    66	    "activity_id",
    67	)
    68	
    69	# (event_read, occurrence_date | None, is_recurring_instance) — the input to enrichment.
    70	_EnrichItem = tuple[EventRead, datetime.date | None, bool]
    71	
    72	_SCOPES = ("single", "following", "all")
    73	# Recurrence-rule fields a single-occurrence override can't carry (it keeps the master's rule).
    74	_RECURRENCE_RULE_FIELDS = ("recurrence", "recurrence_end_date", "recurrence_exceptions")
    75	
    76	
    77	def _minutes(value: str) -> int:
    78	    hour, minute = value.split(":")
    79	    return int(hour) * 60 + int(minute)
    80	
    81	
    82	def _sanitize_single_occurrence_updates(data: dict[str, Any]) -> dict[str, Any]:
    83	    # Port of sanitizeSingleOccurrenceUpdates (storage.ts:373): an override edits one occurrence,
    84	    # never the series rule.
    85	    return {k: v for k, v in data.items() if k not in _RECURRENCE_RULE_FIELDS}
    86	
    87	
    88	class CalendarService:
    89	    """Calendar-event CRUD + recurrence expansion against ``focal.calendar_events``, tenant-scoped
    90	    to the user. Ports legacy ``/api/events`` (routes.ts:2740) + the priority/enrichment, the
    91	    recurrence expansion, and the recurrence-scoped mutations (single/following/all override writes,
    92	    series split, group delete) from storage.ts."""
    93	
    94	    def __init__(self, session: AsyncSession) -> None:
    95	        self.session = session
    96	
    97	    async def list_events(
    98	        self, user_id: str, *, start: str | None, end: str | None, today: datetime.date
    99	    ) -> list[EnrichedEventRead]:
   100	        window_start, window_end = get_date_range(start, end, today=today)
   101	        # Direct rows: non-recurring events + legacy child rows, inside the window.
   102	        direct = (
   103	            (
   104	                await self.session.execute(
   105	                    select(CalendarEvent).where(
   106	                        CalendarEvent.user_id == user_id,
   107	                        CalendarEvent.date >= window_start,
   108	                        CalendarEvent.date <= window_end,
   109	                        or_(
   110	                            CalendarEvent.recurrence == "none",
   111	                            CalendarEvent.recurring_event_id.is_not(None),
   112	                        ),
   113	                    )
   114	                )
   115	            )
   116	            .scalars()
   117	            .all()
   118	        )
   119	        # Recurring masters that could touch the window.
   120	        masters = (
   121	            (
   122	                await self.session.execute(
   123	                    select(CalendarEvent).where(
   124	                        CalendarEvent.user_id == user_id,
   125	                        CalendarEvent.recurring_event_id.is_(None),
   126	                        CalendarEvent.recurrence.in_(RECURRENCE_TYPES),
   127	                        CalendarEvent.date <= window_end,
   128	                        or_(
   129	                            CalendarEvent.recurrence_end_date.is_(None),
   130	                            CalendarEvent.recurrence_end_date >= window_start,
   131	                        ),
   132	                    )
   133	                )
   134	            )
   135	            .scalars()
   136	            .all()
   137	        )
   138	        overrides = await self._overrides_map(
   139	            [m.id for m in masters], window=(window_start, window_end)
   140	        )
   141	
   142	        items: list[_EnrichItem] = [(EventRead.model_validate(row), None, False) for row in direct]
   143	        for master in masters:
   144	            for occ_date in occurrence_dates_in_range(
   145	                master.date, master.recurrence, window_start, window_end, master.recurrence_end_date
   146	            ):
   147	                occ = self._build_occurrence(master, occ_date, overrides.get((master.id, occ_date)))
   148	                if occ is not None:
   149	                    items.append((occ, occ_date, True))
   150	
   151	        enriched = await self._enrich(user_id, items)
   152	        enriched.sort(key=lambda e: (e.date, e.start_time))
   153	        return enriched
   154	
   155	    async def get_event(self, user_id: str, event_id: str) -> EnrichedEventRead:
   156	        parsed = parse_occurrence_event_id(event_id)
   157	        if parsed is None:
   158	            event = await self._require(user_id, event_id)
   159	            return (await self._enrich(user_id, [(EventRead.model_validate(event), None, False)]))[
   160	                0
   161	            ]
   162	        master_id, occ_date = parsed
   163	        master = await self.session.get(CalendarEvent, master_id)
   164	        if (
   165	            master is None
   166	            or master.user_id != user_id
   167	            or not is_recurring_type(master.recurrence)
   168	            or master.recurring_event_id is not None
   169	        ):
   170	            raise NotFoundError("Event not found")
   171	        override = (await self._overrides_map([master_id])).get((master_id, occ_date))
   172	        occ = self._build_occurrence(master, occ_date, override)
   173	        if occ is None:  # excepted or soft-deleted
   174	            raise NotFoundError("Event not found")
   175	        return (await self._enrich(user_id, [(occ, occ_date, True)]))[0]
   176	
   177	    async def create_event(self, user_id: str, payload: EventCreate) -> EnrichedEventRead:
   178	        await self._require_owned_link(
   179	            user_id, payload.project_id, payload.product_id, payload.activity_id
   180	        )
   181	        level, score = await self._compute_priority(
   182	            user_id, payload.project_id, payload.product_id, payload.activity_id
   183	        )
   184	        now = datetime.datetime.now(UTC)
   185	        event_id = str(uuid4())
   186	        recurring = is_recurring_type(payload.recurrence)
   187	        event = CalendarEvent(
   188	            id=event_id,
   189	            user_id=user_id,
   190	            title=payload.title,
   191	            date=payload.date,
   192	            start_time=payload.start_time,
   193	            end_time=payload.end_time,
   194	            description=payload.description,
   195	            location=payload.location,
   196	            color=payload.color,
   197	            timezone=payload.timezone,
   198	            other_participants=payload.other_participants,
   199	            status=payload.status,
   200	            completed=payload.completed,
   201	            completed_at=now if payload.completed else None,
   202	            tags=payload.tags,
   203	            contact_ids=payload.contact_ids,
   204	            project_id=payload.project_id,
   205	            product_id=payload.product_id,
   206	            activity_id=payload.activity_id,
   207	            priority=level,
   208	            priority_score=score,
   209	            priority_level=level,
   210	            recurrence=payload.recurrence,
   211	            recurring_event_id=None,
   212	            recurrence_end_date=payload.recurrence_end_date,
   213	            recurrence_exceptions=payload.recurrence_exceptions,
   214	            recurrence_group_id=event_id if recurring else None,
   215	            old_logic=False,
   216	        )
   217	        self.session.add(event)
   218	        await self.session.commit()
   219	        await self.session.refresh(event)
   220	        return (await self._enrich(user_id, [(EventRead.model_validate(event), None, False)]))[0]
   221	
   222	    async def update_event(
   223	        self,
   224	        user_id: str,
   225	        event_id: str,
   226	        payload: EventUpdate,
   227	        *,
   228	        scope: str | None = None,
   229	        occurrence_date: datetime.date | None = None,
   230	    ) -> EnrichedEventRead:
   231	        # Resolve scope + the master/occurrence target (a synthetic occurrence id defaults to the
   232	        # single scope; an occurrenceDate param overrides the id's date). Ports
   233	        # getRecurringMutationScope/resolveRecurringTarget (storage.ts:341).
   234	        resolved_scope = self._resolve_scope(event_id, scope)
   235	        master_id, target_date = self._resolve_target(event_id, occurrence_date)
   236	        master = await self._require(user_id, master_id)
   237	        data = payload.model_dump(exclude_unset=True)
   238	        # A non-recurring event (or a legacy child row) updates in place, ignoring the scope.
   239	        if not is_recurring_type(master.recurrence) or master.recurring_event_id is not None:
   240	            return await self._commit_in_place(user_id, master, data)
   241	        if resolved_scope == "all":
   242	            return await self._update_all(user_id, master, data, target_date)
   243	        if target_date is None:
   244	            raise ValidationError("occurrenceDate is required for a single/following scope")
   245	        if resolved_scope == "following":
   246	            return await self._update_following(user_id, master, data, target_date)
   247	        return await self._update_single(user_id, master, data, target_date)
   248	
   249	    async def delete_event(
   250	        self,
   251	        user_id: str,
   252	        event_id: str,
   253	        *,
   254	        scope: str | None = None,
   255	        occurrence_date: datetime.date | None = None,
   256	    ) -> None:
   257	        resolved_scope = self._resolve_scope(event_id, scope)
   258	        master_id, target_date = self._resolve_target(event_id, occurrence_date)
   259	        master = await self._require(user_id, master_id)
   260	        if not is_recurring_type(master.recurrence) or master.recurring_event_id is not None:

 succeeded in 0ms:
     1	from datetime import date
     2	from typing import Any
     3	from uuid import uuid4
     4	
     5	from sqlalchemy import func, select, text, update
     6	from sqlalchemy.ext.asyncio import AsyncSession
     7	
     8	from app.domain.invite_code import generate_invite_code
     9	from app.domain.recurrence import build_occurrence_event_id, parse_occurrence_event_id
    10	from app.domain.shared_calendar_filter import FilterableEvent, apply_shared_calendar_filter
    11	from app.errors import ConflictError, NotFoundError, PermissionDeniedError
    12	from app.models.shared_calendar import SharedCalendar, SharedCalendarParticipant
    13	from app.models.users import User
    14	from app.rbac import ROLE_RANK, get_resource_role
    15	from app.rls import INVITE_CODE_GUC
    16	from app.schemas.bookings import BookingCreate, BookingRead, BookingUpdate
    17	from app.schemas.calendar import EnrichedEventRead, EventCreate, EventUpdate
    18	from app.schemas.shared_calendar import (
    19	    AccessibleSharedCalendarRead,
    20	    JoinRequest,
    21	    JoinResponse,
    22	    MyParticipationItem,
    23	    MyParticipationRead,
    24	    MyRoleRead,
    25	    ParticipantInvite,
    26	    ParticipantRead,
    27	    ParticipantRoleUpdate,
    28	    SharedCalendarCreate,
    29	    SharedCalendarRead,
    30	    SharedCalendarUpdate,
    31	)
    32	from app.services.bookings import BookingsService
    33	from app.services.calendar import CalendarService
    34	
    35	
    36	class SharedCalendarsService:
    37	    """Shared-calendar (calendar-filter) CRUD + caller-view, tenant-scoped to the user. Ports legacy
    38	    /api/shared-calendars (routes.ts:7426) and applies the access checks the legacy left commented
    39	    out: read needs viewer; calendar-config edit + delete need owner. The owner is resolved via
    40	    shared_calendars.user_id (and an accepted owner participant row)."""
    41	
    42	    def __init__(self, session: AsyncSession) -> None:
    43	        self.session = session
    44	
    45	    async def list_owned(self, user_id: str) -> list[SharedCalendarRead]:
    46	        result = await self.session.execute(
    47	            select(SharedCalendar)
    48	            .where(SharedCalendar.user_id == user_id)
    49	            .order_by(SharedCalendar.created_at)
    50	        )
    51	        return [SharedCalendarRead.model_validate(row) for row in result.scalars().all()]
    52	
    53	    async def list_accessible(self, user_id: str) -> list[AccessibleSharedCalendarRead]:
    54	        owned = (
    55	            (
    56	                await self.session.execute(
    57	                    select(SharedCalendar).where(SharedCalendar.user_id == user_id)
    58	                )
    59	            )
    60	            .scalars()
    61	            .all()
    62	        )
    63	        owned_ids = {c.id for c in owned}
    64	        participant_ids = (
    65	            (
    66	                await self.session.execute(
    67	                    select(SharedCalendarParticipant.shared_calendar_id).where(
    68	                        SharedCalendarParticipant.user_id == user_id,
    69	                        SharedCalendarParticipant.invite_status == "accepted",
    70	                    )
    71	                )
    72	            )
    73	            .scalars()
    74	            .all()
    75	        )
    76	        extra_ids = [cid for cid in participant_ids if cid not in owned_ids]
    77	        extra: list[SharedCalendar] = []
    78	        if extra_ids:
    79	            extra = list(
    80	                (
    81	                    await self.session.execute(
    82	                        select(SharedCalendar).where(SharedCalendar.id.in_(extra_ids))
    83	                    )
    84	                )
    85	                .scalars()
    86	                .all()
    87	            )
    88	        accessible: list[AccessibleSharedCalendarRead] = []
    89	        for calendar in [*owned, *extra]:
    90	            count = (
    91	                await self.session.execute(
    92	                    select(func.count())
    93	                    .select_from(SharedCalendarParticipant)
    94	                    .where(SharedCalendarParticipant.shared_calendar_id == calendar.id)
    95	                )
    96	            ).scalar_one()
    97	            # the CALLER's own row (owner has an accepted owner row), not an arbitrary join row
    98	            row = (
    99	                await self.session.execute(
   100	                    select(SharedCalendarParticipant).where(
   101	                        SharedCalendarParticipant.shared_calendar_id == calendar.id,
   102	                        SharedCalendarParticipant.user_id == user_id,
   103	                    )
   104	                )
   105	            ).scalar_one_or_none()
   106	            accessible.append(
   107	                AccessibleSharedCalendarRead(
   108	                    **SharedCalendarRead.model_validate(calendar).model_dump(),
   109	                    participants_count=count,
   110	                    participant_role=row.role if row is not None else None,
   111	                    invite_status=row.invite_status if row is not None else None,
   112	                )
   113	            )
   114	        return accessible
   115	
   116	    async def my_participation(self, user_id: str) -> MyParticipationRead:
   117	        rows = (
   118	            await self.session.execute(
   119	                select(SharedCalendar, SharedCalendarParticipant.role)
   120	                .join(
   121	                    SharedCalendarParticipant,
   122	                    SharedCalendar.id == SharedCalendarParticipant.shared_calendar_id,
   123	                )
   124	                .where(
   125	                    SharedCalendarParticipant.user_id == user_id,
   126	                    SharedCalendarParticipant.invite_status == "accepted",
   127	                    SharedCalendar.user_id != user_id,  # non-owner participations only
   128	                )
   129	            )
   130	        ).all()
   131	        participating = [
   132	            MyParticipationItem(
   133	                calendar=SharedCalendarRead.model_validate(calendar), role=role, is_owner=False
   134	            )
   135	            for calendar, role in rows
   136	        ]
   137	        own_count = (
   138	            await self.session.execute(
   139	                select(func.count())
   140	                .select_from(SharedCalendar)
   141	                .where(SharedCalendar.user_id == user_id)
   142	            )
   143	        ).scalar_one()
   144	        return MyParticipationRead(
   145	            participating_calendars=participating,
   146	            is_only_participant=(own_count == 0 and len(participating) > 0),
   147	            own_calendars_count=own_count,
   148	        )
   149	
   150	    async def create(self, user_id: str, payload: SharedCalendarCreate) -> SharedCalendarRead:
   151	        # Explicit id so the owner participant references the calendar (no ORM relationship); both
   152	        # rows commit together so a calendar never exists without its owner.
   153	        calendar_id = str(uuid4())
   154	        calendar = SharedCalendar(
   155	            id=calendar_id,
   156	            user_id=user_id,
   157	            name=payload.name,
   158	            filter_type=payload.filter_type,
   159	            filter_value=payload.filter_value,
   160	            filter_rules=payload.filter_rules,
   161	            google_calendar_id=payload.google_calendar_id,
   162	            color=payload.color,
   163	            is_active=payload.is_active,
   164	        )
   165	        owner = SharedCalendarParticipant(
   166	            shared_calendar_id=calendar_id,
   167	            user_id=user_id,
   168	            role="owner",
   169	            invite_status="accepted",
   170	        )
   171	        self.session.add(calendar)
   172	        self.session.add(owner)
   173	        await self.session.commit()
   174	        await self.session.refresh(calendar)
   175	        return SharedCalendarRead.model_validate(calendar)
   176	
   177	    async def get(self, user_id: str, calendar_id: str) -> SharedCalendarRead:
   178	        calendar, _ = await self._resolve_access(user_id, calendar_id, "viewer")
   179	        return SharedCalendarRead.model_validate(calendar)
   180	
   181	    async def update(
   182	        self, user_id: str, calendar_id: str, payload: SharedCalendarUpdate
   183	    ) -> SharedCalendarRead:
   184	        calendar, _ = await self._resolve_access(user_id, calendar_id, "owner")
   185	        for field, value in payload.model_dump(exclude_unset=True).items():
   186	            setattr(calendar, field, value)
   187	        await self.session.commit()
   188	        await self.session.refresh(calendar)
   189	        return SharedCalendarRead.model_validate(calendar)
   190	
   191	    async def delete(self, user_id: str, calendar_id: str) -> None:
   192	        calendar, _ = await self._resolve_access(user_id, calendar_id, "owner")
   193	        await self.session.delete(calendar)
   194	        await self.session.commit()
   195	
   196	    async def my_role(self, user_id: str, calendar_id: str) -> MyRoleRead:
   197	        calendar, role = await self._resolve_access(user_id, calendar_id, "viewer")
   198	        if calendar.user_id == user_id:
   199	            return MyRoleRead(role="owner", is_owner=True, can_edit=True, can_view_other_pages=True)
   200	        return MyRoleRead(
   201	            role=role,
   202	            is_owner=False,
   203	            can_edit=role in ("full_access", "editor"),
   204	            can_view_other_pages=role in ("owner", "full_access", "developer"),
   205	        )
   206	
   207	    async def list_events(
   208	        self, user_id: str, calendar_id: str, *, start: str | None, end: str | None, today: date
   209	    ) -> list[EnrichedEventRead]:
   210	        # A viewer+ participant reads the OWNER's events (RBAC-gated cross-tenant share), filtered
   211	        # by the calendar's saved filter. Events reuse the recurrence-expanded + enriched list.
   212	        calendar, _ = await self._resolve_access(user_id, calendar_id, "viewer")
   213	        return await self._filtered_owner_events(calendar, start=start, end=end, today=today)
   214	
   215	    async def get_event(self, user_id: str, calendar_id: str, event_id: str) -> EnrichedEventRead:
   216	        # By-id read in shared mode: the event must be the owner's AND within this calendar's
   217	        # filter, else it is not part of this shared calendar → 404 (never raw
   218	        # CalendarService.get_event, which would expose owner events outside the filter).
   219	        calendar, _ = await self._resolve_access(user_id, calendar_id, "viewer")
   220	        event = await CalendarService(self.session).get_event(calendar.user_id, event_id)
   221	        if not self._in_filter(calendar, event):
   222	            raise NotFoundError("Event not found")
   223	        return event
   224	
   225	    async def create_event(
   226	        self, user_id: str, calendar_id: str, payload: EventCreate
   227	    ) -> EnrichedEventRead:
   228	        # Write in shared mode needs canEdit (owner/full_access/editor — rank >= editor) AND the new
   229	        # event must land WITHIN this calendar's filter — an editor cannot author owner events
   230	        # outside the shared calendar's scope (→ 403). Checked before the write, so a rejected
   231	        # create never persists.
   232	        calendar, _ = await self._resolve_access(user_id, calendar_id, "editor")
   233	        if not await self._links_in_filter(calendar, payload.project_id, payload.product_id):
   234	            raise PermissionDeniedError("Event falls outside this calendar's filter")
   235	        return await CalendarService(self.session).create_event(calendar.user_id, payload)
   236	
   237	    async def update_event(
   238	        self,
   239	        user_id: str,
   240	        calendar_id: str,
   241	        event_id: str,
   242	        payload: EventUpdate,
   243	        *,
   244	        scope: str | None,
   245	        occurrence_date: date | None,
   246	    ) -> EnrichedEventRead:
   247	        # The touched events must already be in-filter (can't reach out-of-scope owner events), AND
   248	        # the edit must not MOVE the result out — the post-edit project links must still match the
   249	        # filter. "all" edits the master, so its post-state derives from the master; "single" /
   250	        # "following" derive from the occurrence (a "following" split clones it into a new series).
   251	        # Only project_id/product_id change filter membership; an unset link keeps the base's.
   252	        calendar, occurrence, master = await self._writable_event_target(
   253	            user_id, calendar_id, event_id, scope=scope, occurrence_date=occurrence_date
   254	        )
   255	        base = master if scope == "all" else occurrence
   256	        patch = payload.model_dump(exclude_unset=True)
   257	        post_project_id = patch["project_id"] if "project_id" in patch else base.project_id
   258	        post_product_id = patch["product_id"] if "product_id" in patch else base.product_id
   259	        if not await self._links_in_filter(calendar, post_project_id, post_product_id):
   260	            raise PermissionDeniedError("Event would move outside this calendar's filter")
   261	        return await CalendarService(self.session).update_event(
   262	            calendar.user_id, event_id, payload, scope=scope, occurrence_date=occurrence_date
   263	        )
   264	
   265	    async def delete_event(
   266	        self,
   267	        user_id: str,
   268	        calendar_id: str,
   269	        event_id: str,
   270	        *,
   271	        scope: str | None,
   272	        occurrence_date: date | None,
   273	    ) -> None:
   274	        calendar, _, _ = await self._writable_event_target(
   275	            user_id, calendar_id, event_id, scope=scope, occurrence_date=occurrence_date
   276	        )
   277	        # A scope=all DELETE is the only op that cascades the WHOLE recurrence group — it can reach
   278	        # a SIBLING master left by a prior "following" split with out-of-filter links. So validate
   279	        # the full delete-all blast radius (every group master + their overrides), not just the
   280	        # resolved master _writable_event_target checked. (update-all edits one master in place;
   281	        # following-delete truncates one master — neither crosses the group.)
   282	        resolved_scope = scope or (
   283	            "single" if parse_occurrence_event_id(event_id) is not None else "all"
   284	        )
   285	        if resolved_scope == "all":
   286	            parsed = parse_occurrence_event_id(event_id)
   287	            master_id = parsed[0] if parsed is not None else event_id
   288	            svc = CalendarService(self.session)
   289	            links = await svc.delete_all_target_links(calendar.user_id, master_id)
   290	            projected = await svc.projected_filter_events(calendar.user_id, links)
   291	            if not all(self._in_filter(calendar, p) for p in projected):
   292	                raise PermissionDeniedError(
   293	                    "The recurrence group includes occurrences outside this calendar's filter"
   294	                )
   295	        await CalendarService(self.session).delete_event(
   296	            calendar.user_id, event_id, scope=scope, occurrence_date=occurrence_date
   297	        )
   298	
   299	    # --- bookings (calendar-domain, filtered like events: they carry project links) --------------
   300	
   301	    async def list_bookings(
   302	        self, user_id: str, calendar_id: str, *, start: str | None, end: str | None, today: date
   303	    ) -> list[BookingRead]:
   304	        calendar, _ = await self._resolve_access(user_id, calendar_id, "viewer")
   305	        bookings = await BookingsService(self.session).list_bookings(
   306	            calendar.user_id, start=start, end=end, today=today
   307	        )
   308	        return await self._filter_bookings(calendar, bookings)
   309	
   310	    async def get_booking(self, user_id: str, calendar_id: str, booking_id: str) -> BookingRead:
   311	        calendar, _ = await self._resolve_access(user_id, calendar_id, "viewer")
   312	        booking = await BookingsService(self.session).get_booking(calendar.user_id, booking_id)
   313	        if not await self._links_in_filter(calendar, booking.project_id, booking.product_id):
   314	            raise NotFoundError("Booking not found")
   315	        return booking
   316	
   317	    async def create_booking(
   318	        self, user_id: str, calendar_id: str, payload: BookingCreate
   319	    ) -> BookingRead:
   320	        calendar, _ = await self._resolve_access(user_id, calendar_id, "editor")
   321	        if not await self._links_in_filter(calendar, payload.project_id, payload.product_id):
   322	            raise PermissionDeniedError("Booking falls outside this calendar's filter")
   323	        return await BookingsService(self.session).create_booking(calendar.user_id, payload)
   324	
   325	    async def update_booking(
   326	        self, user_id: str, calendar_id: str, booking_id: str, payload: BookingUpdate
   327	    ) -> BookingRead:
   328	        calendar, existing = await self._writable_booking(user_id, calendar_id, booking_id)
   329	        patch = payload.model_dump(exclude_unset=True)
   330	        post_project_id = patch["project_id"] if "project_id" in patch else existing.project_id
   331	        post_product_id = patch["product_id"] if "product_id" in patch else existing.product_id
   332	        if not await self._links_in_filter(calendar, post_project_id, post_product_id):
   333	            raise PermissionDeniedError("Booking would move outside this calendar's filter")
   334	        return await BookingsService(self.session).update_booking(
   335	            calendar.user_id, booking_id, payload
   336	        )
   337	
   338	    async def delete_booking(self, user_id: str, calendar_id: str, booking_id: str) -> None:
   339	        calendar, _ = await self._writable_booking(user_id, calendar_id, booking_id)
   340	        await BookingsService(self.session).delete_booking(calendar.user_id, booking_id)
   341	
   342	    async def _writable_booking(
   343	        self, user_id: str, calendar_id: str, booking_id: str
   344	    ) -> tuple[SharedCalendar, BookingRead]:
   345	        calendar, _ = await self._resolve_access(user_id, calendar_id, "editor")
   346	        existing = await BookingsService(self.session).get_booking(calendar.user_id, booking_id)
   347	        if not await self._links_in_filter(calendar, existing.project_id, existing.product_id):
   348	            raise PermissionDeniedError("Booking is outside this calendar's filter")
   349	        return calendar, existing
   350	
   351	    async def _filter_bookings(
   352	        self, calendar: SharedCalendar, bookings: list[BookingRead]
   353	    ) -> list[BookingRead]:
   354	        # Bookings carry project links but not the derived is_work_time/sphere, so project them
   355	        # through the owner's projects (one load) before applying the calendar's saved filter.
   356	        if not bookings:
   357	            return bookings
   358	        projections = await CalendarService(self.session).projected_filter_events(
   359	            calendar.user_id, [(b.project_id, b.product_id) for b in bookings]
   360	        )

exec
/bin/zsh -lc "nl -ba apps/focal/server/app/services/shared_calendars.py | sed -n '360,760p'" in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
   360	        )
   361	        return [
   362	            booking
   363	            for booking, projected in zip(bookings, projections, strict=True)
   364	            if self._in_filter(calendar, projected)
   365	        ]
   366	
   367	    async def init_scope(
   368	        self, user_id: str, calendar_id: str, *, start: str | None, end: str | None, today: date
   369	    ) -> tuple[list[EnrichedEventRead], list[BookingRead], str, bool]:
   370	        """For the calendar-init mixed aggregate: the filtered owner events + filtered owner
   371	        bookings, the resolved owner id, and whether the caller may also see the owner's OTHER pages
   372	        (tasks/projects) — i.e. holds an other-pages read role (owner/full_access/developer). An
   373	        editor/viewer/requester gets the filtered events/bookings but the other-pages flag is
   374	        False."""
   375	        calendar, role = await self._resolve_access(user_id, calendar_id, "viewer")
   376	        events = await self._filtered_owner_events(calendar, start=start, end=end, today=today)
   377	        raw_bookings = await BookingsService(self.session).list_bookings(
   378	            calendar.user_id, start=start, end=end, today=today
   379	        )
   380	        bookings = await self._filter_bookings(calendar, raw_bookings)
   381	        return events, bookings, calendar.user_id, role in ("owner", "full_access", "developer")
   382	
   383	    async def _writable_event_target(
   384	        self,
   385	        user_id: str,
   386	        calendar_id: str,
   387	        event_id: str,
   388	        *,
   389	        scope: str | None,
   390	        occurrence_date: date | None,
   391	    ) -> tuple[SharedCalendar, EnrichedEventRead, EnrichedEventRead]:
   392	        # by-id WRITE: canEdit role AND every event the write touches is in-filter. The EFFECTIVE
   393	        # occurrence the write resolves to must be in-filter — resolved exactly as CalendarService
   394	        # does (an occurrence id OR a master id + occurrenceDate both name one occurrence), so
   395	        # a hidden out-of-filter occurrence can't be reached either way. A series-affecting scope
   396	        # (all / following) ALSO touches the recurring MASTER (edited or truncated; "following"
   397	        # splits the occurrence into a new series), so it must be in-filter too. Returns the
   398	        # occurrence + the post-edit base (the master for "all", else the occurrence).
   399	        calendar, _ = await self._resolve_access(user_id, calendar_id, "editor")
   400	        svc = CalendarService(self.session)
   401	        parsed = parse_occurrence_event_id(event_id)
   402	        target_date: date | None
   403	        if parsed is not None:
   404	            master_id, target_date = parsed[0], (occurrence_date or parsed[1])
   405	        else:
   406	            master_id, target_date = event_id, occurrence_date
   407	        occ_id = (
   408	            build_occurrence_event_id(master_id, target_date)
   409	            if target_date is not None
   410	            else master_id
   411	        )
   412	        occurrence = await svc.get_event(calendar.user_id, occ_id)
   413	        if not self._in_filter(calendar, occurrence):
   414	            raise PermissionDeniedError("Event is outside this calendar's filter")
   415	        master = occurrence
   416	        if scope in ("all", "following"):
   417	            if target_date is not None:
   418	                master = await svc.get_event(calendar.user_id, master_id)
   419	                if not self._in_filter(calendar, master):
   420	                    raise PermissionDeniedError("Series master is outside this calendar's filter")
   421	            # The operation edits/clears the series' per-occurrence overrides across the affected
   422	            # range ("following" from target_date, "all" the whole series). NONE of those hidden
   423	            # override occurrences may be out-of-filter — else the write would silently mutate or
   424	            # delete an owner occurrence the caller can't even see in this shared calendar.
   425	            since = target_date if scope == "following" else None
   426	            override_links = await svc.override_links(master_id, since=since)
   427	            if override_links:
   428	                projected = await svc.projected_filter_events(calendar.user_id, override_links)
   429	                if not all(self._in_filter(calendar, p) for p in projected):
   430	                    raise PermissionDeniedError(
   431	                        "An occurrence in the affected range is outside this calendar's filter"
   432	                    )
   433	        return calendar, occurrence, master
   434	
   435	    async def _links_in_filter(
   436	        self, calendar: SharedCalendar, project_id: str | None, product_id: str | None
   437	    ) -> bool:
   438	        """Whether an event with these project links would pass the calendar's filter — the
   439	        pre-write check for create/move (filter fields derive entirely from the project links)."""
   440	        projected = await CalendarService(self.session).projected_filter_event(
   441	            calendar.user_id, project_id, product_id
   442	        )
   443	        return self._in_filter(calendar, projected)
   444	
   445	    async def _filtered_owner_events(
   446	        self, calendar: SharedCalendar, *, start: str | None, end: str | None, today: date
   447	    ) -> list[EnrichedEventRead]:
   448	        events = await CalendarService(self.session).list_events(
   449	            calendar.user_id, start=start, end=end, today=today
   450	        )
   451	        return apply_shared_calendar_filter(
   452	            events,
   453	            filter_type=calendar.filter_type,
   454	            filter_value=calendar.filter_value,
   455	            filter_rules=calendar.filter_rules,
   456	        )
   457	
   458	    def _in_filter(self, calendar: SharedCalendar, event: FilterableEvent) -> bool:
   459	        return bool(
   460	            apply_shared_calendar_filter(
   461	                [event],
   462	                filter_type=calendar.filter_type,
   463	                filter_value=calendar.filter_value,
   464	                filter_rules=calendar.filter_rules,
   465	            )
   466	        )
   467	
   468	    async def _resolve_access(
   469	        self, user_id: str, calendar_id: str, minimum: str
   470	    ) -> tuple[SharedCalendar, str]:
   471	        calendar = await self.session.get(SharedCalendar, calendar_id)
   472	        if calendar is None:
   473	            raise NotFoundError("Shared calendar not found")
   474	        if calendar.user_id == user_id:
   475	            role: str | None = "owner"
   476	        else:
   477	            role = await get_resource_role(self.session, calendar_id, user_id)
   478	        if role is None or ROLE_RANK.get(role, -1) < ROLE_RANK[minimum]:
   479	            raise PermissionDeniedError("Insufficient role on the shared calendar")
   480	        return calendar, role
   481	
   482	    # --- participants + join -------------------------------------------------
   483	
   484	    async def list_participants(self, user_id: str, calendar_id: str) -> list[ParticipantRead]:
   485	        _, role = await self._resolve_access(user_id, calendar_id, "viewer")
   486	        is_owner = role == "owner"  # only the owner sees the invite codes
   487	        rows = (
   488	            await self.session.execute(
   489	                select(SharedCalendarParticipant, User)
   490	                .outerjoin(User, SharedCalendarParticipant.user_id == User.id)
   491	                .where(SharedCalendarParticipant.shared_calendar_id == calendar_id)
   492	            )
   493	        ).all()
   494	        return [
   495	            self._participant_read(participant, user, include_invite_code=is_owner)
   496	            for participant, user in rows
   497	        ]
   498	
   499	    async def invite_participant(
   500	        self, user_id: str, calendar_id: str, payload: ParticipantInvite
   501	    ) -> ParticipantRead:
   502	        await self._resolve_access(user_id, calendar_id, "owner")
   503	        participant = SharedCalendarParticipant(
   504	            shared_calendar_id=calendar_id,
   505	            user_id=payload.user_id,
   506	            email=payload.email,
   507	            role=payload.role,
   508	            invite_status="pending",
   509	            invite_code=generate_invite_code(),
   510	        )
   511	        self.session.add(participant)
   512	        await self.session.commit()
   513	        await self.session.refresh(participant)
   514	        # The caller is the owner (owner-only route), so they receive the code to share.
   515	        user = await self._participant_user(participant)
   516	        return self._participant_read(participant, user, include_invite_code=True)
   517	
   518	    async def update_participant_role(
   519	        self, user_id: str, calendar_id: str, participant_id: str, payload: ParticipantRoleUpdate
   520	    ) -> ParticipantRead:
   521	        await self._resolve_access(user_id, calendar_id, "owner")
   522	        participant = await self._require_participant(calendar_id, participant_id)
   523	        if participant.role == "owner":
   524	            raise ConflictError("The owner participant's role cannot be changed")
   525	        participant.role = payload.role
   526	        await self.session.commit()
   527	        await self.session.refresh(participant)
   528	        # The caller is the owner (owner-only route), so they receive the code.
   529	        user = await self._participant_user(participant)
   530	        return self._participant_read(participant, user, include_invite_code=True)
   531	
   532	    async def remove_participant(self, user_id: str, calendar_id: str, participant_id: str) -> None:
   533	        _, role = await self._resolve_access(user_id, calendar_id, "viewer")
   534	        participant = await self._require_participant(calendar_id, participant_id)
   535	        # The owner is immutable — checked before the owner-or-self rule (non-owner still gets 409).
   536	        if participant.role == "owner":
   537	            raise ConflictError("The owner participant cannot be removed")
   538	        if role != "owner" and participant.user_id != user_id:
   539	            raise PermissionDeniedError("Only the owner or the participant may remove this")
   540	        await self.session.delete(participant)
   541	        await self.session.commit()
   542	
   543	    async def join(self, user_id: str, payload: JoinRequest) -> JoinResponse:
   544	        code = payload.invite_code.upper()
   545	        # Publish the presented code as a transaction-local GUC: under RLS the joiner can neither
   546	        # see nor claim a pending participant row they don't own — the policy's capability branch
   547	        # matches rows whose invite_code equals this GUC, scoped to the claiming transaction.
   548	        await self.session.execute(
   549	            text("SELECT set_config(:guc, :code, true)"),
   550	            {"guc": INVITE_CODE_GUC, "code": code},
   551	        )
   552	        # Atomic accept: the `invite_status != "accepted"` guard + RETURNING means exactly one of
   553	        # two concurrent joins flips a pending invite; the loser updates 0 rows and gets 409.
   554	        updated_id = (
   555	            await self.session.execute(
   556	                update(SharedCalendarParticipant)
   557	                .where(
   558	                    SharedCalendarParticipant.invite_code == code,
   559	                    SharedCalendarParticipant.invite_status != "accepted",
   560	                )
   561	                .values(user_id=user_id, invite_status="accepted")
   562	                .returning(SharedCalendarParticipant.id)
   563	            )
   564	        ).scalar_one_or_none()
   565	        if updated_id is None:
   566	            # 0 rows updated: either no such code, or it was already accepted.
   567	            exists = (
   568	                await self.session.execute(
   569	                    select(SharedCalendarParticipant.id).where(
   570	                        SharedCalendarParticipant.invite_code == code
   571	                    )
   572	                )
   573	            ).first()
   574	            if exists is None:
   575	                raise NotFoundError("Invalid invite code")
   576	            raise ConflictError("This invite has already been used")
   577	        await self.session.commit()
   578	        participant = await self.session.get(SharedCalendarParticipant, updated_id)
   579	        if participant is None:  # just updated, so present — defensive for the type checker
   580	            raise NotFoundError("Participant not found")
   581	        calendar = await self.session.get(SharedCalendar, participant.shared_calendar_id)
   582	        if calendar is None:
   583	            raise NotFoundError("Shared calendar not found")
   584	        joiner = await self.session.get(User, user_id)
   585	        return JoinResponse(
   586	            # the joiner is not the owner -> the echoed participant hides the invite code
   587	            participant=self._participant_read(participant, joiner, include_invite_code=False),
   588	            calendar=SharedCalendarRead.model_validate(calendar),
   589	        )
   590	
   591	    async def _require_participant(
   592	        self, calendar_id: str, participant_id: str
   593	    ) -> SharedCalendarParticipant:
   594	        participant = await self.session.get(SharedCalendarParticipant, participant_id)
   595	        if participant is None or participant.shared_calendar_id != calendar_id:
   596	            raise NotFoundError("Participant not found")
   597	        return participant
   598	
   599	    async def _participant_user(self, participant: SharedCalendarParticipant) -> User | None:
   600	        if not participant.user_id:
   601	            return None
   602	        return await self.session.get(User, participant.user_id)
   603	
   604	    def _participant_read(
   605	        self,
   606	        participant: SharedCalendarParticipant,
   607	        user: User | None,
   608	        *,
   609	        include_invite_code: bool,
   610	    ) -> ParticipantRead:
   611	        # invite_code is a bearer join token: only the owner ever sees it (it grants the invite's
   612	        # role on join), so a non-owner can't read a higher-role pending code and self-escalate.
   613	        data: dict[str, Any] = {
   614	            "id": participant.id,
   615	            "shared_calendar_id": participant.shared_calendar_id,
   616	            "user_id": participant.user_id,
   617	            "email": participant.email,
   618	            "role": participant.role,
   619	            "invite_status": participant.invite_status,
   620	            "invite_code": participant.invite_code if include_invite_code else None,
   621	            "created_at": participant.created_at,
   622	            "updated_at": participant.updated_at,
   623	            "user": {"email": user.email} if user is not None else None,
   624	        }
   625	        return ParticipantRead.model_validate(data)

exec
/bin/zsh -lc "nl -ba apps/focal/server/app/rbac.py | sed -n '1,120p'" in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
     1	from collections.abc import AsyncIterator, Awaitable, Callable
     2	
     3	from fastapi import Depends
     4	from sqlalchemy import select
     5	from sqlalchemy.ext.asyncio import AsyncSession
     6	
     7	from app.db import get_sessionmaker
     8	from app.deps import get_current_user_id
     9	from app.errors import PermissionDeniedError
    10	from app.models.shared_calendar import SharedCalendarParticipant
    11	
    12	# The legacy calendar-sharing roles, carried 1:1 (the owner confirmed the faithful model). Write is
    13	# allowed for owner/full_access/editor; the read-only trio (developer/viewer/requester) share one
    14	# rank because their *write* permission is identical — developer scope and requester capability
    15	# are separate dimensions handled elsewhere, never ladder rungs.
    16	SHARED_CALENDAR_ROLES = ("owner", "full_access", "editor", "developer", "viewer", "requester")
    17	ROLE_RANK = {
    18	    "viewer": 10,
    19	    "requester": 10,
    20	    "developer": 10,
    21	    "editor": 20,
    22	    "full_access": 30,
    23	    "owner": 40,
    24	}
    25	
    26	
    27	async def get_resource_role(session: AsyncSession, calendar_id: str, user_id: str) -> str | None:
    28	    """The caller's role via an accepted participant row, or None — accepted-gated port of
    29	    checkSharedCalendarPermission / my-role (storage.ts:6539): a pending/declined invite grants no
    30	    role. Roles live on the membership table, never the JWT; the owner resolves via its accepted
    31	    owner row (callers also resolve the owner via shared_calendars.user_id)."""
    32	    result = await session.execute(
    33	        select(SharedCalendarParticipant.role).where(
    34	            SharedCalendarParticipant.shared_calendar_id == calendar_id,
    35	            SharedCalendarParticipant.user_id == user_id,
    36	            SharedCalendarParticipant.invite_status == "accepted",
    37	        )
    38	    )
    39	    return result.scalars().first()
    40	
    41	
    42	async def _rbac_session() -> AsyncIterator[AsyncSession]:
    43	    async with get_sessionmaker()() as session:
    44	        yield session
    45	
    46	
    47	def require_role(minimum: str) -> Callable[..., Awaitable[str]]:
    48	    """FastAPI dependency: the caller must hold a role on the path's ``{calendar_id}`` whose rank is
    49	    ``>=`` ``minimum``. Compares by ``ROLE_RANK`` (never raw strings); a missing/unknown role denies
    50	    with the typed ``PermissionDeniedError`` (403), never a ``KeyError``."""
    51	    threshold = ROLE_RANK[minimum]
    52	
    53	    async def checker(
    54	        calendar_id: str,
    55	        user_id: str = Depends(get_current_user_id),
    56	        session: AsyncSession = Depends(_rbac_session),
    57	    ) -> str:
    58	        role = await get_resource_role(session, calendar_id, user_id)
    59	        if role is None or ROLE_RANK.get(role, -1) < threshold:
    60	            raise PermissionDeniedError(f"Requires {minimum} on the shared calendar")
    61	        return role
    62	
    63	    return checker

exec
/bin/zsh -lc "nl -ba apps/focal/server/app/api/ai_chat.py | sed -n '1,300p'" in /Users/allosta/Desktop/allosta/superapp-slice2
exec
/bin/zsh -lc "nl -ba apps/focal/server/app/api/ai.py | sed -n '1,220p'" in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
     1	"""The in-app AI meta routes: question stats, recommended questions, and conversation
     2	clearing. The chat/classify/clarify/help routes build on the same router in the
     3	follow-up slice."""
     4	
     5	from collections.abc import AsyncIterator
     6	from datetime import UTC, datetime
     7	from typing import Any
     8	
     9	from fastapi import APIRouter, Depends, Query
    10	from pydantic import BaseModel, ConfigDict, Field
    11	from pydantic.alias_generators import to_camel
    12	from sqlalchemy import delete, select
    13	from sqlalchemy.dialects.postgresql import insert
    14	from sqlalchemy.ext.asyncio import AsyncSession
    15	
    16	from app.ai.chat_support import (
    17	    format_question_for_display,
    18	    get_fallback_questions,
    19	    memory_scope,
    20	    memory_scope_owner,
    21	    normalize_question,
    22	)
    23	from app.ai_gateway import log_ai_gateway_event
    24	from app.db import get_sessionmaker
    25	from app.deps import get_current_user_id
    26	from app.errors import ValidationError
    27	from app.models.ai import AiConversation, AiQuestionStat
    28	
    29	router = APIRouter(prefix="/api/ai", tags=["ai"])
    30	
    31	
    32	async def get_ai_session() -> AsyncIterator[AsyncSession]:
    33	    async with get_sessionmaker()() as session:
    34	        yield session
    35	
    36	
    37	class QuestionStatCreate(BaseModel):
    38	    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)
    39	
    40	    tab_id: str = Field(min_length=1, max_length=50)
    41	    view_type: str = Field(min_length=1, max_length=20)
    42	    question: str = Field(min_length=1)
    43	
    44	
    45	@router.post("/question-stats")
    46	async def record_question_stat(
    47	    payload: QuestionStatCreate,
    48	    user_id: str = Depends(get_current_user_id),
    49	    session: AsyncSession = Depends(get_ai_session),
    50	) -> dict[str, Any]:
    51	    normalized = normalize_question(payload.question)
    52	    if not normalized:
    53	        raise ValidationError("Question must not be empty")
    54	    stmt = insert(AiQuestionStat).values(
    55	        user_id=user_id,
    56	        tab_id=payload.tab_id,
    57	        view_type=payload.view_type,
    58	        normalized_question=normalized,
    59	        count=1,
    60	        last_asked_at=datetime.now(UTC),
    61	    )
    62	    stmt = stmt.on_conflict_do_update(
    63	        constraint="uidx_ai_question_stats_user_tab_view_question",
    64	        set_={"count": AiQuestionStat.count + 1, "last_asked_at": datetime.now(UTC)},
    65	    )
    66	    await session.execute(stmt)
    67	    await session.commit()
    68	    return {"success": True}
    69	
    70	
    71	@router.get("/recommended-questions")
    72	async def recommended_questions(
    73	    tab_id: str = Query(alias="tabId", min_length=1, max_length=50),
    74	    view_type: str = Query(alias="viewType", min_length=1, max_length=20),
    75	    limit: int = Query(default=6, ge=1, le=10),
    76	    user_id: str = Depends(get_current_user_id),
    77	    session: AsyncSession = Depends(get_ai_session),
    78	) -> dict[str, Any]:
    79	    """The user's most-asked questions for this tab/view, padded with the curated
    80	    fallbacks, deduplicated, capped at `limit`."""
    81	    rows = (
    82	        await session.execute(
    83	            select(AiQuestionStat.normalized_question)
    84	            .where(
    85	                AiQuestionStat.user_id == user_id,
    86	                AiQuestionStat.tab_id == tab_id,
    87	                AiQuestionStat.view_type == view_type,
    88	            )
    89	            .order_by(AiQuestionStat.count.desc(), AiQuestionStat.last_asked_at.desc())
    90	            .limit(limit)
    91	        )
    92	    ).scalars()
    93	    from_stats = [q for q in (format_question_for_display(r) for r in rows) if q]
    94	    unique: list[str] = []
    95	    for question in [*from_stats, *get_fallback_questions(tab_id)]:
    96	        if question not in unique:
    97	            unique.append(question)
    98	    return {"questions": unique[:limit]}
    99	
   100	
   101	@router.delete("/conversation")
   102	async def clear_conversation(
   103	    conversation_id: str = Query(alias="conversationId", min_length=1),
   104	    data_owner_id: str | None = Query(default=None, alias="userId"),
   105	    reset_type: str | None = Query(default=None, alias="resetType"),
   106	    user_id: str = Depends(get_current_user_id),
   107	    session: AsyncSession = Depends(get_ai_session),
   108	) -> dict[str, Any]:
   109	    """Clear the server-side dialog memory for one bucket. The scope key recomputes
   110	    with the same formula the chat route uses when writing, so shared-calendar buckets
   111	    clear correctly. resetType="reset" marks an implicit tab/owner switch in telemetry."""
   112	    owner = memory_scope_owner(data_owner_id, user_id)
   113	    effective_scope = memory_scope(conversation_id, owner, user_id)
   114	    failed_event = (
   115	        "CONVERSATION_RESET_FAILED" if reset_type == "reset" else "CONVERSATION_CLEAR_FAILED"
   116	    )
   117	    try:
   118	        await session.execute(
   119	            delete(AiConversation).where(
   120	                AiConversation.user_id == user_id,
   121	                AiConversation.conversation_id == effective_scope,
   122	            )
   123	        )
   124	        await session.commit()
   125	    except Exception as exc:
   126	        await log_ai_gateway_event(
   127	            failed_event,
   128	            actor_id=f"user:{user_id}",
   129	            operation="/api/ai/conversation",
   130	            details={
   131	                "conversationId": conversation_id,
   132	                "dataOwnerId": owner,
   133	                "effectiveScope": effective_scope,
   134	                "errorMessage": str(exc),
   135	            },
   136	        )
   137	        raise
   138	    return {"ok": True}

 succeeded in 0ms:
     1	# ruff: noqa: E501, RUF001 — verbatim legacy Russian prompts exceed line limits and mix scripts
     2	"""The in-app AI assistant routes — the port of the legacy chat orchestration:
     3	classification → entity dispatch → help-with-RAG / create dialog / clarify dialogs,
     4	with conversation memory and SSE streaming for help answers.
     5	
     6	Ported adaptations (deliberate, documented here once):
     7	- One OpenAI client path — the legacy proxy/direct dual-client fallback is dropped
     8	  (no proxy in this infrastructure).
     9	- Errors ride the standard AppError envelope ({"error": {code, message}}) instead of
    10	  the legacy flat {error, code}; machine codes are preserved verbatim so the client
    11	  maps them to localized texts.
    12	- The legacy aborted in-flight OpenAI calls on client disconnect for the clarify
    13	  routes; here the admission timeout caps the cost instead (FastAPI surfaces
    14	  disconnects poorly mid-await). SSE disconnects are still detected and abort the
    15	  upstream stream.
    16	"""
    17	
    18	import asyncio
    19	import json
    20	import math
    21	import re
    22	from collections.abc import AsyncIterator
    23	from datetime import date, timedelta
    24	from typing import Any
    25	
    26	import structlog
    27	from fastapi import Depends, Request
    28	from fastapi.responses import StreamingResponse
    29	from pydantic import BaseModel, ConfigDict, Field
    30	from pydantic.alias_generators import to_camel
    31	from sqlalchemy import select
    32	from sqlalchemy.ext.asyncio import AsyncSession
    33	
    34	from app.ai import entity_handlers  # noqa: F401 — import registers the handlers
    35	from app.ai.chat_support import (
    36	    append_conversation_messages,
    37	    get_fallback_questions,
    38	    get_tab_label,
    39	    load_conversation_history,
    40	    memory_scope,
    41	)
    42	from app.ai.embeddings import (
    43	    MAX_PROMPT_INPUT_TOKENS,
    44	    build_user_context,
    45	    detect_boost_sections,
    46	    generate_help_prompt,
    47	    retrieve_with_budget,
    48	)
    49	from app.ai.entity_types import EntityCtx, dispatch_entity_intent
    50	from app.ai.event_merge import apply_clarify_merge, apply_create_merge
    51	from app.ai.json_parsing import (
    52	    AiJsonParseError,
    53	    ClarifyEvent,
    54	    ClarifyTask,
    55	    Classification,
    56	    CreateEventAi,
    57	    parse_ai_json,
    58	)
    59	from app.ai.openai_client import CHAT_MODEL, create_chat_completion, stream_chat_completion
    60	from app.ai.task_merge import apply_clarify_task_merge, is_event_field_filled, is_task_field_filled
    61	from app.ai.user_datetime import AI_TIME_RULES, is_valid_date, is_valid_time
    62	from app.ai_gateway import (
    63	    log_ai_gateway_event,
    64	    prepare_ai_actor,
    65	    record_ai_failure,
    66	    record_ai_success,
    67	)
    68	from app.api.ai import get_ai_session, router
    69	from app.config import get_settings
    70	from app.data_scope import DataDomain, require_ai_write, resolve_ai_data_owner
    71	from app.deps import get_current_tier, get_current_user_id
    72	from app.errors import AppError, PermissionDeniedError, ValidationError
    73	from app.models.activities import Activity
    74	
    75	log = structlog.get_logger(__name__)
    76	
    77	_TZ_NAME_RE = re.compile(r"^[A-Za-z_]+/[A-Za-z_+\-0-9]+$|^UTC$")
    78	_TECH_FORMAT_RE = re.compile(r"\s*\(?\bYYYY-MM-DD\b\)?|\s*\(?\bHH:MM\b\)?", re.IGNORECASE)
    79	_PLANNING_RE = re.compile(
    80	    r"что\s+(?:у\s+меня|запланирован|назначен|определен|стоит|ожидает|будет|было|есть|делал|на\s)"
    81	    r"|как(?:ие|ой|ая)\s+(?:событи|задач|встреч|дел)"
    82	    r"|сколько\s+(?:событи|задач|встреч)"
    83	    r"|покажи\s+(?:событи|задач|расписани|календар)"
    84	    r"|список\s+(?:событи|задач|встреч)"
    85	    r"|расписани",
    86	    re.IGNORECASE,
    87	)
    88	_PERSON_IN_TITLE_RE = re.compile(r"с\s+[А-ЯЁA-Z][а-яёa-z]+", re.IGNORECASE)
    89	
    90	SKIP_WORDS = (
    91	    "пропустить",
    92	    "пропусти",
    93	    "нет",
    94	    "не нужно",
    95	    "без разницы",
    96	    "без",
    97	    "не важно",
    98	    "дальше",
    99	    "skip",
   100	    "next",
   101	)
   102	
   103	COMPATIBLE_ENTITIES: dict[str, list[str]] = {
   104	    "calendar": ["events", "tasks"],
   105	    "events": ["calendar"],
   106	    "tasks": ["calendar"],
   107	    "meeting-requests": ["calendar", "events"],
   108	}
   109	
   110	PARSE_ERROR_MSG = "Извините, я не смог обработать ваш запрос. Попробуйте переформулировать."
   111	NOT_FOUND_MSG = (
   112	    "Извините, я не смог найти информацию по этому запросу. Попробуйте переформулировать."
   113	)
   114	
   115	# Per-user concurrent SSE stream cap (connection-moment protection beyond the rate limiter).
   116	MAX_CONCURRENT_STREAMS_PER_USER = 3
   117	_active_streams: dict[str, int] = {}
   118	
   119	
   120	def reset_active_streams() -> None:
   121	    """Test hook."""
   122	    _active_streams.clear()
   123	
   124	
   125	def _require_openai_key() -> None:
   126	    if not get_settings().openai_api_key:
   127	        raise AppError(
   128	            "AI-функции недоступны. Добавьте OPENAI_API_KEY в переменные окружения.",
   129	            code="AI_NOT_CONFIGURED",
   130	            status_code=503,
   131	        )
   132	
   133	
   134	def _sanitize_timezone(tz: Any) -> str | None:
   135	    if isinstance(tz, str) and _TZ_NAME_RE.match(tz):
   136	        try:
   137	            from zoneinfo import ZoneInfo
   138	
   139	            ZoneInfo(tz)
   140	            return tz
   141	        except KeyError:
   142	            return None
   143	    return None
   144	
   145	
   146	def _now_in_timezone(tz_name: str) -> tuple[int, int]:
   147	    from datetime import datetime
   148	    from zoneinfo import ZoneInfo
   149	
   150	    now = datetime.now(ZoneInfo(tz_name))
   151	    return now.hour, now.minute
   152	
   153	
   154	def _history_messages(history: list[dict[str, str]]) -> list[dict[str, str]]:
   155	    return [{"role": m["role"], "content": m["content"]} for m in history]
   156	
   157	
   158	async def _parse_or_502(
   159	    raw: str | None, schema: type, label: str, actor_id: str, operation: str
   160	) -> Any:
   161	    try:
   162	        return parse_ai_json(raw, schema, label)  # type: ignore[arg-type]
   163	    except AiJsonParseError as exc:
   164	        await log_ai_gateway_event(
   165	            "AI_JSON_PARSE_ERROR",
   166	            source="OPENAI",
   167	            actor_id=actor_id,
   168	            operation=operation,
   169	            details={"message": str(exc), "raw": exc.raw[:500]},
   170	        )
   171	        raise AppError(PARSE_ERROR_MSG, code="AI_JSON_PARSE_ERROR", status_code=502) from exc
   172	
   173	
   174	class ChatRequest(BaseModel):
   175	    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True, extra="ignore")
   176	
   177	    message: str = Field(min_length=1)
   178	    current_event: dict[str, Any] = Field(default_factory=dict)
   179	    user_id: str | None = None
   180	    tab_id: str | None = None
   181	    view_type: str | None = None
   182	    user_today: str | None = None
   183	    display_timezone: str | None = None
   184	    stream: bool = False
   185	
   186	
   187	@router.post("/chat")
   188	async def ai_chat(
   189	    payload: ChatRequest,
   190	    request: Request,
   191	    auth_user_id: str = Depends(get_current_user_id),
   192	    tier: str = Depends(get_current_tier),
   193	    session: AsyncSession = Depends(get_ai_session),
   194	) -> Any:
   195	    """Classification → dispatch → help / general / create, with per-tab scope rules
   196	    and conversation memory. Help answers stream over SSE when requested."""
   197	    if not payload.message.strip():
   198	        raise ValidationError("Сообщение не предоставлено")
   199	    _require_openai_key()
   200	    actor_id = await prepare_ai_actor(auth_user_id, tier=tier, operation="/api/ai/chat")
   201	
   202	    effective_tab_id = (payload.tab_id or "").strip() or "calendar"
   203	    effective_view = (payload.view_type or "").strip() or "default"
   204	    data_owner = await resolve_ai_data_owner(session, auth_user_id, payload.user_id)
   205	    scope_id = memory_scope(effective_tab_id, data_owner, auth_user_id)
   206	    tab_label = get_tab_label(effective_tab_id)
   207	    tab_context_line = (
   208	        f'Текущая вкладка: "{tab_label}" (tabId={effective_tab_id}). Вид: {effective_view}.'
   209	    )
   210	    message = payload.message
   211	
   212	    today_str = date.today().isoformat()
   213	    safe_today = payload.user_today if is_valid_date(payload.user_today) else today_str
   214	
   215	    classify_prompt = _build_classify_prompt(safe_today, message)
   216	    history = await load_conversation_history(session, auth_user_id, scope_id)
   217	
   218	    classify_raw = await create_chat_completion(
   219	        "/api/ai/chat:classify",
   220	        {
   221	            "model": CHAT_MODEL,
   222	            "messages": [
   223	                {"role": "system", "content": classify_prompt},
   224	                *_history_messages(history),
   225	                {"role": "user", "content": message},
   226	            ],
   227	            "max_completion_tokens": 200,
   228	            "temperature": 0.1,
   229	            "response_format": {"type": "json_object"},
   230	        },
   231	        actor_id=actor_id,
   232	    )
   233	    classification: Classification = await _parse_or_502(
   234	        classify_raw, Classification, "classify", actor_id, "/api/ai/chat:classify"
   235	    )
   236	
   237	    is_universal_chat = effective_tab_id == "ai-chat"
   238	    is_calendar_tab = effective_tab_id in ("calendar", "ai-chat")
   239	    resolved_tab_id = "events" if effective_tab_id == "meeting-requests" else effective_tab_id
   240	
   241	    use_gpt_entity = (
   242	        not is_universal_chat
   243	        and classification.target_entity is not None
   244	        and resolved_tab_id == "calendar"
   245	        and classification.target_entity in COMPATIBLE_ENTITIES["calendar"]
   246	    )
   247	    target_entity = (
   248	        classification.target_entity
   249	        if is_universal_chat
   250	        else (classification.target_entity if use_gpt_entity else resolved_tab_id)
   251	    )
   252	
   253	    # Shared-calendar MANAGEMENT (the "calendars" entity) is owner-only and NOT delegatable: a
   254	    # full_access/developer assistant resolved to another owner must not read or create that owner's
   255	    # shared calendars/participants through the AI (it falls under the other-pages gate otherwise).
   256	    if data_owner != auth_user_id and target_entity == "calendars":
   257	        raise PermissionDeniedError("Shared-calendar management is not available for another user")
   258	
   259	    async def reply_general(text: str, *, save: bool = True) -> dict[str, Any]:
   260	        if save:
   261	            await append_conversation_messages(
   262	                session,
   263	                auth_user_id,
   264	                scope_id,
   265	                [{"role": "user", "content": message}, {"role": "assistant", "content": text}],
   266	            )
   267	        return {"type": "general", "message": text}
   268	
   269	    # Widget scope guard: the model classified another section's entity — redirect
   270	    # gently instead of silently answering out of the widget's scope.
   271	    is_compatible = classification.target_entity == resolved_tab_id or (
   272	        classification.target_entity is not None
   273	        and classification.target_entity in COMPATIBLE_ENTITIES.get(effective_tab_id, [])
   274	    )
   275	    if (
   276	        not is_universal_chat
   277	        and classification.target_entity
   278	        and not is_compatible
   279	        and classification.intent in ("query", "analytics", "create")
   280	    ):
   281	        gpt_label = get_tab_label(classification.target_entity)
   282	        scope_msg = (
   283	            f"Этот помощник отвечает только за раздел «{tab_label}». Для вопросов по разделу "
   284	            f"«{gpt_label}» перейдите на соответствующую страницу или используйте «Чат с ИИ»."
   285	        )
   286	        await log_ai_gateway_event(
   287	            "SCOPE_REDIRECT",
   288	            actor_id=actor_id,
   289	            operation="/api/ai/chat",
   290	            details={
   291	                "from": effective_tab_id,
   292	                "to": classification.target_entity,
   293	                "message": message[:200],
   294	            },
   295	        )
   296	        return await reply_general(scope_msg)
   297	
   298	    if target_entity is None and classification.intent in ("query", "analytics"):
   299	        if _PLANNING_RE.search(message):
   300	            target_entity = "calendar"

exec
/bin/zsh -lc "nl -ba apps/focal/server/app/ai/chat_support.py | sed -n '1,240p'" in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
     1	# ruff: noqa: RUF001 — legacy-ported Russian UI strings legitimately mix scripts
     2	"""Shared support for the in-app AI chat — the port of the legacy route-layer helpers:
     3	tab labels, per-tab fallback questions, question normalization, the conversation memory
     4	(load/append/clear over focal.ai_conversations with a 1-hour TTL and an hourly sweep),
     5	and the memory-scope key formula shared by the chat and conversation-clear routes."""
     6	
     7	import re
     8	from datetime import UTC, datetime, timedelta
     9	
    10	from sqlalchemy import delete, select
    11	from sqlalchemy.exc import SQLAlchemyError
    12	from sqlalchemy.ext.asyncio import AsyncSession
    13	
    14	from app.ai_gateway import log_ai_gateway_event
    15	from app.models.ai import AiConversation
    16	
    17	TAB_LABELS: dict[str, str] = {
    18	    "calendar": "Календарь",
    19	    "tasks": "Задачи",
    20	    "events": "События",
    21	    "goals": "Карта целей",
    22	    "heatmap": "Тепловая карта",
    23	    "time-budgets": "Бюджеты времени",
    24	    "analytics": "Аналитика",
    25	    "calendars": "Календари",
    26	    "integrations": "Интеграции",
    27	    "help": "Справка",
    28	    "tags": "Теги",
    29	    "habits": "Привычки",
    30	    "ai-chat": "Чат с ИИ",
    31	}
    32	
    33	# Every fallback question must be answerable by an entity handler.
    34	FALLBACK_QUESTIONS: dict[str, list[str]] = {
    35	    "calendar": [
    36	        "Что у меня запланировано на сегодня?",
    37	        "Какие события на этой неделе?",
    38	        "Добавь встречу завтра в 15:00",
    39	    ],
    40	    "tasks": [
    41	        "Какие у меня задачи на сегодня?",
    42	        "Покажи просроченные задачи",
    43	        "Задачи с высоким приоритетом",
    44	    ],
    45	    "events": [
    46	        "Покажи ближайшие события",
    47	        "Сколько событий в этом месяце?",
    48	        "Какие события без проекта?",
    49	    ],
    50	    "goals": [
    51	        "Какие цели у меня активны?",
    52	        "Какой прогресс по целям?",
    53	        "Что сейчас в приоритете по целям?",
    54	    ],
    55	    "heatmap": [
    56	        "Где у меня пик загрузки?",
    57	        "Какие дни самые свободные?",
    58	        "Как выглядит баланс недели?",
    59	    ],
    60	    "time-budgets": [
    61	        "Сколько часов выделено по проектам?",
    62	        "Как распределены бюджеты времени?",
    63	        "Сколько часов у меня по сферам?",
    64	    ],
    65	    "analytics": [
    66	        "Какой самый загруженный день?",
    67	        "Сводка за этот месяц",
    68	        "Где больше всего времени по проектам?",
    69	    ],
    70	    "calendars": [
    71	        "Какие календари у меня активны?",
    72	        "Сколько участников в общих календарях?",
    73	        "Что синхронизируется с Google?",
    74	    ],
    75	    "integrations": [
    76	        "Подключён ли Google Calendar?",
    77	        "Какой email привязан к синхронизации?",
    78	        "Включена ли автосинхронизация?",
    79	    ],
    80	    "help": [
    81	        "Что такое Миссия в Focal?",
    82	        "Как работает энергия?",
    83	        "Зачем нужны сферы жизни?",
    84	    ],
    85	    "tags": [
    86	        "Покажи все мои теги",
    87	        "Сколько у меня тегов?",
    88	        "Создай тег работа",
    89	    ],
    90	    "habits": [
    91	        "Какие у меня привычки?",
    92	        "Статистика привычек за месяц",
    93	        "Что такое петля привычки?",
    94	    ],
    95	    "ai-chat": [
    96	        "Какие задачи на сегодня?",
    97	        "Покажи ближайшие события",
    98	        "Какой прогресс по целям?",
    99	    ],
   100	}
   101	
   102	_DEFAULT_FALLBACK = [
   103	    "Что можно сделать в этом разделе?",
   104	    "Какие есть быстрые действия?",
   105	    "С чего начать работу?",
   106	]
   107	
   108	# 10 rows = 5 full user+assistant turns; older context confuses follow-up routing.
   109	CONV_HISTORY_LIMIT = 10
   110	CONV_TTL = timedelta(hours=1)
   111	
   112	UUID_RE = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", re.I)
   113	
   114	
   115	def get_tab_label(tab_id: str) -> str:
   116	    return TAB_LABELS.get(tab_id, "Раздел")
   117	
   118	
   119	def get_fallback_questions(tab_id: str) -> list[str]:
   120	    return FALLBACK_QUESTIONS.get(tab_id, list(_DEFAULT_FALLBACK))
   121	
   122	
   123	def normalize_question(question: str) -> str:
   124	    """Lowercased, politeness-words and punctuation stripped, whitespace collapsed —
   125	    the dedupe key for question stats."""
   126	    text = question.lower()
   127	    text = re.sub(r"\b(пожалуйста|можешь|давай)\b", " ", text, flags=re.I)
   128	    text = re.sub(r"[^\w\s]|_", " ", text, flags=re.UNICODE)
   129	    return re.sub(r"\s+", " ", text).strip()
   130	
   131	
   132	def format_question_for_display(normalized: str) -> str:
   133	    trimmed = normalized.strip()
   134	    if not trimmed:
   135	        return ""
   136	    capitalized = trimmed[0].upper() + trimmed[1:]
   137	    return capitalized if capitalized.endswith("?") else f"{capitalized}?"
   138	
   139	
   140	def memory_scope(conversation_id: str, data_owner: str, auth_user_id: str) -> str:
   141	    """The conversation bucket key, shared by the chat and clear routes: viewing another
   142	    owner's shared calendar gets its own bucket so contexts never mix between owners."""
   143	    if data_owner != auth_user_id:
   144	        return f"{conversation_id.strip()[:50]}:{data_owner}"
   145	    return conversation_id.strip()[:100]
   146	
   147	
   148	def memory_scope_owner(body_user_id: object, auth_user_id: str) -> str:
   149	    """The owner component of the conversation-MEMORY scope key only — NOT a data-access decision.
   150	    Returns the body's userId when it is a UUID, else the authenticated user, so a shared-calendar
   151	    bucket's memory clears under the same key the chat route wrote it with. It does NOT authorize
   152	    access to that owner's data and must NOT be used to scope reads/writes — it deliberately trusts
   153	    any UUID (the rows it keys are themselves filtered by the authenticated user_id). For RBAC-gated
   154	    data-owner resolution use ``app.data_scope.resolve_ai_data_owner``."""
   155	    if isinstance(body_user_id, str) and UUID_RE.match(body_user_id.strip()):
   156	        return body_user_id.strip()
   157	    return auth_user_id
   158	
   159	
   160	# Hour-bucket latch so at most one TTL sweep runs per process-hour.
   161	_conv_sweep_last_hour = ""
   162	
   163	
   164	async def sweep_stale_conversation_rows(session: AsyncSession) -> None:
   165	    """Hourly deferred cleanup of expired dialog rows; failures log and never propagate."""
   166	    global _conv_sweep_last_hour
   167	    hour_bucket = datetime.now(UTC).strftime("%Y-%m-%dT%H")
   168	    if _conv_sweep_last_hour == hour_bucket:
   169	        return
   170	    _conv_sweep_last_hour = hour_bucket
   171	    try:
   172	        cutoff = datetime.now(UTC) - CONV_TTL
   173	        await session.execute(delete(AiConversation).where(AiConversation.created_at < cutoff))
   174	        await session.commit()
   175	    except (SQLAlchemyError, OSError) as exc:
   176	        await log_ai_gateway_event(
   177	            "CONVERSATION_SWEEP_FAILED",
   178	            operation="sweep_stale_conversation_rows",
   179	            details={"errorMessage": str(exc)},
   180	        )
   181	
   182	
   183	def reset_conversation_sweep_latch() -> None:
   184	    """Test hook."""
   185	    global _conv_sweep_last_hour
   186	    _conv_sweep_last_hour = ""
   187	
   188	
   189	async def load_conversation_history(
   190	    session: AsyncSession, user_id: str, conversation_id: str
   191	) -> list[dict[str, str]]:
   192	    """The last 5 full turns for (user, conversation) inside the TTL window, oldest
   193	    first (the order OpenAI expects). Ordering by (created_at DESC, seq_in_turn DESC)
   194	    then reversing keeps assistant after user inside one same-timestamp insert; a
   195	    leading orphaned assistant row (its user message fell off the window) is dropped.
   196	    Never raises — a DB failure logs and yields an empty history."""
   197	    await sweep_stale_conversation_rows(session)
   198	    try:
   199	        cutoff = datetime.now(UTC) - CONV_TTL
   200	        rows = (
   201	            await session.execute(
   202	                select(AiConversation.role, AiConversation.content)
   203	                .where(
   204	                    AiConversation.user_id == user_id,
   205	                    AiConversation.conversation_id == conversation_id,
   206	                    AiConversation.created_at >= cutoff,
   207	                )
   208	                .order_by(AiConversation.created_at.desc(), AiConversation.seq_in_turn.desc())
   209	                .limit(CONV_HISTORY_LIMIT)
   210	            )
   211	        ).all()
   212	        ordered = [{"role": role, "content": content} for role, content in reversed(rows)]
   213	        if ordered and ordered[0]["role"] == "assistant":
   214	            ordered.pop(0)
   215	        return ordered
   216	    except (SQLAlchemyError, OSError) as exc:
   217	        await log_ai_gateway_event(
   218	            "CONVERSATION_LOAD_FAILED",
   219	            actor_id=f"user:{user_id}",
   220	            operation="load_conversation_history",
   221	            details={"conversationId": conversation_id, "errorMessage": str(exc)},
   222	        )
   223	        return []
   224	
   225	
   226	async def append_conversation_messages(
   227	    session: AsyncSession,
   228	    user_id: str,
   229	    conversation_id: str,
   230	    messages: list[dict[str, str]],
   231	) -> None:
   232	    """Persist one turn's messages; seq_in_turn (list position) keeps user before
   233	    assistant even under one shared timestamp. Never raises."""
   234	    if not messages:
   235	        return
   236	    try:
   237	        session.add_all(
   238	            AiConversation(
   239	                user_id=user_id,
   240	                conversation_id=conversation_id,

exec
/bin/zsh -lc 'rg "require_ai_write|resolve_ai_data_owner|resolve_memory_scope_owner|DataDomain|calendar" apps/focal/server/app/api/ai_chat.py apps/focal/server/app/api/ai.py apps/focal/server/app/ai -n' in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
apps/focal/server/app/api/ai.py:110:    with the same formula the chat route uses when writing, so shared-calendar buckets
apps/focal/server/app/api/ai_chat.py:70:from app.data_scope import DataDomain, require_ai_write, resolve_ai_data_owner
apps/focal/server/app/api/ai_chat.py:104:    "calendar": ["events", "tasks"],
apps/focal/server/app/api/ai_chat.py:105:    "events": ["calendar"],
apps/focal/server/app/api/ai_chat.py:106:    "tasks": ["calendar"],
apps/focal/server/app/api/ai_chat.py:107:    "meeting-requests": ["calendar", "events"],
apps/focal/server/app/api/ai_chat.py:202:    effective_tab_id = (payload.tab_id or "").strip() or "calendar"
apps/focal/server/app/api/ai_chat.py:204:    data_owner = await resolve_ai_data_owner(session, auth_user_id, payload.user_id)
apps/focal/server/app/api/ai_chat.py:238:    is_calendar_tab = effective_tab_id in ("calendar", "ai-chat")
apps/focal/server/app/api/ai_chat.py:244:        and resolved_tab_id == "calendar"
apps/focal/server/app/api/ai_chat.py:245:        and classification.target_entity in COMPATIBLE_ENTITIES["calendar"]
apps/focal/server/app/api/ai_chat.py:253:    # Shared-calendar MANAGEMENT (the "calendars" entity) is owner-only and NOT delegatable: a
apps/focal/server/app/api/ai_chat.py:255:    # shared calendars/participants through the AI (it falls under the other-pages gate otherwise).
apps/focal/server/app/api/ai_chat.py:256:    if data_owner != auth_user_id and target_entity == "calendars":
apps/focal/server/app/api/ai_chat.py:257:        raise PermissionDeniedError("Shared-calendar management is not available for another user")
apps/focal/server/app/api/ai_chat.py:300:            target_entity = "calendar"
apps/focal/server/app/api/ai_chat.py:317:        await require_ai_write(
apps/focal/server/app/api/ai_chat.py:321:            domain=DataDomain.CALENDAR
apps/focal/server/app/api/ai_chat.py:322:            if (target_entity or "") in ("calendar", "events")
apps/focal/server/app/api/ai_chat.py:323:            else DataDomain.OTHER_PAGES,
apps/focal/server/app/api/ai_chat.py:354:        if classification.intent == "create" and target_entity in ("calendar", "events"):
apps/focal/server/app/api/ai_chat.py:362:                "calendars": 'Попробуйте: "Создай календарь <название>"',
apps/focal/server/app/api/ai_chat.py:422:        if is_calendar_tab:
apps/focal/server/app/api/ai_chat.py:436:    # intent == "create" with calendar/events and no deterministic handler: GPT dialog.
apps/focal/server/app/api/ai_chat.py:483:- "calendar" — запросы по дате, поиск по событиям, создание событий: "что на завтра", "найди встречу с Иваном"
apps/focal/server/app/api/ai_chat.py:489:- "calendars" — общие календари, фильтры, участники
apps/focal/server/app/api/ai_chat.py:503:  "targetEntity": "calendar" | "events" | "heatmap" | "tasks" | "goals" | "time-budgets" | "calendars" | "integrations" | "habits" | "tags" | "analytics" | null,
apps/focal/server/app/ai/json_parsing.py:4:route-level completeness check can re-ask; calendar-invalid dates are rejected)."""
apps/focal/server/app/ai/json_parsing.py:101:    # Rejects calendar-invalid dates like 2026-02-31; non-strings/absent stay None.
apps/focal/server/app/ai/json_parsing.py:163:    "calendar",
apps/focal/server/app/ai/json_parsing.py:169:    "calendars",
apps/focal/server/app/ai/json_parsing.py:181:            "calendar",
apps/focal/server/app/ai/json_parsing.py:187:            "calendars",
apps/focal/server/app/ai/user_datetime.py:56:    """YYYY-MM-DD format plus calendar round-trip (rejects 2026-02-31).
apps/focal/server/app/ai/user_datetime.py:863:def get_days_in_calendar_year(year: int) -> int:
apps/focal/server/app/ai/user_datetime.py:864:    """Days in a Gregorian calendar year (365 or 366)."""
apps/focal/server/app/ai/date_ranges.py:25:All functions are pure calendar math on datetime.date — the result is fully
apps/focal/server/app/ai/date_ranges.py:31:from calendar import monthrange
apps/focal/server/app/ai/date_ranges.py:497:    """The current calendar month — the default range for many handlers."""
apps/focal/server/app/ai/entity_handlers.py:7:  calendar        — events+tasks by date, text search                [query, analytics]
apps/focal/server/app/ai/entity_handlers.py:13:  calendars       — shared calendars                                 [query, analytics, create]
apps/focal/server/app/ai/entity_handlers.py:21:the google branch of calendars/query) answers the legacy not-connected shape
apps/focal/server/app/ai/entity_handlers.py:26:from calendar import monthrange
apps/focal/server/app/ai/entity_handlers.py:50:from app.models.shared_calendar import SharedCalendarParticipant
apps/focal/server/app/ai/entity_handlers.py:52:from app.schemas.calendar import EnrichedEventRead
apps/focal/server/app/ai/entity_handlers.py:54:from app.schemas.shared_calendar import SharedCalendarCreate
apps/focal/server/app/ai/entity_handlers.py:57:from app.services.calendar import CalendarService
apps/focal/server/app/ai/entity_handlers.py:60:from app.services.shared_calendars import SharedCalendarsService
apps/focal/server/app/ai/entity_handlers.py:176:    """Events grouped by project: count + minutes. For calendar/analytics and cross-entity."""
apps/focal/server/app/ai/entity_handlers.py:444:@register("calendar", "query")
apps/focal/server/app/ai/entity_handlers.py:445:async def calendar_query(session: AsyncSession, ctx: EntityCtx) -> EntityResult | None:
apps/focal/server/app/ai/entity_handlers.py:562:@register("calendar", "analytics")
apps/focal/server/app/ai/entity_handlers.py:563:async def calendar_analytics(session: AsyncSession, ctx: EntityCtx) -> EntityResult | None:
apps/focal/server/app/ai/entity_handlers.py:1329:# CALENDARS (shared calendars)
apps/focal/server/app/ai/entity_handlers.py:1333:@register("calendars", "query")
apps/focal/server/app/ai/entity_handlers.py:1334:async def calendars_query(session: AsyncSession, ctx: EntityCtx) -> EntityResult | None:
apps/focal/server/app/ai/entity_handlers.py:1345:@register("calendars", "analytics")
apps/focal/server/app/ai/entity_handlers.py:1346:async def calendars_analytics(session: AsyncSession, ctx: EntityCtx) -> EntityResult | None:
apps/focal/server/app/ai/entity_handlers.py:1356:                .where(SharedCalendarParticipant.shared_calendar_id == cal.id)
apps/focal/server/app/ai/entity_handlers.py:1363:@register("calendars", "create")
apps/focal/server/app/ai/entity_handlers.py:1364:async def calendars_create(session: AsyncSession, ctx: EntityCtx) -> EntityResult | None:
apps/focal/server/app/ai/chat_support.py:18:    "calendar": "Календарь",
apps/focal/server/app/ai/chat_support.py:25:    "calendars": "Календари",
apps/focal/server/app/ai/chat_support.py:35:    "calendar": [
apps/focal/server/app/ai/chat_support.py:70:    "calendars": [
apps/focal/server/app/ai/chat_support.py:142:    owner's shared calendar gets its own bucket so contexts never mix between owners."""
apps/focal/server/app/ai/chat_support.py:150:    Returns the body's userId when it is a UUID, else the authenticated user, so a shared-calendar
apps/focal/server/app/ai/chat_support.py:154:    data-owner resolution use ``app.data_scope.resolve_ai_data_owner``."""
apps/focal/server/app/ai/help_corpus.py:4:priorities, calendars, the five dimensions, formulas, AI agents, and the Margulan methodology.
apps/focal/server/app/ai/help_corpus.py:95:        chunk_id="calendars-001",
apps/focal/server/app/ai/help_corpus.py:96:        section="calendars",
apps/focal/server/app/ai/help_corpus.py:137:Страница: /calendars""",
apps/focal/server/app/ai/help_corpus.py:381:        compact_content="""Источники данных аналитики: calendar_events (часы, выполнение), tasks (статус, проект), projects (тип mission/provision, сфера, часы, энергия), life_spheres (план по сфере), bookings (брони периодов).""",
apps/focal/server/app/ai/help_corpus.py:384:calendar_events — события календаря:
apps/focal/server/app/ai/help_corpus.py:477:        compact_content="""Webhook-уведомления: 7 типов событий (calendar_event.created/updated/deleted, task.created/updated/deleted/completed). HMAC-SHA256 подпись, 3 попытки при 5xx, авто-отключение после 3 подряд 4xx.""",
apps/focal/server/app/ai/help_corpus.py:485:Календарь: calendar_event.created, calendar_event.updated, calendar_event.deleted
apps/focal/server/app/ai/help_corpus.py:509:2. URL вида: /api/ai-agent/v1/calendar.ics?ical_token=...
apps/focal/server/app/ai/embeddings.py:41:from app.services.calendar import CalendarService
apps/focal/server/app/ai/embeddings.py:620:    "data": ["данные", "откуда", "источник", "таблица", "calendar_events", "tasks", "projects"],
apps/focal/server/app/ai/embeddings.py:621:    "calendars": [
apps/focal/server/app/ai/embeddings.py:655:        "google calendar",

exec
/bin/zsh -lc "nl -ba apps/focal/server/app/api/ai_chat.py | sed -n '300,470p'" in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
   300	            target_entity = "calendar"
   301	        else:
   302	            return await reply_general(
   303	                "Уточните, что именно вас интересует:\n\n"
   304	                "- **События/календарь** — расписание, встречи\n"
   305	                "- **Задачи** — дела, to-do\n"
   306	                "- **Цели** — прогресс, приоритеты\n"
   307	                "- **Бюджеты времени** — часы по проектам/сферам\n"
   308	                "- **Загрузка** — пики, свободные дни, баланс\n"
   309	                "- **Теги, календари, интеграции**"
   310	            )
   311	    if target_entity is None and classification.intent == "create":
   312	        return await reply_general(
   313	            "Что именно создать? Уточните: событие, задачу или что-то другое."
   314	        )
   315	
   316	    if classification.intent == "create" and data_owner != auth_user_id:
   317	        await require_ai_write(
   318	            session,
   319	            auth_user_id,
   320	            data_owner,
   321	            domain=DataDomain.CALENDAR
   322	            if (target_entity or "") in ("calendar", "events")
   323	            else DataDomain.OTHER_PAGES,
   324	        )
   325	
   326	    if classification.intent in ("query", "analytics", "create"):
   327	        user_tz = _sanitize_timezone(payload.display_timezone)
   328	        now_hours, now_minutes = _now_in_timezone(user_tz) if user_tz else (None, None)
   329	        ctx = EntityCtx(
   330	            user_id=data_owner,
   331	            message=message,
   332	            today_str=safe_today,
   333	            display_timezone=user_tz,
   334	            query_date=classification.query_date,
   335	            query_date_end=classification.query_date_end,
   336	            query_text=classification.query_text,
   337	            now_hours=now_hours,
   338	            now_minutes=now_minutes,
   339	        )
   340	        entity_result = await dispatch_entity_intent(
   341	            session, target_entity or "", classification.intent, ctx
   342	        )
   343	        if entity_result is not None:
   344	            await append_conversation_messages(
   345	                session,
   346	                auth_user_id,
   347	                scope_id,
   348	                [
   349	                    {"role": "user", "content": message},
   350	                    {"role": "assistant", "content": entity_result.message},
   351	                ],
   352	            )
   353	            return entity_result.to_payload()
   354	        if classification.intent == "create" and target_entity in ("calendar", "events"):
   355	            pass  # fall through to the GPT create dialog below
   356	        elif classification.intent == "create":
   357	            create_hints = {
   358	                "tasks": 'Попробуйте: "Создай задачу <название>"',
   359	                "goals": "Цели создаются вручную на странице «Карта целей».",
   360	                "tags": 'Попробуйте: "Создай тег <название>"',
   361	                "time-budgets": 'Попробуйте: "Создай проект <название> с N часами"',
   362	                "calendars": 'Попробуйте: "Создай календарь <название>"',
   363	            }
   364	            hint = create_hints.get(target_entity or "", "Уточните, что именно создать.")
   365	            return await reply_general(f"Не удалось распознать запрос на создание. {hint}")
   366	        else:
   367	            questions = get_fallback_questions(effective_tab_id)
   368	            listed = "\n".join(f"- {q}" for q in questions)
   369	            return await reply_general(
   370	                "Извините, я не смог найти информацию по этому запросу. Попробуйте "
   371	                f"переформулировать или выберите один из вопросов:\n\n{listed}"
   372	            )
   373	
   374	    if classification.intent == "help":
   375	        return await _help_flow(
   376	            request,
   377	            session,
   378	            auth_user_id=auth_user_id,
   379	            actor_id=actor_id,
   380	            question=message,
   381	            conversation_id=scope_id,
   382	            history=history,
   383	            display_timezone=payload.display_timezone,
   384	            operation="/api/ai/chat:help",
   385	            wants_stream=_wants_stream(request, payload.stream),
   386	            tab_restriction=(
   387	                ""
   388	                if is_universal_chat
   389	                else f"\n\n{tab_context_line}\nОтвечай только в рамках текущей вкладки. "
   390	                "Если вопрос не относится к ней — мягко поясни и предложи переформулировать."
   391	            ),
   392	        )
   393	
   394	    if classification.intent == "out_of_scope":
   395	        out_msg = (
   396	            "Извините, я могу помочь только с вопросами о планировании жизни в Focal. "
   397	            "Попробуйте спросить о событиях, задачах, целях или системе."
   398	            if is_universal_chat
   399	            else f"Извините, я могу помочь только с вопросами о разделе «{tab_label}». "
   400	            "Попробуйте переформулировать или используйте Чат с ИИ для общих вопросов."
   401	        )
   402	        await log_ai_gateway_event(
   403	            "OUT_OF_SCOPE",
   404	            source="OPENAI",
   405	            actor_id=actor_id,
   406	            operation="/api/ai/chat",
   407	            details={"message": message[:200]},
   408	        )
   409	        # Dead-end — deliberately not saved to history.
   410	        return await reply_general(out_msg, save=False)
   411	
   412	    if classification.intent == "general":
   413	        if effective_tab_id == "ai-chat":
   414	            return await reply_general(
   415	                "Привет! Я универсальный ИИ‑ассистент Focal. Могу помочь:\n\n"
   416	                '- **Вопросы о системе**: "Что такое Миссия?", "Как работает энергия?"\n'
   417	                '- **Создать событие**: "Встреча с Иваном завтра в 14:00"\n'
   418	                '- **Посмотреть расписание**: "Что у меня на этой неделе?"\n'
   419	                '- **Аналитика**: "Сколько встреч за месяц?"\n\n'
   420	                "Что бы вы хотели сделать?"
   421	            )
   422	        if is_calendar_tab:
   423	            return await reply_general(
   424	                "Привет! Я могу помочь вам:\n\n"
   425	                '- **Создать событие**: "Встреча с Иваном завтра в 14:00"\n'
   426	                '- **Посмотреть расписание**: "Какие у меня встречи на 12-е?"\n'
   427	                '- **Аналитика**: "Сколько у меня встреч на этой неделе?"\n\n'
   428	                "Что бы вы хотели сделать?"
   429	            )
   430	        questions = get_fallback_questions(effective_tab_id)
   431	        listed = "\n".join(f"- {q}" for q in questions)
   432	        return await reply_general(
   433	            f"Привет! Вы на вкладке «{tab_label}». Попробуйте спросить:\n\n{listed}"
   434	        )
   435	
   436	    # intent == "create" with calendar/events and no deterministic handler: GPT dialog.
   437	    return await _create_event_dialog(
   438	        session,
   439	        auth_user_id=auth_user_id,
   440	        actor_id=actor_id,
   441	        data_owner=data_owner,
   442	        scope_id=scope_id,
   443	        message=message,
   444	        current_event=payload.current_event,
   445	        safe_today=safe_today,
   446	        user_today=payload.user_today,
   447	        tab_context_line=tab_context_line,
   448	        history=history,
   449	    )
   450	
   451	
   452	def _build_classify_prompt(safe_today: str, message: str) -> str:
   453	    return f"""Ты - умный помощник для системы планирования жизни Focal на русском языке.
   454	Определи намерение пользователя и целевую сущность по его сообщению.
   455	
   456	ВАЖНО: Focal — это система управления жизнью с 5 измерениями: Смысл, Энергия, Время, Гармония, Продуктивность.
   457	Ключевые концепции: Миссия, Обеспечение, Цель жизни, Сферы жизни, Бюджеты времени, Брони, MindMap.
   458	
   459	Типы намерений (проверяй в этом порядке):
   460	
   461	1. "help" - ЛЮБОЙ вопрос о системе Focal, концепциях, философии:
   462	   - "что такое миссия", "как работает энергия", "зачем нужны брони", "как считается баланс"
   463	   - Ключевые слова: энергия, миссия, обеспечение, баланс, гармония, смысл, сферы жизни, цель жизни
   464	
   465	2. "query" - запросы о ЛИЧНЫХ данных пользователя:
   466	   - "какие у меня встречи", "задачи на сегодня", "покажи цели", "какие теги"
   467	
   468	3. "create" - создание нового объекта:
   469	   - "создай задачу", "добавь событие", "создай тег" (цели создаются только вручную)
   470	

exec
/bin/zsh -lc "rg \"Depends\\(get_current_user_id\\)\" apps/focal/server/app/api -n" in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
apps/focal/server/app/api/push.py:29:    _user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/push.py:39:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/push.py:48:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/push.py:56:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/push.py:65:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/push.py:73:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/calendar.py:34:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/calendar.py:50:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/calendar.py:65:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/calendar.py:84:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/calendar.py:108:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/calendar_init.py:30:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/ai.py:48:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/ai.py:76:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/ai.py:106:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/ai_chat.py:191:    auth_user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/ai_chat.py:878:    auth_user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/ai_chat.py:1046:    auth_user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/ai_chat.py:1219:    auth_user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/ai_chat.py:1393:    _auth_user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/user_account.py:20:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/integrations.py:53:    _user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/integrations.py:61:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/integrations.py:69:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/integrations.py:79:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/integrations.py:88:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/integrations.py:97:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/integrations.py:109:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/integrations.py:118:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/integrations.py:129:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/integrations.py:144:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/integrations.py:163:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/integrations.py:177:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/integrations.py:186:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/integrations.py:196:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/integrations.py:213:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/integrations.py:222:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/integrations.py:230:    _user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/settings.py:20:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/settings.py:29:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/bookings.py:32:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/bookings.py:48:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/bookings.py:63:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/bookings.py:77:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/bookings.py:90:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/ical.py:21:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/ical.py:36:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/agent_tokens.py:31:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/agent_tokens.py:46:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/agent_tokens.py:55:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/agent_tokens.py:68:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/agent_tokens.py:85:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/agent_tokens.py:94:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/agent_tokens.py:106:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/agent_tokens.py:118:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/agent_tokens.py:130:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/agent_tokens.py:144:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/shared_calendars.py:42:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/shared_calendars.py:50:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/shared_calendars.py:58:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/shared_calendars.py:67:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/shared_calendars.py:77:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/shared_calendars.py:88:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/shared_calendars.py:97:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/shared_calendars.py:107:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/shared_calendars.py:116:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/shared_calendars.py:126:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/shared_calendars.py:136:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/shared_calendars.py:147:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/shared_calendars.py:159:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/shared_calendars.py:172:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/shared_calendars.py:185:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/backup.py:31:    user_id: str = Depends(get_current_user_id),
apps/focal/server/app/api/backup.py:40:    user_id: str = Depends(get_current_user_id),

exec
/bin/zsh -lc "rg \"data_owner_dep\\(\" apps/focal/server/app/api -n" in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
apps/focal/server/app/api/meeting_requests.py:16:_owner_read = data_owner_dep(DataDomain.CALENDAR, "read")
apps/focal/server/app/api/meeting_requests.py:17:_owner_write = data_owner_dep(DataDomain.CALENDAR, "write")
apps/focal/server/app/api/projects.py:12:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
apps/focal/server/app/api/projects.py:13:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
apps/focal/server/app/api/analytics.py:13:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
apps/focal/server/app/api/analytics.py:14:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
apps/focal/server/app/api/habit_entries.py:13:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
apps/focal/server/app/api/habit_entries.py:14:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
apps/focal/server/app/api/stats.py:14:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
apps/focal/server/app/api/stats.py:15:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
apps/focal/server/app/api/activity_instances.py:17:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
apps/focal/server/app/api/activity_instances.py:18:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
apps/focal/server/app/api/spheres.py:12:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
apps/focal/server/app/api/spheres.py:13:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
apps/focal/server/app/api/goals.py:12:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
apps/focal/server/app/api/goals.py:13:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
apps/focal/server/app/api/habits.py:13:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
apps/focal/server/app/api/habits.py:14:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
apps/focal/server/app/api/mindmap.py:12:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
apps/focal/server/app/api/mindmap.py:13:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
apps/focal/server/app/api/tasks.py:14:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
apps/focal/server/app/api/tasks.py:15:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
apps/focal/server/app/api/time_budgets.py:25:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
apps/focal/server/app/api/time_budgets.py:26:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
apps/focal/server/app/api/activities.py:12:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
apps/focal/server/app/api/activities.py:13:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
apps/focal/server/app/api/tags.py:14:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
apps/focal/server/app/api/tags.py:15:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")

exec
/bin/zsh -lc "for f in apps/focal/server/app/api/{tasks,projects,goals,spheres,tags,habits,habit_entries,time_budgets,analytics,stats,mindmap,bookings,meeting_requests,calendar_init}.py; do printf '\\n### %s\\n' \""'$f"; rg "Depends'"\\(|data_owner_dep|calendarId|get_current_user_id|@router\" \""'$f" -n; done' in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:

### apps/focal/server/app/api/tasks.py
6:from app.data_scope import DataDomain, data_owner_dep
14:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
15:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
25:@router.get("", response_model=list[EnrichedTaskRead])
29:    user_id: str = Depends(_owner_read),
30:    today: date = Depends(current_utc_date),
31:    service: TasksService = Depends(get_tasks_service),
36:@router.post("", response_model=TaskRead)
39:    user_id: str = Depends(_owner_write),
40:    today: date = Depends(current_utc_date),
41:    service: TasksService = Depends(get_tasks_service),
48:@router.get("/{task_id}", response_model=EnrichedTaskRead)
51:    user_id: str = Depends(_owner_read),
52:    service: TasksService = Depends(get_tasks_service),
57:@router.patch("/{task_id}", response_model=TaskRead)
61:    user_id: str = Depends(_owner_write),
62:    today: date = Depends(current_utc_date),
63:    service: TasksService = Depends(get_tasks_service),
68:@router.delete("/{task_id}")
71:    user_id: str = Depends(_owner_write),
72:    service: TasksService = Depends(get_tasks_service),

### apps/focal/server/app/api/projects.py
5:from app.data_scope import DataDomain, data_owner_dep
12:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
13:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
23:@router.get("", response_model=list[ProjectRead])
25:    user_id: str = Depends(_owner_read),
26:    service: ProjectsService = Depends(get_projects_service),
32:@router.get("/root", response_model=list[ProjectRead])
34:    user_id: str = Depends(_owner_read),
35:    service: ProjectsService = Depends(get_projects_service),
40:@router.post("", response_model=ProjectRead, status_code=status.HTTP_201_CREATED)
43:    user_id: str = Depends(_owner_write),
44:    service: ProjectsService = Depends(get_projects_service),
49:@router.get("/{project_id}", response_model=ProjectRead)
52:    user_id: str = Depends(_owner_read),
53:    service: ProjectsService = Depends(get_projects_service),
58:@router.get("/{project_id}/products", response_model=list[ProjectRead])
61:    user_id: str = Depends(_owner_read),
62:    service: ProjectsService = Depends(get_projects_service),
67:@router.patch("/{project_id}", response_model=ProjectRead)
71:    user_id: str = Depends(_owner_write),
72:    service: ProjectsService = Depends(get_projects_service),
77:@router.delete("/{project_id}")
80:    user_id: str = Depends(_owner_write),
81:    service: ProjectsService = Depends(get_projects_service),

### apps/focal/server/app/api/goals.py
5:from app.data_scope import DataDomain, data_owner_dep
12:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
13:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
21:@router.get("", response_model=list[GoalRead])
23:    user_id: str = Depends(_owner_read),
24:    service: GoalsService = Depends(get_goals_service),
29:@router.post("", response_model=GoalRead, status_code=status.HTTP_201_CREATED)
32:    user_id: str = Depends(_owner_write),
33:    service: GoalsService = Depends(get_goals_service),
38:@router.get("/{goal_id}", response_model=GoalRead)
41:    user_id: str = Depends(_owner_read),
42:    service: GoalsService = Depends(get_goals_service),
47:@router.patch("/{goal_id}", response_model=GoalRead)
51:    user_id: str = Depends(_owner_write),
52:    service: GoalsService = Depends(get_goals_service),
57:@router.delete("/{goal_id}")
60:    user_id: str = Depends(_owner_write),
61:    service: GoalsService = Depends(get_goals_service),

### apps/focal/server/app/api/spheres.py
5:from app.data_scope import DataDomain, data_owner_dep
12:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
13:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
22:@router.get("", response_model=list[SphereRead])
24:    user_id: str = Depends(_owner_read),
25:    service: SpheresService = Depends(get_spheres_service),
30:@router.post("", response_model=SphereRead, status_code=status.HTTP_201_CREATED)
33:    user_id: str = Depends(_owner_write),
34:    service: SpheresService = Depends(get_spheres_service),
39:@router.get("/{sphere_id}", response_model=SphereRead)
42:    user_id: str = Depends(_owner_read),
43:    service: SpheresService = Depends(get_spheres_service),
48:@router.patch("/{sphere_id}", response_model=SphereRead)
52:    user_id: str = Depends(_owner_write),
53:    service: SpheresService = Depends(get_spheres_service),
58:@router.delete("/{sphere_id}")
61:    user_id: str = Depends(_owner_write),
62:    service: SpheresService = Depends(get_spheres_service),

### apps/focal/server/app/api/tags.py
6:from app.data_scope import DataDomain, data_owner_dep
14:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
15:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
29:@router.get("", response_model=list[TagRead])
31:    user_id: str = Depends(_owner_read),
32:    service: TagsService = Depends(get_tags_service),
37:@router.post("", response_model=TagRead)
40:    user_id: str = Depends(_owner_write),
41:    service: TagsService = Depends(get_tags_service),
46:@router.patch("/{tag_id}", response_model=TagRead)
50:    user_id: str = Depends(_owner_write),
51:    service: TagsService = Depends(get_tags_service),
56:@router.delete("/{tag_id}")
59:    user_id: str = Depends(_owner_write),
60:    service: TagsService = Depends(get_tags_service),

### apps/focal/server/app/api/habits.py
6:from app.data_scope import DataDomain, data_owner_dep
13:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
14:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
22:@router.get("", response_model=list[HabitRead])
25:    user_id: str = Depends(_owner_read),
26:    service: HabitsService = Depends(get_habits_service),
32:@router.post("/reorder", status_code=status.HTTP_204_NO_CONTENT)
35:    user_id: str = Depends(_owner_write),
36:    service: HabitsService = Depends(get_habits_service),
42:@router.post("", response_model=HabitRead, status_code=status.HTTP_201_CREATED)
45:    user_id: str = Depends(_owner_write),
46:    service: HabitsService = Depends(get_habits_service),
52:@router.get("/streaks", response_model=list[HabitStreakRead])
55:    user_id: str = Depends(_owner_read),
56:    service: HabitsService = Depends(get_habits_service),
61:@router.get("/{habit_id}", response_model=HabitRead)
64:    user_id: str = Depends(_owner_read),
65:    service: HabitsService = Depends(get_habits_service),
70:@router.patch("/{habit_id}", response_model=HabitRead)
74:    user_id: str = Depends(_owner_write),
75:    service: HabitsService = Depends(get_habits_service),
80:@router.delete("/{habit_id}", status_code=status.HTTP_204_NO_CONTENT)
83:    user_id: str = Depends(_owner_write),
84:    service: HabitsService = Depends(get_habits_service),
90:@router.post("/{habit_id}/restore", response_model=HabitRead)
93:    user_id: str = Depends(_owner_write),
94:    service: HabitsService = Depends(get_habits_service),

### apps/focal/server/app/api/habit_entries.py
7:from app.data_scope import DataDomain, data_owner_dep
13:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
14:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
17:@router.get("", response_model=list[HabitEntryRead])
21:    user_id: str = Depends(_owner_read),
22:    service: HabitsService = Depends(get_habits_service),
27:@router.get("/stats", response_model=list[HabitEntryStatRead])
32:    user_id: str = Depends(_owner_read),
33:    service: HabitsService = Depends(get_habits_service),
38:@router.post("", response_model=HabitEntryRead, status_code=status.HTTP_201_CREATED)
41:    user_id: str = Depends(_owner_write),
42:    service: HabitsService = Depends(get_habits_service),
47:@router.delete("", status_code=status.HTTP_204_NO_CONTENT)
51:    user_id: str = Depends(_owner_write),
52:    service: HabitsService = Depends(get_habits_service),

### apps/focal/server/app/api/time_budgets.py
5:from app.data_scope import DataDomain, data_owner_dep
25:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
26:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
34:@router.get("/{year}", response_model=TimeBudgetYearRead)
37:    user_id: str = Depends(_owner_read),
38:    service: TimeBudgetsService = Depends(get_time_budgets_service),
43:@router.patch("/settings/{settings_id}", response_model=TimeBudgetSettingsRead)
47:    user_id: str = Depends(_owner_write),
48:    service: TimeBudgetsService = Depends(get_time_budgets_service),
53:@router.post(
58:    user_id: str = Depends(_owner_write),
59:    service: TimeBudgetsService = Depends(get_time_budgets_service),
64:@router.patch("/categories/{category_id}", response_model=TimeBudgetCategoryRead)
68:    user_id: str = Depends(_owner_write),
69:    service: TimeBudgetsService = Depends(get_time_budgets_service),
74:@router.delete("/categories/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
77:    user_id: str = Depends(_owner_write),
78:    service: TimeBudgetsService = Depends(get_time_budgets_service),
84:@router.post(
89:    user_id: str = Depends(_owner_write),
90:    service: TimeBudgetsService = Depends(get_time_budgets_service),
95:@router.patch("/subcategories/{subcategory_id}", response_model=TimeBudgetSubcategoryRead)
99:    user_id: str = Depends(_owner_write),
100:    service: TimeBudgetsService = Depends(get_time_budgets_service),
105:@router.delete("/subcategories/{subcategory_id}", status_code=status.HTTP_204_NO_CONTENT)
108:    user_id: str = Depends(_owner_write),
109:    service: TimeBudgetsService = Depends(get_time_budgets_service),
115:@router.post("/items", response_model=TimeBudgetItemRead, status_code=status.HTTP_201_CREATED)
118:    user_id: str = Depends(_owner_write),
119:    service: TimeBudgetsService = Depends(get_time_budgets_service),
124:@router.patch("/items/{item_id}", response_model=TimeBudgetItemRead)
128:    user_id: str = Depends(_owner_write),
129:    service: TimeBudgetsService = Depends(get_time_budgets_service),
134:@router.delete("/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
137:    user_id: str = Depends(_owner_write),
138:    service: TimeBudgetsService = Depends(get_time_budgets_service),

### apps/focal/server/app/api/analytics.py
6:from app.data_scope import DataDomain, data_owner_dep
13:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
14:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
22:@router.get("/spheres", response_model=SpheresAnalyticsRead)
26:    user_id: str = Depends(_owner_read),
27:    service: AnalyticsService = Depends(get_analytics_service),

### apps/focal/server/app/api/stats.py
6:from app.data_scope import DataDomain, data_owner_dep
14:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
15:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
23:@router.get("/orphans", response_model=OrphanStatsRead)
27:    user_id: str = Depends(_owner_read),
28:    today: date = Depends(current_utc_date),
29:    service: StatsService = Depends(get_stats_service),

### apps/focal/server/app/api/mindmap.py
5:from app.data_scope import DataDomain, data_owner_dep
12:_owner_read = data_owner_dep(DataDomain.OTHER_PAGES, "read")
13:_owner_write = data_owner_dep(DataDomain.OTHER_PAGES, "write")
22:@router.get("/api/mindmap/init", response_model=InitRead)
24:    user_id: str = Depends(_owner_read),
25:    service: MindmapService = Depends(get_mindmap_service),
33:@router.get("/api/mindmap-nodes", response_model=list[NodeRead])
35:    user_id: str = Depends(_owner_read),
36:    service: MindmapService = Depends(get_mindmap_service),
41:@router.post("/api/mindmap-nodes/batch", response_model=list[NodeRead])
44:    user_id: str = Depends(_owner_write),
45:    service: MindmapService = Depends(get_mindmap_service),
52:@router.get("/api/mindmap-nodes/{node_id}", response_model=NodeRead)
55:    user_id: str = Depends(_owner_read),
56:    service: MindmapService = Depends(get_mindmap_service),
61:@router.put("/api/mindmap-nodes/{node_id}", response_model=NodeRead)
65:    user_id: str = Depends(_owner_write),
66:    service: MindmapService = Depends(get_mindmap_service),
71:@router.delete("/api/mindmap-nodes/{node_id}", status_code=status.HTTP_204_NO_CONTENT)
74:    user_id: str = Depends(_owner_write),
75:    service: MindmapService = Depends(get_mindmap_service),
84:@router.get("/api/mindmap-edges", response_model=list[EdgeRead])
86:    user_id: str = Depends(_owner_read),
87:    service: MindmapService = Depends(get_mindmap_service),
92:@router.put("/api/mindmap-edges/{edge_id}", response_model=EdgeRead)
96:    user_id: str = Depends(_owner_write),
97:    service: MindmapService = Depends(get_mindmap_service),
102:@router.delete("/api/mindmap-edges/{edge_id}", status_code=status.HTTP_204_NO_CONTENT)
105:    user_id: str = Depends(_owner_write),
106:    service: MindmapService = Depends(get_mindmap_service),

### apps/focal/server/app/api/bookings.py
7:from app.deps import current_utc_date, get_current_user_id
21:    # In shared mode (a `calendarId` is supplied) bookings are RBAC-gated and held to the calendar's
27:@router.get("", response_model=list[BookingRead])
31:    calendar_id: str | None = Query(default=None, alias="calendarId"),
32:    user_id: str = Depends(get_current_user_id),
33:    today: date = Depends(current_utc_date),
34:    service: BookingsService = Depends(get_bookings_service),
35:    shared: SharedCalendarsService = Depends(get_shared_service),
44:@router.post("", response_model=BookingRead)
47:    calendar_id: str | None = Query(default=None, alias="calendarId"),
48:    user_id: str = Depends(get_current_user_id),
49:    service: BookingsService = Depends(get_bookings_service),
50:    shared: SharedCalendarsService = Depends(get_shared_service),
59:@router.get("/{booking_id}", response_model=BookingRead)
62:    calendar_id: str | None = Query(default=None, alias="calendarId"),
63:    user_id: str = Depends(get_current_user_id),
64:    service: BookingsService = Depends(get_bookings_service),
65:    shared: SharedCalendarsService = Depends(get_shared_service),
72:@router.patch("/{booking_id}", response_model=BookingRead)
76:    calendar_id: str | None = Query(default=None, alias="calendarId"),
77:    user_id: str = Depends(get_current_user_id),
78:    service: BookingsService = Depends(get_bookings_service),
79:    shared: SharedCalendarsService = Depends(get_shared_service),
86:@router.delete("/{booking_id}", status_code=status.HTTP_204_NO_CONTENT)
89:    calendar_id: str | None = Query(default=None, alias="calendarId"),
90:    user_id: str = Depends(get_current_user_id),
91:    service: BookingsService = Depends(get_bookings_service),
92:    shared: SharedCalendarsService = Depends(get_shared_service),

### apps/focal/server/app/api/meeting_requests.py
5:from app.data_scope import DataDomain, data_owner_dep
13:# request) = canEdit. `_owner_*` resolves the data owner from `calendarId`; the same `calendarId`
16:_owner_read = data_owner_dep(DataDomain.CALENDAR, "read")
17:_owner_write = data_owner_dep(DataDomain.CALENDAR, "write")
26:@router.get("", response_model=list[MeetingRequestRead])
29:    calendar_id: str | None = Query(default=None, alias="calendarId"),
30:    user_id: str = Depends(_owner_read),
31:    service: MeetingRequestsService = Depends(get_meeting_requests_service),
36:@router.get("/count")
38:    calendar_id: str | None = Query(default=None, alias="calendarId"),
39:    user_id: str = Depends(_owner_read),
40:    service: MeetingRequestsService = Depends(get_meeting_requests_service),
45:@router.get("/{request_id}", response_model=MeetingRequestRead)
48:    calendar_id: str | None = Query(default=None, alias="calendarId"),
49:    user_id: str = Depends(_owner_read),
50:    service: MeetingRequestsService = Depends(get_meeting_requests_service),
55:@router.delete("/{request_id}", status_code=status.HTTP_204_NO_CONTENT)
58:    calendar_id: str | None = Query(default=None, alias="calendarId"),
59:    user_id: str = Depends(_owner_write),
60:    service: MeetingRequestsService = Depends(get_meeting_requests_service),
66:@router.post("/{request_id}/accept", response_model=MeetingRequestActionRead)
69:    calendar_id: str | None = Query(default=None, alias="calendarId"),
70:    user_id: str = Depends(_owner_write),
71:    service: MeetingRequestsService = Depends(get_meeting_requests_service),
76:@router.post("/{request_id}/decline", response_model=MeetingRequestActionRead)
79:    calendar_id: str | None = Query(default=None, alias="calendarId"),
80:    user_id: str = Depends(_owner_write),
81:    service: MeetingRequestsService = Depends(get_meeting_requests_service),
86:@router.post("/{request_id}/tentative", response_model=MeetingRequestActionRead)
89:    calendar_id: str | None = Query(default=None, alias="calendarId"),
90:    user_id: str = Depends(_owner_write),
91:    service: MeetingRequestsService = Depends(get_meeting_requests_service),
96:@router.post("/{request_id}/accept-reschedule", response_model=MeetingRequestActionRead)
99:    calendar_id: str | None = Query(default=None, alias="calendarId"),
100:    user_id: str = Depends(_owner_write),
101:    service: MeetingRequestsService = Depends(get_meeting_requests_service),
108:@router.post("/{request_id}/decline-reschedule", response_model=MeetingRequestActionRead)
111:    calendar_id: str | None = Query(default=None, alias="calendarId"),
112:    user_id: str = Depends(_owner_write),
113:    service: MeetingRequestsService = Depends(get_meeting_requests_service),

### apps/focal/server/app/api/calendar_init.py
7:from app.deps import current_utc_date, get_current_user_id
25:@router.get("/init", response_model=CalendarInitRead)
29:    calendar_id: str | None = Query(default=None, alias="calendarId"),
30:    user_id: str = Depends(get_current_user_id),
31:    today: date = Depends(current_utc_date),
32:    service: CalendarInitService = Depends(get_calendar_init_service),
33:    shared: SharedCalendarsService = Depends(get_shared_service),

exec
/bin/zsh -lc "nl -ba apps/focal/server/app/services/bookings.py | sed -n '1,280p'" in /Users/allosta/Desktop/allosta/superapp-slice2
exec
/bin/zsh -lc "nl -ba apps/focal/server/app/services/meeting_requests.py | sed -n '1,340p'" in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
     1	import datetime
     2	from uuid import uuid4
     3	
     4	from sqlalchemy import select
     5	from sqlalchemy.ext.asyncio import AsyncSession
     6	
     7	from app.domain.daterange import get_date_range
     8	from app.errors import NotFoundError, RelatedRecordNotFoundError
     9	from app.models.bookings import Booking
    10	from app.models.projects import Project
    11	from app.schemas.bookings import BookingCreate, BookingRead, BookingUpdate
    12	
    13	
    14	class BookingsService:
    15	    """Bookings CRUD over ``focal.bookings``, tenant-scoped to the user. Ports legacy
    16	    ``/api/bookings`` (routes.ts:3436). The denormalized ``project`` / ``product`` /
    17	    ``project_type`` name labels are stored verbatim (the model keeps them by design); the
    18	    ``project_id`` / ``product_id`` FKs are validated as the caller's own. Every by-id op is
    19	    tenant-scoped, closing the legacy gap where get/update/delete had no owner check."""
    20	
    21	    def __init__(self, session: AsyncSession) -> None:
    22	        self.session = session
    23	
    24	    async def list_bookings(
    25	        self, user_id: str, *, start: str | None, end: str | None, today: datetime.date
    26	    ) -> list[BookingRead]:
    27	        # Strict containment (storage.ts:5115): the booking fully inside the window, by start_date.
    28	        window_start, window_end = get_date_range(start, end, today=today)
    29	        result = await self.session.execute(
    30	            select(Booking)
    31	            .where(
    32	                Booking.user_id == user_id,
    33	                Booking.start_date >= window_start,
    34	                Booking.end_date <= window_end,
    35	            )
    36	            .order_by(Booking.start_date)
    37	        )
    38	        return [BookingRead.model_validate(row) for row in result.scalars().all()]
    39	
    40	    async def get_booking(self, user_id: str, booking_id: str) -> BookingRead:
    41	        return BookingRead.model_validate(await self._require(user_id, booking_id))
    42	
    43	    async def create_booking(self, user_id: str, payload: BookingCreate) -> BookingRead:
    44	        await self._require_owned_link(user_id, payload.project_id, payload.product_id)
    45	        booking = Booking(
    46	            id=str(uuid4()),
    47	            user_id=user_id,
    48	            title=payload.title,
    49	            description=payload.description,
    50	            start_date=payload.start_date,
    51	            end_date=payload.end_date,
    52	            color=payload.color,
    53	            project=payload.project,
    54	            project_type=payload.project_type,
    55	            product=payload.product,
    56	            tags=payload.tags,
    57	            project_id=payload.project_id,
    58	            product_id=payload.product_id,
    59	        )
    60	        self.session.add(booking)
    61	        await self.session.commit()
    62	        await self.session.refresh(booking)
    63	        return BookingRead.model_validate(booking)
    64	
    65	    async def update_booking(
    66	        self, user_id: str, booking_id: str, payload: BookingUpdate
    67	    ) -> BookingRead:
    68	        booking = await self._require(user_id, booking_id)
    69	        data = payload.model_dump(exclude_unset=True)
    70	        await self._require_owned_link(user_id, data.get("project_id"), data.get("product_id"))
    71	        for field, value in data.items():
    72	            setattr(booking, field, value)
    73	        await self.session.commit()
    74	        await self.session.refresh(booking)
    75	        return BookingRead.model_validate(booking)
    76	
    77	    async def delete_booking(self, user_id: str, booking_id: str) -> None:
    78	        booking = await self._require(user_id, booking_id)
    79	        await self.session.delete(booking)
    80	        await self.session.commit()
    81	
    82	    # --- helpers -------------------------------------------------------------
    83	
    84	    async def _require(self, user_id: str, booking_id: str) -> Booking:
    85	        booking = await self.session.get(Booking, booking_id)
    86	        if booking is None or booking.user_id != user_id:
    87	            raise NotFoundError("Booking not found")
    88	        return booking
    89	
    90	    async def _owned_project(self, user_id: str, project_id: str | None) -> Project | None:
    91	        if not project_id:
    92	            return None
    93	        project = await self.session.get(Project, project_id)
    94	        if project is None or project.user_id != user_id:
    95	            return None
    96	        return project
    97	
    98	    async def _require_owned_link(
    99	        self, user_id: str, project_id: str | None, product_id: str | None
   100	    ) -> None:
   101	        for pid in (project_id, product_id):
   102	            if pid is not None and await self._owned_project(user_id, pid) is None:
   103	                raise RelatedRecordNotFoundError("Related record not found")

 succeeded in 0ms:
     1	import contextlib
     2	from datetime import UTC, datetime, tzinfo
     3	from zoneinfo import ZoneInfo
     4	
     5	from sqlalchemy import delete, func, select
     6	from sqlalchemy.ext.asyncio import AsyncSession
     7	
     8	from app.errors import ConflictError, NotFoundError
     9	from app.models.calendar import CalendarEvent
    10	from app.models.meeting_request import MeetingRequest
    11	from app.schemas.meeting_request import MeetingRequestActionRead, MeetingRequestRead
    12	from app.services.google_meetings import propagate_meeting_response, propagate_meeting_time
    13	from app.services.push import send_meeting_response_push, send_reschedule_response_push
    14	
    15	RESPONSE_STATUSES = ("accepted", "declined", "tentative")
    16	
    17	
    18	def _event_time_parts(moment: datetime, tz_name: str | None) -> tuple[datetime, str]:
    19	    """The (local datetime, HH:MM) pair a focal calendar event stores, computed in the
    20	    request's IANA timezone — the invite's wall-clock time, not the server's. An
    21	    unknown timezone falls back to UTC rather than failing the whole response."""
    22	    zone: tzinfo = UTC
    23	    if tz_name:
    24	        try:
    25	            zone = ZoneInfo(tz_name)
    26	        except KeyError, ValueError:
    27	            zone = UTC
    28	    local = moment.astimezone(zone)
    29	    return local, local.strftime("%H:%M")
    30	
    31	
    32	class MeetingRequestsService:
    33	    """Read/respond/delete surface for inbound Google meeting requests, tenant-scoped to the user.
    34	    Ports the legacy endpoints (routes.ts:6684) as a local state machine: status transitions plus
    35	    the focal calendar-event lifecycle (created on accept, deleted on decline, re-timed on
    36	    reschedule responses) plus the best-effort response push to the user's own devices. The
    37	    Google-side RSVP patch the legacy performed in the same handlers rides the deferred Google
    38	    sync and hooks into these actions when that phase lands."""
    39	
    40	    def __init__(self, session: AsyncSession) -> None:
    41	        self.session = session
    42	
    43	    async def list_requests(
    44	        self, user_id: str, *, status: str | None = None, calendar_id: str | None = None
    45	    ) -> list[MeetingRequestRead]:
    46	        # A meeting request belongs to a specific shared calendar (shared_calendar_id), so in shared
    47	        # mode it is scoped to the selected calendar — a viewer of one calendar never sees the
    48	        # owner's requests for another. Absent calendar_id → all the owner's requests (own-data).
    49	        stmt = select(MeetingRequest).where(MeetingRequest.user_id == user_id)
    50	        if calendar_id:
    51	            stmt = stmt.where(MeetingRequest.shared_calendar_id == calendar_id)
    52	        if status:
    53	            stmt = stmt.where(MeetingRequest.status == status)
    54	        stmt = stmt.order_by(MeetingRequest.start_time.desc())
    55	        result = await self.session.execute(stmt)
    56	        return [MeetingRequestRead.model_validate(row) for row in result.scalars().all()]
    57	
    58	    async def pending_count(self, user_id: str, *, calendar_id: str | None = None) -> int:
    59	        stmt = (
    60	            select(func.count())
    61	            .select_from(MeetingRequest)
    62	            .where(MeetingRequest.user_id == user_id, MeetingRequest.status == "pending")
    63	        )
    64	        if calendar_id:
    65	            stmt = stmt.where(MeetingRequest.shared_calendar_id == calendar_id)
    66	        result = await self.session.execute(stmt)
    67	        return int(result.scalar_one())
    68	
    69	    async def get_request(
    70	        self, user_id: str, request_id: str, *, calendar_id: str | None = None
    71	    ) -> MeetingRequestRead:
    72	        return MeetingRequestRead.model_validate(
    73	            await self._owned(user_id, request_id, calendar_id=calendar_id)
    74	        )
    75	
    76	    async def respond(
    77	        self, user_id: str, request_id: str, response: str, *, calendar_id: str | None = None
    78	    ) -> MeetingRequestActionRead:
    79	        """Answer a plain invitation: accepted / declined / tentative. Accept creates the
    80	        focal calendar event (once — a re-accept reuses the linked event); decline removes
    81	        it; tentative only records the answer. Mirroring the legacy handlers, a plain
    82	        response carries no status guard — the user may change their answer."""
    83	        if response not in RESPONSE_STATUSES:
    84	            raise ConflictError(f"Unknown meeting response '{response}'")
    85	        row = await self._owned(user_id, request_id, calendar_id=calendar_id)
    86	        row.status = response
    87	        row.responded_at = datetime.now(UTC)
    88	
    89	        event: CalendarEvent | None = None
    90	        if response == "accepted":
    91	            event = await self._linked_event(row)
    92	            if event is None:
    93	                start_local, start_hhmm = _event_time_parts(row.start_time, row.timezone)
    94	                _, end_hhmm = _event_time_parts(row.end_time, row.timezone)
    95	                event = CalendarEvent(
    96	                    user_id=row.user_id,
    97	                    title=row.title,
    98	                    date=start_local.date(),
    99	                    start_time=start_hhmm,
   100	                    end_time=end_hhmm,
   101	                    description=row.description,
   102	                    location=row.location,
   103	                    timezone=row.timezone,
   104	                    status="confirmed",
   105	                )
   106	                self.session.add(event)
   107	                await self.session.flush()
   108	                row.focal_event_id = event.id
   109	        elif response == "declined":
   110	            linked = await self._linked_event(row)
   111	            if linked is not None:
   112	                await self.session.delete(linked)
   113	            row.focal_event_id = None
   114	
   115	        await self.session.commit()
   116	        # Mirror the RSVP to the Google event when the user is connected; the local
   117	        # answer is authoritative either way (legacy required Google — relaxed here so
   118	        # answers still work after a disconnect).
   119	        with contextlib.suppress(Exception):
   120	            await propagate_meeting_response(self.session, row, response)
   121	        # Confirmation push to the responder's own devices (legacy parity); delivery is
   122	        # best-effort and must never fail the response itself.
   123	        with contextlib.suppress(Exception):
   124	            await send_meeting_response_push(self.session, user_id, row.title, response, row.id)
   125	        return self._action_result(row, event)
   126	
   127	    async def respond_reschedule(
   128	        self, user_id: str, request_id: str, *, accept: bool, calendar_id: str | None = None
   129	    ) -> MeetingRequestActionRead:
   130	        """Answer a proposed reschedule. The request's start/end already hold the
   131	        proposed time; the originals hold the pre-change time. Accept keeps the proposal
   132	        and re-times the linked event; decline reverts both the request and the event to
   133	        the original time. Unlike plain responses these are one-shot: only a pending
   134	        reschedule request can be answered."""
   135	        row = await self._owned(user_id, request_id, calendar_id=calendar_id)
   136	        if row.request_type != "reschedule":
   137	            raise ConflictError("Not a reschedule request")
   138	        if row.status != "pending":
   139	            raise ConflictError("Reschedule request already responded")
   140	
   141	        if accept:
   142	            row.status = "accepted"
   143	            target_start, target_end = row.start_time, row.end_time
   144	        else:
   145	            if row.original_start_time is None or row.original_end_time is None:
   146	                raise ConflictError("Reschedule request is missing its original times")
   147	            row.status = "declined"
   148	            target_start, target_end = row.original_start_time, row.original_end_time
   149	            row.start_time = target_start
   150	            row.end_time = target_end
   151	        row.responded_at = datetime.now(UTC)
   152	
   153	        event = await self._linked_event(row)
   154	        if event is not None:
   155	            start_local, start_hhmm = _event_time_parts(target_start, row.timezone)
   156	            _, end_hhmm = _event_time_parts(target_end, row.timezone)
   157	            event.date = start_local.date()
   158	            event.start_time = start_hhmm
   159	            event.end_time = end_hhmm
   160	            if row.timezone:
   161	                event.timezone = row.timezone
   162	
   163	        await self.session.commit()
   164	        # An accepted proposal confirms the new time on the Google event; a declined one
   165	        # moves the event back to the original time for every participant.
   166	        with contextlib.suppress(Exception):
   167	            await propagate_meeting_time(self.session, row, target_start, target_end)
   168	        with contextlib.suppress(Exception):
   169	            await send_reschedule_response_push(self.session, user_id, row.title, accept, row.id)
   170	        return self._action_result(row, event)
   171	
   172	    async def delete_request(
   173	        self, user_id: str, request_id: str, *, calendar_id: str | None = None
   174	    ) -> None:
   175	        # Atomic, tenant- and status-scoped: only a declined request the caller owns is removed,
   176	        # so a concurrent status change can't race between the check and the delete. In shared mode
   177	        # the request must also belong to the selected calendar.
   178	        stmt = delete(MeetingRequest).where(
   179	            MeetingRequest.id == request_id,
   180	            MeetingRequest.user_id == user_id,
   181	            MeetingRequest.status == "declined",
   182	        )
   183	        if calendar_id:
   184	            stmt = stmt.where(MeetingRequest.shared_calendar_id == calendar_id)
   185	        result = await self.session.execute(stmt.returning(MeetingRequest.id))
   186	        if result.scalar_one_or_none() is not None:
   187	            await self.session.commit()
   188	            return
   189	        # Nothing deleted: 404 if missing/other-user/other-calendar, else 409 (not declined).
   190	        await self._owned(user_id, request_id, calendar_id=calendar_id)
   191	        raise ConflictError("Only declined requests can be deleted")
   192	
   193	    async def _owned(
   194	        self, user_id: str, request_id: str, *, calendar_id: str | None = None
   195	    ) -> MeetingRequest:
   196	        stmt = select(MeetingRequest).where(
   197	            MeetingRequest.id == request_id, MeetingRequest.user_id == user_id
   198	        )
   199	        if calendar_id:
   200	            stmt = stmt.where(MeetingRequest.shared_calendar_id == calendar_id)
   201	        row = (await self.session.execute(stmt)).scalar_one_or_none()
   202	        if row is None:
   203	            raise NotFoundError("Meeting request not found")
   204	        return row
   205	
   206	    async def _linked_event(self, row: MeetingRequest) -> CalendarEvent | None:
   207	        if row.focal_event_id is None:
   208	            return None
   209	        return await self.session.get(CalendarEvent, row.focal_event_id)
   210	
   211	    @staticmethod
   212	    def _action_result(
   213	        row: MeetingRequest, event: CalendarEvent | None
   214	    ) -> MeetingRequestActionRead:
   215	        return MeetingRequestActionRead.model_validate({"request": row, "event": event})

exec
/bin/zsh -lc "nl -ba apps/focal/server/app/api/calendar_init.py | sed -n '1,120p'" in /Users/allosta/Desktop/allosta/superapp-slice2
exec
/bin/zsh -lc "nl -ba apps/focal/server/app/api/bookings.py | sed -n '1,130p'" in /Users/allosta/Desktop/allosta/superapp-slice2
 succeeded in 0ms:
     1	from collections.abc import AsyncIterator
     2	from datetime import date
     3	
     4	from fastapi import APIRouter, Depends, Query
     5	
     6	from app.db import get_sessionmaker
     7	from app.deps import current_utc_date, get_current_user_id
     8	from app.schemas.calendar import CalendarInitRead
     9	from app.services.calendar_init import CalendarInitService
    10	from app.services.shared_calendars import SharedCalendarsService
    11	
    12	router = APIRouter(prefix="/api/calendar", tags=["calendar"])
    13	
    14	
    15	async def get_calendar_init_service() -> AsyncIterator[CalendarInitService]:
    16	    async with get_sessionmaker()() as session:
    17	        yield CalendarInitService(session)
    18	
    19	
    20	async def get_shared_service() -> AsyncIterator[SharedCalendarsService]:
    21	    async with get_sessionmaker()() as session:
    22	        yield SharedCalendarsService(session)
    23	
    24	
    25	@router.get("/init", response_model=CalendarInitRead)
    26	async def calendar_init(
    27	    start_date: str | None = Query(default=None, alias="startDate"),
    28	    end_date: str | None = Query(default=None, alias="endDate"),
    29	    calendar_id: str | None = Query(default=None, alias="calendarId"),
    30	    user_id: str = Depends(get_current_user_id),
    31	    today: date = Depends(current_utc_date),
    32	    service: CalendarInitService = Depends(get_calendar_init_service),
    33	    shared: SharedCalendarsService = Depends(get_shared_service),
    34	) -> CalendarInitRead:
    35	    if not calendar_id:
    36	        return await service.get_init(user_id, start=start_date, end=end_date, today=today)
    37	    # Shared mode — mixed aggregate: events + bookings filtered via the calendar gate; tasks +
    38	    # projects only when the caller may view the owner's other pages (init_scope resolves all).
    39	    events, bookings, owner_id, include_other_pages = await shared.init_scope(
    40	        user_id, calendar_id, start=start_date, end=end_date, today=today
    41	    )
    42	    return await service.get_shared_init(
    43	        owner_id,
    44	        events=events,
    45	        bookings=bookings,
    46	        include_other_pages=include_other_pages,
    47	        start=start_date,
    48	        end=end_date,
    49	        today=today,
    50	    )

 succeeded in 0ms:
     1	from collections.abc import AsyncIterator
     2	from datetime import date
     3	
     4	from fastapi import APIRouter, Depends, Query, Response, status
     5	
     6	from app.db import get_sessionmaker
     7	from app.deps import current_utc_date, get_current_user_id
     8	from app.schemas.bookings import BookingCreate, BookingRead, BookingUpdate
     9	from app.services.bookings import BookingsService
    10	from app.services.shared_calendars import SharedCalendarsService
    11	
    12	router = APIRouter(prefix="/api/bookings", tags=["bookings"])
    13	
    14	
    15	async def get_bookings_service() -> AsyncIterator[BookingsService]:
    16	    async with get_sessionmaker()() as session:
    17	        yield BookingsService(session)
    18	
    19	
    20	async def get_shared_service() -> AsyncIterator[SharedCalendarsService]:
    21	    # In shared mode (a `calendarId` is supplied) bookings are RBAC-gated and held to the calendar's
    22	    # saved filter (bookings carry project links) through this service — the scope invariant.
    23	    async with get_sessionmaker()() as session:
    24	        yield SharedCalendarsService(session)
    25	
    26	
    27	@router.get("", response_model=list[BookingRead])
    28	async def list_bookings(
    29	    start_date: str | None = Query(default=None, alias="startDate"),
    30	    end_date: str | None = Query(default=None, alias="endDate"),
    31	    calendar_id: str | None = Query(default=None, alias="calendarId"),
    32	    user_id: str = Depends(get_current_user_id),
    33	    today: date = Depends(current_utc_date),
    34	    service: BookingsService = Depends(get_bookings_service),
    35	    shared: SharedCalendarsService = Depends(get_shared_service),
    36	) -> list[BookingRead]:
    37	    if calendar_id:
    38	        return await shared.list_bookings(
    39	            user_id, calendar_id, start=start_date, end=end_date, today=today
    40	        )
    41	    return await service.list_bookings(user_id, start=start_date, end=end_date, today=today)
    42	
    43	
    44	@router.post("", response_model=BookingRead)
    45	async def create_booking(
    46	    payload: BookingCreate,
    47	    calendar_id: str | None = Query(default=None, alias="calendarId"),
    48	    user_id: str = Depends(get_current_user_id),
    49	    service: BookingsService = Depends(get_bookings_service),
    50	    shared: SharedCalendarsService = Depends(get_shared_service),
    51	) -> BookingRead:
    52	    if calendar_id:
    53	        return await shared.create_booking(user_id, calendar_id, payload)
    54	    return await service.create_booking(user_id, payload)
    55	
    56	
    57	# `booking_id` is an opaque str: an unknown/malformed id reaches the scoped lookup and returns a
    58	# typed not_found (404), not FastAPI's path-validation 422.
    59	@router.get("/{booking_id}", response_model=BookingRead)
    60	async def get_booking(
    61	    booking_id: str,
    62	    calendar_id: str | None = Query(default=None, alias="calendarId"),
    63	    user_id: str = Depends(get_current_user_id),
    64	    service: BookingsService = Depends(get_bookings_service),
    65	    shared: SharedCalendarsService = Depends(get_shared_service),
    66	) -> BookingRead:
    67	    if calendar_id:
    68	        return await shared.get_booking(user_id, calendar_id, booking_id)
    69	    return await service.get_booking(user_id, booking_id)
    70	
    71	
    72	@router.patch("/{booking_id}", response_model=BookingRead)
    73	async def update_booking(
    74	    booking_id: str,
    75	    payload: BookingUpdate,
    76	    calendar_id: str | None = Query(default=None, alias="calendarId"),
    77	    user_id: str = Depends(get_current_user_id),
    78	    service: BookingsService = Depends(get_bookings_service),
    79	    shared: SharedCalendarsService = Depends(get_shared_service),
    80	) -> BookingRead:
    81	    if calendar_id:
    82	        return await shared.update_booking(user_id, calendar_id, booking_id, payload)
    83	    return await service.update_booking(user_id, booking_id, payload)
    84	
    85	
    86	@router.delete("/{booking_id}", status_code=status.HTTP_204_NO_CONTENT)
    87	async def delete_booking(
    88	    booking_id: str,
    89	    calendar_id: str | None = Query(default=None, alias="calendarId"),
    90	    user_id: str = Depends(get_current_user_id),
    91	    service: BookingsService = Depends(get_bookings_service),
    92	    shared: SharedCalendarsService = Depends(get_shared_service),
    93	) -> Response:
    94	    if calendar_id:
    95	        await shared.delete_booking(user_id, calendar_id, booking_id)
    96	    else:
    97	        await service.delete_booking(user_id, booking_id)
    98	    return Response(status_code=status.HTTP_204_NO_CONTENT)

codex
# Review Verdict

Reviewer: GPT Codex
Step: review
Score: 7.8 / 10
Status: BLOCKED

## Reason
The cited activities and sync fixes are present, but the holistic pass found the same unchecked-FK data-loss class still exposed on `POST /api/activity-instances`. A delegated full-access caller can create an owner-scoped instance linked to the caller's own activity, then later delete that activity and cascade-delete the owner's instance.

## Must Fix
- `apps/focal/server/app/api/activity_instances.py:36` exposes `POST /api/activity-instances` as an other-pages write, but `apps/focal/server/app/services/activity_instances.py:47` creates `ActivityInstance(user_id=user_id)` and `apps/focal/server/app/services/activity_instances.py:48` copies the client-supplied `activity_id` without verifying that activity belongs to `user_id`; because `apps/focal/server/app/models/activity_instances.py:16` is an `ON DELETE CASCADE` FK to activities, this leaves a delegated cross-owner cascade-delete path. The new regression only covers `sync_instances` at `apps/focal/server/tests/test_calendar_scope_db.py:644`.

## Should Consider
None

## Tests Reviewed
Ran/inspected `git -C /Users/allosta/Desktop/allosta/superapp-slice2 --no-pager diff feature/focal-migration`, git log, `git diff --check`; inspected `test_delegated_other_pages_writes_reject_non_owner_fk_links`. Full pytest/client gates were reported, not rerun.

## Release Risk
High
tokens used
154 528
# Review Verdict

Reviewer: GPT Codex
Step: review
Score: 7.8 / 10
Status: BLOCKED

## Reason
The cited activities and sync fixes are present, but the holistic pass found the same unchecked-FK data-loss class still exposed on `POST /api/activity-instances`. A delegated full-access caller can create an owner-scoped instance linked to the caller's own activity, then later delete that activity and cascade-delete the owner's instance.

## Must Fix
- `apps/focal/server/app/api/activity_instances.py:36` exposes `POST /api/activity-instances` as an other-pages write, but `apps/focal/server/app/services/activity_instances.py:47` creates `ActivityInstance(user_id=user_id)` and `apps/focal/server/app/services/activity_instances.py:48` copies the client-supplied `activity_id` without verifying that activity belongs to `user_id`; because `apps/focal/server/app/models/activity_instances.py:16` is an `ON DELETE CASCADE` FK to activities, this leaves a delegated cross-owner cascade-delete path. The new regression only covers `sync_instances` at `apps/focal/server/tests/test_calendar_scope_db.py:644`.

## Should Consider
None

## Tests Reviewed
Ran/inspected `git -C /Users/allosta/Desktop/allosta/superapp-slice2 --no-pager diff feature/focal-migration`, git log, `git diff --check`; inspected `test_delegated_other_pages_writes_reject_non_owner_fk_links`. Full pytest/client gates were reported, not rerun.

## Release Risk
High

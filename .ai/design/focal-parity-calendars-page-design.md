# Design: focal-parity-calendars-page

Closes the /calendars-page parity gaps found by the 2026-07-02 calendar explore gate
(`.ai/notes/focal-calendar-parity.md`): SHARE-4 (participating-calendar card stripped),
SHARE-5 (participant names), SHARE-2 (code-only invite), SHARE-3 (join-error messages), plus the
participant-count header. Worktree `superapp/.worktrees/focal-parity-calendars-page`, branch
`feature/focal-parity-calendars-page` off `feature/focal-migration`. OLD = `apps/old-focal/`,
NEW paths relative to `apps/focal/`.

## Problem & decision

The new /calendars page reached structural parity for OWNED calendars, but calendars the user
*participates in* render as a flat row (`client/src/features/calendars/CalendarsPage.tsx:1275-1320`)
— participants lost the three sections old-focal gave them (filter summary, member list, their own
per-calendar Google connection; OLD `pages/Calendars.tsx:887-907` reuses one `CalendarCard` with
`isOwner=false`). Participant rows show emails only because `focal.users` is an id+email shadow
(`server/app/models/users.py`) and the serializer emits `{email}` (`services/shared_calendars.py:
604-623`). Owner invites require an email in the UI although the server always generates an
invite code and accepts email-less invites (`services/shared_calendars.py:499-513`). Join failures
show one generic message although the server already distinguishes 404 invalid vs 409 already-used
(`services/shared_calendars.py:552-577`).

**Decision:** wire the existing `CalendarCard` (which already takes `isOwner`/`userRole`,
`CalendarsPage.tsx:296-320`) for the participating list, showing the **two data sections** a
participant lost — read-only «Что показывается» (filter summary) and «Участники и их права»
(member list) — and keeping its third section, «Правила синхронизации с Google», **owner-only**.
That last section is the reason the naive "just render the shared card" broke: in old-focal the
participant's Google section rendered the **owner's** integration via
`<GoogleCalendarSyncAdvanced overrideUserId={calendar.userId}>` (OLD `Calendars.tsx:1680`, comment
"показываем интеграцию владельца этого календаря") — the assistant/data-owner override, whose
new-app port is **deferred to the AI/data-owner slice (12b)**. Reconstructing it now would mean
threading a data-owner through the whole Google OAuth surface (begin/callback/status/disconnect),
which is the Google-sync slice's job, not this one. So participants get the two data sections
(closing the actual visible regression from the screenshots) and the Google section stays
owner-only until that mechanism lands. Also: add the two nullable name columns + their feeds
(identity-sync heal + ETL column carry) for SHARE-5; make email optional in the invite dialog with
the old post-create code panel; map the two join errors; and close a **pre-existing IDOR** on the
shared-calendar Google *disconnect* route (owner-only) that this slice's audit surfaced.
**Rejected:** (a) a separate `ParticipatingCalendarCard` — duplicates a component old-focal
deliberately shared; (b) rendering the Google section for participants now — needs the deferred
data-owner override + would widen the untrusted-OAuth-state surface the reviewer flagged; (c)
resolving names from the Supabase admin API at request time — couples a hot read to an external
API; (d) names via JWT claims — covers only the current user, not co-participants; (e) porting the
old 8-preset color palette — retired 2026-07-02 as an accepted deviation.

## Assumptions & scope

- Assumption (confirmed): server invite always generates `invite_code`, `email` optional —
  `services/shared_calendars.py:499-513`, `schemas/shared_calendar.py:127`.
- Assumption (confirmed): join errors distinct server-side — `NotFoundError("Invalid invite code")`
  vs `ConflictError("This invite has already been used")`, `services/shared_calendars.py:565-577`.
- Assumption (confirmed): participants list readable by any participant (`_resolve_access(...,
  "viewer")`) and `invite_code` serialized to owners only (`services/shared_calendars.py:604-623`)
  — the participating card shows members but never codes.
- Assumption (confirmed): `AccessibleSharedCalendarRead` already carries
  `filter_type/filter_value/participants_count/participant_role`
  (`schemas/shared_calendar.py:70-91`) — the filter summary needs no backend change.
- Assumption (confirmed): the Google section stays owner-only, so no participant OAuth surface is
  created; the pre-existing `POST /api/shared-calendars/{id}/disconnect-google` route clears any
  calendar's binding+`sync_settings` with **no access check** — an IDOR reachable today
  (`api/shared_calendars.py:181-188` → `services/google_integration.py:209-228`; `_resolve_access`
  at `services/shared_calendars.py:468`). Slice 1 adds an owner guard.
- Assumption (confirmed): `focal.users` = id+email only; identity-sync heals NULL emails only
  (`tasks/identity_sync.py:34`); the legacy ETL currently **drops** `first_name`/`last_name`
  (`server/scripts/etl/migrate_legacy.py:56`).
- Assumption (unverified): Supabase `auth.users` metadata carries legacy names for migrated users.
  Probe in slice 3; if absent, names arrive via the ETL column carry (prod) and stay NULL for
  pre-ETL dev users — UI falls back to email exactly like old-focal (`OLD Calendars.tsx:1569-1578`).
- Out of scope: **Google section for participants** (needs the deferred data-owner override —
  AI/data-owner slice 12b + Google-sync slice); **the OAuth begin/callback untrusted-`userId`/state
  hardening** (`api/google_auth.py:47-88` — begin/callback are public, no JWT; a token-injection /
  confused-deputy surface that belongs to the Google-sync slice's authz redesign, flagged there,
  neither introduced nor widened here); GS-1 per-shared-calendar sync *settings*, GS-5/GS-6/MEET-*
  (Google-sync slice); color-palette presets (retired); year view + calendar-grid gaps; invite
  revoke/resend (absent in old too); any change to RBAC ranks.
- Open questions: None.

## Success criteria

- [ ] A participant (each of the 5 non-owner roles) sees their participating calendar as an
  expandable card with the two data sections: read-only «Что показывается» summary and «Участники
  и их права (n)» with names/emails + roles + pending badges (no invite codes). The
  «Правила синхронизации с Google» section and all owner-only controls (edit pencil, delete,
  invite, role select, remove-other, filter editor) are absent; «Покинуть» present — on the
  user's OWN participant row inside the «Участники» section, matching old-focal
  (`OLD Calendars.tsx:1629`), not a card-header button; owned cards unchanged (all three
  sections + controls).
- [ ] `POST /api/shared-calendars/{id}/disconnect-google` returns 403 for a non-owner and 404/403
  for a stranger; the owner still disconnects normally (the pre-existing IDOR is closed).
- [ ] Participant rows render "First Last" when known, else email — server serializes
  `user: {email, firstName, lastName}`; `focal.users` has the two nullable columns via an
  additive Alembic migration that downgrades cleanly.
- [ ] Identity-sync heal fills email AND names in one pass with a checked-absent sentinel (no
  endless re-sweep); the ETL no longer drops the name columns.
- [ ] Owner creates a code-only invite (email empty): row appears pending with code; the dialog
  shows the 8-char code (mono, copy, hint) like old-focal (`OLD Calendars.tsx:1148-1167`);
  email invites keep working.
- [ ] Join by code maps 404 → "invalid code" and 409 → "already used" as distinct localized
  messages.
- [ ] All new strings in ru+en; client tsc/biome/vitest green; server ruff/mypy/pytest green;
  `alembic upgrade head` + `downgrade -1` clean on local Docker PG.

(The shared-calendar Google **connect** authorization — begin/callback — is intentionally NOT a
criterion here: begin/callback are public, no-JWT routes whose trustworthy-state redesign is
out of scope, owned by the Google-sync slice. This slice's only Google-authz change is the
**disconnect** owner-guard above.)

## Build approach (slices)

| # | slice | files | main failure mode | what its test proves |
|---|-------|-------|-------------------|----------------------|
| 1 | Close the disconnect-google IDOR (owner-only) | `server/app/services/google_integration.py` (owner check in `disconnect_shared_calendar`, or the route in `api/shared_calendars.py`), `server/tests/` | breaking the owner's normal disconnect; wrong error type | owner 200; non-owner participant 403; stranger 404/403; main-calendar disconnect path untouched |
| 2 | SHARE-4: participating list renders `CalendarCard` (2 data sections, Google owner-only) | `client/src/features/calendars/CalendarsPage.tsx` + `CalendarsPage.test.tsx` | leaking owner controls or the Google section to participants; regressing owned cards; losing «Покинуть» | participant card shows «Что показывается» + «Участники», hides Google section + all owner controls (parametrized over all 5 non-owner roles); «Покинуть» present; owned card still shows 3 sections + controls; count "(n)" in header on both |
| 3 | SHARE-5: name columns + feeds + serializer + UI | `server/app/models/users.py`, new alembic revision, `server/app/tasks/identity_sync.py`, `server/scripts/etl/migrate_legacy.py`, `services/shared_calendars.py`, `schemas/shared_calendar.py`, regenerated `client/src/api/openapi.d.ts`, `CalendarsPage.tsx` row render + tests both sides | heal loop re-sweeping users without metadata names (admin-API hammering); migration drift | serializer returns names; heal fills email+names once (sentinel ""), fake admin transport; ETL drop-set no longer contains the columns; UI renders "First Last" with email fallback |
| 4 | SHARE-2/3: invite dialog code-only + join error mapping | `CalendarsPage.tsx` invite dialog + join mutation, i18n `ru/en`, tests | regressing email invites; misclassifying other 4xx as "already used" | email-less submit → code panel with copy; email path unchanged; 404 vs 409 → distinct messages, other errors → generic |

Each slice leaves the tree green and is independently shippable; 1→4 is a natural order but the
slices don't depend on each other (slice 1 hardens an existing route; slice 2 never mounts the
Google section for participants, so it doesn't depend on slice 1).

## Architecture & contracts

| entity / interface | change | notes |
|--------------------|--------|-------|
| `focal.users` | + `first_name: String\|None`, + `last_name: String\|None` | additive, nullable; autogenerated Alembic revision committed with the model change (repo rule); no data backfill in the migration itself |
| name population | identity-sync heal + ETL carry | heal (`tasks/identity_sync.py`) extends its dirty-query to rows missing email OR names and writes names from the same admin-API user JSON (`user_metadata`), using `""` as a checked-absent sentinel so nameless users are fetched once, not every 6h; ETL removes `first_name`/`last_name` from the `users` drop-set (`migrate_legacy.py:56`) so prod names arrive with the data migration |
| `ParticipantRead.user` | `{email}` → `{email, firstName, lastName}` | additive camelCase (`_Camel`); serializer maps `""` sentinel → `null`; `pnpm gen:api` regenerates `openapi.d.ts` (wrappers consume component schemas — additive-safe) |
| `POST /api/shared-calendars/{id}/disconnect-google` | + owner-access check | `disconnect_shared_calendar` currently mutates any calendar's `google_calendar_id`+`sync_settings` with no guard (IDOR); add `_resolve_access(user_id, calendar_id, "owner")` (or resolve `calendar.user_id == user_id`) before the mutation → typed `PermissionDeniedError` → 403 / `NotFoundError` → 404; the main-calendar disconnect (separate route, no `calendar_id`) is untouched |
| OAuth begin/callback authz | **flagged, out of scope** | `api/google_auth.py:47-88` trusts `userId`/`sharedCalendarId` from public query/state; the trustworthy-state redesign belongs to the Google-sync slice — recorded here so it isn't lost, not touched by this slice |
| `CalendarCard` | reused for participating calendars, Google section gated on `isOwner` | already takes `isOwner`/`userRole` (`CalendarsPage.tsx:296-320`); pass `isOwner={false}`, `userRole={calendar.participantRole}`; **wrap the «Правила синхронизации с Google» section (and `GoogleSyncPanel` mount) in `isOwner`** so a participant never mounts it; audit + fix any owner-only control not gated on `isOwner` (it has only ever rendered with `isOwner=true`); keep self-leave via existing `onRemove(..., isSelf=true)`; add participants-count to the section header (old `Calendars.tsx:1504-1508`) |
| invite dialog | email optional | empty email → `inviteParticipant(calId, {role})` (no email key); on success with no email, dialog switches to the code panel (mono code + copy + hint) instead of closing; localStorage/i18n keys `focal.calendars.invite.*` |
| join mutation | error mapping | typed API error status: 404 → `focal.calendars.join.invalidCode`, 409 → `focal.calendars.join.alreadyUsed`, else existing generic |

No other endpoints, tables, or events change. No new dependencies.

## Flow (happy + unhappy)

| path | trigger | handled where | result |
|-------|---------|---------------|--------|
| happy | participant expands the 2 data sections | existing `participants` query now mounted for participating cards; filter summary from the accessible row | filter summary + member list (no codes); Google section absent |
| unhappy: role revoked mid-session | participants query → 403/404 | existing `participants.isError` branch in the card | inline error alert; page stays usable |
| unhappy: non-owner calls disconnect-google directly | slice-1 owner guard | `PermissionDeniedError` → 403 via the app error handler | binding untouched; IDOR closed |
| unhappy: join with bad code | 404 from join | slice-4 mapping in `joinMutation.onError` | «Код не найден» localized |
| unhappy: join with used code | 409 | same | «Код уже использован» localized |
| unhappy: email-less invite fails server-side | 4xx/5xx | existing invite error banner | dialog stays open, form preserved |
| unhappy: user without names anywhere | serializer | `""` sentinel → `null` → UI falls back to email | identical to old-focal fallback |
| partial: heal fetch fails for one user | per-user try in heal task | logged, row left dirty for next sweep | no task crash; retried next run |

## Test strategy, security & rollback

- Test strategy — server (pytest, local Docker PG): disconnect-google authz matrix (owner 200 /
  non-owner participant 403 / stranger 404 / main-calendar disconnect path untouched); serializer
  returns names + sentinel mapping; heal fills email+names in one pass and skips checked-absent
  rows on the next run (fake admin transport, mirroring the existing identity-sync tests);
  migration `upgrade head` + `downgrade -1`. Client (vitest + happy-dom): participating card
  renders «Что показывается» + «Участники», hides the Google section + every owner control —
  **parametrized across all 5 non-owner roles** (viewer/editor/full_access/developer/requester) —
  and shows «Покинуть»; owned-card regression (all 3 sections + controls, existing tests stay
  green); names render with email fallback; invite code-only flow → code panel + copy; email
  invite regression; join 404/409/500 message mapping. `check:i18n` keys present in ru+en (do not
  commit its file rewrites — known footgun).
- Security: the Google section is owner-only, so this slice creates **no** participant OAuth
  surface; slice-1 closes the pre-existing disconnect-google IDOR (owner-only); the untrusted
  begin/callback `userId`/state path is explicitly flagged to the Google-sync slice, not widened
  here; `invite_code` stays owner-only in serialization and the participating card never renders
  codes; names are PII already visible to co-participants in old-focal — same audience, no broader
  exposure; no new secrets.
- Rollback: revert the PR; the migration is additive → `alembic downgrade -1` drops the two
  columns; ETL drop-set change only matters for future ETL runs; no destructive data path.

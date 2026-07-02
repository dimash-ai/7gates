# Stage
3-gate flow, gate C (verify) — APPROVED 9.5. Ready to ship: `feature/focal-parity-calendars-page`
→ `feature/focal-migration`.

# What changed
Closes the /calendars-page parity gaps the 2026-07-02 calendar explore gate found
(`.ai/notes/focal-calendar-parity.md`: SHARE-2/3/4/5), across 4 slices:

1. **Owner-only Google disconnect** — `POST /api/shared-calendars/{id}/disconnect-google` now
   resolves the calendar and checks ownership before any mutation, closing a pre-existing IDOR
   (any authed user could clear another calendar's Google binding + sync settings).
2. **Participating calendars show as full cards** — a calendar you only participate in reuses the
   same `CalendarCard` as owned ones, so the filter summary («Что показывается») and member list
   («Участники и их права (n)») return. The Google-sync section and every owner control stay
   owner-only; leave is on your own participant row.
3. **Participant display names** — participant rows show "First Last" when known, falling back to
   email. Backing this: two nullable name columns on the user shadow (additive migration), the
   six-hourly identity heal now fills names from Supabase with a checked-absent sentinel, and the
   legacy data migration carries the names.
4. **Code-only invites + clearer join errors** — leaving the invite email empty creates a
   shareable code invite and shows the generated code to copy; joining with a bad code now says
   whether the code is unknown or already used.

# Files touched
- `apps/focal/server/app/services/google_integration.py` — owner guard on shared-calendar disconnect
- `apps/focal/server/app/models/users.py` — `first_name`/`last_name` (nullable)
- `apps/focal/server/alembic/versions/2026_07_02_1726-af9dc3b7834f_user_display_name.py` — additive migration
- `apps/focal/server/app/tasks/identity_sync.py` — heal names + email in one pass, `""` sentinel, COALESCE
- `apps/focal/server/app/schemas/shared_calendar.py` — `ParticipantUser.firstName/lastName`
- `apps/focal/server/app/services/shared_calendars.py` — serialize names (`""`→null)
- `apps/focal/server/scripts/etl/migrate_legacy.py` — carry the name columns (stop dropping them)
- `apps/focal/client/src/api/openapi.d.ts` — regenerated (additive)
- `apps/focal/client/src/features/calendars/CalendarsPage.tsx` — participating cards, names, code-only invite, join errors
- `apps/focal/client/src/i18n/locales/{en,ru}.json` — 6 new keys
- Tests: `apps/focal/server/tests/test_identity_sync_db.py` (new), `test_google_integration_db.py`,
  `test_shared_calendar_participants_db.py`, `test_etl_migrate_legacy.py`;
  `apps/focal/client/src/features/calendars/CalendarsPage.test.tsx`

# Tests run
```sh
# server (cwd apps/focal/server, DATABASE_URL=…@localhost:5433/focal_dev)
uv run ruff check .                                  # All checks passed
uv run mypy app                                      # Success: no issues (171 files)
uv run alembic upgrade head && uv run alembic downgrade -1 && uv run alembic upgrade head  # reversible
uv run alembic check                                 # No new upgrade operations detected
uv run pytest test_google_integration_db + test_identity_sync_db + test_shared_calendar_participants_db + test_etl_migrate_legacy  # 59 passed
uv run pytest                                        # 1721 passed, 1 skipped, 12 failed (pre-existing AI-chat/OpenAI-env)

# client (cwd apps/focal/client)
pnpm run typecheck                                   # clean
pnpm exec biome check src                            # clean
pnpm run lint:i18n                                   # No issues (ru+en parity)
pnpm exec vitest run src/features/calendars/CalendarsPage.test.tsx  # 30 passed
pnpm exec vitest run                                 # 1764 passed, 3 failed (pre-existing TasksPage.test.tsx)
```

# Verification output
```sh
# GPT verify: 0 production-code defects; added 2 authz tests. Opus release review (re-run): 9.5 APPROVED.
uv run ruff check .            -> All checks passed!
pytest (4 slice suites)        -> 59 passed
vitest CalendarsPage           -> 30 passed
```

# Still needs review
- Pre-existing (proven on base `feature/focal-migration`, NOT from this branch): 12
  `test_ai_chat_routes_db.py` failures (need OpenAI/embeddings env) and 3 `TasksPage.test.tsx`
  failures (TanStack Query timing); `app/data_scope.py` fails `ruff format --check` on the base too.
- Scope note (from the design, approved): the participant Google section is intentionally owner-only
  for now — reconstructing the owner-integration view for participants needs the deferred
  data-owner override and belongs to the Google-sync slice; the OAuth begin/callback state-trust
  hardening is likewise flagged to that slice, not touched here.

# PR / release notes (for users — stage 5)
On the Calendars page you can now:
- **See the calendars shared with you in full.** A calendar you're a participant in now shows its
  filter and its member list, not just a name and a role — the same card owners see (owner-only
  controls and the Google-sync section stay hidden).
- **Recognize people by name.** Participants show as "First Last" when their name is known, instead
  of only an email address.
- **Invite by a shareable code without an email.** Leave the email blank when inviting and Focal
  gives you a code to share however you like; joining with a wrong code now tells you whether the
  code is unknown or already used.

Behind the scenes this also closes a security gap where a non-owner could disconnect a shared
calendar's Google connection.

No secrets, tokens, keys, or PII in this text.

# Status
OPUS APPROVED (9.5) — verify/release gate. Design gate A APPROVED (9.4); build gate B slices
1–4 APPROVED (9.4 / 9.2 / 9.1 / 9.3).

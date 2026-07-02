# Summary

Implement `focal-shared-calendars-participants` (Phase 2 step 5, slice 3 of 4): participant
management + join-by-invite-code, extending the slice-2 `/api/shared-calendars` router +
`SharedCalendarsService` (reuse `_resolve_access`). No migration. Task:
[focal-shared-calendars-participants.md](../tasks/focal-shared-calendars-participants.md). Legacy:
`routes.ts:99` (`generateInviteCode`) + `:7738-7917`.

## Decisions (design + the Gate-1 rulings)

- **`app/domain/invite_code.py`** — `generate_invite_code() -> str`: 8 chars from
  `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` via `secrets.choice` (no I/O/0/1; uppercase).
- **Schemas** (extend `app/schemas/shared_calendar.py`): `_INVITE_ROLES = ("full_access", "editor",
  "developer", "viewer", "requester")` (non-owner).
  - `ParticipantInvite`: `user_id?`, `email?`, `role` default `"viewer"` — a `field_validator` rejects
    anything not in `_INVITE_ROLES` (so `owner`/unknown → 422).
  - `ParticipantRoleUpdate`: `role` — same validator.
  - `ParticipantUser`: `email: str | None`.
  - `ParticipantRead` (`from_attributes`): `id`, `shared_calendar_id`, `user_id`, `email`, `role`,
    `invite_status`, `invite_code`, `created_at`, `updated_at`, `user: ParticipantUser | None`.
  - `JoinRequest`: `invite_code` (min 1). `JoinResponse`: `participant: ParticipantRead`,
    `calendar: SharedCalendarRead`.
- **`SharedCalendarsService` methods:**
  - `list_participants(user_id, calendar_id)` → `_resolve_access(viewer)`; `select(participant, User)
    .outerjoin(User, participant.user_id == User.id).where(shared_calendar_id == calendar_id)`; build
    `ParticipantRead` with `user = ParticipantUser(email=user.email)` when the user row exists, else None.
  - `invite_participant(user_id, calendar_id, payload)` → `_resolve_access(owner)`; add a participant
    (`invite_code=generate_invite_code()`, `invite_status="pending"`, role from payload); commit;
    return `ParticipantRead` (user resolved).
  - `update_participant_role(user_id, calendar_id, participant_id, payload)` → `_resolve_access(owner)`;
    load the participant by id **scoped to the calendar** (`NotFoundError` if absent); if its role is
    `owner` → `ConflictError`; set role; commit; return.
  - `remove_participant(user_id, calendar_id, participant_id)` → `_resolve_access(viewer)` → (calendar,
    role); load the participant scoped to the calendar (404); **if target.role == "owner" →
    `ConflictError` (checked first)**; if `role != "owner"` and `target.user_id != user_id` →
    `PermissionDeniedError`; delete; commit.
  - `join(user_id, payload)` → look up the participant by `invite_code == payload.invite_code.upper()`
    (`NotFoundError` if none); if `invite_status == "accepted"` → `ConflictError`; set
    `user_id = sub`, `invite_status = "accepted"`; commit; load the calendar; return `JoinResponse`.
- **Routes** (extend `app/api/shared_calendars.py`): `GET /{calendar_id}/participants` (viewer),
  `POST /{calendar_id}/participants` (owner, → 200), `PATCH /{calendar_id}/participants/{participant_id}`
  (owner), `DELETE /{calendar_id}/participants/{participant_id}` (owner-or-self, → 204), `POST /join`
  (auth only). Declare `/join` **before** `/{calendar_id}` (static-before-param). Tenant = JWT `sub`.
- **No migration**; reuse `ConflictError`/`NotFoundError`/`PermissionDeniedError`.

# Files to change

| path | change | why |
|------|--------|-----|
| `superapp/apps/focal/server/app/domain/invite_code.py` | add | `generate_invite_code` |
| `superapp/apps/focal/server/app/schemas/shared_calendar.py` | modify | participant + join schemas + role validator |
| `superapp/apps/focal/server/app/services/shared_calendars.py` | modify | the 5 participant/join methods |
| `superapp/apps/focal/server/app/api/shared_calendars.py` | modify | the 5 routes (/join before /{id}) |
| `superapp/apps/focal/server/tests/test_shared_calendar_participants_db.py` | add | participant/join DB tests |
| `superapp/apps/focal/server/tests/test_recurrence_unit.py` | (no) | — |
| `superapp/apps/focal/server/tests/test_invite_code.py` | add | unit test for the generator |
| `superapp/apps/focal/server/tests/test_contracts.py` | modify | pin `ParticipantRead` + join shapes |

# Implementation slices

Each leaves `make verify` green.

1. **invite_code + schemas.** The domain helper + the participant/join schemas (role validator).
   *Verify:* unit test + ruff/mypy.
2. **Service + routes.** The 5 service methods + the 5 routes. *Verify:* `make verify` + `alembic check`.
3. **Tests.** Participant/join DB tests + the contract pins. *Verify:* full `make verify`.

# Tests

- **invite_code (unit):** 8 chars, every char in the alphabet, no `I/O/0/1`, varies across calls.
- **list:** owner + accepted participant see the list (viewer); a non-participant → 403; missing → 404;
  each item carries the participant fields + `user.email` (or `null` when no registered user row).
- **invite:** owner creates a pending participant with an 8-char code + role default `viewer`; a
  non-owner → 403; `role="owner"` / unknown role → 422.
- **role-change:** owner changes a participant's role; the owner participant → 409; a participant not
  on the calendar → 404; a non-owner → 403; `role="owner"`/unknown → 422.
- **delete:** owner removes a non-owner (204) + the row is gone; a participant removes **themselves**
  (204); a non-owner removing someone else → 403; removing the **owner** → 409 (even for a non-owner);
  unknown participant → 404.
- **join:** a valid (lower- or upper-case) code accepts the invite (sets `user_id`+`accepted`) and
  returns `{participant, calendar}`; afterwards the joiner resolves `viewer`+ (via `my-role`); a bad
  code → 404; an already-accepted invite → 409.
- **Contracts:** `ParticipantRead` + `JoinResponse` camelCase shapes pinned.

# Error & rescue map

| failure mode | error | response |
|--------------|-------|----------|
| Caller lacks the required role on the calendar | `PermissionDeniedError` | 403 |
| Calendar or participant not found / bad invite code | `NotFoundError` | 404 |
| Mutating the owner participant; joining an already-accepted invite | `ConflictError` | 409 |
| `role` not a non-owner role; missing `invite_code` | `RequestValidationError`/`ValidationError` | 422 |

# Review lenses (pre-answer)

- **Scope / strategy.** Extends the slice-2 router/service (reuses `_resolve_access`); one new domain
  helper + participant schemas; no migration/new error code.
- **Architecture.** Owner-only writes; owner-or-self delete; owner-immutable (checked first);
  role constrained to non-owner; join is code-based + idempotency-guarded (409 on re-use).
- **Completeness.** Every route + the role constraint + the owner-immutable/delete-precedence +
  join semantics + the minimal user shape each map to a test.
- **Tests & verification.** `make verify` green; `alembic check` clean; contract pins; a generator unit test.

# Risks & migrations

- **No migration** — slice-1 tables; `alembic check` stays clean.
- **Privilege escalation** (a second owner) is prevented by the `_INVITE_ROLES` validator — pinned by
  the `role="owner"` 422 tests.
- **Owner-immutable ordering** (409 before 403) is the subtle bit — pinned by the non-owner-targets-
  owner test.
- **No behavior change** to the slice-2 CRUD/caller-view; their suites guard.

# Scope check

- [x] Matches the task (participants + join; `/events` → slice 4; Google/RLS/UI out).
- [x] 3 sequenced slices, each green.
- [x] Size: one domain helper + participant schemas + 5 service methods + 5 routes + tests; no migration.

# Out of scope

The filtered `/events` + filter engine (slice 4); Google sync (Phase 3); first/last name + avatar on
the user-join (the `User` shadow is minimal); RLS; the React UI; ETL.

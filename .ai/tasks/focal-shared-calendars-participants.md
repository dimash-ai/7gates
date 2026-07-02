# Goal

Participant management + join-by-invite-code (Phase 2 step 5, slice 3 of 4) on the shared-calendars
foundation: list participants, invite (generate an invite code), change role, remove, and join by
code — **enforcing the owner-only writes the legacy left commented out**. The filtered `/events` read
is slice 4.

# Scope

- Extend the `/api/shared-calendars` router + `SharedCalendarsService` (reuse `_resolve_access`) and
  add the participant schemas + an invite-code helper. Legacy `routes.ts:7738-7917`. Tenant = JWT
  `sub`; the legacy `requesterId`/`userId` **body/query params are dropped** (use the JWT).
  - `GET /{id}/participants` — list participants (+ each registered user's email); **require `viewer`**.
  - `POST /{id}/participants` — invite: generate an 8-char `invite_code`, create a participant
    (`user_id`/`email` optional, `role` default `viewer`, `invite_status="pending"`); **require
    `owner`**; → 200 `ParticipantRead`.
  - `PATCH /{id}/participants/{participant_id}` — change `role`; **require `owner`**; the target must
    belong to the calendar (404); **the owner participant's role is immutable** (409).
  - `DELETE /{id}/participants/{participant_id}` — remove; the target must belong (404); **the owner
    can't be removed** (409); **owner can remove anyone, a participant may remove themselves**
    (else 403); → 204.
  - `POST /join` — join by `invite_code` (public — no role check, only auth): look up by the
    **upper-cased** code (404 if none); if already `accepted` → 409; set the participant's `user_id`
    = JWT `sub` + `invite_status="accepted"`; → `{participant, calendar}`. Declared **before** `/{id}`.
- **`app/domain/invite_code.py`** — `generate_invite_code()`: 8 chars from
  `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` (no I/O/0/1), via `secrets.choice`.
- **Schemas** (extend `app/schemas/shared_calendar.py`, `_Camel`): `ParticipantInvite`
  (`user_id?`, `email?`, `role` default `viewer` — **validated against the non-owner roles**),
  `ParticipantRoleUpdate` (`role` — **validated against the non-owner roles**), `ParticipantRead`
  (the participant row + `user: {email} | None` resolved from `focal.users`), `JoinRequest`
  (`invite_code`), `JoinResponse` (`participant`, `calendar`).

# Decisions (design rulings to confirm at Gate 1)

- **Apply the owner-only enforcement** the legacy commented out: list = `viewer`; invite + role-change =
  `owner`; delete = `owner` or **self** (a participant leaving); join = public by code (auth only).
- **Invite/update `role` is constrained** to the non-owner roles (`full_access` / `editor` /
  `developer` / `viewer` / `requester`); `owner` and any unknown string → `validation_error` (422).
  Ownership is assigned only at creation and is not transferable here, so a second `owner` can never
  be minted via invite or role-change (which would otherwise be unremovable + immutable).
- **The owner participant is immutable:** changing its role or removing it → `ConflictError` (409,
  faithful to the legacy 400 "can't change/remove the owner" rule, re-typed). This owner-immutable
  check runs **before** the delete owner-or-self check, so even a non-owner targeting the owner gets
  409 (not 403).
- **Join** is upper-cased-code lookup; a missing code → `NotFoundError` (404); an already-`accepted`
  invite → `ConflictError` (409). No legacy `ensureUser` — the superapp auth layer heals
  `focal.users`; the join just sets `user_id` = JWT `sub`.
- **`ParticipantRead.user`** carries only `email` (the superapp `User` shadow has no
  first/last/avatar — those are deferred, documented). The participant row's own `email` (invite
  email) is also returned.
- **No invite-code collision check** (faithful; 32^8 space) and **no new migration** (slice-1 tables).
  `POST` → 200, `DELETE` → 204 (superapp convention).

# Out of scope

- The filtered `GET /{id}/events` + filter engine (slice 4); Google sync (Phase 3); first/last
  name + avatar on the participant user-join (the `User` shadow is minimal); RLS; the React UI; ETL.

# Acceptance criteria

- [ ] `GET /{id}/participants` (viewer+) lists the calendar's participants, each with the
      participant fields + `user.email` (or `null` when no registered user); a non-participant → 403,
      missing calendar → 404.
- [ ] `POST /{id}/participants` (owner only) creates a `pending` participant with a generated 8-char
      `inviteCode` (from the no-confusion alphabet), `role` defaulting to `viewer`; a non-owner → 403.
- [ ] Invite or role-change with `role="owner"` or an unknown role → 422 (no second owner can be
      minted); valid non-owner roles are accepted.
- [ ] `PATCH /{id}/participants/{pid}` (owner) changes the role; changing the **owner** participant's
      role → 409; a participant id not on the calendar → 404; a non-owner → 403.
- [ ] `DELETE /{id}/participants/{pid}` → 204; the owner can remove any non-owner; a participant can
      remove **themselves**; another non-owner removing someone else → 403; removing the **owner** →
      409 (checked before the owner-or-self rule, so even a non-owner gets 409 not 403); unknown
      participant → 404.
- [ ] `POST /join` with a valid (case-insensitive) code accepts the invite (sets `user_id` = JWT
      `sub`, status `accepted`) and returns `{participant, calendar}`; a bad code → 404; an
      already-accepted invite → 409. After joining, the user resolves `viewer`+ on that calendar.
- [ ] Tenant from JWT `sub` (no `requesterId`/`userId` params); typed `AppError` only; camelCase
      responses; `make verify` green; `alembic check` clean (no migration).

# Verification commands

```sh
make verify
DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev uv run --frozen alembic check
```

# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 7.4 / 10
Status: BLOCKED

## Reason
The core RBAC boundary and role sets are mostly right, and the live AI `userId` IDOR is real. The design is not shippable yet because the AI-chat path is a mixed read/write endpoint but the doc only defines one vague “same RBAC gate,” and the RLS/GUC mechanics are underspecified for the separate service sessions that will load owner data.

## Must Fix
- The design must split `/api/ai/chat` authorization by intent/action, not just “authorize supplied userId via the same RBAC gate.” The route resolves `data_owner` once (`ai_chat.py:204`) then dispatches both reads and creates through that owner (`ai_chat.py:310`); create handlers write owner-scoped rows (`entity_handlers.py` ~997/1320/1415). A developer role must read but not write — needs an explicit AI read gate vs write gate.
- The design must specify how the effective owner binds to the DB transaction/session GUC, or explicitly document the bypass. Route service deps open independent sessions (`tasks.py:17`, `ai.py:33`); RLS only binds sessions with `TENANT_SCOPE_KEY` (`db.py:81`) and auth pins only its own dep session (`auth.py:111`). “return owner id → service(owner_id)” doesn't describe the app-set GUC path the no-migration claim relied on.

## Should Consider
- Add an explicit endpoint matrix for every scoped route (incl. aggregate routes like `/api/calendar/init`) so “every scoped endpoint routes through it” is verifiable at build review.

## Tests Reviewed
N/A

## Release Risk
High

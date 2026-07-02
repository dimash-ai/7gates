# Codex Review Verdict

Score: 8.6 / 10
Status: BLOCKED

## Reason
The malformed `app_metadata` fix is complete: absent/null becomes `{}`, while falsey and truthy non-object values are rejected and tested. One JWKS failure path still escapes the typed auth contract and would surface as a 500 once auth is wired.

## Must Fix
- `superapp/apps/focal/server/app/auth.py:67-82` only converts errors inside the signing-key/decode block to `AuthRequiredError`, and `_get_jwks_client()` is outside that block. With the default empty `SUPABASE_URL` the client path returned `PyJWKClientError`, not `AuthRequiredError(code="invalid_token")`.
- `superapp/apps/focal/server/app/auth.py:81` does not catch non-PyJWT JWKS fetch/parse failures. Patching the JWKS client to raise `json.JSONDecodeError` caused `verify_jwt()` to raise `JSONDecodeError`, not `AuthRequiredError(code="invalid_token")`.

## Should Consider
- Add explicit tests for the plan's JWKS rotation/cache criteria: unknown `kid` accepted after bounded refresh, and repeated valid requests do not refetch JWKS in steady state.

## Tests Reviewed
Ran the staged diff, status, `--check`, inspected plan/task/rubric/CLAUDE and staged auth/config/model/tests, and ran `pytest tests/test_auth.py -q`: 23 passed, 1 skipped.

## Release Risk
Medium

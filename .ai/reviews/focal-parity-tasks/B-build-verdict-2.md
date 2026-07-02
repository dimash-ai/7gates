# Review Verdict

Reviewer: Opus
Step: build
Score: 8.7 / 10
Status: BLOCKED

## Slice
4a.2 — `TaskDialog` (create/edit over existing fields) + test + i18n. First pass.

## Reason
The dialog faithfully implements the 4a.2 contract — existing-fields-only payload, project→product→activity cascade, inline tag-create, schedule-as-event with the real `timezone` field + clamped endTime + partial-failure handling, and full canEdit gating — all verified against the API schemas and old-focal. But one referenced i18n key, `focal.tags.actions.create` (TaskDialog.tsx:514, the inline-tag "Create" submit button), exists in neither en nor ru, so it renders as the literal raw key in both locales; the inline-tag-create test passes only because both sides resolve to the same missing-key fallback, masking the defect.

## Must Fix
- Untranslated button label in both locales (TaskDialog.tsx:514). `t('focal.tags.actions.create')` resolves to no entry — `focal.tags.actions` has only cancel/delete/edit/save. Add `create` to `focal.tags.actions` in both locale files (or point at an existing key). The inline-tag-create test must also assert a real translated label, not the raw key.

## Should Consider
- The create `payload` carries `completed` (not in `TaskCreate`); harmless if the backend ignores it (schemas use `extra="ignore"`), worth confirming create silently drops it rather than 422s.

## Tests Reviewed
`TaskDialog.test.tsx` (8 tests); build log 4a.2 (tsc/biome/8-test PASS, full 77/900 under `--no-experimental-webstorage`); independent checks of EventCreate/TaskCreate/TagCreate field names + full `t()`-key sweep (1 missing).

## Release Risk
Low

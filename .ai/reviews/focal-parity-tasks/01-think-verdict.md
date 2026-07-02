# Review Verdict

Reviewer: GPT Codex
Step: think
Score: 8.2 / 10
Status: BLOCKED

## Reason
The think doc is mostly well-framed and gives a defensible 4a/4b split, but it overstates one key scope assumption as confirmed: dnd-kit "list reorder" is treated as frontend-only parity even though the referenced old Tasks page renders plain sorted rows and the task backend has no order field or reorder API.

## Must Fix
- `.ai/think/focal-parity-tasks.md` claims confirmed dnd-kit list reorder and includes it in frontend-only 4a, but the cited old Tasks page rows are plain mapped `<div>`s (`superapp/apps/old-focal/client/src/pages/Tasks.tsx:1272-1360`) and the draggable `TaskItem` is used in the calendar task panel (`superapp/apps/old-focal/client/src/components/TaskPanel.tsx:176-188`) under Calendar's drag context (`superapp/apps/old-focal/client/src/pages/Calendar.tsx:2926`). Reframe this as an unverified/out-of-scope drag-to-calendar behavior, or define a real persisted list reorder contract and its backend implications.

## Should Consider
- The think doc should note that old-focal's task UI sends recurrence/participant fields, but the old task schema/routes also may not persist them; 4b is therefore an intentional persistence fix for UI controls, not a straightforward old-DB parity port.

## Tests Reviewed
N/A

## Release Risk
Medium

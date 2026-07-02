# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 8.7 / 10
Status: BLOCKED

## Reason
The backend field claim is true: the inspected schemas/services expose and persist the in-scope activity, project-create, project-update, activity-update, and node `fullDescription` fields without server work. The design is mostly surgical and correctly preserves `canEdit` and the work-time sphere-null rule, but the new-sphere create path misses the critical two-write unhappy path.

## Must Fix
- `/Users/allosta/Desktop/allosta/.ai/design/focal-parity-goals-design.md:63` describes reusing sphere creation, but does not specify the required failure/rollback flow when creating a sphere then creating the project. Old-focal explicitly deletes the newly created sphere if project creation fails (`/Users/allosta/Desktop/allosta/superapp/apps/old-focal/client/src/components/MindMap/MindMap.tsx:4821`), and the new backend has the delete endpoint available (`/Users/allosta/Desktop/allosta/superapp-slice8/apps/focal/server/app/api/spheres.py:58`). Add the state transition contract: create sphere first, create project with the sphere name, disable while either mutation is pending, and rollback/delete the created sphere on project-create failure or defer the create-new affordance.

## Should Consider
- Make the `fullDescription` data plumbing explicit in the design: `graph.ts` must carry `fullDescription` into `FocalNodeData` for base/project/activity nodes before `FocalNode` can show the `FileText` button.
- Specify that inline rename should route through a page/context handler so `FocalNode` does not own calendar scoping, cache invalidation, or mutation error recovery.

## Tests Reviewed
N/A

## Release Risk
Medium

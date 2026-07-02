# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 8.2 / 10
Status: BLOCKED

## Reason
The design frames the layout/edge problem well, chooses a coherent in-place architecture, and gives clear slice-level tests. It is blocked by two concrete design gaps that would prevent claimed behavior from shipping correctly.

## Must Fix
- `.ai/design/focal-goals-mindmap-v2-design.md:45-48` and `.ai/design/focal-goals-mindmap-v2-design.md:117` specify `GET /api/mindmap/edges`, but the actual routed/OpenAPI endpoint is `/api/mindmap-edges` (`superapp/apps/focal/server/app/api/mindmap.py:84`, `superapp/apps/focal/client/src/api/openapi.d.ts:423`). Following the design as written would make persisted edge overrides fail at runtime.
- `.ai/design/focal-goals-mindmap-v2-design.md:27-29` says newly created nodes appear locally next to their parent, but the slice/test scope only covers product/activity creation (`.ai/design/focal-goals-mindmap-v2-design.md:88-90`, `.ai/design/focal-goals-mindmap-v2-design.md:104`). Existing pillar project creation is a separate path (`superapp/apps/focal/client/src/features/goals/GoalsPage.tsx:189`, `superapp/apps/focal/client/src/features/goals/GoalsPage.tsx:585`, `superapp/apps/focal/client/src/features/goals/GoalsPage.tsx:612`), so the design must cover project creation too or explicitly narrow the requirement.

## Should Consider
- Reuse the existing `/api/mindmap/init` aggregate for edge overrides unless there is a stated need for separate refetch semantics; it already includes `edges` (`superapp/apps/focal/server/app/schemas/mindmap.py:97-101`, `superapp/apps/focal/client/src/api/mindmap.ts:3-10`).
- Clarify the `layoutTree` contract: slice 1 says “same signature,” while the architecture table adds a required `parents` parameter.

## Tests Reviewed
N/A

## Release Risk
Medium

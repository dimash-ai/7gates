# Review pass — note on tooling deviation

The Gate-5 doer for this pipeline is normally GPT-Codex (holistic review pass), scored by a fresh
Opus subagent. In this session the GPT-Codex side was **unavailable**: `codex exec` hung at startup
twice (no output for 10 min) and once returned a byte-identical STALE verdict that flagged an
already-committed fix (`GoogleSyncPanel` disconnect action-error) as still missing — a known
load/MCP-churn flakiness while 3+ parallel codex sessions ran.

**Deviation:** the independent holistic review was performed by a fresh-context Opus subagent
instead (it inspected the real committed diff, confirmed the action-error is present in BOTH
`MainCalendarGoogleSection.tsx` and `GoogleSyncPanel.tsx`, checked i18n parity, cache keys, and
scope). Its verdict is in `05-review-verdict.md`. Earlier (stale) codex output is in
`.ai/runs/focal-gsync-connection-05-review-pass*.txt`.

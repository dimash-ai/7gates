# Review Checklist

The reviewer applies this read-only — never editing the artifact. Who reviews alternates by step:
**Opus** reviews steps 2 (plan), 5 (review), 6 (test); **GPT Codex** reviews steps 1 (think),
3 (design), 4 (build), 7 (ship). On its steps Opus runs as a fresh, clean-context subagent so it
never grades its own work.

- [ ] Correctness — does it do what the task says, including edge cases?
- [ ] Matches the original task and the approved plan; flag any deviation.
- [ ] Regressions — anything touched or depended-on that could break?
- [ ] Tests — present, meaningful (not tautological), covering the risky paths?
- [ ] Security (OWASP/STRIDE) — access control & authz, injection (SQL/command/template/prompt), secrets & crypto, SSRF / user-controlled URLs, auth & session, rate-limiting & abuse, audit logging, unsafe defaults.
- [ ] Maintainability — clear enough to live with; no needless complexity.
- [ ] Simplicity First — no overcomplication, bloat, or speculative abstraction (many lines where far fewer would do).
- [ ] Surgical Changes — every changed line traces to the task; no unrelated edits, refactors, or style drift; no code removed that wasn't understood.
- [ ] Think Before Coding — assumptions and tradeoffs surfaced; ambiguity not resolved silently.
- [ ] Goal-Driven Execution — task has verifiable success criteria and tests prove them.
- [ ] Scope — built exactly what the task asked, no more; unrelated edits flagged as the first finding.
- [ ] Completeness beyond the diff — new enum/status/union values handled at every sibling call-site, not just where the diff touches.
- [ ] Findings cite evidence (`file:line` / failing command); uncertain issues go to Should Consider, not Must Fix.
- [ ] No failing/skipped check dismissed as "pre-existing" without proof it also fails on the base branch.
- [ ] Scored 0–10 per `scoring-rubric.md`; Status APPROVED only if Score >= 9.0.
- [ ] Output uses the scored verdict format (Score / Status / Reason / Must Fix / Should Consider / Tests Reviewed / Release Risk).
- [ ] Did NOT edit code; only reviewed and reported.

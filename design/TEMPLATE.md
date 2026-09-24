# Design summary
<!-- Step 3 (design) — Opus does, GPT reviews. The technical approach in plain language: the shape of the solution and the one or two decisions everything else hinges on. Must trace back to the approved think doc and plan. -->

# Architecture
<!-- Components touched/added and how they relate. Coupling, ownership, and where this fits the existing system. A small diagram (ASCII) if it clarifies. -->

# Data model
<!-- New/changed tables, columns, types, indexes, constraints, migrations. "None" if the change adds no persistent state. -->

| entity | change | notes |
|--------|--------|-------|
|        |        |       |

# Interfaces & contracts
<!-- Public functions/endpoints/events this adds or changes: signature, inputs, outputs, error returns. The contract the next developer codes against. -->

# Flow (happy + unhappy paths)
<!-- The main sequence, then what happens on null / empty / upstream error / partial failure. Name each failure, where it is caught, and what the caller/user sees. -->

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| happy |        |               |        |
|       |         |               |        |

# Alternatives rejected
<!-- Designs you considered and dropped, with the reason. Prevents the reviewer re-litigating settled choices. -->
- 

# Test strategy
<!-- Which levels (unit/integration/e2e), the risky paths each level proves, and what "verified" will mean before ship. Detailed test list lives in the plan; here state the strategy. -->
- 

# Security & release notes
<!-- Authz, injection, secrets, SSRF, rate-limiting surfaces this design introduces; migration/rollback shape. "None" only if genuinely none. -->
- 

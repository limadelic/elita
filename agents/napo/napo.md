---
name: napo
tools: spawn, become, set, get
includes: attempt, split, judge
---

# Napo

Problem orchestrator. Initialize depth (read from ETS keyed by your name), spawn judge once (shared), set attempts to zero, become to attempt phase.

When given a problem:
1. Call whoami to get your own name
2. Get key "depth_<your_name>" — if returns "(empty)", treat as depth 0; otherwise parse as integer
3. Spawn judge with configs ["judge"]
4. Set attempts to 0
5. Become to role "attempt"

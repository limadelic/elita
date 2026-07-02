---
name: napo
tools: spawn, cast, set, get
includes: attempt, split, judge
---

# Napo

Problem orchestrator. Spawn judge once (shared), set attempts to zero, cast to attempt phase.

When given a problem:
1. spawn judge with configs ["judge"]
2. set attempts to 0
3. cast to role "attempt"

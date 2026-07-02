---
name: split
tools: spawn, ask
---

# Split Phase

Break the problem into 2 or 3 subproblems. NEVER more than 3.

For each subproblem:
1. Derive a UNIQUE facet name (short word related to that facet)
2. spawn the facet name with configs ["napo"]
3. ask each: the subproblem
4. collect replies

Combine the replies into one final answer. Return it.

CRITICAL: Each spawned child must have a UNIQUE name. Do NOT reuse "napo" or any other child name. Unique names prevent registry collision and keep children as leaves.

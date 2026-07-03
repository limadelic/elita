---
name: split
tools: spawn, tell, whoami, get, set
---

# Split Phase

Break the problem into 2–3 subproblems. HARD CAP: 3 children. Each owns one facet, no auxiliaries.

## Spawn Phase
1. Call whoami for your name
2. Get "depth_<your_name>" (integer, default 0)
3. For each subproblem (2–3 total):
   - Derive unique facet name (short word)
   - Set "depth_<facet_name>" = (your_depth + 1)
   - Spawn facet name with configs ["napo"]

## Structure Phase
4. Set "tree_<your_name>" = "facet1: [subproblem 1] | facet2: [subproblem 2] | ..."

## Tell Phase
5. Tell each child their subproblem (fire and forget, no wait)

## Return
6. Return immediately: structure + "children spawned and told"

Children fill tree_<facet_name> asynchronously when their judge verdicts complete. Do not block or poll.

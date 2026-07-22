---
name: split
tools: spawn, tell, get, set
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
5. Tell each child their subproblem ending with "when done tell <your_name>" (fire and forget, no wait)

## Return
6. Return immediately: structure + "children spawned and told"

Children fill tree_<facet_name> asynchronously when their judge verdicts complete. Do not block or poll.

## Listen Phase
7. When message says a child is done:
   - Get tree_<child> for all children in structure
   - If all tree_<child> filled: set tree_<yourname> = combined answer (present children's content verbatim, no rewrite)
   - If problem names a parent, tell that parent "<yourname> done"
   - If some pending: do nothing
   
8. If anyone ASKS status:
   - Answer from memory: which children done, which pending
   - If all done, include combined answer

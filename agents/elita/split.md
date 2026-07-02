---
name: split
tools: spawn, ask, whoami, get, set
---

# Split Phase

Break the problem into 2 or 3 subproblems. NEVER more than 3. Propagate depth to children.

For each subproblem:
1. Call whoami to get your own name
2. Get "depth_<your_name>" to learn your current depth (parse as integer, default 0)
3. Derive a UNIQUE facet name (short word related to that facet)
4. Set "depth_<facet_name>" to (current_depth + 1) to pass depth to child
5. Spawn the facet name with configs ["napo"]
6. Ask each child: the subproblem
7. Collect replies

After all children spawned and replied:
8. For each child, get "tree_<child_name>" to retrieve their subtree (if it exists)
9. Call whoami again to confirm your own name
10. Build combined tree structure:
    - Include each child's tree: "child1: [their_tree_content] | child2: [their_tree_content] | ..."
11. Set "tree_<your_name>" to this combined structure
12. In your final answer, include the complete assembled tree (do NOT paraphrase children's content; present it verbatim from tree_ keys)

Combine the replies into one final answer with the tree structure. Return it.

CRITICAL: Each spawned child must have a UNIQUE name. Do NOT reuse "napo" or any other child name. Unique names prevent registry collision.

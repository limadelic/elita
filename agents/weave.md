---
name: weave
tools: get, set, browse, cast
---

# Weave

Your goal is to execute each todo from planning.

Get the todos.
Get the host.
For each todo with status pending:
- Use browse to achieve the todo goal
- Only navigate to URLs on the host
- Navigate returns numbered snapshot of interactive elements
- Use element indices from snapshot, never guess
- Get fresh snapshot after page changes
- Extract actual data from page content
- Update todo result with what you found
- Set status to done

Use set tool to save updated todos.
When all done, cast to mend for review.

---
name: tell
description: Tell an agent a message asynchronously
imports: 
---

# Tell

Tell an agent a message without waiting for response.

Uses Agent.Router to handle agent dispatch with fallback to direct cast if not registered.

Returns acknowledgment or error.

```elixir
case Agent.Router.route(String.to_atom(recipient), :tell, message) do
  :ok -> "message sent"
  {:error, :not_found} -> "agent not found"
  other -> other
end
```

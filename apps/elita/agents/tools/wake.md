---
name: wake
description: Wake an agent with a message and return response
imports: 
---

# Wake

Wake an agent and get its response.

Uses Agent.Router to handle agent dispatch with fallback to direct call if not registered.

Returns the agent's response or error message.

```elixir
case Agent.Router.route(String.to_atom(agent), :ask, message) do
  {:ok, response} -> response
  {:error, :not_found} -> "agent not found"
  other -> other
end
```

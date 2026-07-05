---
name: wake
description: Wake an agent with a message
imports: 
---

# Wake

Look up an agent in the registry and send it a message.

Returns the agent's response, or "agent not found" if not registered.

```elixir
case Agent.Registry.lookup(String.to_atom(agent)) do
  {:ok, {pid, _folder}} ->
    {:ok, response} = Agent.Session.ask(pid, message)
    response
  {:error, :not_found} ->
    "agent not found"
end
```

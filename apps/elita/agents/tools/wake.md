---
name: wake
description: Wake an agent with a message
imports: 
---

# Wake

Look up an agent in the registry and send it a message.

Dispatches by folder kind:
- nil folder → markdown/Elita agent via Elita.call
- binary folder → external session via Agent.Session.ask

Returns the agent's response, or "agent not found" if not registered.

```elixir
case Agent.Registry.lookup(String.to_atom(name)) do
  {:ok, {_pid, nil}} ->
    Elita.call(String.to_atom(name), message)
  {:ok, {pid, _folder}} ->
    {:ok, response} = Agent.Session.ask(pid, message)
    response
  {:error, :not_found} ->
    "agent not found"
end
```

---
name: tell
description: Tell an agent a message asynchronously
imports: 
---

# Tell

Look up an agent in the registry and send it a message without waiting for response.

Dispatches by folder kind:
- nil folder → markdown/Elita agent via Elita.cast
- binary folder → external session via Agent.Session.cast

Returns acknowledgment: "message sent" or "agent not found" if not registered.

```elixir
case Agent.Registry.lookup(String.to_atom(recipient)) do
  {:ok, {_pid, nil}} ->
    Elita.cast(String.to_atom(recipient), message)
    "message sent"
  {:ok, {pid, _folder}} ->
    Agent.Session.cast(pid, message)
    "message sent"
  {:error, :not_found} ->
    "agent not found"
end
```

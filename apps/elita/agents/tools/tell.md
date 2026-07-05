---
name: tell
description: Tell an agent a message asynchronously
params: recipient, message
imports: 
---

# Tell

Look up an agent in the registry and send it a message without waiting for response.

Registry routes sessions with binary folder; unregistered/markdown agents fall back to plain cast.

Returns acknowledgment: "sent".

```elixir
formatted = "[from #{sender}] #{message}"

case Agent.Registry.lookup(String.to_atom(recipient)) do
  {:ok, {pid, folder}} when is_binary(folder) ->
    Agent.Session.cast(pid, formatted)
    "sent"
  _ ->
    Elita.cast(String.to_atom(recipient), formatted)
    "sent"
end
```

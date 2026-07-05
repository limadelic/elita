---
name: lookup
description: Query registry for agent location
imports: 
---

# Lookup

Query the agent registry to find where an agent is running.

Returns the process ID and folder path, or "not found" if not registered.

```elixir
case Agent.Registry.lookup(String.to_atom(name)) do
  {:ok, {pid, folder}} -> "#{inspect(pid)} at #{folder}"
  {:error, :not_found} -> "not found"
end
```

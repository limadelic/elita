---
name: spec
description: reads a spec file
args:
  file:
    type: string
    description: spec file to read
imports: File
---

# Spec

Reads a spec file

```elixir
  case read file do
    {:ok, content} -> content
    {:error, _} -> "spec file not found"
  end
```
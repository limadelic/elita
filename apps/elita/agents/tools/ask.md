---
name: ask
description: Ask question to another agent and get response
params: recipient, question
imports: 
---

# Ask

Ask a question to another agent and wait for the response.

Registry routes sessions with binary folder; unregistered/markdown agents fall back to plain ask dispatch through el.

```elixir
Elita.call(:el, "ask #{recipient} #{question}")
```

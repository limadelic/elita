---
name: pick_10
description: Pick 10 dominoes from the shuffled deck and update remaining
tools: get, set
imports: Enum
---

# Pick 10

Take 10 dominoes from the shuffled deck and remove them from available dominoes.

Returns the 10 picked dominoes for the player.

```elixir
dominoes = get :dominoes

{picked, remaining} = split dominoes, 10

set :dominoes, remaining

picked
```
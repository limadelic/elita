---
name: dale_agua
description: Shuffle dominoes Cuban style - give water to the bones
tools: set
imports: Enum
---

# Dale Agua

In Cuba, shuffling dominoes is called "dar agua". The tiles flow and mix like water washing over stones.

This tool generates all combinations from [0,0] to [9,9] and shuffles them in random order.

The shuffled dominoes are stored as dominoes.

```elixir
dominoes = shuffle(for h <- 0..9, t <- h..9, do: [h, t])

set :dominoes, dominoes
```
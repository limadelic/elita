# Elita

Agentic platform using OTP patterns for reliable agent behavior

## Runtime model

`Elita` agent processes are registered by name but **not** placed under the
application supervisor: they are started from the escript or from tools. Crashes
are **not** automatically restarted—by design for a CLI-oriented workflow.

## Testing

- **`mix test`** — full suite (includes LLM-driven `Tester` cases).
- **`mix test_fast`** — runs `mix test --exclude integration` (skips modules using `use Tester`).

## Performance notes

- Conversation **`history`** is stored **newest-first** and reversed when building API requests (linear append cost per turn).
- **`Out.assist`** avoids syncing the fd on every write; **`Out.flush`** runs after each completed reply and after streaming.
- **SSE** response bytes kept for diagnostics are **capped** (8 KB tail).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `elita` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elita, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/elita>.

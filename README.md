# Elita

Agentic platform using OTP patterns for reliable agent behavior

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

## Tape

Agent calls replay from cassettes in `test/cassettes/` — readable JSON, `q` matches the request, `a` is the reply.

- `mix test` — replay, free
- `mix tape` — record live
- `mix live` — live, no tape

Edit the tape and the tape is the spec.

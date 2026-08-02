defmodule Tape.Play do
  import Tape.Matcher, only: [contains: 2]
  import Tape.Store, only: [load: 2]
  import Tape.Writer, only: [claim: 3]
  import Tape.Play.Pick, only: [agent: 1]
  import System, only: [get_env: 1]
  import Enum, only: [at: 2]
  import Map, only: [get: 2, get: 3]
  import List, only: [last: 1]
  import Jason, only: [decode!: 1, encode!: 1]

  def play(body, name, fun) do
    e = load(c = get_env("CASSETTE"), get_env("CASSETTE_DIR"))
    seed(e, c)
    %{entries: e, normalized: norm(body, name), body: body,
      name: name, fun: fun, cassette: c} |> answer()
  end

  defp norm(body, name) do
    messages = get(body, :messages, [])
    sparse(name, messages) |> normalize()
  end

  defp sparse(name, messages) do
    %{"agent" => name, "messages" => recent(messages), "n" => length(messages)}
  end

  defp recent([]), do: []
  defp recent(messages), do: [last(messages)]

  defp seed([], cassette), do: guard(cassette)
  defp seed(_, _), do: :ok

  defp guard(nil), do: :ok
  defp guard(cassette), do: raise("no cassette: #{cassette}")

  defp answer(ctx) do
    agent(ctx) |> process(ctx)
  end

  defp process(nil, ctx), do: untagged(ctx, 0)
  defp process(answer, _ctx), do: answer

  defp untagged(%{entries: entries, name: name, normalized: normalized}, idx) when idx >= length(entries) do
    raise "tape miss: #{name} #{inspect(normalized)}"
  end

  defp untagged(ctx, idx) do
    entry = at(ctx.entries, idx)
    scan(entry, ctx, idx, get(entry["q"], "agent"))
  end

  defp scan(entry, ctx, idx, nil) do
    hit(contains(entry["q"], ctx.normalized), entry, ctx, idx)
  end

  defp scan(_entry, ctx, idx, _agent), do: untagged(ctx, idx + 1)

  defp hit(true, entry, ctx, idx) do
    claim(ctx.cassette, idx, ticks(entry))
    |> keep(entry, ctx, idx)
  end

  defp hit(false, _entry, ctx, idx), do: untagged(ctx, idx + 1)

  defp keep(true, entry, _ctx, _idx), do: entry["a"]
  defp keep(false, _entry, ctx, idx), do: untagged(ctx, idx + 1)

  defp ticks(%{"times" => times}), do: times
  defp ticks(_), do: 1

  defp normalize(req), do: req |> encode!() |> decode!()
end

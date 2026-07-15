defmodule Tape.Play do
  import Tape.Matcher, only: [contains: 2]
  import Tape.Store, only: [load: 0]
  import Tape.Writer, only: [claim: 3]
  import Tape.Play.Pick, only: [agent: 1]
  import System, only: [get_env: 1]
  import Enum, only: [at: 2]
  import Map, only: [get: 2, get: 3]
  import List, only: [last: 1]
  import Jason, only: [decode!: 1, encode!: 1]

  def play(body, name, fun, on_miss \\ :raise) do
    seed(load())
    context(load(), body, name, fun, on_miss) |> answer()
  end

  defp context(entries, body, name, fun, miss) do
    %{entries: entries, normalized: norm(body, name), body: body,
      name: name, fun: fun, on_miss: miss}
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

  defp seed([]), do: guard(get_env("CASSETTE"))
  defp seed(_), do: :ok

  defp guard(nil), do: :ok
  defp guard(cassette), do: raise("no cassette: #{cassette}")

  defp answer(ctx) do
    agent(ctx) |> process(ctx)
  end

  defp process(nil, ctx), do: untagged(ctx, 0)
  defp process(answer, _ctx), do: answer

  defp untagged(%{entries: entries, on_miss: :raise} = ctx, idx) when idx >= length(entries) do
    raise "tape miss: #{ctx.name} #{inspect(ctx.normalized)}"
  end

  defp untagged(%{entries: entries, on_miss: :live, fun: fun}, idx) when idx >= length(entries) do
    fun.()
  end

  defp untagged(%{entries: entries, on_miss: :swallow}, idx) when idx >= length(entries) do
    []
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
    claim(tape(), idx, ticks(entry))
    |> keep(entry, ctx, idx)
  end

  defp hit(false, _entry, ctx, idx), do: untagged(ctx, idx + 1)

  defp keep(true, entry, _ctx, _idx), do: entry["a"]
  defp keep(false, _entry, ctx, idx), do: untagged(ctx, idx + 1)

  defp ticks(%{"times" => times}), do: times
  defp ticks(_), do: 1

  defp tape, do: get_env("CASSETTE")
  defp normalize(req), do: req |> encode!() |> decode!()
end

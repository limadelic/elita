defmodule Tape.Play.Pick do
  import Tape.Matcher, only: [contains: 2]
  import Tape.Writer, only: [bind: 4]
  import System, only: [get_env: 1]
  import Enum, only: [filter: 2, map: 2, find: 2, find_index: 2, split_with: 2]
  import Map, only: [drop: 2, get: 2, get: 3]
  import List, only: [last: 1]

  def agent(ctx) do
    ctx.entries
    |> filter(&entry?(&1, ctx.name))
    |> filter(&fits?(&1, ctx.normalized))
    |> pick(ctx)
  end

  defp entry?(e, name), do: get(e["q"], "agent") == name

  defp fits?(entry, normalized) do
    contains(drop(entry["q"], ["agent", "n"]), normalized)
  end

  defp pick([], _ctx), do: nil

  defp pick(matches, ctx) do
    count = length(get(ctx.body, :messages, []))
    sorted = sort(matches, count)
    indexed = map(sorted, fn m -> {m, index(ctx.entries, m)} end)
    extract(find(indexed, &slot?(ctx, &1)), sorted)
  end

  defp sort(matches, count) do
    {t, o} = split_with(matches, &(get(&1["q"], "n") == count))
    t ++ o
  end

  defp index(entries, target), do: find_index(entries, &(&1 == target))

  defp extract({e, _}, _), do: e["a"]
  defp extract(nil, []), do: nil
  defp extract(nil, matches), do: last(matches)["a"]

  defp slot?(ctx, {e, idx}) do
    bind(key(), ctx.name, idx, times(e))
  end

  defp times(%{"times" => times}), do: times
  defp times(_), do: 1

  defp key, do: get_env("CASSETTE")
end

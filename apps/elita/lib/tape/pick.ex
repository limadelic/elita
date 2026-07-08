defmodule Tape.Play.Pick do
  import Tape.Matcher, only: [contains: 2]
  import Tape.Writer, only: [claim_agent: 4]
  import System, only: [get_env: 1]
  import Enum, only: [filter: 2, map: 2, find: 2, find_index: 2, split_with: 2]
  import Map, only: [drop: 2, get: 2, get: 3]
  import List, only: [last: 1]

  def agent(ctx) do
    ctx.entries
    |> filter(&agent_entry?(&1, ctx.name))
    |> filter(&content_match?(&1, ctx.normalized))
    |> pick(ctx)
  end

  defp agent_entry?(e, name), do: get(e["q"], "agent") == name

  defp content_match?(entry, normalized) do
    contains(drop(entry["q"], ["agent", "n"]), normalized)
  end

  defp pick([], _ctx), do: nil

  defp pick(matches, ctx) do
    count = length(get(ctx.body, :messages, []))
    sorted = sort(matches, count)
    indexed = map(sorted, fn m -> {m, index(ctx.entries, m)} end)
    extract(find(indexed, &claim_slot?(ctx, &1)), sorted)
  end

  defp sort(matches, count) do
    {t, o} = split_with(matches, &(get(&1["q"], "n") == count))
    t ++ o
  end

  defp index(entries, target), do: find_index(entries, &(&1 == target))

  defp extract({e, _}, _), do: e["a"]
  defp extract(nil, []), do: nil
  defp extract(nil, matches), do: last(matches)["a"]

  defp claim_slot?(ctx, {e, idx}) do
    claim_agent(cassette_key(), ctx.name, idx, get_times(e))
  end

  defp get_times(%{"times" => times}), do: times
  defp get_times(_), do: 1

  defp cassette_key, do: get_env("CASSETTE")
end

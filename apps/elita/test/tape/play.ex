defmodule Tape.Play do
  import Tape.Matcher, only: [contains: 2]
  import Tape.Writer, only: [claim_agent: 4, claim: 3]
  import Tape.Store, only: [load_entries: 0]

  def handle(body, name, fun) do
    ensure_entries(load())

    %{entries: load(), normalized: norm(body), body: body, name: name, fun: fun}
    |> answer()
  end

  defp load, do: load_entries()
  defp norm(body), do: normalize(request(body))

  defp ensure_entries([]), do: validate_cassette(System.get_env("CASSETTE"))
  defp ensure_entries(_), do: :ok

  defp validate_cassette(nil), do: :ok
  defp validate_cassette(cassette), do: raise("no cassette: #{cassette}")

  defp answer(ctx) do
    agent_answer(ctx) |> handle_answer(ctx)
  end

  defp handle_answer(nil, ctx), do: untagged(ctx, 0)
  defp handle_answer(answer, _ctx), do: answer

  defp agent_answer(ctx) do
    ctx.entries
    |> Enum.filter(&agent_entry?(&1, ctx.name))
    |> Enum.filter(&content_match?(&1, ctx.normalized))
    |> pick_answer(ctx)
  end

  defp agent_entry?(e, name), do: Map.get(e["q"], "agent") == name

  defp content_match?(entry, normalized) do
    contains(Map.drop(entry["q"], ["agent", "n"]), normalized)
  end

  defp pick_answer([], _ctx), do: nil

  defp pick_answer(matches, ctx) do
    count = length(Map.get(ctx.body, :messages, []))
    sorted = sort_matches(matches, count)
    indexed = Enum.map(sorted, fn m -> {m, find_idx(ctx.entries, m)} end)
    extract_answer(Enum.find(indexed, &claim_slot?(ctx, &1)), sorted, ctx)
  end

  defp sort_matches(matches, count) do
    {t, o} = Enum.split_with(matches, &(Map.get(&1["q"], "n") == count))
    t ++ o
  end

  defp find_idx(entries, target), do: Enum.find_index(entries, &(&1 == target))

  defp extract_answer({e, _}, _, _), do: e["a"]
  defp extract_answer(nil, [], _), do: nil
  defp extract_answer(nil, _, ctx) do
    raise "tape miss: #{ctx.name} #{inspect(ctx.normalized)}"
  end

  defp claim_slot?(ctx, {e, idx}) do
    claim_agent(cassette_key(), ctx.name, idx, get_times(e))
  end

  defp untagged(%{entries: entries} = ctx, idx) when idx >= length(entries) do
    raise "tape miss: #{ctx.name} #{inspect(ctx.normalized)}"
  end

  defp untagged(ctx, idx) do
    entry = Enum.at(ctx.entries, idx)
    check_untagged(entry, ctx, idx, Map.get(entry["q"], "agent"))
  end

  defp check_untagged(entry, ctx, idx, nil) do
    if_match(contains(entry["q"], ctx.normalized), entry, ctx, idx)
  end

  defp check_untagged(_entry, ctx, idx, _agent), do: untagged(ctx, idx + 1)

  defp if_match(true, entry, ctx, idx) do
    claim(cassette_key(), idx, get_times(entry))
    |> claim_result(entry, ctx, idx)
  end

  defp if_match(false, _entry, ctx, idx), do: untagged(ctx, idx + 1)

  defp claim_result(true, entry, _ctx, _idx), do: entry["a"]
  defp claim_result(false, _entry, ctx, idx), do: untagged(ctx, idx + 1)

  defp get_times(%{"times" => times}), do: times
  defp get_times(_), do: 1

  defp cassette_key, do: System.get_env("CASSETTE")
  defp normalize(req), do: req |> Jason.encode!() |> Jason.decode!()
  defp request(body), do: Map.take(body, [:system, :messages, :tools])
end

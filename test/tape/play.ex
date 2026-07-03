defmodule Tape.Play do
  import Tape.Matcher, only: [contains: 2]

  def handle(body, name, fun) do
    normalized = normalize(request(body))
    entries = Tape.Store.load_entries()
    ensure_entries(entries)
    %{entries: entries, normalized: normalized, body: body, name: name, fun: fun}
    |> answer()
  end

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
    |> Enum.filter(&turn_match?(&1, ctx.body))
    |> Enum.filter(&content_match?(&1, ctx.normalized))
    |> pick_answer(ctx)
  end

  defp agent_entry?(e, name), do: Map.get(e["q"], "agent") == name

  defp turn_match?(%{"q" => %{"n" => n}}, body) do
    n == length(Map.get(body, :messages, []))
  end

  defp turn_match?(_entry, _body), do: true

  defp content_match?(entry, normalized) do
    contains(Map.delete(entry["q"], "agent"), normalized)
  end

  defp pick_answer([], _ctx), do: nil

  defp pick_answer(matches, ctx) do
    indexed = Enum.map(matches, &{&1, find_idx(ctx.entries, &1)})
    claimed = Enum.find(indexed, &claim_slot?(ctx, &1))
    extract_answer(claimed, matches)
  end

  defp extract_answer({e, _}, _), do: e["a"]
  defp extract_answer(nil, matches), do: List.last(matches)["a"]

  defp claim_slot?(ctx, {e, idx}) do
    Tape.Writer.claim_agent(cassette_key(), ctx.name, idx, get_times(e))
  end

  defp find_idx(entries, target) do
    Enum.find_index(entries, &(&1 == target))
  end

  defp untagged(%{entries: entries} = ctx, idx) when idx >= length(entries) do
    raise "tape miss: #{ctx.name} #{inspect(ctx.normalized)}"
  end

  defp untagged(ctx, idx) do
    entry = Enum.at(ctx.entries, idx)
    dispatch_tag_check(Map.get(entry["q"], "agent"), entry, ctx, idx)
  end

  defp dispatch_tag_check(nil, entry, ctx, idx), do: check_untagged(entry, ctx, idx)
  defp dispatch_tag_check(_agent, ctx, idx), do: untagged(ctx, idx + 1)

  defp check_untagged(entry, ctx, idx) do
    dispatch_content_check(contains(entry["q"], ctx.normalized), entry, ctx, idx)
  end

  defp dispatch_content_check(true, entry, ctx, idx), do: try_claim_untagged(entry, ctx, idx)
  defp dispatch_content_check(false, _entry, ctx, idx), do: untagged(ctx, idx + 1)

  defp try_claim_untagged(entry, ctx, idx) do
    dispatch_claim(Tape.Writer.claim(cassette_key(), idx, get_times(entry)), entry, ctx, idx)
  end

  defp dispatch_claim(true, entry, _ctx, _idx), do: entry["a"]
  defp dispatch_claim(false, _entry, ctx, idx), do: untagged(ctx, idx + 1)

  defp get_times(%{"times" => times}), do: times
  defp get_times(_), do: 1

  defp cassette_key, do: System.get_env("CASSETTE")
  defp normalize(req), do: req |> Jason.encode!() |> Jason.decode!()
  defp request(body), do: Map.take(body, [:system, :messages, :tools])
end

defmodule Tape.Play do
  import Tape.Matcher, only: [contains: 2]

  def handle(body, name, fun) do
    normalized = normalize(request(body))
    entries = Tape.Store.load_entries()
    ensure_entries(entries)
    ctx = %{entries: entries, normalized: normalized, body: body, name: name, fun: fun}
    try_ordered(ctx)
  end

  defp ensure_entries([]) do
    validate_cassette(System.get_env("CASSETTE"))
  end

  defp ensure_entries(_entries), do: :ok

  defp validate_cassette(nil), do: :ok

  defp validate_cassette(cassette) do
    raise("no cassette: #{cassette}")
  end

  defp try_ordered(ctx) do
    agent_entries = agent_list(ctx.entries, ctx.name)
    try_next_ordered(ctx, agent_entries)
  end

  defp try_next_ordered(ctx, agent_entries) when length(agent_entries) > 0 do
    idx = Tape.Writer.next_idx(cassette_key(), ctx.name)
    entry = Enum.at(agent_entries, idx)
    return_ordered_or_fallback(entry, ctx)
  end

  defp return_ordered_or_fallback(entry, ctx) when not is_nil(entry) do
    entry["a"]
  end

  defp return_ordered_or_fallback(_entry, ctx) do
    find_untagged(ctx, 0)
  end

  defp try_next_ordered(ctx, _agent_entries) do
    find_untagged(ctx, 0)
  end

  defp agent_list(entries, name) do
    entries |> Enum.filter(fn e -> Map.get(e["q"], "agent") == name end)
  end

  defp find_untagged(%{entries: entries} = ctx, idx) when idx >= length(entries) do
    raise "tape miss: #{ctx.name} #{inspect(ctx.normalized)}"
  end

  defp find_untagged(ctx, idx) do
    entry = Enum.at(ctx.entries, idx)
    req = entry["q"]
    agent = Map.get(req, "agent")
    check_match(agent, entry, ctx, idx)
  end

  defp check_match(nil, entry, ctx, idx) do
    match = contains(entry["q"], ctx.normalized)
    process_match(match, entry, ctx, idx)
  end

  defp check_match(_agent, _entry, ctx, idx) do
    find_untagged(ctx, idx + 1)
  end

  defp process_match(true, entry, ctx, idx) do
    claimed = Tape.Writer.claim(cassette_key(), idx, get_times(entry))
    return_or_skip(claimed, entry, ctx, idx)
  end

  defp process_match(false, _entry, ctx, idx) do
    find_untagged(ctx, idx + 1)
  end

  defp return_or_skip(true, entry, _ctx, _idx), do: entry["a"]
  defp return_or_skip(false, _entry, ctx, idx), do: find_untagged(ctx, idx + 1)

  defp get_times(%{"times" => times}), do: times
  defp get_times(_entry), do: 1

  defp cassette_key do
    System.get_env("CASSETTE")
  end

  defp normalize(req), do: req |> Jason.encode!() |> Jason.decode!()

  defp request(body), do: Map.take(body, [:system, :messages, :tools])
end

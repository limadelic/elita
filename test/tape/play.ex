defmodule Tape.Play do
  import Tape.Matcher, only: [contains: 2]

  def handle(body, name, fun) do
    normalized = normalize(request(body))
    entries = Tape.Store.load_entries()
    ensure_entries(entries)
    ctx = %{entries: entries, normalized: normalized, body: body, name: name, fun: fun}
    find_match(ctx, 0)
  end

  defp ensure_entries(entries) do
    cassette = System.get_env("CASSETTE")
    if cassette && Enum.empty?(entries) do
      raise "no cassette: #{cassette}"
    end
  end

  defp find_match(%{entries: entries} = ctx, idx) when idx >= length(entries) do
    raise "tape miss: #{ctx.name} #{inspect(ctx.normalized)}"
  end

  defp find_match(ctx, idx) do
    entry = Enum.at(ctx.entries, idx)
    check_match(entry, ctx, idx)
  end

  defp check_match(entry, ctx, idx) do
    req = entry["q"]
    if agent_match(req, ctx.name) do
      filtered = Map.delete(req, "agent")
      match = contains(filtered, ctx.normalized)
      process_match(match, entry, ctx, idx)
    else
      find_match(ctx, idx + 1)
    end
  end

  defp agent_match(req, name) do
    agent = Map.get(req, "agent")
    agent == nil or agent == name
  end

  defp process_match(true, entry, ctx, idx) do
    claimed = Tape.Writer.claim(cassette_key(), idx, get_times(entry))
    return_or_skip(claimed, entry, ctx, idx)
  end

  defp process_match(false, _entry, ctx, idx) do
    find_match(ctx, idx + 1)
  end

  defp return_or_skip(true, entry, _ctx, _idx), do: entry["a"]
  defp return_or_skip(false, _entry, ctx, idx), do: find_match(ctx, idx + 1)

  defp get_times(%{"times" => times}), do: times
  defp get_times(_entry), do: 1

  defp cassette_key do
    System.get_env("CASSETTE")
  end

  defp normalize(req), do: req |> Jason.encode!() |> Jason.decode!()

  defp request(body), do: Map.take(body, [:system, :messages, :tools])
end

defmodule Tape.Play do
  import Tape.Matcher, only: [contains: 2]

  def handle(body, name, fun) do
    normalized = normalize(request(body))
    entries = Tape.Store.load_entries()
    ctx = %{entries: entries, normalized: normalized, body: body, name: name, fun: fun}
    find_match(ctx, 0)
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
    match = contains(req, ctx.normalized)
    process_match(match, entry, ctx, idx)
  end

  defp process_match(true, entry, ctx, idx) do
    if Tape.Writer.claim(cassette_key(), idx, get_times(entry)) do
      entry["a"]
    else
      find_match(ctx, idx + 1)
    end
  end

  defp process_match(false, _entry, ctx, idx) do
    find_match(ctx, idx + 1)
  end

  defp get_times(%{"times" => times}), do: times
  defp get_times(_entry), do: 1

  defp cassette_key do
    System.get_env("CASSETTE")
  end

  defp normalize(req), do: req |> Jason.encode!() |> Jason.decode!()

  defp request(body), do: Map.take(body, [:system, :messages, :tools])
end

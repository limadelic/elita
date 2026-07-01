defmodule Tape.Play do
  import Tape.Matcher, only: [contains: 2]
  alias Tape.Record

  def handle(body, name, fun) do
    normalized = normalize(request(body))
    entries = Tape.Store.load_entries()
    ctx = %{entries: entries, normalized: normalized, body: body, name: name, fun: fun}
    find_match(ctx, 0)
  end

  defp find_match(%{entries: entries} = ctx, idx) when idx >= length(entries) do
    Record.handle(ctx.body, ctx.name, ctx.fun)
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
    use_entry_if(exhausted?(entry, idx), entry, ctx, idx)
  end

  defp process_match(false, _entry, ctx, idx) do
    find_match(ctx, idx + 1)
  end

  defp use_entry_if(false, entry, _ctx, idx) do
    increment_hit_count(idx)
    entry["a"]
  end

  defp use_entry_if(true, _entry, ctx, idx) do
    find_match(ctx, idx + 1)
  end

  defp exhausted?(entry, idx) do
    times = get_times(entry)
    is_exhausted_check(times, idx)
  end

  defp get_times(%{"times" => times}), do: times
  defp get_times(_entry), do: 1

  defp is_exhausted_check("always", _idx), do: false
  defp is_exhausted_check(times, idx) do
    times <= get_hit_count(idx)
  end

  defp get_hit_count(idx) do
    Tape.Writer.get_hit_count(cassette_key(), idx)
  end

  defp increment_hit_count(idx) do
    Tape.Writer.increment_hit_count(cassette_key(), idx)
  end

  defp cassette_key do
    System.get_env("CASSETTE")
  end

  defp normalize(req), do: req |> Jason.encode!() |> Jason.decode!()

  defp request(body), do: Map.take(body, [:system, :messages, :tools])
end

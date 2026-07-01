defmodule Tape.Replay.Exact do
  import Jason
  import Tape.Matcher, only: [contains: 2]

  def first_match(entries, body, request_fun) do
    incoming = normalize(request(body))
    ctx = %{entries: entries, incoming: incoming, body: body, request_fun: request_fun}
    find_match(ctx, 0)
  end

  defp find_match(%{entries: entries} = ctx, idx) when idx >= length(entries) do
    Tape.Replay.live(ctx.body, ctx.request_fun)
  end

  defp find_match(ctx, idx) do
    entry = Enum.at(ctx.entries, idx)
    check_match(entry, ctx, idx)
  end

  defp check_match(entry, ctx, idx) do
    req = entry["req"]
    match = contains(req, ctx.incoming)
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
    entry["res"]
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
    key = :"tape_hit_#{cassette_key()}_#{idx}"
    Process.get(key, 0)
  end

  defp increment_hit_count(idx) do
    key = :"tape_hit_#{cassette_key()}_#{idx}"
    current = Process.get(key, 0)
    Process.put(key, current + 1)
  end

  defp cassette_key do
    System.get_env("CASSETTE")
  end

  defp normalize(req), do: req |> Jason.encode!() |> Jason.decode!()

  defp request(body), do: Map.take(body, [:system, :messages, :tools])
end

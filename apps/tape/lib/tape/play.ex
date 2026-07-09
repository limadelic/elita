defmodule Tape.Play do
  import Tape.Matcher, only: [contains: 2]
  import Tape.Store, only: [load_entries: 0]
  import Tape.Writer, only: [claim: 3]
  import Tape.Play.Pick, only: [agent: 1]
  import System, only: [get_env: 1]
  import Enum, only: [at: 2]
  import Map, only: [get: 2, take: 2]
  import Jason, only: [decode!: 1, encode!: 1]

  def handle(body, name, fun) do
    ensure_entries(load())

    %{entries: load(), normalized: norm(body), body: body, name: name, fun: fun}
    |> answer()
  end

  defp load, do: load_entries()
  defp norm(body), do: normalize(request(body))

  defp ensure_entries([]), do: validate_cassette(get_env("CASSETTE"))
  defp ensure_entries(_), do: :ok

  defp validate_cassette(nil), do: :ok
  defp validate_cassette(cassette), do: raise("no cassette: #{cassette}")

  defp answer(ctx) do
    agent(ctx) |> handle_answer(ctx)
  end

  defp handle_answer(nil, ctx), do: untagged(ctx, 0)
  defp handle_answer(answer, _ctx), do: answer

  defp untagged(%{entries: entries} = ctx, idx) when idx >= length(entries) do
    raise "tape miss: #{ctx.name} #{inspect(ctx.normalized)}"
  end

  defp untagged(ctx, idx) do
    entry = at(ctx.entries, idx)
    check_untagged(entry, ctx, idx, get(entry["q"], "agent"))
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

  defp cassette_key, do: get_env("CASSETTE")
  defp normalize(req), do: req |> encode!() |> decode!()
  defp request(body), do: take(body, [:system, :messages, :tools])
end

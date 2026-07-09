defmodule Now do
  import System, only: [get_env: 2]
  import String, only: [split: 2, to_integer: 1]
  import NaiveDateTime, only: [from_erl!: 1]

  def time do
    read_clock().()
  end

  def text do
    time() |> from_erl!() |> to_string()
  end

  defp read_clock do
    Application.get_env(:elita, :clock, &clock_from_env/0)
  end

  defp clock_from_env do
    "CLOCK"
    |> get_env("10:00:00")
    |> parse()
  end

  defp parse(str) do
    [h, m | rest] = split(str, ":")
    s = seconds(rest)
    {{2025, 7, 7}, {to_integer(h), to_integer(m), to_integer(s)}}
  end

  defp seconds([]), do: "0"
  defp seconds(list), do: hd(list)
end

defmodule Now do
  import :calendar, only: [local_time: 0]
  import Application, only: [get_env: 3]
  import System, only: [get_env: 1]
  import NaiveDateTime, only: [from_erl!: 1, from_iso8601!: 1, to_erl: 1]

  def time do
    get_env("CLOCK") |> clock()
  end

  def text do
    time() |> from_erl!() |> to_string()
  end

  defp clock(nil), do: get_env(:elita, :clock, &default/0).()

  defp clock(str), do: from_iso8601!(str) |> to_erl()

  defp default do
    local_time()
  end
end

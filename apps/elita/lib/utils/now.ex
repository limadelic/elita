defmodule Now do
  import :calendar, only: [local_time: 0]
  import Application, only: [get_env: 3]

  def time do
    get_env(:elita, :clock, &default/0).()
  end

  def text do
    time() |> NaiveDateTime.from_erl!() |> to_string()
  end

  defp default do
    local_time()
  end
end

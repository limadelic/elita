defmodule Tape do
  import Keyword, only: [get: 2, get: 3]
  import Tape.Play, only: [play: 4]
  import Tape.Record, only: [record: 3]

  def handle(body, name, fun, opts \\ []) do
    %{body: body, name: name, fun: fun, on_miss: get(opts, :on_miss, :raise),
      tape: get(opts, :tape), live: get(opts, :live)}
    |> route()
  end

  defp route(%{tape: "rec", body: body, name: name, fun: fun}), do: record(body, name, fun)
  defp route(%{live: "1", fun: fun}), do: fun.()

  defp route(%{body: body, name: name, fun: fun, on_miss: on_miss}),
    do: play(body, name, fun, on_miss)
end

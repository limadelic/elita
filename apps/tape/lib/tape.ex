defmodule Tape do
  import Keyword, only: [get: 2]
  import Tape.Play, only: [play: 3]
  import Tape.Record, only: [record: 3]

  def handle(body, name, fun, opts \\ []) do
    %{body: body, name: name, fun: fun,
      tape: get(opts, :tape), live: get(opts, :live)}
    |> route()
  end

  defp route(%{tape: "rec", body: body, name: name, fun: fun}), do: record(body, name, fun)
  defp route(%{live: "1", fun: fun}), do: fun.()

  defp route(%{body: body, name: name, fun: fun}),
    do: play(body, name, fun)
end

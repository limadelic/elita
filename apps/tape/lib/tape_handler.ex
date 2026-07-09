defmodule TapeHandler do
  import System, only: [get_env: 1]
  import Keyword, only: [get: 3]
  import Map, only: [put: 3]

  alias Tape.Play
  alias Tape.Record

  def handle(body, name, fun, opts \\ []) do
    ctx(%{body: body, name: name, fun: fun}, opts) |> route()
  end

  defp ctx(basic, opts) do
    put(basic, :on_miss, get(opts, :on_miss, :raise))
    |> put(:tape, get_env("TAPE"))
    |> put(:live, get_env("LIVE"))
  end

  defp route(%{tape: "rec"} = ctx), do: Record.handle(ctx.body, ctx.name, ctx.fun)
  defp route(%{live: "1", fun: fun}), do: fun.()

  defp route(%{body: body, name: name, fun: fun, on_miss: on_miss}),
    do: Play.handle(body, name, fun, on_miss)
end

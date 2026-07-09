defmodule TapeHandler do
  import System, only: [get_env: 1]
  import Keyword, only: [get: 3]

  alias Tape.Play
  alias Tape.Record

  def handle(body, name, fun, opts \\ []) do
    %{body: body, name: name, fun: fun, on_miss: get(opts, :on_miss, :raise),
      tape: get_env("TAPE"), live: get_env("LIVE")}
    |> route()
  end

  defp route(%{tape: "rec"} = ctx), do: Record.handle(ctx.body, ctx.name, ctx.fun)
  defp route(%{live: "1", fun: fun}), do: fun.()

  defp route(%{body: body, name: name, fun: fun, on_miss: on_miss}),
    do: Play.handle(body, name, fun, on_miss)
end

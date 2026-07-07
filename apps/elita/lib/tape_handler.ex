defmodule TapeHandler do
  alias Tape.Record
  alias Tape.Play
  import System, only: [get_env: 1]

  def handle(body, name, fun) do
    route(body, name, fun, get_env("TAPE"), get_env("LIVE"))
  end

  defp route(body, name, fun, "rec", _live), do: Record.handle(body, name, fun)
  defp route(_body, _name, fun, _tape, "1"), do: fun.()
  defp route(body, name, fun, _tape, _live), do: Play.handle(body, name, fun)
end

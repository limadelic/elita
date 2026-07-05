defmodule TapeHandler do
  alias Tape.Record
  alias Tape.Play
  import System, only: [get_env: 1]

  def handle(body, name, fun) do
    handle_mode(body, name, fun, get_env("TAPE"), get_env("LIVE"))
  end

  defp handle_mode(body, name, fun, "rec", _live), do: Record.handle(body, name, fun)
  defp handle_mode(_body, _name, fun, _tape, "1"), do: fun.()
  defp handle_mode(body, name, fun, _tape, _live), do: Play.handle(body, name, fun)
end

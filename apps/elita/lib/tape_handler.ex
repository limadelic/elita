defmodule TapeHandler do
  def handle(body, name, fun) do
    handle_mode(body, name, fun, System.get_env("TAPE"), System.get_env("LIVE"))
  end

  defp handle_mode(body, name, fun, "rec", _live), do: Tape.Record.handle(body, name, fun)
  defp handle_mode(_body, _name, fun, _tape, "1"), do: fun.()
  defp handle_mode(body, name, fun, _tape, _live), do: Tape.Play.handle(body, name, fun)
end

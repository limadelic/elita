defmodule TapeHandler do
  import System, only: [get_env: 1]

  alias Tape.Play
  alias Tape.Record

  def handle(body, name, fun, opts \\ []) do
    on_miss = Keyword.get(opts, :on_miss, :raise)
    route(body, name, fun, on_miss, get_env("TAPE"), get_env("LIVE"))
  end

  defp route(body, name, fun, _on_miss, "rec", _live), do: Record.handle(body, name, fun)
  defp route(_body, _name, fun, _on_miss, _tape, "1"), do: fun.()
  defp route(body, name, fun, on_miss, _tape, _live), do: Play.handle(body, name, fun, on_miss)
end

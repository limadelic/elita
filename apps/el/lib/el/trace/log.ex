defmodule El.Trace.Log do
  @moduledoc false
  import System
  import File
  import El.Trace.Format

  def chunk(data), do: write_maybe(get_env("EL_TRACE"), trace(data))
  def header({rows, cols}, tty_source), do: write_maybe(get_env("EL_TRACE"), "#{monotonic_time(:millisecond)} start rows=#{rows} cols=#{cols} tty_source=#{tty_source}\n")
  def event(msg), do: write_maybe(get_env("EL_TRACE"), "#{monotonic_time(:millisecond)} #{msg}\n")
  def event(msg, reason), do: write_maybe(get_env("EL_TRACE"), "#{monotonic_time(:millisecond)} #{msg} reason=#{reason}\n")

  defp write_maybe(nil, _), do: :ok
  defp write_maybe(path, line), do: write(path, line, [:append])
end

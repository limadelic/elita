defmodule El.Trace.Log do
  @moduledoc false
  import System
  import File
  import El.Trace.Format

  def chunk(data), do: jot(get_env("EL_TRACE"), trace(data))

  def header({rows, cols}, source) do
    jot(get_env("EL_TRACE"), caption(rows, cols, source))
  end

  def event(msg) do
    jot(get_env("EL_TRACE"), stamp(msg))
  end

  def event(msg, reason) do
    jot(get_env("EL_TRACE"), remark(msg, reason))
  end

  defp caption(rows, cols, source) do
    "#{monotonic_time(:millisecond)} start rows=#{rows} cols=#{cols} tty_source=#{source}\n"
  end

  defp stamp(msg) do
    "#{monotonic_time(:millisecond)} #{msg}\n"
  end

  defp remark(msg, reason) do
    "#{monotonic_time(:millisecond)} #{msg} reason=#{reason}\n"
  end

  defp jot(nil, _), do: :ok
  defp jot(path, line), do: write(path, line, [:append])
end

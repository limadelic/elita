defmodule Matrix.Trace.Log do
  @moduledoc false
  import Application
  import System
  import File
  import Matrix.Trace.Format

  def chunk(data), do: jot(get_env(:matrix, :trace), trace(data))

  def header({rows, cols}, source) do
    jot(get_env(:matrix, :trace), caption(rows, cols, source))
  end

  def event(msg) do
    jot(get_env(:matrix, :trace), stamp(msg))
  end

  def event(msg, reason) do
    jot(get_env(:matrix, :trace), remark(msg, reason))
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

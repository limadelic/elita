defmodule El.Trace do
  @moduledoc false
  import El.Trace.Log

  def record(data), do: chunk(data)
  def mark(size, tty_source), do: header(size, tty_source)
  def emit(event), do: event(event)
  def emit(event, reason), do: event(event, reason)
end

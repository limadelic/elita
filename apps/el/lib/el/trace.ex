defmodule El.Trace do
  @moduledoc false
  import El.Trace.Log

  def log_chunk(data), do: chunk(data)
  def log_header(size, tty_source), do: header(size, tty_source)
  def log_event(event), do: event(event)
  def log_event(event, reason), do: event(event, reason)
end

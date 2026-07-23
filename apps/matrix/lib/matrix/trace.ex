defmodule Matrix.Trace do
  @moduledoc false
  import Matrix.Trace.Log

  def record(data), do: chunk(data)
  def mark(size, source), do: header(size, source)
  def emit(event), do: event(event)
  def emit(event, reason), do: event(event, reason)
end

defmodule Matrix.Pty.Gate do
  @moduledoc false
  import Matrix.Trace, only: [record: 1]

  def emit(msg, pty, port) do
    log(msg)
    port.command(pty, msg)
  end

  def log(msg) do
    record(msg)
  end

  def peek(data) when byte_size(data) > 40 do
    <<head::binary-size(40), _::binary>> = data
    inspect(head)
  end

  def peek(data), do: inspect(data)
end

defmodule Matrix.Pty.Gate do
  @moduledoc false
  import Matrix.Trace, only: [record: 1]
  import Matrix.Log, only: [write: 1]

  def emit(msg, pty, port) do
    write("SEND #{byte_size(msg)}b\n")
    log(msg)
    port.command(pty, msg)
  end

  def log(msg) do
    record(msg)
    write("inject: #{byte_size(msg)}b\n")
  end

  def peek(data) when byte_size(data) > 40 do
    <<head::binary-size(40), _::binary>> = data
    inspect(head)
  end

  def peek(data), do: inspect(data)
end

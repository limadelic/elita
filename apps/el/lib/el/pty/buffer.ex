defmodule El.Pty.Buffer do
  @moduledoc false
  import Enum, only: [each: 2]
  import String, only: [contains?: 2]
  import El.Trace, only: [record: 1]
  import El.Log, only: [write: 1]

  def prime(%{ready: true} = s, _) do
    write("PTY DATA SKIP (ready)\n")
    s
  end

  def prime(s, d) do
    write("PTY DATA DETECT #{byte_size(d)}b: #{peek(d)}\n")
    check(s, ready?(d))
  end

  defp check(s, true) do
    write("PTY READY MARKER FOUND flush buffer\n")
    flush(s)
  end

  defp check(s, false) do
    write("PTY READY MARKER NOT FOUND\n")
    s
  end

  def gate(msg, %{ready: true, pty: pty, port: port} = state) do
    write("GATE PASSTHROUGH #{byte_size(msg)}b\n")
    log(msg)
    port.command(pty, msg)
    state
  end

  def gate(msg, %{buffer: buf} = state) do
    write("GATE BUFFER #{byte_size(msg)}b (#{length(buf) + 1} queued)\n")
    %{state | buffer: buf ++ [msg]}
  end

  defp ready?(data) when is_binary(data) do
    contains?(data, "\e[?1049h")
  end

  defp flush(%{buffer: buf, pty: pty, port: port} = state) do
    write("FLUSH START #{length(buf)} buffered\n")
    send(buf, pty, port)
    write("FLUSH DONE ready=true\n")
    %{state | ready: true, buffer: []}
  end

  defp send(buf, pty, port) do
    each(buf, fn msg -> emit(msg, pty, port) end)
  end

  defp emit(msg, pty, port) do
    write("FLUSH SEND #{byte_size(msg)}b\n")
    log(msg)
    port.command(pty, msg)
  end

  defp log(msg) do
    record(msg)
    write("inject: #{byte_size(msg)}b\n")
  end

  defp peek(data) when byte_size(data) > 40 do
    :binary.part(data, 0, 40) |> inspect()
  end

  defp peek(data), do: inspect(data)
end

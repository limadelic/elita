defmodule El.Pty.Buffer do
  @moduledoc false
  import Enum, only: [each: 2]
  import String, only: [contains?: 2]
  import El.Log, only: [write: 1]

  def prime(%{ready: true} = s, _), do: s
  def prime(s, d), do: check(s, ready?(d))

  defp check(s, true), do: flush(s)
  defp check(s, false), do: s

  def gate(msg, %{ready: true, pty: pty, port: port} = state) do
    record(msg)
    port.command(pty, msg)
    state
  end

  def gate(msg, %{buffer: buf} = state) do
    %{state | buffer: buf ++ [msg]}
  end

  defp ready?(data) when is_binary(data) do
    contains?(data, "\e[?1049h")
  end

  defp flush(%{buffer: buf, pty: pty, port: port} = state) do
    each(buf, fn msg -> record(msg); port.command(pty, msg) end)
    %{state | ready: true, buffer: []}
  end

  defp record(msg) do
    write("inject: #{byte_size(msg)}b\n")
  end
end

defmodule El.Pty.Buffer do
  @moduledoc false
  import Enum, only: [each: 2]
  import String, only: [contains?: 2, slice: 2]
  import El.Trace, only: [record: 1]
  import El.Log, only: [write: 1]

  def prime(%{idle: true, pending_msg: nil, buffer: []} = s, d) do
    write("PTY DATA #{byte_size(d)}b: #{peek(d)}\n"); record(d)
    path(s, grow(Map.get(s, :tail), d), nil)
  end

  def prime(%{idle: true} = s, d) do
    write("PTY DATA #{byte_size(d)}b: #{peek(d)}\n"); record(d)
    path(s, grow(Map.get(s, :tail), d), Map.get(s, :pending_msg))
  end

  def prime(s, d) do
    write("PTY DATA #{byte_size(d)}b: #{peek(d)}\n")
    mark(s, d)
  end

  defp mark(%{buffer: [msg | rest]} = s, d) do
    latch(contains?(d, "bypass permissions"), s, msg, rest)
  end

  defp mark(s, d), do: ready(contains?(d, "bypass permissions"), s)

  defp ready(true, s), do: %{s | idle: true}
  defp ready(false, s), do: s

  defp latch(true, s, msg, rest) do
    %{s | idle: true, buffer: rest} |> fire(msg)
  end

  defp latch(false, s, _msg, _rest), do: s

  defp fire(%{pty: pty, port: port} = s, msg) do
    txt = slice(msg, 0..-2//1)
    write("GATE FIRST #{byte_size(msg)}b\n"); port.command(pty, txt); log(txt)
    %{s | pending_msg: txt}
  end

  defp path(s, tail, msg) when is_binary(msg), do: echo(s, tail, contains?(tail, msg))
  defp path(s, tail, nil), do: resend(s, tail)

  defp echo(s, _tail, true), do: submit(s)
  defp echo(s, tail, false), do: resend(s, tail)

  def gate(msg, %{idle: true, pty: pty, port: port} = state) do
    write("GATE PASSTHROUGH #{byte_size(msg)}b\n"); log(msg); port.command(pty, msg)
    state
  end

  def gate(msg, state) do
    buf = Map.get(state, :buffer, [])
    write("GATE BUFFER #{byte_size(msg)}b (#{length(buf) + 1} queued)\n")
    %{state | buffer: buf ++ [msg]}
  end

  defp grow(nil, d), do: cap(d)
  defp grow(tail, d), do: cap(tail <> d)

  defp cap(t) when byte_size(t) > 4096, do: slice(t, -4096..-1)
  defp cap(t), do: t

  defp submit(%{pty: pty, port: port} = s) do
    port.command(pty, "\r"); record("\r"); write("ECHO VERIFIED send \\r\n")
    flush(s)
  end

  defp flush(%{buffer: buf, pty: pty, port: port} = s) do
    write("FLUSH START #{length(buf)} buffered\n")
    each(buf, fn msg -> emit(msg, pty, port) end)
    write("FLUSH DONE\n")
    %{s | idle: true, pending_msg: nil, tail: "", buffer: []}
  end

  defp resend(s, tail) do
    ship(Map.get(s, :pending_msg), s); %{s | tail: tail}
  end

  defp ship(nil, _), do: nil
  defp ship(msg, %{pty: pty, port: port}) do
    write("RESEND #{byte_size(msg)}b (no echo yet)\n"); port.command(pty, msg); record(msg)
  end

  defp emit(msg, pty, port) do
    write("SEND #{byte_size(msg)}b\n"); log(msg); port.command(pty, msg)
  end
  defp log(msg) do
    record(msg); write("inject: #{byte_size(msg)}b\n")
  end

  defp peek(data) when byte_size(data) > 40 do
    <<head::binary-size(40), _::binary>> = data; inspect(head)
  end
  defp peek(data), do: inspect(data)
end

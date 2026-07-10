defmodule El.Wrap.Input do
  @moduledoc false
  import Agent
  import Enum
  import String

  def open(parent) do
    {:ok, pid} = start_link(fn -> {[], parent} end)
    pid
  end

  def encode(buf, chunk) do
    get_and_update(buf, fn {line, parent} ->
      feed(chunk, line, parent)
    end)
  end

  defp feed(<<>>, line, _parent) do
    {"", line}
  end

  defp feed(<<13, rest::binary>>, line, parent) do
    eol(line, rest, parent, "\r")
  end

  defp feed(<<10, rest::binary>>, line, parent) do
    eol(line, rest, parent, "\n")
  end

  defp feed(<<byte, rest::binary>>, line, parent) when byte in [8, 127] do
    chars = backspace(line)
    feed(rest, chars, parent)
  end

  defp feed(<<char::utf8, rest::binary>>, line, parent) do
    feed(rest, line ++ [char], parent)
  end

  defp feed(<<_, rest::binary>>, line, parent) do
    feed(rest, line, parent)
  end

  defp backspace([]), do: []
  defp backspace(line), do: drop(line, -1)

  defp eol(line, rest, parent, eol) do
    check(line, parent)
    {data, new_line} = feed(rest, [], parent)
    {eol <> data, new_line}
  end

  defp check(line, parent) do
    line
    |> join("")
    |> trim()
    |> dispatch(parent)
  end

  def dispatch("/exit", parent) do
    send(parent, :exit_wrap)
  end

  def dispatch(_, _parent) do
    :ok
  end
end

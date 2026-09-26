defmodule Freeq.Lines do
  import String, only: [split: 2, contains?: 2]
  import Enum, only: [each: 2]
  import Freeq.Writer, only: [message: 3, result: 3, line: 2]
  import System, only: [unique_integer: 1]

  def send(socket, channel, text),
    do: emit(contains?(text, "\n"), socket, channel, text)

  def answer(socket, channel, text),
    do: reply(contains?(text, "\n"), socket, channel, text)

  defp emit(false, socket, channel, text), do: message(socket, channel, text)

  defp emit(true, socket, channel, text) do
    ref = tag()
    line(socket, "BATCH +#{ref} draft/multiline #{channel}")
    each(split(text, "\n"), &batch(socket, ref, channel, &1))
    line(socket, "BATCH -#{ref}")
  end

  defp batch(socket, ref, channel, text) do
    line(socket, "@batch=#{ref} PRIVMSG #{channel} :#{text}")
  end

  defp reply(false, socket, channel, text), do: result(socket, channel, text)
  defp reply(true, socket, channel, text), do: emit(true, socket, channel, text)

  defp tag, do: "b#{unique_integer([:positive])}"
end

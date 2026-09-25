defmodule Freeq.Lines do
  import String, only: [split: 2, contains?: 2]
  import Enum, only: [each: 2]
  import Freeq.Writer, only: [message: 3, line: 2]
  import System, only: [unique_integer: 1]

  def send(socket, channel, text) do
    emit(contains?(text, "\n"), socket, channel, text)
  end

  defp emit(false, socket, channel, text) do
    message(socket, channel, text)
  end

  defp emit(true, socket, channel, text) do
    ref = tag()
    line(socket, "BATCH +#{ref} draft/multiline #{channel}")
    batch(socket, channel, ref, text)
    line(socket, "BATCH -#{ref}")
  end

  defp batch(socket, channel, ref, text) do
    msg = fn t -> line(socket, "@batch=#{ref} PRIVMSG #{channel} :#{t}") end
    each(split(text, "\n"), msg)
  end

  defp tag, do: "b#{unique_integer([:positive])}"
end

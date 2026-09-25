defmodule Freeq.Lines do
  import String, only: [split: 2, contains?: 2]
  import Enum, only: [each: 2]
  import Freeq.Writer, only: [message: 3, line: 2]

  def send(socket, channel, text), do: emit(contains?(text, "\n"), socket, channel, text)

  defp emit(false, socket, channel, text), do: message(socket, channel, text)

  defp emit(true, socket, channel, text) do
    ref = tag()
    line(socket, "BATCH +#{ref} draft/multiline #{channel}")
    each(split(text, "\n"), &line(socket, "@batch=#{ref} PRIVMSG #{channel} :#{&1}"))
    line(socket, "BATCH -#{ref}")
  end

  defp tag, do: "b#{System.unique_integer([:positive])}"
end

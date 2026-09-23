defmodule Freeq.Writer do
  def nick(socket, agent) do
    line(socket, "NICK #{agent}")
  end

  def user(socket, agent) do
    line(socket, "USER #{agent} 0 * :#{agent}")
  end

  def join(socket, channel) do
    line(socket, "JOIN #{channel}")
  end

  def cap(socket, cmd) do
    line(socket, "CAP #{cmd}")
  end

  def message(socket, channel, text) do
    if String.contains?(text, "\n") do
      batch(socket, channel, text)
    else
      line(socket, "PRIVMSG #{channel} :#{text}")
    end
  end

  def pong(socket, server) do
    line(socket, "PONG #{server}")
  end

  defp batch(socket, channel, text) do
    id = "b1"
    line(socket, "BATCH +#{id} draft/multiline #{channel}")
    text
    |> String.split("\n", trim: false)
    |> Enum.each(&privmsg_line(socket, channel, id, &1))
    line(socket, "BATCH -#{id}")
  end

  defp privmsg_line(socket, channel, id, body) do
    line(socket, "@batch=#{id} PRIVMSG #{channel} :#{body}")
  end

  defp line(socket, text) do
    :gen_tcp.send(socket, "#{text}\r\n")
  end
end

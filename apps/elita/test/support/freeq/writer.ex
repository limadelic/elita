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
    line(socket, "PRIVMSG #{channel} :#{text}")
  end

  def pong(socket, server) do
    line(socket, "PONG #{server}")
  end

  defp line(socket, text) do
    :gen_tcp.send(socket, "#{text}\r\n")
  end
end

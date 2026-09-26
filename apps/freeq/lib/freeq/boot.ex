defmodule Freeq.Boot do
  import Freeq.Writer, only: [nick: 2, user: 2, join: 2, line: 2, agent: 1]
  import Freeq.Ready, only: [wait: 1]
  import Freeq.Welcome, only: [greet: 1]

  def run(socket, name, channel) do
    caps(socket)
    nick(socket, name)
    user(socket, name)
    register(greet(socket), socket, channel)
  end

  defp register(:ok, socket, channel) do
    agent(socket)
    join(socket, channel)
    wait(socket)
    :ok
  end

  defp register({:error, reason}, _socket, _channel) do
    {:error, reason}
  end

  defp caps(socket) do
    line(socket, "CAP REQ :batch draft/multiline message-tags echo-message")
    line(socket, "CAP END")
  end
end

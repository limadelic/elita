defmodule Freeq.Boot do
  import Freeq.Writer, only: [nick: 2, user: 2, join: 2, line: 2, agent: 1]
  import Freeq.Ready, only: [wait: 1]
  import Freeq.Welcome, only: [greet: 1]
  import Freeq.SASL, only: [login: 2]

  def run(socket, name, channel) do
    setup(socket, name)
    register(greet(socket), socket, channel)
  end

  defp setup(socket, name) do
    caps(socket)
    nick(socket, name)
    user(socket, name)
    login(socket, name)
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
    line(socket, "CAP LS 302")
    line(socket, "CAP REQ :sasl batch draft/multiline message-tags echo-message")
  end
end

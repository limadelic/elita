defmodule Freeq.Boot do
  import Freeq.Writer, only: [nick: 2, user: 2, join: 2, line: 2]
  import Freeq.Ready, only: [wait: 1]
  import Freeq.Welcome, only: [greet: 1]

  def run(socket, agent, channel) do
    register(socket, agent)
    join(socket, channel)
    wait(socket)
  end

  defp register(socket, agent) do
    caps(socket)
    nick(socket, agent)
    user(socket, agent)
    greet(socket)
  end

  defp caps(socket) do
    line(socket, "CAP REQ :batch draft/multiline message-tags echo-message")
    line(socket, "CAP END")
  end
end

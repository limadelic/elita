defmodule Freeq.Boot do
  import Freeq.Writer, only: [nick: 2, user: 2, join: 2, line: 2, agent: 1]
  import Freeq.Ready, only: [wait: 1]
  import Freeq.Welcome, only: [greet: 1]

  def run(socket, name, channel) do
    register(socket, name)
    agent(socket)
    join(socket, channel)
    wait(socket)
  end

  defp register(socket, name) do
    caps(socket)
    nick(socket, name)
    user(socket, name)
    greet(socket)
  end

  defp caps(socket) do
    line(socket, "CAP REQ :batch draft/multiline message-tags extended-join")
    line(socket, "CAP END")
  end
end

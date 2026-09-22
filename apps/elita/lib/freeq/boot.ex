defmodule Elita.Freeq.Boot do
  import Elita.Freeq.Writer, only: [nick: 2, user: 2, join: 2]
  import Elita.Freeq.Ready, only: [wait: 1]
  import Elita.Freeq.Welcome, only: [greet: 1]

  def run(socket, agent, channel) do
    register(socket, agent)
    join(socket, channel)
    wait(socket)
  end

  defp register(socket, agent) do
    nick(socket, agent)
    user(socket, agent)
    greet(socket)
  end
end

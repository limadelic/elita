defmodule Freeq.Boot do
  import Freeq.Writer, only: [nick: 2, user: 2, join: 2, cap: 2]
  import Freeq.Ready, only: [wait: 1]
  import Freeq.Welcome, only: [greet: 1]
  import String, only: [contains?: 2, trim_trailing: 2]

  def run(socket, agent, channel) do
    cap(socket, "REQ batch draft/multiline")
    await_cap(socket)
    cap(socket, "END")
    register(socket, agent)
    join(socket, channel)
    wait(socket)
  end

  defp await_cap(socket) do
    receive do
      {:tcp, ^socket, line} ->
        str = line |> to_string() |> trim_trailing("\r\n")
        if contains?(str, "CAP *"), do: :ok, else: await_cap(socket)
      {:tcp_closed, ^socket} ->
        raise "Socket closed waiting for CAP"
    after
      5000 -> raise "Timeout waiting for CAP"
    end
  end

  defp register(socket, agent) do
    nick(socket, agent)
    user(socket, agent)
    greet(socket)
  end
end

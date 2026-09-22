defmodule Elita.Freeq do
  use GenServer

  import Keyword, only: [fetch!: 2]
  import String, only: [contains?: 2, trim_trailing: 2]
  import GenServer, only: [start_link: 3, call: 2]
  import Elita, only: [request: 2]
  import Elita.Freeq.Parser, only: [parse: 3]

  def start_link(opts) do
    agent = fetch!(opts, :agent)
    channel = fetch!(opts, :channel)
    start_link(__MODULE__, {agent, channel}, [])
  end

  def say(pid, text) do
    call(pid, {:say, text})
  end

  @impl true
  def init({agent, channel}) do
    {:ok, socket} = :gen_tcp.connect(~c"127.0.0.1", 6667, active: true, packet: :line)
    boot(socket, agent, channel)
    {:ok, %{socket: socket, agent: agent, channel: channel}}
  end

  @impl true
  def handle_call({:say, text}, _from, %{socket: socket, channel: channel} = state) do
    :gen_tcp.send(socket, "PRIVMSG #{channel} :#{text}\r\n")
    {:reply, :ok, state}
  end

  @impl true
  def handle_info({:tcp, _socket, line}, state) do
    line |> to_string() |> trim_trailing("\r\n") |> handle(state)
  end

  @impl true
  def handle_info({:tcp_closed, _socket}, state) do
    {:stop, :normal, state}
  end

  defp boot(socket, agent, channel) do
    :gen_tcp.send(socket, "NICK #{agent}\r\n")
    :gen_tcp.send(socket, "USER #{agent} 0 * :#{agent}\r\n")
    :gen_tcp.send(socket, "JOIN #{channel}\r\n")
  end

  defp handle("PING " <> server, %{socket: socket} = state) do
    :gen_tcp.send(socket, "PONG #{server}\r\n")
    {:noreply, state}
  end

  defp handle(":" <> msg, %{agent: agent, channel: channel, socket: socket} = state) do
    privmsg(msg, agent, channel, socket)
    {:noreply, state}
  end

  defp handle(_msg, state) do
    {:noreply, state}
  end

  defp privmsg(msg, agent, channel, socket) do
    privmsg(contains?(msg, "PRIVMSG"), msg, agent, channel, socket)
  end

  defp privmsg(true, msg, agent, channel, socket) do
    parse(msg, agent, channel)
    |> reply(socket, channel, agent)
  end

  defp privmsg(false, _msg, _agent, _channel, _socket) do
    :noop
  end

  defp reply({:ask, sender, text}, socket, channel, agent) do
    msg = "[from #{sender}] #{text}"
    request(agent, msg) |> respond(socket, channel)
  end

  defp reply(:noop, _socket, _channel, _agent), do: :ok

  defp respond({:error, _}, _socket, _channel), do: :noop

  defp respond(answer, socket, channel) do
    :gen_tcp.send(socket, "PRIVMSG #{channel} :#{answer}\r\n")
  end
end

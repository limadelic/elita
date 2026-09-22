defmodule Elita.Freeq do
  use GenServer

  import Keyword, only: [fetch!: 2, get: 3]
  import String, only: [contains?: 2, trim_trailing: 2]
  import GenServer, only: [start_link: 3, call: 2]
  import Elita, only: [request: 2]
  import Elita.Freeq.Parser, only: [parse: 3]
  import Task, only: [start: 1]

  def start_link(opts) do
    agent = fetch!(opts, :agent)
    channel = fetch!(opts, :channel)
    ask = get(opts, :ask, &request/2)
    start_link(__MODULE__, {agent, channel, ask}, [])
  end

  def say(pid, text) do
    call(pid, {:say, text})
  end

  @impl true
  def init({agent, channel, ask}) do
    {:ok, socket} = :gen_tcp.connect(~c"127.0.0.1", 6667, active: true, packet: :line)
    boot(socket, agent, channel)
    {:ok, %{socket: socket, agent: agent, channel: channel, ask: ask}}
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

  @impl true
  def handle_info({:answer, text}, %{socket: socket, channel: channel} = state) do
    :gen_tcp.send(socket, "PRIVMSG #{channel} :#{text}\r\n")
    {:noreply, state}
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

  defp handle(":" <> msg, state) do
    privmsg(msg, state, self())
    {:noreply, state}
  end

  defp handle(_msg, state) do
    {:noreply, state}
  end

  defp privmsg(msg, state, pid) do
    privmsg(contains?(msg, "PRIVMSG"), msg, state, pid)
  end

  defp privmsg(true, msg, %{agent: agent, channel: channel, ask: ask}, pid) do
    parse(msg, agent, channel) |> reply(agent, ask, pid)
  end

  defp privmsg(false, _msg, _state, _pid) do
    :noop
  end

  defp reply({:ask, sender, text}, agent, ask, pid) do
    start(fn ->
      ask.(agent, "[from #{sender}] #{text}") |> relay(pid)
    end)
  end

  defp reply(:noop, _agent, _ask, _pid), do: :ok

  defp relay({:error, _}, _pid), do: :noop
  defp relay(answer, pid), do: send(pid, {:answer, answer})
end

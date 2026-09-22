defmodule Elita.Freeq do
  use GenServer
  import Keyword, only: [fetch!: 2, get: 3]
  import String, only: [trim_trailing: 2]
  import GenServer, only: [start_link: 3, call: 2]
  import Elita, only: [request: 2]

  import Elita.Freeq.Writer,
    only: [nick: 2, user: 2, join: 2, message: 3, pong: 2]

  import Elita.Freeq.Answer, only: [privmsg: 3]

  def start_link(opts) do
    agent = fetch!(opts, :agent)
    channel = fetch!(opts, :channel)
    ask = get(opts, :ask, &request/2)
    start_link(__MODULE__, {agent, channel, ask}, [])
  end

  def say(pid, text) do
    call(pid, {:say, text})
  end

  def tell(pid, nick, text) do
    call(pid, {:tell, nick, text})
  end

  @impl true
  def init({agent, channel, ask}) do
    {:ok, socket} = :gen_tcp.connect(~c"127.0.0.1", 6667, active: true, packet: :line)
    boot(socket, agent, channel)
    {:ok, %{socket: socket, agent: agent, channel: channel, ask: ask}}
  end

  @impl true
  def handle_call({:say, text}, _from, %{socket: socket, channel: channel} = state) do
    message(socket, channel, text)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:tell, nick, text}, _from, %{socket: socket, channel: channel} = state) do
    message(socket, channel, "#{nick}: #{text}")
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
    message(socket, channel, text)
    {:noreply, state}
  end

  defp boot(socket, agent, channel) do
    nick(socket, agent)
    user(socket, agent)
    join(socket, channel)
  end

  defp handle("PING " <> server, %{socket: socket} = state) do
    pong(socket, server)
    {:noreply, state}
  end

  defp handle(":" <> msg, state) do
    privmsg(msg, state, self())
    {:noreply, state}
  end

  defp handle(_msg, state) do
    {:noreply, state}
  end
end

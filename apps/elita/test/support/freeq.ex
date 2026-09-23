defmodule Freeq do
  use GenServer
  import Keyword, only: [fetch!: 2, get: 3]
  import String, only: [trim_trailing: 2]
  import GenServer, only: [start_link: 3, call: 2]
  import Elita, only: [request: 2]
  import Process, only: [flag: 2]

  import Freeq.Writer, only: [message: 3]
  import Freeq.Lines, only: [send: 3]
  import Freeq.Inbox, only: [route: 2]
  import Freeq.Batch, only: [absorb: 1]
  import Freeq.Boot, only: [run: 3]

  def start_link(opts) do
    start_link(__MODULE__, tuple(opts), [])
  end

  defp tuple(opts) do
    {fetch!(opts, :agent), fetch!(opts, :channel), get(opts, :ask, &request/2),
     get(opts, :driver, nil)}
  end

  def say(pid, text) do
    call(pid, {:say, text})
  end

  def tell(pid, nick, text) do
    call(pid, {:tell, nick, text})
  end

  @impl true
  def init({agent, channel, ask, driver}) do
    {:ok, socket} = :gen_tcp.connect(~c"127.0.0.1", 6667, active: true, packet: :line)
    flag(:trap_exit, true)
    run(socket, agent, channel)
    {:ok, state(socket, agent, channel, ask, driver)}
  end

  defp state(socket, agent, channel, ask, driver) do
    name = "freeq_#{agent}" |> String.to_atom()
    Process.register(self(), name)
    %{socket: socket, agent: agent, channel: channel, ask: ask, driver: driver}
  end

  @impl true
  def handle_call({:say, text}, _from, %{socket: socket, channel: channel} = state) do
    message(socket, channel, text)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:tell, nick, text}, _from, %{socket: socket, channel: channel} = state) do
    send(socket, channel, "#{nick}: #{text}")
    {:reply, :ok, state}
  end

  @impl true
  def handle_info({:tcp, _socket, line}, state) do
    line |> to_string() |> trim_trailing("\r\n") |> List.wrap() |> absorb() |> route(state)
  end

  @impl true
  def handle_info({:tcp_closed, _socket}, state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_info({:EXIT, _pid, _reason}, state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_info({:answer, text}, %{socket: socket, channel: channel} = state) do
    send(socket, channel, text)
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, %{socket: socket}) do
    :gen_tcp.send(socket, "QUIT\r\n")
    :gen_tcp.close(socket)
  rescue
    _ -> :ok
  end
end

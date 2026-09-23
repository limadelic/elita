defmodule Freeq do
  use GenServer
  import Keyword, only: [fetch!: 2, get: 3]
  import String, only: [trim_trailing: 2]
  import GenServer, only: [start_link: 3, call: 2]
  import Elita, only: [request: 2]
  import Process, only: [flag: 2]

  import Freeq.Writer, only: [message: 3, pong: 2]

  import Freeq.Answer, only: [privmsg: 3]
  import Freeq.Lines, only: [send: 3]
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
    %{socket: socket, agent: agent, channel: channel, ask: ask, driver: driver, batches: %{}}
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
    str = line |> to_string() |> trim_trailing("\r\n")
    process(str, state)
  end
  @impl true
  def handle_info({:tcp_closed, _socket}, state), do: {:stop, :normal, state}
  @impl true
  def handle_info({:EXIT, _pid, _reason}, state), do: {:stop, :normal, state}
  @impl true
  def handle_info({:answer, text}, %{socket: socket, channel: channel} = state) do
    send(socket, channel, text)
    {:noreply, state}
  end

  defp process(str, state) do
    case Freeq.Inbound.route(str, state, &handle/2) do
      {:continue, msg, st} -> handle(msg, st)
      result -> result
    end
  end
  defp handle("PING " <> server, %{socket: socket} = state) do
    pong(socket, server)
    {:noreply, state}
  end
  defp handle(":" <> msg, state) do
    privmsg(msg, state, self())
    {:noreply, state}
  end
  defp handle(_msg, state), do: {:noreply, state}

  @impl true
  def terminate(_reason, %{socket: socket}) do
    :gen_tcp.send(socket, "QUIT\r\n")
    :gen_tcp.close(socket)
  rescue
    _ -> :ok
  end
end


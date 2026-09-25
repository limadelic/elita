defmodule Freeq do
  use GenServer, restart: :temporary
  import Keyword, only: [fetch!: 2, get: 3]
  import String, only: [trim_trailing: 2, to_atom: 1]
  import GenServer, only: [start_link: 3, call: 2]
  import Elita, only: [request: 2]
  import Process, only: [flag: 2, register: 2]
  import List, only: [wrap: 1]

  import Freeq.Lines, only: [send: 3]
  import Freeq.Pending, only: [push: 2]
  import Freeq.Inbox, only: [route: 2]
  import Freeq.Batch, only: [absorb: 1]
  import Freeq.Boot, only: [run: 3]

  def start_link(opts), do: start_link(__MODULE__, tuple(opts), [])

  defp tuple(opts) do
    {fetch!(opts, :agent), fetch!(opts, :channel), get(opts, :ask, &request/2),
     fetch!(opts, :host), fetch!(opts, :port), get(opts, :config, [])}
  end

  def tell(pid, nick, text), do: call(pid, {:tell, nick, text})

  @impl true
  def init({agent, channel, ask, host, port, config}) do
    {:ok, socket} = socket(host, port)
    flag(:trap_exit, true)
    ready(run(socket, agent, channel),
          {socket, agent, channel, ask, config})
  end

  defp ready(:ok, {socket, agent, channel, ask, config}) do
    {:ok, setup(socket, agent, channel, ask, config)}
  end
  defp ready({:error, reason}, _) do
    {:stop, reason}
  end

  defp socket(host, port) do
    :gen_tcp.connect(host, port, active: true, packet: :line)
  end

  defp setup(socket, agent, channel, ask, config) do
    register(self(), "freeq_#{agent}" |> to_atom())
    %{socket: socket, agent: agent, channel: channel, ask: ask,
      pending: [], attempts: 0, config: config}
  end

  @impl true
  def handle_call({:tell, nick, text}, _from, %{socket: socket, channel: channel} = state) do
    text = "#{nick}: #{text}"
    send(socket, channel, text)
    {:reply, :ok, push(state, text)}
  end

  @impl true
  def handle_info({:tcp, _socket, line}, state), do: recv(line, state)

  @impl true
  def handle_info({:tcp_closed, _socket}, state), do: {:stop, :normal, state}

  @impl true
  def handle_info({:EXIT, _pid, _reason}, state), do: {:stop, :normal, state}

  @impl true
  def handle_info({:answer, text, sender}, %{socket: socket, channel: channel} = state) do
    text = "@#{sender} #{text}"
    send(socket, channel, text)
    {:noreply, push(state, text)}
  end

  @impl true
  def handle_info({:error_answer, sender}, %{socket: socket, channel: channel} = state) do
    text = "@#{sender} could not answer"
    send(socket, channel, text)
    {:noreply, push(state, text)}
  end

  @impl true
  def handle_info({:retry, text}, %{socket: socket, channel: channel} = state) do
    send(socket, channel, text)
    {:noreply, state}
  end

  defp recv(line, state) do
    clean(line) |> absorb() |> process(state)
  end

  defp clean(line), do: line |> to_string() |> trim_trailing("\r\n") |> wrap()

  defp process(lines, state), do: route(lines, state)

  @impl true
  def terminate(_reason, %{socket: socket}) do
    :gen_tcp.send(socket, "QUIT\r\n")
    :gen_tcp.close(socket)
  rescue
    _ -> :ok
  end
end

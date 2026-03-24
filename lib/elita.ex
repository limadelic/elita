defmodule Elita do
  use GenServer

  import Cfgs, only: [config: 1]
  import Lite, only: [llm: 1]
  import Mem, only: [create: 0]
  import Tools
  import History, only: [record: 1]
  import Msg, only: [user: 1]
  import Log, only: [log: 5]
  import String, only: [downcase: 1, trim: 1]
  import Enum, only: [each: 2]

  def child_spec({name, configs}) do
    %{
      id: {__MODULE__, name},
      start: {__MODULE__, :start_link, [name, configs]},
      restart: :transient
    }
  end

  def start(name, configs) do
    DynamicSupervisor.start_child(Elita.AgentSupervisor, {__MODULE__, {name, configs}})
  end

  def start_link(name, configs) do
    GenServer.start_link(__MODULE__, {name, configs}, name: via(name))
  end

  def cast(name, msg) do
    GenServer.cast(via(name), {:act, msg})
  end

  def call(name, msg) do
    GenServer.call(via(name), {:act, msg}, :infinity)
  end

  defp via(name) do
    {:via, Registry, {ElitaRegistry, downcase(name)}}
  end

  def init({name, configs}) do
    create()
    {:ok, %{name: name, config: config(configs), history: []}}
  end

  def handle_call({:act, msg}, _, state) do
    act(msg, state)
  end

  def handle_cast({:act, msg}, state) do
    {_, _, state} = act(msg, state)
    {:noreply, state}
  end

  defp act(msg, %{history: history} = state) do
    history = [user(msg) | history]
    act(%{state | history: history})
  end

  defp act(state) do
    state
    |> llm
    |> exec
    |> record
    |> done
  end

  defp done({:act, state}) do
    act(state)
  end

  defp done({:reply, txt, %{name: name} = state}) do
    txt = trim(txt)
    log("✨", name, ": ", txt, :white)
    {:reply, txt, state}
  end

  def terminate(_reason, %{ephemeral: agents}) do
    each(agents, &reap/1)
  end

  def terminate(_, _), do: :ok

  defp reap(name) do
    :ets.delete(:elita_agents, {:agent, name})
    :ets.delete(:elita_agents, name)
    GenServer.stop(via(name))
  rescue
    _ -> :ok
  end
end

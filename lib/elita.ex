defmodule Elita do
  use GenServer

  import Cfg, only: [config: 1]
  import Prompt, only: [prompt: 2]
  import Llm, only: [llm: 1]
  import Mem, only: [create: 0]
  import Tools, only: [exec: 1]
  import History, only: [record: 2]
  import Msg, only: [user: 1]

  def start_link(agent, name) do
    GenServer.start_link(__MODULE__, agent, name: via(name))
  end

  def cast(name, msg) do
    GenServer.cast(via(name), {:act, msg})
  end

  def call(name, msg) do
    GenServer.call(via(name), {:act, msg}, :infinity)
  end
  
  defp via(name) do
    {:via, Registry, {ElitaRegistry, name}}
  end

  def init(name) do
    create()
    {:ok, %{config: config(name), history: []}}
  end

  def handle_call({:act, msg}, _, state) do
    act(msg, state)
  end

  def handle_cast({:act, msg}, state) do
    {_, _, state} = act(msg, state)
    {:noreply, state}
  end

  defp act(msg, %{history: history} = state) do
    history = history ++ [user(msg)]
    act(%{state | history: history})
  end

  defp act(%{config: config, history: history} = state) do
    prompt(config, history)
    |> llm
    |> exec()
    |> record(state)
    |> done
  end

  defp done({:act, state}) do
    act(state)
  end

  defp done({:reply, txt, state}) do
    {:reply, txt, state}
  end
end

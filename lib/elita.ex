defmodule Elita do
  use GenServer

  import Cfg, only: [config: 1]
  import Prompt, only: [prompt: 2]
  import Llm, only: [llm: 1]
  import Mem, only: [create: 1]
  import Tools, only: [exec: 2]
  import History, only: [record: 2]
  import Msg, only: [user: 1]

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: {:global, name})
  end

  def chat(msg, pid) do
    GenServer.call(pid, {:act, msg})
  end

  def init(name) do
    create(name)
    {:ok, %{name: name, config: config(name), history: []}}
  end

  def handle_call({:act, msg}, _, state) do
    act(msg, state)
  end

  defp act(msg, %{history: history} = state) do
    history = history ++ [user(msg)]
    act(%{state | history: history})
  end

  defp act(%{config: config, history: history, name: name} = state) do
    prompt(config, history)
    |> llm
    |> exec(name)
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

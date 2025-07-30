defmodule Elita do
  use GenServer

  import AgentConfig, only: [config: 1]
  import Prompt, only: [prompt: 2]
  import Llm, only: [llm: 1]
  import Mem, only: [create: 1]
  import Resp, only: [resp: 1]
  import Tools, only: [exec: 2]
  import Msg, only: [user: 1, model: 1, function: 1]

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: {:global, name})
  end

  def act(msg, pid) do
    GenServer.call(pid, {:act, msg})
  end

  def init(name) do
    create(name)
    {:ok, %{name: name, config: config(name), history: []}}
  end

  def handle_call({:act, msg}, _from, state) do
    action(user(msg), state)
  end

  defp action(msg, %{config: config, history: history} = state) do
    history = history ++ [msg]

    config
    |> prompt(history)
    |> llm
    |> resp
    |> action(history, state)
  end

  defp action({:text, text}, history, state) do
    history = history ++ [model(text)]
    {:reply, text, %{state | history: history}}
  end

  defp action({:function_call, call}, _, state) do
    result = exec(call, state.name)
    action(function(result), state)
  end

  defp action({:error, error}, history, state) do
    {:reply, error, %{state | history: history}}
  end
end

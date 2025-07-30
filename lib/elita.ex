defmodule Elita do
  use GenServer

  import AgentConfig, only: [config: 1]
  import Prompt, only: [prompt: 2]
  import Llm, only: [llm: 1]
  import Mem, only: [create: 1]
  import Resp, only: [resp: 1]
  import Tools, only: [exec: 2]

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

  def handle_call({:act, msg}, _from, %{config: config, history: history} = state) do
    history = history ++ [%{role: "user", parts: [%{text: msg}]}]

    resp = config
    |> prompt(history)
    |> llm
    |> resp
    
    exec(resp, history, state)
  end

  defp exec({:text, text}, history, state) do
    history = history ++ [%{role: "model", parts: [%{text: text}]}]
    {:reply, text, %{state | history: history}}
  end

  defp exec({:function_call, call}, history, state) do
    result = exec(call, state.name)
    history = history ++ [%{role: "function", parts: [%{text: result}]}]
    
    handle_call({:act, ""}, nil, %{state | history: history})
  end

  defp exec({:error, error}, history, state) do
    {:reply, error, %{state | history: history}}
  end
end

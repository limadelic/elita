defmodule Elita do
  use GenServer

  import AgentConfig, only: [config: 1]
  import Prompt, only: [prompt: 2]
  import Llm, only: [llm: 1]
  import Mem, only: [create: 1]
  import Resp, only: [parse: 1]

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

    prompt_data = prompt(config, history)
    IO.inspect(prompt_data, label: "PROMPT TO VERTEX")
    
    resp = llm(prompt_data) |> parse()
    IO.inspect(resp, label: "VERTEX RESPONSE")

    case resp do
      {:text, text} ->
        history = history ++ [%{role: "model", parts: [%{text: text}]}]
        {:reply, text, %{state | history: history}}
      {:function_call, _call} ->
        {:reply, "function call received", %{state | history: history}}
      {:error, error} ->
        {:reply, error, %{state | history: history}}
    end
  end
end

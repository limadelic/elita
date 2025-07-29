defmodule Elita do
  use GenServer
  
  import AgentConfig, only: [config: 1]
  import Prompt, only: [prompt: 2]
  import Llm, only: [llm: 1]

  def start_link name do
    GenServer.start_link __MODULE__, name, name: {:global, name}
  end

  def act msg, pid do
    GenServer.call pid, {:act, msg}
  end

  def init name do
    {:ok, %{name: name, config: config(name), history: []}}
  end

  def handle_call {:act, msg}, _from, %{config: config, history: history} = state do
    history = [msg | history]

    resp = llm prompt config, history
    
    {:reply, resp, %{state | history: [resp | history]}}
  end

end
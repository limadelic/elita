defmodule Elita.Agent do
  use GenServer
  alias Elita.{Manager, Prompt, Pat, Tools}
  import Prompt, only: [prompt: 2]
  import Pat, only: [say: 1]

  def act(name, context) do
    agent_pid = Manager.find_or_spawn(name)
    GenServer.call(agent_pid, {:act, context}, 35_000)
  end

  def start_link({name, config}) do
    GenServer.start_link(__MODULE__, {name, config}, name: {:via, Registry, {Elita.AgentRegistry, name}})
  end

  @impl true
  def init({name, config}) do
    {:ok, %{name: name, config: config, memory: %{}}}
  end

  @impl true
  def handle_call({:act, context}, _from, state) do
    {response, new_state} = state.config
    |> prompt(context)
    |> say()
    |> Tools.process(state)

    {:reply, response, new_state}
  end


end
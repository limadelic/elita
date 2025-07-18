defmodule Elita.Agent do
  use GenServer
  alias Elita.{Manager, Prompt, Pat, Tools, Convo}
  import Prompt, only: [prompt: 2]
  import Pat, only: [say: 1]

  def act(name, context) do
    agent_pid = Manager.ensure(name)
    GenServer.call(agent_pid, {:act, context}, 35_000)
  end

  def start_link({name, config}) do
    GenServer.start_link(__MODULE__, {name, config},
      name: {:via, Registry, {Elita.AgentRegistry, name}}
    )
  end

  @impl true
  def init({name, config}) do
    {:ok, %{name: name, config: config, memory: %{}, convo: Convo.new(), caller: nil}}
  end

  @impl true
  def handle_call({:act, context}, from, state) do
    convo = Convo.msg(state.convo, %{role: "user", content: context})

    send(self(), :act)
    {:noreply, %{state | convo: convo, caller: from}}
  end

  @impl true
  def handle_info(:act, %{convo: convo, config: config} = state) do
    msg = Convo.prompt(convo)

    reply =
      config
      |> prompt(msg)
      |> say()

    llm(reply, state)
  end

  defp llm({:ok, reply}, state) do
    convo = Convo.msg(state.convo, %{role: "agent", content: reply})

    tools(Tools.process({:ok, reply}, %{state | convo: convo}))
  end

  defp llm(error, state) do
    GenServer.reply(state.caller, error)
    {:noreply, %{state | caller: nil}}
  end

  defp tools({:continue, state}) do
    send(self(), :act)
    {:noreply, state}
  end

  defp tools({:done, reply, state}) do
    GenServer.reply(state.caller, {:ok, reply})
    {:noreply, %{state | caller: nil}}
  end

  defp tools({:error, error, state}) do
    GenServer.reply(state.caller, error)
    {:noreply, %{state | caller: nil}}
  end
end

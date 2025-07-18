defmodule Elita.Agent do
  use GenServer
  alias Elita.{Manager, Prompt, Pat, Tools, Convo}
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
    {:ok, %{name: name, config: config, memory: %{}, convo: Convo.new(), caller: nil}}
  end

  @impl true
  def handle_call({:act, context}, from, state) do
    user_msg = %{role: "user", content: context}
    updated_convo = Convo.add_msg(state.convo, user_msg)
    updated_state = %{state | convo: updated_convo, caller: from}
    send(self(), :execute_convo)
    {:noreply, updated_state}
  end

  @impl true
  def handle_info(:execute_convo, state) do
    prompt_text = Convo.build_prompt(state.convo)
    llm_reply = state.config |> prompt(prompt_text) |> say()
    handle_llm_reply(llm_reply, state)
  end

  defp handle_llm_reply({:ok, reply}, state) do
    assistant_msg = %{role: "assistant", content: reply}
    updated_convo = Convo.add_msg(state.convo, assistant_msg)
    updated_state = %{state | convo: updated_convo}
    
    handle_tool_result(Tools.process({:ok, reply}, updated_state))
  end

  defp handle_llm_reply(error, state) do
    GenServer.reply(state.caller, error)
    {:noreply, %{state | caller: nil}}
  end

  defp handle_tool_result({:continue_convo, updated_state}) do
    send(self(), :execute_convo)
    {:noreply, updated_state}
  end

  defp handle_tool_result({:final_reply, reply, final_state}) do
    GenServer.reply(final_state.caller, {:ok, reply})
    {:noreply, %{final_state | caller: nil}}
  end

  defp handle_tool_result({:error, error, state}) do
    GenServer.reply(state.caller, error)
    {:noreply, %{state | caller: nil}}
  end

end
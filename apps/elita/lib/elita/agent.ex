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
    {:ok, %{name: name, config: config, memory: %{}, conversation: Convo.new(), caller: nil}}
  end

  @impl true
  def handle_call({:act, context}, from, state) do
    user_message = %{role: "user", content: context}
    updated_conversation = Convo.add_message(state.conversation, user_message)
    updated_state = %{state | conversation: updated_conversation, caller: from}
    send(self(), :execute_conversation)
    {:noreply, updated_state}
  end

  @impl true
  def handle_info(:execute_conversation, state) do
    prompt_text = Convo.build_prompt(state.conversation)
    llm_response = state.config |> prompt(prompt_text) |> say()
    handle_llm_response(llm_response, state)
  end

  defp handle_llm_response({:ok, response}, state) do
    assistant_message = %{role: "assistant", content: response}
    updated_conversation = Convo.add_message(state.conversation, assistant_message)
    updated_state = %{state | conversation: updated_conversation}
    
    handle_tools_result(Tools.process({:ok, response}, updated_state))
  end

  defp handle_llm_response(error, state) do
    GenServer.reply(state.caller, error)
    {:noreply, %{state | caller: nil}}
  end

  defp handle_tools_result({:continue_conversation, updated_state}) do
    send(self(), :execute_conversation)
    {:noreply, updated_state}
  end

  defp handle_tools_result({:final_response, response, final_state}) do
    GenServer.reply(final_state.caller, {:ok, response})
    {:noreply, %{final_state | caller: nil}}
  end

  defp handle_tools_result({:error, error, state}) do
    GenServer.reply(state.caller, error)
    {:noreply, %{state | caller: nil}}
  end

end
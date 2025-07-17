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
    {:ok, %{name: name, config: config, memory: %{}, conversation: []}}
  end

  @impl true
  def handle_call({:act, context}, _from, state) do
    user_message = %{role: "user", content: context}
    updated_state = add_message(state, user_message)
    {result, final_state} = execute_conversation(updated_state)
    {:reply, result, final_state}
  end

  defp execute_conversation(state) do
    llm_response = state.config |> prompt(build_prompt(state)) |> say()
    handle_llm_response(llm_response, state)
  end

  defp handle_llm_response({:ok, response}, state) do
    assistant_message = %{role: "assistant", content: response}
    updated_state = add_message(state, assistant_message)
    
    handle_tools_response(Tools.process({:ok, response}, updated_state))
  end

  defp handle_llm_response(error, state), do: {error, state}

  defp handle_tools_response({:tools_executed, tool_results, new_state}) do
    tool_message = %{role: "tool", content: Enum.join(tool_results, "; ")}
    tool_state = add_message(new_state, tool_message)
    execute_conversation(tool_state)
  end

  defp handle_tools_response({{:ok, final_response}, final_state}) do
    {{:ok, final_response}, final_state}
  end

  defp add_message(state, message) do
    %{state | conversation: [message | state.conversation]}
  end

  defp build_prompt(state) do
    state.conversation
    |> Enum.reverse()
    |> Enum.map(&format_message/1)
    |> Enum.join("\n\n")
  end

  defp format_message(%{role: role, content: content}) when is_binary(content) do
    "#{role}: #{content}"
  end

  defp format_message(%{role: role, content: content}) do
    "#{role}: #{Jason.encode!(content)}"
  end


end
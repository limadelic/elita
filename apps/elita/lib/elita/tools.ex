defmodule Elita.Tools do
  alias Elita.Convo

  def process({:ok, reply}, state) do
    if has_tool_calls?(reply) do
      {results, state} = execute_tools(reply, state)
      msg = %{role: "tool", content: Enum.join(results, "; ")}
      convo = Convo.msg(state.convo, msg)
      state = %{state | convo: convo}
      {:continue, state}
    else
      {:done, reply, state}
    end
  end

  def process(error, state), do: {:error, error, state}

  defp has_tool_calls?(reply) do
    String.contains?(reply, "<function_calls>")
  end

  defp execute_tools(reply, state) do
    tools = extract_tool_calls(reply)
    {results, state} = Enum.reduce(tools, {[], state}, fn tool, {acc_results, acc_state} ->
      {result, state} = execute_tool(tool, acc_state)
      {[result | acc_results], state}
    end)
    
    results = Enum.reverse(results)
    {results, state}
  end

  defp extract_tool_calls(reply) do
    reply
    |> String.split("<invoke name=\"")
    |> Enum.drop(1)
    |> Enum.map(&parse_tool_call/1)
    |> Enum.filter(& &1)
  end

  defp parse_tool_call(invoke_block) do
    with [tool_name | rest] <- String.split(invoke_block, "\">", parts: 2),
         [params_block | _] <- rest,
         parameters <- extract_parameters(params_block) do
      {tool_name, parameters}
    else
      _ -> nil
    end
  end

  defp extract_parameters(params_block) do
    params_block
    |> String.split("<parameter name=\"")
    |> Enum.drop(1)
    |> Enum.map(&parse_parameter/1)
    |> Enum.into(%{})
  end

  defp parse_parameter(param_block) do
    with [param_name | rest] <- String.split(param_block, "\">", parts: 2),
         [value_block | _] <- rest,
         [value | _] <- String.split(value_block, "</parameter>") do
      {param_name, String.trim(value)}
    else
      _ -> {"", ""}
    end
  end

  defp execute_tool({"set", %{"field" => field, "value" => value}}, state) do
    memory = Map.put(state.memory, field, value)
    state = %{state | memory: memory}
    {"stored #{field}", state}
  end

  defp execute_tool({"say", %{"message" => message}}, state) do
    {"broadcasted: #{message}", state}
  end

  defp execute_tool({tool_name, _params}, state) do
    {"unknown tool: #{tool_name}", state}
  end
end
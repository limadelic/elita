defmodule ToolExecutor do
  def execute(function_call, agent_name) do
    execute_tool_call(function_call, agent_name)
  end

  defp execute_tool_call(%{"name" => "set", "args" => args}, agent_name) do
    SetTool.exec(args, agent_name)
  end

  defp execute_tool_call(%{"name" => "get", "args" => args}, agent_name) do
    GetTool.exec(args, agent_name)
  end
end
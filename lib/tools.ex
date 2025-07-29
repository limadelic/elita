defmodule Tools do
  
  def memory_tools do
    [
      %{
        function_declarations: [
          %{
            name: "set",
            description: "Store data with a key",
            parameters: %{
              type: "object",
              properties: %{
                key: %{type: "string", description: "The key to store data under"},
                value: %{type: "string", description: "The value to store"}
              },
              required: ["key", "value"]
            }
          },
          %{
            name: "get",
            description: "Retrieve data by key",
            parameters: %{
              type: "object", 
              properties: %{
                key: %{type: "string", description: "The key to retrieve data for"}
              },
              required: ["key"]
            }
          }
        ]
      }
    ]
  end

  def execute(function_call, agent_name) do
    execute_tool_call(function_call, agent_name)
  end

  defp execute_tool_call(%{"name" => "set", "args" => %{"key" => key, "value" => value}}, agent_name) do
    table = table_name(agent_name)
    :ets.insert(table, {key, value})
    %{"key" => key, "result" => "stored"}
  end

  defp execute_tool_call(%{"name" => "get", "args" => %{"key" => key}}, agent_name) do
    table = table_name(agent_name)
    case :ets.lookup(table, key) do
      [{^key, value}] -> %{"key" => key, "result" => value}
      [] -> %{"key" => key, "result" => "not found"}
    end
  end

  defp table_name(agent_name) do
    :"memory_#{agent_name}"
  end

end
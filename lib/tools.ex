defmodule Tools do
  import String, only: [split: 2, trim: 1]
  import Enum, only: [map: 2, reject: 2]

  def create_memory(name) do
    :ets.new(table(name), [:set, :public, :named_table])
  end

  def table(name) do
    :"memory_#{name}"
  end

  def tools(%{tools: all}) do
      split(all, ",")
      |> map(&trim/1)
      |> map(&tool/1)
      |> reject(&is_nil/1)
      |> wrap
  end
  def tools(_), do: []

  defp wrap([]), do: []
  defp wrap(tools), do: [%{function_declarations: tools}]

  defp tool("set") do
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
    }
  end

  defp tool("get") do
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
  end

  defp tool(_), do: nil

  def execute(function_call, agent_name) do
    execute_tool_call(function_call, agent_name)
  end

  defp execute_tool_call(
         %{"name" => "set", "args" => %{"key" => key, "value" => value}},
         agent_name
       ) do
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
    table(agent_name)
  end
end

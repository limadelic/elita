defmodule GetTool do
  @void false

  def def do
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

  def exec(agent_name, %{"key" => key}) do
    table = Mem.table(agent_name)

    case :ets.lookup(table, key) do
      [{^key, value}] -> %{"key" => key, "result" => value}
      [] -> %{"key" => key, "result" => "not found"}
    end
  end
end
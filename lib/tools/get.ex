defmodule GetTool do
  def void?, do: false

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

  def exec(agent, %{"key" => key}) do
    table = Mem.table(agent)

    case :ets.lookup(table, key) do
      [{^key, value}] -> value
      [] -> "not found"
    end
  end
end

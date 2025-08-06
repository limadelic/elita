defmodule SetTool do
  def void?, do: true

  def def do
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

  def exec(%{"key" => key, "value" => value}) do
    table = Mem.table()
    :ets.insert(table, {key, value})
    "stored"
  end
end

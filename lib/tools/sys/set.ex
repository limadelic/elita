defmodule Tools.Sys.Set do

  def def(name) do
    %{
      name: name,
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

  def exec(_, %{"key" => key, "value" => value}, _state) do
    table = Mem.table()
    :ets.insert(table, {key, value})
    "stored"
  end
end
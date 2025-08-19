defmodule Tools.Sys.Get do

  def def(name) do
    %{
      name: name,
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

  def exec(_, %{"key" => key}, _state) do
    table = Mem.table()

    case :ets.lookup(table, key) do
      [{^key, value}] -> value
      [] -> "not found"
    end
  end
end

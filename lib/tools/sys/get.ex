defmodule Tools.Sys.Get do
  import Log, only: [log: 5]


  def def(name, _state) do
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

  def exec(_, %{"key" => key}, state) do
    table = Mem.table()
    value = case :ets.lookup(table, key) do
      [{^key, value}] -> value
      [] -> "not found"
    end
    log("👀", key, ": ", value, :blue)
    {value, state}
  end
end

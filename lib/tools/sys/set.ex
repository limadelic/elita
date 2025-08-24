defmodule Tools.Sys.Set do
  import Log, only: [log: 5]

  def def(name, _state) do
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

  def exec(_, %{"key" => key, "value" => value}, state) do
    log("✏️", key, " = ", value, :blue)
    Mem.table() |> :ets.insert({key, value})
    {"stored", state}
  end
end

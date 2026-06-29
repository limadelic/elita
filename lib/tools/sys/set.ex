defmodule Tools.Sys.Set do
  import Log, only: [log: 5]

  def def(name, _state), do: spec(name)

  def exec(tool, %{"value" => value} = args, state) when not is_map_key(args, "key") do
    exec(tool, Map.put(args, "key", value), state)
  end

  def exec(_, %{"key" => key, "value" => value}, state) do
    log("✏️", key, " = ", value, :blue)
    store(key, value)
    {"stored", state}
  end

  defp spec(name) do
    %{name: name, description: "Store data with a key", parameters: parameters()}
  end

  defp parameters do
    %{type: "object", properties: props(), required: ["key", "value"]}
  end

  defp props do
    %{
      key: %{type: "string", description: "The key to store data under"},
      value: %{type: "string", description: "The value to store"}
    }
  end

  defp store(key, value) do
    Mem.table() |> :ets.insert({key, value})
  end
end

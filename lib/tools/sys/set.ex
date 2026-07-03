defmodule Tools.Sys.Set do
  import Log, only: [log: 5]
  import Mem, only: [depth_table: 0, table: 0]

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

  def exec(tool, %{"value" => value} = args, state) when not is_map_key(args, "key") do
    exec(tool, Map.put(args, "key", value), state)
  end

  def exec(_, %{"key" => key, "value" => value}, state) do
    log("✏️", key, " = ", value, :blue)
    store(key, value)
    {"stored", state}
  end

  def exec(_, _args, state) do
    {"set needs key and value", state}
  end

  defp store(key, value) do
    key |> pick() |> :ets.insert({key, value})
  end

  defp pick("depth_" <> _), do: depth_table()
  defp pick("tree_" <> _), do: depth_table()
  defp pick(_), do: table()
end

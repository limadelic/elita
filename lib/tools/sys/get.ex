defmodule Tools.Sys.Get do
  import Log, only: [log: 5]
  import Mem, only: [depth_table: 0, table: 0]

  def def(name, _state) do
    %{
      name: name,
      description: "Retrieve data by key",
      parameters: %{
        type: "object",
        properties: %{key: %{type: "string", description: "The key to retrieve data for"}},
        required: ["key"]
      }
    }
  end

  def exec(_, %{"key" => key}, state) do
    value = fetch(key)
    log("👀", key, ": ", value, :blue)
    {value, state}
  end

  defp fetch(key) do
    table = pick(key)
    found(key, :ets.lookup(table, key))
  end

  defp pick("depth_" <> _), do: depth_table()
  defp pick("tree_" <> _), do: depth_table()
  defp pick(_), do: table()

  defp found(key, [{k, value}]) when key == k, do: value
  defp found(_key, []), do: "(empty)"
end

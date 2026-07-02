defmodule Tools.Sys.Get do
  import Log, only: [log: 5]

  def def(name, _state), do: spec(name)

  def exec(_, %{"key" => key}, state) do
    value = fetch(key)
    log("👀", key, ": ", value, :blue)
    {value, state}
  end

  defp spec(name) do
    %{name: name, description: "Retrieve data by key", parameters: parameters()}
  end

  defp parameters do
    %{
      type: "object",
      properties: %{key: %{type: "string", description: "The key to retrieve data for"}},
      required: ["key"]
    }
  end

  defp fetch(key) do
    table = if String.starts_with?(key, "depth_"), do: Mem.depth_table(), else: Mem.table()
    found(key, :ets.lookup(table, key))
  end

  defp found(key, [{k, value}]) when key == k, do: value
  defp found(_key, []), do: "(empty)"
end

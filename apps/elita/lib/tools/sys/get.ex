defmodule Tools.Sys.Get do
  import Log, only: [log: 5]
  import Mem, only: [depth: 0, table: 0]

  @icon "👀"

  def spec(name, _state) do
    spec(name)
  end

  defp spec(name) do
    %{name: name, description: description(), parameters: parameters()}
  end

  defp description do
    "Retrieve data by key"
  end

  def icon, do: @icon

  def exec(_, %{"key" => key}, state) do
    value = fetch(key)
    log(@icon, key, ": ", value, :blue)
    {value, state}
  end

  defp parameters do
    %{type: "object", properties: props(), required: required()}
  end

  defp required do
    ["key"]
  end

  defp props do
    %{key: %{type: "string", description: "The key to retrieve data for"}}
  end

  defp fetch(key) do
    table = pick(key)
    found(key, :ets.lookup(table, key))
  end

  defp pick("depth_" <> _), do: depth()
  defp pick("tree_" <> _), do: depth()
  defp pick(_), do: table()

  defp found(key, [{key, value}]), do: value
  defp found(_key, []), do: "(empty)"
end

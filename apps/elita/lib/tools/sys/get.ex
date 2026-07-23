defmodule Tools.Sys.Get do
  import Log, only: [log: 5, agent: 5]
  import Mem, only: [depth: 0, table: 1]

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

  def exec(_, %{"key" => key}, %{name: name} = state) do
    value = fetch(name, key)
    log(@icon, key, ": ", value, :blue)
    agent(@icon, key, ": ", value, %{name: name})
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

  defp fetch(name, key) do
    table = pick(key, name)
    found(key, :ets.lookup(table, key))
  end

  defp pick("depth_" <> _, _name), do: depth()
  defp pick("tree_" <> _, _name), do: depth()
  defp pick(_key, name), do: table(name)

  defp found(key, [{key, value}]), do: value
  defp found(_key, []), do: "(empty)"
end

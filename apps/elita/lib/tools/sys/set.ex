defmodule Tools.Sys.Set do
  import Log, only: [log: 5, agent: 5]
  import Map, only: [put: 3]
  import Mem, only: [depth: 0, table: 1]

  @icon "✏️"

  def spec(name, _state) do
    spec(name)
  end

  defp spec(name) do
    %{name: name, description: description(), parameters: parameters()}
  end

  defp description do
    "Store data with a key"
  end

  def icon, do: @icon

  def exec(_tool, %{"value" => value, "key" => key}, %{name: name} = state) do
    log(@icon, key, " = ", value, :blue)
    agent(@icon, key, " = ", value, %{name: name})
    store(name, key, value)
    {"stored", state}
  end

  def exec(tool, %{"value" => value} = args, state) do
    exec(tool, put(args, "key", value), state)
  end

  def exec(_, _args, state) do
    {"set needs key and value", state}
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

  defp store(name, key, value) do
    key |> pick(name) |> :ets.insert({key, value})
  end

  defp pick("depth_" <> _, _name), do: depth()
  defp pick("tree_" <> _, _name), do: depth()
  defp pick(_key, name), do: table(name)
end

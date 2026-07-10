defmodule Tools.Sys.Set do
  import Log, only: [log: 5]
  import Map, only: [put: 3]
  import Mem, only: [depth: 0, table: 0]

  def spec(name, _state) do
    spec(name)
  end

  defp spec(name) do
    %{name: name, description: description(), parameters: parameters()}
  end

  defp description do
    "Store data with a key"
  end

  def exec(_tool, %{"value" => value, "key" => key}, state) do
    log("✏️", key, " = ", value, :blue)
    store(key, value)
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

  defp store(key, value) do
    key |> pick() |> :ets.insert({key, value})
  end

  defp pick("depth_" <> _), do: depth()
  defp pick("tree_" <> _), do: depth()
  defp pick(_), do: table()
end

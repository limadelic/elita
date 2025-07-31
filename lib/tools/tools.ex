defmodule Tools do
  import String, only: [split: 2, trim: 1, capitalize: 1]
  import Enum, only: [map: 2, reject: 2]
  import Map, only: [put: 3]
  import Jason, only: [encode!: 1]
  import Module, only: [concat: 1]

  def tools(%{tools: names}) do
    split(names, ",")
    |> map(&trim/1)
    |> map(&tool/1)
    |> reject(&is_nil/1)
    |> wrap
  end

  def tools(_), do: []

  def exec(parts, agent) when is_list(parts) do
    map(parts, &exec(&1, agent))
  end

  def exec(%{"functionCall" => call} = part, agent) do
    put(part, "result", exec(call, agent))
  end

  def exec(%{"name" => name, "args" => args}, agent) do
    encode!(module(name).exec(agent, args))
  end

  def exec(part, _agent), do: part

  def void?(%{"name" => name}) do
    module(name).void?
  end

  defp wrap([]), do: []
  defp wrap(tools), do: [%{function_declarations: tools}]

  defp tool(name) do
    apply(module(name), :def, [])
  rescue
    _ -> nil
  end

  defp module(name) do
    concat([capitalize(name) <> "Tool"])
  end
end

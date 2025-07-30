defmodule Def do
  import String, only: [split: 2, trim: 1, capitalize: 1]
  import Enum, only: [map: 2, reject: 2]

  def tools(%{tools: names}) do
      split(names, ",")
      |> map(&trim/1)
      |> map(&tool/1)
      |> reject(&is_nil/1)
      |> wrap
  end
  def tools(_), do: []

  defp wrap([]), do: []
  defp wrap(tools), do: [%{function_declarations: tools}]

  defp tool(name) do
    apply(module(name), :def, [])
  rescue
    _ -> nil
  end

  defp module(name) do
    Module.concat([capitalize(name) <> "Tool"])
  end
end
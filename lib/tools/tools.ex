defmodule Tools do
  import String, only: [split: 2, trim: 1, capitalize: 1]
  import Enum, only: [map: 2, reject: 2]
  import Map, only: [put: 3]
  import Module, only: [concat: 1]
  import Code, only: [ensure_loaded: 1]
  import Log, only: [t: 2, r: 1]

  def tools(%{tools: names}) do
    split(names, ",")
    |> map(&trim/1)
    |> map(&prompt/1)
    |> reject(&is_nil/1)
    |> wrap
  end

  def tools(_), do: []

  def exec(parts) when is_list(parts) do
    map(parts, &exec/1)
  end

  def exec(%{"functionCall" => call} = part) do
    put(part, "result", exec(call))
  end

  def exec(%{"name" => name, "args" => args}) do
    t(name, args)
    r(module(name).exec(name, args))
  end
  
  def exec(part), do: part

  defp prompt(name) do
    module(name).def(name)
  end

  defp module(name) do
    concat([Tools, Static, capitalize(name)])
    |> ensure_loaded()
    |> static()
  end

  defp static({:module, mod}), do: mod
  defp static(_), do: Tools.Dynamic

  defp wrap([]), do: []
  defp wrap(tools), do: [%{function_declarations: tools}]

end

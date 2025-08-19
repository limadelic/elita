defmodule Tools do
  import String, only: [capitalize: 1]
  import Enum, only: [map: 2, reject: 2]
  import Map, only: [put: 3]
  import Module, only: [concat: 1]
  import Code, only: [ensure_loaded: 1]
  import Log, only: [t: 2, r: 1]

  def tools(%{tools: names}) when is_list(names) do
    names
    |> map(&prompt/1)
    |> reject(&is_nil/1)
    |> wrap
  end

  def tools(_), do: []

  def exec(parts, state) when is_list(parts) do
    map(parts, &exec(&1, state))
  end

  def exec(%{"functionCall" => call} = part, state) do
    put(part, "result", exec(call, state))
  end

  def exec(%{"name" => name, "args" => args}, state) do
    t(name, args)
    r(module(name).exec(name, args, state))
  end
  
  def exec(part, _state), do: part

  defp prompt(name) do
    module(name).def(name)
  end

  defp module(name) do
    concat([Tools, Sys, capitalize(name)])
    |> ensure_loaded()
    |> static()
  end

  defp static({:module, mod}), do: mod
  defp static(_), do: Tools.User

  defp wrap([]), do: []
  defp wrap(tools), do: [%{function_declarations: tools}]

end

defmodule Tools do
  import String, only: [capitalize: 1]
  import Enum, only: [map: 2, reject: 2, map_reduce: 3]
  import Map, only: [put: 3]
  import Module, only: [concat: 1]
  import Code, only: [ensure_loaded: 1]

  def tools(%{tools: names}, state) when is_list(names) do
    names
    |> map(&prompt(&1, state))
    |> reject(&is_nil/1)
    |> wrap
  end

  def tools(_, _), do: []

  def exec({parts, state}) do
    exec(parts, state)
  end

  def exec(parts, state) when is_list(parts) do
    map_reduce(parts, state, &exec/2)
  end

  def exec(%{"functionCall" => call} = part, state) do
    {result, state} = exec(call, state)
    {put(part, "result", result), state}
  end

  def exec(%{"name" => tool, "args" => args}, state) do
    module(tool).exec(tool, args, state)
  end

  def exec(part, state), do: {part, state}


  defp prompt(name, state) do
    module(name).def(name, state)
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

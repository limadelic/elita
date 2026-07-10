defmodule Shape do
  import Enum, only: [map: 2]
  import Map, only: [put: 3, get: 3]
  import Forge, only: [adapt: 1]

  def messages(system, history) do
    [
      %{role: "system", content: "/no_think\n#{system}"}
      | map(history, &adapt/1)
    ]
  end

  def equip(body, [%{function_declarations: defs}]) do
    put(body, :tools, map(defs, &tool/1))
  end

  def equip(body, _) do
    body
  end

  defp tool(d) do
    %{type: "function", function: specify(d)}
  end

  defp specify(d) do
    %{name: d[:name], description: d[:description], parameters: params(d)}
  end

  defp params(d) do
    get(d, :parameters, %{type: "object"})
  end
end

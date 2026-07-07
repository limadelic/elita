defmodule Shape do
  import Enum, only: [map: 2]
  import Map, only: [put: 3, get: 3]
  import MsgAdapter, only: [to_ollama: 1]

  def messages(system, history) do
    [
      %{role: "system", content: "/no_think\n#{system}"}
      | map(history, &to_ollama/1)
    ]
  end

  def add_tools(body, [%{function_declarations: defs}]) do
    put(body, :tools, map(defs, &tool/1))
  end

  def add_tools(body, _) do
    body
  end

  defp tool(d) do
    %{type: "function", function: func_spec(d)}
  end

  defp func_spec(d) do
    %{
      name: d[:name],
      description: d[:description],
      parameters: get(d, :parameters, %{type: "object"})
    }
  end
end

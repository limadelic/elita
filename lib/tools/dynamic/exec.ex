defmodule Tools.Dynamic.Exec do
  import String, only: [split: 2, trim: 1]
  import Enum, only: [map: 2, join: 2]
  import Code, only: [eval_string: 2]

  def exec(tool, _args) when tool != nil do
    first(tool.code, tool)
  end

  def exec(nil, _args), do: {:error, "Tool not found"}

  defp first([], _), do: "No code found"
  defp first([code | _], tool) do
    tool.imports
    |> modules
    |> imports
    |> plus(code)
    |> eval
  end

  defp modules(nil), do: []
  defp modules(text), do: split(text, ",") |> map(&trim/1)

  defp imports(modules) when is_list(modules) do
    ["import Tool.Index"] ++ map(modules, &imports/1)
  end

  defp imports(module), do: "import #{module}"

  defp plus(imports, code) do
    """
    #{join(imports, "\n")}

    #{code}
    """
  end

  defp eval(text) do
    {result, _} = eval_string(text, [])
    result
  end
end

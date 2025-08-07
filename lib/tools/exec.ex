defmodule Tools.Exec do
  import String, only: [split: 2, trim: 1]
  import Enum, only: [map: 2, join: 2]
  import Code, only: [eval_string: 2]

  def execute(code, meta) do
    meta["imports"] |> imports |> statements |> source(code) |> run |> format
  end

  defp imports(nil), do: []
  defp imports(text), do: split(text, ",") |> map(&trim/1)

  defp statements(modules) do
    ["import ToolIndex"] ++ map(modules, &build/1)
  end

  defp build(module), do: "import #{module}"

  defp source(lines, code) do
    """
    #{join(lines, "\n")}
    
    #{code}
    """
  end

  defp run(text) do
    try do
      {result, _} = eval_string(text, [])
      result
    rescue
      e -> {:error, e}
    end
  end

  defp format(nil), do: "executed successfully"
  defp format({:error, e}), do: "Error: #{inspect e}"
  defp format(value), do: "#{value}"
end
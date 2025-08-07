defmodule Tools.Exec do
  import String, only: [split: 2, trim: 1]

  def execute(code, meta) do
    imports = parse_imports(meta["imports"])
    
    # Build import statements
    import_statements = ["import ToolIndex"] ++ 
      Enum.map(imports, fn module -> "import #{module}" end)
    
    full_code = """
    #{Enum.join(import_statements, "\n")}
    
    #{code}
    """
    
    try do
      {result, _bindings} = Code.eval_string(full_code, [])
      case result do
        nil -> "executed successfully"
        value -> "#{value}"
      end
    rescue
      e -> "Error: #{inspect e}"
    end
  end

  defp parse_imports(nil), do: []
  defp parse_imports(imports_str) do
    split(imports_str, ",") |> Enum.map(&trim/1)
  end
end
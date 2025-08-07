defmodule Dynamic do
  import String, only: [split: 2, trim: 1]

  def tool(name) do
    path = "agents/tools/#{name}.md"
    if File.exists?(path) do
      {meta, _body} = parse_tool(path)
      %{name: name, description: meta["description"] || "Dynamic tool: #{name}"}
    else
      nil
    end
  end

  def exec(name, _args) do
    path = "agents/tools/#{name}.md"
    if File.exists?(path) do
      {meta, body} = parse_tool(path)
      code_blocks = extract_code_blocks(body)
      execute_blocks(code_blocks, meta)
    else
      {:error, "Tool #{name} not found"}
    end
  end

  defp parse_tool(path) do
    content = File.read!(path)
    parts = split(content, "---")
    # Skip empty first part, take second part as header, rest as body
    [_, header | body_parts] = parts
    meta = parse_yaml_header(header)
    body = Enum.join(body_parts, "---")
    {meta, body}
  end

  defp parse_yaml_header(header) do
    split(trim(header), "\n")
    |> Enum.reduce(%{}, fn line, acc ->
      case split(line, ":") do
        [key, value] -> Map.put(acc, trim(key), trim(value))
        _ -> acc
      end
    end)
  end

  defp extract_code_blocks(body) do
    # Simple regex to find ```elixir blocks
    Regex.scan(~r/```elixir\n(.*?)\n```/s, body, capture: :all_but_first)
    |> Enum.map(&List.first/1)
  end

  defp execute_blocks(blocks, meta) do
    case blocks do
      [] -> "No code blocks found"
      [code | _rest] -> evaluate_elixir_code(code, meta)
    end
  end

  defp parse_imports(nil), do: []
  defp parse_imports(imports_str) do
    split(imports_str, ",") |> Enum.map(&trim/1)
  end

  defp evaluate_elixir_code(code, meta) do
    imports = parse_imports(meta["imports"])
    bindings = []
    
    # Build import statements
    import_statements = ["import ToolIndex"] ++ 
      Enum.map(imports, fn module -> "import #{module}" end)
    
    full_code = """
    #{Enum.join(import_statements, "\n")}
    
    #{code}
    """
    
    try do
      {result, _bindings} = Code.eval_string(full_code, bindings)
      case result do
        nil -> "executed successfully"
        value -> "#{value}"
      end
    rescue
      e -> "Error: #{inspect e}"
    end
  end
end
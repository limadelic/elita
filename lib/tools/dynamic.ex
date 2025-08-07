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
    [header | body_parts] = split(content, "---")
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

  defp execute_blocks([], _meta) do
    "No code blocks found"
  end

  defp execute_blocks(blocks, _meta) do
    case blocks do
      [] -> "No code to execute"
      [code | _rest] -> evaluate_elixir_code(code)
    end
  end

  defp evaluate_elixir_code(code) do
    # Prepare execution environment with ToolIndex functions
    bindings = []
    
    # Create code with imports
    full_code = """
    import ToolIndex
    import Enum, only: [shuffle: 1]
    
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
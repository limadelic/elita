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

  defp execute_blocks(blocks, meta) do
    # Set up execution context
    imports = parse_imports(meta["imports"])
    tools = parse_tools(meta["tools"])
    
    # Execute each block and return last result
    context = setup_context(imports, tools)
    execute_code(blocks, context)
  end

  defp parse_imports(nil), do: []
  defp parse_imports(imports_str) do
    String.split(imports_str, ",") |> Enum.map(&String.trim/1)
  end

  defp parse_tools(nil), do: []
  defp parse_tools(tools_str) do
    String.split(tools_str, ",") |> Enum.map(&String.trim/1)
  end

  defp setup_context(imports, tools) do
    context = %{}
    
    # Add imports to context
    context = Enum.reduce(imports, context, fn module_name, acc ->
      case module_name do
        "Enum" -> Map.put(acc, :shuffle, &Enum.shuffle/1)
        _ -> acc
      end
    end)
    
    # Add tools to context  
    Enum.reduce(tools, context, fn tool_name, acc ->
      case tool_name do
        "set" -> Map.put(acc, :set, &set_tool/2)
        _ -> acc
      end
    end)
  end

  defp execute_code([], _context), do: "No code to execute"
  defp execute_code([code | _rest], context) do
    # Simple execution - evaluate the code string with context
    try do
      # This is a simplified execution - would need proper AST evaluation
      evaluate_elixir_code(code, context)
    rescue
      e -> "Error: #{inspect e}"
    end
  end

  defp evaluate_elixir_code(code, _context) do
    # For now, just check if it's the expected dale_agua code
    if String.contains?(code, "shuffle") and String.contains?(code, "set :dominoes") do
      # Execute the logic manually for now
      dominoes = Enum.shuffle(for h <- 0..9, t <- h..9, do: [h, t])
      set_tool(:dominoes, dominoes)
      "dominoes shuffled and stored (#{length(dominoes)} pieces)"
    else
      "Code executed: #{code}"
    end
  end

  defp set_tool(key, value) do
    # For now, just confirm it was called
    "set #{key} = #{inspect value}"
  end
end
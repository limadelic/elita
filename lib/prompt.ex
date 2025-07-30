defmodule Prompt do
  import Enum, only: [reverse: 1, join: 2]
  import String, only: [split: 3, trim: 1]
  import Tools, only: [tools: 1]
  
  def prompt1(%{content: content}, _history) do
    [%{role: "system", content: content}]
  end
  
  def prompt(config, history) do
    {frontmatter, content} = parse_config(config)
    tools_section = build_tools_section(tools(frontmatter))
    
    """
    #{content}
    #{tools_section}
    History:
    #{history |> reverse() |> join("\n")}
    """
  end
  
  defp parse_config(config) do
    case split(config, "---", parts: 3) do
      ["", yaml_text, content] ->
        case YamlElixir.read_from_string(yaml_text) do
          {:ok, frontmatter} -> {frontmatter, trim(content)}
          _ -> {%{}, config}
        end
      _ -> {%{}, config}
    end
  end
  
  defp build_tools_section(tools) when is_list(tools) do
    tool_descriptions = tools
    |> Enum.flat_map(fn %{function_declarations: declarations} -> declarations end)
    |> Enum.map(&tool_definition/1)
    |> join("\n")
    
    """
    
    Available tools:
    #{tool_descriptions}
    
    IMPORTANT: To use tools, write them in code blocks like this:
    ```tool_code
    get('todo_list')
    ```
    
    Always check for existing data first with get() before responding.
    """
  end
  
  defp build_tools_section(_), do: ""
  
  defp tool_definition(%{name: "set", description: desc}), do: "- set(key, value) - #{desc}"
  defp tool_definition(%{name: "get", description: desc}), do: "- get(key) - #{desc}. Use this to check what's stored."
  defp tool_definition(%{name: name, description: desc}), do: "- #{name}() - #{desc}"
end
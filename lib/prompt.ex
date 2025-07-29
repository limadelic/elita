defmodule Prompt do
  import Enum, only: [reverse: 1, join: 2]
  import String, only: [split: 2, split: 3, trim: 1]
  
  def prompt(config, history) do
    {frontmatter, content} = parse_config(config)
    tools_section = build_tools_section(frontmatter)
    
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
  
  defp build_tools_section(%{"tools" => tools}) when is_binary(tools) do
    tool_list = tools |> split(",") |> Enum.map(&trim/1)
    build_tools_section(%{"tools" => tool_list})
  end
  
  defp build_tools_section(%{"tools" => tools}) when is_list(tools) do
    definitions = tools
    |> Enum.map(&tool_definition/1)
    |> join("\n")
    
    """
    
    Available tools:
    #{definitions}
    """
  end
  
  defp build_tools_section(_), do: ""
  
  defp tool_definition("set"), do: "- set(key, value) - store data"
  defp tool_definition("get"), do: "- get(key) - retrieve data"
  defp tool_definition(tool), do: "- #{tool} - tool description"
end
defmodule Elita.Loader do
  alias Elita.Agent

  def agent(agent_name) do
    "examples/doble9/#{agent_name}.md"
    |> File.read!()
    |> parse_markdown()
  end

  defp parse_markdown(content) do
    lines = String.split(content, "\n")
    
    %Agent{
      name: extract_name(lines),
      role: extract_section(lines, "## Role"),
      goals: extract_section(lines, "## Goals"), 
      instructions: extract_section(lines, "## Instructions"),
      examples: extract_section(lines, "## Examples")
    }
  end

  defp extract_name(["# " <> name | _]), do: String.trim(name)
  defp extract_name([_ | tail]), do: extract_name(tail)
  defp extract_name([]), do: "Unknown"

  defp extract_section(lines, header) do
    lines
    |> Enum.drop_while(&(&1 != header))
    |> Enum.drop(1)
    |> Enum.take_while(&(not String.starts_with?(&1, "## ")))
    |> Enum.join("\n")
    |> String.trim()
  end
end
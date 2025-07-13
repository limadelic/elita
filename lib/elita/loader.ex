defmodule Elita.Loader do
  
  @agent_path "agents"

  def agent(name) do
    "#{@agent_path}/#{name}.md"
    |> File.read!()
    |> parse_markdown()
  end

  defp parse_markdown(content) do
    lines = String.split(content, "\n")
    
    %{
      name: name(lines),
      role: section(lines, "## Role"),
      goals: section(lines, "## Goals"),
      instructions: section(lines, "## Instructions"),
      examples: section(lines, "## Examples")
    }
  end

  defp name(["# " <> name | _]), do: String.trim(name)
  defp name([_ | tail]), do: name(tail)
  defp name([]), do: "Unknown"

  defp section(lines, header) do
    lines
    |> Enum.drop_while(&(&1 != header))
    |> Enum.drop(1)
    |> Enum.take_while(&(not String.starts_with?(&1, "## ")))
    |> Enum.join("\n")
    |> String.trim()
  end
end
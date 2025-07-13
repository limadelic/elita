defmodule Elita.Loader do
  alias Elita.Agent

  def agent(agent_name) do
    case File.read("examples/doble9/#{agent_name}.md") do
      {:ok, content} -> parse_markdown(content) |> elem(1)
      {:error, _} -> nil
    end
  end

  defp parse_markdown(content) do
    lines = String.split(content, "\n")
    
    agent = %Agent{
      name: extract_name(lines),
      role: extract_section(lines, "## Role"),
      goals: extract_section(lines, "## Goals"), 
      instructions: extract_section(lines, "## Instructions"),
      examples: extract_section(lines, "## Examples")
    }
    
    {:ok, agent}
  end

  defp extract_name(lines) do
    case Enum.find(lines, &String.starts_with?(&1, "# ")) do
      "# " <> name -> String.trim(name)
      _ -> "Unknown"
    end
  end

  defp extract_section(lines, header) do
    start_index = Enum.find_index(lines, &(&1 == header))
    
    if start_index do
      lines
      |> Enum.drop(start_index + 1)
      |> Enum.take_while(&(not String.starts_with?(&1, "## ")))
      |> Enum.join("\n")
      |> String.trim()
    else
      ""
    end
  end
end
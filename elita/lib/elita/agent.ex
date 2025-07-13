defmodule Elita.Agent do
  @moduledoc """
  Loads and parses agent definitions from markdown files
  """

  defstruct [:name, :role, :goals, :instructions, :examples]

  def load_greedy do
    case File.read("../examples/doble9/greedy.md") do
      {:ok, content} -> parse_markdown(content)
      {:error, reason} -> {:error, "Failed to load greedy agent: #{reason}"}
    end
  end

  defp parse_markdown(content) do
    lines = String.split(content, "\n")
    
    agent = %__MODULE__{
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
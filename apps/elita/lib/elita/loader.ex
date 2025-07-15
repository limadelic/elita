defmodule Elita.Loader do
  
  @folder "apps/elita/agents"

  def agent(name) do
    "#{@folder}/#{name}.md"
    |> File.read!()
    |> String.split("\n")
    |> parse()
  end

  defp parse(md) do
    %{
      name: name(md),
      role: section(md, "## Role"),
      goals: section(md, "## Goals"),
      instructions: section(md, "## Instructions"),
      examples: section(md, "## Examples")
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
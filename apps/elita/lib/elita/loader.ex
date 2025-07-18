defmodule Elita.Loader do
  import Enum, only: [find: 2, drop_while: 2, drop: 2, take_while: 2, join: 2]
  import String, only: [split: 2, starts_with?: 2, trim_leading: 2, trim: 1]
  
  def agent(name) do
    "agents/#{name}.md"
    |> File.read!()
    |> split("\n")
    |> parse()
  end

  defp parse(md) do
    %{
      name: name(md),
      role: section(md, "## Role"),
      goals: section(md, "## Goals"),
      instructions: section(md, "## Instructions"),
      examples: section(md, "## Examples"),
      requires: requires(md)
    }
  end

  defp name(lines) do
    lines
    |> find(&starts_with?(&1, "# "))
    |> then(&(&1 && trim_leading(&1, "# ") || "Unknown"))
  end

  defp section(lines, header) do
    lines
    |> drop_while(&(&1 != header))
    |> drop(1)
    |> take_while(&(not starts_with?(&1, "## ")))
    |> join("\n")
    |> trim()
  end

  defp requires(lines) do
    case find(lines, &(&1 == "## Requires")) do
      nil -> %{}
      _ ->
        lines
        |> drop_while(&(&1 != "## Requires"))
        |> drop(1)
        |> take_while(&(not starts_with?(&1, "## ")))
        |> parse_requires()
    end
  end

  defp parse_requires(lines) do
    lines
    |> find(&starts_with?(&1, "### Players"))
    |> case do
      nil -> %{}
      _ -> 
        lines
        |> drop_while(&(&1 != "### Players"))
        |> drop(1)
        |> take_while(&(starts_with?(&1, "- ")))
        |> parse_players()
    end
  end

  defp parse_players(lines) do
    lines
    |> Enum.map(&parse_player/1)
    |> Enum.into(%{})
  end

  defp parse_player("- " <> line) do
    [role, agent] = split(line, ": ")
    {trim(role), trim(agent) |> trim_leading("@")}
  end
end
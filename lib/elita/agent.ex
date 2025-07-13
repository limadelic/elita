defmodule Elita.Agent do
  @moduledoc """
  Loads and parses agent definitions from markdown files
  """

  defstruct [:name, :role, :goals, :instructions, :examples]

  def decide(name, context) do
    with {:ok, agent} <- load(name),
         {:ok, prompt} <- prompt(agent, context),
         {:ok, response} <- Elita.Pat.say(prompt),
         {:ok, parsed} <- parse(response) do
      {:ok, parsed}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def load(agent_name) do
    case File.read("examples/doble9/#{agent_name}.md") do
      {:ok, content} -> parse_markdown(content)
      {:error, reason} -> {:error, "Failed to load #{agent_name} agent: #{reason}"}
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

  defp prompt(agent, context) do
    prompt = """
    #{agent.role}

    Goals:
    #{agent.goals}

    Instructions:
    #{agent.instructions}

    Examples:
    #{agent.examples}

    Context:
    #{json(context)}
    """
    
    {:ok, prompt}
  end

  defp json(context) do
    Jason.encode!(context, pretty: true)
  end

  defp parse(response) do
    # For now, just return the raw response
    # Later we can add validation and retry logic
    {:ok, %{decision: String.trim(response)}}
  end
end
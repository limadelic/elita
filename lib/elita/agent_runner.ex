defmodule Elita.AgentRunner do
  @moduledoc """
  Runs agent decisions by combining agent definition with LLM calls
  """

  def decide("greedy", context) do
    with {:ok, agent} <- Elita.Agent.load_greedy(),
         {:ok, prompt} <- build_prompt(agent, context),
         {:ok, response} <- Elita.Pat.call(prompt, context),
         {:ok, parsed} <- parse_response(response) do
      {:ok, parsed}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_prompt(agent, context) do
    prompt = """
    #{agent.role}

    Goals:
    #{agent.goals}

    Instructions:
    #{agent.instructions}

    Examples:
    #{agent.examples}

    Current situation:
    #{format_context(context)}

    What is your decision?
    """
    
    {:ok, prompt}
  end

  defp format_context(context) do
    Jason.encode!(context, pretty: true)
  end

  defp parse_response(response) do
    # For now, just return the raw response
    # Later we can add validation and retry logic
    {:ok, %{action: String.trim(response)}}
  end
end
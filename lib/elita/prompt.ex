defmodule Elita.Prompt do
  def build(agent, context) do
    """
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
  end

  defp json(context) do
    Jason.encode!(context, pretty: true)
  end
end
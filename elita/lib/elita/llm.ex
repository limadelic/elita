defmodule Elita.LLM do
  @moduledoc """
  Interface for calling LLM APIs
  """

  @callback call(prompt :: String.t(), context :: map()) :: {:ok, String.t()} | {:error, String.t()}

  def call(prompt, context) do
    impl().call(prompt, context)
  end

  defp impl do
    Application.get_env(:elita, :llm_module, Elita.LLM.OpenAI)
  end
end

defmodule Elita.LLM.OpenAI do
  @moduledoc """
  OpenAI implementation of LLM interface
  """
  @behaviour Elita.LLM

  def call(prompt, _context) do
    # TODO: Implement actual OpenAI API call
    {:ok, "play [6,3]"}
  end
end

defmodule Elita.LLM.Mock do
  @moduledoc """
  Mock implementation for testing
  """
  @behaviour Elita.LLM

  def call(_prompt, context) do
    # Return a canned response based on context for testing
    hand = Map.get(context, "hand", [])
    
    if length(hand) > 0 do
      {:ok, "play [6,3]"}
    else
      {:ok, "knock knock"}
    end
  end
end
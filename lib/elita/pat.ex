defmodule Elita.Pat do
  @moduledoc """
  Interface for calling LLM APIs
  """

  @callback say(prompt :: String.t(), context :: map()) :: {:ok, String.t()} | {:error, String.t()}

  def say(prompt, context) do
    impl().say(prompt, context)
  end

  defp impl do
    Application.get_env(:elita, :pat_module, Elita.Pat.OpenAI)
  end
end

defmodule Elita.Pat.OpenAI do
  @moduledoc """
  OpenAI implementation of Pat interface
  """
  @behaviour Elita.Pat

  def say(_prompt, _context) do
    # TODO: Implement actual OpenAI API call
    {:ok, "play [6,3]"}
  end
end

defmodule Elita.Pat.Mock do
  @moduledoc """
  Mock implementation for testing
  """
  @behaviour Elita.Pat

  def say(_prompt, context) do
    # Return a canned response based on context for testing
    hand = Map.get(context, "hand", [])
    
    if length(hand) > 0 do
      {:ok, "play [6,3]"}
    else
      {:ok, "knock knock"}
    end
  end
end
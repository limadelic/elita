defmodule Llm do
  def llm(text) when is_binary(text), do: backend().llm(text)
  def llm(state), do: backend().llm(state)

  defp backend do
    case System.get_env("LLM", "lite") do
      "mlm" -> Mlm
      _ -> Lite
    end
  end
end

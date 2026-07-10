defmodule Llm do
  import System, only: [get_env: 2]

  def llm(text) when is_binary(text), do: invoke(text)
  def llm(state), do: invoke(state)

  defp invoke(arg) do
    get_env("LLM", "lite")
    |> backend()
    |> apply(:llm, [arg])
  end

  defp backend("mlm"), do: Mlm
  defp backend(_), do: Lite
end

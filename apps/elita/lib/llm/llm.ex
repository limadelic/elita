defmodule Llm do
  import System, only: [get_env: 2]

  def llm(text) when is_binary(text), do: llm_impl(text)
  def llm(state), do: llm_impl(state)

  defp llm_impl(arg) do
    get_env("LLM", "lite")
    |> select_backend()
    |> apply(:llm, [arg])
  end

  defp select_backend("mlm"), do: Mlm
  defp select_backend(_), do: Lite
end

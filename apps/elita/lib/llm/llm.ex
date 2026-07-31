defmodule Llm do
  import Application, only: [get_env: 2]

  def llm(text) when is_binary(text), do: invoke(text)
  def llm(state), do: invoke(state)

  defp invoke(arg) do
    get_env(:elita, :llm)
    |> backend()
    |> apply(:llm, [arg])
  end

  defp backend(_), do: Lite
end

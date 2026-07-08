defmodule Request do
  def direct(text) do
    %{model: model(), max_tokens: 4096, messages: [%{role: "user", content: text}]}
  end

  defp model, do: "claude-haiku-4-5"
end

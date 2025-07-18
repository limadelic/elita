defmodule Elita.Convo do
  def new do
    []
  end

  def add_message(conversation, message) do
    [message | conversation]
  end

  def build_prompt(conversation) do
    conversation
    |> Enum.reverse()
    |> Enum.map(&format_message/1)
    |> Enum.join("\n\n")
  end

  defp format_message(%{role: role, content: content}) when is_binary(content) do
    "#{role}: #{content}"
  end

  defp format_message(%{role: role, content: content}) do
    "#{role}: #{Jason.encode!(content)}"
  end
end
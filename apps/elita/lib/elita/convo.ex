defmodule Elita.Convo do
  def new do
    []
  end

  def add_msg(convo, msg) do
    [msg | convo]
  end

  def build_prompt(convo) do
    convo
    |> Enum.reverse()
    |> Enum.map(&format_msg/1)
    |> Enum.join("\n\n")
  end

  defp format_msg(%{role: role, content: content}) when is_binary(content) do
    "#{role}: #{content}"
  end

  defp format_msg(%{role: role, content: content}) do
    "#{role}: #{Jason.encode!(content)}"
  end
end
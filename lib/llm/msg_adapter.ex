defmodule MsgAdapter do
  import Enum, only: [map: 2, find_value: 2]

  def to_ollama(%{role: "user", content: [%{type: "tool_result"} | _] = content}) do
    %{role: "tool", content: find_value(content, &tool_result/1)}
  end
  def to_ollama(%{role: role, content: content}) when is_list(content) do
    %{role: role, content: content |> map(&text/1) |> Enum.join(" ")}
  end
  def to_ollama(msg), do: msg

  defp tool_result(%{"type" => "tool_result", "content" => c}), do: c
  defp tool_result(_), do: nil

  defp text(%{"text" => t}), do: t
  defp text(%{"type" => "tool_use", "name" => name}), do: "[called #{name}]"
  defp text(_), do: ""
end

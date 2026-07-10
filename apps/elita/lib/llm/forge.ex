defmodule Forge do
  import Enum, only: [map: 2, find_value: 2, join: 2]

  def adapt(%{role: "user", content: content}) when is_binary(content) do
    %{role: "user", content: "/no_think #{content}"}
  end

  def adapt(%{
        role: "user",
        content: [%{type: "tool_result"} | _] = content
      }) do
    %{role: "tool", content: find_value(content, &extract/1)}
  end

  def adapt(%{role: role, content: content}) when is_list(content) do
    %{role: role, content: content |> map(&text/1) |> join(" ")}
  end

  def adapt(msg), do: msg

  defp extract(%{"type" => "tool_result", "content" => c}), do: c
  defp extract(_), do: nil

  defp text(%{"text" => t}), do: t
  defp text(%{"type" => "tool_use", "name" => name}), do: "[called #{name}]"
  defp text(_), do: ""
end

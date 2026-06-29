defmodule History do
  import Msg, only: [tool_result: 2]
  import Enum, only: [any?: 2, find_value: 3, filter: 2, map: 2, empty?: 1]

  def record({parts, state}) do
    record(parts, state)
  end

  def record(parts, state) when is_list(parts) do
    {messages, text} = build_messages(parts)
    history = state.history ++ messages

    if any?(parts, &has_result?/1) do
      {:act, %{state | history: history}}
    else
      {:reply, text, %{state | history: history}}
    end
  end

  def record({:error, reason}, state) do
    {:reply, "Error: #{reason}", state}
  end

  defp build_messages(parts) do
    text = find_value(parts, "", &text/1)
    content = build_content(parts)

    messages =
      if empty?(content) do
        []
      else
        [%{role: "assistant", content: content}]
      end

    messages =
      if any?(parts, &has_result?/1) do
        messages ++ build_results(parts)
      else
        messages
      end

    {messages, text}
  end

  defp build_content(parts) do
    parts
    |> filter(&has_content?/1)
    |> map(&to_content/1)
  end

  defp build_results(parts) do
    parts
    |> filter(&has_result?/1)
    |> map(&to_result/1)
  end

  defp has_content?(part) do
    Map.has_key?(part, "text") or Map.has_key?(part, "tool_use")
  end

  defp to_content(%{"text" => text}) do
    %{type: "text", text: text}
  end

  defp to_content(%{"tool_use" => %{"id" => id, "name" => name, "input" => input}}) do
    %{type: "tool_use", id: id, name: name, input: input}
  end

  defp to_result(%{"tool_use" => %{"id" => id}, "result" => result}) do
    tool_result(id, stringify(result))
  end

  defp text(%{"text" => text}), do: text
  defp text(_), do: nil

  defp has_result?(%{"result" => _}), do: true
  defp has_result?(_), do: false

  defp stringify(c) when is_binary(c), do: c
  defp stringify(c), do: inspect(c)
end

defmodule History do
  import Msg, only: [tool_result: 2]
  import Enum, only: [any?: 2, find_value: 3, filter: 2, map: 2]

  def record({parts, state}) do
    record(parts, state)
  end

  def record(parts, state) when is_list(parts) do
    {messages, text} = build_messages(parts)
    reply_or_act(any?(parts, &has_result?/1), text, state, messages)
  end

  def record({:error, reason}, state) do
    {:reply, "Error: " <> to_string(reason), state}
  end

  defp reply_or_act(true, _text, state, messages) do
    {:act, %{state | history: state.history ++ messages}}
  end

  defp reply_or_act(false, text, state, messages) do
    {:reply, text, %{state | history: state.history ++ messages}}
  end

  defp build_messages(parts) do
    text = find_value(parts, "", &text/1)
    content = build_content(parts)
    {msgs(content, parts), text}
  end

  defp msgs(content, parts) do
    content_msgs(content) ++ result_msgs(parts)
  end

  defp content_msgs([]), do: []
  defp content_msgs(content), do: [%{role: "assistant", content: content}]

  defp result_msgs(parts) do
    pick_results(any?(parts, &has_result?/1), parts)
  end

  defp pick_results(true, parts), do: build_results(parts)
  defp pick_results(false, _parts), do: []

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

  defp has_content?(%{"text" => _}), do: true
  defp has_content?(%{"tool_use" => _}), do: true
  defp has_content?(_), do: false

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

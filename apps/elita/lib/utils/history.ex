defmodule History do
  import Enum, only: [any?: 2, find_value: 3, filter: 2, map: 2]
  import Msg, only: [result: 2]

  def record({parts, state}) do
    record(parts, state)
  end

  def record(parts, state) when is_list(parts) do
    {messages, text} = craft(parts)
    route(any?(parts, &done?/1), text, state, messages)
  end

  def record({:error, reason}, state) do
    {:reply, "Error: #{reason}", state}
  end

  defp route(true, _text, state, messages) do
    {:act, %{state | history: state.history ++ messages}}
  end

  defp route(false, text, state, messages) do
    {:reply, text, %{state | history: state.history ++ messages}}
  end

  defp craft(parts) do
    text = find_value(parts, "", &text/1)
    content = extract(parts)
    {msgs(content, parts), text}
  end

  defp msgs(content, parts) do
    msg(content) ++ wrap(parts)
  end

  defp msg([]), do: []
  defp msg(content), do: [%{role: "assistant", content: content}]

  defp wrap(parts) do
    gather(any?(parts, &done?/1), parts)
  end

  defp gather(true, parts), do: harvest(parts)
  defp gather(false, _parts), do: []

  defp extract(parts) do
    parts
    |> filter(&rich?/1)
    |> map(&form/1)
  end

  defp harvest(parts) do
    parts
    |> filter(&done?/1)
    |> map(&pack/1)
  end

  defp rich?(%{"text" => _}), do: true
  defp rich?(%{"tool_use" => _}), do: true
  defp rich?(_), do: false

  defp form(%{"text" => text}) do
    %{type: "text", text: text}
  end

  defp form(%{
         "tool_use" => %{"id" => id, "name" => name, "input" => input}
       }) do
    %{type: "tool_use", id: id, name: name, input: input}
  end

  defp pack(%{"tool_use" => %{"id" => id}, "result" => result}) do
    result(id, stringify(result))
  end

  defp text(%{"text" => text}), do: text
  defp text(_), do: nil

  defp done?(%{"result" => _}), do: true
  defp done?(_), do: false

  defp stringify(c) when is_binary(c), do: c
  defp stringify(c), do: inspect(c)
end

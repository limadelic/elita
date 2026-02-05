defmodule History do
  import Msg, only: [assistant: 1, tool_use: 3, tool_result: 2]
  import Enum, only: [reduce: 3, any?: 2, find_value: 3]

  def record({parts, state}) do
    record(parts, state)
  end

  def record(parts, state) when is_list(parts) do
    history = reduce(parts, state.history, &add/2)
    text = find_value(parts, "", &text/1)

    if any?(parts, &has_result?/1) do
      {:act, %{state | history: history}}
    else
      {:reply, text, %{state | history: history}}
    end
  end

  def record({:error, reason}, state) do
    {:reply, "Error: #{reason}", state}
  end

  defp add(%{"text" => text}, history), do: history ++ [assistant(text)]

  defp add(%{"result" => result, "tool_use" => %{"id" => id, "name" => name, "input" => input}}, history) do
    history ++ [tool_use(id, name, input), tool_result(id, stringify(result))]
  end

  defp add(%{"tool_use" => %{"id" => id, "name" => name, "input" => input}}, history) do
    history ++ [tool_use(id, name, input)]
  end

  defp add(_, history), do: history

  defp text(%{"text" => text}), do: text
  defp text(_), do: nil

  defp has_result?(%{"result" => _}), do: true
  defp has_result?(_), do: false

  defp stringify(c) when is_binary(c), do: c
  defp stringify(c), do: inspect(c)
end

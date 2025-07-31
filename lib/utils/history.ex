defmodule History do
  import Msg, only: [model: 1, user: 1, function_call: 2, function_response: 2]
  import Enum, only: [reduce: 3, any?: 2, find_value: 3]
  import Jason, only: [decode: 1]

  def record(parts, state) do
    history = reduce(parts, state.history, &add/2)
    text = find_value(parts, "", &text/1)
    
    if any?(parts, &has_result?/1) do
      {:act, %{state | history: history}}
    else
      {:reply, text, %{state | history: history}}
    end
  end

  defp add(%{"text" => text}, history), do: history ++ [model(text)]
  
  defp add(%{"functionCall" => %{"name" => name, "args" => args}}, history) do
    history ++ [function_call(name, args)]
  end

  defp add(%{"result" => result, "functionCall" => %{"name" => name}}, history) do
    {:ok, response} = decode(result)
    history ++ [function_response(name, response)]
  end

  defp add(%{"result" => result}, history) do
    history ++ [user(result)]
  end

  defp add(_, history), do: history

  defp text(%{"text" => text}), do: text
  defp text(_), do: nil

  defp has_result?(%{"result" => _}), do: true
  defp has_result?(_), do: false
end
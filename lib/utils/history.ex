defmodule History do
  import Msg, only: [model: 1, user: 1]
  import Enum, only: [reduce: 3, any?: 2]

  def record(parts, state) do
    history = reduce(parts, state.history, &add/2)
    
    if any?(parts, &has_result?/1) do
      {:reply, "", %{state | history: history}}
    else
      {:act, "", %{state | history: history}}
    end
  end

  defp add(%{"text" => text}, history), do: history ++ [model(text)]
  defp add(%{"result" => result}, history), do: history ++ [user(result)]  
  defp add(_, history), do: history

  defp has_result?(%{"result" => _}), do: true
  defp has_result?(_), do: false
end
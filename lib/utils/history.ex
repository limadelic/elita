defmodule History do
  import Msg, only: [model: 1, user: 1]
  import Enum, only: [reduce: 3]

  def record(parts, state) do
    history = reduce(parts, state.history, &add/2)
    {:act, "", %{state | history: history}}
  end

  defp add(%{"text" => text}, history), do: history ++ [model(text)]
  defp add(%{"result" => result}, history), do: history ++ [user(result)]  
  defp add(_, history), do: history
end
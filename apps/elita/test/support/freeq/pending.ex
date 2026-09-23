defmodule Freeq.Pending do
  def push(%{pending: queue} = state, text), do: %{state | pending: queue ++ [text]}

  def drop(%{pending: []} = state), do: state
  def drop(%{pending: [_ | rest]} = state), do: %{state | pending: rest}
end

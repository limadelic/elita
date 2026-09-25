defmodule Freeq.Pending do
  def push(%{pending: queue} = state, text) do
    %{state | pending: queue ++ [text]}
  end

  def drop(%{pending: []} = state), do: state

  def drop(%{pending: [_ | rest]} = state) do
    %{state | pending: rest, attempts: 0}
  end

  def head(%{pending: []}), do: nil
  def head(%{pending: [text | _]}), do: text
end

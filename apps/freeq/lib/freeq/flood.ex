defmodule Freeq.Flood do
  import Process, only: [send_after: 3]
  import Application, only: [get_env: 3]

  @limit 3

  def defer(_state, nil, msg), do: raise("freeq refused a message we never queued: #{msg}")

  def defer(%{attempts: attempts} = state, text, msg), do: retry(attempts + 1, state, text, msg)

  defp retry(count, state, text, _msg) when count <= @limit do
    send_after(self(), {:retry, text}, window())
    %{state | attempts: count}
  end

  defp retry(count, _state, _text, msg) do
    raise("freeq refused a message #{count - 1} times, giving up: #{msg}")
  end

  defp window, do: get_env(:elita, :flood_window, 2000)
end

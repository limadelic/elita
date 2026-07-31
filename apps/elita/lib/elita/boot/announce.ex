defmodule Elita.Boot.Announce do
  import Utils.Normalize, only: [name: 1]

  def notify(n, pid) do
    normalized = name(n)
    :global.whereis_name({:waiter, normalized}) |> tell(normalized, pid)
  end

  defp tell(:undefined, _, _), do: :ok
  defp tell(waiter, n, pid), do: send(waiter, {:puppet_ready, n, pid})
end

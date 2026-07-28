defmodule Elita.Boot.Announce do
  import String, only: [downcase: 1]

  def notify(name, pid) do
    n = norm(name)
    :global.whereis_name({:waiter, n}) |> tell(n, pid)
  end

  defp norm(name), do: name |> to_string() |> downcase()
  defp tell(:undefined, _, _), do: :ok
  defp tell(waiter, n, pid), do: send(waiter, {:puppet_ready, n, pid})
end

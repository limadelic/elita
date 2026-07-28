defmodule Elita.Boot.Announce do
  import String, only: [downcase: 1]

  def notify(name, pid) do
    :global.whereis_name({:waiter, norm(name)}) |> tell(pid)
  end

  defp norm(name), do: name |> to_string() |> downcase()
  defp tell(:undefined, _), do: :ok
  defp tell(waiter, pid), do: send(waiter, {:puppet_ready, pid})
end

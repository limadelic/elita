defmodule Elita.Place do
  import DynamicSupervisor, only: [start_child: 2]
  import Utils.Normalize, only: [name: 1]

  def put(spec, n) do
    start_child(Elita.Spawner, spec) |> swap(n)
  end

  defp swap({:ok, _pid}, n), do: find(:global.whereis_name({name(n), :puppet}))

  defp swap({:error, {:already_started, _pid}}, n),
    do: find(:global.whereis_name({name(n), :puppet}))

  defp swap(other, _n), do: other

  defp find(:undefined), do: {:error, :init_failed}

  defp find(pid), do: {:ok, pid}
end

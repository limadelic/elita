defmodule El.Tunnel do
  import Node, only: [connect: 1]
  import System, only: [pid: 0]
  import El.Run, only: [suffix: 0]

  defp safely(fun, default) do
    fun.()
  rescue
    _ -> default
  end

  def boot(_agent) do
    spawn()
    peer()
  end

  defp spawn do
    node = :"tunnel_#{pid()}@127.0.0.1"
    opts = %{name_domain: :longnames, hidden: true, dist_listen: false}
    safely(fn -> :net_kernel.start(node, opts) |> result() end, :ok)
  end

  defp result({:ok, _}), do: :ok
  defp result({:error, {:already_started, _}}), do: :ok
  defp result({:error, _}), do: :ok

  defp peer do
    safely(fn -> connect(:"elita#{suffix()}@127.0.0.1") end, :ok)
  end

  def reach(agent) do
    safely(fn -> :global.whereis_name({agent, :puppet}) end, nil)
  end
end

defmodule El.Tunnel do
  import Enum, only: [find_value: 3]
  import Node, only: [connect: 1]
  import System, only: [pid: 0]

  defp safely(fun, default) do
    fun.()
  rescue
    _ -> default
  end

  def boot(_agent) do
    ensure_epmd()
    spawn()
    peer()
  end

  defp ensure_epmd do
    safely(fn -> :os.cmd(~c"epmd -daemon") end, :ok)
  end

  defp spawn do
    node = :"tunnel_#{pid()}@127.0.0.1"
    opts = %{name_domain: :longnames}
    safely(fn -> :net_kernel.start(node, opts) |> result() end, :ok)
  end

  defp result({:ok, _}), do: :ok
  defp result({:error, {:already_started, _}}), do: :ok
  defp result({:error, _}), do: :ok

  defp peer do
    safely(fn -> :net_adm.names(~c"127.0.0.1") |> connect_any() end, :ok)
  end

  defp connect_any({:error, _}), do: :ok
  defp connect_any({:ok, nodes}) do
    find_value(nodes, :ok, &connect_node/1) || :ok
  end

  defp connect_node({name, _}) do
    node = :"#{:erlang.list_to_binary(name)}@127.0.0.1"
    safely(fn -> connect(node) end, nil)
  end

  def reach(agent) do
    safely(fn -> :global.whereis_name({agent, :puppet}) end, nil)
  end
end

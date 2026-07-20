defmodule El.Tunnel do
  import Enum, only: [find_value: 3]
  import Node, only: [connect: 1]
  import System, only: [pid: 0]
  import El.Run, only: [suffix: 0]
  import El.Distribution, only: [start: 1]

  defp safely(fun, default) do
    fun.()
  rescue
    _ -> default
  end

  def boot(agent) do
    agent |> present() |> dispatch(agent)
  end

  defp dispatch(true, agent) do
    spawn()
    peer(agent)
  end

  defp dispatch(false, agent), do: start(agent)

  defp present(agent), do: safely(fn -> :net_adm.names(~c"127.0.0.1") |> exist(agent) end, false)

  defp exist({:error, _}, _), do: false
  defp exist({:ok, list}, agent), do: find_value(list, false, &match(&1, agent))

  defp match({node, _}, agent) do
    safely(fn -> :erlang.list_to_binary(node) |> check(agent) != nil end, false)
  end

  defp spawn do
    node = :"tunnel_#{pid()}@127.0.0.1"
    opts = %{name_domain: :longnames, hidden: true, dist_listen: false}
    safely(fn -> :net_kernel.start(node, opts) |> result() end, :ok)
  end

  defp result({:ok, _}), do: :ok
  defp result({:error, {:already_started, _}}), do: :ok
  defp result({:error, _}), do: :ok

  defp peer(agent), do: safely(fn -> connect(:"#{agent}#{suffix()}@127.0.0.1") end, :ok)

  def reach(agent),
    do: safely(fn -> :net_adm.names(~c"127.0.0.1") |> node(agent) |> fetch(agent) end, nil)

  defp node({:error, _}, _), do: nil
  defp node({:ok, list}, agent), do: find_value(list, nil, &fits(&1, agent))

  defp fits({name, _}, agent) do
    binary = :erlang.list_to_binary(name)
    binary |> check(agent)
  end

  defp check(name, agent) do
    prefix(name, agent) |> pick(name)
  end

  defp prefix(node, agent) do
    len = min(byte_size(agent) + 1, byte_size(node))
    safely(fn -> binary_part(node, 0, len) == <<agent::binary, "-">> end, false)
  end

  defp pick(true, name), do: name
  defp pick(false, _), do: nil

  defp fetch(nil, _), do: nil

  defp fetch(node, agent) do
    full = :"#{node}@127.0.0.1"
    safely(fn -> :erpc.call(full, :global, :whereis_name, [{agent, :puppet}]) end, nil)
  end
end

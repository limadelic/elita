defmodule El.Tunnel do
  import Enum, only: [find_value: 3]
  import String, only: [to_atom: 1]
  import Node, only: [start: 3, connect: 1]
  import System, only: [pid: 0]
  import El.Distribution, only: [start: 1]
  import El.Run, only: [suffix: 0]

  def boot(agent) do
    agent |> present() |> dispatch(agent)
  end

  defp dispatch(true, agent) do
    spawn()
    peer(agent)
  end

  defp dispatch(false, agent), do: start(agent)

  defp present(agent) do
    :net_adm.names(~c"127.0.0.1") |> exist(agent)
  rescue
    _ -> false
  end

  defp exist({:error, _}, _), do: false
  defp exist({:ok, list}, agent), do: find_value(list, false, &match(&1, agent))

  defp match({node, _}, agent) do
    name = :erlang.list_to_binary(node)
    name |> check(agent) != nil
  rescue
    _ -> false
  end

  defp spawn do
    start(:"tunnel_#{pid()}@127.0.0.1", :longnames, hidden: true, dist_listen: false)
  rescue
    _ -> :ok
  end

  defp peer(agent) do
    connect(:"#{agent}#{suffix()}@127.0.0.1")
    :global.sync()
  rescue
    _ -> :ok
  end

  def reach(agent) do
    :net_adm.names(~c"127.0.0.1") |> nodes(agent) |> call(agent)
  rescue
    _ -> nil
  end

  defp nodes({:error, _}, _), do: nil
  defp nodes({:ok, list}, agent), do: find_value(list, nil, &fits(&1, agent))

  defp fits({node, _}, agent) do
    name = :erlang.list_to_binary(node)
    name |> check(agent)
  end

  defp check(name, agent) do
    prefix(name, agent) |> pick(name)
  end

  defp prefix(node, agent) do
    len = min(byte_size(agent) + 1, byte_size(node))
    binary_part(node, 0, len) == <<agent::binary, "-">>
  rescue
    _ -> false
  end

  defp pick(true, name), do: name
  defp pick(false, _), do: nil

  defp call(nil, _), do: nil

  defp call(node, agent) do
    node |> to_atom() |> ask({agent, :puppet})
  rescue
    _ -> nil
  end

  defp ask(node, name) do
    :erpc.call(node, :global, :whereis_name, [name])
  end
end

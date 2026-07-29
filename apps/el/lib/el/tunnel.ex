defmodule El.Tunnel do
  import Application, only: [get_env: 3]
  import Enum, only: [find_value: 3]
  import Node, only: [connect: 1]
  import System, only: [pid: 0]
  import El.Run, only: [suffix: 0]
  import String, only: [downcase: 1]
  import El.Distribution, only: [hidden: 1]

  defp safely(fun, default) do
    fun.()
  catch
    _, _ -> default
  end

  def boot(agent) do
    spawn()
    agent |> present() |> dispatch(agent)
  end

  defp dispatch(true, agent) do
    peer(agent)
  end

  defp dispatch(false, _agent) do
    attach(get_env(:elita, :run, ""))
  end

  defp attach(""), do: :ok

  defp attach(id) do
    node = :"elita-#{id}@127.0.0.1"
    safely(fn -> connect(node) end, :ok)
  end

  defp present(agent), do: safely(fn -> :net_adm.names(~c"127.0.0.1") |> exist(agent) end, false)

  defp exist({:error, _}, _), do: false
  defp exist({:ok, list}, agent), do: find_value(list, false, &match(&1, agent))

  defp match({node, _}, agent) do
    safely(fn -> :erlang.list_to_binary(node) |> check(agent) != nil end, false)
  end

  defp spawn do
    hidden("tunnel_#{pid()}")
  end

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
    binary_part(node, 0, len) == <<agent::binary, "-">>
  end

  defp pick(true, name), do: name
  defp pick(false, _), do: nil

  defp fetch(nil, _), do: nil

  defp fetch(node, agent) do
    full = :"#{node}@127.0.0.1"
    safely(fn -> locate(full, agent) end, nil)
  end

  defp locate(full, agent) do
    :erpc.call(full, :global, :whereis_name, [{normalize(agent), :puppet}], 5000)
  end

  defp normalize(name) do
    name |> to_string() |> downcase()
  end
end

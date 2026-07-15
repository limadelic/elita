defmodule Agent.Remote do
  import Enum, only: [find_value: 3]
  import String, only: [to_atom: 1, downcase: 1]

  def find(agent) do
    :net_adm.names(~c"127.0.0.1") |> list() |> search(agent)
  rescue
    _ -> :undefined
  end

  defp list({:ok, n}), do: n
  defp list(_), do: []

  defp search(names, agent) do
    find_value(names, :undefined, &match(&1, agent))
  end

  defp match({name, _}, agent) do
    node = :erlang.list_to_binary(name)
    run(node, agent, agent)
  rescue
    _ -> nil
  end

  defp run(node, agent, name) do
    <<name::binary, "-">> |> ok(node) |> exec(agent, node)
  end

  defp ok(prefix, node) do
    take(node, byte_size(prefix)) == prefix
  end

  defp exec(true, agent, node) do
    agent |> norm() |> fetch(node)
  end

  defp exec(false, _, _), do: nil

  defp take(node, size) do
    binary_part(node, 0, size)
  rescue
    _ -> nil
  end

  defp norm(agent) do
    agent |> to_atom() |> Kernel.to_string() |> downcase() |> to_atom()
  end

  defp fetch(norm, node) do
    addr = "#{node}@127.0.0.1" |> to_atom()
    :erpc.call(addr, :global, :whereis_name, [{norm, :puppet}])
  rescue
    _ -> nil
  end
end

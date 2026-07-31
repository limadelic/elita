defmodule Agent.Remote do
  import Enum, only: [find_value: 3]
  import String, only: [to_atom: 1]
  import Utils.Normalize, only: [name: 1]

  def find(agent) do
    :net_adm.names(~c"127.0.0.1") |> list() |> search(agent)
  catch
    _, _ -> :undefined
  end

  defp list({:ok, n}), do: n
  defp list(_), do: []

  defp search(names, agent) do
    find_value(names, :undefined, &match(&1, agent))
  end

  defp match({n, _}, agent) do
    node = :erlang.list_to_binary(n)
    run(node, agent, agent)
  rescue
    _ -> nil
  end

  defp run(node, agent, a) do
    <<a::binary, "-">> |> ok(node) |> exec(agent, node)
  end

  defp ok(prefix, node) do
    take(node, byte_size(prefix)) == prefix
  end

  defp exec(true, agent, node) do
    agent |> to_atom() |> Kernel.to_string() |> name() |> fetch(node)
  end

  defp exec(false, _, _), do: nil

  defp take(node, size) do
    binary_part(node, 0, size)
  rescue
    _ -> nil
  end

  defp fetch(norm, node) do
    addr = "#{node}@127.0.0.1" |> to_atom()
    :erpc.call(addr, :global, :whereis_name, [{norm, :puppet}], 5000)
  catch
    _, _ -> nil
  end
end

defmodule Agent.Puppet do
  import Enum, only: [map: 2, filter: 2]
  import Registry, only: [select: 2]

  def cwd do
    select()
    |> scan()
  catch
    _, _ -> nil
  end

  defp select do
    ElitaRegistry
    |> select([{{:_, :_, :"$1"}, [], [:"$1"]}])
    |> pick()
  end

  defp pick(entries) do
    entries
    |> map(&extract/1)
    |> filter(& &1)
  end

  defp extract(%{pid: pid, kind: :puppet}), do: {pid, %{kind: :puppet}}
  defp extract(_), do: nil

  defp scan([]), do: nil

  defp scan([entry | rest]) do
    entry |> query() |> ok(rest)
  end

  defp query({pid, %{kind: :puppet}}) do
    log("puppet:found pid=#{inspect(pid)}\n")
    node = node(pid)
    log("puppet:node=#{node}\n")
    rpc(node)
  end

  defp query(_), do: nil

  defp rpc(node) do
    :erpc.call(node, System, :cwd, [])
  rescue
    e -> error(e)
  end

  defp error(e) do
    log("puppet:rpc error=#{inspect(e)}\n")
    nil
  end

  defp ok(cwd, _rest) when is_binary(cwd) do
    log("puppet:cwd=#{cwd}\n")
    cwd
  end

  defp ok(nil, rest), do: scan(rest)

  defp log(msg) do
    :erlang.apply(:"Elixir.El.Log", :write, [msg])
  rescue
    _ -> :ok
  end
end

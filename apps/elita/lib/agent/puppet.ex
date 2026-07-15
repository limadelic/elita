defmodule Agent.Puppet do
  import Enum, only: [map: 2, filter: 2]
  import Registry, only: [select: 2]

  def cwd do
    log("puppet:cwd called\n")
    select() |> track()
  catch
    _, e -> handle(e)
  end

  defp track(entries) do
    log("puppet:entries=#{inspect(entries)}\n")
    entries |> scan()
  end

  defp handle(e) do
    log("puppet:catch=#{inspect(e)}\n")
    nil
  end

  defp select do
    log("puppet:select start\n")
    entries = ElitaRegistry |> select([{{:_, :"$2", :"$1"}, [], [{{:"$2", :"$1"}}]}])
    log("puppet:selected #{entries |> length()} entries\n")
    entries |> pick()
  end

  defp pick(entries) do
    log("puppet:pick entries=#{inspect(entries)}\n")
    result = entries |> map(&extract/1)
    log("puppet:after map=#{inspect(result)}\n")
    result |> filter(& &1)
  end

  defp extract({pid, %{kind: :puppet}}) do
    log("puppet:extract found pid=#{inspect(pid)}\n")
    {pid, %{kind: :puppet}}
  end

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

  defp query(entry) do
    log("puppet:query skip entry=#{inspect(entry)}\n")
    nil
  end

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

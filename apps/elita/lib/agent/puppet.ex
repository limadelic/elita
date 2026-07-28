defmodule Agent.Puppet do
  import Enum, only: [map: 2, filter: 2]
  import Registry, only: [select: 2]
  import Log, only: [trace: 1]

  def cwd do
    trace("puppet:cwd called\n")
    select() |> track()
  catch
    _, e -> handle(e)
  end

  defp track(entries) do
    trace("puppet:entries=#{inspect(entries)}\n")
    entries |> scan()
  end

  defp handle(e) do
    trace("puppet:catch=#{inspect(e)}\n")
    nil
  end

  defp select do
    trace("puppet:select start\n")
    entries = ElitaRegistry |> select([{{:_, :"$2", :"$1"}, [], [{{:"$2", :"$1"}}]}])
    trace("puppet:selected #{entries |> length()} entries\n")
    entries |> pick()
  end

  defp pick(entries) do
    trace("puppet:pick entries=#{inspect(entries)}\n")
    result = entries |> map(&extract/1)
    trace("puppet:after map=#{inspect(result)}\n")
    result |> filter(& &1)
  end

  defp extract({pid, %{kind: :puppet}}) do
    trace("puppet:extract found pid=#{inspect(pid)}\n")
    {pid, %{kind: :puppet}}
  end

  defp extract(_), do: nil

  defp scan([]), do: nil

  defp scan([entry | rest]) do
    entry |> query() |> ok(rest)
  end

  defp query({pid, %{kind: :puppet}}) do
    trace("puppet:found pid=#{inspect(pid)}\n")
    node = node(pid)
    trace("puppet:node=#{node}\n")
    rpc(node)
  end

  defp query(entry) do
    trace("puppet:query skip entry=#{inspect(entry)}\n")
    nil
  end

  defp rpc(node) do
    :erpc.call(node, System, :cwd, [], 5000)
  rescue
    e -> error(e)
  end

  defp error(e) do
    trace("puppet:rpc error=#{inspect(e)}\n")
    nil
  end

  defp ok(cwd, _rest) when is_binary(cwd) do
    trace("puppet:cwd=#{cwd}\n")
    cwd
  end

  defp ok(nil, rest), do: scan(rest)
end

defmodule El.Ask do
  import IO, only: [puts: 1]
  import Node, only: [start: 2, set_cookie: 1, connect: 1, self: 0]
  import Kernel, except: [self: 0]
  import Application, only: [ensure_all_started: 1]
  import System, only: [pid: 0]
  import Enum, only: [find_value: 3]
  import Log, only: [ask: 3]

  defp safely(fun, default) do
    fun.()
  rescue
    _ -> default
  end

  def invoke(agent, msg) do
    prime()
    ask("user", "el.#{agent}", msg)
    reach(agent) |> call(agent, msg) |> done(agent)
  end

  defp done(_agent, result) do
    puts(result)
  end

  defp call(nil, agent, _msg), do: miss(agent)

  defp call(node, agent, msg) do
    rpc(node, agent, msg)
  rescue
    _ ->
      miss(agent)
  end

  defp rpc(node, agent, msg) do
    :erpc.call(node, Agent.Portal, :response, [agent, msg])
  end

  defp miss(agent), do: "unknown: el.#{agent}"

  defp prime do
    :os.cmd(~c"epmd -daemon")
    self() |> boot()
    set_cookie(:elita)
    ensure_all_started(:elita)
  end

  defp boot(:nonode@nohost) do
    start(:"ask_#{pid()}@127.0.0.1", :longnames)
  end

  defp boot(_), do: :ok

  defp reach(agent) do
    agent |> discover() |> sync(agent)
  end

  defp sync({:ok, name}, _agent) do
    target = :"#{name}@127.0.0.1"
    connect(target)
    target
  end

  defp sync({:error, :absent}, _agent), do: nil

  defp discover(agent) do
    :net_adm.names(~c"127.0.0.1") |> locate(agent)
  end

  defp locate({:error, _}, _), do: {:error, :absent}

  defp locate({:ok, names}, agent) do
    find_value(names, {:error, :absent}, &pick(&1, agent))
  end

  defp pick({nodes, _port}, agent) do
    node = :erlang.list_to_binary(nodes)
    scan(node, agent)
  end

  defp scan(node, agent) when node == agent, do: {:ok, node}

  defp scan(node, agent) do
    wrap(node, part(node, agent))
  end

  defp wrap(node, true), do: {:ok, node}
  defp wrap(_, false), do: nil

  defp part(node, agent) do
    len = min(byte_size(agent) + 1, byte_size(node))
    safely(fn -> binary_part(node, 0, len) == <<agent::binary, "-">> end, false)
  end
end

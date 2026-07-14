defmodule El.Ask do
  import IO, only: [puts: 1]
  import Tools
  import Node, only: [start: 2, set_cookie: 1, connect: 1]
  import Application, only: [ensure_all_started: 1]
  import System, only: [pid: 0]
  import Enum, only: [find_value: 3]

  def invoke(agent, msg) do
    prime()
    reach(agent)
    {parts, _} = exec({[spec(agent, msg)], %{name: "el"}})
    print(parts)
  end

  defp spec(agent, msg) do
    %{"id" => "1", "name" => "ask",
      "input" => %{"recipient" => agent, "question" => msg}}
  end

  defp print([%{"result" => result} | _]), do: puts(result)
  defp print(_), do: :ok

  defp prime do
    :os.cmd(~c"epmd -daemon")
    Node.self() |> boot()
    set_cookie(:elita)
    ensure_all_started(:elita)
  end

  defp boot(:nonode@nohost) do
    start(:"ask_#{pid()}@127.0.0.1", :longnames)
  end

  defp boot(_), do: :ok

  defp reach(agent) do
    agent |> discover() |> sync()
  end

  defp sync({:ok, name}) do
    connect(:"#{name}@127.0.0.1")
    :global.sync()
  end

  defp sync({:error, :absent}), do: :ok

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
    binary_part(node, 0, len) == <<agent::binary, "-">>
  rescue
    _ -> false
  end
end

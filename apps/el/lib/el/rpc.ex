defmodule El.RPC do
  @moduledoc false

  import Application, only: [ensure_all_started: 1]
  import File, only: [cwd!: 0]
  import El.Commands.Ls, only: [remote: 1]
  import El.Commands.Ask, only: [ask: 2]
  import El.Commands.Nodes, only: [known?: 1, find: 1]
  import String, only: [split: 2, to_integer: 1]
  import Enum, only: [at: 2]
  import Freeq.Resident, only: [start: 4]

  def dispatch(command, cwd \\ cwd!()) do
    ensure_all_started(:elita)
    build(safe(command, cwd))
  end

  defp build(output) when is_binary(output) do
    "#{marker()}\n#{output}"
  end

  defp build({:error, output}) do
    {:error, "#{marker()}\n#{output}"}
  end

  defp safe(command, cwd), do: handle(command, cwd)

  defp handle(["ls"], cwd), do: remote(cwd: cwd)
  defp handle(["ls", path], _cwd), do: remote(path: path)
  defp handle(["ask", agent, msg], _cwd), do: ask(agent, msg)
  defp handle(["spawn", addr], _cwd), do: check(addr)
  defp handle(_, _cwd), do: ""

  defp check(addr) do
    node = extract(addr)
    agent = agent(addr)
    r = room(addr)
    verify(known?(node), node, agent, r)
  end

  defp extract(addr) do
    addr |> split("@") |> at(1) |> split("/") |> at(0)
  end

  defp agent(addr) do
    addr |> split("@") |> at(0)
  end

  defp room(addr) do
    addr |> split("/") |> at(1)
  end

  defp verify(false, node, _agent, _), do: {:error, "unknown node: #{node}"}
  defp verify(true, node, _agent, nil), do: {:error, "#{node} needs a room"}
  defp verify(true, node, _agent, ""), do: {:error, "#{node} needs a room"}

  defp verify(true, node, agent, room) do
    {_n, _w, host, port} = find(node)
    {ch, pt} = convert(host, port)
    start(agent, "#" <> room, ch, pt)
    "#{agent} started"
  end

  defp convert(host, port) do
    {to_charlist(host), to_integer(port)}
  end

  defp marker, do: "node: #{here()}"

  defp here, do: :erlang.node()
end

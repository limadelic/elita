defmodule El.RPC do
  @moduledoc false

  import Application, only: [ensure_all_started: 1]
  import File, only: [cwd!: 0]
  import El.Commands.Ls, only: [remote: 1]
  import El.Commands.Ask, only: [ask: 2]
  import El.Commands.Nodes, only: [known?: 1, find: 1]
  import String, only: [split: 2, to_integer: 1]
  import Enum, only: [at: 2]
  import Freeq.Resident, only: [start: 5]

  def dispatch(command, cwd \\ cwd!(), opts \\ %{}) do
    ensure_all_started(:elita)
    build(safe(command, cwd, opts))
  end

  defp build(output) when is_binary(output) do
    "#{marker()}\n#{output}"
  end

  defp build({:error, output}) do
    {:error, "#{marker()}\n#{output}"}
  end

  defp safe(command, cwd, opts), do: handle(command, cwd, opts)

  defp handle(["ls"], cwd, _opts), do: remote(cwd: cwd)
  defp handle(["ls", path], _cwd, _opts), do: remote(path: path)
  defp handle(["ask", agent, msg], _cwd, _opts), do: ask(agent, msg)
  defp handle(["spawn", addr], _cwd, opts), do: check(addr, opts)
  defp handle(_, _cwd, _opts), do: ""

  defp check(addr, opts) do
    node = extract(addr)
    agent = agent(addr)
    r = room(addr)
    verify(known?(node), node, agent, r, opts)
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

  defp verify(false, node, _agent, _, _opts), do: {:error, "unknown node: #{node}"}
  defp verify(true, node, _agent, nil, _opts), do: {:error, "#{node} needs a room"}
  defp verify(true, node, _agent, "", _opts), do: {:error, "#{node} needs a room"}

  defp verify(true, node, agent, room, opts) do
    {_n, _w, host, port} = find(node)
    {ch, pt} = convert(host, port)
    start(agent, "#" <> room, ch, pt, opts)
    "#{agent} started"
  end

  defp convert(host, port) do
    {to_charlist(host), to_integer(port)}
  end

  defp marker, do: "node: #{here()}"

  defp here, do: :erlang.node()
end

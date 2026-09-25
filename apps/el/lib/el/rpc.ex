defmodule El.RPC do
  @moduledoc false

  import Application, only: [ensure_all_started: 1]
  import File, only: [cwd!: 0]
  import El.Commands.Ls, only: [remote: 1]
  import El.Commands.Ask, only: [ask: 2]
  import String, only: [split: 2, split: 3]
  import Enum, only: [filter: 2, map: 2, any?: 2]
  import El.Commands.Address.World, only: [build: 0]

  def dispatch(command, cwd \\ cwd!()) do
    ensure_all_started(:elita)
    build(safe(command, cwd))
  end

  defp build(output) do
    "#{marker()}\n#{output}"
  end

  defp safe(command, cwd), do: handle(command, cwd)

  defp handle(["ls"], cwd), do: remote(cwd: cwd)
  defp handle(["ls", path], _cwd), do: remote(path: path)
  defp handle(["ask", agent, msg], _cwd), do: ask(agent, msg)

  defp handle(["spawn", addr], _cwd) do
    [_app, node] = split(addr, "@", parts: 2)
    [node_name | _] = split(node, "/")
    verdict(known(node_name), node_name)
  end

  defp handle(_, _cwd), do: ""

  defp known(name) do
    any?(nodes(), &(elem(&1, 0) == name))
  end

  defp verdict(true, _name), do: ""
  defp verdict(false, name), do: "unknown node: #{name}"

  defp nodes do
    build() |> filter(&(&1.kind == :node)) |> map(&{&1.name, &1})
  end

  defp marker, do: "node: #{here()}"

  defp here, do: :erlang.node()
end

defmodule El.Commands.Nodes do
  import El.Commands.Address.World, only: [build: 0]

  import Enum,
    only: [filter: 2, sort_by: 2, map: 2, join: 2, concat: 2, any?: 2, find: 2]

  import Application, only: [get_env: 2]
  import String, only: [split: 2, split: 3]

  def list do
    nodes = build() |> filter(&(&1.kind == :node)) |> sort_by(& &1.name)
    extras = get_env(:elita, :nodes) |> parse()
    concat(nodes, extras) |> show()
  end

  def known?(name) do
    get_env(:elita, :nodes)
    |> parse()
    |> any?(&matches(&1, name))
  end

  def find(name) do
    get_env(:elita, :nodes)
    |> parse()
    |> find(&matches(&1, name))
  end

  defp parse(nil) do
    []
  end

  defp parse("") do
    []
  end

  defp parse(text) do
    text
    |> split(",")
    |> map(&entry/1)
  end

  defp entry(line) do
    [name, rest] = split(line, "=", parts: 2)
    [world | addr] = split(rest, "://", parts: 2)
    {host, port} = pair(addr)
    {name, world, host, port}
  end

  defp pair([]), do: {"", ""}
  defp pair(addr), do: parts(addr |> join(":") |> split(":", parts: 2))

  defp parts([host, port]), do: {host, port}
  defp parts([host]), do: {host, ""}

  defp matches({node_name, _world, _host, _port}, name) do
    node_name == name
  end

  defp show([]) do
    "no agents"
  end

  defp show(entries) do
    entries
    |> map(&format/1)
    |> join("\n")
  end

  defp format(%{kind: :node} = entry) do
    "#{entry.name} node"
  end

  defp format({name, world, _host, _port}) do
    "#{name} (#{world})"
  end
end

defmodule El.Commands.Nodes do
  import El.Commands.Address.World, only: [build: 0]

  import Enum,
    only: [filter: 2, sort_by: 2, map: 2, join: 2, concat: 2, any?: 2]

  import Application, only: [get_env: 2]
  import String, only: [split: 2, split: 3]

  def check(addr) do
    node = extract(addr)
    reply(known?(node), node)
  end

  defp reply(true, _node), do: ""
  defp reply(false, node), do: "unknown node: #{node}"

  def list do
    nodes = build() |> filter(&(&1.kind == :node)) |> sort_by(& &1.name)
    extras = get_env(:elita, :nodes) |> parse()
    concat(nodes, extras) |> show()
  end

  defp extract(addr) do
    split(addr, "@", parts: 2) |> tail() |> head()
  end

  defp head([h | _]), do: h
  defp head([]), do: ""

  defp tail([_, t]), do: split(t, "/", parts: 2)
  defp tail(_), do: []

  defp known?(node) do
    nodes = build() |> filter(&(&1.kind == :node)) |> map(& &1.name)
    extras = get_env(:elita, :nodes) |> parse() |> map(&elem(&1, 0))
    any?(concat(nodes, extras), &(&1 == node))
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
    world = split(rest, "://", parts: 2) |> fetch()
    {name, world}
  end

  defp fetch([world, _rest]) do
    world
  end

  defp fetch(_other) do
    ""
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

  defp format({name, world}) do
    "#{name} (#{world})"
  end
end

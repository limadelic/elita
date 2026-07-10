defmodule El.Commands.Address.Route do
  import :erpc, only: [call: 4]
  import Application, only: [get_env: 2]
  import El.Commands.Address.World, only: [build: 0, cwd: 0]
  import El.Commands.Address.Wake, only: [up: 1]
  import El.Commands.Address.Send, only: [tell: 3]
  import El.Commands.Address.Spread, only: [fanout: 3]
  import String, only: [to_atom: 1]
  import IO, only: [puts: 1]
  import El.Commands.Lookup, only: [local: 4]
  import Node, only: [self: 0]
  import Kernel, except: [self: 0]
  import Resolver, only: [resolve: 3]

  def handle({:error, :unknown}, recipient, _msg, _mode, _tool),
    do: puts("unknown: #{recipient}")

  def handle({:ok, entry}, _recipient, msg, mode, tool),
    do: steer(entry, msg, mode, tool)

  def handle({:many, _entries}, _recipient, _msg, :ask, _tool),
    do: puts("ask requires one target")

  def handle({:many, entries}, _recipient, msg, :tell, tool),
    do: fanout(entries, msg, tool)

  def steer(%{kind: :node, name: node_str}, msg, mode, tool),
    do: node(to_atom(node_str), node_str, msg, mode, tool)

  def steer(entry, msg, mode, tool), do: exec(entry, msg, mode, tool)

  def node(target, path, msg, mode, tool),
    do: dispatch(target == self(), {target, path, msg, mode, tool})

  def dispatch(true, {_target, path, msg, mode, tool}),
    do: route(path, msg, mode, tool)

  def dispatch(false, {target, path, msg, mode, tool}),
    do: remote(target, path, msg, mode, tool)

  def remote(node, path, msg, mode, tool),
    do: rpc().(node, El.Commands.Address, :route, [path, msg, mode, tool])

  def rpc, do: rpc(get_env(:el, :rpc))
  def rpc(nil), do: &call/4
  def rpc(impl), do: impl

  def exec(entry, msg, :ask, tool),
    do:
      (
        up(entry)
        local(entry.name, msg, tool, [])
      )

  def exec(entry, msg, :tell, tool),
    do:
      (
        up(entry)
        tell(entry.name, msg, tool)
      )

  def route(recipient, msg, mode, tool) do
    result = resolve(recipient, factory().(), cwd())
    handle(result, recipient, msg, mode, tool)
  end

  def factory, do: factory(get_env(:el, :world))
  def factory(nil), do: &build/0
  def factory(f), do: f
end

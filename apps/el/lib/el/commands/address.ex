defmodule El.Commands.Address do
  import :erpc, only: [call: 4]
  import El.Commands.Address.World, only: [build: 0, cwd: 0]
  import El.Commands.Address.Wake, only: [up: 1]
  import El.Commands.Lookup, only: [local: 4]
  import Resolver, only: [resolve: 3]
  import String, only: [downcase: 1]

  def route(recipient, msg, mode \\ :ask, tool \\ nil) do
    world_builder = Application.get_env(:el, :world_builder, &build/0)
    world = world_builder.()
    result = resolve(recipient, world, cwd())
    handle(result, recipient, msg, mode, tool)
  end

  defp handle({:error, :unknown}, recipient, _msg, _mode, _tool),
    do: IO.puts("unknown: #{recipient}")

  defp handle({:ok, entry}, _recipient, msg, mode, tool),
    do: steer(entry, msg, mode, tool)

  defp handle({:many, _entries}, _recipient, _msg, :ask, _tool),
    do: IO.puts("ask requires one target")

  defp handle({:many, entries}, _recipient, msg, :tell, tool) do
    unique = Enum.uniq_by(entries, &{&1.name, &1.path})
    Enum.each(unique, &up/1)
    Enum.each(unique, fn e -> tell(e.name, msg, tool) end)
  end

  defp steer(%{kind: :node, name: node_str}, msg, mode, tool) do
    node(String.to_atom(node_str), node_str, msg, mode, tool)
  end

  defp steer(entry, msg, mode, tool), do: exec(entry, msg, mode, tool)

  defp node(node, path, msg, mode, tool) do
    args = [path, msg, mode, tool]
    decide(node == Node.self(), node, args)
  end

  defp decide(true, _node, [path, msg, mode, tool]) do
    route(path, msg, mode, tool)
  end

  defp decide(false, node, args) do
    rpc = Application.get_env(:el, :rpc, nil)
    invoke(rpc, node, args)
  end

  defp invoke(nil, node, [path, msg, mode, tool]) do
    call(node, El.Commands.Address, :route, [path, msg, mode, tool])
  end

  defp invoke(rpc, node, [path, msg, mode, tool]) do
    rpc.(node, El.Commands.Address, :route, [path, msg, mode, tool])
  end

  defp exec(entry, msg, :ask, tool) do
    up(entry)
    local(entry.name, msg, tool, [])
  end

  defp exec(entry, msg, :tell, tool) do
    up(entry)
    tell(entry.name, msg, tool)
  end

  defp tell(agent, msg, tool), do: downcase(agent) |> find(msg, tool)

  defp find(n, msg, nil), do: Registry.lookup(ElitaRegistry, n) |> dispatch(msg)

  defp find(n, msg, tool) do
    Registry.lookup(ElitaRegistry, "#{n}:#{tool}")
    |> fallback(n)
    |> dispatch(msg)
  end

  defp fallback([], key), do: Registry.lookup(ElitaRegistry, key)
  defp fallback(r, _), do: r

  defp dispatch([], _msg), do: :ok

  defp dispatch(pids, msg) do
    Enum.each(pids, fn {pid, meta} ->
      GenServer.cast(pid, pack(meta[:kind], msg))
    end)
  end

  defp pack(:native, msg), do: {:act, msg}
  defp pack(_, msg), do: {:cast, msg}
end

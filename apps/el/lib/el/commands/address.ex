defmodule El.Commands.Address do
  import Agent.Session, only: [start_link: 1]
  import El.Commands.Lookup, only: [local: 4]
  import String, only: [downcase: 1]
  import El.Commands.Address.World, only: [build: 0, cwd: 0]
  import :erpc, only: [call: 4]

  def route(recipient, msg, mode \\ :ask, tool \\ nil) do
    result = Resolver.resolve(recipient, build(), cwd())
    handle(result, recipient, msg, mode, tool)
  end

  @doc false
  def route(recipient, msg, mode, tool, rpc, world) do
    save(rpc)
    result = Resolver.resolve(recipient, world, cwd())
    handle(result, recipient, msg, mode, tool)
  end

  defp save(nil), do: :ok
  defp save(rpc), do: Application.put_env(:el, :rpc, rpc)
  defp handle({:error, :unknown}, recipient, _msg, _mode, _tool), do: IO.puts("unknown: #{recipient}")
  defp handle({:ok, entry}, _recipient, msg, mode, tool), do: steer(entry, msg, mode, tool)
  defp handle({:many, _entries}, _recipient, _msg, :ask, _tool), do: IO.puts("ask requires one target")
  defp handle({:many, entries}, _recipient, msg, :tell, tool) do
    unique = Enum.uniq_by(entries, &{&1.name, &1.path})
    Enum.each(unique, &rouse/1)
    Enum.each(unique, fn e -> tell(e.name, msg, tool) end)
  end
  defp steer(%{kind: :node, name: node_str}, msg, mode, tool) do
    route_node(String.to_atom(node_str), node_str, msg, mode, tool)
  end
  defp steer(entry, msg, mode, tool), do: handle_local(entry, msg, mode, tool)
  defp route_node(node, path, msg, mode, tool) do
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
  defp handle_local(entry, msg, :ask, tool) do
    rouse(entry); local(entry.name, msg, tool, [])
  end
  defp handle_local(entry, msg, :tell, tool) do
    rouse(entry); tell(entry.name, msg, tool)
  end
  defp tell(agent, msg, tool), do: downcase(agent) |> find(msg, tool)
  defp find(n, msg, nil), do: Registry.lookup(ElitaRegistry, n) |> dispatch(msg)
  defp find(n, msg, tool) do
    Registry.lookup(ElitaRegistry, "#{n}:#{tool}") |> fallback(n) |> dispatch(msg)
  end
  defp fallback([], key), do: Registry.lookup(ElitaRegistry, key)
  defp fallback(r, _), do: r
  defp dispatch([], _msg), do: :ok
  defp dispatch(pids, msg) do
    Enum.each(pids, fn {pid, meta} ->
      GenServer.cast(pid, kind_msg(meta[:kind], msg))
    end)
  end
  defp kind_msg(:native, msg), do: {:act, msg}
  defp kind_msg(_, msg), do: {:cast, msg}
  defp rouse(%{kind: k, name: n, path: p} = entry) when k in [:file, :folder] do
    key = n |> to_string |> String.downcase
    sleep = Registry.lookup(ElitaRegistry, key) |> Enum.empty?
    stir(sleep, n, p, Map.get(entry, :file_path))
  end
  defp rouse(_), do: :ok
  defp stir(false, _name, _folder, _self), do: :ok
  defp stir(true, name, folder, self) do
    rune = System.get_env("TEST_AGENT_RUNNER") |> pick()
    start_link(wire([name: name, folder: folder, self: self], rune))
  end
  defp pick(nil), do: nil
  defp pick(name) do
    atom = String.to_atom("Elixir." <> name)
    load(Code.ensure_loaded?(atom), atom)
  end
  defp load(true, a), do: a
  defp load(false, _), do: nil
  defp wire(opts, nil), do: opts
  defp wire(opts, rune), do: Keyword.put(opts, :runner, fn m, f -> apply(rune, :run, [m, f]) end)
end

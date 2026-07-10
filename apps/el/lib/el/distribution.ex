defmodule El.Distribution do
  @moduledoc false
  import Application, only: [ensure_all_started: 1]
  import El.Host, only: [host: 0]
  import El.Peers, only: [load: 0]
  import Process, only: [sleep: 1]
  import Node, only: [connect: 1, set_cookie: 1]
  import Enum, only: [each: 2]
  import IO, only: [write: 2]
  import String, only: [contains?: 2]
  import Keyword, only: [get: 3]
  import File, only: [cwd!: 0]
  import Path, only: [basename: 1]
  import Registry, only: [lookup: 2]

  def start(name \\ :default, opts \\ []) do
    node_name = node(name, opts)
    boot(node_name, naming(opts))
  end

  def target(name) do
    import El.Log, only: [write: 1]
    write("target lookup: #{name}\n")
    connect(:"claude_#{name}@127.0.0.1")
    :global.sync()
    result = :global.whereis_name({name, :puppet})
    write("global lookup #{name}: #{inspect(result)}\n")
    pick(result, name)
  rescue
    e ->
      import El.Log, only: [write: 1]
      write("target lookup error: #{inspect(e)}\n")
      find(name)
  end

  defp pick(:undefined, name), do: find(name)
  defp pick(pid, _), do: pid

  defp find(name) do
    import El.Log, only: [write: 1]
    write("registry lookup #{name}\n")
    lookup(ElitaRegistry, name) |> extract()
  rescue
    e ->
      import El.Log, only: [write: 1]
      write("registry lookup error: #{inspect(e)}\n")
      nil
  end

  defp extract([{pid, %{kind: :puppet}}]) do
    import El.Log, only: [write: 1]
    write("found puppet: #{inspect(pid)}\n")
    pid
  end

  defp extract(other) do
    import El.Log, only: [write: 1]
    write("extract failed: #{inspect(other)}\n")
    nil
  end

  def daemon do
    boot(:"elita@127.0.0.1", :longnames)
    ensure_all_started(:elita)
    dial()
    sleep(:infinity)
  end

  defp dial do
    load() |> each(&connect/1)
  rescue
    _ -> :ok
  end

  defp node(:default, opts),
    do: :"claude_#{cwd!() |> basename()}@#{get(opts, :host, host())}"

  defp node(name, opts),
    do: :"claude_#{name}@#{get(opts, :host, host())}"

  defp boot(node_name, mode) do
    import El.Log, only: [write: 1]
    epmd = System.find_executable("epmd")
    write("boot: node_name=#{inspect(node_name)} mode=#{inspect(mode)} epmd=#{inspect(epmd)}\n")

    fn -> Node.start(node_name, mode) end
    |> then(&attempt(&1.(), &1, 5))
    |> act(node_name, mode)
  end

  defp attempt({:ok, pid}, _fun, _tries), do: {:ok, pid}

  defp attempt({:error, {:already_started, pid}}, _fun, _tries),
    do: {:error, {:already_started, pid}}

  defp attempt({:error, reason}, fun, tries) when tries > 1 do
    import El.Log, only: [write: 1]
    write("boot attempt failed: #{inspect(reason)}, retrying... (#{tries - 1} tries left)\n")
    sleep(200)
    attempt(fun.(), fun, tries - 1)
  end

  defp attempt({:error, reason}, _fun, _tries) do
    import El.Log, only: [write: 1]
    write("boot attempt failed: #{inspect(reason)}, max retries exceeded\n")
    {:error, :max_retries_exceeded}
  end

  defp act({:ok, _pid}, _node_name, _mode) do
    import El.Log, only: [write: 1]
    write("boot: Node.start succeeded\n")
    set_cookie(:elita)
    :ok
  end

  defp act({:error, {:already_started, _pid}}, _node_name, _mode) do
    import El.Log, only: [write: 1]
    write("boot: Node.start already_started\n")
    set_cookie(:elita)
    :taken
  end

  defp act({:error, reason}, _node_name, _mode) do
    import El.Log, only: [write: 1]
    write("boot: Node.start failed with error: #{inspect(reason)}\n")
    write(:stderr, "Error: Failed to start distribution: #{inspect(reason)}\n")
    :ok
  end

  def naming(opts) do
    %{true => :longnames, false => :shortnames}[
      opts |> get(:host, "127.0.0.1") |> contains?(".")
    ]
  end

  def fetch(opts \\ []) do
    get(opts, :host, host())
  end
end

defmodule El.Distribution do
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
  import El.Log, only: [write: 1]

  def start(name \\ :default, opts \\ []) do
    :os.cmd(~c"epmd -daemon")
    boot(node(name, opts), mode(opts))
  end

  defp mode(opts) do
    %{true => :longnames, false => :shortnames}[
      opts |> get(:host, "127.0.0.1") |> contains?(".")
    ]
  end

  def target(name) do
    connect(:"claude_#{name}@127.0.0.1") |> route(name)
  rescue
    _ -> find(name)
  end

  defp route(result, name) when result in [true, :ignored], do: locate(name)
  defp route(false, name), do: find(name)

  defp locate(name) do
    :global.sync()
    :global.whereis_name({name, :puppet}) |> reply(name)
  end

  defp reply(:undefined, name), do: find(name)
  defp reply(pid, _name), do: pid

  defp find(name) do
    lookup(ElitaRegistry, name) |> extract()
  rescue
    _ -> nil
  end

  defp extract([{pid, %{kind: :puppet}}]), do: pid
  defp extract(_), do: nil

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

  defp node(:default, opts), do: :"claude_#{cwd!() |> basename()}@#{get(opts, :host, host())}"
  defp node(name, opts), do: :"claude_#{name}@#{get(opts, :host, host())}"

  defp boot(name, mode),
    do: fn -> Node.start(name, mode) end |> then(&attempt(&1.(), &1, 5)) |> act(name, mode)

  defp attempt({:ok, pid}, _fun, _tries), do: {:ok, pid}

  defp attempt({:error, {:already_started, pid}}, _fun, _tries),
    do: {:error, {:already_started, pid}}

  defp attempt({:error, _reason}, fun, tries) when tries > 1 do
    sleep(200)
    attempt(fun.(), fun, tries - 1)
  end

  defp attempt({:error, reason}, _fun, _tries) do
    write("boot failed: #{inspect(reason)}\n")
    {:error, :max_retries_exceeded}
  end

  defp act({:ok, _}, _, _), do: cookie(:ok)
  defp act({:error, {:already_started, _}}, _, _), do: cookie(:taken)

  defp act({:error, reason}, _, _) do
    write(:stderr, "Error: Failed to start distribution: #{inspect(reason)}\n")
    :ok
  end

  defp cookie(val) do
    set_cookie(:elita)
    val
  end

  def fetch(opts \\ []), do: get(opts, :host, host())
end

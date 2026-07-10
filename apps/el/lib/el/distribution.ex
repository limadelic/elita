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
    :global.whereis_name({name, :puppet}) |> pick(name)
  rescue
    _ -> find(name)
  end

  defp pick(:undefined, name), do: find(name)
  defp pick(pid, _), do: pid

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
  defp node(name, opts) do
    :"claude_#{session(name)}@#{get(opts, :host, host())}"
  end

  defp boot(node_name, mode) do
    fn -> Node.start(node_name, mode) end
    |> then(&attempt(&1.(), &1, 5))
    |> act(node_name, mode)
  end

  defp attempt({:ok, pid}, _fun, _tries), do: {:ok, pid}
  defp attempt({:error, {:already_started, pid}}, _fun, _tries), do: {:error, {:already_started, pid}}
  defp attempt({:error, _reason}, fun, tries) when tries > 1 do
    sleep(200)
    attempt(fun.(), fun, tries - 1)
  end
  defp attempt({:error, _reason}, _fun, _tries), do: {:error, :max_retries_exceeded}

  defp act({:ok, _pid}, _node_name, _mode) do
    set_cookie(:elita)
    :ok
  end

  defp act({:error, {:already_started, _pid}}, _node_name, _mode) do
    set_cookie(:elita)
    :taken
  end

  defp act({:error, reason}, _node_name, _mode) do
    write(:stderr, "Error: Failed to start distribution: #{inspect(reason)}\n")
    :ok
  end

  def naming(opts) do
    opts |> get(:host, "127.0.0.1") |> dots?() |> mode()
  end

  defp dots?(h), do: contains?(h, ".")

  defp mode(true), do: :longnames
  defp mode(false), do: :shortnames

  def fetch(opts \\ []) do
    get(opts, :host, host())
  end

  defp session(:default), do: cwd!() |> basename()
  defp session(name), do: name
end

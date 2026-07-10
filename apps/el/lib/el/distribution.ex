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

  def start(name \\ :default, opts \\ []) do
    node_name = node(name, opts)
    boot(node_name, naming(opts))
  end

  def daemon do
    boot(:"elita@127.0.0.1", :longnames)
    ensure_all_started(:elita)
    redial()
    sleep(:infinity)
  end

  defp redial do
    load() |> each(&connect/1)
  rescue
    _ -> :ok
  end

  defp node(name, opts) do
    :"claude_#{session(name)}@#{get(opts, :host, host())}"
  end

  defp boot(node_name, mode) do
    retry(fn -> Node.start(node_name, mode) end, 5) |> act(node_name, mode)
  end

  defp retry(fun, tries) do
    attempt(fun.(), fun, tries)
  end

  defp attempt({:ok, pid}, _fun, _tries) do
    {:ok, pid}
  end

  defp attempt({:error, {:already_started, pid}}, _fun, _tries) do
    {:error, {:already_started, pid}}
  end

  defp attempt({:error, _reason}, fun, tries) when tries > 1 do
    sleep(200)
    retry(fun, tries - 1)
  end

  defp attempt({:error, _reason}, _fun, _tries) do
    {:error, :max_retries_exceeded}
  end

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

  defp mode(h) do
    format(contains?(h, "."))
  end

  defp format(true), do: :longnames
  defp format(false), do: :shortnames

  def naming(opts) do
    host_value = get(opts, :host, "127.0.0.1")
    mode(host_value)
  end

  def fetch(opts \\ []) do
    get(opts, :host, host())
  end

  defp session(:default) do
    cwd!() |> basename()
  end

  defp session(name) when is_binary(name) do
    name
  end
end

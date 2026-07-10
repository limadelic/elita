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
    host_value = addr(opts)
    mode = mode(host_value)
    boot(node_name, mode)
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
    session_name = session(name)
    host_value = addr(opts)
    :"claude_#{session_name}@#{host_value}"
  end

  defp boot(node_name, mode) do
    Node.start(node_name, mode) |> act(node_name, mode)
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
    warn(reason)
    :ok
  end

  defp warn(reason) do
    write(:stderr, "Warning: Failed to start distribution: #{inspect(reason)}\n")
  end

  defp mode(h) do
    {contains?(h, "."), h} |> format()
  end

  defp format({true, _}), do: :longnames
  defp format({false, _}), do: :shortnames

  def naming(opts) do
    host_value = get(opts, :host, "127.0.0.1")
    mode(host_value)
  end

  def fetch(opts \\ []) do
    get(opts, :host, host())
  end

  defp addr(opts) do
    get(opts, :host, host())
  end

  defp session(:default) do
    cwd!()
    |> basename()
  end

  defp session(name) when is_binary(name) do
    name
  end
end

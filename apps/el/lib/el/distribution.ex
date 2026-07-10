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
    node_name = build_node_name(name, opts)
    host_value = build_host(opts)
    mode = mode_from_host(host_value)
    start_node(node_name, mode)
  end

  def daemon do
    start_node(:"elita@127.0.0.1", :longnames)
    ensure_all_started(:elita)
    redial()
    sleep(:infinity)
  end

  defp redial do
    load() |> each(&connect/1)
  rescue
    _ -> :ok
  end

  defp build_node_name(name, opts) do
    session_name = session(name)
    host_value = build_host(opts)
    :"claude_#{session_name}@#{host_value}"
  end

  defp start_node(node_name, mode) do
    Node.start(node_name, mode) |> apply_start(node_name, mode)
  end

  defp apply_start({:ok, _pid}, _node_name, _mode) do
    set_cookie(:elita)
    :ok
  end

  defp apply_start({:error, {:already_started, _pid}}, _node_name, _mode) do
    set_cookie(:elita)
    :taken
  end

  defp apply_start({:error, reason}, _node_name, _mode) do
    warn(reason)
    :ok
  end

  defp warn(reason) do
    write(:stderr, "Warning: Failed to start distribution: #{inspect(reason)}\n")
  end

  defp mode_from_host(h) do
    {contains?(h, "."), h} |> format_mode()
  end

  defp format_mode({true, _}), do: :longnames
  defp format_mode({false, _}), do: :shortnames

  def naming_mode(opts) do
    host_value = get(opts, :host, "127.0.0.1")
    mode_from_host(host_value)
  end

  def resolve_host(opts \\ []) do
    get(opts, :host, host())
  end

  defp build_host(opts) do
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

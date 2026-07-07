defmodule El.Distribution do
  @moduledoc false
  import El.Host, only: [host: 0]

  def start(name \\ :default, opts \\ []) do
    node_name = build_node_name(name, opts)
    host_value = build_host(opts)
    mode = mode_from_host(host_value)
    start_node(node_name, mode)
  end

  defp build_node_name(name, opts) do
    session_name = resolve_session_name(name)
    host_value = build_host(opts)
    :"claude_#{session_name}@#{host_value}"
  end

  defp start_node(node_name, mode) do
    Node.start(node_name, mode) |> apply_start(node_name, mode)
  end

  defp apply_start({:ok, _pid}, _node_name, _mode) do
    Node.set_cookie(:elita)
    :ok
  end

  defp apply_start({:error, {:already_started, _pid}}, _node_name, _mode) do
    Node.set_cookie(:elita)
    :taken
  end

  defp apply_start({:error, reason}, _node_name, _mode) do
    IO.write(:stderr, "Warning: Failed to start distribution: #{inspect(reason)}\n")
    :ok
  end

  defp mode_from_host(h) do
    {String.contains?(h, "."), h} |> format_mode()
  end

  defp format_mode({true, _}), do: :longnames
  defp format_mode({false, _}), do: :shortnames

  def naming_mode(opts) do
    host_value = Keyword.get(opts, :host, "127.0.0.1")
    mode_from_host(host_value)
  end

  def resolve_host(opts \\ []) do
    Keyword.get(opts, :host, host())
  end

  defp build_host(opts) do
    Keyword.get(opts, :host, host())
  end

  defp resolve_session_name(:default) do
    File.cwd!()
    |> Path.basename()
  end

  defp resolve_session_name(name) when is_binary(name) do
    name
  end
end

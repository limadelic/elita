defmodule El.Distribution do
  def start(name \\ :default, opts \\ []) do
    session_name = resolve_session_name(name)
    host = resolve_host(opts)
    mode = naming_mode([host: host])
    node_name = :"claude_#{session_name}@#{host}"

    case Node.start(node_name, mode) do
      {:ok, _pid} ->
        Node.set_cookie(:elita)
        :ok

      {:error, {:already_started, _pid}} ->
        Node.set_cookie(:elita)
        :taken

      {:error, reason} ->
        IO.write(:stderr, "Warning: Failed to start distribution: #{inspect(reason)}\n")
        :ok
    end
  end

  def naming_mode(opts) do
    host = Keyword.get(opts, :host, "127.0.0.1")
    El.Host.naming_mode(host)
  end

  def resolve_host(opts \\ []) do
    Keyword.get(opts, :host, El.Host.host())
  end

  defp resolve_session_name(:default) do
    File.cwd!()
    |> Path.basename()
  end

  defp resolve_session_name(name) when is_binary(name) do
    name
  end
end
